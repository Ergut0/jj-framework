// Simulacion en el navegador de los mensajes de Lua del HUD (?hud=1) y del editor (?creator=1)
import { emitNui } from "@/lib/nui";
import type { CheckpointKind, CreatorHud, HudShow, HudStandingRow, HudStandings, Locale } from "@/lib/types";

const TICK_MS = 100;
const LAPS = 3;
const TOTAL_CP = 12;
const YOU = 3;
const OUT_REASONS = ["too_fast", "teleport", "left_vehicle"];

class Cancelled extends Error {}

const locale = (): Locale => (new URLSearchParams(location.search).get("lang") === "en" ? "en" : "es");

interface Driver {
  pid: number;
  name: string;
  tag?: string;
  color?: string;
  pace: number;
  phase: number;
  prog: number;
  finishedAt?: number;
  out?: boolean;
}

const ROSTER: Pick<Driver, "pid" | "name" | "tag" | "color">[] = [
  { pid: 1, name: "Marcos Vidal", tag: "VLX", color: "#ef4444" },
  { pid: 2, name: "Lucía Ferrer", tag: "NTR", color: "#22c55e" },
  { pid: 3, name: "Josete", tag: "APX", color: "#a855f7" },
  { pid: 4, name: "Dani Ortega", tag: "VLX", color: "#ef4444" },
  { pid: 5, name: "Sergio Pla", tag: "NTR", color: "#22c55e" },
  { pid: 6, name: "Alba Montes", tag: "APX", color: "#a855f7" },
  { pid: 7, name: "Iván Cruz", tag: "KRN", color: "#38bdf8" },
  { pid: 8, name: "Nerea Soto" },
];

let generation = 0;

function makeSleep(gen: number) {
  return (ms: number) =>
    new Promise<void>((resolve, reject) =>
      setTimeout(() => (gen === generation ? resolve() : reject(new Cancelled())), ms),
    );
}

function buildStandings(drivers: Driver[], you: number, youProg: number, youPace: number): HudStandings {
  const ranked = [...drivers].sort((a, b) => {
    if (!!a.out !== !!b.out) return a.out ? 1 : -1;
    if (a.finishedAt != null || b.finishedAt != null) return (a.finishedAt ?? Infinity) - (b.finishedAt ?? Infinity);
    return b.prog - a.prog;
  });
  const leader = ranked[0]!;
  const me = drivers.find((d) => d.pid === you)!;
  const rows: HudStandingRow[] = ranked.map((d) => ({
    pid: d.pid,
    name: d.name,
    tag: d.tag,
    color: d.color,
    lap: Math.min(LAPS, Math.floor(d.prog / TOTAL_CP) + 1),
    finished: d.finishedAt != null || undefined,
    out: d.out || undefined,
  }));
  const pos = ranked.findIndex((d) => d.pid === you) + 1;
  const finishedGap = me.finishedAt != null && leader.finishedAt != null ? Math.round(me.finishedAt - leader.finishedAt) : null;
  const gap = pos === 1 ? 0 : finishedGap ?? Math.round(((leader.prog - youProg) / youPace) * 1000);
  return { pos, total: ranked.length, gap, leader: leader.name, rows };
}

