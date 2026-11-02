import type { NuiResponse } from "../types";
import { MockError, wait, type Handler } from "./db";
import { playerHandlers } from "./player";
import { adminHandlers } from "./admin";

const handlers: Record<string, Handler> = { ...playerHandlers, ...adminHandlers };

/** Backend simulado para desarrollo en navegador: responde como lo haria el servidor Lua */
export async function mockNui<T>(action: string, data: unknown): Promise<NuiResponse<T>> {
  await wait();
  const handler = handlers[action];
  if (!handler) return { ok: false, error: `mock: accion desconocida "${action}"`, code: "generic" };
  try {
    return { ok: true, data: (await handler(data ?? {})) as T };
  } catch (e) {
    if (e instanceof MockError) return { ok: false, error: e.message, code: e.code };
    console.error("[mock]", action, e);
    return { ok: false, error: "Error interno del mock", code: "generic" };
  }
}
