export type PermissionKey = "invite" | "kick" | "setRank" | "deposit" | "withdraw" | "manageRanks" | "editCrew";
export type Permissions = Partial<Record<string, boolean>>;

export interface Rank {
  id: number;
  name: string;
  level: number;
  isLeader: boolean;
  permissions: Permissions;
}

export interface Member {
  citizenid: string;
  name: string;
  rankId: number;
  rankLevel: number;
  online: boolean;
  joinedAt: number;
  isLeader: boolean;
}

export interface Me {
  citizenid: string;
  rankId: number;
  level: number;
  isLeader: boolean;
  permissions: Permissions;
}

export interface Crew {
  id: number;
  name: string;
  tag: string;
  color: string;
  logo: string;
  level: number;
  points: number;
  wins: number;
  money: number;
  frozen: boolean;
  leader: string;
  createdAt: number;
  nextLevelPoints?: number;
  ranks: Rank[];
  members: Member[];
  me?: Me;
}

export interface CrewSummary {
  id: number;
  name: string;
  tag: string;
  color: string;
  logo: string;
  level: number;
  points: number;
  wins: number;
  money: number;
  frozen: boolean;
  members: number;
  leaderName: string;
  createdAt: number;
}

export interface Invite {
  id: number;
  crewId: number;
  crewName: string;
  crewTag: string;
  color: string;
  logo: string;
  invitedBy: string;
  expiresAt: number;
  members: number;
}

export interface GameConfig {
  locale: string;
  currency: string;
  createCost: number;
  maxMembers: number;
  nameMin: number;
  nameMax: number;
  tagMin: number;
  tagMax: number;
  allowLogo: boolean;
  maxRanks: number;
  permissionKeys: string[];
  depositAccounts: string[];
  maxTransaction: number;
  pageSize: number;
  levelPoints: number[];
  leaderLevel: number;
  withdrawAccount: string;
}

export interface GameState {
  player: { citizenid: string; name: string; cash: number; bank: number };
  isAdmin: boolean;
  crew?: Crew | null;
  invites: Invite[];
  config: GameConfig;
}

export interface Page<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface Transaction {
  id: number;
  name: string;
  type: "deposit" | "withdraw" | "admin" | "export";
  amount: number;
  balance: number;
  note: string;
  createdAt: number;
}

export interface ActivityItem {
  id: number;
  actor: string;
  action: string;
  details: Record<string, unknown>;
  createdAt: number;
}

export interface LogItem extends ActivityItem {
  crewId: number;
  crewName: string;
  actorCid: string;
  admin: boolean;
}

export interface RankingRow {
  pos: number;
  id: number;
  name: string;
  tag: string;
  color: string;
  logo: string;
  level: number;
  points: number;
  wins: number;
  members: number;
}

export interface SettingsValues {
  maxMembers: number;
  createCost: number;
  nameMin: number;
  nameMax: number;
  maxRanks: number;
  inviteExpiryMinutes: number;
  allowLogo: boolean;
  bannedNames: string[];
}

export interface SettingsPayload {
  values: SettingsValues;
  schema: Record<string, { t: string; min?: number; max?: number }>;
}

export type NuiResponse<T> = { ok: true; data: T } | { ok: false; error: string; code?: string };

export type View = "player" | "admin";
