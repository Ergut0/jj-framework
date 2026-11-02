import { useState } from "react";
import { Card, CrewTag, DataState, Field, PositionBadge, Segmented, Select, Empty } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { useAsync } from "@/lib/hooks";
import { fetchNui } from "@/lib/nui";
import { num } from "@/lib/format";
import type { CrewRankRow, LeaderboardPayload, PilotRankRow } from "@/lib/types";
import { LeaderboardTable } from "./common";
import { loadAllTracks } from "./trackData";

type Tab = "times" | "pilots" | "crews";

function BestTimes() {
  const t = useT();
  const tracks = useAsync(() => loadAllTracks(), []);
  const [picked, setPicked] = useState<number | null>(null);
  const trackId = picked ?? tracks.data?.[0]?.id ?? null;
  const board = useAsync<LeaderboardPayload | null>(
    async () => (trackId === null ? { ok: true, data: null } : fetchNui<LeaderboardPayload>("getLeaderboard", { trackId })),
    [trackId],
  );
  return (
    <DataState loading={tracks.loading} error={tracks.error} hasData={tracks.data !== null} empty={tracks.data?.length === 0} emptyText={t("p.catalog.empty")} onRetry={tracks.reload}>
      <Field label={t("p.create.track")} className="mb-4 max-w-sm">
        {(id) => (
          <Select id={id} value={trackId ?? ""} onChange={(e) => setPicked(Number(e.target.value))}>
            {tracks.data?.map((x) => (
              <option key={x.id} value={x.id}>
                {x.name}
              </option>
            ))}
          </Select>
        )}
      </Field>
      <LeaderboardTable rows={board.data?.rows ?? null} loading={board.loading} error={board.error} onRetry={board.reload} />
    </DataState>
  );
}

function Pilots() {
  const t = useT();
  const { state } = useApp();
  const res = useAsync(() => fetchNui<{ rows: PilotRankRow[] }>("getPilotRanking"), []);
  return (
    <DataState loading={res.loading} error={res.error} hasData={res.data !== null} empty={res.data?.rows.length === 0} emptyText={t("p.rank.empty")} onRetry={res.reload}>
      <div className="overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead className="text-xs tracking-wide text-mute uppercase">
            <tr>
              <th className="w-12 py-2">#</th>
              <th className="py-2">{t("p.col.driver")}</th>
              <th className="hidden py-2 text-right sm:table-cell">{t("p.stats.races")}</th>
              <th className="py-2 text-right">{t("p.stats.wins")}</th>
              <th className="hidden py-2 text-right sm:table-cell">{t("p.stats.podiums")}</th>
              <th className="py-2 text-right">{t("p.col.points")}</th>
            </tr>
          </thead>
          <tbody>
            {res.data?.rows.map((r) => (
              <tr key={r.position} className={`border-t border-line/60 ${r.name === state.me.name ? "bg-accent/10" : ""}`}>
                <td className="py-2">
                  <PositionBadge position={r.position} />
                </td>
                <td className="py-2">
                  <span className="mr-2 font-semibold">{r.name}</span>
                  <CrewTag tag={r.crewTag} color={r.crewColor} />
                </td>
                <td className="tabular hidden py-2 text-right text-mute sm:table-cell">{num(r.races)}</td>
                <td className="tabular py-2 text-right">{num(r.wins)}</td>
                <td className="tabular hidden py-2 text-right text-mute sm:table-cell">{num(r.podiums)}</td>
                <td className="tabular py-2 text-right font-bold">{num(r.points)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </DataState>
  );
}

function Crews() {
  const t = useT();
  const { state } = useApp();
  const res = useAsync(() => fetchNui<{ enabled: boolean; rows: CrewRankRow[] }>("getCrewRanking"), []);
  return (
    <DataState loading={res.loading} error={res.error} hasData={res.data !== null} onRetry={res.reload}>
      {res.data && !res.data.enabled ? (
        <Empty text={t("p.rank.crewsDisabled")} />
      ) : res.data?.rows.length === 0 ? (
        <Empty text={t("p.rank.empty")} />
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="text-xs tracking-wide text-mute uppercase">
              <tr>
                <th className="w-12 py-2">#</th>
                <th className="py-2">{t("p.rank.crew")}</th>
                <th className="hidden py-2 text-right sm:table-cell">{t("p.crews.levelLabel")}</th>
                <th className="hidden py-2 text-right sm:table-cell">{t("p.crews.members")}</th>
                <th className="py-2 text-right">{t("p.stats.wins")}</th>
                <th className="py-2 text-right">{t("p.col.points")}</th>
              </tr>
            </thead>
            <tbody>
              {res.data?.rows.map((r) => (
                <tr key={r.id} className={`border-t border-line/60 ${r.id === state.crew?.id ? "bg-accent/10" : ""}`}>
                  <td className="py-2">
                    <PositionBadge position={r.position} />
                  </td>
                  <td className="py-2">
                    <CrewTag tag={r.tag} color={r.color} className="mr-2" />
                    <span className="font-semibold">{r.name}</span>
                  </td>
                  <td className="tabular hidden py-2 text-right text-mute sm:table-cell">{r.level}</td>
                  <td className="tabular hidden py-2 text-right text-mute sm:table-cell">{r.members}</td>
                  <td className="tabular py-2 text-right">{num(r.wins)}</td>
                  <td className="tabular py-2 text-right font-bold">{num(r.points)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </DataState>
  );
}

export function Rankings() {
  const t = useT();
  const { config } = useApp();
  const [tab, setTab] = useState<Tab>("times");
  const options: { value: Tab; label: string }[] = [
    { value: "times", label: t("p.rank.times") },
    { value: "pilots", label: t("p.rank.pilots") },
    { value: "crews", label: t("p.rank.crews") },
  ];
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="racing-title text-xl">{t("p.rank.title")}</h2>
        <Segmented value={tab} options={options} onChange={setTab} />
      </div>
      <Card>
        {tab === "times" && <BestTimes />}
        {tab === "pilots" && <Pilots />}
        {tab === "crews" && (config.crewsEnabled ? <Crews /> : <Empty text={t("p.rank.crewsDisabled")} />)}
      </Card>
    </div>
  );
}
