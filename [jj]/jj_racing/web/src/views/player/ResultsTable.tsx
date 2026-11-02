import { Flag, Trophy } from "lucide-react";
import { Badge, CrewTag, PositionBadge } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { formatTime, safeColor } from "@/lib/format";
import type { ResultRow } from "@/lib/types";
import { useMoney } from "./common";

/** Fila de resultados; las carreras pasadas (getRaceResults) no traen `pid` */
export type ResultTableRow = Omit<ResultRow, "pid"> & { pid?: number };

const STATUS_COLOR = { finished: "#22c55e", dnf: "#f59e0b", dq: "#ef4444" } as const;

export function Podium({ rows }: { rows: ResultTableRow[] }) {
  const t = useT();
  const money = useMoney();
  const top = rows.filter((r) => r.status === "finished").slice(0, 3);
  if (top.length === 0) return null;
  const order = [top[1], top[0], top[2]].filter((r): r is ResultTableRow => !!r);
  const heights: Record<number, string> = { 1: "h-28", 2: "h-20", 3: "h-16" };
  return (
    <div className="flex items-end justify-center gap-3">
      {order.map((r) => (
        <div key={r.position} className="animate-rise flex w-1/3 max-w-52 flex-col items-center text-center">
          <PositionBadge position={r.position} className="mb-1 size-9" />
          <div className="max-w-full truncate text-sm font-bold">{r.name}</div>
          <CrewTag tag={r.crew?.tag} color={r.crew?.color} className="mt-0.5" />
          <div className="tabular mt-1 text-xs text-mute">{formatTime(r.totalTime)}</div>
          <div className={`mt-2 flex w-full flex-col items-center justify-center rounded-t-lg bg-white/5 ${heights[r.position] ?? "h-12"}`} style={{ borderTop: `3px solid ${r.position === 1 ? "#fbbf24" : r.position === 2 ? "#cbd5e1" : "#d97706"}` }}>
            {r.prize > 0 && <span className="racing-title tabular text-sm text-ok">{money(r.prize)}</span>}
            <span className="text-[10px] tracking-wide text-mute uppercase">{t("p.col.prize")}</span>
          </div>
        </div>
      ))}
    </div>
  );
}

export function ResultsTable({ rows, you }: { rows: ResultTableRow[]; you?: number }) {
  const t = useT();
  const money = useMoney();
  const { state } = useApp();
  const hasCrewPoints = rows.some((r) => r.crewPoints > 0);
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-left text-sm">
        <thead className="text-xs tracking-wide text-mute uppercase">
          <tr>
            <th className="w-12 py-2">#</th>
            <th className="py-2">{t("p.col.driver")}</th>
            <th className="py-2">{t("p.col.status")}</th>
            <th className="py-2 text-right">{t("p.col.total")}</th>
            <th className="hidden py-2 text-right md:table-cell">{t("p.col.bestLap")}</th>
            <th className="py-2 text-right">{t("p.col.prize")}</th>
            <th className="hidden py-2 text-right sm:table-cell">{t("p.col.points")}</th>
            {hasCrewPoints && <th className="hidden py-2 text-right lg:table-cell">{t("p.col.crewPoints")}</th>}
            <th className="w-14 py-2" />
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => {
            const mine = (you !== undefined && r.pid === you) || (r.pid === undefined && r.name === state.me.name);
            return (
              <tr key={`${r.position}-${r.name}`} className={`border-t border-line/60 ${mine ? "bg-accent/10" : ""}`}>
                <td className="py-2">
                  <PositionBadge position={r.position} />
                </td>
                <td className="py-2">
                  <span className="mr-2 font-semibold">{r.name}</span>
                  {mine && <span className="mr-2 text-xs text-accent">({t("you")})</span>}
                  <CrewTag tag={r.crew?.tag} color={r.crew?.color} />
                  {r.team && (
                    <Badge color={safeColor(r.crew?.color)} className="ml-1">
                      {r.team}
                    </Badge>
                  )}
                </td>
                <td className="py-2">
                  <Badge color={STATUS_COLOR[r.status]}>{t(`status.${r.status}`)}</Badge>
                </td>
                <td className="tabular py-2 text-right font-bold">{formatTime(r.totalTime)}</td>
                <td className="tabular hidden py-2 text-right text-mute md:table-cell">{formatTime(r.bestLap)}</td>
                <td className="tabular py-2 text-right">{r.prize > 0 ? <span className="text-ok">{money(r.prize)}</span> : "-"}</td>
                <td className="tabular hidden py-2 text-right sm:table-cell">{r.points > 0 ? `+${r.points}` : "-"}</td>
                {hasCrewPoints && <td className="tabular hidden py-2 text-right lg:table-cell">{r.crewPoints > 0 ? `+${r.crewPoints}` : "-"}</td>}
                <td className="py-2">
                  <span className="flex justify-end gap-1.5">
                    {r.trackRecord && <Trophy className="size-4 text-warn" aria-label={t("p.results.record")} />}
                    {r.flagged && <Flag className="size-4 text-bad" aria-label={t("p.results.flagged")} />}
                  </span>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
