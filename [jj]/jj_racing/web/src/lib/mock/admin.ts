import type {
  AdminRace,
  AdminResultRow,
  DraftCheckpoint,
  EventInput,
  EventItem,
  LeaderboardPayload,
  LeaderboardRow,
  LogRow,
  RaceSettings,
  TestResult,
  TrackDraft,
} from "@/lib/types";
import { emitNui } from "@/lib/nui";
import { invalidSettings } from "@/views/admin/settingsSchema";
import { MockError, config, findTrack, gameState, listTracks, pathLength, settings, trackDetail, tracks, wait, type Handler, type MockTrack } from "./db";

const now = () => Math.floor(Date.now() / 1000);
const isInt = (v: unknown, min: number, max: number): v is number => typeof v === "number" && Number.isInteger(v) && v >= min && v <= max;
const inRange = (v: unknown, min: number, max: number): v is number => typeof v === "number" && Number.isFinite(v) && v >= min && v <= max;
const round = (n: number, d: number) => Math.round(n * 10 ** d) / 10 ** d;

/** Generador pseudoaleatorio determinista para los datos de ejemplo */
function rng(seed: number) {
  let s = seed;
  return () => {
    s = (s * 1664525 + 1013904223) % 4294967296;
    return s / 4294967296;
  };
}
const pick = <T,>(r: () => number, list: T[]): T => list[Math.floor(r() * list.length)]!;

// Logs ---------------------------------------------------------------------------------------------------

const ACTOR = { cid: "ABC12345", name: "Alex Ruiz" };
const logs: LogRow[] = [];
let logSeq = 0;

function addLog(action: string, details: Record<string, unknown>, at = now(), actor = ACTOR, isAdmin = true) {
  logs.unshift({ id: ++logSeq, actorCid: actor.cid, actorName: actor.name, action, details, isAdmin, createdAt: at });
}

(function seedLogs() {
  const r = rng(11);
  const people = [ACTOR, { cid: "QWE98765", name: "Dani Moreno" }, { cid: "ZXC45612", name: "Laura Vega" }, { cid: "RTY33210", name: "Kira Tanaka" }];
  const actions = [
    "track_create", "track_save", "track_duplicate", "track_enable", "track_disable", "track_test", "race_create", "race_cancel", "race_result", "race_dq",
    "new_record", "result_void", "result_approve", "settings_save", "event_create", "event_start", "crew_export", "crew_export", "challenge_create",
    "challenge_accept", "challenge_decline", "escrow_recover", "race_kick", "record_void", "track_export",
  ];
  const adminActions = ["track_create", "track_save", "settings_save", "track_enable", "result_void"];
  for (let i = 0; i < 60; i++) {
    const action = pick(r, actions);
    const who = pick(r, people);
    const track = pick(r, tracks).name;
    let details: Record<string, unknown> = { lobby: 100 + Math.floor(r() * 50), track };
    if (action === "crew_export") details = { export: pick(r, ["GetCrewByMember", "AddCrewPoints", "GetCrewMembers"]), crewId: 1 + Math.floor(r() * 4), caller: "races" };
    else if (action.startsWith("track_")) details = { id: 1 + Math.floor(r() * 6), name: track };
    else if (action === "settings_save") details = { keys: "commissionPct,maxLaps" };
    else if (action === "race_dq" || action === "race_kick") details = { lobby: 100 + Math.floor(r() * 50), player: who.name, reason: "strikes" };
    else if (action === "new_record") details = { track, time: `1:${String(10 + Math.floor(r() * 40)).padStart(2, "0")}.${String(Math.floor(r() * 999)).padStart(3, "0")}`, player: who.name };
    addLog(action, details, now() - (i * 2100 + Math.floor(r() * 1800)), who, adminActions.includes(action));
  }
})();

// Circuitos ---------------------------------------------------------------------------------------------------

