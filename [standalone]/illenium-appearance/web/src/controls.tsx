import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react';
import type { Range, Rgb } from './types';

const SLIDE_DELAY = 120;

const percent = (value: number, min: number, max: number) => (max > min ? ((value - min) / (max - min)) * 100 : 0);

function ControlHead({ title, value, stored, onRestore }: { title: string; value: string; stored?: boolean; onRestore?: () => void }) {
  return (
    <div className="control-head">
      <span className="control-title">{title}</span>
      {stored === false && onRestore && (
        <button type="button" className="restore" aria-label={`Volver al valor original de ${title}`} title="Volver al valor original" onClick={onRestore}>
          <i className="fa-solid fa-rotate-left" />
        </button>
      )}
      <span className="control-value">{value}</span>
    </div>
  );
}

interface StepperProps {
  title: string;
  range: Range;
  value: number;
  stored?: number;
  blacklist?: number[];
  onChange: (value: number) => void;
}

// Elige una opción de una lista numerada, saltándose las bloqueadas en shared/blacklist.lua
export function Stepper({ title, range, value, stored, blacklist = [], onChange }: StepperProps) {
  const { min, max } = range;
  const [text, setText] = useState<string | null>(null);
  const [sliding, setSliding] = useState<number | null>(null);
  const latest = useRef(onChange);
  const timer = useRef<number | undefined>(undefined);
  const pending = useRef<number | null>(null);
  latest.current = onChange;

  useEffect(() => () => window.clearTimeout(timer.current), []);

  const fixed = max <= min;
  const shown = sliding ?? value;

  const wrap = (next: number) => (next < min ? max : next > max ? min : next);

  const step = (from: number, direction: number) => {
    let next = from;
    for (let tries = max - min + 1; tries >= 0; tries -= 1) {
      next = wrap(next + direction);
      if (!blacklist.includes(next)) return next;
    }
    return from;
  };

  // Una opción bloqueada salta a la siguiente libre en el sentido del cambio
  const allowed = (target: number) => {
    const next = Math.max(min, Math.min(max, target));
    return blacklist.includes(next) ? step(next, next > value ? 1 : -1) : next;
  };

  // Mover la barra no puede cambiar la ropa en cada píxel: cada cambio es una llamada al juego
  const flush = () => {
    window.clearTimeout(timer.current);
    timer.current = undefined;
    if (pending.current !== null) {
      latest.current(pending.current);
      pending.current = null;
    }
  };

  const slide = (target: number) => {
    const next = allowed(target);
    setSliding(next);
    pending.current = next;
    if (timer.current === undefined) {
      timer.current = window.setTimeout(flush, SLIDE_DELAY);
    }
  };

  const endSlide = () => {
    flush();
    setSliding(null);
  };

  const commitText = () => {
    if (text !== null) {
      const typed = parseInt(text, 10);
      if (!Number.isNaN(typed) && allowed(typed) !== value) onChange(allowed(typed));
    }
    setText(null);
  };

  return (
    <div className="control">
      <ControlHead title={title} value={fixed ? 'Sin opciones' : `${shown} / ${max}`} stored={stored === undefined || stored === value} onRestore={stored === undefined ? undefined : () => onChange(stored)} />
      <div className="stepper">
        <button type="button" className="arrow" disabled={fixed} aria-label={`Anterior: ${title}`} onClick={() => onChange(step(value, -1))}>
          <i className="fa-solid fa-chevron-left" />
        </button>
        <input
          type="range"
          className="range"
          aria-label={title}
          min={min}
          max={fixed ? min + 1 : max}
          step={1}
          value={shown}
          disabled={fixed}
          style={{ '--fill': `${percent(shown, min, max)}%` } as CSSProperties}
          onChange={(event) => slide(Number(event.target.value))}
          onPointerUp={endSlide}
          onKeyUp={endSlide}
          onBlur={endSlide}
        />
        <button type="button" className="arrow" disabled={fixed} aria-label={`Siguiente: ${title}`} onClick={() => onChange(step(value, 1))}>
          <i className="fa-solid fa-chevron-right" />
        </button>
        <input
          className="number"
          inputMode="numeric"
          aria-label={`Número de ${title}`}
          disabled={fixed}
          value={text ?? String(shown)}
          onFocus={(event) => event.target.select()}
          onChange={(event) => setText(event.target.value.replace(/[^\d-]/g, ''))}
          onBlur={commitText}
          onKeyDown={(event) => {
            if (event.key === 'Enter') event.currentTarget.blur();
          }}
        />
      </div>
    </div>
  );
}

interface SliderProps {
  title: string;
  range: Range;
  value: number;
  stored?: number;
  onChange: (value: number) => void;
}

export function Slider({ title, range, value, stored, onChange }: SliderProps) {
  const { min, max, factor = 1 } = range;
  return (
    <div className="control">
      <ControlHead title={title} value={value.toFixed(1)} stored={stored === undefined || stored === value} onRestore={stored === undefined ? undefined : () => onChange(stored)} />
      <input
        type="range"
        className="range range-full"
        aria-label={title}
        min={min}
        max={max}
        step={factor}
        value={value}
        style={{ '--fill': `${percent(value, min, max)}%` } as CSSProperties}
        onChange={(event) => onChange(parseFloat(event.target.value))}
      />
    </div>
  );
}

interface SwatchesProps {
  title: string;
  colors?: Rgb[];
  value: number;
  stored?: number;
  onChange: (value: number) => void;
}

export function Swatches({ title, colors = [], value, stored, onChange }: SwatchesProps) {
  return (
    <div className="control">
      <ControlHead title={title} value={String(value)} stored={stored === undefined || stored === value} onRestore={stored === undefined ? undefined : () => onChange(stored)} />
      <div className="swatches">
        {colors.map((color, index) => (
          <button
            type="button"
            key={index}
            className={`swatch ${value === index ? 'swatch-active' : ''}`}
            aria-label={`${title} ${index}`}
            aria-pressed={value === index}
            style={{ backgroundColor: `rgb(${color[0]}, ${color[1]}, ${color[2]})` }}
            onClick={() => onChange(index)}
          />
        ))}
      </div>
    </div>
  );
}

export function Group({ title, open, onToggle, children }: { title: string; open: boolean; onToggle: () => void; children: ReactNode }) {
  return (
    <section className={`group ${open ? 'group-open' : ''}`}>
      <button type="button" className="group-head" aria-expanded={open} onClick={onToggle}>
        <span>{title}</span>
        <i className="fa-solid fa-chevron-down" />
      </button>
      {open && <div className="group-body">{children}</div>}
    </section>
  );
}

// Lista de grupos en la que solo hay uno abierto a la vez: la de ropa tiene once
export function Groups({ items }: { items: { key: string; title: string; content: ReactNode }[] }) {
  const [open, setOpen] = useState<string | null>(items[0]?.key ?? null);
  return (
    <>
      {items.map((item) => (
        <Group key={item.key} title={item.title} open={open === item.key} onToggle={() => setOpen(open === item.key ? null : item.key)}>
          {item.content}
        </Group>
      ))}
    </>
  );
}
