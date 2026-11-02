import { useState } from "react";
import { Plus, Search, Snowflake } from "lucide-react";
import { Badge, Button, Card, Emblem, Empty, ErrorState, Field, Input, Loading, Modal, Pagination, Select } from "@/components/ui";
import { IdentityForm } from "@/components/IdentityForm";
import { useApp } from "@/lib/store";
import { useAsync, useDebounced } from "@/lib/hooks";
import { useT, type Key } from "@/lib/i18n";
import { money, num } from "@/lib/format";
import type { CrewSummary, Page } from "@/lib/types";

export function CrewList({ onOpen }: { onOpen: (id: number) => void }) {
  const t = useT();
  const { call, config } = useApp();
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState("all");
  const [sort, setSort] = useState("points");
  const [page, setPage] = useState(1);
  const [creating, setCreating] = useState(false);
  const [leaderCid, setLeaderCid] = useState("");
  const q = useDebounced(search);
  const list = useAsync(() => call<Page<CrewSummary>>("adminList", { search: q, filter, sort, page }), [q, filter, sort, page]);

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center gap-2">
        <div className="relative min-w-56 flex-1">
          <Search className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-mute" />
          <Input value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} placeholder={t("adm.search")} className="pl-9" maxLength={32} aria-label={t("search")} />
        </div>
        <Select value={filter} onChange={(e) => { setFilter(e.target.value); setPage(1); }} className="w-auto" aria-label="filter">
          <option value="all">{t("all")}</option>
          <option value="active">{t("adm.active")}</option>
          <option value="frozen">{t("adm.frozen")}</option>
        </Select>
        <Select value={sort} onChange={(e) => setSort(e.target.value)} className="w-auto" aria-label="sort">
          {["points", "name", "members", "created", "money"].map((s) => (
            <option key={s} value={s}>{t(`adm.sort.${s}` as Key)}</option>
          ))}
        </Select>
        <Button onClick={() => setCreating(true)}>
          <Plus className="size-4" /> {t("adm.new")}
        </Button>
      </div>

      <Card className="!p-3">
        {list.loading && !list.data ? (
          <Loading />
        ) : list.error ? (
          <ErrorState message={list.error} onRetry={list.reload} />
        ) : !list.data?.items.length ? (
          <Empty />
        ) : (
          <>
            <ul className="flex flex-col gap-2">
              {list.data.items.map((c) => (
                <li key={c.id}>
                  <button onClick={() => onOpen(c.id)} className="flex w-full items-center gap-4 rounded-lg border border-line bg-panel2/50 px-3 py-2.5 text-left transition-colors hover:border-accent/60 hover:bg-panel2">
                    <Emblem color={c.color} tag={c.tag} logo={c.logo} size={40} />
                    <div className="min-w-0 flex-1">
                      <div className="racing-title flex items-center gap-2 truncate" style={{ color: c.color }}>
                        [{c.tag}] {c.name}
                        {c.frozen && <Badge color="#38bdf8"><Snowflake className="mr-1 size-3" />{t("adm.frozen")}</Badge>}
                      </div>
                      <div className="truncate text-xs text-mute">#{c.id} · {t("ov.leader")}: {c.leaderName}</div>
                    </div>
                    <div className="hidden text-right text-xs text-mute sm:block">
                      <div><b className="text-ink">{num(c.points)}</b> {t("stat.points").toLowerCase()}</div>
                      <div>{c.members}/{config.maxMembers} · {money(c.money, config.currency)}</div>
                    </div>
                  </button>
                </li>
              ))}
            </ul>
            <Pagination page={list.data.page} total={list.data.total} pageSize={list.data.pageSize} onChange={setPage} />
          </>
        )}
      </Card>

      {creating && (
        <Modal title={t("adm.new")} onClose={() => setCreating(false)}>
          <IdentityForm
            mode="full"
            submitLabel={t("create")}
            onSubmit={async (v) => {
              const res = await call("adminCreate", { ...v, leaderCid: leaderCid.trim() }, t("adm.created"));
              if (res.ok) {
                setCreating(false);
                setLeaderCid("");
                await list.reload();
              }
            }}
          >
            <Field label={t("adm.leader_cid")}>{(id) => <Input id={id} value={leaderCid} onChange={(e) => setLeaderCid(e.target.value)} maxLength={50} required autoComplete="off" />}</Field>
          </IdentityForm>
        </Modal>
      )}
    </div>
  );
}
