import { emitNui } from "../nui";
import type {
  Challenge,
  CreateRaceInput,
  CrewBrief,
  CrewListItem,
  CrewRankRow,
  GameState,
  HistoryItem,
  LeaderboardRow,
  Lobby,
  LobbyPlayer,
  LobbySummary,
  PastResults,
  PilotRankRow,
  RaceMode,
  RaceResults,
  ResultRow,
} from "../types";
import { config, crew, findTrack, gameState, me, MockError, settings, tracks, trackDetail, listTracks, type Handler, type MockTrack } from "./db";

// Errores del servidor (code -> [es, en]) ------------------------------------------------------------

const ERR: Record<string, [string, string]> = {
  already_in_race: ["Ya estás en una carrera.", "You are already in a race."],
  not_in_race: ["No estás en ninguna carrera.", "You are not in a race."],
  race_not_found: ["La carrera ya no existe o ha empezado.", "The race no longer exists or has started."],
  race_full: ["La carrera está completa.", "The race is full."],
  race_starting: ["La carrera está comprobando vehículos o a punto de salir.", "The race is checking vehicles or about to start."],
  private_race: ["Esta carrera es privada: necesitas una invitación.", "This race is private: you need an invitation."],
  players_not_ready: ["Todos los pilotos deben estar listos.", "All drivers must be ready."],
  no_money: ["No tienes dinero suficiente.", "You don't have enough money."],
  cannot_self: ["No puedes hacerlo sobre ti mismo.", "You cannot do that to yourself."],
  target_not_found: ["El jugador no está conectado.", "That player is not online."],
  target_busy: ["Ese jugador ya está en una carrera.", "That player is already in a race."],
  track_not_found: ["El circuito no existe o no está activo.", "The track does not exist or is not active."],
  track_no_crews: ["Este circuito no permite carreras de crews.", "This track does not allow crew races."],
  laps_invalid: ["Número de vueltas no válido.", "Invalid number of laps."],
  class_invalid: ["Clase de vehículo no permitida para este circuito.", "Vehicle class not allowed for this track."],
  name_invalid: ["Nombre no válido (3-48 caracteres).", "Invalid name (3-48 characters)."],
  invalid_data: ["Datos inválidos.", "Invalid data."],
  no_permission: ["No tienes permiso para hacer esto.", "You don't have permission to do this."],
  crews_disabled: ["El sistema de crews no está activo.", "The crew system is not active."],
  crew_not_found: ["El crew no existe.", "The crew does not exist."],
  crew_no_funds: ["El banco del crew no tiene fondos suficientes.", "The crew bank has insufficient funds."],
  not_crew_member: ["Solo pueden unirse miembros de los crews del reto.", "Only members of the challenged crews can join."],
  teams_unbalanced: ["Ambos equipos deben tener el mismo número de pilotos.", "Both teams must have the same number of drivers."],
  challenge_exists: ["Tu crew ya tiene un reto pendiente.", "Your crew already has a pending challenge."],
  challenge_not_found: ["El reto ya no está disponible.", "The challenge is no longer available."],
  grid_too_small: ["La parrilla del circuito es demasiado pequeña.", "The track grid is too small."],
  result_not_found: ["Resultado no encontrado.", "Result not found."],
};

function fail(code: string): never {
  const m = ERR[code];
  throw new MockError(m ? m[config.locale === "en" ? 1 : 0] : code, code);
}

// Utilidades -------------------------------------------------------------------------------------------

const later = (ms: number, fn: () => void) => void setTimeout(fn, ms);
const nowSec = () => Math.floor(Date.now() / 1000);

function int(v: unknown, min: number, max: number): number | null {
  const n = Number(v);
  return Number.isInteger(n) && n >= min && n <= max ? n : null;
}

function rng(seed: number) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const myCrewBrief: CrewBrief = { id: crew.id, name: crew.name, tag: crew.tag, color: crew.color };
const RIVALS: (CrewBrief & CrewListItem)[] = [
  { id: 2, name: "Night Owls", tag: "NOS", color: "#3b82f6", level: 5, points: 6120, members: 14 },
  { id: 3, name: "Rust Kings", tag: "RST", color: "#f59e0b", level: 3, points: 3880, members: 9 },
  { id: 4, name: "Velocity Club", tag: "VLC", color: "#22c55e", level: 4, points: 4410, members: 11 },
  { id: 5, name: "Ghost Lane", tag: "GHL", color: "#d946ef", level: 2, points: 1750, members: 6 },
];
const brief = (c: CrewBrief): CrewBrief => ({ id: c.id, name: c.name, tag: c.tag, color: c.color });