function routeSignature(cps: DraftCheckpoint[], grid: { x: number; y: number; z: number }[]): string {
  return [...cps.map((c) => `${c.kind}:${c.x}:${c.y}:${c.z}:${c.linkFrom ?? ""}:${c.linkTo ?? ""}`), ...grid.map((g) => `g:${g.x}:${g.y}:${g.z}`)].join("|");
}

interface Clean {
  name: string;
  category: string;
  difficulty: string;
  description: string;
  lapsDefault: number;
  vehicleClass: string;
  allowCrews: boolean;
  collisions: boolean;
  basePrize: number;
  timeLimit: number;
  checkpoints: DraftCheckpoint[];
  grid: { x: number; y: number; z: number; h: number }[];
}

function fail(msg: string, code: string): never {
  throw new MockError(msg, code);
}

/** Espejo de Validation.Track */
function validate(d: Partial<TrackDraft>): Clean {
  const cr = config.creator;
  const name = typeof d.name === "string" ? d.name.trim() : "";
  if (name.length < 3 || name.length > 48) fail("Nombre no válido (3-48 caracteres, sin símbolos especiales).", "name_invalid");
  if (!d.category || !config.categories.includes(d.category)) fail("Categoría no válida.", "category_invalid");
  if (!d.difficulty || !config.difficulties.includes(d.difficulty)) fail("Dificultad no válida.", "difficulty_invalid");
  const description = d.description ?? "";
  if (typeof description !== "string" || description.length > 255) fail("Datos inválidos.", "invalid_data");
  const lapsDefault = config.pointToPoint.includes(d.category!) ? 1 : d.lapsDefault;
  if (!isInt(lapsDefault, 1, settings.maxLaps)) fail("Número de vueltas no válido.", "laps_invalid");
  if (!d.vehicleClass || !config.allVehicleClasses.includes(d.vehicleClass)) fail("Clase de vehículo no permitida para este circuito.", "class_invalid");
  if (typeof d.allowCrews !== "boolean" || typeof d.collisions !== "boolean") fail("Datos inválidos.", "invalid_data");
  if (!isInt(d.basePrize, 0, settings.baseMaxPrize)) fail("Premio fuera de los límites permitidos.", "prize_invalid");
  if (!isInt(d.timeLimit, 0, 86400)) fail("Datos inválidos.", "invalid_data");

  const src = d.checkpoints;
  if (!Array.isArray(src) || src.length < 2 || src.length > cr.maxCheckpoints) fail("Número de checkpoints no válido.", "checkpoints_invalid");
  const cps: DraftCheckpoint[] = [];
  let normals = 0;
  for (const c of src!) {
    const okKind = c.kind === "normal" || c.kind === "shortcut" || c.kind === "pit";
    if (!okKind || !inRange(c.x, -12000, 12000) || !inRange(c.y, -12000, 12000) || !inRange(c.z, -500, 3000) || !inRange(c.radius, cr.minRadius, cr.maxRadius) || !inRange(c.height, cr.minHeight, cr.maxHeight))
      fail("Algún checkpoint tiene datos no válidos.", "checkpoint_invalid");
    if (c.kind === "normal") normals++;
    const out: DraftCheckpoint = { kind: c.kind, x: round(c.x, 2), y: round(c.y, 2), z: round(c.z, 2), radius: round(c.radius, 1), height: round(c.height, 1) };
    if (c.kind === "shortcut") {
      if (!isInt(c.linkFrom, 1, 1000) || !isInt(c.linkTo, 2, 1000)) fail("Un atajo debe enlazar dos checkpoints saltándose al menos uno.", "shortcut_invalid");
      out.linkFrom = c.linkFrom;
      out.linkTo = c.linkTo;
    }
    cps.push(out);
  }
  if (normals < 2) fail("Se necesitan al menos 2 checkpoints normales.", "too_few_checkpoints");
  for (const c of cps) if (c.kind === "shortcut" && (c.linkTo! < c.linkFrom! + 2 || c.linkTo! > normals)) fail("Un atajo debe enlazar dos checkpoints saltándose al menos uno.", "shortcut_invalid");

  const gridSrc = d.grid;
  if (!Array.isArray(gridSrc) || gridSrc.length < 1 || gridSrc.length > cr.maxGrid) fail("La parrilla de salida no es válida.", "grid_invalid");
  const grid = gridSrc!.map((g) => {
    if (!inRange(g.x, -12000, 12000) || !inRange(g.y, -12000, 12000) || !inRange(g.z, -500, 3000) || !inRange(g.h, -360, 720)) fail("La parrilla de salida no es válida.", "grid_invalid");
    return { x: round(g.x, 2), y: round(g.y, 2), z: round(g.z, 2), h: round(((g.h % 360) + 360) % 360, 1) };
  });
  return {
    name, category: d.category!, difficulty: d.difficulty!, description, lapsDefault: lapsDefault as number, vehicleClass: d.vehicleClass!,
    allowCrews: d.allowCrews!, collisions: d.collisions!, basePrize: d.basePrize!, timeLimit: d.timeLimit!, checkpoints: cps, grid,
  };
}