async function runRace(run: number, sleep: (ms: number) => Promise<void>) {
  const show: HudShow = {
    locale: locale(),
    trackName: "Circuito del Puerto",
    laps: LAPS,
    totalCp: TOTAL_CP,
    mode: run % 2 === 0 ? "crew" : "official",
    you: YOU,
  };
  emitNui("hud:show", { data: show });
  await sleep(900);
  for (let n = 5; n >= 1; n--) {
    emitNui("hud:countdown", { data: { n } });
    await sleep(1000);
  }
  emitNui("hud:go", { data: {} });

  const drivers: Driver[] = ROSTER.map((r, i) => ({ ...r, pace: 1.05 + ((i * 37) % 30) / 100, phase: i * 1.7, prog: 0 }));
  const you = drivers.find((d) => d.pid === YOU)!;
  you.pace = 1.2;

  const start = performance.now();
  let lapStart = start;
  let best: number | undefined;
  let lastCp = 0;
  let elapsed = 0;
  let finishedCount = 0;
  let youDone = false;
  let youOut = false;
  let pitDone = false;
  let sinceStandings = 0;

  const finishTimes = new Map<number, number>();
  while (true) {
    await sleep(TICK_MS);
    elapsed = performance.now() - start;
    const dt = TICK_MS / 1000;
    for (const d of drivers) {
      if (d.out || d.finishedAt != null) continue;
      if (d.pid === YOU && (youDone || youOut)) continue;
      d.prog += d.pace * (1 + 0.14 * Math.sin(elapsed / 2500 + d.phase)) * dt;
      if (d.prog >= LAPS * TOTAL_CP) {
        d.prog = LAPS * TOTAL_CP;
        d.finishedAt = elapsed;
        finishTimes.set(d.pid, elapsed);
        finishedCount++;
      }
    }
    const rival = drivers.find((d) => d.pid === 7)!;
    if (!rival.out && rival.finishedAt == null && elapsed > 14000 && run === 0) rival.out = true;

    if (run === 0 && !pitDone && you.prog > 5) {
      pitDone = true;
      emitNui("hud:pit", { data: {} });
    }
    if (run === 1 && !youOut && elapsed > 12000) {
      youOut = true;
      you.out = true;
      emitNui("hud:out", { data: { reason: OUT_REASONS[Math.floor(Math.random() * OUT_REASONS.length)] } });
    }

    if (!youDone && !youOut) {
      const cps = Math.floor(you.prog);
      if (you.finishedAt != null) {
        youDone = true;
        const rank = [...finishTimes.values()].filter((t) => t <= (you.finishedAt as number)).length;
        emitNui("hud:finish", { data: { time: Math.round(you.finishedAt), order: rank, bestLap: best } });
      } else if (cps > lastCp) {
        lastCp = cps;
        const now = performance.now();
        const lapDone = cps % TOTAL_CP === 0;
        let lapTime: number | undefined;
        if (lapDone) {
          lapTime = Math.round(now - lapStart);
          best = best == null ? lapTime : Math.min(best, lapTime);
          lapStart = now;
        }
        emitNui("hud:progress", {
          data: { lap: Math.floor(cps / TOTAL_CP) + 1, cp: cps % TOTAL_CP, lapTime, bestLap: best, total: Math.round(now - start) },
        });
      }
    }

    sinceStandings += TICK_MS;
    if (sinceStandings >= 500) {
      sinceStandings = 0;
      emitNui("hud:standings", { data: buildStandings(drivers, YOU, you.prog, you.pace) });
    }

    const racers = drivers.filter((d) => !d.out && d.finishedAt == null).length;
    if (racers === 0 || (youDone && elapsed - (you.finishedAt ?? elapsed) > 6000) || (youOut && elapsed > 20000)) break;
  }
  await sleep(3500);
  emitNui("hud:hide", {});
  await sleep(3000);
}

/** Bucle completo: show -> cuenta atras -> go -> progreso -> finish/out -> hide, y vuelta a empezar */
export function startHudSim(): () => void {
  const gen = ++generation;
  const sleep = makeSleep(gen);
  void (async () => {
    try {
      for (let run = 0; ; run = (run + 1) % 3) await runRace(run, sleep);
    } catch (e) {
      if (!(e instanceof Cancelled)) throw e;
    }
  })();
  return () => {
    if (gen === generation) generation++;
  };
}

const KIND_CYCLE: (CheckpointKind | "grid")[] = ["normal", "normal", "shortcut", "pit", "grid"];

/** Editor de circuitos: creator:start y creator:hud que cambian tipo, origen, radio y contadores */
export function startCreatorSim(): () => void {
  const gen = ++generation;
  emitNui("creator:start", {});
  let step = 0;
  const hud: CreatorHud = {
    locale: locale(),
    kind: "normal",
    source: "aim",
    radius: 8,
    height: 6,
    checkpoints: 0,
    normals: 0,
    grid: 0,
    selected: 0,
    name: "Circuito del Puerto",
    keys: { place: "E", remove: "Q", prev: "←", next: "→", move: "F", source: "TAB", kind: "Z", finish: "RETROCESO", wheel: "RUEDA / ↑↓", modifier: "SHIFT" },
  };
  const push = () => emitNui("creator:hud", { data: hud });
  push();
  const id = setInterval(() => {
    if (gen !== generation) return clearInterval(id);
    step++;
    hud.kind = KIND_CYCLE[step % KIND_CYCLE.length]!;
    hud.source = step % 4 < 2 ? "aim" : "player";
    hud.radius = 4 + ((step * 3) % 14);
    hud.height = 4 + ((step * 2) % 9);
    if (hud.kind === "grid") hud.grid = Math.min(12, hud.grid + 1);
    else {
      hud.checkpoints++;
      if (hud.kind === "normal") hud.normals++;
      hud.selected = hud.checkpoints;
      hud.selectedKind = hud.kind;
    }
    push();
  }, 1600);
  return () => {
    if (gen === generation) generation++;
    clearInterval(id);
    emitNui("creator:stop", {});
  };
}