interface Bot {
  name: string;
  crewId?: number;
}
const BOTS: Bot[] = [
  { name: "Dani Moreno", crewId: 1 },
  { name: "Laura Vega", crewId: 2 },
  { name: "Kira Tanaka" },
  { name: "Pablo Núñez", crewId: 2 },
  { name: "Marta Solis", crewId: 3 },
  { name: "Iván Cruz", crewId: 4 },
  { name: "Noa Ferrer" },
  { name: "Hugo Prado", crewId: 5 },
  { name: "Sara Beltrán", crewId: 3 },
  { name: "Leo Quintana" },
  { name: "Aitana Rey", crewId: 4 },
  { name: "Bruno Sanz", crewId: 1 },
];
const VEHICLES = ["Pfister Comet", "Karin Futo", "Annis Elegy RH8", "Bravado Buffalo", "Ocelot Pariah", "Dinka Jester"];

function crewInfo(id?: number): LobbyPlayer["crew"] {
  const c = id === 1 ? myCrewBrief : RIVALS.find((x) => x.id === id);
  return c ? { tag: c.tag, color: c.color, name: c.name } : undefined;
}

let botSeq = 20;
function bot(opts: { name?: string; crewId?: number; ready?: boolean; host?: boolean; team?: "A" | "B" } = {}): LobbyPlayer {
  const b = opts.name ? { name: opts.name, crewId: opts.crewId } : BOTS[botSeq % BOTS.length]!;
  const p: LobbyPlayer = { pid: botSeq++, name: b.name, ready: !!opts.ready || !!opts.host, host: !!opts.host, crew: crewInfo(b.crewId), you: false };
  if (opts.team) p.team = opts.team;
  return p;
}

function meAs(host: boolean, team?: "A" | "B"): LobbyPlayer {
  const p: LobbyPlayer = { pid: me.pid, name: me.name, ready: host, host, crew: crewInfo(crew.id), you: true };
  if (team) p.team = team;
  return p;
}

// Estado en memoria -------------------------------------------------------------------------------------

interface MockChallenge extends Challenge {
  expiresAt: number;
}

let seq = 100;
const S = {
  wallet: 30000,
  lobby: null as Lobby | null,
  open: [] as Lobby[],
  invited: new Map<number, number>(),
  incoming: [] as MockChallenge[],
  outgoing: [] as MockChallenge[],
  last: null as RaceResults | null,
  stats: { races: 38, wins: 9, podiums: 17, earnings: 184500, points: 612 },
  bests: new Map<number, { bestLap: number; vehicle: string }>(),
  history: [] as HistoryItem[],
  past: new Map<string, PastResults>(),
};

function recalc(l: Lobby): Lobby {
  const entries = l.entryFee * l.players.length;
  l.prizePool = l.crewVs ? l.crewVs.stake * 2 : entries - Math.floor((entries * config.commissionPct) / 100) + l.extraPrize + findTrack(l.trackId).basePrize;
  const host = l.players.find((p) => p.host);
  l.hostName = host?.name ?? l.hostName;
  l.isHost = !!host?.you;
  return l;
}

interface LobbyOpts {
  name: string;
  mode: RaceMode;
  track: MockTrack;
  laps: number;
  vehicleClass: string;
  entryFee?: number;
  extraPrize?: number;
  private?: boolean;
  hostName?: string;
  players: LobbyPlayer[];
  crewVs?: Lobby["crewVs"];
}

function makeLobby(o: LobbyOpts): Lobby {
  return recalc({
    id: ++seq,
    name: o.name,
    mode: o.mode,
    state: "open",
    trackId: o.track.id,
    trackName: o.track.name,
    category: o.track.category,
    difficulty: o.track.difficulty,
    collisions: o.track.collisions,
    laps: o.laps,
    vehicleClass: o.vehicleClass,
    entryFee: o.entryFee ?? 0,
    extraPrize: o.extraPrize ?? 0,
    prizePool: 0,
    private: !!o.private,
    maxPlayers: o.crewVs ? o.crewVs.size * 2 : config.maxPlayers,
    official: o.mode === "official",
    hostName: o.hostName ?? "",
    isHost: false,
    you: me.pid,
    crewVs: o.crewVs,
    players: o.players,
  });
}

