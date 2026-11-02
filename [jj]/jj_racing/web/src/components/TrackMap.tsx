import { useMemo } from "react";
import { cn } from "@/lib/utils";
import type { RoutePoint } from "@/lib/types";

const W = 400;
const H = 260;
const PAD = 22;

interface Props {
  route: RoutePoint[];
  grid?: { x: number; y: number; h?: number }[];
  /** unir meta con salida (circuitos y circulares) */
  closed?: boolean;
  className?: string;
  /** resalta un checkpoint (indice dentro de `route`) */
  highlight?: number;
  showLabels?: boolean;
}

/** Vista de ruta en SVG (norte arriba): checkpoints numerados, atajos, pits y parrilla */
export function TrackMap({ route, grid, closed, className, highlight, showLabels = true }: Props) {
  const geo = useMemo(() => {
    const pts = [...route, ...(grid ?? []).map((g) => ({ x: g.x, y: g.y }))];
    if (pts.length === 0) return null;
    const xs = pts.map((p) => p.x);
    const ys = pts.map((p) => p.y);
    const minX = Math.min(...xs), maxX = Math.max(...xs);
    const minY = Math.min(...ys), maxY = Math.max(...ys);
    const span = Math.max(maxX - minX, maxY - minY, 1);
    const scale = Math.min((W - PAD * 2) / span, (H - PAD * 2) / span);
    const offX = (W - (maxX - minX) * scale) / 2;
    const offY = (H - (maxY - minY) * scale) / 2;
    return {
      px: (x: number) => offX + (x - minX) * scale,
      // GTA: +Y es norte; en pantalla +Y baja
      py: (y: number) => H - (offY + (y - minY) * scale),
    };
  }, [route, grid]);

  if (!geo) return <div className={cn("rounded-lg border border-line bg-bg/60", className)} />;

  const normals = route.filter((p) => p.kind === "normal");
  const bySeq = new Map(normals.map((p) => [p.seq, p]));
  const line = normals.map((p) => `${geo.px(p.x)},${geo.py(p.y)}`).join(" ");
  const first = normals[0];
  const last = normals[normals.length - 1];

  return (
    <svg viewBox={`0 0 ${W} ${H}`} className={cn("w-full rounded-lg border border-line bg-bg/60", className)} role="img" aria-label="route">
      <defs>
        <pattern id="map-grid" width="20" height="20" patternUnits="userSpaceOnUse">
          <path d="M 20 0 L 0 0 0 20" fill="none" stroke="rgb(255 255 255 / 0.04)" strokeWidth="1" />
        </pattern>
      </defs>
      <rect width={W} height={H} fill="url(#map-grid)" />

      {closed && first && last && first !== last && (
        <line x1={geo.px(last.x)} y1={geo.py(last.y)} x2={geo.px(first.x)} y2={geo.py(first.y)} stroke="var(--accent)" strokeOpacity="0.35" strokeWidth="2" strokeDasharray="4 5" />
      )}
      <polyline points={line} fill="none" stroke="var(--accent)" strokeWidth="3" strokeLinejoin="round" strokeLinecap="round" />

      {route
        .filter((p) => p.kind === "shortcut")
        .map((p, i) => {
          const from = bySeq.get(p.linkFrom);
          const to = bySeq.get(p.linkTo);
          if (!from || !to) return null;
          return (
            <polyline
              key={`sc${i}`}
              points={`${geo.px(from.x)},${geo.py(from.y)} ${geo.px(p.x)},${geo.py(p.y)} ${geo.px(to.x)},${geo.py(to.y)}`}
              fill="none"
              stroke="#fbbf24"
              strokeWidth="2"
              strokeDasharray="5 4"
            />
          );
        })}

      {grid?.map((g, i) => (
        <rect key={`g${i}`} x={geo.px(g.x) - 3} y={geo.py(g.y) - 3} width="6" height="6" fill="#e5e7eb" opacity="0.8" transform={`rotate(${-(g.h ?? 0)} ${geo.px(g.x)} ${geo.py(g.y)})`} />
      ))}

      {route.map((p, i) => {
        if (p.kind === "normal") {
          const isFirst = p === first;
          const isLast = p === last;
          return (
            <g key={i}>
              <circle cx={geo.px(p.x)} cy={geo.py(p.y)} r={highlight === i ? 8 : isFirst || isLast ? 7 : 5} fill={isLast ? "#fff" : "#101016"} stroke={highlight === i ? "#22c55e" : "var(--accent)"} strokeWidth="2.5" />
              {showLabels && (
                <text x={geo.px(p.x)} y={geo.py(p.y) - 10} textAnchor="middle" fontSize="9" fill="#d4d4e0" fontWeight="700">
                  {p.seq}
                </text>
              )}
            </g>
          );
        }
        const colour = p.kind === "pit" ? "#3cc8ff" : "#fbbf24";
        return (
          <g key={i}>
            <rect x={geo.px(p.x) - 4} y={geo.py(p.y) - 4} width="8" height="8" fill={colour} transform={`rotate(45 ${geo.px(p.x)} ${geo.py(p.y)})`} stroke={highlight === i ? "#22c55e" : "none"} strokeWidth="2" />
            {showLabels && p.kind === "pit" && (
              <text x={geo.px(p.x)} y={geo.py(p.y) - 8} textAnchor="middle" fontSize="8" fill={colour} fontWeight="700">
                PIT
              </text>
            )}
          </g>
        );
      })}
    </svg>
  );
}
