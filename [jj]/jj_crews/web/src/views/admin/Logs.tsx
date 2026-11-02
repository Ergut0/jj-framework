import { useState } from "react";
import { Card, ErrorState, Input, Loading, Pagination, Select } from "@/components/ui";
import { ActivityList } from "@/components/ActivityList";
import { useApp } from "@/lib/store";
import { useAsync, useDebounced } from "@/lib/hooks";
import { LOG_ACTIONS, useT, type Key } from "@/lib/i18n";
import type { LogItem, Page } from "@/lib/types";

export function Logs() {
  const t = useT();
  const { call } = useApp();
  const [search, setSearch] = useState("");
  const [action, setAction] = useState("");
  const [crewId, setCrewId] = useState("");
  const [page, setPage] = useState(1);
  const q = useDebounced(search);
  const cid = useDebounced(crewId);
  const res = useAsync(
    () => call<Page<LogItem>>("adminLogs", { search: q, action, page, ...(cid && Number(cid) > 0 ? { crewId: Number(cid) } : {}) }),
    [q, action, cid, page],
  );

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap gap-2">
        <Input className="min-w-56 flex-1" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} placeholder={t("adm.logs.search")} maxLength={40} aria-label={t("search")} />
        <Input className="w-32" type="number" min={1} value={crewId} onChange={(e) => { setCrewId(e.target.value); setPage(1); }} placeholder={t("adm.logs.crew")} aria-label={t("adm.logs.crew")} />
        <Select className="w-auto" value={action} onChange={(e) => { setAction(e.target.value); setPage(1); }} aria-label={t("adm.logs.action")}>
          <option value="">{t("adm.logs.action")}: {t("all")}</option>
          {LOG_ACTIONS.map((a) => (
            <option key={a} value={a}>{a}</option>
          ))}
        </Select>
      </div>
      <Card>
        {res.loading && !res.data ? (
          <Loading />
        ) : res.error ? (
          <ErrorState message={res.error} onRetry={res.reload} />
        ) : (
          <>
            <ActivityList items={res.data?.items ?? []} showCrew />
            {res.data && <Pagination page={res.data.page} total={res.data.total} pageSize={res.data.pageSize} onChange={setPage} />}
          </>
        )}
      </Card>
    </div>
  );
}

export type { Key };