function seedLobbies() {
  const official = makeLobby({
    name: "Gran Premio Vinewood",
    mode: "official",
    track: findTrack(1),
    laps: 3,
    vehicleClass: "any",
    extraPrize: 25000,
    hostName: "Dirección de Carrera",
    players: [bot({ name: "Dirección de Carrera", host: true }), bot({ ready: true }), bot({ ready: true }), bot(), bot({ ready: true })],
  });
  const vsTrack = findTrack(4);
  const vs = makeLobby({
    name: "NOS vs RST — Docks",
    mode: "crew",
    track: vsTrack,
    laps: 3,
    vehicleClass: "any",
    crewVs: { a: brief(RIVALS[0]!), b: brief(RIVALS[1]!), size: 3, stake: 20000, formula: settings.crewVsFormula },
    players: [
      bot({ name: "Laura Vega", crewId: 2, host: true, team: "A" }),
      bot({ name: "Pablo Núñez", crewId: 2, ready: true, team: "A" }),
      bot({ name: "Marta Solis", crewId: 3, ready: true, team: "B" }),
      bot({ name: "Sara Beltrán", crewId: 3, team: "B" }),
    ],
  });
  const fee = makeLobby({
    name: "Vuelta al lago",
    mode: "open",
    track: findTrack(5),
    laps: 3,
    vehicleClass: "any",
    entryFee: 1500,
    players: [bot({ name: "Noa Ferrer", host: true }), bot({ ready: true }), bot({ ready: true })],
  });
  const priv = makeLobby({
    name: "Solo amigos",
    mode: "open",
    track: findTrack(2),
    laps: 1,
    vehicleClass: "sports",
    private: true,
    players: [bot({ name: "Kira Tanaka", host: true }), bot({ ready: true })],
  });
  S.open = [official, vs, fee, priv];
  S.invited.set(priv.id, Date.now() + 15 * 60000);
  S.incoming = [
    {
      id: 1,
      from: brief(RIVALS[0]!),
      to: myCrewBrief,
      fromName: "Laura Vega",
      trackId: 4,
      trackName: findTrack(4).name,
      laps: 3,
      vehicleClass: "any",
      teamSize: 3,
      stake: 15000,
      expiresIn: 0,
      expiresAt: Date.now() + 15 * 60000,
    },
  ];
}

function seedHistory() {
  const r = rng(42);
  const pts = settings.pilotPoints;
  for (let i = 0; i < 25; i++) {
    const track = tracks[i % 5]!;
    const position = i % 4 === 0 ? 1 : 1 + Math.floor(r() * 8);
    const status = i % 11 === 6 ? "dnf" : "finished";
    const laps = track.category === "sprint" ? 1 : 3;
    const ref = track.referenceTime || 90000;
    const total = Math.round(ref * laps * (1 + r() * 0.12));
    const id = 900 - i;
    S.history.push({
      id,
      raceKey: `mock-${id}`,
      trackId: track.id,
      trackName: track.name,
      mode: i % 7 === 0 ? "official" : i % 6 === 0 ? "crew" : "open",
      position,
      status,
      totalTime: status === "dnf" ? 0 : total,
      bestLap: status === "dnf" ? 0 : Math.round((total / laps) * 0.985),
      prize: status === "finished" && position <= 3 ? [8000, 4500, 2500][position - 1]! : 0,
      points: status === "finished" ? (pts[position - 1] ?? 0) : 0,
      crewPoints: status === "finished" && position <= 6 ? (settings.crewPointsByPosition[position - 1] ?? 0) : 0,
      flagged: i === 13,
      voided: i === 19,
      createdAt: nowSec() - (i + 1) * 72000,
    });
  }
  for (const [id, lap] of [[1, 83900], [2, 96200], [4, 115800], [5, 63400]] as const) S.bests.set(id, { bestLap: lap, vehicle: VEHICLES[id % VEHICLES.length]! });
}

seedLobbies();
seedHistory();

// Salas -------------------------------------------------------------------------------------------------------

const view = (l: Lobby): Lobby => structuredClone(l);

function push(l: Lobby) {
  recalc(l);
  if (S.lobby === l) emitNui("lobby", { lobby: view(l) });
}

const active = (l: Lobby) => S.lobby === l && S.open.includes(l);

/** Simula la llegada de invitados y que acaben marcandose listos */
function animateLobby(l: Lobby, guests: number) {
  for (let i = 0; i < guests; i++) {
    later(2200 + i * 2000, () => {
      if (!active(l) || l.state !== "open" || l.players.length >= l.maxPlayers) return;
      l.players.push(bot());
      push(l);
    });
  }
  const readyUp = (delay: number) =>
    later(delay, () => {
      if (!active(l) || l.state !== "open") return;
      const p = l.players.find((x) => !x.you && !x.ready);
      if (p) p.ready = true;
      push(l);
      if (l.players.some((x) => !x.you && !x.ready)) readyUp(1500);
    });
  readyUp(3500 + guests * 2000);
  hostBot(l);
}

