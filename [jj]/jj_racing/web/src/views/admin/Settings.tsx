import { useEffect, useMemo, useState } from "react";
import { RotateCcw, Save } from "lucide-react";
import { Button, DataState, Field, SectionTitle, Select, Toggle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { fetchNui } from "@/lib/nui";
import { useAsync } from "@/lib/hooks";
import { cn } from "@/lib/utils";
import type { RaceSettings } from "@/lib/types";
import { ChipList, Group, IntField } from "./SettingsParts";
import { FORMULAS, invalidSettings } from "./settingsSchema";

interface SettingsPayload {
  settings: RaceSettings;
  allClasses: string[];
}

export function Settings() {
  const t = useT();
  const { call, reload } = useApp();
  const load = useAsync(() => fetchNui<SettingsPayload>("adminGetSettings"), []);
  const [base, setBase] = useState<RaceSettings | null>(null);
  const [form, setForm] = useState<RaceSettings | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!load.data) return;
    setBase(load.data.settings);
    setForm(structuredClone(load.data.settings));
  }, [load.data]);

  const invalid = useMemo(() => new Set(form ? invalidSettings(form) : []), [form]);
  const dirty = !!form && !!base && JSON.stringify(form) !== JSON.stringify(base);

  const set = <K extends keyof RaceSettings>(key: K, value: RaceSettings[K]) => setForm((f) => (f ? { ...f, [key]: value } : f));
  const int = (key: Parameters<typeof IntField>[0]["name"]) => <IntField name={key} value={form![key]} invalid={invalid.has(key)} onChange={(v) => set(key, v)} />;

  const save = async () => {
    if (!form) return;
    setBusy(true);
    const res = await call<{ settings: RaceSettings }>("adminSaveSettings", { settings: form }, t("a.set.saved"));
    setBusy(false);
    if (!res.ok) return;
    // Se muestran los valores que devuelve el servidor (ya validados)
    setBase(res.data.settings);
    setForm(structuredClone(res.data.settings));
    void reload();
  };

  const toggleClass = (c: string) => {
    if (!form) return;
    const has = form.allowedClasses.includes(c);
    set("allowedClasses", has ? form.allowedClasses.filter((x) => x !== c) : [...form.allowedClasses, c]);
  };

  return (
    <div>
      <SectionTitle
        action={
          <div className="flex items-center gap-2">
            {dirty && <span className="text-xs text-warn">{t("a.set.dirty")}</span>}
            <Button variant="ghost" size="sm" disabled={!dirty || busy} onClick={() => base && setForm(structuredClone(base))}>
              <RotateCcw className="size-4" /> {t("reset")}
            </Button>
            <Button size="sm" loading={busy} disabled={!dirty || invalid.size > 0} onClick={() => void save()}>
              <Save className="size-4" /> {t("save")}
            </Button>
          </div>
        }
      >
        {t("a.nav.settings")}
      </SectionTitle>
      <p className="mb-4 text-xs text-mute">{t("a.set.live")}</p>

      <DataState loading={load.loading} error={load.error} hasData={!!form} onRetry={load.reload}>
        {form && load.data && (
          <div className="flex flex-col gap-4">
            <Group title={t("a.set.g.general")}>
              {int("maxPlayers")}
              {int("minPlayersToStart")}
              {int("minPlayersForRewards")}
              {int("maxLaps")}
              {int("countdownSeconds")}
              {int("finishGraceSeconds")}
              {int("openLobbyMinutes")}
              <div className="flex items-end pb-2">
                <Toggle checked={form.useRoutingBuckets} onChange={(v) => set("useRoutingBuckets", v)} label={t("a.set.useRoutingBuckets")} />
              </div>
              <p className="text-xs text-mute sm:col-span-2 lg:col-span-3">{t("a.set.useRoutingBucketsHint")}</p>
            </Group>

            <Group title={t("a.set.g.prizes")}>
              {int("entryFeeMax")}
              {int("extraPrizeMax")}
              {int("baseMaxPrize")}
              {int("commissionPct")}
              <ChipList name="prizeSplit" values={form.prizeSplit} onChange={(v) => set("prizeSplit", v)} />
            </Group>

            <Group title={t("a.set.g.pilot")} hint={t("a.set.g.pilotHint")}>
              <ChipList name="pilotPoints" values={form.pilotPoints} onChange={(v) => set("pilotPoints", v)} />
            </Group>

            <Group title={t("a.set.g.crew")} hint={t("a.set.g.crewHint")}>
              <ChipList name="crewPointsByPosition" values={form.crewPointsByPosition} onChange={(v) => set("crewPointsByPosition", v)} />
              {int("crewFinishPoints")}
              {int("crewMaxPointsPerRace")}
              {int("crewPrizeSharePct")}
              <div className="flex items-end pb-2">
                <Toggle checked={form.crewRequireOutsider} onChange={(v) => set("crewRequireOutsider", v)} label={t("a.set.crewRequireOutsider")} />
              </div>
              <Field label={t("a.set.crewVsFormula")} hint={t(`a.set.formula.${form.crewVsFormula}.hint`)}>
                {(id) => (
                  <Select id={id} value={form.crewVsFormula} onChange={(e) => set("crewVsFormula", e.target.value as RaceSettings["crewVsFormula"])}>
                    {FORMULAS.map((f) => (
                      <option key={f} value={f}>{t(`a.set.formula.${f}`)}</option>
                    ))}
                  </Select>
                )}
              </Field>
              {int("crewVsWinPoints")}
              {int("crewVsStakeMax")}
              {int("crewVsMinRank")}
            </Group>

            <Group title={t("a.set.g.classes")} hint={t("a.set.g.classesHint")}>
              <div className="flex flex-wrap gap-2 sm:col-span-2 lg:col-span-3" role="group" aria-label={t("a.set.g.classes")}>
                {load.data.allClasses.map((c) => {
                  const on = form.allowedClasses.includes(c);
                  return (
                    <label key={c} className={cn("flex cursor-pointer items-center gap-2 rounded-lg border px-3 py-1.5 text-sm transition-colors", on ? "border-accent bg-accent/10" : "border-line text-mute hover:text-ink")}>
                      <input type="checkbox" checked={on} onChange={() => toggleClass(c)} className="accent-(--accent)" />
                      {t(`class.${c}`)}
                    </label>
                  );
                })}
              </div>
              {invalid.has("allowedClasses") && <p className="text-xs text-bad sm:col-span-2 lg:col-span-3">{t("a.set.classesEmpty")}</p>}
            </Group>
          </div>
        )}
      </DataState>
    </div>
  );
}
