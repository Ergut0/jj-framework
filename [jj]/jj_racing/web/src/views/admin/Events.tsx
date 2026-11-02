import { useMemo, useState } from "react";
import { CalendarPlus, X } from "lucide-react";
import { Badge, Button, Card, ConfirmDialog, DataState, Field, Input, SectionTitle, Select } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { fetchNui } from "@/lib/nui";
import { useAsync } from "@/lib/hooks";
import { dateTime, fromLocalInput, money, toLocalInput } from "@/lib/format";
import type { EventItem, NuiResponse, Paginated, TrackSummary } from "@/lib/types";
import { DecimalInput, IconButton } from "./fields";

const STATUS_COLOR: Record<EventItem["status"], string> = { scheduled: "#3cc8ff", open: "#22c55e", running: "#f59e0b", done: "#8d8da3", cancelled: "#ef4444" };
const MAX_AHEAD_DAYS = 60;
const MIN_AHEAD_SECONDS = 30;
const nowSec = () => Math.floor(Date.now() / 1000);

/** Todos los circuitos publicados (el listado esta paginado) */
async function fetchEnabledTracks(): Promise<NuiResponse<TrackSummary[]>> {
  const all: TrackSummary[] = [];
  for (let page = 1; page < 50; page++) {
    const res = await fetchNui<Paginated<TrackSummary>>("adminListTracks", { status: "enabled", sort: "name", page });
    if (!res.ok) return res;
    all.push(...res.data.items);
    if (all.length >= res.data.total || res.data.items.length === 0) break;
  }
  return { ok: true, data: all };
}

export function Events() {
  const t = useT();
  const { call, config } = useApp();
  const list = useAsync(() => fetchNui<{ items: EventItem[] }>("adminListEvents"), []);
  const [cancelling, setCancelling] = useState<EventItem | null>(null);
  const [busy, setBusy] = useState(false);
  const items = list.data?.items ?? [];
  const upcoming = items.filter((e) => e.status === "scheduled" || e.status === "open" || e.status === "running").sort((a, b) => a.scheduledAt - b.scheduledAt);
  const past = items.filter((e) => !upcoming.includes(e));

  const cancel = async (e: EventItem) => {
    setBusy(true);
    const res = await call("adminCancelEvent", { id: e.id }, t("a.ev.cancelled"));
    setBusy(false);
    setCancelling(null);
    if (res.ok) void list.reload();
  };

  const renderRow = (e: EventItem) => (
    <li key={e.id} className="flex flex-wrap items-center gap-3 rounded-lg border border-line bg-panel2/60 px-3 py-2.5 text-sm">
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-2">
          <span className="truncate font-semibold">{e.title}</span>
          <Badge color={STATUS_COLOR[e.status]}>{t(`a.ev.status.${e.status}`)}</Badge>
        </div>
        <div className="mt-0.5 text-xs text-mute">
          {e.trackName} · {t("laps")} {e.laps} · {t(`class.${e.vehicleClass}`)} · {money(e.prize, config.currency)}
        </div>
      </div>
      <span className="tabular text-xs text-mute">{dateTime(e.scheduledAt, config.locale)}</span>
      {e.status === "scheduled" && (
        <IconButton danger label={t("a.ev.cancel")} onClick={() => setCancelling(e)}>
          <X className="size-4" />
        </IconButton>
      )}
    </li>
  );

  return (
    <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_340px]">
      <div className="min-w-0">
        <SectionTitle>{t("a.nav.events")}</SectionTitle>
        <DataState loading={list.loading} error={list.error} hasData={!!list.data} empty={!!list.data && items.length === 0} emptyText={t("a.ev.empty")} onRetry={list.reload}>
          {upcoming.length > 0 && (
            <>
              <h4 className="mb-2 text-xs font-semibold tracking-wide text-mute uppercase">{t("a.ev.upcoming")}</h4>
              <ul className="mb-5 flex flex-col gap-2">{upcoming.map(renderRow)}</ul>
            </>
          )}
          {past.length > 0 && (
            <>
              <h4 className="mb-2 text-xs font-semibold tracking-wide text-mute uppercase">{t("a.ev.past")}</h4>
              <ul className="flex flex-col gap-2">{past.map(renderRow)}</ul>
            </>
          )}
        </DataState>
      </div>
      <EventForm onCreated={() => void list.reload()} />

      {cancelling && (
        <ConfirmDialog danger loading={busy} title={t("a.ev.cancelTitle")} message={t("a.ev.cancelMsg", { title: cancelling.title })} onConfirm={() => void cancel(cancelling)} onClose={() => setCancelling(null)} />
      )}
    </div>
  );
}