/** Si el anfitrion es un bot, sale en cuanto todos estan listos */
function hostBot(l: Lobby) {
  const tick = () => {
    if (!active(l) || l.state !== "open" || l.isHost) return;
    if (l.players.length >= 2 && l.players.every((p) => p.ready)) beginRace(l);
    else later(4000, tick);
  };
  later(12000, tick);
}

function beginRace(l: Lobby) {
  l.state = "checking";
  push(l);
  const cd = config.countdownSeconds * 1000;
  later(1200, () => {
    if (!active(l)) return;
    l.state = "countdown";
    push(l);
  });
  later(1200 + cd, () => {
    if (!active(l)) return;
    l.state = "running";
    push(l);
  });
  later(1200 + cd + 6000, () => active(l) && finishRace(l));
}

function leaveCurrent() {
  const l = S.lobby;
  if (!l) return;
  if (l.isHost) {
    S.wallet += l.entryFee + l.extraPrize;
    S.open = S.open.filter((x) => x !== l);
  } else {
    S.wallet += l.entryFee;
    l.players = l.players.filter((p) => !p.you);
    recalc(l);
  }
  S.lobby = null;
  emitNui("lobby", { lobby: false });
}

function crewLobby(ch: { from: CrewBrief; to: CrewBrief; trackId: number; laps: number; vehicleClass: string; teamSize: number; stake: number }, meHost: boolean): Lobby {
  const mineIsA = ch.from.id === crew.id;
  const meTeam = mineIsA ? "A" : "B";
  const other = mineIsA ? ch.to : ch.from;
  const botHost = meHost ? [] : [bot({ name: BOTS[1]!.name, crewId: other.id, host: true, team: mineIsA ? "B" : "A" })];
  const l = makeLobby({
    name: `${ch.from.tag} vs ${ch.to.tag}`,
    mode: "crew",
    track: findTrack(ch.trackId),
    laps: ch.laps,
    vehicleClass: ch.vehicleClass,
    crewVs: { a: ch.from, b: ch.to, size: ch.teamSize, stake: ch.stake, formula: settings.crewVsFormula },
    players: [meAs(meHost, meTeam), ...botHost],
  });
  S.open.push(l);
  S.lobby = l;
  // Los equipos se completan con bots poco a poco
  const slots = ch.teamSize * 2 - l.players.length;
  for (let i = 0; i < slots; i++) {
    later(1800 + i * 1500, () => {
      if (!active(l) || l.state !== "open") return;
      const count = (t: "A" | "B") => l.players.filter((p) => p.team === t).length;
      const team = count("A") <= count("B") ? "A" : "B";
      if (count(team) >= ch.teamSize) return;
      const b = team === "A" ? ch.from : ch.to;
      l.players.push(bot({ name: BOTS[(botSeq + i) % BOTS.length]!.name, crewId: b.id, team }));
      push(l);
    });
  }
  later(1800 + slots * 1500 + 2000, function ready() {
    if (!active(l) || l.state !== "open") return;
    const p = l.players.find((x) => !x.you && !x.ready);
    if (p) p.ready = true;
    push(l);
    if (l.players.some((x) => !x.you && !x.ready)) later(1200, ready);
  });
  hostBot(l);
  return l;
}

// Resultados ----------------------------------------------------------------------------------------------------

function pastFor(h: HistoryItem): PastResults {
  const r = rng(h.id);
  const n = Math.max(6, h.position);
  const pool = [...BOTS].sort(() => r() - 0.5);
  const rows: PastResults["rows"] = [];
  let o = 0;
  for (let pos = 1; pos <= n; pos++) {
    const mine = pos === h.position;
    const b = pool[o]!;
    if (!mine) o++;
    const total = h.totalTime > 0 ? Math.round(h.totalTime * (1 + (pos - h.position) * 0.012)) : Math.round(95000 * 3 * (1 + pos * 0.012));
    const c = mine ? crewInfo(crew.id) : crewInfo(b.crewId);
    rows.push({
      position: pos,
      name: mine ? me.name : b.name,
      status: mine ? h.status : "finished",
      crew: c ? { tag: c.tag, color: c.color } : undefined,
      totalTime: mine && h.status !== "finished" ? undefined : total,
      bestLap: mine && h.status !== "finished" ? undefined : Math.round(total / 3.05),
      laps: 3,
      prize: mine ? h.prize : pos <= 3 ? [8000, 4500, 2500][pos - 1]! : 0,
      points: mine ? h.points : (settings.pilotPoints[pos - 1] ?? 0),
      crewPoints: mine ? h.crewPoints : c && pos <= 6 ? (settings.crewPointsByPosition[pos - 1] ?? 0) : 0,
      vehicle: VEHICLES[(h.id + pos) % VEHICLES.length],
    });
  }
  return { raceKey: h.raceKey, trackId: h.trackId, trackName: h.trackName, mode: h.mode, rows };
}

