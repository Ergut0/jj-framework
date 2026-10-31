// Datos de ejemplo para trabajar en el navegador, sin el juego
import type { ActionResult, AdminData, Ban, LogEntry, Option } from '../types';

const now = () => Math.floor(Date.now() / 1000);

const jobs = [
  { name: 'ambulance', label: 'Paramédico', grades: [{ value: 0, label: 'Practicante' }, { value: 1, label: 'Paramédico' }, { value: 2, label: 'Jefe médico' }] },
  { name: 'unemployed', label: 'Desempleado', grades: [{ value: 0, label: 'Desempleado' }] },
  { name: 'mechanic', label: 'Mecánico', grades: [{ value: 0, label: 'Aprendiz' }, { value: 1, label: 'Mecánico' }, { value: 2, label: 'Jefe de taller' }] },
  { name: 'police', label: 'Policía', grades: [{ value: 0, label: 'Cadete' }, { value: 1, label: 'Agente' }, { value: 2, label: 'Sargento' }, { value: 3, label: 'Comisario' }] },
];

const state: AdminData = {
  me: {
    id: 1,
    name: 'Ana García',
    level: 'admin',
    actions: [
      'goto', 'bring', 'spectate', 'freeze', 'revive', 'heal', 'kick', 'ban', 'viewInventory', 'kill', 'money', 'setJob', 'setDuty',
      'giveItem', 'clearInventory', 'giveVehicle', 'noclip', 'invisible', 'players', 'tpWaypoint', 'tpCoords', 'god', 'vehicleRepair',
      'vehicleFlip', 'vehicleDelete', 'spawnVehicle', 'clearVehicles', 'announce', 'weather', 'time', 'saveAll', 'unban', 'banOffline',
    ],
  },
  players: [
    { id: 1, name: 'Ana García', fivemName: 'anita', ping: 24, license: 'license:1a2b3c', identifier: 'JJ4K2M9QXA', loaded: true, frozen: false, level: 'admin', bucket: 0, health: 200, armour: 50, down: false, job: { name: 'police', label: 'Policía', grade: 3, gradeLabel: 'Comisario', onDuty: true }, accounts: { cash: 1250, bank: 48200, black: 0 } },
    { id: 4, name: 'Marcos Ruiz', fivemName: 'marcos_rp', ping: 62, license: 'license:4d5e6f', identifier: 'JJP7Q1ZLMC', loaded: true, frozen: false, level: 'none', bucket: 0, health: 142, armour: 0, down: false, job: { name: 'mechanic', label: 'Mecánico', grade: 1, gradeLabel: 'Mecánico', onDuty: true }, accounts: { cash: 320, bank: 9100, black: 1500 } },
    { id: 7, name: 'Lucía Torres', fivemName: 'luu', ping: 38, license: 'license:7a8b9c', identifier: 'JJD3V8HNWT', loaded: true, frozen: false, level: 'mod', bucket: 0, health: 200, armour: 0, down: false, job: { name: 'ambulance', label: 'Paramédico', grade: 2, gradeLabel: 'Jefe médico', onDuty: true }, accounts: { cash: 90, bank: 22750, black: 0 } },
    { id: 12, name: 'Pablo Vega', fivemName: 'pablov', ping: 110, license: 'license:0d1e2f', identifier: 'JJR5T2YBEK', loaded: true, frozen: true, level: 'none', bucket: 0, health: 104, armour: 0, down: true, job: { name: 'unemployed', label: 'Desempleado', grade: 0, gradeLabel: 'Desempleado', onDuty: true }, accounts: { cash: 15, bank: 400, black: 0 } },
    { id: 15, name: 'nuevo_jugador', fivemName: 'nuevo_jugador', ping: 75, license: 'license:3f4a5b', loaded: false, frozen: false, level: 'none', bucket: 1015 },
  ],
  maxPlayers: 48,
  stats: { police: 1, ambulance: 1, bans: 2 },
  jobs,
  accounts: [{ name: 'bank', label: 'Banco' }, { name: 'black', label: 'Dinero negro' }, { name: 'cash', label: 'Efectivo' }],
  weatherOptions: [
    { value: 'EXTRASUNNY', label: 'Muy soleado' }, { value: 'CLEAR', label: 'Despejado' }, { value: 'CLOUDS', label: 'Nublado' },
    { value: 'FOGGY', label: 'Niebla' }, { value: 'RAIN', label: 'Lluvia' }, { value: 'THUNDER', label: 'Tormenta' }, { value: 'SNOW', label: 'Nieve' },
  ],
  vehiclePresets: ['adder', 'zentorno', 't20', 'sultan', 'police', 'ambulance', 'sanchez', 'buzzard2', 'dinghy'],
  weather: false,
  time: false,
  toggles: { noclip: false, god: false, invisible: false, players: false },
};

