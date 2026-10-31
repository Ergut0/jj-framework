import { useEffect, useRef } from 'react';

declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = () => !window.invokeNative;

export async function fetchNui<T = unknown>(event: string, data?: unknown): Promise<T | undefined> {
  if (isBrowser()) return undefined;
  try {
    const response = await fetch(`https://${window.GetParentResourceName!()}/${event}`, {
      method: 'post',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    return await response.json();
  } catch {
    return undefined;
  }
}

export function useNuiEvent<T = unknown>(action: string, handler: (data: T) => void) {
  const saved = useRef(handler);

  useEffect(() => {
    saved.current = handler;
  }, [handler]);

  useEffect(() => {
    const listener = (event: MessageEvent<{ action?: string; data: T }>) => {
      if (event.data.action !== action) return;
      try {
        saved.current(event.data.data);
      } catch (error) {
        console.error(`Error in useNuiEvent handler for action ${action}:`, error);
      }
    };
    window.addEventListener('message', listener);
    return () => window.removeEventListener('message', listener);
  }, [action]);
}
