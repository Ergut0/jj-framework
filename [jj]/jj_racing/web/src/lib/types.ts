// Contrato entre la NUI y los callbacks Lua (server/callbacks.lua, client/*.lua).
// Todo dato que viene del servidor se tipa aqui; el servidor es la autoridad.

export type NuiResponse<T = unknown> = { ok: true; data: T } | { ok: false; error: string; code?: string };

export type View = "player" | "admin";
export type Locale = "es" | "en";

export type CheckpointKind = "normal" | "shortcut" | "pit";
export type RaceMode = "open" | "crew" | "official" | "test";
export type LobbyState = "open" | "checking" | "countdown" | "running";
export type ResultStatus = "finished" | "dnf" | "dq";

export interface Paginated<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

// Estado inicial (callback getState) -------------------------------------------------------------

export interface GameConfig {
  locale: Locale;
  currency: string;
  categories: string[];
  difficulties: string[];
  /** categorias de una sola vuelta (laps se fuerza a 1) */
  pointToPoint: string[];
  /** clases habilitadas ahora mismo (ajustes en vivo) */
  vehicleClasses: string[];
  allVehicleClasses: string[];
  pageSize: number;
  leaderboardSize: number;
  maxLaps: number;
  entryFeeMax: number;
  extraPrizeMax: number;
  baseMaxPrize: number;
  maxPlayers: number;
  countdownSeconds: number;
  commissionPct: number;
  prizeSplit: number[];
  crewsEnabled: boolean;
  crewVs: { maxTeamSize: number; stakeMax: number; formula: "points" | "positions" | "best"; minRank: number };
  creator: {
    minRadius: number;
    maxRadius: number;
    defaultRadius: number;
    minHeight: number;
    maxHeight: number;
    defaultHeight: number;
    maxCheckpoints: number;
    maxGrid: number;
    requireTest: boolean;
  };
  eventsMaxPrize: number;
}

export interface CrewBrief {
  id: number;
  name: string;
  tag: string;
  color: string;
}

export interface MyCrew extends CrewBrief {
  level: number;
  points: number;
  wins: number;
  canChallenge: boolean;
}

export interface Invite {
  lobbyId: number;
  name: string;
  trackName: string;
  hostName: string;
  expiresIn: number;
}

export interface Challenge {
  id: number;
  from: CrewBrief;
  to: CrewBrief;
  fromName: string;
  trackId: number;
  trackName: string;
  laps: number;
  vehicleClass: string;
  teamSize: number;
  stake: number;
  expiresIn: number;
}

export interface GameState {
  config: GameConfig;
  isAdmin: boolean;
  me: { name: string; pid: number };
  crewsEnabled: boolean;
  crew: MyCrew | null;
  lobby: Lobby | null;
  invites: Invite[];
  challenges: { incoming: Challenge[]; outgoing: Challenge[] };
  hasResult: boolean;
}

// Circuitos -------------------------------------------------------------------------------------------

export interface RecordBrief {
  /** solo lo recibe la administracion */
  citizenid?: string;
  name: string;
  crewTag?: string;
  crewColor?: string;
  /** ms */
  time: number;
  vehicle: string;
}

export interface TrackSummary {
  id: number;
  name: string;
  category: string;
  difficulty: string;
  description: string;
  lapsDefault: number;
  vehicleClass: string;
  allowCrews: boolean;
  basePrize: number;
  /** segundos, 0 = sin limite */
  timeLimit: number;
  collisions: boolean;
  /** ms, 0 = sin medir */
  referenceTime: number;
  checkpointCount: number;
  /** metros */
  length: number;
  version: number;
  gridSize: number;
  record: RecordBrief | null;
  // Solo administracion
  enabled?: boolean;
  tested?: boolean;
  updatedAt?: number;
  inUse?: boolean;
}

export interface RoutePoint {
  x: number;
  y: number;
  kind: CheckpointKind;
  seq?: number;
  linkFrom?: number;
  linkTo?: number;
}

export interface TrackDetail extends TrackSummary {
  route: RoutePoint[];
  grid: { x: number; y: number; h: number; z?: number }[];
  // Solo administracion (adminGetTrack)
  checkpoints?: DraftCheckpoint[];
  testedVersion?: number;
}

export interface DraftCheckpoint {
  kind: CheckpointKind;
  x: number;
  y: number;
  z: number;
  radius: number;
  height: number;
  /** atajos: numero (entre los normales) del checkpoint del que parte y al que vuelve */
  linkFrom?: number;
  linkTo?: number;
  idx?: number;
  seq?: number;
}

