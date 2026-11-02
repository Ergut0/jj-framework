import { Flag } from "lucide-react";
import { useT } from "@/lib/i18n";
import type { HudStandings, HudStandingRow } from "@/lib/types";
import { Panel, TagChip } from "./hudUi";

const ROW_STEP = 2.15; // em

interface Line {
  key: string;
  row: HudStandingRow;
  index: number;
  rank: number;
  you: boolean;
}

function Row({ line }: { line: Line }) {
  const t = useT();
  const { row, you } = line;
  const dim = row.out ? "opacity-45" : "";
  return (
    <div
      className={`absolute inset-x-0 top-0 flex h-[1.95em] items-center gap-[0.55em] px-[0.7em] transition-transform duration-500 ease-out ${you ? "bg-accent/25 shadow-[inset_0.25em_0_0_var(--accent)]" : "bg-white/5"} ${dim}`}
      style={{ transform: `translateY(${line.index * ROW_STEP}em)` }}
    >
      <span className="w-[1.5em] shrink-0 text-center font-mono font-bold text-mute tabular">{line.rank}</span>
      <TagChip tag={row.tag} color={row.color} />
      <span className={`min-w-0 flex-1 truncate font-semibold ${row.out ? "line-through" : ""} ${you ? "text-ink" : "text-ink/90"}`}>
        {you ? `${row.name} (${t("h.you")})` : row.name}
      </span>
      {row.finished ? (
        <Flag className="size-[1.1em] shrink-0 text-ok" />
      ) : (
        <span className="w-[1.8em] shrink-0 text-right font-mono text-[0.85em] text-mute tabular">L{row.lap}</span>
      )}
    </div>
  );
}

export function Standings({ standings, you }: { standings: HudStandings | null; you: number }) {
  const t = useT();
  if (!standings || standings.rows.length === 0) return null;

  const lines: Line[] = standings.rows.map((row, i) => ({ key: String(row.pid), row, index: i, rank: i + 1, you: row.pid === you }));
  // Si no estamos entre las filas visibles se añade una fila propia con nuestra posición real
  if (!standings.rows.some((r) => r.pid === you) && standings.pos > standings.rows.length) {
    lines.push({
      key: `you-${you}`,
      row: { pid: you, name: t("h.you"), lap: 1 },
      index: lines.length,
      rank: standings.pos,
      you: true,
    });
  }

  return (
    <Panel className="animate-rise w-[19em] p-[0.5em]" style={{ animationDelay: "120ms" }}>
      <div className="mb-[0.4em] px-[0.3em] text-[0.8em] font-semibold uppercase tracking-[0.2em] text-mute">{t("h.standings")}</div>
      <div className="relative text-[0.95em]" style={{ height: `${lines.length * ROW_STEP - (ROW_STEP - 1.95)}em` }}>
        {lines.map((l) => (
          <Row key={l.key} line={l} />
        ))}
      </div>
    </Panel>
  );
}
