import { useEffect, useRef } from 'react';

declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = () => !window.invokeNative;

export async function fetchNui<T = unknown>(event: string, data?: unknown): Promise<T | undefined> {
  try {
    const response = await fetch(`https://${window.GetParentResourceName!()}/${event}`, {
      method: 'post',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data ?? {}),
    });
    return await response.json();
  } catch {
    return undefined;
  }
}

export function useNuiEvent(action: string, handler: () => void) {
  const saved = useRef(handler);

  useEffect(() => {
    saved.current = handler;
  }, [handler]);

  useEffect(() => {
    const listener = (event: MessageEvent<{ action?: string }>) => {
      if (event.data.action === action) saved.current();
    };
    window.addEventListener('message', listener);
    return () => window.removeEventListener('message', listener);
  }, [action]);
}
