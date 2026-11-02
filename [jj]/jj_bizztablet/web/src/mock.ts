import type { Business, Item, TabletData, TabletEvent } from './types';

// Datos de ejemplo para trabajar la interfaz en el navegador, fuera del juego
const svg = (color: string, text: string) =>
  `data:image/svg+xml,${encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200"><rect width="200" height="200" fill="${color}"/><text x="100" y="125" font-size="80" font-family="sans-serif" fill="white" text-anchor="middle">${text}</text></svg>`,
  )}`;

const item = (name: string, label: string, price: number, color = '#3b2352'): Item => ({
  name,
  label,
  price,
  image: svg(color, label[0]),
});

const food = [item('burger', 'Hamburguesa', 45), item('refresco', 'Refresco', 15), item('croissant_mixto', 'Croissant mixto', 20), item('cafe', 'Café', 10)];
const garage = [item('repairkit', 'Kit de reparación', 250), item('carlockpick', 'Ganzúa', 150)];

const jobs: Business[] = [
  {
    name: 'burgershot',
    label: 'Burger Shot',
    logo: svg('#b45309', 'B'),
    description: 'Las mejores hamburguesas de la ciudad, recién hechas y a cualquier hora.',
    discordUrl: 'https://discord.gg/ejemplo',
    category: 'food',
    coords: { x: -1191.2, y: -889.7, z: 13.9 },
    categories: [{ id: 'category-1', label: 'Menú', items: food.slice(0, 3) }],
    promotions: [{ id: 'promo-1', item: food[0], originalPrice: 60, promotionalPrice: 45 }],
    market: food,
    status: 'open',
  },
  {
    name: 'mechanic',
    label: 'Benny\'s Motorworks',
    logo: svg('#1d4ed8', 'M'),
    description: '',
    discordUrl: '',
    category: 'mechanics',
    coords: { x: -205.7, y: -1310.4, z: 31.3 },
    categories: [],
    promotions: [],
    market: garage,
    status: 'closed',
  },
  {
    name: 'vanilla',
    label: 'Vanilla Unicorn',
    logo: svg('#be185d', 'V'),
    description: 'Música, copas y espectáculo hasta el amanecer.',
    discordUrl: '',
    category: 'leisure',
    coords: { x: 129.2, y: -1283.1, z: 29.3 },
    categories: [],
    promotions: [],
    market: [],
    status: 'in_event',
  },
  {
    name: 'taxi',
    label: 'Downtown Cab Co.',
    logo: svg('#ca8a04', 'T'),
    description: 'Te llevamos a donde quieras.',
    discordUrl: '',
    category: 'services',
    categories: [],
    promotions: [],
    market: [],
    status: 'open',
  },
];

const hour = 3600000;
const now = Date.now();
let nextId = 4;
let events: TabletEvent[] = [
  { id: 1, job: 'vanilla', title: 'Noche de apertura', startAt: now - hour, endAt: now + 2 * hour, location: 'Vanilla Unicorn', description: 'Música en directo y consumiciones gratis para los primeros en llegar.', organizer: 'Vanilla Unicorn', imageUrl: svg('#7e22ce', '★'), cancelled: false },
  { id: 2, job: 'burgershot', title: 'Concurso de hamburguesas', startAt: now + 48 * hour, endAt: now + 51 * hour, location: 'Burger Shot', description: 'Quien se coma más gana un mes de menús.', organizer: 'Burger Shot', imageUrl: '', cancelled: false },
  { id: 3, job: 'burgershot', title: 'Torneo de pool', startAt: now - 72 * hour, endAt: now - 70 * hour, location: 'Yellow Jack', description: '', organizer: 'Burger Shot', imageUrl: '', cancelled: false },
];

export const mockData = (): TabletData => ({
  jobs,
  events,
  currentJob: 'burgershot',
  isBoss: true,
  hasPerms: new URLSearchParams(location.search).has('admin'),
});

export function mockRequest(name: string, data: any): unknown {
  switch (name) {
    case 'tablet:getCoords':
      return { x: 215.76, y: -810.12, z: 30.73 };
    case 'tablet:createEvent':
      events = [...events, { ...data, id: nextId++, job: 'burgershot', cancelled: false }];
      window.postMessage({ type: 'tablet:updateEvents', data: events });
      return { success: true };
    case 'tablet:updateEvent':
      events = events.map((e) => (e.id === data.id ? { ...e, ...data } : e));
      window.postMessage({ type: 'tablet:updateEvents', data: events });
      return { success: true };
    case 'tablet:cancelEvent':
      events = events.map((e) => (e.id === data ? { ...e, cancelled: true } : e));
      window.postMessage({ type: 'tablet:updateEvents', data: events });
      return { success: true };
    case 'tablet:deleteEvent':
      events = events.filter((e) => e.id !== data);
      window.postMessage({ type: 'tablet:updateEvents', data: events });
      return { success: true };
    case 'business:update':
      window.postMessage({ type: 'tablet:updateJob', data });
      return { success: true };
    default:
      return 'ok';
  }
}