const nameTaken = (name: string, exceptId?: number) => tracks.some((t) => t.id !== exceptId && t.name.toLowerCase() === name.toLowerCase());

function uniqueName(base: string): string {
  if (!nameTaken(base)) return base;
  for (let i = 2; i < 100; i++) {
    const suffix = ` (${i})`;
    const c = `${base.slice(0, 48 - suffix.length)}${suffix}`;
    if (!nameTaken(c)) return c;
  }
  return `${base.slice(0, 40)}-${Math.floor(Math.random() * 900 + 100)}`;
}

function assertNotInUse(t: MockTrack) {
  if (t.inUse) fail("El circuito está siendo usado en una carrera.", "track_in_use");
}

function saveTrack(d: Partial<TrackDraft>): { track: MockTrack; bumped: boolean } {
  const clean = validate(d);
  const existing = d.id != null ? findTrack(d.id) : undefined;
  if (existing) assertNotInUse(existing);
  if (nameTaken(clean.name, existing?.id)) fail("Ya existe un circuito con ese nombre.", "name_taken");

  if (!existing) {
    const t: MockTrack = {
      ...clean, id: Math.max(0, ...tracks.map((x) => x.id)) + 1, enabled: false, version: 1, testedVersion: 0, tested: false, referenceTime: 0,
      updatedAt: now(), inUse: false, record: null,
    };
    tracks.push(t);
    addLog("track_create", { id: t.id, name: t.name });
    return { track: t, bumped: false };
  }
  const changed = routeSignature(clean.checkpoints, clean.grid) !== routeSignature(existing.checkpoints, existing.grid);
  const bump = changed && d.minor !== true;
  Object.assign(existing, clean, { updatedAt: now() });
  if (bump) {
    existing.version += 1;
    existing.referenceTime = 0;
    existing.record = null;
    if (config.creator.requireTest) existing.enabled = false;
  }
  existing.tested = existing.testedVersion === existing.version;
  addLog("track_save", { id: existing.id, name: existing.name, version: existing.version, newVersion: bump });
  return { track: existing, bumped: bump };
}

function exportTable(t: MockTrack) {
  return {
    format: "races.track", schema: 1, name: t.name, category: t.category, difficulty: t.difficulty, description: t.description, lapsDefault: t.lapsDefault,
    vehicleClass: t.vehicleClass, allowCrews: t.allowCrews, basePrize: t.basePrize, timeLimit: t.timeLimit, collisions: t.collisions,
    checkpoints: t.checkpoints.map((c) => ({ kind: c.kind, x: c.x, y: c.y, z: c.z, radius: c.radius, height: c.height, linkFrom: c.linkFrom, linkTo: c.linkTo })),
    grid: t.grid,
  };
}

// Clasificaciones (para anular records) ----------------------------------------------------------------------

const boards = new Map<number, LeaderboardRow[]>();

