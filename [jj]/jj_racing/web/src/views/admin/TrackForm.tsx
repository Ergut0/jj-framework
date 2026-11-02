import { Field, Input, Select, Textarea, Toggle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import type { TrackDraft } from "@/lib/types";
import { DecimalInput } from "./fields";
import { DESC_MAX, NAME_MAX, TIME_LIMIT_MAX, isPointToPoint } from "./draft";

export function TrackForm({ draft, onChange }: { draft: TrackDraft; onChange: (patch: Partial<TrackDraft>) => void }) {
  const t = useT();
  const { config } = useApp();
  const p2p = isPointToPoint(config, draft.category);

  return (
    <div className="grid gap-4 sm:grid-cols-2">
      <Field label={t("a.form.name")} className="sm:col-span-2">
        {(id) => <Input id={id} value={draft.name} maxLength={NAME_MAX} onChange={(e) => onChange({ name: e.target.value })} placeholder={t("a.form.namePh")} />}
      </Field>
      <Field label={t("a.f.category")}>
        {(id) => (
          <Select id={id} value={draft.category} onChange={(e) => onChange({ category: e.target.value, ...(isPointToPoint(config, e.target.value) ? { lapsDefault: 1 } : {}) })}>
            {config.categories.map((c) => (
              <option key={c} value={c}>{t(`cat.${c}`)}</option>
            ))}
          </Select>
        )}
      </Field>
      <Field label={t("a.f.difficulty")}>
        {(id) => (
          <Select id={id} value={draft.difficulty} onChange={(e) => onChange({ difficulty: e.target.value })}>
            {config.difficulties.map((d) => (
              <option key={d} value={d}>{t(`diff.${d}`)}</option>
            ))}
          </Select>
        )}
      </Field>
      <Field label={t("a.form.description")} hint={`${draft.description.length}/${DESC_MAX}`} className="sm:col-span-2">
        {(id) => <Textarea id={id} rows={2} maxLength={DESC_MAX} value={draft.description} onChange={(e) => onChange({ description: e.target.value })} />}
      </Field>
      <Field label={t("a.form.laps")} hint={p2p ? t("a.form.lapsP2p") : t("a.form.lapsHint", { max: config.maxLaps })}>
        {(id) => <DecimalInput id={id} integer min={1} max={config.maxLaps} value={p2p ? 1 : draft.lapsDefault} disabled={p2p} onChange={(v) => onChange({ lapsDefault: v })} />}
      </Field>
      <Field label={t("a.form.class")}>
        {(id) => (
          <Select id={id} value={draft.vehicleClass} onChange={(e) => onChange({ vehicleClass: e.target.value })}>
            {config.allVehicleClasses.map((c) => (
              <option key={c} value={c}>{t(`class.${c}`)}</option>
            ))}
          </Select>
        )}
      </Field>
      <Field label={t("a.form.prize")} hint={t("a.form.prizeHint", { max: config.baseMaxPrize.toLocaleString("es-ES") })}>
        {(id) => <DecimalInput id={id} integer min={0} max={config.baseMaxPrize} value={draft.basePrize} onChange={(v) => onChange({ basePrize: v })} />}
      </Field>
      <Field label={t("a.form.timeLimit")} hint={t("a.form.timeLimitHint")}>
        {(id) => <DecimalInput id={id} integer min={0} max={TIME_LIMIT_MAX} value={draft.timeLimit} onChange={(v) => onChange({ timeLimit: v })} />}
      </Field>
      <Toggle checked={draft.allowCrews} onChange={(v) => onChange({ allowCrews: v })} label={t("a.form.allowCrews")} />
      <Toggle checked={draft.collisions} onChange={(v) => onChange({ collisions: v })} label={t("a.form.collisions")} />
    </div>
  );
}
