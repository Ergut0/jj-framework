export interface Coords {
  x: number;
  y: number;
  z: number;
}

export interface Capture {
  attacker: number;
  attackerLabel: string;
  attackerHex: string;
  secondsLeft: number;
  contested: boolean;
}

export interface Flag {
  id: number;
  gang: number;
  label: string;
  hex: string;
  coords: Coords;
  capture?: Capture;
}

export interface Gang {
  id: number;
  label: string;
  hex: string;
  flags: number;
  online: number;
  excluded: boolean;
}

export interface Settings {
  RadiusFlag: number;
  MaxFlagsPerGang: number;
  SecondsBetweenPlants: number;
  SecondsToPlant: number;
  SecondsToCapture: number;
  SecondsBetweenDefends: number;
  SecondsBetweenAttacks: number;
  PauseWhenDefended: boolean;
  ClearOnStart: boolean;
}

export interface State {
  active: boolean;
  settings: Settings;
  flags: Flag[];
  gangs: Gang[];
}

declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = !window.invokeNative;

const resource = window.GetParentResourceName?.() ?? 'jj_flags';

export async function fetchNui<T>(name: string, data: unknown = {}): Promise<T | undefined> {
  if (isBrowser) return undefined;
  try {
    const response = await fetch(`https://${resource}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    return (await response.json()) as T;
  } catch {
    return undefined;
  }
}

// Lua envía las tablas vacías como objeto o como lista según el caso
const toList = <T,>(list: unknown): T[] => (Array.isArray(list) ? list : list && typeof list === 'object' ? (Object.values(list) as T[]) : []);

export const normalizeState = (state: State): State => ({ ...state, flags: toList<Flag>(state.flags), gangs: toList<Gang>(state.gangs) });

// Datos para ver el panel en el navegador
export const sampleState: State = {
  active: true,
  settings: {
    RadiusFlag: 60,
    MaxFlagsPerGang: 5,
    SecondsBetweenPlants: 100,
    SecondsToPlant: 10,
    SecondsToCapture: 300,
    SecondsBetweenDefends: 450,
    SecondsBetweenAttacks: 300,
    PauseWhenDefended: true,
    ClearOnStart: true,
  },
  flags: [
    { id: 1, gang: 1, label: 'Los Tridentes', hex: '#a855f7', coords: { x: 102.4, y: -1938.2, z: 20.8 } },
    { id: 2, gang: 2, label: 'Vagos', hex: '#facc15', coords: { x: 331.7, y: -2036.5, z: 21.1 }, capture: { attacker: 1, attackerLabel: 'Los Tridentes', attackerHex: '#a855f7', secondsLeft: 184, contested: false } },
    { id: 3, gang: 3, label: 'Ballas', hex: '#22c55e', coords: { x: -151.2, y: -1625.9, z: 33.6 }, capture: { attacker: 2, attackerLabel: 'Vagos', attackerHex: '#facc15', secondsLeft: 96, contested: true } },
    { id: 4, gang: 1, label: 'Los Tridentes', hex: '#a855f7', coords: { x: 1205.0, y: -1560.3, z: 39.4 } },
  ],
  gangs: [
    { id: 1, label: 'Los Tridentes', hex: '#a855f7', flags: 2, online: 6, excluded: false },
    { id: 2, label: 'Vagos', hex: '#facc15', flags: 1, online: 4, excluded: false },
    { id: 3, label: 'Ballas', hex: '#22c55e', flags: 1, online: 3, excluded: false },
    { id: 4, label: 'Mafia Rusa', hex: '#38d9f5', flags: 0, online: 0, excluded: true },
  ],
};
