export interface Ingredient {
  name: string;
  label: string;
  image: string;
  needs: number;
  have: number;
  tool: boolean;
}

export interface Recipe {
  slot: number;
  name: string;
  label: string;
  image: string;
  description?: string;
  count: number | [number, number];
  duration: number;
  ingredients: Ingredient[];
  xpRequired: number;
  xpReward: number;
  blueprint?: { key: string; uses: number };
}

export interface Job {
  id: number;
  name: string;
  label: string;
  image: string;
  count: number;
  duration: number;
  remaining?: number;
}

export interface BenchData {
  id: string;
  label: string;
  storage: { id: string; weight: number; maxWeight: number };
  xp: { enabled: boolean; current: number };
  recipes: Recipe[];
  queue: Job[];
}

export interface Role {
  id: number;
  name: string;
  canUse: boolean;
  canMove: boolean;
  canPack: boolean;
  canManage: boolean;
  members: { identifier: string; name: string; online: boolean }[];
}

export interface ManageData {
  id: string;
  label: string;
  owner: string;
  isOwner: boolean;
  roles: Role[];
  nearby: { id: number; name: string; roleId?: number }[];
}

declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = !window.invokeNative;

const resource = window.GetParentResourceName?.() ?? 'jj_crafting';

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
export const toList = <T,>(list: unknown): T[] => (Array.isArray(list) ? list : list && typeof list === 'object' ? (Object.values(list) as T[]) : []);

// Datos para ver la interfaz en el navegador
const image = (name: string) => `https://placehold.co/96x96/1b1131/c084fc?text=${encodeURIComponent(name.slice(0, 3))}`;
const ingredient = (name: string, label: string, needs: number, have: number, tool = false): Ingredient => ({ name, label, image: image(label), needs, have, tool });

export const sampleBench: BenchData = {
  id: 'placed:1',
  label: 'Mesa de crafteo básica',
  storage: { id: 'crafting:placed:1:1', weight: 18400, maxWeight: 100000 },
  xp: { enabled: true, current: 42 },
  recipes: [
    { slot: 1, name: 'lockpick', label: 'Ganzúa', image: image('Ganzúa'), count: 2, duration: 5, xpRequired: 0, xpReward: 5, blueprint: { key: 'lockpick', uses: 12 }, ingredients: [ingredient('scrapmetal', 'Chatarra', 5, 34), ingredient('WEAPON_HAMMER', 'Martillo', 5, 80, true)] },
    { slot: 2, name: 'bandage', label: 'Venda', image: image('Venda'), count: 1, duration: 4, xpRequired: 0, xpReward: 3, ingredients: [ingredient('scrapmetal', 'Chatarra', 2, 34), ingredient('WEAPON_HAMMER', 'Martillo', 5, 80, true)] },
    { slot: 3, name: 'radio', label: 'Radio', image: image('Radio'), count: 1, duration: 5.5, xpRequired: 0, xpReward: 7, ingredients: [ingredient('scrapmetal', 'Chatarra', 6, 34), ingredient('WEAPON_HAMMER', 'Martillo', 5, 80, true)] },
    { slot: 4, name: 'armour', label: 'Chaleco antibalas', image: image('Chaleco'), count: 1, duration: 15, xpRequired: 0, xpReward: 15, ingredients: [ingredient('scrapmetal', 'Chatarra', 15, 34), ingredient('WEAPON_HAMMER', 'Martillo', 5, 80, true)] },
    { slot: 5, name: 'heavyarmour', label: 'Chaleco pesado', image: image('Pesado'), count: 1, duration: 25, xpRequired: 0, xpReward: 25, ingredients: [ingredient('scrapmetal', 'Chatarra', 25, 34), ingredient('WEAPON_HAMMER', 'Martillo', 5, 80, true)] },
    { slot: 6, name: 'weapon_smg', label: 'Subfusil', image: image('SMG'), count: 1, duration: 60, xpRequired: 48, xpReward: 28, blueprint: { key: 'weapon_smg', uses: 0 }, ingredients: [ingredient('scrapmetal', 'Chatarra', 40, 34), ingredient('WEAPON_HAMMER', 'Martillo', 5, 80, true)] },
  ],
  queue: [
    { id: 1, name: 'lockpick', label: 'Ganzúa', image: image('Ganzúa'), count: 2, duration: 5, remaining: 3 },
    { id: 2, name: 'bandage', label: 'Venda', image: image('Venda'), count: 1, duration: 4 },
  ],
};

export const sampleManage: ManageData = {
  id: 'placed:1',
  label: 'Mesa de crafteo básica',
  owner: 'Marco Vidal',
  isOwner: true,
  roles: [
    { id: 1, name: 'Miembro', canUse: true, canMove: false, canPack: false, canManage: false, members: [{ identifier: 'JJ3PL8DWA', name: 'Lucía Ferrer', online: true }] },
    { id: 2, name: 'Gestor', canUse: true, canMove: true, canPack: true, canManage: true, members: [] },
  ],
  nearby: [
    { id: 12, name: 'Lucía Ferrer', roleId: 1 },
    { id: 31, name: 'Dani Ortega' },
  ],
};
