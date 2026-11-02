import { useState } from "react";
import { Crown, Flag, Lock, LogIn, MailPlus, Plus, RefreshCw, Users } from "lucide-react";
import { Badge, Button, Card, DataState, SectionTitle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { useAsync, useInterval } from "@/lib/hooks";
import { fetchNui } from "@/lib/nui";
import type { Invite, Lobby, LobbySummary } from "@/lib/types";
import { Countdown, ModeBadge, useMoney } from "./common";
import { CreateRaceModal } from "./CreateRaceModal";

interface RacesPayload {
  races: LobbySummary[];
  invites: Invite[];
}

export function Races({ onEnterLobby }: { onEnterLobby: () => void }) {
  const t = useT();
  const { state, call, reload } = useApp();
  const money = useMoney();
  const [creating, setCreating] = useState(false);
  const [joining, setJoining] = useState<number | null>(null);
  const data = useAsync(() => fetchNui<RacesPayload>("listRaces"), []);
  useInterval(() => void data.reload(), 5000);

  const join = async (id: number) => {
    setJoining(id);
    const res = await call<Lobby>("joinRace", { id });
    setJoining(null);
    if (!res.ok) return void data.reload();
    await reload();
    onEnterLobby();
  };

  const inRace = !!state.lobby;
  const races = data.data?.races ?? [];
  const invites = data.data?.invites ?? [];

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center gap-2">
        <h2 className="racing-title mr-auto text-xl">{t("p.races.title")}</h2>
        <Button variant="ghost" size="sm" onClick={() => void data.reload()} aria-label={t("refresh")}>
          <RefreshCw className={`size-4 ${data.loading ? "animate-spin" : ""}`} />
        </Button>
        <Button disabled={inRace} title={inRace ? t("p.races.alreadyIn") : undefined} onClick={() => setCreating(true)}>
          <Plus className="size-4" /> {t("p.races.create")}
        </Button>
      </div>

      {invites.length > 0 && (
        <Card className="border-accent/40">
          <SectionTitle>
            <span className="flex items-center gap-2">
              <MailPlus className="size-4 text-accent" /> {t("p.races.invites")}
            </span>
          </SectionTitle>
          <div className="space-y-2">
            {invites.map((i) => (
              <div key={i.lobbyId} className="flex flex-wrap items-center gap-3 rounded-lg bg-white/5 px-3 py-2 text-sm">
                <div className="min-w-0 flex-1">
                  <div className="truncate font-semibold">{i.name}</div>
                  <div className="truncate text-xs text-mute">
                    {i.trackName} · {t("p.races.host")}: {i.hostName} · <Countdown seconds={i.expiresIn} />
                  </div>
                </div>
                <Button size="sm" disabled={inRace} loading={joining === i.lobbyId} onClick={() => join(i.lobbyId)}>
                  <LogIn className="size-4" /> {t("p.races.join")}
                </Button>
              </div>
            ))}
          </div>
        </Card>
      )}

      <DataState loading={data.loading} error={data.error} hasData={data.data !== null} empty={data.data !== null && races.length === 0} emptyText={t("p.races.empty")} onRetry={data.reload}>
        <div className="space-y-3">
          {races.map((r) => {
            const full = r.playerCount >= r.maxPlayers;
            const mine = state.lobby?.id === r.id;
            return (
              <Card key={r.id} className={`p-4 ${r.official ? "border-warn/40" : ""}`}>
                <div className="flex flex-wrap items-center gap-x-4 gap-y-3">
                  <div className="min-w-48 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="racing-title truncate text-base">{r.name}</span>
                      <ModeBadge mode={r.mode} />
                      {r.private && (
                        <Badge>
                          <Lock className="mr-1 size-3" />
                          {t("p.races.private")}
                        </Badge>
                      )}
                      {r.invited && <Badge color="#22c55e">{t("p.races.invited")}</Badge>}
                      {r.crewVs && (
                        <Badge color={r.crewVs.a.color}>
                          {r.crewVs.a.tag} vs {r.crewVs.b.tag}
                        </Badge>
                      )}
                    </div>
                    <div className="mt-1 flex flex-wrap items-center gap-x-3 text-xs text-mute">
                      <span>{r.trackName}</span>
                      <span>
                        {r.laps} {t("laps").toLowerCase()}
                      </span>
                      <span>{t(`class.${r.vehicleClass}`)}</span>
                      <span className="flex items-center gap-1">
                        <Crown className="size-3" /> {r.hostName}
                      </span>
                    </div>
                  </div>
                  <div className="tabular flex items-center gap-5 text-sm">
                    <div>
                      <div className="text-[10px] tracking-wide text-mute uppercase">{t("p.races.fee")}</div>
                      <div className="font-bold">{r.entryFee > 0 ? money(r.entryFee) : t("p.races.free")}</div>
                    </div>
                    <div>
                      <div className="text-[10px] tracking-wide text-mute uppercase">{t("p.races.prize")}</div>
                      <div className="font-bold text-accent">{money(r.prizePool)}</div>
                    </div>
                    <div>
                      <div className="text-[10px] tracking-wide text-mute uppercase">{t("players")}</div>
                      <div className="flex items-center gap-1 font-bold">
                        <Users className="size-3.5 text-mute" />
                        {r.playerCount}/{r.maxPlayers}
                      </div>
                    </div>
                  </div>
                  <Button
                    size="sm"
                    loading={joining === r.id}
                    disabled={inRace || full}
                    title={mine ? t("p.races.alreadyIn") : full ? t("p.races.full") : undefined}
                    onClick={() => join(r.id)}
                  >
                    <LogIn className="size-4" /> {mine ? t("p.races.yours") : full ? t("p.races.full") : t("p.races.join")}
                  </Button>
                </div>
              </Card>
            );
          })}
        </div>
      </DataState>
      {creating && <CreateRaceModal onClose={() => setCreating(false)} onCreated={onEnterLobby} />}
      <p className="flex items-center gap-2 text-xs text-mute">
        <Flag className="size-3.5" /> {t("p.races.hint")}
      </p>
      <p className="text-xs text-mute">{t("p.races.keys")}</p>
    </div>
  );
}
