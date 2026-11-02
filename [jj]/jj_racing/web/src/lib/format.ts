/** m:ss.mmm (o --:--.--- si no hay dato) */
export function formatTime(ms?: number | null): string {
  if (ms == null || !Number.isFinite(ms) || ms <= 0) return "--:--.---";
  const total = Math.round(ms);
  const m = Math.floor(total / 60000);
  const s = Math.floor((total % 60000) / 1000);
  const r = total % 1000;
  return `${m}:${String(s).padStart(2, "0")}.${String(r).padStart(3, "0")}`;
}

/** Diferencia con el lider: +1.234 o +1:02.345 */
export function formatGap(ms?: number | null): string {
  if (ms == null || !Number.isFinite(ms)) return "--";
  if (ms <= 0) return "LEADER";
  const total = Math.round(ms);
  if (total < 60000) return `+${(total / 1000).toFixed(3)}`;
  const m = Math.floor(total / 60000);
  const s = ((total % 60000) / 1000).toFixed(3).padStart(6, "0");
  return `+${m}:${s}`;
}

export function money(n: number, currency = "$"): string {
  return `${currency}${Math.round(n).toLocaleString("es-ES")}`;
}

export function num(n: number): string {
  return Math.round(n).toLocaleString("es-ES");
}

export function dateTime(ts: number, locale = "es"): string {
  return new Date(ts * 1000).toLocaleString(locale === "es" ? "es-ES" : "en-GB", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function date(ts: number, locale = "es"): string {
  return new Date(ts * 1000).toLocaleDateString(locale === "es" ? "es-ES" : "en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

/** km / m con un decimal */
export function distance(meters: number): string {
  return meters >= 1000 ? `${(meters / 1000).toFixed(1)} km` : `${Math.round(meters)} m`;
}

/** Fecha -> valor para <input type="datetime-local"> en hora local */
export function toLocalInput(ts: number): string {
  const d = new Date(ts * 1000);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export function fromLocalInput(v: string): number {
  return Math.floor(new Date(v).getTime() / 1000);
}

/** Solo permite colores #rrggbb (defensa extra: el servidor ya valida) */
export function safeColor(c?: string | null, fallback = "#8d8da3"): string {
  return c && /^#[0-9a-f]{6}$/i.test(c) ? c : fallback;
}
