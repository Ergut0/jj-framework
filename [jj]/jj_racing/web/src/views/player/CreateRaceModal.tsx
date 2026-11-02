import { useState } from "react";
import { Flag } from "lucide-react";
import { Button, DataState, Field, Input, Modal, NumberInput, Select, Toggle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { useAsync } from "@/lib/hooks";
import type { CreateRaceInput, Lobby } from "@/lib/types";
import { estimatePrize, Kv, useMoney } from "./common";
import { loadAllTracks } from "./trackData";

export function CreateRaceModal({ initialTrackId, onClose, onCreated }: { initialTrackId?: number; onClose: () => void; onCreated: () => void }) {
  const t = useT();
  const { config, call, reload } = useApp();
  const money = useMoney();
  const tracks = useAsync(() => loadAllTracks(), []);
  const [trackId, setTrackId] = useState<number | null>(initialTrackId ?? null);
  const [lapsInput, setLapsInput] = useState<number | null>(null);
  const [classInput, setClassInput] = useState<string | null>(null);
  const [entryFee, setEntryFee] = useState(0);
  const [extraPrize, setExtraPrize] = useState(0);
  const [priv, setPriv] = useState(false);
  const [name, setName] = useState("");
  const [drivers, setDrivers] = useState(4);
  const [busy, setBusy] = useState(false);

  const list = tracks.data ?? [];
  const track = list.find((x) => x.id === trackId) ?? (trackId === null ? list[0] : undefined);
  const pointToPoint = !!track && config.pointToPoint.includes(track.category);
  const laps = pointToPoint ? 1 : (lapsInput ?? track?.lapsDefault ?? 1);
  const fixedClass = !!track && track.vehicleClass !== "any";
  const vehicleClass = track ? (fixedClass ? track.vehicleClass : (classInput ?? "any")) : "any";
  const valid = !!track && laps >= 1 && laps <= config.maxLaps && entryFee >= 0 && entryFee <= config.entryFeeMax && extraPrize >= 0 && extraPrize <= config.extraPrizeMax;
  const est = estimatePrize(config, { entryFee, drivers, extra: extraPrize, base: track?.basePrize ?? 0 });

  const pick = (id: number) => {
    setTrackId(id);
    setLapsInput(null);
    setClassInput(null);
  };

  const submit = async () => {
    if (!track || !valid) return;
    setBusy(true);
    const input: CreateRaceInput = { trackId: track.id, laps, vehicleClass, entryFee, extraPrize, private: priv };
    if (name.trim()) input.name = name.trim();
    const res = await call<Lobby>("createRace", input, t("p.create.done"));
    setBusy(false);
    if (!res.ok) return;
    await reload();
    onClose();
    onCreated();
  };

  return (
    <Modal title={t("p.create.title")} onClose={onClose} wide>
      <DataState loading={tracks.loading} error={tracks.error} hasData={tracks.data !== null} empty={tracks.data?.length === 0} emptyText={t("p.catalog.empty")} onRetry={tracks.reload}>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label={t("p.create.track")} className="sm:col-span-2">
            {(id) => (
              <Select id={id} value={track?.id ?? ""} onChange={(e) => pick(Number(e.target.value))}>
                {list.map((x) => (
                  <option key={x.id} value={x.id}>
                    {x.name} · {t(`cat.${x.category}`)} · {t(`diff.${x.difficulty}`)}
                  </option>
                ))}
              </Select>
            )}
          </Field>
          {!pointToPoint && (
            <Field label={t("laps")} hint={t("p.create.lapsHint", { max: config.maxLaps })}>
              {(id) => <NumberInput id={id} value={laps} min={1} max={config.maxLaps} onChange={setLapsInput} />}
            </Field>
          )}
          <Field label={t("p.create.class")} hint={fixedClass ? t("p.create.classFixed") : undefined}>
            {(id) => (
              <Select id={id} value={vehicleClass} disabled={fixedClass} onChange={(e) => setClassInput(e.target.value)}>
                {(fixedClass ? [vehicleClass] : config.vehicleClasses).map((c) => (
                  <option key={c} value={c}>
                    {t(`class.${c}`)}
                  </option>
                ))}
              </Select>
            )}
          </Field>
          <Field label={t("p.create.entryFee")} hint={t("p.create.max", { max: money(config.entryFeeMax) })}>
            {(id) => <NumberInput id={id} value={entryFee} min={0} max={config.entryFeeMax} step={100} onChange={setEntryFee} />}
          </Field>
          <Field label={t("p.create.extraPrize")} hint={t("p.create.max", { max: money(config.extraPrizeMax) })}>
            {(id) => <NumberInput id={id} value={extraPrize} min={0} max={config.extraPrizeMax} step={100} onChange={setExtraPrize} />}
          </Field>
          <Field label={t("p.create.name")} hint={t("p.create.nameHint")}>
            {(id) => <Input id={id} value={name} maxLength={48} placeholder={track?.name} onChange={(e) => setName(e.target.value)} />}
          </Field>
          <div className="flex items-center">
            <Toggle checked={priv} onChange={setPriv} label={t("p.create.private")} />
          </div>
        </div>

        <div className="mt-5 rounded-lg border border-line bg-panel2/60 p-4">
          <div className="mb-2 flex items-center justify-between gap-3">
            <span className="racing-title text-sm">{t("p.create.estimate")}</span>
            <label className="flex items-center gap-2 text-xs text-mute">
              {t("p.create.drivers")}
              <NumberInput className="w-16 py-1" value={drivers} min={1} max={config.maxPlayers} onChange={setDrivers} aria-label={t("p.create.drivers")} />
            </label>
          </div>
          <Kv label={t("p.prize.entries")}>{money(est.entries)}</Kv>
          <Kv label={t("p.prize.commission", { pct: config.commissionPct })}>-{money(est.commission)}</Kv>
          <Kv label={t("p.prize.extra")}>{money(est.extra)}</Kv>
          <Kv label={t("p.prize.base")}>{money(est.base)}</Kv>
          <Kv label={t("p.prize.total")}>
            <span className="text-accent">{money(est.total)}</span>
          </Kv>
          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-mute">
            {est.split.map((v, i) => (
              <span key={i}>
                {t("p.prize.place", { n: i + 1 })}: <b className="tabular text-ink">{money(v)}</b>
              </span>
            ))}
          </div>
          <p className="mt-2 text-xs text-mute">{t("p.create.costNote", { cost: money(entryFee + extraPrize) })}</p>
        </div>

        <div className="mt-5 flex justify-end gap-2">
          <Button variant="ghost" onClick={onClose}>
            {t("cancel")}
          </Button>
          <Button loading={busy} disabled={!valid} onClick={submit}>
            <Flag className="size-4" /> {t("p.create.submit")}
          </Button>
        </div>
      </DataState>
    </Modal>
  );
}
