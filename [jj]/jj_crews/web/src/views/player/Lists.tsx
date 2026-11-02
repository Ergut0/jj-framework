import { useState } from "react";
import { Crown } from "lucide-react";
import { Card, Emblem, Empty, ErrorState, Loading, Pagination, SectionTitle } from "@/components/ui";
import { ActivityList } from "@/components/ActivityList";
import { useApp } from "@/lib/store";
import { useAsync } from "@/lib/hooks";
import { useT } from "@/lib/i18n";
import { num } from "@/lib/format";
import type { ActivityItem, Page, RankingRow } from "@/lib/types";

export function Activity() {
  const t = useT();
  const { call, state } = useApp();
  const [page, setPage] = useState(1);
  const res = useAsync(() => call<Page<ActivityItem>>("getActivity", { page }), [page, state.crew?.points, state.crew?.members.length]);
  return (
    <Card>
      <SectionTitle>{t("nav.activity")}</SectionTitle>
      {res.loading && !res.data ? (
        <Loading />
      ) : res.error ? (
        <ErrorState message={res.error} onRetry={res.reload} />
      ) : (
        <>
          <ActivityList items={res.data?.items ?? []} />
          {res.data && <Pagination page={res.data.page} total={res.data.total} pageSize={res.data.pageSize} onChange={setPage} />}
        </>
      )}
    </Card>
  );
}

export function Ranking() {
  const t = useT();
  const { call } = useApp();
  const res = useAsync(() => call<{ top: RankingRow[]; mine?: RankingRow }>("getRanking"), []);
  const myId = res.data?.mine?.id;

  return (
    <Card>
      <SectionTitle action={res.data?.mine && <span className="text-xs text-mute">{t("rank.mine")}: <b className="text-accent">#{res.data.mine.pos}</b></span>}>
        {t("nav.ranking")}
      </SectionTitle>
      {res.loading && !res.data ? (
        <Loading />
      ) : res.error ? (
        <ErrorState message={res.error} onRetry={res.reload} />
      ) : !res.data?.top.length ? (
        <Empty text={t("rank.empty")} />
      ) : (
        <ul className="flex flex-col gap-2">
          {res.data.top.map((r, i) => (
            <li
              key={r.id}
              style={{ animationDelay: `${Math.min(i, 12) * 25}ms` }}
              className={`animate-rise flex items-center gap-4 rounded-lg border px-3 py-2.5 ${r.id === myId ? "border-accent/60 bg-accent/10" : "border-line bg-panel2/50"}`}
            >
              <span className={`racing-title w-8 text-center text-xl ${r.pos === 1 ? "text-warn" : r.pos <= 3 ? "text-ink" : "text-mute"}`}>
                {r.pos === 1 ? <Crown className="mx-auto size-5" /> : r.pos}
              </span>
              <Emblem color={r.color} tag={r.tag} logo={r.logo} size={38} />
              <div className="min-w-0 flex-1">
                <div className="racing-title truncate" style={{ color: r.color }}>[{r.tag}] {r.name}</div>
                <div className="text-xs text-mute">{t("stat.level")} {r.level} · {t("invites.members", { n: r.members })}</div>
              </div>
              <div className="text-right">
                <div className="racing-title text-lg">{num(r.points)}</div>
                <div className="text-xs text-mute">{num(r.wins)} {t("stat.wins").toLowerCase()}</div>
              </div>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}
