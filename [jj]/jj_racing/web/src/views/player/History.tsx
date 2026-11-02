import { useState } from "react";
import { Ban, Flag } from "lucide-react";
import { Badge, Card, DataState, Modal, Pagination, PositionBadge, SectionTitle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { useAsync } from "@/lib/hooks";
import { fetchNui } from "@/lib/nui";
import { dateTime, formatTime } from "@/lib/format";
import type { HistoryItem, Paginated, PastResults } from "@/lib/types";
import { ModeBadge, useMoney } from "./common";
import { Podium, ResultsTable } from "./ResultsTable";

function PastResultsModal({ raceKey, onClose }: { raceKey: string; onClose: () => void }) {
  const t = useT();
  const res = useAsync(() => fetchNui<PastResults>("getRaceResults", { raceKey }), [raceKey]);
  return (
    <Modal title={res.data?.trackName ?? t("p.history.detail")} onClose={onClose} wide>
      <DataState loading={res.loading} error={res.error} hasData={res.data !== null} onRetry={res.reload}>
        {res.data && (
          <div className="space-y-4">
            <ModeBadge mode={res.data.mode} />
            <Podium rows={res.data.rows} />
            <ResultsTable rows={res.data.rows} />
          </div>
        )}
      </DataState>
    </Modal>
  );
}

export function History() {
  const t = useT();
  const { config } = useApp();
  const money = useMoney();
  const [page, setPage] = useState(1);
  const [open, setOpen] = useState<string | null>(null);
  const list = useAsync(() => fetchNui<Paginated<HistoryItem>>("getHistory", { page }), [page]);

  return (
    <Card>
      <SectionTitle>{t("p.history.title")}</SectionTitle>
      <DataState loading={list.loading} error={list.error} hasData={list.data !== null} empty={list.data?.items.length === 0} emptyText={t("p.history.empty")} onRetry={list.reload}>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="text-xs tracking-wide text-mute uppercase">
              <tr>
                <th className="w-12 py-2">#</th>
                <th className="py-2">{t("p.col.track")}</th>
                <th className="hidden py-2 md:table-cell">{t("p.col.date")}</th>
                <th className="py-2 text-right">{t("p.col.total")}</th>
                <th className="hidden py-2 text-right sm:table-cell">{t("p.col.bestLap")}</th>
                <th className="py-2 text-right">{t("p.col.prize")}</th>
                <th className="hidden py-2 text-right sm:table-cell">{t("p.col.points")}</th>
              </tr>
            </thead>
            <tbody>
              {list.data?.items.map((h) => (
                <tr
                  key={h.id}
                  tabIndex={0}
                  onClick={() => setOpen(h.raceKey)}
                  onKeyDown={(e) => e.key === "Enter" && setOpen(h.raceKey)}
                  className={`cursor-pointer border-t border-line/60 transition-colors hover:bg-white/5 ${h.voided ? "opacity-50" : ""}`}
                >
                  <td className="py-2">
                    <PositionBadge position={h.position} />
                  </td>
                  <td className="py-2">
                    <span className="mr-2 font-semibold">{h.trackName}</span>
                    <ModeBadge mode={h.mode} />
                    {h.status !== "finished" && (
                      <Badge color="#f59e0b" className="ml-1">
                        {t(`status.${h.status}`)}
                      </Badge>
                    )}
                    {h.flagged && <Flag className="ml-2 inline size-3.5 text-bad" aria-label={t("p.results.flagged")} />}
                    {h.voided && <Ban className="ml-2 inline size-3.5 text-bad" aria-label={t("p.history.voided")} />}
                  </td>
                  <td className="hidden py-2 text-mute md:table-cell">{dateTime(h.createdAt, config.locale)}</td>
                  <td className="tabular py-2 text-right font-bold">{formatTime(h.totalTime)}</td>
                  <td className="tabular hidden py-2 text-right text-mute sm:table-cell">{formatTime(h.bestLap)}</td>
                  <td className="tabular py-2 text-right">{h.prize > 0 ? <span className="text-ok">{money(h.prize)}</span> : "-"}</td>
                  <td className="tabular hidden py-2 text-right sm:table-cell">{h.points > 0 ? `+${h.points}` : "-"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {list.data && <Pagination page={list.data.page} total={list.data.total} pageSize={list.data.pageSize} onChange={setPage} />}
      </DataState>
      {open && <PastResultsModal raceKey={open} onClose={() => setOpen(null)} />}
    </Card>
  );
}
