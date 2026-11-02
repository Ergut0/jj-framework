import { useEffect } from 'react';

declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = () => !window.invokeNative;

export function fetchNui(name: string, data?: unknown) {
  if (isBrowser()) return;

  const resource = window.GetParentResourceName?.() ?? 'jj_pausemenu';
  fetch(`https://${resource}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  }).catch(() => undefined);
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
