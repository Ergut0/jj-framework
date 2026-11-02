import { useState } from "react";
import { Flag, Route, Trophy } from "lucide-react";
import { Card, CrewTag, DataState, DifficultyBadge, Badge, Pagination, SearchInput, Select } from "@/components/ui";
import { TrackMap } from "@/components/TrackMap";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { useAsync, useDebounced } from "@/lib/hooks";
import { fetchNui } from "@/lib/nui";
import { distance, formatTime } from "@/lib/format";
import type { Paginated, TrackSummary } from "@/lib/types";
import { useTrackDetail } from "./trackData";
import { TrackDetailView } from "./TrackDetail";
import { CreateRaceModal } from "./CreateRaceModal";
import { ChallengeModal } from "./ChallengeModal";

const SORTS = ["name", "difficulty", "length", "newest"] as const;

function Thumb({ track }: { track: TrackSummary }) {
  const { config } = useApp();
  const detail = useTrackDetail(track.id, track.version);
  return (
    <div className="aspect-[400/260] w-full overflow-hidden rounded-lg">
      {detail ? (
        <TrackMap route={detail.route} grid={detail.grid} closed={!config.pointToPoint.includes(track.category)} showLabels={false} className="h-full border-0" />
      ) : (
        <div className="h-full w-full animate-pulse rounded-lg bg-white/5" />
      )}
    </div>
  );
}

function TrackCard({ track, onOpen }: { track: TrackSummary; onOpen: () => void }) {
  const t = useT();
  const rec = track.record;
  return (
    <button onClick={onOpen} className="group animate-rise text-left">
      <Card className="h-full p-4 transition-colors group-hover:border-accent/60">
        <Thumb track={track} />
        <div className="mt-3 flex items-start justify-between gap-2">
          <h4 className="racing-title truncate text-base">{track.name}</h4>
          <DifficultyBadge difficulty={track.difficulty} />
        </div>
        <div className="mt-1.5 flex flex-wrap gap-1.5">
          <Badge>{t(`cat.${track.category}`)}</Badge>
          <Badge>{t(`class.${track.vehicleClass}`)}</Badge>
        </div>
        <div className="mt-3 flex items-center gap-4 text-xs text-mute">
          <span className="flex items-center gap-1">
            <Route className="size-3.5" />
            {distance(track.length)}
          </span>
          <span className="flex items-center gap-1">
            <Flag className="size-3.5" />
            {track.checkpointCount}
          </span>
          <span>
            {track.lapsDefault} {t("laps").toLowerCase()}
          </span>
        </div>
        <div className="mt-3 flex items-center gap-2 border-t border-line/60 pt-3 text-xs">
          <Trophy className="size-3.5 shrink-0 text-warn" />
          {rec ? (
            <>
              <span className="truncate font-semibold">{rec.name}</span>
              <CrewTag tag={rec.crewTag} color={rec.crewColor} />
              <span className="tabular ml-auto font-bold">{formatTime(rec.time)}</span>
            </>
          ) : (
            <span className="text-mute">{t("p.catalog.noRecord")}</span>
          )}
        </div>
      </Card>
    </button>
  );
}

export function Catalog({ onEnterLobby }: { onEnterLobby: () => void }) {
  const t = useT();
  const { config } = useApp();
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("");
  const [difficulty, setDifficulty] = useState("");
  const [vehicleClass, setVehicleClass] = useState("");
  const [sort, setSort] = useState<(typeof SORTS)[number]>("name");
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<number | null>(null);
  const [createFor, setCreateFor] = useState<number | null>(null);
  const [challengeFor, setChallengeFor] = useState<number | null>(null);
  const q = useDebounced(search.trim(), 300);

  const list = useAsync(
    () => fetchNui<Paginated<TrackSummary>>("listTracks", { search: q, category, difficulty, vehicleClass, sort, page }),
    [q, category, difficulty, vehicleClass, sort, page],
  );

  const filter = <T extends string>(set: (v: T) => void) => (v: T) => {
    set(v);
    setPage(1);
  };

  return (
    <div className="space-y-4">
      {selected === null ? (
        <>
          <div className="flex flex-wrap gap-2">
            <SearchInput
              className="min-w-48 flex-1"
              value={search}
              placeholder={t("p.catalog.search")}
              aria-label={t("search")}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
            />
            <Select className="w-auto" value={category} aria-label={t("p.catalog.category")} onChange={(e) => filter(setCategory)(e.target.value)}>
              <option value="">{t("p.catalog.category")}</option>
              {config.categories.map((c) => (
                <option key={c} value={c}>
                  {t(`cat.${c}`)}
                </option>
              ))}
            </Select>
            <Select className="w-auto" value={difficulty} aria-label={t("p.catalog.difficulty")} onChange={(e) => filter(setDifficulty)(e.target.value)}>
              <option value="">{t("p.catalog.difficulty")}</option>
              {config.difficulties.map((d) => (
                <option key={d} value={d}>
                  {t(`diff.${d}`)}
                </option>
              ))}
            </Select>
            <Select className="w-auto" value={vehicleClass} aria-label={t("p.catalog.class")} onChange={(e) => filter(setVehicleClass)(e.target.value)}>
              <option value="">{t("p.catalog.class")}</option>
              {config.allVehicleClasses.map((c) => (
                <option key={c} value={c}>
                  {t(`class.${c}`)}
                </option>
              ))}
            </Select>
            <Select className="w-auto" value={sort} aria-label={t("p.catalog.sort")} onChange={(e) => {
                setSort(e.target.value as (typeof SORTS)[number]);
                setPage(1);
              }}>
              {SORTS.map((s) => (
                <option key={s} value={s}>
                  {t(`p.sort.${s}`)}
                </option>
              ))}
            </Select>
          </div>
          <DataState loading={list.loading} error={list.error} hasData={list.data !== null} empty={list.data?.items.length === 0} emptyText={t("p.catalog.empty")} onRetry={list.reload}>
            <div className="grid grid-cols-1 gap-4 lg:grid-cols-2 xl:grid-cols-3">
              {list.data?.items.map((tr) => <TrackCard key={tr.id} track={tr} onOpen={() => setSelected(tr.id)} />)}
            </div>
            {list.data && <Pagination page={list.data.page} total={list.data.total} pageSize={list.data.pageSize} onChange={setPage} />}
          </DataState>
        </>
      ) : (
        <TrackDetailView id={selected} onBack={() => setSelected(null)} onCreate={setCreateFor} onChallenge={setChallengeFor} />
      )}
      {createFor !== null && <CreateRaceModal initialTrackId={createFor} onClose={() => setCreateFor(null)} onCreated={onEnterLobby} />}
      {challengeFor !== null && <ChallengeModal initialTrackId={challengeFor} onClose={() => setChallengeFor(null)} onCreated={() => setChallengeFor(null)} />}
    </div>
  );
}
