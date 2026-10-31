// Datos de ejemplo para trabajar en el navegador, sin el juego
import type { Access, RawMessage, Suggestion } from '../types';

export const mockAccess: Access = { staff: true, job: 'Policía' };

export const mockSuggestions: Suggestion[] = [
  { name: '/b', help: 'Habla fuera de personaje', params: [{ name: 'mensaje' }] },
  { name: '/dep', help: 'Canal de tu trabajo, si estás de servicio', params: [{ name: 'mensaje' }] },
  { name: '/do', help: '', params: [] },
  { name: '/entorno', help: '', params: [] },
  { name: '/g', help: 'Grita: te oyen desde más lejos', params: [{ name: 'mensaje' }] },
  { name: '/gritar', help: 'Grita: te oyen desde más lejos', params: [{ name: 'mensaje' }] },
  { name: '/limpiarchat', help: 'Borra tu chat', params: [] },
  { name: '/me', help: '', params: [] },
  { name: '/mp', help: 'Mensaje privado', params: [{ name: 'id' }, { name: 'mensaje' }] },
  { name: '/ooc', help: 'Habla fuera de personaje', params: [{ name: 'mensaje' }] },
  { name: '/r', help: 'Responde al último mensaje privado', params: [{ name: 'mensaje' }] },
  { name: '/reporte', help: 'Avisa al staff de un problema', params: [{ name: 'mensaje' }] },
  { name: '/silenciar', help: 'Silencia a un jugador en el chat', params: [{ name: 'id' }, { name: 'minutos' }, { name: 'motivo' }] },
  { name: '/staff', help: 'Canal de staff', params: [{ name: 'mensaje' }] },
];

export const mockMessages: RawMessage[] = [
  { channel: 'system', tag: 'Sistema', text: 'Bienvenida al servidor. Usa /reporte si necesitas al staff.' },
  { channel: 'local', author: 'Marcos Ruiz', id: 4, text: '¿Sabes dónde queda el taller de la calle Strawberry?' },
  { channel: 'local', author: 'Ana García', id: 1, text: 'Sigue recto y gira en el segundo semáforo.' },
  { channel: 'local', color: [194, 162, 218], args: ['[ME] Marcos Ruiz', 'saca el móvil y mira el mapa'] },
  { channel: 'local', color: [100, 180, 240], args: ['[DO] Ana García', 'se vería un coche patrulla aparcado detrás'] },
  { channel: 'local', tag: 'Grita', author: 'Pablo Vega', id: 12, text: '¡Que alguien llame a una ambulancia!' },
  { channel: 'ooc', tag: 'OOC', author: 'Lucía Torres', id: 7, text: 'Perdón, se me ha cortado la conexión un momento' },
  { channel: 'job', tag: 'Policía', author: 'Ana García', detail: 'Comisario', id: 1, text: 'Unidad 3, acudid a Vespucci, por favor.' },
  { channel: 'pm', tag: 'De', author: 'Lucía Torres', id: 7, text: '¿Puedes ayudarme con una duda de la policía?' },
  { channel: 'staff', tag: 'Reporte', author: 'Marcos Ruiz', id: 4, text: 'Un jugador está chocando coches a propósito en la plaza.' },
  { args: ['^3Anuncios', 'Mensaje de otro recurso con ^1color^7 de FiveM'] },
];

const SEND_MESSAGE: Record<string, RawMessage> = {
  say: { channel: 'local' },
  ooc: { channel: 'ooc', tag: 'OOC' },
  job: { channel: 'job', tag: 'Policía', detail: 'Comisario' },
  staff: { channel: 'staff', tag: 'Staff' },
  reply: { channel: 'pm', tag: 'Para' },
};

export const mockSubmit = (channel: string, text: string): RawMessage =>
  text.startsWith('/')
    ? { channel: 'system', tag: 'Sistema', text: `Comando enviado: ${text}` }
    : { ...SEND_MESSAGE[channel], author: 'Ana García', id: 1, text };
