export interface Point {
  x: number;
  y: number;
  z: number;
}

export interface ZoneShape {
  points: Point[];
  thickness: number;
}

export interface Zone {
  id: number;
  label?: string;
  entorno: string;
  coords: ZoneShape;
  duration: number;
  color: string;
  enabled: boolean;
  createdBy?: string;
}

declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = !window.invokeNative;

const resource = window.GetParentResourceName?.() ?? 'jj_entornozones';

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

export const normalizeZones = (zones: unknown): Zone[] =>
  toList<Zone>(zones).map((zone) => ({ ...zone, coords: { ...zone.coords, points: toList<Point>(zone.coords?.points) } }));

const square = (x: number, y: number): ZoneShape => ({
  points: [
    { x, y, z: 29 },
    { x: x + 40, y, z: 29 },
    { x: x + 40, y: y + 30, z: 29 },
    { x, y: y + 30, z: 29 },
  ],
  thickness: 12,
});

// Datos para ver el panel en el navegador
export const sampleZones: Zone[] = [
  { id: 1, label: 'Taller de Sandy', entorno: 'Huele a gasolina y aceite quemado. Se oyen motores revolucionados al fondo.', coords: square(1700, 3600), duration: 10, color: '#9B30FF', enabled: true, createdBy: 'JJ7K2M9QX' },
  { id: 2, label: 'Callejón de Davis', entorno: 'Un callejón oscuro lleno de grafitis. Hay jeringuillas en el suelo y alguien vigila desde una ventana.', coords: square(80, -1600), duration: 12, color: '#F97316', enabled: true },
  { id: 3, entorno: 'El muelle está desierto. Solo se oye el agua golpeando los pilares.', coords: square(-1600, -1100), duration: 8, color: '#38D9F5', enabled: false },
];
