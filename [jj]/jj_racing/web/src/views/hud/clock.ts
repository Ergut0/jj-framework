import { formatTime } from "@/lib/format";

/** Reloj local de carrera: se sincroniza con el servidor en cada progreso y no tiene coste en reposo */
export class RaceClock {
  private t0 = 0;
  private lapStart = 0;
  private running = false;
  private frozenTotal = 0;
  private frozenLap = 0;

  reset() {
    this.running = false;
    this.frozenTotal = 0;
    this.frozenLap = 0;
  }

  start(now = performance.now()) {
    this.t0 = now;
    this.lapStart = now;
    this.running = true;
  }

  /** total = ms de carrera segun el servidor; lapRestarted = el servidor cerro una vuelta */
  sync(total: number, lapRestarted: boolean, now = performance.now()) {
    if (!this.running) return;
    this.t0 = now - total;
    if (lapRestarted) this.lapStart = now;
  }

  freeze(total?: number, now = performance.now()) {
    if (this.running) {
      this.frozenTotal = total ?? now - this.t0;
      this.frozenLap = now - this.lapStart;
    } else if (total != null) {
      this.frozenTotal = total;
    }
    this.running = false;
  }

  total(now: number): number {
    return this.running ? now - this.t0 : this.frozenTotal;
  }

  lap(now: number): number {
    return this.running ? now - this.lapStart : this.frozenLap;
  }
}

export const clockText = (ms: number): string => (ms > 0 ? formatTime(ms) : "0:00.000");
