import { useMemo } from "react";
import { useApp } from "@/lib/store";
import type { Crew, NuiResponse, PermissionKey } from "@/lib/types";

/**
 * Contexto de gestion de un crew. Permite reutilizar los mismos componentes en el panel
 * de jugador y en el de administracion: solo cambia como se lanzan las acciones.
 * (La autoridad real siempre esta en el servidor.)
 */
export interface CrewCtx {
  crew: Crew;
  admin: boolean;
  /** nivel de rango del actor (los admin se consideran por encima de todos) */
  level: number;
  isLeader: boolean;
  can: (p: PermissionKey) => boolean;
  run: <T = unknown>(op: string, payload?: Record<string, unknown>, okMsg?: string) => Promise<NuiResponse<T>>;
  refresh: () => Promise<void>;
}

const adminOps: Record<string, string> = {
  transferLeader: "adminSetLeader",
  invite: "adminAddMember",
};

export function useCrewCtx(crew: Crew, admin: boolean, refreshAdmin?: () => Promise<void> | void): CrewCtx {
  const { call, reload } = useApp();
  return useMemo<CrewCtx>(
    () => ({
      crew,
      admin,
      level: admin ? 1000 : (crew.me?.level ?? 0),
      isLeader: admin || !!crew.me?.isLeader,
      can: (p) => admin || !!crew.me?.permissions[p],
      run: (op, payload = {}, okMsg) =>
        admin
          ? call(adminOps[op] ?? `admin${op[0]!.toUpperCase()}${op.slice(1)}`, { id: crew.id, ...payload }, okMsg)
          : call(op, payload, okMsg),
      refresh: async () => {
        if (admin) await refreshAdmin?.();
        else await reload();
      },
    }),
    [crew, admin, call, reload, refreshAdmin],
  );
}
