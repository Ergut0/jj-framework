import type { DraftCheckpoint, DraftGrid, GameConfig, RoutePoint, TrackDetail, TrackDraft } from "@/lib/types";

export const COORD_MAX = 12000;
export const Z_MIN = -500;
export const Z_MAX = 3000;
export const TIME_LIMIT_MAX = 86400;
export const NAME_MIN = 3;
export const NAME_MAX = 48;
export const DESC_MAX = 255;

export function newDraft(config: GameConfig): TrackDraft {
  return {
    name: "",
    category: config.categories[0] ?? "street",
    difficulty: "medium",
    description: "",
    lapsDefault: config.pointToPoint.includes(config.categories[0] ?? "") ? 1 : 3,
    vehicleClass: "any",
    allowCrews: true,
    basePrize: 0,
    timeLimit: 0,
    collisions: true,
    checkpoints: [],
    grid: [],
  };
}

/** Convierte el detalle de administracion (adminGetTrack / adminSaveTrack) en un borrador editable */
export function draftFromDetail(d: TrackDetail): TrackDraft {
  return {
    id: d.id,
    name: d.name,
    category: d.category,
    difficulty: d.difficulty,
    description: d.description,
    lapsDefault: d.lapsDefault,
    vehicleClass: d.vehicleClass,
    allowCrews: d.allowCrews,
    basePrize: d.basePrize,
    timeLimit: d.timeLimit,
    collisions: d.collisions,
    checkpoints: (d.checkpoints ?? []).map(cleanCheckpoint),
    grid: d.grid.map((g) => ({ x: g.x, y: g.y, z: g.z ?? 0, h: g.h })),
  };
}

function cleanCheckpoint(c: DraftCheckpoint): DraftCheckpoint {
  const out: DraftCheckpoint = { kind: c.kind, x: c.x, y: c.y, z: c.z, radius: c.radius, height: c.height };
  if (c.kind === "shortcut") {
    out.linkFrom = c.linkFrom ?? 1;
    out.linkTo = c.linkTo ?? 3;
  }
  return out;
}

/** Firma comparable del borrador (ignora el cambio menor y campos calculados) */
export function draftSignature(d: TrackDraft): string {
  return JSON.stringify({
    ...d,
    minor: undefined,
    checkpoints: d.checkpoints.map(cleanCheckpoint),
    grid: d.grid.map((g) => ({ x: g.x, y: g.y, z: g.z, h: g.h })),
  });
}

export function normalCount(cps: DraftCheckpoint[]): number {
  return cps.filter((c) => c.kind === "normal").length;
}

/** Numero de secuencia (entre los normales) de cada checkpoint; undefined para atajos y pits */
export function sequences(cps: DraftCheckpoint[]): (number | undefined)[] {
  let n = 0;
  return cps.map((c) => (c.kind === "normal" ? ++n : undefined));
}

export function toRoute(cps: DraftCheckpoint[]): RoutePoint[] {
  const seqs = sequences(cps);
  return cps.map((c, i) => ({ x: c.x, y: c.y, kind: c.kind, seq: seqs[i], linkFrom: c.linkFrom, linkTo: c.linkTo }));
}

export function isPointToPoint(config: GameConfig, category: string): boolean {
  return config.pointToPoint.includes(category);
}

export interface Problem {
  key: string;
  vars?: Record<string, string | number>;
}

const inRange = (v: number, min: number, max: number) => Number.isFinite(v) && v >= min && v <= max;

/** Espejo de Validation.Track (server/validation.lua): lista de problemas que impedirian guardar */
export function validateDraft(d: TrackDraft, config: GameConfig): Problem[] {
  const out: Problem[] = [];
  const cr = config.creator;
  const name = d.name.trim();
  if (name.length < NAME_MIN || name.length > NAME_MAX) out.push({ key: "a.v.name", vars: { min: NAME_MIN, max: NAME_MAX } });
  if (d.description.length > DESC_MAX) out.push({ key: "a.v.description", vars: { max: DESC_MAX } });
  if (!isPointToPoint(config, d.category) && !(Number.isInteger(d.lapsDefault) && inRange(d.lapsDefault, 1, config.maxLaps))) out.push({ key: "a.v.laps", vars: { max: config.maxLaps } });
  if (!(Number.isInteger(d.basePrize) && inRange(d.basePrize, 0, config.baseMaxPrize))) out.push({ key: "a.v.prize", vars: { max: config.baseMaxPrize } });
  if (!(Number.isInteger(d.timeLimit) && inRange(d.timeLimit, 0, TIME_LIMIT_MAX))) out.push({ key: "a.v.timeLimit", vars: { max: TIME_LIMIT_MAX } });

  const cps = d.checkpoints;
  const normals = normalCount(cps);
  if (cps.length > cr.maxCheckpoints) out.push({ key: "a.v.maxCheckpoints", vars: { max: cr.maxCheckpoints } });
  if (normals < 2) out.push({ key: "a.v.fewCheckpoints" });

  cps.forEach((c, i) => {
    const bad =
      !inRange(c.x, -COORD_MAX, COORD_MAX) ||
      !inRange(c.y, -COORD_MAX, COORD_MAX) ||
      !inRange(c.z, Z_MIN, Z_MAX) ||
      !inRange(c.radius, cr.minRadius, cr.maxRadius) ||
      !inRange(c.height, cr.minHeight, cr.maxHeight);
    if (bad) out.push({ key: "a.v.checkpoint", vars: { n: i + 1 } });
    if (c.kind === "shortcut") {
      const from = c.linkFrom ?? 0;
      const to = c.linkTo ?? 0;
      if (!Number.isInteger(from) || !Number.isInteger(to) || from < 1 || to < from + 2 || to > normals) out.push({ key: "a.v.shortcut", vars: { n: i + 1, normals } });
    }
  });

  if (d.grid.length < 1) out.push({ key: "a.v.noGrid" });
  else if (d.grid.length > cr.maxGrid) out.push({ key: "a.v.maxGrid", vars: { max: cr.maxGrid } });
  d.grid.forEach((g: DraftGrid, i) => {
    if (!inRange(g.x, -COORD_MAX, COORD_MAX) || !inRange(g.y, -COORD_MAX, COORD_MAX) || !inRange(g.z, Z_MIN, Z_MAX) || !inRange(g.h, -360, 720)) out.push({ key: "a.v.gridSlot", vars: { n: i + 1 } });
  });
  return out;
}

/** Extrae numeros de texto pegado ("vector4(1, 2, 3, 90)", "1 2 3"...) */
export function parseCoords(text: string): number[] {
  return (text.replace(/[A-Za-z_]+\d*/g, " ").match(/-?\d+(?:\.\d+)?/g) ?? []).map(Number).filter(Number.isFinite);
}

export function newCheckpoint(config: GameConfig, last?: DraftCheckpoint): DraftCheckpoint {
  return {
    kind: "normal",
    x: last ? Math.round((last.x + 20) * 100) / 100 : 0,
    y: last ? Math.round((last.y + 20) * 100) / 100 : 0,
    z: last?.z ?? 30,
    radius: config.creator.defaultRadius,
    height: config.creator.defaultHeight,
  };
}
