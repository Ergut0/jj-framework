import type { CSSProperties, ReactNode } from "react";
import { useT } from "@/lib/i18n";
import { safeColor } from "@/lib/format";

/** Tamaño base del HUD: todo lo demás va en `em`, asi escala de 1280x720 a 4K */
export const HUD_ROOT_STYLE: CSSProperties = { fontSize: "clamp(11px, calc(0.55vw + 0.62vh), 44px)" };

export const HUD_ROOT_CLASS = "pointer-events-none fixed inset-0 select-none overflow-hidden font-display text-ink";

export const PANEL_CLASS = "border border-white/10 bg-bg/75 shadow-[0_0.35em_1.4em_rgb(0_0_0/0.5)]";

export function Panel({ className = "", children, style }: { className?: string; children: ReactNode; style?: CSSProperties }) {
  return (
    <div className={`${PANEL_CLASS} ${className}`} style={style}>
      {children}
    </div>
  );
}

/** Ordinal localizado: 1º / 1st, 2nd, 3rd, 4th... */
export function useOrdinal() {
  const t = useT();
  return (n: number): string => {
    const last = n % 10;
    const teen = n % 100 >= 11 && n % 100 <= 13;
    const key = !teen && last >= 1 && last <= 3 ? `h.ord.${last}` : "h.ord.n";
    return t(key, { n });
  };
}

export const MEDAL_COLOR: Record<number, string> = {
  1: "var(--color-gold)",
  2: "var(--color-silver)",
  3: "var(--color-bronze)",
};

export function TagChip({ tag, color }: { tag?: string; color?: string }) {
  if (!tag) return null;
  const c = safeColor(color);
  return (
    <span
      className="shrink-0 rounded-[0.2em] px-[0.45em] py-[0.1em] text-[0.78em] font-bold leading-none tracking-wider"
      style={{ color: c, backgroundColor: `${c}26`, boxShadow: `inset 0 0 0 1px ${c}66` }}
    >
      {tag}
    </span>
  );
}
