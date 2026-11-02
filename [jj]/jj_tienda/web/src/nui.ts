export interface Item {
  index: number;
  img: string;
  label: string;
  price: number;
  category: string;
}

export interface BuyResult {
  ok: boolean;
  message: string;
  balance?: number;
}

declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = !window.invokeNative;

const resource = window.GetParentResourceName?.() ?? 'jj_tienda';

export async function fetchNui<T>(name: string, data: unknown = {}): Promise<T | undefined> {
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

// Datos de ejemplo para ver la interfaz en el navegador, sin el juego
const sample: [string, string, number, string][] = [
  ['valecoleccionable.png', 'Vale Coleccionable', 25000, 'Vales'],
  ['valetuneo.png', 'Vale Tuneo', 25000, 'Vales'],
  ['vale3x3.png', 'Vale 3x3', 25000, 'Vales'],
  ['valevip.png', 'Vale Coche VIP', 50000, 'Vales'],
  ['valedeluxe.png', 'Vale Coche Deluxe', 60000, 'Vales'],
  ['neon.webp', 'Pfister Neon', 60000, 'Coches'],
  ['jester4.webp', 'Dinka Jester RR', 65000, 'Coches'],
  ['growler.webp', 'Pfister Growler', 70000, 'Coches'],
  ['italigto.webp', 'Grotti Itali GTO', 80000, 'Coches'],
  ['italirsx.webp', 'Grotti Itali RSX', 90000, 'Coches'],
  ['xa21.webp', 'Ocelot XA-21', 95000, 'Coches'],
  ['visione.webp', 'Grotti Visione', 100000, 'Coches'],
  ['tigon.webp', 'Lampadati Tigon', 105000, 'Coches'],
  ['entity3.webp', 'Överflöd Entity MT', 110000, 'Coches'],
  ['furia.webp', 'Grotti Furia', 115000, 'Coches'],
  ['emerus.webp', 'Progen Emerus', 120000, 'Coches'],
  ['zeno.webp', 'Överflöd Zeno', 125000, 'Coches'],
  ['thrax.webp', 'Truffade Thrax', 130000, 'Coches'],
  ['krieger.webp', 'Benefactor Krieger', 135000, 'Coches'],
  ['ignus.webp', 'Pegassi Ignus', 145000, 'Coches'],
  ['turismo3.webp', 'Grotti Turismo Omaggio', 150000, 'Coches'],
];

export const sampleItems: Item[] = sample.map(([img, label, price, category], position) => ({
  index: position + 1,
  img,
  label,
  price,
  category,
}));
