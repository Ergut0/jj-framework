export interface Grade {
  id: number;
  name: string;
  label: string;
  salary: number;
  permission: boolean;
}

export interface Employee {
  identifier: string;
  nombre: string;
  grade: number;
  gradeLabel: string;
  onduty: boolean;
  online: boolean;
}

export interface Point {
  id: number;
  x: number;
  y: number;
  z: number;
  heading: number;
  typePoint: string;
  radius: number;
}

export interface Blip {
  id: number;
  x: number;
  y: number;
  z: number;
  label: string;
  blipsprite: number;
  blipcolor: number;
}

export interface MarketItem {
  id: number;
  name: string;
  label: string;
  price: number;
}

export interface Vehicle {
  id: number;
  name: string;
  livery: number;
}

export interface Perm {
  id: number;
  typePermission: string;
}

export interface TeleportCoords {
  entrance_x: number;
  entrance_y: number;
  entrance_z: number;
  entrance_heading: number;
  exit_x: number;
  exit_y: number;
  exit_z: number;
  exit_heading: number;
}

export interface Teleport extends TeleportCoords {
  id: number;
  label: string;
  job_only: boolean;
  on_duty_only: boolean;
  allow_vehicle: boolean;
}

export interface GlobalTeleport extends TeleportCoords {
  id: number;
  label: string;
  password: string | null;
  bucket: number;
}

export interface LogEntry {
  id: number;
  category: string;
  actor: string;
  message: string;
  created_at: number;
}

export interface JobSummary {
  id: number;
  name: string;
  label: string;
  img?: string;
  open: boolean;
}

export interface Job extends JobSummary {
  level: number;
  experience: number;
  money: number;
  employees: Employee[];
  grades: Grade[];
  items: MarketItem[];
  points: Point[];
  blips: Blip[];
  vehicles: Vehicle[];
  perms: Perm[];
  teleports: Teleport[];
}

export interface Panel {
  admin: boolean;
  jobs?: JobSummary[];
  job?: Job;
  maxLevel: number;
  maxExp: number;
}

export interface Coords {
  x: number;
  y: number;
  z: number;
  heading: number;
}

// Lua convierte una lista vacía en un objeto vacío al enviarla
export function asList<T>(value: T[] | Record<string, never> | undefined): T[] {
  return Array.isArray(value) ? value : [];
}
