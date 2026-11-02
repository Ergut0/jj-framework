import { useT } from "@/lib/i18n";
import type { HudShow, HudProgress, HudStandings } from "@/lib/types";
import { Flag } from "lucide-react";
import type { RaceClock } from "./clock";
import type { HudState } from "./useHud";
import { HUD_ROOT_CLASS, HUD_ROOT_STYLE, Panel } from "./hudUi";
import { Timers } from "./Timers";
import { Standings } from "./Standings";
import { Countdown } from "./Countdown";
import { FinishBanner, OutBanner, PitToast } from "./Banners";

const MAX_SEGMENTS = 40;

function PositionPanel({ show, standings }: { show: HudShow; standings: HudStandings | null }) {
  const t = useT();
  return (
    <Panel className="animate-rise w-[19em] overflow-hidden">
      <div className="flex items-stretch">
        <div className="w-[0.35em] bg-accent" />
        <div className="flex-1 px-[1em] py-[0.7em]">
          <div className="text-[0.8em] font-semibold uppercase tracking-[0.2em] text-mute">{t("h.position")}</div>
          <div className="racing-title flex items-baseline leading-none tabular">
            <span className="text-[5em] text-ink">{standings?.pos ?? "–"}</span>
            <span className="text-[2.2em] text-mute">/{standings?.total ?? "–"}</span>
          </div>
        </div>
      </div>
      <div className="flex items-center gap-[0.6em] border-t border-white/10 px-[1em] py-[0.5em] text-[0.85em]">
        <Flag className="size-[1.1em] shrink-0 text-accent" />
        <span className="min-w-0 flex-1 truncate font-semibold">{show.trackName}</span>
        <span className="shrink-0 rounded-[0.2em] bg-white/10 px-[0.5em] py-[0.15em] text-[0.85em] font-bold uppercase tracking-wider text-mute">{t(`mode.${show.mode}`)}</span>
      </div>
    </Panel>
  );
}

function ProgressBar({ passed, total }: { passed: number; total: number }) {
  if (total <= 0) return null;
  if (total > MAX_SEGMENTS) {
    return (
      <div className="h-[0.5em] -skew-x-[20deg] overflow-hidden bg-white/10">
        <div className="h-full bg-accent transition-[width] duration-300" style={{ width: `${Math.min(100, (passed / total) * 100)}%` }} />
      </div>
    );
  }
  return (
    <div className="flex gap-[0.2em]">
      {Array.from({ length: total }, (_, i) => (
        <div
          key={i}
          className={`h-[0.5em] flex-1 -skew-x-[20deg] transition-colors duration-300 ${i < passed ? "bg-accent" : i === passed ? "animate-pulse bg-accent/45" : "bg-white/12"}`}
        />
      ))}
    </div>
  );
}

function LapPanel({ show, progress, done }: { show: HudShow; progress: HudProgress | null; done: boolean }) {
  const t = useT();
  const lap = Math.min(progress?.lap ?? 1, Math.max(show.laps, 1));
  const cp = done ? show.totalCp : Math.min(progress?.cp ?? 0, show.totalCp);
  return (
    <Panel className="animate-rise w-[19em] px-[1em] py-[0.7em]" style={{ animationDelay: "60ms" }}>
      <div className="mb-[0.55em] flex items-baseline justify-between">
        <span className="racing-title text-[1.5em] leading-none tabular">{t("h.lap", { n: lap, total: show.laps })}</span>
        {show.totalCp > 0 && <span className="font-mono text-[1em] font-bold leading-none text-accent tabular">{t("h.cp", { n: cp, total: show.totalCp })}</span>}
      </div>
      <ProgressBar passed={cp} total={show.totalCp} />
    </Panel>
  );
}

interface Props {
  state: HudState;
  clock: RaceClock;
  pitVisible: boolean;
}

export function RaceHud({ state, clock, pitVisible }: Props) {
  const { show, standings, progress } = state;
  if (!show) return null;
  const racing = state.started && !state.finish && state.out == null;
  const leading = standings?.pos === 1;

  return (
    <div className={HUD_ROOT_CLASS} style={HUD_ROOT_STYLE}>
      <div className="absolute left-[2.5vw] top-[3vh] flex flex-col gap-[0.6em]">
        <PositionPanel show={show} standings={standings} />
        <LapPanel show={show} progress={progress} done={!!state.finish} />
      </div>

      <div className="absolute right-[2.5vw] top-[3vh] flex flex-col items-end gap-[0.6em]">
        <Timers clock={clock} racing={racing} epoch={show} progress={progress} standings={standings} leading={leading} />
        <Standings standings={standings} you={show.you} />
      </div>

      <Countdown n={state.countdown} go={state.go} />
      {state.finish && <FinishBanner info={state.finish} />}
      {state.out != null && <OutBanner reason={state.out} />}
      {pitVisible && <PitToast key={state.pit} />}
    </div>
  );
}
