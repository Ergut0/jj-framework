import { useEffect } from 'react';
import { mockRequest } from './mock';

declare global {
  interface Window {
    invokeNative?: (name: string, ...args: unknown[]) => void;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = () => !window.invokeNative;

// En el navegador no hay juego: responde la simulación de mock.ts
export async function fetchNui<T>(name: string, data?: unknown): Promise<T> {
  if (isBrowser()) return mockRequest(name, data) as T;

  const resource = window.GetParentResourceName?.() ?? 'jj_bizztablet';
  const response = await fetch(`https://${resource}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  });
  return response.json();
}

export function useNuiEvent<T>(type: string, handler: (data: T) => void) {
  useEffect(() => {
    const listener = (event: MessageEvent) => {
      if (event.data?.type === type) handler(event.data.data);
    };
    window.addEventListener('message', listener);
    return () => window.removeEventListener('message', listener);
  }, [type, handler]);
}

export function openUrl(url: string) {
  if (window.invokeNative) window.invokeNative('openUrl', url);
  else window.open(url, '_blank');
}
