import { Plus, X } from "lucide-react";
import { Button, Card, Field, SectionTitle } from "@/components/ui";
import { useT } from "@/lib/i18n";
import { cn } from "@/lib/utils";
import type { ReactNode } from "react";
import { DecimalInput } from "./fields";
import { INT_BOUNDS, LIST_BOUNDS } from "./settingsSchema";

type IntKey = keyof typeof INT_BOUNDS;
type ListKey = keyof typeof LIST_BOUNDS;

export function Group({ title, hint, children }: { title: string; hint?: string; children: ReactNode }) {
  return (
    <Card>
      <SectionTitle>{title}</SectionTitle>
      {hint && <p className="-mt-2 mb-4 text-xs text-mute">{hint}</p>}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">{children}</div>
    </Card>
  );
}

export function IntField({ name, value, onChange, invalid }: { name: IntKey; value: number; onChange: (v: number) => void; invalid: boolean }) {
  const t = useT();
  const b = INT_BOUNDS[name];
  return (
    <Field label={t(`a.set.${name}`)} hint={`${b.min.toLocaleString("es-ES")} – ${b.max.toLocaleString("es-ES")}`}>
      {(id) => <DecimalInput id={id} integer min={b.min} max={b.max} value={value} onChange={onChange} className={cn(invalid && "border-bad")} />}
    </Field>
  );
}

/** Lista editable de enteros (fichas con anadir / quitar) */
export function ChipList({ name, values, onChange }: { name: ListKey; values: number[]; onChange: (v: number[]) => void }) {
  const t = useT();
  const b = LIST_BOUNDS[name];
  const sum = values.reduce((a, n) => a + n, 0);
  const over = b.sumMax != null && sum > b.sumMax;
  return (
    <div className="sm:col-span-2 lg:col-span-3">
      <div className="mb-2 flex flex-wrap items-center justify-between gap-2">
        <span className="text-xs font-semibold tracking-wide text-mute uppercase">{t(`a.set.${name}`)}</span>
        <span className={cn("tabular text-xs", over ? "text-bad" : "text-mute")}>
          {b.sumMax != null ? t("a.set.total", { sum, max: b.sumMax }) : t("a.set.items", { n: values.length, max: b.maxItems })} · {b.min}–{b.max.toLocaleString("es-ES")}
        </span>
      </div>
      <div className="flex flex-wrap items-center gap-2">
        {values.map((v, i) => (
          <div key={i} className="flex items-center gap-1 rounded-lg border border-line bg-panel2/70 py-1 pr-1 pl-2">
            <span className="racing-title text-xs text-mute">{i + 1}º</span>
            <DecimalInput aria-label={`${t(`a.set.${name}`)} ${i + 1}`} integer min={b.min} max={b.max} value={v} onChange={(n) => onChange(values.map((x, k) => (k === i ? n : x)))} className="h-8 w-20 px-2 py-1" />
            <button type="button" aria-label={t("delete")} onClick={() => onChange(values.filter((_, k) => k !== i))} className="rounded p-1 text-mute hover:bg-bad/15 hover:text-bad">
              <X className="size-3.5" />
            </button>
          </div>
        ))}
        <Button variant="outline" size="sm" disabled={values.length >= b.maxItems} onClick={() => onChange([...values, values.length ? values[values.length - 1]! : 0])}>
          <Plus className="size-4" /> {t("add")}
        </Button>
      </div>
      {over && <p className="mt-2 text-xs text-bad">{t("a.set.sumOver", { max: b.sumMax ?? 0 })}</p>}
    </div>
  );
}
