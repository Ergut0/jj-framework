import { Flag, Medal, Percent, Star, Trophy, Wallet } from "lucide-react";
import { Card, DataState, SectionTitle, StatTile } from "@/components/ui";
import { useT } from "@/lib/i18n";
import { useAsync } from "@/lib/hooks";
import { fetchNui } from "@/lib/nui";
import { formatTime, num } from "@/lib/format";
import type { StatsPayload } from "@/lib/types";
import { useMoney } from "./common";

export function Stats() {
  const t = useT();
  const money = useMoney();
  const res = useAsync(() => fetchNui<StatsPayload>("getStats"), []);
  const s = res.data?.stats;
  const rate = s && s.races > 0 ? Math.round((s.wins / s.races) * 100) : 0;
  const icon = "size-3.5";

  return (
    <div className="space-y-5">
      <h2 className="racing-title text-xl">{t("p.stats.title")}</h2>
      <DataState loading={res.loading} error={res.error} hasData={res.data !== null} onRetry={res.reload}>
        {s && (
          <>
            <div className="grid grid-cols-2 gap-3 md:grid-cols-3">
              <StatTile label={t("p.stats.races")} value={num(s.races)} icon={<Flag className={icon} />} />
              <StatTile label={t("p.stats.wins")} value={num(s.wins)} icon={<Trophy className={icon} />} />
              <StatTile label={t("p.stats.podiums")} value={num(s.podiums)} icon={<Medal className={icon} />} />
              <StatTile label={t("p.stats.earnings")} value={money(s.earnings)} icon={<Wallet className={icon} />} />
              <StatTile label={t("p.stats.points")} value={num(s.points)} icon={<Star className={icon} />} />
              <StatTile label={t("p.stats.winRate")} value={`${rate}%`} icon={<Percent className={icon} />} />
            </div>
            <Card>
              <SectionTitle>{t("p.stats.bests")}</SectionTitle>
              {res.data?.bests.length === 0 ? (
                <p className="py-6 text-center text-sm text-mute">{t("p.stats.noBests")}</p>
              ) : (
                <table className="w-full text-left text-sm">
                  <thead className="text-xs tracking-wide text-mute uppercase">
                    <tr>
                      <th className="py-2">{t("p.col.track")}</th>
                      <th className="hidden py-2 sm:table-cell">{t("p.col.vehicle")}</th>
                      <th className="py-2 text-right">{t("p.col.bestLap")}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {res.data?.bests.map((b) => (
                      <tr key={b.trackId} className="border-t border-line/60">
                        <td className="py-2 font-semibold">{b.trackName}</td>
                        <td className="hidden py-2 text-mute sm:table-cell">{b.vehicle}</td>
                        <td className="tabular py-2 text-right font-bold">{formatTime(b.bestLap)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </Card>
          </>
        )}
      </DataState>
    </div>
  );
}
