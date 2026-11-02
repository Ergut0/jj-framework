import { useEffect, useRef } from "react";
import type { NuiResponse } from "./types";

/** true cuando la pagina se abre en un navegador normal (modo desarrollo con mock) */
export const isEnvBrowser = (): boolean => !(window as unknown as { invokeNative?: unknown }).invokeNative;

const TIMEOUT_MS = 10000;

/**
 * Envia una peticion a Lua (RegisterNUICallback) y devuelve la respuesta tipada.
 * En el navegador se resuelve contra el backend simulado de lib/mock.ts.
 */
export async function fetchNui<T = unknown>(action: string, data: unknown = {}): Promise<NuiResponse<T>> {
  if (isEnvBrowser()) {
    const { mockNui } = await import("./mock");
    return mockNui<T>(action, data);
  }

  const resource =
    (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName?.() ?? "crews";
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(`https://${resource}/${action}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(data),
      signal: ctrl.signal,
    });
    return (await res.json()) as NuiResponse<T>;
  } catch {
    return { ok: false, error: "timeout" };
  } finally {
    clearTimeout(timer);
  }
}

interface NuiMessage<T = unknown> {
  action: string;
  [key: string]: unknown;
  data?: T;
}

/** Suscribe un handler a los SendNUIMessage de Lua con la clave `action` indicada */
export function useNuiEvent(action: string, handler: (msg: NuiMessage) => void) {
  const saved = useRef(handler);
  saved.current = handler;
  useEffect(() => {
    const listener = (e: MessageEvent<NuiMessage>) => {
      if (e.data && e.data.action === action) saved.current(e.data);
    };
    window.addEventListener("message", listener);
    return () => window.removeEventListener("message", listener);
  }, [action]);
}
