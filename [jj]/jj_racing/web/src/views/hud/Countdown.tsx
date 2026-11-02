import { useEffect, useState } from "react";
import { useT } from "@/lib/i18n";

const GLOW = "0 0 0.25em rgb(0 0 0 / 0.6), 0 0 0.6em currentColor";

function Go() {
  const t = useT();
  const [fading, setFading] = useState(false);
  useEffect(() => {
    const id = setTimeout(() => setFading(true), 650);
    return () => clearTimeout(id);
  }, []);
  return (
    <div
      className={`animate-pop racing-title text-[11em] leading-none text-ok transition-opacity duration-500 ${fading ? "opacity-0" : "opacity-100"}`}
      style={{ textShadow: GLOW }}
    >
      {t("h.go")}
    </div>
  );
}

/** n: 5..1 de la cuenta atras (null = sin cuenta); go: destello de salida */
export function Countdown({ n, go }: { n: number | null; go: boolean }) {
  if (!go && n == null) return null;
  // 5 -> warn, 1 -> accent
  const mix = Math.max(0, Math.min(1, ((n ?? 1) - 1) / 4)) * 100;
  return (
    <div className="absolute inset-x-0 top-[26vh] flex justify-center">
      {go ? (
        <Go />
      ) : (
        <div
          key={n}
          className="animate-pop racing-title text-[16em] leading-none tabular"
          style={{ color: `color-mix(in srgb, var(--color-warn) ${mix}%, var(--accent))`, textShadow: GLOW }}
        >
          {n}
        </div>
      )}
    </div>
  );
}
