import { useState } from "react";
import { Info, Swords } from "lucide-react";
import { Button, CrewTag, DataState, Field, Modal, NumberInput, Select, SearchInput } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { useAsync, useDebounced } from "@/lib/hooks";
import { fetchNui } from "@/lib/nui";
import { num } from "@/lib/format";
import type { ChallengeInput, CrewListItem } from "@/lib/types";
import { useMoney } from "./common";
import { loadAllTracks } from "./trackData";

export function ChallengeModal({ initialTrackId, onClose, onCreated }: { initialTrackId?: number; onClose: () => void; onCreated: () => void }) {
  const t = useT();
  const { config, state, call, reload } = useApp();
  const money = useMoney();
  const [search, setSearch] = useState("");
  const q = useDebounced(search.trim(), 300);
  const crews = useAsync(() => fetchNui<{ items: CrewListItem[] }>("listCrews", { search: q }), [q]);
  const tracks = useAsync(() => loadAllTracks((x) => x.allowCrews), []);
  const [crewId, setCrewId] = useState<number | null>(null);
  const [trackId, setTrackId] = useState<number | null>(initialTrackId ?? null);
  const [lapsInput, setLapsInput] = useState<number | null>(null);
  const [classInput, setClassInput] = useState<string | null>(null);
  const [teamSize, setTeamSize] = useState(2);
  const [stake, setStake] = useState(0);
  const [busy, setBusy] = useState(false);

  const list = tracks.data ?? [];
  const track = list.find((x) => x.id === trackId) ?? list[0];
  const pointToPoint = !!track && config.pointToPoint.includes(track.category);
  const laps = pointToPoint ? 1 : (lapsInput ?? track?.lapsDefault ?? 1);
  const fixedClass = !!track && track.vehicleClass !== "any";
  const vehicleClass = track ? (fixedClass ? track.vehicleClass : (classInput ?? "any")) : "any";
  const allowed = !!state.crew?.canChallenge;
  const valid = allowed && crewId !== null && !!track && laps >= 1 && laps <= config.maxLaps && teamSize >= 1 && teamSize <= config.crewVs.maxTeamSize && stake >= 0 && stake <= config.crewVs.stakeMax;

  const submit = async () => {
    if (!valid || !track || crewId === null) return;
    setBusy(true);
    const input: ChallengeInput = { crewId, trackId: track.id, laps, vehicleClass, teamSize, stake };
    const res = await call("challengeCrew", input, t("p.challenge.sent"));
    setBusy(false);
    if (!res.ok) return;
    await reload();
    onClose();
    onCreated();
  };

  return (
    <Modal title={t("p.challenge.title")} onClose={onClose} wide>
      {!allowed && (
        <p className="mb-4 flex items-start gap-2 rounded-lg bg-warn/10 p-3 text-sm text-warn">
          <Info className="mt-0.5 size-4 shrink-0" /> {t("p.crews.cannotChallenge", { rank: config.crewVs.minRank })}
        </p>
      )}
      <Field label={t("p.challenge.rival")}>
        {(id) => <SearchInput id={id} value={search} placeholder={t("p.challenge.searchCrew")} onChange={(e) => setSearch(e.target.value)} />}
      </Field>
      <div className="mt-2 max-h-44 space-y-1.5 overflow-y-auto">
        <DataState loading={crews.loading} error={crews.error} hasData={crews.data !== null} empty={crews.data?.items.length === 0} emptyText={t("p.challenge.noCrews")} onRetry={crews.reload}>
          {crews.data?.items.map((c) => (
            <button
              key={c.id}
              type="button"
              aria-pressed={crewId === c.id}
              onClick={() => setCrewId(c.id)}
              className={`flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm transition-colors ${crewId === c.id ? "bg-accent/15 ring-1 ring-accent" : "bg-white/5 hover:bg-white/10"}`}
            >
              <CrewTag tag={c.tag} color={c.color} />
              <span className="min-w-0 flex-1 truncate font-semibold">{c.name}</span>
              <span className="tabular text-xs text-mute">
                {t("p.crews.level", { n: c.level })} · {num(c.points)} {t("p.crews.pts")} · {c.members} {t("p.crews.members")}
              </span>
            </button>
          ))}
        </DataState>
      </div>

      <div className="mt-4 grid gap-4 sm:grid-cols-2">
        <Field label={t("p.create.track")} hint={tracks.data?.length === 0 ? t("p.challenge.noTracks") : undefined} className="sm:col-span-2">
          {(id) => (
            <Select
              id={id}
              value={track?.id ?? ""}
              onChange={(e) => {
                setTrackId(Number(e.target.value));
                setLapsInput(null);
                setClassInput(null);
              }}
            >
              {list.map((x) => (
                <option key={x.id} value={x.id}>
                  {x.name} · {t(`cat.${x.category}`)}
                </option>
              ))}
            </Select>
          )}
        </Field>
        {!pointToPoint && (
          <Field label={t("laps")}>{(id) => <NumberInput id={id} value={laps} min={1} max={config.maxLaps} onChange={setLapsInput} />}</Field>
        )}
        <Field label={t("p.create.class")}>
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
        <Field label={t("p.challenge.teamSize")} hint={t("p.create.max", { max: config.crewVs.maxTeamSize })}>
          {(id) => <NumberInput id={id} value={teamSize} min={1} max={config.crewVs.maxTeamSize} onChange={setTeamSize} />}
        </Field>
        <Field label={t("p.challenge.stake")} hint={t("p.create.max", { max: money(config.crewVs.stakeMax) })}>
          {(id) => <NumberInput id={id} value={stake} min={0} max={config.crewVs.stakeMax} step={500} onChange={setStake} />}
        </Field>
      </div>

      <p className="mt-4 flex items-start gap-2 text-xs text-mute">
        <Info className="mt-0.5 size-3.5 shrink-0" /> {t(`p.formula.${config.crewVs.formula}`)}
      </p>
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          {t("cancel")}
        </Button>
        <Button loading={busy} disabled={!valid} onClick={submit}>
          <Swords className="size-4" /> {t("p.challenge.submit")}
        </Button>
      </div>
    </Modal>
  );
}