function buildResults(l: Lobby): RaceResults {
  const track = findTrack(l.trackId);
  const r = rng(l.id * 13 + (Date.now() % 997));
  const base = (track.referenceTime || 90000) * (track.category === "sprint" ? 1 : l.laps);
  const order = [...l.players].sort(() => r() - 0.5);
  const eligible = l.players.length >= settings.minPlayersForRewards;
  const pool = l.crewVs ? 0 : l.prizePool;
  const dnf = order.length >= 4 ? order[order.length - 1]!.pid : -1;
  const rows: ResultRow[] = order.map((p, i) => {
    const finished = p.pid !== dnf;
    const total = Math.round(base * (1 + i * 0.011 + r() * 0.008));
    const row: ResultRow = {
      pid: p.pid,
      position: i + 1,
      name: p.name,
      status: finished ? "finished" : "dnf",
      laps: finished ? l.laps : Math.max(1, l.laps - 1),
      prize: eligible && finished && !l.crewVs ? Math.floor(((pool || 0) * (config.prizeSplit[i] ?? 0)) / 100) : 0,
      points: eligible && finished && !l.crewVs ? (settings.pilotPoints[i] ?? 0) : 0,
      crewPoints: eligible && finished && p.crew && i < 6 ? (settings.crewPointsByPosition[i] ?? 0) : 0,
      vehicle: VEHICLES[(p.pid + i) % VEHICLES.length],
    };
    if (p.crew) row.crew = { tag: p.crew.tag, color: p.crew.color };
    if (p.team) row.team = p.team;
    if (finished) {
      row.totalTime = total;
      row.bestLap = Math.round(total / l.laps / (1.01 + r() * 0.02));
    }
    return row;
  });
  const best = rows[0]!;
  if (best.status === "finished" && best.bestLap && (!track.record || best.bestLap < track.record.time)) {
    best.trackRecord = true;
    if (best.pid === me.pid) track.record = { name: me.name, crewTag: crew.tag, crewColor: crew.color, time: best.bestLap, vehicle: best.vehicle ?? VEHICLES[0]! };
  }

  const results: RaceResults = { raceKey: `mock-${++seq}`, trackId: l.trackId, trackName: l.trackName, laps: l.laps, mode: l.mode, eligible, rows, at: nowSec(), you: me.pid };
  if (!l.crewVs) {
    const entries = l.entryFee * l.players.length;
    results.rewards = { entries, commission: Math.floor((entries * config.commissionPct) / 100), extra: l.extraPrize, base: track.basePrize, total: pool };
  } else {
    const score = (t: "A" | "B") => rows.filter((x) => x.team === t && x.status === "finished").reduce((s, x) => s + (settings.crewPointsByPosition[x.position - 1] ?? settings.crewFinishPoints), 0);
    const a = score("A");
    const b = score("B");
    const winner = a === b ? undefined : a > b ? "A" : "B";
    results.crewVs = { winner, scoreA: a, scoreB: b, formula: l.crewVs.formula, payout: eligible ? l.crewVs.stake * 2 : 0, points: eligible ? settings.crewVsWinPoints : 0 };
    if (winner) results.crewVs.winnerCrew = winner === "A" ? l.crewVs.a : l.crewVs.b;
  }
  return results;
}

function finishRace(l: Lobby) {
  const results = buildResults(l);
  const mine = results.rows.find((x) => x.pid === me.pid);
  if (mine) {
    const h: HistoryItem = {
      id: ++seq,
      raceKey: results.raceKey,
      trackId: results.trackId,
      trackName: results.trackName,
      mode: results.mode,
      position: mine.position,
      status: mine.status,
      totalTime: mine.totalTime ?? 0,
      bestLap: mine.bestLap ?? 0,
      prize: mine.prize,
      points: mine.points,
      crewPoints: mine.crewPoints,
      flagged: false,
      voided: false,
      createdAt: results.at,
    };
    S.history.unshift(h);
    S.past.set(results.raceKey, { raceKey: results.raceKey, trackId: results.trackId, trackName: results.trackName, mode: results.mode, rows: results.rows.map(({ pid: _pid, ...rest }) => rest) });
    S.stats.races++;
    S.stats.earnings += mine.prize;
    S.stats.points += mine.points;
    if (mine.position === 1 && mine.status === "finished") S.stats.wins++;
    if (mine.position <= 3 && mine.status === "finished") S.stats.podiums++;
    S.wallet += mine.prize;
    const prev = S.bests.get(results.trackId);
    if (mine.bestLap && (!prev || mine.bestLap < prev.bestLap)) S.bests.set(results.trackId, { bestLap: mine.bestLap, vehicle: mine.vehicle ?? VEHICLES[0]! });
  }
  S.last = results;
  S.open = S.open.filter((x) => x !== l);
  S.lobby = null;
  emitNui("results", { results });
  emitNui("lobby", { lobby: false });
}

