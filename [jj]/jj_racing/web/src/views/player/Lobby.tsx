import { useState } from "react";
import { Check, Crown, DoorOpen, Info, Play, Swords, UserMinus, UserPlus, Users, X } from "lucide-react";
import { Badge, Button, Card, ConfirmDialog, CrewTag, NumberInput, SectionTitle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { safeColor } from "@/lib/format";
import type { Lobby as LobbyData, LobbyPlayer } from "@/lib/types";
import { Kv, ModeBadge, StateBadge, useMoney } from "./common";

function PlayerRow({ p, canKick, onKick }: { p: LobbyPlayer; canKick: boolean; onKick: () => void }) {
  const t = useT();
  return (
    <div className={`flex items-center gap-3 rounded-lg px-3 py-2 text-sm ${p.you ? "bg-accent/10 ring-1 ring-accent/40" : "bg-white/5"}`}>
      {p.host ? <Crown className="size-4 shrink-0 text-warn" aria-label={t("p.lobby.host")} /> : <span className="size-4 shrink-0" />}
      <span className="min-w-0 flex-1 truncate font-semibold">
        {p.name}
        {p.you && <span className="ml-1 text-xs font-normal text-mute">({t("you")})</span>}
      </span>
      <CrewTag tag={p.crew?.tag} color={p.crew?.color} />
      {p.ready ? (
        <Badge color="#22c55e">
          <Check className="mr-1 size-3" />
          {t("p.lobby.ready")}
        </Badge>
      ) : (
        <Badge color="#f59e0b">{t("p.lobby.waiting")}</Badge>
      )}
      {canKick && (
        <button onClick={onKick} aria-label={t("p.lobby.kick")} title={t("p.lobby.kick")} className="rounded p-1 text-mute hover:bg-bad/20 hover:text-bad">
          <UserMinus className="size-4" />
        </button>
      )}
    </div>
  );
}

function CrewVsBanner({ lobby }: { lobby: LobbyData }) {
  const t = useT();
  const money = useMoney();
  const vs = lobby.crewVs;
  if (!vs) return null;
  const side = (c: typeof vs.a, align: string) => (
    <div className={`flex-1 ${align}`}>
      <div className="racing-title text-2xl" style={{ color: safeColor(c.color) }}>
        [{c.tag}]
      </div>
      <div className="truncate text-xs text-mute">{c.name}</div>
    </div>
  );
  return (
    <Card className="border-fuchsia-500/30">
      <div className="flex items-center gap-4">
        {side(vs.a, "text-left")}
        <Swords className="size-7 shrink-0 text-accent" />
        {side(vs.b, "text-right")}
      </div>
      <div className="mt-3 flex flex-wrap justify-center gap-x-6 gap-y-1 border-t border-line/60 pt-3 text-xs text-mute">
        <span>{t("p.lobby.teamSize", { n: vs.size })}</span>
        <span>{t("p.lobby.stake", { amount: money(vs.stake) })}</span>
        <span>{t(`p.formula.${vs.formula}`)}</span>
      </div>
    </Card>
  );
}

export function Lobby({ lobby }: { lobby: LobbyData }) {
  const t = useT();
  const { call, reload } = useApp();
  const money = useMoney();
  const [busy, setBusy] = useState<string | null>(null);
  const [confirmLeave, setConfirmLeave] = useState(false);
  const [invitePid, setInvitePid] = useState(0);
  const me = lobby.players.find((p) => p.you);
  const open = lobby.state === "open";

  const run = async (key: string, action: string, data?: unknown, okMsg?: string) => {
    setBusy(key);
    const res = await call(action, data, okMsg);
    setBusy(null);
    if (res.ok) await reload();
    return res.ok;
  };

  const kick = (pid: number) => void run(`kick${pid}`, "kickPlayer", { pid }, t("p.lobby.kicked"));
  const teams = lobby.crewVs ? (["A", "B"] as const) : null;

  return (
    <div className="space-y-4">
      <Card>
        <div className="flex flex-wrap items-center gap-2">
          <h2 className="racing-title mr-auto text-2xl">{lobby.name}</h2>
          <ModeBadge mode={lobby.mode} />
          <StateBadge state={lobby.state} />
          {lobby.private && <Badge>{t("p.races.private")}</Badge>}
        </div>
        <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-sm text-mute">
          <span>{lobby.trackName}</span>
          <span>{t(`cat.${lobby.category}`)}</span>
          <span>{t(`diff.${lobby.difficulty}`)}</span>
          <span>
            {lobby.laps} {t("laps").toLowerCase()}
          </span>
          <span>{t(`class.${lobby.vehicleClass}`)}</span>
          <span>{lobby.collisions ? t("p.lobby.collisionsOn") : t("p.lobby.collisionsOff")}</span>
          <span className="flex items-center gap-1">
            <Crown className="size-3.5 text-warn" /> {lobby.hostName}
          </span>
        </div>
      </Card>

      <CrewVsBanner lobby={lobby} />

      <div className="grid gap-4 lg:grid-cols-[2fr_1fr]">
        <Card>
          <SectionTitle
            action={
              <span className="flex items-center gap-1 text-xs text-mute">
                <Users className="size-3.5" />
                {lobby.players.length}/{lobby.crewVs ? lobby.crewVs.size * 2 : lobby.maxPlayers}
              </span>
            }
          >
            {t("players")}
          </SectionTitle>
          {teams ? (
            <div className="grid gap-4 sm:grid-cols-2">
              {teams.map((team) => {
                const crew = lobby.crewVs?.[team === "A" ? "a" : "b"];
                return (
                  <div key={team} className="space-y-2">
                    <div className="racing-title text-sm" style={{ color: safeColor(crew?.color) }}>
                      {t("p.lobby.team", { team })} · {crew?.tag}
                    </div>
                    {lobby.players
                      .filter((p) => p.team === team)
                      .map((p) => (
                        <PlayerRow key={p.pid} p={p} canKick={lobby.isHost && !p.you && open} onKick={() => kick(p.pid)} />
                      ))}
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="space-y-2">
              {lobby.players.map((p) => (
                <PlayerRow key={p.pid} p={p} canKick={lobby.isHost && !p.you && open} onKick={() => kick(p.pid)} />
              ))}
            </div>
          )}
        </Card>

        <div className="space-y-4">
          <Card>
            <SectionTitle>{t("p.lobby.prizePool")}</SectionTitle>
            <div className="racing-title tabular mb-2 text-3xl text-accent">{money(lobby.prizePool)}</div>
            <Kv label={t("p.races.fee")}>{lobby.entryFee > 0 ? money(lobby.entryFee) : t("p.races.free")}</Kv>
            <Kv label={t("p.prize.extra")}>{money(lobby.extraPrize)}</Kv>
          </Card>
          <Card>
            <div className="flex flex-col gap-2">
              {!lobby.isHost && me && (
                <Button variant={me.ready ? "outline" : "primary"} disabled={!open} loading={busy === "ready"} onClick={() => void run("ready", "setReady", { ready: !me.ready })}>
                  {me.ready ? (
                    <>
                      <X className="size-4" /> {t("p.lobby.notReady")}
                    </>
                  ) : (
                    <>
                      <Check className="size-4" /> {t("p.lobby.setReady")}
                    </>
                  )}
                </Button>
              )}
              {lobby.isHost && (
                <Button disabled={!open} loading={busy === "start"} onClick={() => void run("start", "startRace")}>
                  <Play className="size-4" /> {t("p.lobby.start")}
                </Button>
              )}
              <Button variant="danger" onClick={() => setConfirmLeave(true)}>
                <DoorOpen className="size-4" /> {t("p.lobby.leave")}
              </Button>
            </div>
            {lobby.isHost && open && (
              <form
                className="mt-4 flex items-end gap-2 border-t border-line/60 pt-4"
                onSubmit={(e) => {
                  e.preventDefault();
                  if (invitePid > 0) void run("invite", "invitePlayer", { pid: invitePid }, t("p.lobby.invited"));
                }}
              >
                <label className="flex-1 text-xs font-semibold tracking-wide text-mute uppercase">
                  {t("p.lobby.inviteId")}
                  <NumberInput className="mt-1.5" value={invitePid} min={0} max={65535} onChange={setInvitePid} />
                </label>
                <Button size="sm" type="submit" variant="outline" disabled={invitePid < 1} loading={busy === "invite"}>
                  <UserPlus className="size-4" /> {t("p.lobby.invite")}
                </Button>
              </form>
            )}
          </Card>
        </div>
      </div>

      <p className="flex items-start gap-2 text-xs text-mute">
        <Info className="mt-0.5 size-3.5 shrink-0" /> {t("p.lobby.vehicleNote", { class: t(`class.${lobby.vehicleClass}`) })}
      </p>

      {confirmLeave && (
        <ConfirmDialog
          danger
          title={t("p.lobby.leave")}
          message={lobby.isHost ? t("p.lobby.leaveHost") : t("p.lobby.leaveGuest")}
          loading={busy === "leave"}
          onClose={() => setConfirmLeave(false)}
          onConfirm={async () => {
            if (await run("leave", "leaveRace")) setConfirmLeave(false);
          }}
        />
      )}
    </div>
  );
}
