export type Level = 'none' | 'mod' | 'admin';

export interface PlayerJob {
  name: string;
  label: string;
  grade: number;
  gradeLabel: string;
  onDuty: boolean;
}

export interface Player {
  id: number;
  name: string;
  fivemName: string;
  ping: number;
  license?: string;
  identifier?: string;
  loaded: boolean;
  frozen: boolean;
  level: Level;
  bucket: number;
  health?: number;
  armour?: number;
  down?: boolean;
  job?: PlayerJob;
  accounts?: Record<string, number>;
}

export interface Option<T = string> {
  value: T;
  label: string;
}

export interface JobInfo {
  name: string;
  label: string;
  grades: Option<number>[];
}

export interface AdminData {
  me: { id: number; name: string; level: Level; actions: string[] };
  players: Player[];
  maxPlayers: number;
  stats: { police: number; ambulance: number; bans: number };
  jobs: JobInfo[];
  accounts: { name: string; label: string }[];
  weatherOptions: Option[];
  vehiclePresets: string[];
  weather: string | false;
  time: { hour: number; minute: number } | false;
  toggles: { noclip: boolean; god: boolean; invisible: boolean; players: boolean };
}

export interface Ban {
  id: number;
  license: string;
  name: string;
  reason: string;
  admin: string;
  created_at: number;
  expires_at: number | null;
}

export interface LogEntry {
  id: number;
  admin: string;
  action: string;
  target: string | null;
  details: string | null;
  created_at: number;
}

export interface ActionResult {
  ok: boolean;
  message?: string;
}
