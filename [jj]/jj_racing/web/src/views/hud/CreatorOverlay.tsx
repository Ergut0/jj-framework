import { useState, type ReactNode } from "react";
import { Crosshair, PencilRuler, User } from "lucide-react";
import { useNuiEvent, type NuiMessage } from "@/lib/nui";
import { useT } from "@/lib/i18n";
import type { CreatorHud } from "@/lib/types";
import { HUD_ROOT_CLASS, HUD_ROOT_STYLE, Panel } from "./hudUi";

const KIND_COLOR: Record<string, string> = {
  normal: "#a855f7",
  shortcut: "#ffbe28",
  pit: "#3cc8ff",
  grid: "#ebebeb",
};

type Msg<T> = NuiMessage & { data: T };

function Kbd({ children }: { children: ReactNode }) {
  return (
    <kbd className="inline-flex min-w-[1.9em] items-center justify-center rounded-[0.3em] border border-white/20 border-b-[0.2em] bg-white/10 px-[0.5em] py-[0.15em] font-mono text-[0.85em] font-bold leading-tight">
      {children}
    </kbd>
  );
}

function Stat({ label, value, color, sub }: { label: string; value: ReactNode; color?: string; sub?: string }) {
  return (
    <div className="bg-bg/60 px-[0.8em] py-[0.45em]">
      <div className="text-[0.7em] font-semibold uppercase tracking-[0.15em] text-mute">{label}</div>
      <div className="font-mono text-[1.15em] font-bold tabular" style={{ color }}>
        {value}
      </div>
      {sub && <div className="-mt-[0.1em] truncate text-[0.75em] text-mute">{sub}</div>}
    </div>
  );
}

function Hint({ keys, action, sep = "+" }: { keys: (string | undefined)[]; action: string; sep?: string }) {
  const labels = keys.filter((k): k is string => !!k);
  if (labels.length === 0) return null;
  return (
    <li className="flex items-center gap-[0.6em]">
      <span className="flex shrink-0 items-center gap-[0.25em]">
        {labels.map((k, i) => (
          <span key={i} className="flex items-center gap-[0.25em]">
            {i > 0 && <span className="text-mute">{sep}</span>}
            <Kbd>{k}</Kbd>
          </span>
        ))}
      </span>
      <span className="min-w-0 flex-1 truncate text-[0.9em] text-ink/85">{action}</span>
    </li>
  );
}

function CreatorPanel({ hud }: { hud: CreatorHud }) {
  const t = useT();
  const kindColor = KIND_COLOR[hud.kind] ?? "#ffffff";
  const k = hud.keys ?? {};
  const SourceIcon = hud.source === "aim" ? Crosshair : User;

  return (
    <Panel className="animate-rise absolute bottom-[3vh] left-[2.5vw] w-[24em] overflow-hidden">
      <div className="h-[0.3em] bg-accent" />
      <div className="flex items-center gap-[0.7em] px-[1em] py-[0.7em]">
        <PencilRuler className="size-[1.6em] shrink-0 text-accent" />
        <div className="min-w-0 flex-1">
          <div className="racing-title text-[1.2em] leading-none">{t("h.creator.title")}</div>
          <div className="mt-[0.25em] truncate text-[0.9em] text-mute">{hud.name || t("h.creator.untitled")}</div>
        </div>
      </div>

      <div className="flex items-center justify-between gap-[0.6em] border-t border-white/10 px-[1em] py-[0.55em]">
        <span className="flex items-center gap-[0.5em] text-[0.85em] text-mute">
          {t("h.creator.placing")}
          <span
            className="racing-title cut-sm px-[0.9em] py-[0.25em] text-[1.05em] leading-none"
            style={{ color: kindColor, backgroundColor: `${kindColor}26`, boxShadow: `inset 0 0 0 1px ${kindColor}77` }}
          >
            {t(`kind.${hud.kind}`)}
          </span>
        </span>
        <span className="flex items-center gap-[0.4em] text-[0.85em]" title={t("h.creator.source")}>
          <SourceIcon className="size-[1.1em] text-accent" />
          {t(`h.creator.source.${hud.source}`)}
        </span>
      </div>

      <div className="grid grid-cols-3 gap-px border-t border-white/10 bg-white/10">
        <Stat label={t("h.creator.radius")} value={`${hud.radius.toFixed(1)} m`} />
        <Stat label={t("h.creator.height")} value={`${hud.height.toFixed(1)} m`} />
        <Stat label={t("h.creator.grid")} value={hud.grid} color={KIND_COLOR.grid} />
        <Stat label={t("h.creator.checkpoints")} value={hud.checkpoints} />
        <Stat label={t("h.creator.normals")} value={hud.normals} color={KIND_COLOR.normal} />
        <Stat
          label={t("h.creator.selected")}
          value={hud.selected > 0 ? `#${hud.selected}` : "–"}
          color={hud.selected > 0 ? "var(--color-ok)" : undefined}
          sub={hud.selected > 0 && hud.selectedKind ? t(`kind.${hud.selectedKind}`) : t("h.creator.none")}
        />
      </div>

      <ul className="flex flex-col gap-[0.4em] border-t border-white/10 px-[1em] py-[0.7em]">
        <Hint keys={[k.place]} action={t("h.creator.place")} />
        <Hint keys={[k.remove]} action={t("h.creator.remove")} />
        <Hint keys={[k.prev, k.next]} sep="/" action={t("h.creator.prevNext")} />
        <Hint keys={[k.move]} action={t("h.creator.move")} />
        <Hint keys={[k.source]} action={t("h.creator.sourceKey")} />
        <Hint keys={[k.kind]} action={t("h.creator.kind")} />
        <Hint keys={[k.wheel]} action={t("h.creator.radiusKey")} />
        <Hint keys={[k.modifier, k.wheel]} action={t("h.creator.heightKey")} />
        <Hint keys={[k.finish]} action={t("h.creator.finish")} />
      </ul>
    </Panel>
  );
}

/** Overlay del editor de circuitos en el mundo: visible entre creator:start y creator:stop */
export function CreatorOverlay() {
  const [active, setActive] = useState(false);
  const [hud, setHud] = useState<CreatorHud | null>(null);
  useNuiEvent("creator:start", () => setActive(true));
  useNuiEvent("creator:stop", () => {
    setActive(false);
    setHud(null);
  });
  useNuiEvent<Msg<CreatorHud>>("creator:hud", ({ data }) => setHud(data));

  if (!active || !hud) return null;
  return (
    <div className={HUD_ROOT_CLASS} style={HUD_ROOT_STYLE}>
      <CreatorPanel hud={hud} />
    </div>
  );
}
