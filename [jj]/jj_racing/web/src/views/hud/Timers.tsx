import { useEffect, useRef } from "react";
import { useT } from "@/lib/i18n";
import { formatGap, formatTime } from "@/lib/format";
import type { HudProgress, HudStandings, HudShow } from "@/lib/types";
import { clockText, type RaceClock } from "./clock";
import { Panel } from "./hudUi";

interface Props {
  clock: RaceClock;
  racing: boolean;
  /** cambia al empezar una carrera nueva para repintar el reloj a cero */
  epoch: HudShow;
  progress: HudProgress | null;
  standings: HudStandings | null;
  leading: boolean;
}

export function Timers({ clock, racing, epoch, progress, standings, leading }: Props) {
  const t = useT();
  const totalRef = useRef<HTMLSpanElement>(null);
  const lapRef = useRef<HTMLSpanElement>(null);

  // El bucle rAF solo existe mientras se corre; en reposo no hay coste
  useEffect(() => {
    const paint = () => {
      const now = performance.now();
      if (totalRef.current) totalRef.current.textContent = clockText(clock.total(now));
      if (lapRef.current) lapRef.current.textContent = clockText(clock.lap(now));
    };
    paint();
    if (!racing) return;
    let id = requestAnimationFrame(function loop() {
      paint();
      id = requestAnimationFrame(loop);
    });
    return () => cancelAnimationFrame(id);
  }, [clock, racing, epoch]);

  const gap = standings?.gap;
  const isLeader = leading || (gap != null && gap <= 0);

  return (
    <Panel className="animate-rise w-[19em] overflow-hidden">
      <div className="px-[1.1em] pb-[0.5em] pt-[0.7em]">
        <div className="text-[0.8em] font-semibold uppercase tracking-[0.2em] text-mute">{t("h.time")}</div>
        <span ref={totalRef} className="block font-mono text-[3em] font-bold leading-[1.1] tracking-tight tabular">
          0:00.000
        </span>
      </div>
      <div className="grid grid-cols-2 gap-px border-t border-white/10 bg-white/10 text-[0.95em]">
        <div className="bg-bg/60 px-[1em] py-[0.5em]">
          <div className="text-[0.75em] font-semibold uppercase tracking-[0.18em] text-mute">{t("h.lapTime")}</div>
          <span ref={lapRef} className="font-mono text-[1.3em] font-bold tabular">
            0:00.000
          </span>
        </div>
        <div className="bg-bg/60 px-[1em] py-[0.5em]">
          <div className="text-[0.75em] font-semibold uppercase tracking-[0.18em] text-mute">{t("h.best")}</div>
          <span className="font-mono text-[1.3em] font-bold text-gold tabular">{formatTime(progress?.bestLap)}</span>
        </div>
      </div>
      {standings && (
        <div className="flex items-center justify-between border-t border-white/10 px-[1.1em] py-[0.5em]">
          <span className="text-[0.75em] font-semibold uppercase tracking-[0.18em] text-mute">{t("h.gap")}</span>
          <span className={`font-mono text-[1.3em] font-bold tabular ${isLeader ? "text-ok" : "text-warn"}`}>
            {isLeader ? t("h.leader") : formatGap(gap)}
          </span>
        </div>
      )}
    </Panel>
  );
}
