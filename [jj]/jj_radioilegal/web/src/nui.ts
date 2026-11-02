export interface RadioPlayer {
  id: number;
  name: string;
}

declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = !window.invokeNative;

const resource = window.GetParentResourceName?.() ?? 'jj_radioilegal';

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

// Datos para ver el panel en el navegador
export const sampleFrequencies: RadioPlayer[][] = [
  [
    { id: 1, name: 'Marco Vidal' },
    { id: 12, name: 'Lucía Ferrer' },
    { id: 31, name: 'Dani Ortega' },
  ],
  [],
  [{ id: 8, name: 'Nora Blanco' }],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
];