export interface DraftGrid {
  x: number;
  y: number;
  z: number;
  h: number;
}

/** Borrador del editor (adminSaveTrack, creatorEnter y exportacion JSON) */
export interface TrackDraft {
  id?: number;
  name: string;
  category: string;
  difficulty: string;
  description: string;
  lapsDefault: number;
  vehicleClass: string;
  allowCrews: boolean;
  basePrize: number;
  timeLimit: number;
  collisions: boolean;
  /** cambio menor: no sube la version aunque cambie el trazado */
  minor?: boolean;
  checkpoints: DraftCheckpoint[];
  grid: DraftGrid[];
}

export interface TrackFilters {
  search?: string;
  category?: string;
  difficulty?: string;
  vehicleClass?: string;
  /** administracion: enabled | disabled | untested */
  status?: string;
  /** name | difficulty | length | newest */
  sort?: string;
  page?: number;
}

// Salas -------------------------------------------------------------------------------------------------

export interface LobbyPlayer {
  pid: number;
  name: string;
  ready: boolean;
  host: boolean;
  team?: "A" | "B";
  crew?: { tag: string; color: string; name: string };
  you: boolean;
}

export interface Lobby {
  id: number;
  name: string;
  mode: RaceMode;
  state: LobbyState;
  trackId: number;
  trackName: string;
  category: string;
  difficulty: string;
  collisions: boolean;
  laps: number;
  vehicleClass: string;
  entryFee: number;
  extraPrize: number;
  prizePool: number;
  private: boolean;
  maxPlayers: number;
  official: boolean;
  hostName: string;
  isHost: boolean;
  you: number;
  crewVs?: { a: CrewBrief; b: CrewBrief; size: number; stake: number; formula: string };
  players: LobbyPlayer[];
}

export interface LobbySummary extends Omit<Lobby, "players"> {
  playerCount: number;
  invited?: boolean;
}

export interface CreateRaceInput {
  trackId: number;
  laps: number;
  vehicleClass: string;
  entryFee: number;
  extraPrize: number;
  private: boolean;
  name?: string;
}

export interface ChallengeInput {
  crewId: number;
  trackId: number;
  laps: number;
  vehicleClass: string;
  teamSize: number;
  stake: number;
}

// Resultados -------------------------------------------------------------------------------------------

export interface ResultRow {
  pid: number;
  position: number;
  name: string;
  status: ResultStatus;
  crew?: { tag: string; color: string };
  team?: "A" | "B";
  /** ms; ausente si no termino */
  totalTime?: number;
  bestLap?: number;
  laps: number;
  prize: number;
  points: number;
  crewPoints: number;
  flagged?: boolean;
  trackRecord?: boolean;
  vehicle?: string;
}

export interface RaceResults {
  raceKey: string;
  trackId: number;
  trackName: string;
  laps: number;
  mode: RaceMode;
  /** false = no hubo premios ni puntos de crew (pocos pilotos) */
  eligible: boolean;
  rewards?: { entries: number; commission: number; extra: number; base: number; total: number };
  crewVs?: {
    winner?: "A" | "B";
    scoreA?: number;
    scoreB?: number;
    formula: string;
    winnerCrew?: CrewBrief;
    payout?: number;
    points?: number;
  };
  rows: ResultRow[];
  at: number;
  you: number;
}

/** Resultado de una carrera pasada (getRaceResults): sin `pid` */
export interface PastResults {
  raceKey: string;
  trackId: number;
  trackName: string;
  mode: RaceMode;
  rows: Omit<ResultRow, "pid">[];
}

export interface HistoryItem {
  id: number;
  raceKey: string;
  trackId: number;
  trackName: string;
  mode: RaceMode;
  position: number;
  status: ResultStatus;
  totalTime: number;
  bestLap: number;
  prize: number;
  points: number;
  crewPoints: number;
  flagged: boolean;
  voided: boolean;
  createdAt: number;
}

export interface StatsPayload {
  stats: { races: number; wins: number; podiums: number; earnings: number; points: number };
  bests: { trackId: number; trackName: string; bestLap: number; vehicle: string }[];
}

export interface LeaderboardRow extends RecordBrief {
  position: number;
  vehicleClass: string;
  at: number;
}

