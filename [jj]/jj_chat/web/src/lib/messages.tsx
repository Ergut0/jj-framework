import type { ReactNode } from 'react';
import type { Channel, ChatMessage, RawMessage } from '../types';

const CHANNELS: Channel[] = ['local', 'ooc', 'pm', 'job', 'staff', 'system'];

const COLORS: Record<string, string> = {
  '1': '#f87171',
  '2': '#4ade80',
  '3': '#facc15',
  '4': '#60a5fa',
  '5': '#22d3ee',
  '6': '#c084fc',
  '8': '#dc2626',
  '9': '#f472b6',
};

let nextKey = 1;

// Los mensajes de otros recursos pueden traer una plantilla con HTML: se muestra solo su texto
function fromTemplate(template: string, args: string[]) {
  return template
    .replace(/\{(\d+)\}/g, (_, index) => args[Number(index)] ?? '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function normalizeMessage(raw: RawMessage): ChatMessage | null {
  const args = (raw.args ?? []).map((value) => String(value ?? ''));
  let { author, text } = raw;

  if (raw.template) {
    text = fromTemplate(raw.template, args);
  } else if (text === undefined) {
    if (args.length > 1 && author === undefined) {
      author = args[0];
      text = args.slice(1).join(' ');
    } else {
      text = args.join(' ');
    }
  }
  if (!text && !author) return null;

  return {
    key: nextKey++,
    time: Date.now(),
    channel: CHANNELS.includes(raw.channel as Channel) ? (raw.channel as Channel) : 'system',
    tag: raw.tag,
    author,
    detail: raw.detail,
    id: raw.id,
    text: text ?? '',
    color: raw.color?.length === 3 ? `rgb(${raw.color[0]}, ${raw.color[1]}, ${raw.color[2]})` : undefined,
  };
}

// Convierte los códigos de color de FiveM (^1, ^2...) en texto de color
export function renderColored(text: string): ReactNode[] {
  const parts = text.split(/\^([0-9*_~=r])/);
  const nodes: ReactNode[] = [];
  let color: string | undefined;

  parts.forEach((part, index) => {
    if (index % 2 === 1) {
      if (/\d/.test(part)) color = COLORS[part];
      else if (part === 'r') color = undefined;
    } else if (part) {
      nodes.push(color ? <span key={index} style={{ color }}>{part}</span> : part);
    }
  });
  return nodes;
}

export const formatTime = (time: number) =>
  new Date(time).toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
