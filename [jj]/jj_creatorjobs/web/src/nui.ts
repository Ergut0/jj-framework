import { mockRequest } from './mock';

declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = () => !window.invokeNative;

// En el navegador no hay juego: responde la simulación de mock.ts
async function fetchNui<T>(name: string, data?: unknown): Promise<T> {
  if (isBrowser()) return mockRequest(name, data) as T;

  const resource = window.GetParentResourceName?.() ?? 'jj_creatorjobs';
  const response = await fetch(`https://${resource}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  });
  return response.json();
}

export const api = {
  getPanel: <T>() => fetchNui<T | false>('getPanel'),
  getJob: <T>(name: string) => fetchNui<T | false>('getJob', name),
  getLogs: <T>(name: string) => fetchNui<T>('getLogs', name),
  getGlobalTeleports: <T>() => fetchNui<T>('getGlobalTeleports'),
  action: (name: string, data: unknown) => fetchNui<boolean>('action', { name, data }),
  getCoords: <T>() => fetchNui<T>('getCoords'),
  tp: (coords: { x: number; y: number; z: number }) => fetchNui('tp', coords),
  close: () => fetchNui('hideFrame'),
};
