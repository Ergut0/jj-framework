import { useState } from "react";
import { ChevronDown, ShieldAlert } from "lucide-react";
import { Badge, Card, DataState, Pagination, SearchInput, SectionTitle, Select } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT, type Translator } from "@/lib/i18n";
import { fetchNui } from "@/lib/nui";
import { useAsync, useDebounced } from "@/lib/hooks";
import { dateTime } from "@/lib/format";
import { cn } from "@/lib/utils";
import type { LogRow, Paginated } from "@/lib/types";

export const LOG_ACTIONS = [
  "track_create", "track_save", "track_duplicate", "track_enable", "track_disable", "track_delete", "track_import", "track_export", "track_test",
  "race_create", "race_cancel", "race_kick", "race_result", "race_dq", "new_record", "result_void", "result_approve", "record_void", "settings_save",
  "event_create", "event_cancel", "event_start", "crew_export", "challenge_create", "challenge_accept", "challenge_decline", "escrow_recover",
] as const;

function actionLabel(t: Translator, action: string): string {
  const k = `a.act.${action}`;
  const v = t(k);
  return v === k ? action : v;
}

const show = (v: unknown): string => (v !== null && typeof v === "object" ? JSON.stringify(v) : String(v));

export function Logs() {
  const t = useT();
  const [action, setAction] = useState("");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [open, setOpen] = useState<number | null>(null);
  const q = useDebounced(search.trim(), 300);
  const list = useAsync(() => fetchNui<Paginated<LogRow>>("adminLogs", { action, search: q, page }), [action, q, page]);
  const data = list.data;

  return (
    <div>
      <SectionTitle>{t("a.nav.logs")}</SectionTitle>
      <div className="mb-4 grid gap-2 sm:grid-cols-[minmax(0,1fr)_240px]">
        <SearchInput value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); setOpen(null); }} placeholder={t("a.logs.search")} aria-label={t("search")} />
        <Select aria-label={t("a.logs.action")} value={action} onChange={(e) => { setAction(e.target.value); setPage(1); setOpen(null); }}>
          <option value="">{t("a.logs.action")}: {t("all")}</option>
          {LOG_ACTIONS.map((a) => (
            <option key={a} value={a}>{actionLabel(t, a)}</option>
          ))}
        </Select>
      </div>

      <DataState loading={list.loading} error={list.error} hasData={!!data} empty={!!data && data.items.length === 0} emptyText={t("a.logs.empty")} onRetry={list.reload}>
        <div className="flex flex-col gap-2">
          {data?.items.map((row) => (
            <LogItem key={row.id} row={row} open={open === row.id} onToggle={() => setOpen(open === row.id ? null : row.id)} />
          ))}
        </div>
        {data && <Pagination page={data.page} total={data.total} pageSize={data.pageSize} onChange={(p) => { setPage(p); setOpen(null); }} />}
      </DataState>
    </div>
  );
}

function LogItem({ row, open, onToggle }: { row: LogRow; open: boolean; onToggle: () => void }) {
  const t = useT();
  const { config } = useApp();
  const audit = row.action === "crew_export";
  const entries = Object.entries(row.details ?? {});
  return (
    <Card className={cn("p-0", audit && "border-accent/50 bg-accent/5")}>
      <button type="button" onClick={onToggle} aria-expanded={open} className="flex w-full items-center gap-3 px-4 py-2.5 text-left">
        {audit && <ShieldAlert className="size-4 shrink-0 text-accent" aria-label={t("a.logs.audit")} />}
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <Badge color={audit ? "#a855f7" : undefined}>{actionLabel(t, row.action)}</Badge>
            {row.isAdmin && <Badge color="#fbbf24">{t("a.logs.admin")}</Badge>}
            {audit && <span className="text-xs text-accent">{t("a.logs.audit")}</span>}
          </div>
          <div className="mt-0.5 truncate text-xs text-mute">
            {row.actorName || "—"} <span className="font-mono">({row.actorCid || "—"})</span>
          </div>
        </div>
        <span className="tabular shrink-0 text-xs text-mute">{dateTime(row.createdAt, config.locale)}</span>
        <ChevronDown className={cn("size-4 shrink-0 text-mute transition-transform", open && "rotate-180")} />
      </button>
      {open && (
        <div className="animate-fade border-t border-line px-4 py-3">
          {entries.length === 0 ? (
            <p className="text-xs text-mute">{t("a.logs.noDetails")}</p>
          ) : (
            <table className="w-full text-xs">
              <tbody>
                {entries.map(([k, v]) => (
                  <tr key={k} className="border-b border-line/50 last:border-0">
                    <th scope="row" className="w-1/3 py-1 pr-3 text-left align-top font-semibold text-mute">{k}</th>
                    <td className="py-1 font-mono break-all select-text">{show(v)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </Card>
  );
}