// Rankings -----------------------------------------------------------------------------------------------------

function leaderboardRows(trackId: number): LeaderboardRow[] {
  const t = findTrack(trackId);
  const r = rng(trackId * 31);
  const rows: Omit<LeaderboardRow, "position">[] = [];
  if (t.record) {
    rows.push({ ...t.record, vehicleClass: t.vehicleClass, at: nowSec() - 5 * 86400 });
    for (let i = 0; i < 11; i++) {
      const b = BOTS[(i + trackId) % BOTS.length]!;
      const c = crewInfo(b.crewId);
      rows.push({ name: b.name, crewTag: c?.tag, crewColor: c?.color, time: Math.round(t.record.time * (1 + 0.008 * (i + 1) + r() * 0.01)), vehicle: VEHICLES[(i + trackId) % VEHICLES.length]!, vehicleClass: t.vehicleClass, at: nowSec() - (i + 6) * 86400 });
    }
  }
  const mine = S.bests.get(trackId);
  if (mine && !rows.some((x) => x.name === me.name)) rows.push({ name: me.name, crewTag: crew.tag, crewColor: crew.color, time: mine.bestLap, vehicle: mine.vehicle, vehicleClass: t.vehicleClass, at: nowSec() - 3600 });
  return rows
    .sort((a, b) => a.time - b.time)
    .slice(0, config.leaderboardSize)
    .map((x, i) => ({ ...x, position: i + 1 }));
}

function pilotRows(): PilotRankRow[] {
  const r = rng(7);
  const rows = BOTS.map((b) => {
    const c = crewInfo(b.crewId);
    const races = 20 + Math.floor(r() * 80);
    const wins = Math.floor(races * r() * 0.3);
    return { name: b.name, crewTag: c?.tag, crewColor: c?.color, races, wins, podiums: wins + Math.floor(races * r() * 0.3), points: wins * 25 + Math.floor(races * r() * 9) };
  });
  rows.push({ name: me.name, crewTag: crew.tag, crewColor: crew.color, races: S.stats.races, wins: S.stats.wins, podiums: S.stats.podiums, points: S.stats.points });
  return rows.sort((a, b) => b.points - a.points).map((x, i) => ({ ...x, position: i + 1 }));
}

function crewRows(): CrewRankRow[] {
  const rows = [
    { id: crew.id, name: crew.name, tag: crew.tag, color: crew.color, points: crew.points, wins: crew.wins, level: crew.level, members: 12 },
    ...RIVALS.map((c, i) => ({ id: c.id, name: c.name, tag: c.tag, color: c.color, points: c.points, wins: 6 + i * 3, level: c.level, members: c.members })),
  ];
  return rows.sort((a, b) => b.points - a.points).map((x, i) => ({ ...x, position: i + 1 }));
}

// Handlers ------------------------------------------------------------------------------------------------------

function checkRace(trackId: unknown, lapsIn: unknown, classIn: unknown) {
  const track = tracks.find((x) => x.id === trackId && x.enabled);
  if (!track) fail("track_not_found");
  const laps = config.pointToPoint.includes(track.category) ? 1 : int(lapsIn, 1, config.maxLaps);
  if (laps === null) fail("laps_invalid");
  const fixed = track.vehicleClass !== "any";
  const vehicleClass = fixed ? track.vehicleClass : String(classIn ?? "any");
  if ((fixed && classIn !== undefined && classIn !== track.vehicleClass) || !(fixed || config.vehicleClasses.includes(vehicleClass))) fail("class_invalid");
  return { track, laps, vehicleClass };
}