export interface LeaderboardPayload {
  track: { id: number; name: string; version: number };
  rows: LeaderboardRow[];
}

export interface PilotRankRow {
  position: number;
  name: string;
  crewTag?: string;
  crewColor?: string;
  races: number;
  wins: number;
  podiums: number;
  points: number;
}

export interface CrewRankRow {
  position: number;
  id: number;
  name: string;
  tag: string;
  color: string;
  points: number;
  wins: number;
  level: number;
  members: number;
}

export interface CrewListItem extends CrewBrief {
  level: number;
  points: number;
  members: number;
}

// Administracion -------------------------------------------------------------------------------------------

export interface AdminRacePlayer extends LobbyPlayer {
  status: string;
  strikes: number;
  paid: number;
}

export interface AdminRace extends Omit<Lobby, "players" | "state"> {
  state: LobbyState | "running";
  startedAt?: number;
  players: AdminRacePlayer[];
}

export interface EventItem {
  id: number;
  trackId: number;
  trackName: string;
  title: string;
  laps: number;
  vehicleClass: string;
  prize: number;
  /** unix seg */
  scheduledAt: number;
  status: "scheduled" | "open" | "running" | "done" | "cancelled";
}

export interface EventInput {
  trackId: number;
  title: string;
  laps: number;
  vehicleClass: string;
  prize: number;
  scheduledAt: number;
}

export interface AdminResultRow {
  id: number;
  raceKey: string;
  trackId: number;
  trackName: string;
  mode: RaceMode;
  citizenid: string;
  name: string;
  crewTag?: string;
  position: number;
  status: ResultStatus;
  totalTime: number;
  bestLap: number;
  prize: number;
  flagged: boolean;
  flagReason: string;
  voided: boolean;
  voidReason: string;
  createdAt: number;
}

export interface LogRow {
  id: number;
  actorCid: string;
  actorName: string;
  action: string;
  details: Record<string, unknown>;
  isAdmin: boolean;
  createdAt: number;
}

/** Ajustes globales editables en vivo (server/main.lua -> SettingsSchema) */
export interface RaceSettings {
  maxPlayers: number;
  minPlayersToStart: number;
  minPlayersForRewards: number;
  maxLaps: number;
  countdownSeconds: number;
  finishGraceSeconds: number;
  entryFeeMax: number;
  extraPrizeMax: number;
  baseMaxPrize: number;
  commissionPct: number;
  prizeSplit: number[];
  pilotPoints: number[];
  allowedClasses: string[];
  useRoutingBuckets: boolean;
  openLobbyMinutes: number;
  crewPointsByPosition: number[];
  crewFinishPoints: number;
  crewMaxPointsPerRace: number;
  crewRequireOutsider: boolean;
  crewPrizeSharePct: number;
  crewVsFormula: "points" | "positions" | "best";
  crewVsWinPoints: number;
  crewVsStakeMax: number;
  crewVsMinRank: number;
}

export interface TestResult {
  ok: boolean;
  time?: number;
  reference?: number;
  trackId: number;
}

// Mensajes extra al abrir el panel (client/nui.lua -> UI.Open(view, extra)) --------------------------------

export interface OpenExtra {
  /** pestana inicial */
  tab?: string;
  results?: RaceResults;
  testResult?: TestResult;
  /** borrador devuelto por el editor del mundo */
  draft?: TrackDraft;
}

// HUD -------------------------------------------------------------------------------------------------------

export interface HudShow {
  locale: Locale;
  trackName: string;
  laps: number;
  totalCp: number;
  mode: RaceMode;
  you: number;
}

export interface HudStandingRow {
  pid: number;
  name: string;
  tag?: string;
  color?: string;
  lap: number;
  finished?: boolean;
  out?: boolean;
}

export interface HudStandings {
  pos: number;
  total: number;
  /** ms respecto al lider (0 = lider) */
  gap?: number;
  leader: string;
  rows: HudStandingRow[];
}

export interface HudProgress {
  lap: number;
  /** checkpoints superados en la vuelta actual */
  cp: number;
  lapTime?: number;
  bestLap?: number;
  total: number;
}

export interface CreatorHud {
  locale: Locale;
  kind: CheckpointKind | "grid";
  source: "aim" | "player";
  radius: number;
  height: number;
  checkpoints: number;
  normals: number;
  grid: number;
  selected: number;
  selectedKind?: CheckpointKind;
  name?: string;
  keys: Record<string, string>;
}
