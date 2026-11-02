import { Ban, Flag, Wrench } from "lucide-react";
import { useT } from "@/lib/i18n";
import { formatTime } from "@/lib/format";
import { MEDAL_COLOR, Panel, useOrdinal } from "./hudUi";
import type { FinishInfo } from "./useHud";

const KNOWN_REASONS = new Set(["teleport", "left_vehicle", "vehicle_changed", "order", "position", "too_fast", "below_reference", "kicked", "time_limit", "grace"]);
/** Estos motivos son DNF por tiempo; el resto son descalificaciones */
const DNF_REASONS = new Set(["time_limit", "grace"]);

export function FinishBanner({ info }: { info: FinishInfo }) {
  const t = useT();
  const ord = useOrdinal();
  const color = (info.order != null && MEDAL_COLOR[info.order]) || "var(--color-ink)";
  return (
    <div className="absolute inset-x-0 top-[17vh] flex justify-center">
      <Panel className="checker animate-pop w-[27em] overflow-hidden text-center">
        <div className="h-[0.35em] bg-accent" />
        <div className="px-[1.5em] pb-[1em] pt-[0.9em]">
          <div className="racing-title flex items-center justify-center gap-[0.5em] text-[1.6em] leading-none text-accent">
            <Flag className="size-[1em]" /> {t("h.finish")}
          </div>
          {info.order != null && (
            <div className="racing-title my-[0.1em] text-[7em] leading-[1.1]" style={{ color, textShadow: `0 0 0.35em color-mix(in srgb, ${color} 45%, transparent)` }}>
              {ord(info.order)}
            </div>
          )}
          <div className="text-[0.8em] font-semibold uppercase tracking-[0.2em] text-mute">{t("h.finish.time")}</div>
          <div className="font-mono text-[2.6em] font-bold leading-tight tabular">{formatTime(info.time)}</div>
          {info.bestLap != null && (
            <div className="text-[1em] text-mute">
              {t("h.finish.best")}: <span className="font-mono font-bold text-gold tabular">{formatTime(info.bestLap)}</span>
            </div>
          )}
          <div className="mt-[0.7em] text-[0.85em] text-mute">{t("h.finish.hint")}</div>
        </div>
      </Panel>
    </div>
  );
}

export function OutBanner({ reason }: { reason: string }) {
  const t = useT();
  const dnf = DNF_REASONS.has(reason);
  const color = dnf ? "var(--color-warn)" : "var(--color-bad)";
  return (
    <div className="absolute inset-x-0 top-[20vh] flex justify-center">
      <Panel className="animate-pop w-[27em] overflow-hidden text-center">
        <div className="h-[0.35em]" style={{ backgroundColor: color }} />
        <div className="px-[1.5em] py-[1.1em]">
          <div className="racing-title flex items-center justify-center gap-[0.4em] text-[3em] leading-none" style={{ color }}>
            <Ban className="size-[0.9em]" /> {dnf ? t("h.out.dnfTag") : t("h.out.dq")}
          </div>
          {dnf && <div className="mt-[0.3em] text-[1em] font-semibold uppercase tracking-[0.15em] text-mute">{t("h.out.dnf")}</div>}
          <div className="mt-[0.7em] text-[1.3em] font-semibold">{t(`h.reason.${KNOWN_REASONS.has(reason) ? reason : "unknown"}`)}</div>
          <div className="mt-[0.7em] text-[0.85em] text-mute">{t("h.out.hint")}</div>
        </div>
      </Panel>
    </div>
  );
}

export function PitToast() {
  const t = useT();
  return (
    <div className="absolute inset-x-0 top-[3vh] flex justify-center">
      <Panel className="animate-rise flex items-center gap-[0.7em] px-[1.2em] py-[0.6em] text-[1.2em] font-semibold">
        <Wrench className="size-[1.1em] text-ok" />
        {t("h.pit")}
      </Panel>
    </div>
  );
}