function board(t: MockTrack): LeaderboardRow[] {
  const cached = boards.get(t.id);
  if (cached) return cached;
  const r = rng(t.id * 97);
  const base = t.record?.time ?? (t.referenceTime || 90000);
  const names = ["Dani Moreno", "Laura Vega", "Kira Tanaka", "Pablo Núñez", "Alex Ruiz", "Marta Gil", "Iván Soto", "Nora Blanco"].filter((n) => n !== t.record?.name);
  if (t.record) names.unshift(t.record.name);
  let time = base;
  const rows: LeaderboardRow[] = names.map((name, i) => ({
    position: i + 1,
    citizenid: `CID${1000 + i * 37 + t.id}`,
    name,
    crewTag: i % 3 === 0 ? "APX" : i % 3 === 1 ? "NOS" : undefined,
    crewColor: i % 3 === 0 ? "#a855f7" : i % 3 === 1 ? "#3b82f6" : undefined,
    time: (time += i === 0 ? 0 : Math.round(400 + r() * 1800)),
    vehicle: pick(r, ["Pfister Comet", "Karin Futo", "Annis Elegy RH8", "Bravado Buffalo", "Grotti Itali GTO"]),
    vehicleClass: t.vehicleClass,
    at: now() - Math.floor(r() * 20) * 86400,
  }));
  boards.set(t.id, rows);
  return rows;
}

// Carreras activas ----------------------------------------------------------------------------------------------

type RacePlayer = AdminRace["players"][number];

function player(pid: number, name: string, extra: Partial<RacePlayer> = {}): RacePlayer {
  return { pid, name, ready: true, host: false, you: false, status: "waiting", strikes: 0, paid: 0, ...extra };
}

const apx = { tag: "APX", color: "#a855f7", name: "Apex Syndicate" };
const nos = { tag: "NOS", color: "#3b82f6", name: "Nitro Union" };

const races: AdminRace[] = [
  {
    id: 101, name: "Quedada Vinewood", mode: "open", state: "open", trackId: 1, trackName: "Vinewood Hills GP", category: "circuit", difficulty: "medium", collisions: true,
    laps: 3, vehicleClass: "any", entryFee: 500, extraPrize: 2000, prizePool: 3500, private: false, maxPlayers: 12, official: false, hostName: "Dani Moreno", isHost: false, you: 0,
    players: [player(12, "Dani Moreno", { host: true, crew: apx, paid: 500 }), player(5, "Kira Tanaka", { paid: 500 }), player(9, "Pablo Núñez", { crew: nos, ready: false, paid: 500 })],
  },
  {
    id: 102, name: "Docks Showdown", mode: "crew", state: "countdown", trackId: 4, trackName: "Docks Street Race", category: "street", difficulty: "extreme", collisions: true, laps: 2,
    vehicleClass: "sports", entryFee: 0, extraPrize: 0, prizePool: 20000, private: true, maxPlayers: 4, official: false, hostName: "Laura Vega", isHost: false, you: 0,
    crewVs: { a: { id: 1, ...apx }, b: { id: 2, ...nos }, size: 2, stake: 10000, formula: "points" },
    players: [
      player(3, "Laura Vega", { host: true, team: "B", crew: nos, status: "ready", paid: 10000 }),
      player(8, "Marta Gil", { team: "B", crew: nos, status: "ready", paid: 10000 }),
      player(14, "Iván Soto", { team: "A", crew: apx, status: "ready", paid: 10000, strikes: 1 }),
      player(2, "Nora Blanco", { team: "A", crew: apx, status: "ready", paid: 10000 }),
    ],
  },
  {
    id: 103, name: "Sprint nocturno", mode: "official", state: "running", trackId: 2, trackName: "Del Perro Sprint", category: "sprint", difficulty: "easy", collisions: false, laps: 1,
    vehicleClass: "sports", entryFee: 0, extraPrize: 0, prizePool: 25000, private: false, maxPlayers: 12, official: true, hostName: "Oficial", isHost: false, you: 0, startedAt: 74,
    players: [player(6, "Alex Ruiz", { status: "racing" }), player(10, "Carla Mena", { status: "racing", strikes: 2 }), player(11, "Rubén Díaz", { status: "finished" })],
  },
];

