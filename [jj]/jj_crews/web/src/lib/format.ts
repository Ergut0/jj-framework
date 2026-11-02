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

/** Solo permite logos https (defensa extra: el servidor ya valida) */
export function safeLogo(url?: string): string | undefined {
  return url && /^https:\/\//i.test(url) ? url : undefined;
}
