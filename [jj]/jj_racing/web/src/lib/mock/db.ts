import type { DraftCheckpoint, DraftGrid, GameConfig, GameState, MyCrew, NuiResponse, RaceSettings, RecordBrief, TrackDetail, TrackSummary } from "../types";

/** Error de negocio del backend simulado (equivale a `return false, 'codigo'` en Lua) */
export class MockError extends Error {
  constructor(
    message: string,
    public code = "generic",
  ) {
    super(message);
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type Handler = (data: any) => unknown | Promise<unknown>;

export const wait = (ms = 180) => new Promise<void>((r) => setTimeout(r, ms));

export function ok<T>(data: T): NuiResponse<T> {
  return { ok: true, data };
}

// Configuracion y jugador -------------------------------------------------------------------------

export const config: GameConfig = {
  locale: new URLSearchParams(location.search).get("lang") === "en" ? "en" : "es",
  currency: "$",
  categories: ["street", "circuit", "offroad", "sprint", "circular"],
  difficulties: ["easy", "medium", "hard", "extreme"],
  pointToPoint: ["sprint"],
  vehicleClasses: ["any", "street", "muscle", "classics", "sports", "super", "offroad", "motorcycle"],
  allVehicleClasses: ["any", "classics", "motorcycle", "muscle", "offroad", "sports", "street", "super"],
  pageSize: 6,
  leaderboardSize: 25,
  maxLaps: 15,
  entryFeeMax: 50000,
  extraPrizeMax: 100000,
  baseMaxPrize: 250000,
  maxPlayers: 12,
  countdownSeconds: 5,
  commissionPct: 10,
  prizeSplit: [50, 30, 20],
  crewsEnabled: true,
  crewVs: { maxTeamSize: 6, stakeMax: 500000, formula: "points", minRank: 3 },
  creator: {
    minRadius: 3,
    maxRadius: 60,
    defaultRadius: 12,
    minHeight: 2,
    maxHeight: 40,
    defaultHeight: 8,
    maxCheckpoints: 150,
    maxGrid: 20,
    requireTest: true,
  },
  eventsMaxPrize: 1000000,
};

export const me = { name: "Alex Ruiz", pid: 7 };

export const crew: MyCrew = { id: 1, name: "Apex Syndicate", tag: "APX", color: "#a855f7", level: 4, points: 5230, wins: 18, canChallenge: true };

export const settings: RaceSettings = {
  maxPlayers: 12,
  minPlayersToStart: 1,
  minPlayersForRewards: 2,
  maxLaps: 15,
  countdownSeconds: 5,
  finishGraceSeconds: 60,
  entryFeeMax: 50000,
  extraPrizeMax: 100000,
  baseMaxPrize: 250000,
  commissionPct: 10,
  prizeSplit: [50, 30, 20],
  pilotPoints: [25, 18, 15, 12, 10, 8, 6, 4, 2, 1],
  allowedClasses: ["any", "street", "muscle", "classics", "sports", "super", "offroad", "motorcycle"],
  useRoutingBuckets: true,
  openLobbyMinutes: 15,
  crewPointsByPosition: [100, 60, 40, 25, 15, 10],
  crewFinishPoints: 5,
  crewMaxPointsPerRace: 300,
  crewRequireOutsider: true,
  crewPrizeSharePct: 0,
  crewVsFormula: "points",
  crewVsWinPoints: 500,
  crewVsStakeMax: 500000,
  crewVsMinRank: 3,
};

/** Estado inicial que devolveria getState. Las vistas pueden sobrescribir `lobby`, `invites`... en su mock. */
export const gameState: GameState = {
  config,
  isAdmin: true,
  me,
  crewsEnabled: true,
  crew,
  lobby: null,
  invites: [],
  challenges: { incoming: [], outgoing: [] },
  hasResult: false,
};

// Circuitos de ejemplo ---------------------------------------------------------------------------------

export interface MockTrack extends Omit<TrackSummary, "checkpointCount" | "length" | "gridSize" | "record"> {
  checkpoints: DraftCheckpoint[];
  grid: DraftGrid[];
  testedVersion: number;
  record: RecordBrief | null;
}

function cp(kind: DraftCheckpoint["kind"], x: number, y: number, extra: Partial<DraftCheckpoint> = {}): DraftCheckpoint {
  return { kind, x: Math.round(x * 10) / 10, y: Math.round(y * 10) / 10, z: 30, radius: 12, height: 8, ...extra };
}

function loop(cx: number, cy: number, rx: number, ry: number, n: number, wobble = 0): DraftCheckpoint[] {
  return Array.from({ length: n }, (_, i) => {
    const a = (i / n) * Math.PI * 2;
    const w = 1 + wobble * Math.sin(a * 3);
    return cp("normal", cx + Math.cos(a) * rx * w, cy + Math.sin(a) * ry * w);
  });
}

function gridAt(x: number, y: number, n = 8): DraftGrid[] {
  return Array.from({ length: n }, (_, i) => ({ x: x - i * 7, y: y + (i % 2) * 4, z: 30, h: 90 }));
}

function make(id: number, name: string, category: string, difficulty: string, extra: Partial<MockTrack>, checkpoints: DraftCheckpoint[], grid: DraftGrid[]): MockTrack {
  return {
    id,
    name,
    category,
    difficulty,
    description: "",
    lapsDefault: category === "sprint" ? 1 : 3,
    vehicleClass: "any",
    allowCrews: true,
    basePrize: 5000,
    timeLimit: 0,
    collisions: true,
    referenceTime: 78000 + id * 4300,
    version: 1,
    enabled: true,
    tested: true,
    updatedAt: Math.floor(Date.now() / 1000) - id * 86400,
    inUse: false,
    testedVersion: 1,
    record: null,
    ...extra,
    checkpoints,
    grid,
  };
}

const circuitA = loop(-300, -2000, 380, 240, 12, 0.12);
circuitA.splice(5, 0, cp("shortcut", -120, -1930, { linkFrom: 4, linkTo: 6 }));
circuitA.push(cp("pit", -300, -2290, { radius: 8 }));

export const tracks: MockTrack[] = [
  make(1, "Vinewood Hills GP", "circuit", "medium", { description: "Circuito técnico por las colinas con una larga recta final y un atajo opcional.", basePrize: 12000, record: { name: "Dani Moreno", crewTag: "APX", crewColor: "#ff2d55", time: 81240, vehicle: "Pfister Comet" } }, circuitA, gridAt(-230, -2250)),
  make(2, "Del Perro Sprint", "sprint", "easy", { description: "Sprint costero de punta a punta.", vehicleClass: "sports", record: { name: "Laura Vega", crewTag: "NOS", crewColor: "#3b82f6", time: 94310, vehicle: "Karin Futo" } }, [cp("normal", -1700, -900), cp("normal", -1300, -700), cp("normal", -900, -750), cp("normal", -450, -500), cp("normal", 100, -300)], gridAt(-1750, -950)),
  make(3, "Sandy Dust Rally", "offroad", "hard", { description: "Barro, saltos y curvas ciegas en el desierto.", vehicleClass: "offroad", collisions: false, timeLimit: 600, record: null, referenceTime: 142000 }, loop(1900, 3400, 520, 360, 10, 0.2), gridAt(2330, 3300)),
  make(4, "Docks Street Race", "street", "extreme", { description: "Carrera urbana ilegal por el puerto y el centro.", basePrize: 30000, record: { name: "Kira Tanaka", time: 112500, vehicle: "Annis Elegy RH8" }, referenceTime: 105000 }, loop(1000, -3000, 300, 300, 14, 0.18), gridAt(1300, -3000)),
  make(5, "Mirror Park Circular", "circular", "easy", { description: "Vuelta tranquila al lago para calentar.", record: { name: "Pablo Núñez", crewTag: "NOS", crewColor: "#3b82f6", time: 61720, vehicle: "Bravado Buffalo" } }, loop(1060, -600, 260, 200, 9), gridAt(1320, -600)),
  make(6, "Paleto Pass (borrador)", "sprint", "medium", { description: "Pendiente de prueba.", enabled: false, tested: false, testedVersion: 0, referenceTime: 0 }, [cp("normal", -300, 6200), cp("normal", -250, 6500), cp("normal", -150, 6800), cp("normal", 0, 7000)], gridAt(-320, 6150, 6)),
];

export function pathLength(t: { checkpoints: DraftCheckpoint[] }): number {
  const n = t.checkpoints.filter((c) => c.kind === "normal");
  let len = 0;
  for (let i = 1; i < n.length; i++) len += Math.hypot(n[i]!.x - n[i - 1]!.x, n[i]!.y - n[i - 1]!.y);
  return Math.round(len);
}

export function trackSummary(t: MockTrack, admin = false): TrackSummary {
  const { checkpoints, grid, testedVersion: _tv, ...rest } = t;
  void _tv;
  const out: TrackSummary = {
    ...rest,
    checkpointCount: checkpoints.filter((c) => c.kind === "normal").length,
    length: pathLength(t),
    gridSize: grid.length,
  };
  if (!admin) {
    delete out.enabled;
    delete out.tested;
    delete out.updatedAt;
    delete out.inUse;
  }
  return out;
}

export function trackDetail(t: MockTrack, admin = false): TrackDetail {
  let seq = 0;
  const route = t.checkpoints.map((c) => ({ x: c.x, y: c.y, kind: c.kind, seq: c.kind === "normal" ? ++seq : undefined, linkFrom: c.linkFrom, linkTo: c.linkTo }));
  const d: TrackDetail = { ...trackSummary(t, admin), route, grid: t.grid.map((g) => ({ x: g.x, y: g.y, h: g.h, z: g.z })) };
  if (admin) {
    d.checkpoints = t.checkpoints.map((c, i) => ({ ...c, idx: i + 1 }));
    d.testedVersion = t.testedVersion;
  }
  return d;
}

export function findTrack(id: number): MockTrack {
  const t = tracks.find((x) => x.id === id);
  if (!t) throw new MockError("El circuito no existe o no está activo.", "track_not_found");
  return t;
}

/** Filtra, ordena y pagina circuitos como lo hace Tracks.List en Lua */
export function listTracks(opts: { search?: string; category?: string; difficulty?: string; vehicleClass?: string; status?: string; sort?: string; page?: number }, admin: boolean) {
  const search = (opts.search ?? "").toLowerCase();
  let list = tracks.filter((t) => admin || t.enabled);
  if (opts.category) list = list.filter((t) => t.category === opts.category);
  if (opts.difficulty) list = list.filter((t) => t.difficulty === opts.difficulty);
  if (opts.vehicleClass) list = list.filter((t) => t.vehicleClass === opts.vehicleClass);
  if (search) list = list.filter((t) => t.name.toLowerCase().includes(search) || t.description.toLowerCase().includes(search));
  if (admin && opts.status === "enabled") list = list.filter((t) => t.enabled);
  if (admin && opts.status === "disabled") list = list.filter((t) => !t.enabled);
  if (admin && opts.status === "untested") list = list.filter((t) => t.testedVersion !== t.version);
  const diff = (d: string) => config.difficulties.indexOf(d);
  list = [...list].sort((a, b) => {
    if (opts.sort === "difficulty" && diff(a.difficulty) !== diff(b.difficulty)) return diff(a.difficulty) - diff(b.difficulty);
    if (opts.sort === "length" && pathLength(a) !== pathLength(b)) return pathLength(b) - pathLength(a);
    if (opts.sort === "newest" && a.id !== b.id) return b.id - a.id;
    return a.name.localeCompare(b.name);
  });
  const page = Math.max(1, opts.page ?? 1);
  const size = config.pageSize;
  return { items: list.slice((page - 1) * size, page * size).map((t) => trackSummary(t, admin)), total: list.length, page, pageSize: size };
}