// Eventos -------------------------------------------------------------------------------------------------------

/** Un circuito esta en uso mientras haya una sala sobre el */
function syncInUse() {
  for (const t of tracks) t.inUse = races.some((r) => r.trackId === t.id);
}
syncInUse();

const events: EventItem[] = [
  { id: 3, trackId: 1, trackName: "Vinewood Hills GP", title: "Gran Premio de fin de semana", laps: 3, vehicleClass: "any", prize: 50000, scheduledAt: now() + 2 * 86400, status: "scheduled" },
  { id: 2, trackId: 4, trackName: "Docks Street Race", title: "Noche de calle", laps: 2, vehicleClass: "sports", prize: 25000, scheduledAt: now() - 3 * 86400, status: "done" },
  { id: 1, trackId: 5, trackName: "Mirror Park Circular", title: "Copa del lago", laps: 3, vehicleClass: "any", prize: 10000, scheduledAt: now() - 9 * 86400, status: "cancelled" },
];

// Resultados -------------------------------------------------------------------------------------------------------

const results: AdminResultRow[] = (() => {
  const r = rng(5);
  const names = ["Dani Moreno", "Laura Vega", "Kira Tanaka", "Pablo Núñez", "Alex Ruiz", "Marta Gil", "Iván Soto", "Nora Blanco"];
  const reasons = ["Velocidad imposible entre checkpoints", "Checkpoint saltado", "Tiempo muy inferior al de referencia", "Teletransporte detectado", "Atajo no registrado"];
  const flaggedAt = new Set([2, 6, 11, 15, 22, 27]);
  return Array.from({ length: 30 }, (_, i): AdminResultRow => {
    const name = names[i % names.length]!;
    const t = tracks[i % 5]!;
    const status = r() < 0.12 ? "dnf" : "finished";
    const flagged = flaggedAt.has(i);
    return {
      id: 500 - i, raceKey: `r${700 - i}`, trackId: t.id, trackName: t.name, mode: i % 7 === 0 ? "official" : "open", citizenid: `CID${1000 + (i % names.length) * 37}`, name,
      crewTag: i % 3 === 0 ? "APX" : undefined, position: 1 + Math.floor(r() * 6), status,
      totalTime: status === "dnf" ? 0 : Math.round(t.referenceTime * (flagged ? 0.55 : 1 + r() * 0.2) * 3),
      bestLap: status === "dnf" ? 0 : Math.round(t.referenceTime * (flagged ? 0.55 : 1 + r() * 0.1)), prize: r() < 0.5 ? Math.round(r() * 8) * 500 : 0, flagged,
      flagReason: flagged ? reasons[i % reasons.length]! : "", voided: false, voidReason: "", createdAt: now() - i * 5400,
    };
  });
})();

// Ajustes -------------------------------------------------------------------------------------------------------------

function applySettings(s: RaceSettings) {
  Object.assign(settings, s);
  Object.assign(config, {
    maxLaps: s.maxLaps, maxPlayers: s.maxPlayers, countdownSeconds: s.countdownSeconds, entryFeeMax: s.entryFeeMax, extraPrizeMax: s.extraPrizeMax,
    baseMaxPrize: s.baseMaxPrize, commissionPct: s.commissionPct, prizeSplit: s.prizeSplit,
    vehicleClasses: config.allVehicleClasses.filter((c) => s.allowedClasses.includes(c)),
  });
  Object.assign(config.crewVs, { stakeMax: s.crewVsStakeMax, formula: s.crewVsFormula, minRank: s.crewVsMinRank });
}

function paginate<T>(list: T[], page?: number) {
  const p = Math.max(1, page ?? 1);
  const size = config.pageSize;
  return { items: list.slice((p - 1) * size, p * size), total: list.length, page: p, pageSize: size };
}

