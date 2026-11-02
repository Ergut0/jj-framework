import { useState } from "react";
import { Ban, RefreshCw, UserX } from "lucide-react";
import { Badge, Button, Card, CrewTag, DataState, DifficultyBadge, SectionTitle, Toggle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT, type Translator } from "@/lib/i18n";
import { fetchNui } from "@/lib/nui";
import { useAsync, useInterval } from "@/lib/hooks";
import { money } from "@/lib/format";
import type { AdminRace, AdminRacePlayer } from "@/lib/types";
import { IconButton, ReasonDialog } from "./fields";

const STATE_COLOR: Record<string, string> = { open: "#22c55e", checking: "#f59e0b", countdown: "#f59e0b", running: "#3cc8ff" };
const MODE_COLOR: Record<string, string> = { open: "#8d8da3", crew: "#38d9f5", official: "#fbbf24", test: "#a855f7" };

function playerStatus(t: Translator, status: string): string {
  const k = `a.ps.${status}`;
  const v = t(k);
  return v === k ? status : v;
}

type Dialog = { kind: "cancel"; race: AdminRace } | { kind: "kick"; race: AdminRace; player: AdminRacePlayer };

export function ActiveRaces() {
  const t = useT();
  const { call, config } = useApp();
  const list = useAsync(() => fetchNui<{ races: AdminRace[] }>("adminListRaces"), []);
  const [dialog, setDialog] = useState<Dialog | null>(null);
  const [refund, setRefund] = useState(true);
  const [busy, setBusy] = useState(false);
  useInterval(() => void list.reload(), 4000, dialog === null);

  const races = list.data?.races ?? [];

  const confirm = async (reason: string) => {
    if (!dialog) return;
    setBusy(true);
    const res =
      dialog.kind === "cancel"
        ? await call("adminCancelRace", { id: dialog.race.id, reason }, t("a.races.cancelled"))
        : await call("adminKickPlayer", { raceId: dialog.race.id, pid: dialog.player.pid, reason, refund }, t("a.races.kicked", { name: dialog.player.name }));
    setBusy(false);
    if (res.ok) {
      setDialog(null);
      void list.reload();
    }
  };

  return (
    <div>
      <SectionTitle
        action={
          <Button variant="ghost" size="sm" onClick={() => void list.reload()}>
            <RefreshCw className={`size-4 ${list.loading ? "animate-spin" : ""}`} /> {t("refresh")}
          </Button>
        }
      >
        {t("a.nav.races")}
      </SectionTitle>
      <p className="mb-4 text-xs text-mute">{t("a.races.auto")}</p>

      <DataState loading={list.loading} error={list.error} hasData={!!list.data} empty={!!list.data && races.length === 0} emptyText={t("a.races.empty")} onRetry={list.reload}>
        <div className="grid gap-4 lg:grid-cols-2">
          {races.map((r) => (
            <Card key={r.id} className="flex flex-col gap-3 p-4">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <div className="racing-title truncate text-base">{r.name}</div>
                  <div className="mt-1 flex flex-wrap items-center gap-2">
                    <Badge color={MODE_COLOR[r.mode]}>{t(`mode.${r.mode}`)}</Badge>
                    <Badge color={STATE_COLOR[r.state]}>{t(`state.${r.state}`)}</Badge>
                    {r.private && <Badge>{t("a.races.private")}</Badge>}
                    <DifficultyBadge difficulty={r.difficulty} />
                  </div>
                </div>
                <Button variant="danger" size="sm" onClick={() => setDialog({ kind: "cancel", race: r })}>
                  <Ban className="size-4" /> {t("a.races.cancel")}
                </Button>
              </div>
              <dl className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs sm:grid-cols-3">
                <Info label={t("a.races.track")} value={r.trackName} />
                <Info label={t("a.races.host")} value={r.hostName} />
                <Info label={t("laps")} value={String(r.laps)} />
                <Info label={t("a.form.class")} value={t(`class.${r.vehicleClass}`)} />
                <Info label={t("a.races.pool")} value={money(r.prizePool, config.currency)} />
                <Info label={t("a.races.fee")} value={money(r.entryFee, config.currency)} />
              </dl>
              <ul className="flex flex-col gap-1">
                {r.players.map((p) => (
                  <li key={p.pid} className="flex items-center gap-2 rounded-lg bg-panel2/70 px-3 py-1.5 text-sm">
                    <span className="tabular w-7 shrink-0 text-xs text-mute">#{p.pid}</span>
                    <span className="min-w-0 truncate font-semibold">{p.name}</span>
                    <CrewTag tag={p.crew?.tag} color={p.crew?.color} />
                    {p.host && <Badge>{t("a.races.hostTag")}</Badge>}
                    {p.team && <Badge>{p.team}</Badge>}
                    <span className="ml-auto flex shrink-0 items-center gap-2 text-xs text-mute">
                      <span>{playerStatus(t, p.status)}</span>
                      {p.strikes > 0 && <span className="text-warn">{t("a.races.strikes", { n: p.strikes })}</span>}
                      {p.paid > 0 && <span className="tabular">{money(p.paid, config.currency)}</span>}
                    </span>
                    <IconButton danger label={t("a.races.kick")} onClick={() => { setRefund(true); setDialog({ kind: "kick", race: r, player: p }); }}>
                      <UserX className="size-4" />
                    </IconButton>
                  </li>
                ))}
                {r.players.length === 0 && <li className="text-xs text-mute">{t("a.races.noPlayers")}</li>}
              </ul>
            </Card>
          ))}
        </div>
      </DataState>

      {dialog?.kind === "cancel" && <ReasonDialog title={t("a.races.cancelTitle")} message={t("a.races.cancelMsg", { name: dialog.race.name })} loading={busy} onConfirm={(r) => void confirm(r)} onClose={() => setDialog(null)} />}
      {dialog?.kind === "kick" && (
        <ReasonDialog title={t("a.races.kickTitle")} message={t("a.races.kickMsg", { name: dialog.player.name })} loading={busy} onConfirm={(r) => void confirm(r)} onClose={() => setDialog(null)}>
          <Toggle checked={refund} onChange={setRefund} label={t("a.races.refund")} />
        </ReasonDialog>
      )}
    </div>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div className="min-w-0">
      <dt className="text-mute">{label}</dt>
      <dd className="truncate font-semibold text-ink">{value}</dd>
    </div>
  );
}
