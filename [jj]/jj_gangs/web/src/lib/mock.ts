// Datos de ejemplo para trabajar en el navegador, sin el juego
import type { ActionResult, Gang, PanelData, Payload } from '../types';

const config: PanelData['config'] = {
  pointTypes: [
    { value: 'stash', label: 'Armario' },
    { value: 'garage', label: 'Garaje' },
    { value: 'boss', label: 'Gestión de la banda' },
    { value: 'lab', label: 'Laboratorio' },
    { value: 'wardrobe', label: 'Ropero' },
  ],
  labs: [
    { value: 'coke', label: 'Cocaína' },
    { value: 'weed', label: 'Marihuana' },
    { value: 'meth', label: 'Metanfetamina' },
  ],
  colors: [
    { value: 1, label: 'Rojo', hex: '#e03232' },
    { value: 2, label: 'Verde', hex: '#4bb543' },
    { value: 3, label: 'Azul', hex: '#5ab4e6' },
    { value: 4, label: 'Amarillo', hex: '#f0cb58' },
    { value: 5, label: 'Morado', hex: '#a855f7' },
    { value: 6, label: 'Naranja', hex: '#f08a24' },
    { value: 7, label: 'Rosa', hex: '#f472b6' },
    { value: 8, label: 'Blanco', hex: '#f4f4f5' },
  ],
  ranks: [
    { value: 0, label: 'Oficial' },
    { value: 1, label: 'Sub Jefe' },
    { value: 2, label: 'Jefe' },
  ],
  minRadius: 30,
  maxRadius: 600,
  defaultRadius: 150,
  maxGraffitis: 15,
};

let nextId = 100;

const state: PanelData = {
  config,
  players: [
    { id: 1, name: 'Ana García', gang: 'Ballas' },
    { id: 4, name: 'Marcos Ruiz' },
    { id: 7, name: 'Lucía Torres', gang: 'Vagos' },
    { id: 12, name: 'Pablo Vega' },
  ],
  gangs: [
    {
      id: 1, label: 'Ballas', color: 5, hex: '#a855f7', x: 85.3, y: -1959.2, z: 20.8, radius: 180,
      points: [
        { id: 1, type: 'boss', x: 87.1, y: -1962.4, z: 20.7 },
        { id: 2, type: 'stash', x: 90.5, y: -1958.1, z: 20.7 },
        { id: 3, type: 'wardrobe', x: 92.2, y: -1955.7, z: 20.7 },
        { id: 4, type: 'garage', x: 101.6, y: -1950.3, z: 20.6 },
        { id: 5, type: 'lab', lab: 'meth', x: 75.9, y: -1970.3, z: 20.7 },
      ],
      members: [
        { identifier: 'JJ4K2M9QXA', name: 'Ana García', rank: 2, online: true, source: 1 },
        { identifier: 'JJP7Q1ZLMC', name: 'Rubén Sanz', rank: 1, online: false },
        { identifier: 'JJD3V8HNWT', name: 'Iván Mora', rank: 0, online: false },
      ],
      graffitis: [
        { id: 1, x: 70.2, y: -1940.6, z: 21.4, nx: 1, ny: 0, nz: 0, author: 'Ana García' },
        { id: 2, x: 120.8, y: -1980.1, z: 21.1, nx: 0, ny: 1, nz: 0, author: 'Rubén Sanz', url: 'https://docs.fivem.net/vehicles/adder.webp' },
      ],
    },
    {
      id: 2, label: 'Vagos', color: 4, hex: '#f0cb58', x: 334.2, y: -2039.5, z: 21.1, radius: 220,
      points: [{ id: 6, type: 'lab', lab: 'weed', x: 340.1, y: -2042.2, z: 21.2 }],
      members: [{ identifier: 'JJR5T2YBEK', name: 'Lucía Torres', rank: 2, online: true, source: 7 }],
      graffitis: [],
    },
    {
      id: 3, label: 'Families', color: 2, hex: '#4bb543', x: -120.4, y: -1560.7, z: 34.1, radius: 150,
      points: [], members: [], graffitis: [],
    },
  ],
};

export const mockData = (): PanelData => structuredClone(state);

const findGang = (payload: Payload): Gang | undefined => state.gangs.find((gang) => gang.id === payload.gang);

export function mockAction(action: string, payload: Payload): ActionResult {
  const gang = findGang(payload);

  switch (action) {
    case 'create': {
      const color = config.colors.find((option) => option.value === payload.color) ?? config.colors[0];
      const id = nextId++;
      state.gangs.push({
        id, label: String(payload.label), color: color.value, hex: color.hex, x: 1, y: 2, z: 3,
        radius: Number(payload.radius), points: [], members: [], graffitis: [],
      });
      state.gangs.sort((a, b) => a.label.localeCompare(b.label));
      return { ok: true, message: `Banda ${payload.label} creada`, id };
    }
    case 'radius':
    case 'territory':
      if (gang) gang.radius = Number(payload.radius);
      return { ok: true, message: 'Barrio actualizado' };
    case 'rename':
      if (gang) gang.label = String(payload.label);
      return { ok: true, message: 'Nombre actualizado' };
    case 'color': {
      const color = config.colors.find((option) => option.value === payload.color);
      if (gang && color) {
        gang.color = color.value;
        gang.hex = color.hex;
      }
      return { ok: true, message: 'Color actualizado' };
    }
    case 'addPoint':
      gang?.points.push({ id: nextId++, type: String(payload.type), lab: payload.lab as string | undefined, x: 10, y: 20, z: 30 });
      return { ok: true, message: 'Punto añadido' };
    case 'movePoint':
      return { ok: true, message: 'Punto movido' };
    case 'removePoint':
      if (gang) gang.points = gang.points.filter((point) => point.id !== payload.point);
      return { ok: true, message: 'Punto eliminado' };
    case 'memberAdd': {
      const player = state.players.find((option) => option.id === payload.target);
      if (gang && player) {
        gang.members = gang.members.filter((member) => member.name !== player.name);
        gang.members.push({ identifier: `JJ${player.id}`, name: player.name, rank: Number(payload.rank), online: true, source: player.id });
        player.gang = gang.label;
      }
      return { ok: true, message: 'Miembro añadido' };
    }
    case 'memberRank':
      gang?.members.forEach((member) => {
        if (member.identifier === payload.identifier) member.rank = Number(payload.rank);
        else if (payload.rank === 2 && member.rank === 2) member.rank = 1;
      });
      return { ok: true, message: 'Rango actualizado' };
    case 'memberKick':
      if (gang) gang.members = gang.members.filter((member) => member.identifier !== payload.identifier);
      return { ok: true, message: 'Miembro expulsado' };
    case 'removeGraffiti':
      if (gang) gang.graffitis = gang.graffitis.filter((graffiti) => graffiti.id !== payload.graffiti);
      return { ok: true, message: 'Grafiti borrado' };
    case 'delete':
      state.gangs = state.gangs.filter((other) => other !== gang);
      return { ok: true, message: 'Banda eliminada' };
    case 'teleport':
      return { ok: true, message: 'Te has teletransportado' };
    default:
      return { ok: false, message: 'Acción no válida' };
  }
}
