import { ArrowDown, ArrowUp, Plus, Trash2 } from "lucide-react";
import { Badge, Button, Field, Select } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { cn } from "@/lib/utils";
import type { CheckpointKind, DraftCheckpoint } from "@/lib/types";
import { DecimalInput, IconButton, PasteCoords } from "./fields";
import { COORD_MAX, Z_MAX, Z_MIN, newCheckpoint, normalCount, sequences } from "./draft";

const KINDS: CheckpointKind[] = ["normal", "shortcut", "pit"];
const KIND_COLOR: Record<CheckpointKind, string> = { normal: "#a855f7", shortcut: "#fbbf24", pit: "#3cc8ff" };

interface Props {
  checkpoints: DraftCheckpoint[];
  onChange: (cps: DraftCheckpoint[]) => void;
  selected: number | null;
  onSelect: (i: number | null) => void;
}

export function CheckpointEditor({ checkpoints, onChange, selected, onSelect }: Props) {
  const t = useT();
  const { config } = useApp();
  const cr = config.creator;
  const seqs = sequences(checkpoints);
  const normals = normalCount(checkpoints);
  const full = checkpoints.length >= cr.maxCheckpoints;

  const patch = (i: number, p: Partial<DraftCheckpoint>) => onChange(checkpoints.map((c, n) => (n === i ? { ...c, ...p } : c)));

  const changeKind = (i: number, kind: CheckpointKind) =>
    onChange(
      checkpoints.map((c, n) => {
        if (n !== i) return c;
        const base: DraftCheckpoint = { kind, x: c.x, y: c.y, z: c.z, radius: c.radius, height: c.height };
        return kind === "shortcut" ? { ...base, linkFrom: 1, linkTo: 3 } : base;
      }),
    );

  const move = (i: number, dir: -1 | 1) => {
    const j = i + dir;
    if (j < 0 || j >= checkpoints.length) return;
    const next = [...checkpoints];
    [next[i], next[j]] = [next[j]!, next[i]!];
    onChange(next);
    onSelect(j);
  };

  const remove = (i: number) => {
    onChange(checkpoints.filter((_, n) => n !== i));
    onSelect(null);
  };

  const add = (cp: DraftCheckpoint) => {
    onChange([...checkpoints, cp]);
    onSelect(checkpoints.length);
  };

  return (
    <div>
      <div className="mb-3 flex flex-wrap items-center justify-between gap-2 text-xs text-mute">
        <span>{t("a.cp.count", { n: checkpoints.length, normals, max: cr.maxCheckpoints })}</span>
        <Button variant="outline" size="sm" disabled={full} onClick={() => add(newCheckpoint(config, checkpoints[checkpoints.length - 1]))}>
          <Plus className="size-4" /> {t("a.cp.add")}
        </Button>
      </div>

      {checkpoints.length === 0 && <p className="rounded-lg border border-dashed border-line px-4 py-6 text-center text-sm text-mute">{t("a.cp.empty")}</p>}

      <ol className="flex flex-col gap-1.5">
        {checkpoints.map((c, i) => {
          const open = selected === i;
          const seq = seqs[i];
          return (
            <li key={i} className={cn("rounded-lg border bg-panel2/60 transition-colors", open ? "border-accent" : "border-line")}>
              <div className="flex items-center gap-2 px-2 py-1.5">
                <button type="button" onClick={() => onSelect(open ? null : i)} aria-expanded={open} className="flex min-w-0 flex-1 items-center gap-2 text-left">
                  <span className="tabular w-6 shrink-0 text-center text-xs text-mute">{i + 1}</span>
                  <Badge color={KIND_COLOR[c.kind]}>
                    {t(`kind.${c.kind}`)}
                    {seq != null && ` ${seq}`}
                    {c.kind === "shortcut" && ` ${c.linkFrom ?? "?"}→${c.linkTo ?? "?"}`}
                  </Badge>
                  <span className="tabular truncate font-mono text-xs text-mute">
                    {c.x.toFixed(1)}, {c.y.toFixed(1)}, {c.z.toFixed(1)} · r{c.radius}
                  </span>
                </button>
                <IconButton label={t("a.cp.up")} disabled={i === 0} onClick={() => move(i, -1)}><ArrowUp className="size-4" /></IconButton>
                <IconButton label={t("a.cp.down")} disabled={i === checkpoints.length - 1} onClick={() => move(i, 1)}><ArrowDown className="size-4" /></IconButton>
                <IconButton danger label={t("delete")} onClick={() => remove(i)}><Trash2 className="size-4" /></IconButton>
              </div>
              {open && (
                <div className="animate-fade grid grid-cols-2 gap-3 border-t border-line p-3 sm:grid-cols-3">
                  <Field label={t("a.cp.kind")}>
                    {(id) => (
                      <Select id={id} value={c.kind} onChange={(e) => changeKind(i, e.target.value as CheckpointKind)}>
                        {KINDS.map((k) => (
                          <option key={k} value={k}>{t(`kind.${k}`)}</option>
                        ))}
                      </Select>
                    )}
                  </Field>
                  <Field label="X">{(id) => <DecimalInput id={id} min={-COORD_MAX} max={COORD_MAX} value={c.x} onChange={(v) => patch(i, { x: v })} />}</Field>
                  <Field label="Y">{(id) => <DecimalInput id={id} min={-COORD_MAX} max={COORD_MAX} value={c.y} onChange={(v) => patch(i, { y: v })} />}</Field>
                  <Field label="Z">{(id) => <DecimalInput id={id} min={Z_MIN} max={Z_MAX} value={c.z} onChange={(v) => patch(i, { z: v })} />}</Field>
                  <Field label={t("a.cp.radius")} hint={`${cr.minRadius}–${cr.maxRadius}`}>
                    {(id) => <DecimalInput id={id} min={cr.minRadius} max={cr.maxRadius} value={c.radius} onChange={(v) => patch(i, { radius: v })} />}
                  </Field>
                  <Field label={t("a.cp.height")} hint={`${cr.minHeight}–${cr.maxHeight}`}>
                    {(id) => <DecimalInput id={id} min={cr.minHeight} max={cr.maxHeight} value={c.height} onChange={(v) => patch(i, { height: v })} />}
                  </Field>
                  {c.kind === "shortcut" && (
                    <>
                      <Field label={t("a.cp.linkFrom")} hint={t("a.cp.linkHint", { n: normals })}>
                        {(id) => <DecimalInput id={id} integer min={1} max={Math.max(1, normals - 2)} value={c.linkFrom ?? 1} onChange={(v) => patch(i, { linkFrom: v })} />}
                      </Field>
                      <Field label={t("a.cp.linkTo")} hint={t("a.cp.linkToHint")}>
                        {(id) => <DecimalInput id={id} integer min={(c.linkFrom ?? 1) + 2} max={Math.max(3, normals)} value={c.linkTo ?? 3} onChange={(v) => patch(i, { linkTo: v })} />}
                      </Field>
                    </>
                  )}
                </div>
              )}
            </li>
          );
        })}
      </ol>

      {!full && (
        <div className="mt-3">
          <PasteCoords min={3} placeholder={t("a.paste.cp")} onAdd={([x, y, z]) => add({ ...newCheckpoint(config), x: x!, y: y!, z: z! })} />
        </div>
      )}
    </div>
  );
}
