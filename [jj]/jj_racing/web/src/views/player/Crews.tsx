import { useState } from "react";
import { Check, Info, Medal, Swords, Trophy, X } from "lucide-react";
import { Button, Card, CrewTag, Empty, SectionTitle, StatTile } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { useInterval } from "@/lib/hooks";
import { num, safeColor } from "@/lib/format";
import type { Challenge } from "@/lib/types";
import { Countdown, Kv, useMoney } from "./common";
import { ChallengeModal } from "./ChallengeModal";

function ChallengeSummary({ c, other }: { c: Challenge; other: Challenge["from"] }) {
  const t = useT();
  const money = useMoney();
  return (
    <div className="min-w-0 flex-1">
      <div className="flex flex-wrap items-center gap-2 text-sm">
        <CrewTag tag={other.tag} color={other.color} />
        <span className="font-semibold">{other.name}</span>
        <span className="ml-auto text-xs text-mute">
          {t("p.crews.expires")} <Countdown seconds={c.expiresIn} />
        </span>
      </div>
      <div className="mt-1 text-xs text-mute">
        {c.trackName} · {c.laps} {t("laps").toLowerCase()} · {t(`class.${c.vehicleClass}`)} · {t("p.lobby.teamSize", { n: c.teamSize })} · {t("p.lobby.stake", { amount: money(c.stake) })}
      </div>
    </div>
  );
}

export function Crews({ onEnterLobby }: { onEnterLobby: () => void }) {
  const t = useT();
  const { state, config, call, reload } = useApp();
  const money = useMoney();
  const [busy, setBusy] = useState<string | null>(null);
  const [challenging, setChallenging] = useState(false);
  useInterval(() => void reload(), 5000);
  const crew = state.crew;
  if (!crew) return null;
  const { incoming, outgoing } = state.challenges;

  const respond = async (c: Challenge, accept: boolean) => {
    setBusy(`r${c.id}`);
    const res = await call("respondChallenge", { id: c.id, accept }, accept ? undefined : t("p.crews.declined"));
    setBusy(null);
    await reload();
    if (res.ok && accept) onEnterLobby();
  };

  const cancel = async (c: Challenge) => {
    setBusy(`c${c.id}`);
    const res = await call("cancelChallenge", { id: c.id }, t("p.crews.cancelled"));
    setBusy(null);
    if (res.ok) await reload();
  };

  return (
    <div className="space-y-5">
      <div className="rounded-xl border-l-4" style={{ borderLeftColor: safeColor(crew.color) }}>
        <Card className="rounded-l-none">
          <div className="mb-4 flex flex-wrap items-center gap-3">
            <CrewTag tag={crew.tag} color={crew.color} className="text-sm" />
            <h2 className="racing-title mr-auto text-xl">{crew.name}</h2>
            <Button disabled={!crew.canChallenge} title={crew.canChallenge ? undefined : t("p.crews.cannotChallenge", { rank: config.crewVs.minRank })} onClick={() => setChallenging(true)}>
              <Swords className="size-4" /> {t("p.crews.challenge")}
            </Button>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <StatTile label={t("p.crews.levelLabel")} value={crew.level} icon={<Medal className="size-3.5" />} />
            <StatTile label={t("p.crews.points")} value={num(crew.points)} icon={<Trophy className="size-3.5" />} />
            <StatTile label={t("p.stats.wins")} value={num(crew.wins)} />
          </div>
          {!crew.canChallenge && (
            <p className="mt-4 flex items-start gap-2 rounded-lg bg-warn/10 p-3 text-sm text-warn">
              <Info className="mt-0.5 size-4 shrink-0" /> {t("p.crews.cannotChallenge", { rank: config.crewVs.minRank })}
            </p>
          )}
        </Card>
      </div>

      <Card>
        <SectionTitle>
          {t("p.crews.incoming")} {incoming.length > 0 && <span className="ml-1 text-accent">({incoming.length})</span>}
        </SectionTitle>
        {incoming.length === 0 ? (
          <Empty text={t("p.crews.noIncoming")} />
        ) : (
          <div className="space-y-2">
            {incoming.map((c) => (
              <div key={c.id} className="flex flex-wrap items-center gap-3 rounded-lg bg-white/5 px-3 py-2.5">
                <ChallengeSummary c={c} other={c.from} />
                <Button size="sm" loading={busy === `r${c.id}`} onClick={() => respond(c, true)}>
                  <Check className="size-4" /> {t("p.crews.accept")}
                </Button>
                <Button size="sm" variant="danger" disabled={busy === `r${c.id}`} onClick={() => respond(c, false)}>
                  <X className="size-4" /> {t("p.crews.decline")}
                </Button>
              </div>
            ))}
          </div>
        )}
      </Card>

      <Card>
        <SectionTitle>{t("p.crews.outgoing")}</SectionTitle>
        {outgoing.length === 0 ? (
          <Empty text={t("p.crews.noOutgoing")} />
        ) : (
          <div className="space-y-2">
            {outgoing.map((c) => (
              <div key={c.id} className="flex flex-wrap items-center gap-3 rounded-lg bg-white/5 px-3 py-2.5">
                <ChallengeSummary c={c} other={c.to} />
                <Button size="sm" variant="danger" loading={busy === `c${c.id}`} onClick={() => cancel(c)}>
                  {t("p.crews.cancel")}
                </Button>
              </div>
            ))}
          </div>
        )}
      </Card>

      <Card>
        <SectionTitle>{t("p.crews.rules")}</SectionTitle>
        <Kv label={t("p.crews.maxTeam")}>{config.crewVs.maxTeamSize}</Kv>
        <Kv label={t("p.crews.maxStake")}>{money(config.crewVs.stakeMax)}</Kv>
        <p className="mt-3 text-xs text-mute">{t(`p.formula.${config.crewVs.formula}`)}</p>
      </Card>

      {challenging && <ChallengeModal onClose={() => setChallenging(false)} onCreated={() => setChallenging(false)} />}
    </div>
  );
}
