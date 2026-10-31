import { atom } from 'jotai';
import { isBrowser } from './lib/nui';

export interface Character {
  id: number;
  citizenid: string;
  fullName: string;
  birthdate: string;
  image?: string;
}

export interface Zone {
  id: number;
  name: string;
  image: string;
  description: string;
}

// Datos de ejemplo para trabajar en el navegador, sin el juego
const mockCharacters: Character[] = [
  { id: 1, citizenid: '123456789', fullName: 'John Doe', birthdate: '1990-01-01' },
  { id: 2, citizenid: '987654321', fullName: 'Jane Smith', birthdate: '1992-05-15' },
  { id: 3, citizenid: '456789123', fullName: 'Alice Johnson', birthdate: '1985-09-30' },
];

const mockZones: Zone[] = [1, 2, 3, 4, 5].map((id) => ({
  id,
  name: `Zona ${id}`,
  image: id === 1 ? 'https://randomuser.me/api/portraits/men/1.jpg' : 'https://via.placeholder.com/150',
  description: `Descripción de la Zona ${id}`,
}));

export const charactersAtom = atom<Character[]>(isBrowser() ? mockCharacters : []);
export const activeCharacterAtom = atom<Character | null>(null);
export const slotsUnlockedAtom = atom(isBrowser() ? 4 : 0);
export const creatingAtom = atom(false);
export const zonesAtom = atom<Zone[]>(isBrowser() ? mockZones : []);
export const selectedZoneAtom = atom<Zone | null>(null);