const reasonOf = (v: unknown): string => {
  const s = typeof v === "string" ? v.trim() : "";
  if (s.length < 3) fail("Debes indicar un motivo (mínimo 3 caracteres).", "reason_required");
  return s;
};
const idOf = (v: unknown): number => {
  if (!isInt(v, 1, 2147483647)) fail("Datos inválidos.", "invalid_data");
  return v as number;
};

// Handlers ---------------------------------------------------------------------------------------------------------------

export const adminHandlers: Record<string, Handler> = {
  adminListTracks: (d) => listTracks(d, true),

  adminGetTrack: (d) => trackDetail(findTrack(idOf(d.id)), true),

  adminSaveTrack: async (d: TrackDraft) => {
    await wait(250);
    const { track, bumped } = saveTrack(d);
    return { track: trackDetail(track, true), newVersion: bumped };
  },

  adminDuplicateTrack: (d) => {
    const src = findTrack(idOf(d.id));
    const copy: Partial<TrackDraft> = { ...exportTable(src), name: uniqueName(`${src.name} copy`.slice(0, 48)) };
    const { track } = saveTrack(copy);
    addLog("track_duplicate", { from: src.id, to: track.id });
    return { track: trackDetail(track, true) };
  },

  adminToggleTrack: (d) => {
    const t = findTrack(idOf(d.id));
    if (typeof d.enabled !== "boolean") fail("Datos inválidos.", "invalid_data");
    if (d.enabled && config.creator.requireTest && t.testedVersion !== t.version) fail("Debes completar una prueba de la versión actual antes de publicar el circuito.", "track_untested");
    t.enabled = d.enabled;
    addLog(d.enabled ? "track_enable" : "track_disable", { id: t.id, name: t.name });
    return {};
  },

  adminDeleteTrack: (d) => {
    const t = findTrack(idOf(d.id));
    assertNotInUse(t);
    tracks.splice(tracks.indexOf(t), 1);
    boards.delete(t.id);
    addLog("track_delete", { id: t.id, name: t.name });
    return {};
  },

  adminExportTrack: (d) => {
    const t = findTrack(idOf(d.id));
    addLog("track_export", { id: t.id, name: t.name });
    return { json: JSON.stringify(exportTable(t)) };
  },

  adminImportTrack: (d: { json?: unknown }) => {
    const invalid = () => fail("El JSON importado no es un circuito válido.", "import_invalid");
    if (typeof d.json !== "string" || d.json.length === 0 || d.json.length > 262144) invalid();
    let data: Partial<TrackDraft> & { format?: string; schema?: number };
    try {
      data = JSON.parse(d.json as string) as typeof data;
    } catch {
      return invalid();
    }
    if (!data || typeof data !== "object" || data.format !== "races.track" || data.schema !== 1) invalid();
    if (typeof data.name !== "string" || data.name.trim().length < 3) fail("Nombre no válido (3-48 caracteres, sin símbolos especiales).", "name_invalid");
    data.id = undefined;
    data.name = uniqueName(data.name!.trim().slice(0, 48));
    if (typeof data.basePrize === "number") data.basePrize = Math.min(Math.max(0, Math.floor(data.basePrize)), settings.baseMaxPrize);
    if (typeof data.lapsDefault === "number") data.lapsDefault = Math.min(Math.max(1, Math.floor(data.lapsDefault)), settings.maxLaps);
    if (typeof data.vehicleClass !== "string" || !config.allVehicleClasses.includes(data.vehicleClass)) data.vehicleClass = "any";
    const { track } = saveTrack(data);
    addLog("track_import", { id: track.id, name: track.name });
    return { track: trackDetail(track, true) };
  },

  adminTestTrack: (d) => {
    const t = findTrack(idOf(d.id));
    const time = Math.round(60000 + pathLength(t) * 12 + Math.random() * 4000);
    t.referenceTime = t.testedVersion === t.version && t.referenceTime > 0 ? Math.min(t.referenceTime, time) : time;
    t.testedVersion = t.version;
    t.tested = true;
    addLog("track_test", { id: t.id, name: t.name, version: t.version });
    // Emula que el panel se cierra, se corre la prueba y se reabre con el resultado
    const result: TestResult = { ok: true, time, reference: t.referenceTime, trackId: t.id };
    emitNui("close");
    setTimeout(() => emitNui("open", { view: "admin", state: gameState, extra: { tab: "tracks", testResult: result } }), 2500);
    return {};
  },

  adminLeaderboard: (d): LeaderboardPayload => {
    const t = findTrack(idOf(d.trackId));
    return { track: { id: t.id, name: t.name, version: t.version }, rows: board(t).map((x) => ({ ...x })) };
  },

  adminVoidRecord: (d) => {
    const t = findTrack(idOf(d.trackId));
    const reason = reasonOf(d.reason);
    const rows = board(t);
    const i = rows.findIndex((x) => x.citizenid === d.citizenid);
    if (i < 0) fail("Resultado no encontrado.", "result_not_found");
    const [gone] = rows.splice(i, 1);
    rows.forEach((x, n) => (x.position = n + 1));
    const first = rows[0];
    t.record = first ? { name: first.name, crewTag: first.crewTag, crewColor: first.crewColor, time: first.time, vehicle: first.vehicle } : null;
    addLog("record_void", { track: t.name, citizenid: gone!.citizenid, reason });
    return {};
  },

  adminListRaces: () => ({ races: races.map((r) => ({ ...r, players: r.players.map((p) => ({ ...p })) })) }),

  adminCancelRace: (d) => {
    const i = races.findIndex((r) => r.id === d.id);
    if (i < 0) fail("La carrera ya no existe o ha empezado.", "race_not_found");
    const reason = reasonOf(d.reason);
    const [r] = races.splice(i, 1);
    syncInUse();
    addLog("race_cancel", { lobby: r!.id, track: r!.trackName, reason });
    return {};
  },

  adminKickPlayer: (d) => {
    const r = races.find((x) => x.id === d.raceId);
    if (!r) return fail("La carrera ya no existe o ha empezado.", "race_not_found");
    const reason = reasonOf(d.reason);
    const i = r.players.findIndex((p) => p.pid === d.pid);
    if (i < 0) fail("El jugador no está conectado.", "target_not_found");
    const [p] = r.players.splice(i, 1);
    addLog("race_kick", { lobby: r.id, player: p!.name, refund: d.refund === true, reason });
    return {};
  },

  adminListEvents: () => ({ items: [...events].sort((a, b) => b.scheduledAt - a.scheduledAt) }),

  adminSaveEvent: (d: EventInput) => {
    const t = tracks.find((x) => x.id === d.trackId);
    if (!t || !t.enabled) return fail("El circuito no existe o no está activo.", "track_not_found");
    const title = typeof d.title === "string" ? d.title.trim() : "";
    if (title.length < 3 || title.length > 64) fail("Datos inválidos.", "invalid_data");
    const laps = config.pointToPoint.includes(t.category) ? 1 : d.laps;
    if (!isInt(laps, 1, settings.maxLaps)) fail("Número de vueltas no válido.", "laps_invalid");
    if (!config.allVehicleClasses.includes(d.vehicleClass) || (t.vehicleClass !== "any" && d.vehicleClass !== t.vehicleClass) || !settings.allowedClasses.includes(d.vehicleClass))
      fail("Clase de vehículo no permitida para este circuito.", "class_invalid");
    if (!isInt(d.prize ?? 0, 0, config.eventsMaxPrize) || !isInt(d.scheduledAt, now() + 30, now() + 60 * 86400)) fail("Datos del evento no válidos (fecha o premio fuera de rango).", "event_invalid");
    const e: EventItem = {
      id: Math.max(0, ...events.map((x) => x.id)) + 1, trackId: t.id, trackName: t.name, title, laps: laps as number, vehicleClass: d.vehicleClass,
      prize: d.prize ?? 0, scheduledAt: d.scheduledAt, status: "scheduled",
    };
    events.push(e);
    addLog("event_create", { id: e.id, title, track: t.name, prize: e.prize });
    return { id: e.id };
  },

  adminCancelEvent: (d) => {
    const e = events.find((x) => x.id === d.id);
    if (!e || e.status !== "scheduled") return fail("Datos del evento no válidos (fecha o premio fuera de rango).", "event_invalid");
    e.status = "cancelled";
    addLog("event_cancel", { id: e.id, title: e.title });
    return {};
  },

  adminListResults: (d: { flaggedOnly?: boolean; search?: string; page?: number }) => {
    const q = (d.search ?? "").trim().toLowerCase();
    const list = results.filter((r) => (!d.flaggedOnly || r.flagged) && (!q || [r.name, r.citizenid, r.trackName].some((s) => s.toLowerCase().includes(q))));
    return paginate(list, d.page);
  },

  adminVoidResult: (d) => {
    const id = idOf(d.id);
    const reason = reasonOf(d.reason);
    const r = results.find((x) => x.id === id);
    if (!r) return fail("Resultado no encontrado.", "result_not_found");
    if (r.voided) fail("Ese resultado ya está anulado.", "already_voided");
    r.voided = true;
    r.voidReason = reason;
    addLog("result_void", { id: r.id, player: r.name, reason });
    return {};
  },

  adminApproveResult: (d) => {
    const r = results.find((x) => x.id === idOf(d.id));
    if (!r) return fail("Resultado no encontrado.", "result_not_found");
    r.flagged = false;
    r.flagReason = "";
    addLog("result_approve", { id: r.id, player: r.name });
    return {};
  },

  adminGetSettings: () => ({ settings: structuredClone(settings), allClasses: [...config.allVehicleClasses] }),

  adminSaveSettings: (d: { settings?: RaceSettings }) => {
    const s = d.settings;
    if (!s || typeof s !== "object") return fail("Datos inválidos.", "invalid_data");
    const bad = invalidSettings(s);
    if (bad.length) fail(`Ajuste no válido: ${bad[0]}`, "setting_invalid");
    const changed = (Object.keys(s) as (keyof RaceSettings)[]).filter((k) => JSON.stringify(s[k]) !== JSON.stringify(settings[k]));
    applySettings(structuredClone(s));
    if (changed.length) addLog("settings_save", { keys: changed.join(",") });
    return { settings: structuredClone(settings) };
  },

  adminLogs: (d: { action?: string; search?: string; page?: number }) => {
    const q = (d.search ?? "").trim().toLowerCase();
    const list = logs.filter((l) => (!d.action || l.action === d.action) && (!q || `${l.actorName} ${l.actorCid} ${l.action} ${JSON.stringify(l.details)}`.toLowerCase().includes(q)));
    return paginate(list, d.page);
  },

  /** Emula la ida y vuelta al editor del mundo: el panel se cierra y reaparece con el borrador ampliado */
  creatorEnter: (draft: TrackDraft) => {
    const last = [...draft.checkpoints].reverse().find((c) => c.kind === "normal");
    const extra: DraftCheckpoint = {
      kind: "normal", x: round((last?.x ?? 0) + 60, 2), y: round((last?.y ?? 0) + 40, 2), z: last?.z ?? 30, radius: config.creator.defaultRadius, height: config.creator.defaultHeight,
    };
    const next: TrackDraft = { ...draft, checkpoints: [...draft.checkpoints, extra], grid: draft.grid.length ? draft.grid : [{ x: extra.x - 20, y: extra.y, z: extra.z, h: 90 }] };
    emitNui("close");
    setTimeout(() => emitNui("open", { view: "admin", state: gameState, extra: { tab: "creator", draft: next } }), 1500);
    return {};
  },
};