function currentState(): GameState {
  const now = Date.now();
  const strip = (list: MockChallenge[]): Challenge[] =>
    list.filter((c) => c.expiresAt > now).map(({ expiresAt, ...c }) => ({ ...c, expiresIn: Math.ceil((expiresAt - now) / 1000) }));
  const invites = [...S.invited]
    .filter(([id, exp]) => exp > now && S.open.some((l) => l.id === id && l.state === "open"))
    .map(([id, exp]) => {
      const l = S.open.find((x) => x.id === id)!;
      return { lobbyId: id, name: l.name, trackName: l.trackName, hostName: l.hostName, expiresIn: Math.ceil((exp - now) / 1000) };
    });
  return structuredClone({
    ...gameState,
    lobby: S.lobby ? view(S.lobby) : null,
    invites,
    challenges: { incoming: strip(S.incoming), outgoing: strip(S.outgoing) },
    hasResult: S.last !== null,
  });
}

export const playerHandlers: Record<string, Handler> = {
  getState: () => currentState(),

  listTracks: (d) => listTracks(d, false),
  getTrack: (d) => {
    const t = tracks.find((x) => x.id === d.id && x.enabled);
    if (!t) fail("track_not_found");
    return trackDetail(t, false);
  },
  getLeaderboard: (d) => {
    const t = findTrack(Number(d.trackId));
    return { track: { id: t.id, name: t.name, version: t.version }, rows: leaderboardRows(t.id) };
  },
  getPilotRanking: () => ({ rows: pilotRows() }),
  getCrewRanking: () => ({ enabled: config.crewsEnabled, rows: crewRows() }),
  getStats: () => ({
    stats: { ...S.stats },
    bests: [...S.bests].map(([trackId, b]) => ({ trackId, trackName: findTrack(trackId).name, bestLap: b.bestLap, vehicle: b.vehicle })),
  }),
  getHistory: (d) => {
    const page = int(d.page, 1, 100000) ?? 1;
    const size = config.pageSize;
    return { items: S.history.slice((page - 1) * size, page * size), total: S.history.length, page, pageSize: size };
  },
  getLastResult: () => S.last,
  getRaceResults: (d) => {
    const h = S.history.find((x) => x.raceKey === d.raceKey);
    if (!h) fail("result_not_found");
    return S.past.get(h.raceKey) ?? pastFor(h);
  },

  listRaces: () => {
    const now = Date.now();
    const races: LobbySummary[] = S.open
      .filter((l) => l.state === "open" && (!l.private || S.invited.has(l.id) || l.isHost))
      .sort((a, b) => Number(b.official) - Number(a.official) || b.id - a.id)
      .map(({ players, ...rest }) => ({ ...structuredClone(rest), playerCount: players.length, invited: (S.invited.get(rest.id) ?? 0) > now }));
    return { races, invites: currentState().invites };
  },
  createRace: (d: Partial<CreateRaceInput>) => {
    if (S.lobby) fail("already_in_race");
    const { track, laps, vehicleClass } = checkRace(d.trackId, d.laps, d.vehicleClass);
    const fee = int(d.entryFee ?? 0, 0, config.entryFeeMax);
    const extra = int(d.extraPrize ?? 0, 0, config.extraPrizeMax);
    if (fee === null || extra === null) fail("invalid_data");
    const name = d.name === undefined ? track.name : String(d.name).trim();
    if (name.length < 3 || name.length > 48) fail("name_invalid");
    if (S.wallet < fee + extra) fail("no_money");
    S.wallet -= fee + extra;
    const l = makeLobby({ name, mode: "open", track, laps, vehicleClass, entryFee: fee, extraPrize: extra, private: d.private === true, players: [meAs(true)] });
    S.open.push(l);
    S.lobby = l;
    push(l);
    animateLobby(l, 2);
    return view(l);
  },
  joinRace: (d) => {
    if (S.lobby) fail("already_in_race");
    const l = S.open.find((x) => x.id === d.id && x.state === "open");
    if (!l) fail("race_not_found");
    if (l.mode === "crew") fail("not_crew_member");
    if (l.private && !S.invited.has(l.id)) fail("private_race");
    if (l.players.length >= l.maxPlayers) fail("race_full");
    if (S.wallet < l.entryFee) fail("no_money");
    S.wallet -= l.entryFee;
    S.invited.delete(l.id);
    l.players.push(meAs(false));
    S.lobby = l;
    push(l);
    animateLobby(l, 1);
    return view(l);
  },
  leaveRace: () => {
    if (!S.lobby) fail("not_in_race");
    leaveCurrent();
    return {};
  },
  setReady: (d) => {
    const l = S.lobby;
    if (!l) fail("not_in_race");
    if (l.state !== "open") fail("race_starting");
    const p = l.players.find((x) => x.you);
    if (p && !p.host) p.ready = d.ready === true;
    push(l);
    return {};
  },
  startRace: () => {
    const l = S.lobby;
    if (!l) fail("not_in_race");
    if (!l.isHost) fail("no_permission");
    if (l.state !== "open") fail("race_starting");
    if (l.crewVs) {
      const a = l.players.filter((p) => p.team === "A").length;
      if (a !== l.players.length - a || a === 0) fail("teams_unbalanced");
    }
    if (!l.players.every((p) => p.ready)) fail("players_not_ready");
    beginRace(l);
    return {};
  },
  kickPlayer: (d) => {
    const l = S.lobby;
    if (!l) fail("not_in_race");
    if (!l.isHost) fail("no_permission");
    const p = l.players.find((x) => x.pid === d.pid);
    if (!p) fail("target_not_found");
    if (p.you) fail("cannot_self");
    l.players = l.players.filter((x) => x !== p);
    push(l);
    return {};
  },
  invitePlayer: (d) => {
    const l = S.lobby;
    const pid = int(d.pid, 1, 2147483647);
    if (!pid) fail("invalid_data");
    if (!l) fail("not_in_race");
    if (!l.isHost) fail("no_permission");
    if (pid === me.pid) fail("cannot_self");
    if (pid >= 200) fail("target_not_found");
    if (l.players.some((p) => p.pid === pid)) fail("target_busy");
    later(2000, () => {
      if (!active(l) || l.state !== "open" || l.players.length >= l.maxPlayers) return;
      l.players.push({ ...bot({ name: `Invitado #${pid}` }), pid });
      push(l);
    });
    return {};
  },

  listCrews: (d) => {
    if (!config.crewsEnabled) fail("crews_disabled");
    const q = String(d.search ?? "").toLowerCase();
    const items: CrewListItem[] = RIVALS.filter((c) => !q || c.name.toLowerCase().includes(q) || c.tag.toLowerCase().includes(q))
      .map(({ id, name, tag, color, level, points, members }) => ({ id, name, tag, color, level, points, members }))
      .sort((a, b) => b.points - a.points);
    return { items };
  },
  challengeCrew: (d) => {
    if (!config.crewsEnabled) fail("crews_disabled");
    if (!crew.canChallenge) fail("no_permission");
    if (S.lobby) fail("already_in_race");
    const target = RIVALS.find((c) => c.id === d.crewId);
    if (!target) fail("crew_not_found");
    const { track, laps, vehicleClass } = checkRace(d.trackId, d.laps, d.vehicleClass);
    if (!track.allowCrews) fail("track_no_crews");
    const teamSize = int(d.teamSize, 1, config.crewVs.maxTeamSize);
    const stake = int(d.stake ?? 0, 0, config.crewVs.stakeMax);
    if (teamSize === null || stake === null) fail("invalid_data");
    if (track.grid.length < teamSize * 2) fail("grid_too_small");
    if (stake > 120000) fail("crew_no_funds");
    if (S.outgoing.some((c) => c.expiresAt > Date.now())) fail("challenge_exists");
    const ch: MockChallenge = { id: ++seq, from: myCrewBrief, to: brief(target), fromName: me.name, trackId: track.id, trackName: track.name, laps, vehicleClass, teamSize, stake, expiresIn: 0, expiresAt: Date.now() + 120000 };
    S.outgoing.push(ch);
    // El crew rival acepta pasados unos segundos
    later(7000, () => {
      if (!S.outgoing.includes(ch)) return;
      S.outgoing = S.outgoing.filter((c) => c !== ch);
      if (!S.lobby) {
        const l = crewLobby(ch, true);
        emitNui("lobby", { lobby: view(l) });
      }
      emitNui("refresh");
    });
    const { expiresAt, ...out } = ch;
    return { ...out, expiresIn: Math.ceil((expiresAt - Date.now()) / 1000) };
  },
  respondChallenge: (d) => {
    const ch = S.incoming.find((c) => c.id === d.id && c.expiresAt > Date.now());
    if (!ch) fail("challenge_not_found");
    if (d.accept === true && S.lobby) fail("already_in_race");
    S.incoming = S.incoming.filter((c) => c !== ch);
    if (d.accept !== true) return {};
    const l = crewLobby(ch, false);
    push(l);
    return { lobbyId: l.id };
  },
  cancelChallenge: (d) => {
    const ch = S.outgoing.find((c) => c.id === d.id);
    if (!ch) fail("challenge_not_found");
    S.outgoing = S.outgoing.filter((c) => c !== ch);
    return {};
  },
};
