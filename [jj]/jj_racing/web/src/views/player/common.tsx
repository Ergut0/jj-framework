import { useEffect, useRef, useState, type ReactNode } from "react";
import { Badge, CrewTag, DataState, PositionBadge } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { formatTime, money, dateTime } from "@/lib/format";
import type { GameConfig, LeaderboardRow, LobbyState, RaceMode } from "@/lib/types";

export function useMoney(): (n: number) => string {
  const { config } = useApp();
  return (n) => money(n, config.currency);
}

const MODE_COLOR: Record<RaceMode, string> = { open: "#3b82f6", crew: "#d946ef", official: "#fbbf24", test: "#8d8da3" };

export function ModeBadge({ mode }: { mode: RaceMode }) {
  const t = useT();
  return <Badge color={MODE_COLOR[mode]}>{t(`mode.${mode}`)}</Badge>;
}

const STATE_COLOR: Record<LobbyState, string> = { open: "#22c55e", checking: "#f59e0b", countdown: "#f59e0b", running: "#ef4444" };

export function StateBadge({ state }: { state: LobbyState }) {
  const t = useT();
  return <Badge color={STATE_COLOR[state]}>{t(`state.${state}`)}</Badge>;
}

/** Cuenta atras mm:ss a partir de los segundos que quedaban al recibir el dato */
export function Countdown({ seconds }: { seconds: number }) {
  const [left, setLeft] = useState(seconds);
  const start = useRef(Date.now());
  useEffect(() => {
    start.current = Date.now();
    setLeft(seconds);
    const id = setInterval(() => setLeft(Math.max(0, seconds - Math.floor((Date.now() - start.current) / 1000))), 1000);
    return () => clearInterval(id);
  }, [seconds]);
  return (
    <span className="tabular">
      {Math.floor(left / 60)}:{String(left % 60).padStart(2, "0")}
    </span>
  );
}

export function Kv({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-3 border-b border-line/60 py-1.5 text-sm last:border-0">
      <span className="text-mute">{label}</span>
      <span className="tabular text-right font-semibold">{children}</span>
    </div>
  );
}

export interface PrizeEstimate {
  entries: number;
  commission: number;
  extra: number;
  base: number;
  total: number;
  split: number[];
}

/** Misma formula que Lobbies.PrizePool: inscripciones - comision + extra + premio base, repartido segun prizeSplit */
export function estimatePrize(config: GameConfig, o: { entryFee: number; drivers: number; extra: number; base: number }): PrizeEstimate {
  const entries = o.entryFee * o.drivers;
  const commission = Math.floor((entries * config.commissionPct) / 100);
  const total = entries - commission + o.extra + o.base;
  return { entries, commission, extra: o.extra, base: o.base, total, split: config.prizeSplit.map((p) => Math.floor((total * p) / 100)) };
}

export function LeaderboardTable({ rows, loading, error, onRetry }: { rows: LeaderboardRow[] | null; loading: boolean; error: string | null; onRetry: () => void }) {
  const t = useT();
  const { state } = useApp();
  return (
    <DataState loading={loading} error={error} hasData={rows !== null} empty={rows !== null && rows.length === 0} emptyText={t("p.lb.empty")} onRetry={onRetry}>
      <div className="overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead className="text-xs tracking-wide text-mute uppercase">
            <tr>
              <th className="w-12 py-2">#</th>
              <th className="py-2">{t("p.col.driver")}</th>
              <th className="hidden py-2 sm:table-cell">{t("p.col.vehicle")}</th>
              <th className="hidden py-2 md:table-cell">{t("p.col.date")}</th>
              <th className="py-2 text-right">{t("p.col.time")}</th>
            </tr>
          </thead>
          <tbody>
            {rows?.map((r) => (
              <tr key={r.position} className={`border-t border-line/60 ${r.name === state.me.name ? "bg-accent/10" : ""}`}>
                <td className="py-2">
                  <PositionBadge position={r.position} />
                </td>
                <td className="py-2">
                  <span className="mr-2 font-semibold">{r.name}</span>
                  <CrewTag tag={r.crewTag} color={r.crewColor} />
                </td>
                <td className="hidden py-2 text-mute sm:table-cell">{r.vehicle}</td>
                <td className="hidden py-2 text-mute md:table-cell">{dateTime(r.at, state.config.locale)}</td>
                <td className="tabular py-2 text-right font-bold">{formatTime(r.time)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </DataState>
  );
}
