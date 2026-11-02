import type { RaceSettings } from "@/lib/types";

// Espejo de SettingsSchema (server/main.lua): el servidor sigue siendo quien valida
export interface IntBound {
  min: number;
  max: number;
}
export interface ListBound extends IntBound {
  maxItems: number;
  sumMax?: number;
}

type NumericKeys = {
  [K in keyof RaceSettings]: RaceSettings[K] extends number ? K : never;
}[keyof RaceSettings];
type ListKeys = {
  [K in keyof RaceSettings]: RaceSettings[K] extends number[] ? K : never;
}[keyof RaceSettings];

export const INT_BOUNDS: Record<NumericKeys, IntBound> = {
  maxPlayers: { min: 2, max: 32 },
  minPlayersToStart: { min: 1, max: 32 },
  minPlayersForRewards: { min: 1, max: 32 },
  maxLaps: { min: 1, max: 100 },
  countdownSeconds: { min: 3, max: 30 },
  finishGraceSeconds: { min: 10, max: 900 },
  entryFeeMax: { min: 0, max: 10000000 },
  extraPrizeMax: { min: 0, max: 10000000 },
  baseMaxPrize: { min: 0, max: 10000000 },
  commissionPct: { min: 0, max: 100 },
  openLobbyMinutes: { min: 1, max: 240 },
  crewFinishPoints: { min: 0, max: 100000 },
  crewMaxPointsPerRace: { min: 0, max: 1000000 },
  crewPrizeSharePct: { min: 0, max: 100 },
  crewVsWinPoints: { min: 0, max: 1000000 },
  crewVsStakeMax: { min: 0, max: 10000000 },
  crewVsMinRank: { min: 1, max: 99 },
};

export const LIST_BOUNDS: Record<ListKeys, ListBound> = {
  prizeSplit: { min: 0, max: 100, maxItems: 16, sumMax: 100 },
  pilotPoints: { min: 0, max: 10000, maxItems: 32 },
  crewPointsByPosition: { min: 0, max: 100000, maxItems: 32 },
};

export const FORMULAS = ["points", "positions", "best"] as const;

/** Claves de ajustes con un problema (vacio = valido) */
export function invalidSettings(s: RaceSettings): string[] {
  const bad: string[] = [];
  for (const [k, b] of Object.entries(INT_BOUNDS)) {
    const v = s[k as NumericKeys];
    if (!Number.isInteger(v) || v < b.min || v > b.max) bad.push(k);
  }
  for (const [k, b] of Object.entries(LIST_BOUNDS)) {
    const list = s[k as ListKeys];
    const sum = list.reduce((a, n) => a + n, 0);
    if (list.length > b.maxItems || list.some((n) => !Number.isInteger(n) || n < b.min || n > b.max) || (b.sumMax != null && sum > b.sumMax)) bad.push(k);
  }
  if (s.allowedClasses.length === 0) bad.push("allowedClasses");
  return bad;
}
