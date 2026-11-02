import { ArrowLeft, Swords, Flag } from "lucide-react";
import { Badge, Button, Card, CrewTag, DataState, DifficultyBadge, SectionTitle } from "@/components/ui";
import { TrackMap } from "@/components/TrackMap";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { useAsync } from "@/lib/hooks";
import { fetchNui } from "@/lib/nui";
import { distance, formatTime } from "@/lib/format";
import type { LeaderboardPayload, TrackDetail } from "@/lib/types";
import { Kv, LeaderboardTable, useMoney } from "./common";

export function TrackDetailView({ id, onBack, onCreate, onChallenge }: { id: number; onBack: () => void; onCreate: (id: number) => void; onChallenge: (id: number) => void }) {
  const t = useT();
  const { config, state } = useApp();
  const money = useMoney();
  const track = useAsync(() => fetchNui<TrackDetail>("getTrack", { id }), [id]);
  const board = useAsync(() => fetchNui<LeaderboardPayload>("getLeaderboard", { trackId: id }), [id]);
  const d = track.data;
  const canChallenge = config.crewsEnabled && !!state.crew && !!d?.allowCrews;

  return (
    <div className="space-y-4">
      <Button variant="ghost" size="sm" onClick={onBack}>
        <ArrowLeft className="size-4" /> {t("back")}
      </Button>
      <DataState loading={track.loading} error={track.error} hasData={d !== null} onRetry={track.reload}>
        {d && (
          <>
            <div className="grid gap-4 lg:grid-cols-[3fr_2fr]">
              <Card>
                <div className="mb-3 flex flex-wrap items-center gap-2">
                  <h3 className="racing-title mr-auto text-2xl">{d.name}</h3>
                  <Badge>{t(`cat.${d.category}`)}</Badge>
                  <DifficultyBadge difficulty={d.difficulty} />
                  <Badge>{t(`class.${d.vehicleClass}`)}</Badge>
                </div>
                <TrackMap route={d.route} grid={d.grid} closed={!config.pointToPoint.includes(d.category)} />
                {d.description && <p className="mt-3 text-sm text-mute">{d.description}</p>}
              </Card>
              <Card>
                <SectionTitle>{t("p.detail.stats")}</SectionTitle>
                <Kv label={t("p.detail.length")}>{distance(d.length)}</Kv>
                <Kv label={t("p.detail.checkpoints")}>{d.checkpointCount}</Kv>
                <Kv label={t("p.detail.lapsDefault")}>{d.lapsDefault}</Kv>
                <Kv label={t("p.detail.basePrize")}>{money(d.basePrize)}</Kv>
                <Kv label={t("p.detail.timeLimit")}>{d.timeLimit > 0 ? `${Math.floor(d.timeLimit / 60)} ${t("minutes")}` : t("p.detail.noLimit")}</Kv>
                <Kv label={t("p.detail.collisions")}>{d.collisions ? t("yes") : t("no")}</Kv>
                <Kv label={t("p.detail.allowsCrews")}>{d.allowCrews ? t("yes") : t("no")}</Kv>
                <Kv label={t("p.detail.reference")}>{formatTime(d.referenceTime)}</Kv>
                <Kv label={t("p.detail.version")}>v{d.version}</Kv>
                <div className="mt-3 rounded-lg bg-white/5 p-3 text-sm">
                  <div className="text-xs font-semibold tracking-wide text-mute uppercase">{t("p.detail.record")}</div>
                  {d.record ? (
                    <div className="mt-1 flex flex-wrap items-center gap-2">
                      <span className="font-semibold">{d.record.name}</span>
                      <CrewTag tag={d.record.crewTag} color={d.record.crewColor} />
                      <span className="text-xs text-mute">{d.record.vehicle}</span>
                      <span className="racing-title tabular ml-auto text-lg">{formatTime(d.record.time)}</span>
                    </div>
                  ) : (
                    <div className="mt-1 text-mute">{t("p.catalog.noRecord")}</div>
                  )}
                </div>
                <div className="mt-4 flex flex-wrap gap-2">
                  <Button onClick={() => onCreate(d.id)}>
                    <Flag className="size-4" /> {t("p.detail.create")}
                  </Button>
                  {canChallenge && (
                    <Button variant="outline" disabled={!state.crew?.canChallenge} title={state.crew?.canChallenge ? undefined : t("p.crews.cannotChallenge", { rank: config.crewVs.minRank })} onClick={() => onChallenge(d.id)}>
                      <Swords className="size-4" /> {t("p.detail.challenge")}
                    </Button>
                  )}
                </div>
              </Card>
            </div>
            <Card>
              <SectionTitle>{t("p.detail.topTimes")}</SectionTitle>
              <LeaderboardTable rows={board.data?.rows ?? null} loading={board.loading} error={board.error} onRetry={board.reload} />
            </Card>
          </>
        )}
      </DataState>
    </div>
  );
}
