export interface Option<T = string> {
  value: T;
  label: string;
}

export interface Point {
  id: number;
  type: string;
  lab?: string;
  x: number;
  y: number;
  z: number;
}

export interface Member {
  identifier: string;
  name: string;
  rank: number;
  online: boolean;
  source?: number;
}

export interface Graffiti {
  id: number;
  x: number;
  y: number;
  z: number;
  nx: number;
  ny: number;
  nz: number;
  url?: string;
  author?: string;
}

export interface Gang {
  id: number;
  label: string;
  color: number;
  hex: string;
  x: number;
  y: number;
  z: number;
  radius: number;
  points: Point[];
  members: Member[];
  graffitis: Graffiti[];
}

export interface OnlinePlayer {
  id: number;
  name: string;
  gang?: string;
}

export interface PanelConfig {
  pointTypes: Option[];
  labs: Option[];
  colors: (Option<number> & { hex: string })[];
  ranks: Option<number>[];
  minRadius: number;
  maxRadius: number;
  defaultRadius: number;
  maxGraffitis: number;
}

export interface PanelData {
  gangs: Gang[];
  players: OnlinePlayer[];
  config: PanelConfig;
}

export interface ActionResult {
  ok: boolean;
  message?: string;
  id?: number;
}

export type Payload = Record<string, unknown>;