let bans: Ban[] = [
  { id: 2, license: 'license:9c8b7a', name: 'cheater_01', reason: 'Uso de programas externos', admin: 'Ana García', created_at: now() - 86400, expires_at: null },
  { id: 1, license: 'license:6f5e4d', name: 'trollazo', reason: 'Antirol reiterado en comisaría', admin: 'Lucía Torres', created_at: now() - 3600, expires_at: now() + 86400 * 3 },
];

const logs: LogEntry[] = [
  { id: 5, admin: 'Ana García', action: 'ban', target: 'cheater_01', details: 'Uso de programas externos (permanente)', created_at: now() - 120 },
  { id: 4, admin: 'Lucía Torres', action: 'revive', target: 'pablov', details: null, created_at: now() - 900 },
  { id: 3, admin: 'Ana García', action: 'money', target: 'Marcos Ruiz', details: 'add bank 5000', created_at: now() - 2400 },
  { id: 2, admin: 'Ana García', action: 'giveVehicle', target: 'Marcos Ruiz', details: 'sultan K2M9QXA4', created_at: now() - 5400 },
  { id: 1, admin: 'Lucía Torres', action: 'announce', target: null, details: 'Reinicio en 10 minutos', created_at: now() - 7200 },
];

export const mockItems: Option[] = [
  { value: 'bandage', label: 'Bandage (bandage)' },
  { value: 'burger', label: 'Burger (burger)' },
  { value: 'lockpick', label: 'Lockpick (lockpick)' },
  { value: 'phone', label: 'Phone (phone)' },
  { value: 'WEAPON_PISTOL', label: 'Pistol (WEAPON_PISTOL)' },
  { value: 'water', label: 'Water (water)' },
];

export const mockData = (): AdminData => structuredClone(state);
export const mockBans = (): Ban[] => structuredClone(bans);
export const mockLogs = (): LogEntry[] => structuredClone(logs);

const TOGGLES = ['noclip', 'god', 'invisible', 'players'] as const;

export function mockAction(action: string, payload: Record<string, unknown>): ActionResult {
  const target = state.players.find((player) => player.id === payload.target);

  if ((TOGGLES as readonly string[]).includes(action)) {
    const key = action as (typeof TOGGLES)[number];
    state.toggles[key] = !state.toggles[key];
    return { ok: true };
  }
  if (action === 'freeze' && target) {
    target.frozen = !target.frozen;
    return { ok: true, message: target.frozen ? 'Jugador congelado' : 'Jugador descongelado' };
  }
  if (action === 'unban') {
    bans = bans.filter((ban) => ban.id !== payload.id);
    state.stats.bans = bans.length;
    return { ok: true, message: 'Baneo eliminado' };
  }
  if ((action === 'kick' || action === 'ban') && target) {
    state.players = state.players.filter((player) => player !== target);
    return { ok: true, message: action === 'kick' ? 'Jugador expulsado' : 'Jugador baneado' };
  }
  if (action === 'weather') {
    state.weather = (payload.weather as string | false) ?? false;
    return { ok: true, message: 'Clima cambiado' };
  }
  if (action === 'time') {
    state.time = payload.hour === false ? false : { hour: Number(payload.hour), minute: Number(payload.minute ?? 0) };
    return { ok: true, message: 'Hora cambiada' };
  }
  return { ok: true, message: `Acción "${action}" enviada (ejemplo)` };
}
