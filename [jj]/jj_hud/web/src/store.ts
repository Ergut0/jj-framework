import { create } from 'zustand';

export interface VehicleData {
  speed: number;
  unit: string;
  rpm: number;
  gear?: string;
  kind: 'land' | 'boat' | 'air';
  fuel: number;
  engine: number;
  running: boolean;
  lights: 0 | 1 | 2;
  locked: boolean;
  hasSeatbelt: boolean;
  belted: boolean;
  altitude?: number;
  street: string;
  direction: string;
}

export interface HudState {
  visible: boolean;
  mapOpened: boolean;
  micro: number;
  microphoneOn: boolean;
  health: number;
  armour: number;
  hunger: number;
  thirst: number;
  stamina: number;
  oxygen: number;
  vehicle: VehicleData | null;
  update: (values: Partial<HudState>) => void;
}

export const useHud = create<HudState>((set) => ({
  visible: false,
  mapOpened: false,
  micro: 67,
  microphoneOn: false,
  health: 100,
  armour: 0,
  hunger: 100,
  thirst: 100,
  stamina: 100,
  oxygen: 100,
  vehicle: null,
  update: (values) => set(values),
}));
