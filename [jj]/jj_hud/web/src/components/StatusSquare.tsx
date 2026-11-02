import { useId } from 'react';
import type { ReactNode } from 'react';

// Medidas del diseño original: un cuadrado redondeado que se llena de abajo arriba
const BOX = 626;
const RADIUS = 80;
const STROKE = 40;
const INSET = STROKE / 2 + 24;
const INNER = BOX - INSET * 2;
const VIEW = BOX + STROKE;

interface Props {
  value: number;
  color: string;
  stroke: string;
  size?: number;
  children: ReactNode;
}

export function StatusSquare({ value, color, stroke, size = 40, children }: Props) {
  const clipId = `fill-${useId().replace(/:/g, '')}`;
  const level = Math.max(0, Math.min(100, value));
  const fill = (level / 100) * INNER;

  return (
    <svg className="square" viewBox={`${-STROKE / 2} ${-STROKE / 2} ${VIEW} ${VIEW}`} width={size} height={size}>
      <defs>
        <clipPath id={clipId}>
          <rect x={INSET} y={INSET} width={INNER} height={INNER} rx={RADIUS - INSET} ry={RADIUS - INSET} />
        </clipPath>
      </defs>
      <rect x={0} y={0} width={BOX} height={BOX} rx={RADIUS} ry={RADIUS} fill="none" stroke={stroke} strokeWidth={STROKE} />
      <g clipPath={`url(#${clipId})`}>
        <rect x={INSET} y={INSET} width={INNER} height={INNER} fill={color} opacity={0.2} />
        <rect className="square-level" x={INSET} y={BOX - INSET - fill} width={INNER} height={fill + 1} fill={color} />
      </g>
      <foreignObject x={0} y={0} width={BOX} height={BOX} className="square-icon">
        <div style={{ transform: `scale(${BOX / size})` }}>{children}</div>
      </foreignObject>
    </svg>
  );
}
