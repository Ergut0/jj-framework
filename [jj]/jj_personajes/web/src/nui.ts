export interface Character {
  identifier: string;
  name: string;
  birthdate: string;
  nationality: string;
  gender: number;
  job: string;
  grade: string;
  cash: number;
  bank: number;
  secondsAgo?: number;
  place?: string;
}

export interface ScreenData {
  characters: Character[] | Record<string, Character>;
  slots: number;
  maxSlots: number;
  minAge: number;
  maxAge: number;
}

declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = !window.invokeNative;

const resource = window.GetParentResourceName?.() ?? 'jj_personajes';

export async function fetchNui<T>(name: string, data: unknown = {}): Promise<T | undefined> {
  if (isBrowser) return { success: true } as T;
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

// Datos para ver la pantalla en el navegador
export const sample: ScreenData = {
  characters: [
    { identifier: 'JJ7K2M9QX', name: 'Marco Vidal', birthdate: '14/03/1994', nationality: 'España', gender: 0, job: 'Policía', grade: 'Oficial', cash: 4250, bank: 186300, secondsAgo: 7200, place: 'Vinewood Blvd, Downtown Vinewood' },
    { identifier: 'JJ3PL8DWA', name: 'Lucía Ferrer', birthdate: '02/11/1998', nationality: 'Argentina', gender: 1, job: 'Sin trabajo', grade: 'Desempleado', cash: 320, bank: 12800, secondsAgo: 302400, place: 'Grove St, Davis' },
  ],
  slots: 3,
  maxSlots: 5,
  minAge: 18,
  maxAge: 90,
};
