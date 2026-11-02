import { Plus, Trash2 } from "lucide-react";
import { Button, Field } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import type { DraftGrid } from "@/lib/types";
import { DecimalInput, IconButton, PasteCoords } from "./fields";
import { COORD_MAX, Z_MAX, Z_MIN } from "./draft";

export function GridEditor({ grid, onChange }: { grid: DraftGrid[]; onChange: (g: DraftGrid[]) => void }) {
  const t = useT();
  const { config } = useApp();
  const max = config.creator.maxGrid;
  const full = grid.length >= max;
  const patch = (i: number, p: Partial<DraftGrid>) => onChange(grid.map((g, n) => (n === i ? { ...g, ...p } : g)));
  const blank = (): DraftGrid => {
    const last = grid[grid.length - 1];
    return last ? { ...last, x: Math.round((last.x - 7) * 100) / 100 } : { x: 0, y: 0, z: 30, h: 0 };
  };

  return (
    <div>
      <div className="mb-3 flex flex-wrap items-center justify-between gap-2 text-xs text-mute">
        <span>{t("a.grid.count", { n: grid.length, max })}</span>
        <Button variant="outline" size="sm" disabled={full} onClick={() => onChange([...grid, blank()])}>
          <Plus className="size-4" /> {t("a.grid.add")}
        </Button>
      </div>
      {grid.length === 0 && <p className="rounded-lg border border-dashed border-line px-4 py-6 text-center text-sm text-mute">{t("a.grid.empty")}</p>}
      <ol className="flex flex-col gap-1.5">
        {grid.map((g, i) => (
          <li key={i} className="flex items-end gap-2 rounded-lg border border-line bg-panel2/60 p-2">
            <span className="racing-title tabular mb-2 w-7 shrink-0 text-center text-sm text-mute">{i + 1}</span>
            <div className="grid min-w-0 flex-1 grid-cols-2 gap-2 sm:grid-cols-4">
              <Field label="X">{(id) => <DecimalInput id={id} min={-COORD_MAX} max={COORD_MAX} value={g.x} onChange={(v) => patch(i, { x: v })} />}</Field>
              <Field label="Y">{(id) => <DecimalInput id={id} min={-COORD_MAX} max={COORD_MAX} value={g.y} onChange={(v) => patch(i, { y: v })} />}</Field>
              <Field label="Z">{(id) => <DecimalInput id={id} min={Z_MIN} max={Z_MAX} value={g.z} onChange={(v) => patch(i, { z: v })} />}</Field>
              <Field label={t("a.grid.heading")}>{(id) => <DecimalInput id={id} min={-360} max={720} value={g.h} onChange={(v) => patch(i, { h: v })} />}</Field>
            </div>
            <IconButton danger label={t("delete")} disabled={grid.length <= 1} onClick={() => onChange(grid.filter((_, n) => n !== i))}>
              <Trash2 className="size-4" />
            </IconButton>
          </li>
        ))}
      </ol>
      {!full && (
        <div className="mt-3">
          <PasteCoords min={3} placeholder={t("a.paste.grid")} onAdd={([x, y, z, h]) => onChange([...grid, { x: x!, y: y!, z: z!, h: h ?? 0 }])} />
        </div>
      )}
    </div>
  );
}
