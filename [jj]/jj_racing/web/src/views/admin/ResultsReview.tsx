import { useState } from "react";
import { Ban, CheckCheck, Flag } from "lucide-react";
import { Badge, Button, Card, CrewTag, DataState, Pagination, PositionBadge, SearchInput, SectionTitle, Toggle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { fetchNui } from "@/lib/nui";
import { useAsync, useDebounced } from "@/lib/hooks";
import { dateTime, formatTime, money } from "@/lib/format";
import type { AdminResultRow, Paginated } from "@/lib/types";
import { ReasonDialog } from "./fields";

const STATUS_COLOR: Record<string, string> = { finished: "#22c55e", dnf: "#f59e0b", dq: "#ef4444" };

export function ResultsReview() {
  const t = useT();
  const { call, config } = useApp();
  const [flaggedOnly, setFlaggedOnly] = useState(true);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [voiding, setVoiding] = useState<AdminResultRow | null>(null);
  const [busy, setBusy] = useState(false);
  const q = useDebounced(search.trim(), 300);

  const list = useAsync(() => fetchNui<Paginated<AdminResultRow>>("adminListResults", { flaggedOnly, search: q, page }), [flaggedOnly, q, page]);
  const data = list.data;

  const approve = async (r: AdminResultRow) => {
    const res = await call("adminApproveResult", { id: r.id }, t("a.rev.approved"));
    if (res.ok) void list.reload();
  };

  const confirmVoid = async (reason: string) => {
    if (!voiding) return;
    setBusy(true);
    const res = await call("adminVoidResult", { id: voiding.id, reason }, t("a.rev.voided"));
    setBusy(false);
    if (res.ok) {
      setVoiding(null);
      void list.reload();
    }
  };

  return (
    <div>
      <SectionTitle>{t("a.nav.review")}</SectionTitle>
      <div className="mb-4 flex flex-wrap items-center gap-3">
        <SearchInput className="min-w-56 flex-1" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} placeholder={t("a.rev.search")} aria-label={t("search")} />
        <Toggle checked={flaggedOnly} onChange={(v) => { setFlaggedOnly(v); setPage(1); }} label={t("a.rev.onlyFlagged")} />
      </div>

      <DataState loading={list.loading} error={list.error} hasData={!!data} empty={!!data && data.items.length === 0} emptyText={t("a.rev.empty")} onRetry={list.reload}>
        <div className="flex flex-col gap-2">
          {data?.items.map((r) => (
            <Card key={r.id} className={`flex flex-col gap-2 p-3 sm:flex-row sm:items-center ${r.voided ? "opacity-60" : ""}`}>
              <PositionBadge position={r.position} />
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="truncate font-semibold">{r.name}</span>
                  <CrewTag tag={r.crewTag} />
                  <span className="font-mono text-xs text-mute">{r.citizenid}</span>
                  <Badge color={STATUS_COLOR[r.status]}>{t(`status.${r.status}`)}</Badge>
                  <Badge>{t(`mode.${r.mode}`)}</Badge>
                  {r.voided && <Badge color="#ef4444">{t("a.rev.voidedTag")}</Badge>}
                </div>
                <div className="mt-0.5 flex flex-wrap gap-x-3 text-xs text-mute">
                  <span>{r.trackName}</span>
                  <span className="tabular">{t("a.rev.total")}: {formatTime(r.totalTime)}</span>
                  <span className="tabular">{t("a.rev.best")}: {formatTime(r.bestLap)}</span>
                  <span className="tabular">{money(r.prize, config.currency)}</span>
                  <span>{dateTime(r.createdAt, config.locale)}</span>
                </div>
                {r.flagged && !r.voided && (
                  <p className="mt-1 flex items-center gap-1.5 text-xs text-warn">
                    <Flag className="size-3.5 shrink-0" /> {r.flagReason || t("a.rev.noReason")}
                  </p>
                )}
                {r.voided && <p className="mt-1 text-xs text-bad">{t("a.rev.voidReason", { reason: r.voidReason })}</p>}
              </div>
              {!r.voided && (
                <div className="flex shrink-0 gap-2">
                  {r.flagged && (
                    <Button variant="outline" size="sm" onClick={() => void approve(r)}>
                      <CheckCheck className="size-4" /> {t("a.rev.approve")}
                    </Button>
                  )}
                  <Button variant="danger" size="sm" onClick={() => setVoiding(r)}>
                    <Ban className="size-4" /> {t("a.rev.void")}
                  </Button>
                </div>
              )}
            </Card>
          ))}
        </div>
        {data && <Pagination page={data.page} total={data.total} pageSize={data.pageSize} onChange={setPage} />}
      </DataState>

      {voiding && <ReasonDialog title={t("a.rev.voidTitle")} message={t("a.rev.voidMsg", { name: voiding.name, track: voiding.trackName })} loading={busy} onConfirm={(r) => void confirmVoid(r)} onClose={() => setVoiding(null)} />}
    </div>
  );
}