function EventForm({ onCreated }: { onCreated: () => void }) {
  const t = useT();
  const { call, config } = useApp();
  const tracks = useAsync(fetchEnabledTracks, []);
  const [title, setTitle] = useState("");
  const [trackId, setTrackId] = useState(0);
  const [laps, setLaps] = useState<number | null>(null);
  const [vehicleClass, setVehicleClass] = useState<string | null>(null);
  const [prize, setPrize] = useState(0);
  const [at, setAt] = useState(() => toLocalInput(nowSec() + 86400));
  const [busy, setBusy] = useState(false);

  const options = tracks.data ?? [];
  const track = options.find((x) => x.id === trackId) ?? options[0];
  const p2p = !!track && config.pointToPoint.includes(track.category);
  const lapsValue = p2p ? 1 : (laps ?? track?.lapsDefault ?? 1);
  const classLocked = !!track && track.vehicleClass !== "any";
  const classValue = track && classLocked ? track.vehicleClass : (vehicleClass ?? "any");
  const when = fromLocalInput(at);

  const timeOk = Number.isFinite(when) && when >= nowSec() + MIN_AHEAD_SECONDS && when <= nowSec() + MAX_AHEAD_DAYS * 86400;
  const titleOk = title.trim().length >= 3 && title.trim().length <= 64;
  const problem = useMemo(() => (!track ? "a.ev.v.track" : !titleOk ? "a.ev.v.title" : !timeOk ? "a.ev.v.time" : null), [track, titleOk, timeOk]);

  const submit = async () => {
    if (!track || problem) return;
    setBusy(true);
    const res = await call("adminSaveEvent", { trackId: track.id, title: title.trim(), laps: lapsValue, vehicleClass: classValue, prize, scheduledAt: when }, t("a.ev.created"));
    setBusy(false);
    if (!res.ok) return;
    setTitle("");
    setPrize(0);
    onCreated();
  };

  return (
    <Card className="self-start">
      <SectionTitle>{t("a.ev.new")}</SectionTitle>
      <DataState loading={tracks.loading} error={tracks.error} hasData={!!tracks.data} empty={!!tracks.data && options.length === 0} emptyText={t("a.ev.noTracks")} onRetry={tracks.reload}>
        <div className="flex flex-col gap-3">
          <Field label={t("a.ev.title")}>{(id) => <Input id={id} maxLength={64} value={title} onChange={(e) => setTitle(e.target.value)} />}</Field>
          <Field label={t("a.races.track")}>
            {(id) => (
              <Select id={id} value={track?.id ?? 0} onChange={(e) => { setTrackId(Number(e.target.value)); setLaps(null); }}>
                {options.map((o) => (
                  <option key={o.id} value={o.id}>{o.name}</option>
                ))}
              </Select>
            )}
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label={t("laps")} hint={p2p ? t("a.form.lapsP2p") : undefined}>
              {(id) => <DecimalInput id={id} integer min={1} max={config.maxLaps} disabled={p2p} value={lapsValue} onChange={setLaps} />}
            </Field>
            <Field label={t("a.form.class")}>
              {(id) => (
                <Select id={id} value={classValue} disabled={classLocked} onChange={(e) => setVehicleClass(e.target.value)}>
                  {(classLocked ? [classValue] : config.vehicleClasses).map((c) => (
                    <option key={c} value={c}>{t(`class.${c}`)}</option>
                  ))}
                </Select>
              )}
            </Field>
          </div>
          <Field label={t("a.ev.prize")} hint={t("a.ev.prizeHint", { max: config.eventsMaxPrize.toLocaleString("es-ES") })}>
            {(id) => <DecimalInput id={id} integer min={0} max={config.eventsMaxPrize} value={prize} onChange={setPrize} />}
          </Field>
          <Field label={t("a.ev.when")} hint={t("a.ev.whenHint", { days: MAX_AHEAD_DAYS })}>
            {(id) => (
              <input
                id={id}
                type="datetime-local"
                value={at}
                min={toLocalInput(nowSec() + MIN_AHEAD_SECONDS)}
                max={toLocalInput(nowSec() + MAX_AHEAD_DAYS * 86400)}
                onChange={(e) => setAt(e.target.value)}
                className="w-full rounded-md border border-line bg-bg/70 px-3 py-2 text-sm text-ink scheme-dark outline-none focus:border-accent"
              />
            )}
          </Field>
          <p className="text-xs text-mute">{t("a.ev.info")}</p>
          {problem && <p className="text-xs text-bad">{t(problem)}</p>}
          <Button loading={busy} disabled={!!problem} onClick={() => void submit()}>
            <CalendarPlus className="size-4" /> {t("a.ev.schedule")}
          </Button>
        </div>
      </DataState>
    </Card>
  );
}
