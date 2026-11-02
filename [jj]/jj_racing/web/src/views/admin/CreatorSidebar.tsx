import { AlertTriangle, CheckCircle2, Crosshair, Eye, EyeOff, FilePlus2, FlaskConical, Info, Save } from "lucide-react";
import { Badge, Button, Card, SectionTitle, Toggle } from "@/components/ui";
import { TrackMap } from "@/components/TrackMap";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { formatTime } from "@/lib/format";
import type { TrackDetail, TrackDraft } from "@/lib/types";
import { isPointToPoint, toRoute, type Problem } from "./draft";

export interface SaveNote {
  version: number;
  newVersion: boolean;
  disabled: boolean;
}

interface Props {
  draft: TrackDraft;
  meta: TrackDetail | null;
  problems: Problem[];
  dirty: boolean;
  selected: number | null;
  minor: boolean;
  onMinor: (v: boolean) => void;
  busy: "save" | "test" | "toggle" | null;
  note: SaveNote | null;
  onSave: () => void;
  onWorld: () => void;
  onTest: () => void;
  onToggle: () => void;
  onReset: () => void;
}

export function CreatorSidebar({ draft, meta, problems, dirty, selected, minor, onMinor, busy, note, onSave, onWorld, onTest, onToggle, onReset }: Props) {
  const t = useT();
  const { config } = useApp();
  const valid = problems.length === 0;
  const tested = !!meta && meta.testedVersion === meta.version;
  const requireTest = config.creator.requireTest;

  return (
    <div className="flex flex-col gap-4">
      <Card className="p-4">
        {draft.checkpoints.length > 0 || draft.grid.length > 0 ? (
          <TrackMap route={toRoute(draft.checkpoints)} grid={draft.grid} closed={!isPointToPoint(config, draft.category)} highlight={selected ?? undefined} />
        ) : (
          <div className="flex h-40 items-center justify-center rounded-lg border border-dashed border-line px-4 text-center text-sm text-mute">{t("a.map.empty")}</div>
        )}
      </Card>

      <Card className="p-4">
        <SectionTitle>{t("a.status.title")}</SectionTitle>
        {meta ? (
          <div className="mb-3 flex flex-wrap items-center gap-2 text-xs">
            <Badge>v{meta.version}</Badge>
            <Badge color={tested ? "#22c55e" : "#f59e0b"}>{t(tested ? "a.status.tested" : "a.status.untested")}</Badge>
            <Badge color={meta.enabled ? "#22c55e" : "#8d8da3"}>{t(meta.enabled ? "a.st.enabled" : "a.st.draft")}</Badge>
            {meta.referenceTime > 0 && <span className="tabular text-mute">{t("a.tracks.reference")}: {formatTime(meta.referenceTime)}</span>}
          </div>
        ) : (
          <p className="mb-3 text-xs text-mute">{t("a.status.new")}</p>
        )}
        {dirty && draft.id != null && <p className="mb-3 flex items-center gap-2 text-xs text-warn"><Info className="size-4 shrink-0" />{t("a.status.dirty")}</p>}

        {valid ? (
          <p className="flex items-center gap-2 text-sm text-ok"><CheckCircle2 className="size-4" />{t("a.v.ok")}</p>
        ) : (
          <ul className="flex flex-col gap-1 text-sm text-bad" aria-live="polite">
            {problems.map((p, i) => (
              <li key={i} className="flex items-start gap-2"><AlertTriangle className="mt-0.5 size-4 shrink-0" />{t(p.key, p.vars)}</li>
            ))}
          </ul>
        )}
      </Card>

      <Card className="flex flex-col gap-3 p-4">
        {draft.id != null && <Toggle checked={minor} onChange={onMinor} label={t("a.save.minor")} />}
        {draft.id != null && <p className="-mt-1 text-xs text-mute">{t("a.save.minorHint")}</p>}
        {draft.id == null && requireTest && <p className="text-xs text-mute">{t("a.save.newHint")}</p>}

        <div className="grid grid-cols-2 gap-2">
          <Button loading={busy === "save"} disabled={!valid || busy !== null} onClick={onSave} className="col-span-2">
            <Save className="size-4" /> {t("save")}
          </Button>
          <Button variant="outline" size="sm" onClick={onWorld} disabled={busy !== null}>
            <Crosshair className="size-4 shrink-0" /> {t("a.world.edit")}
          </Button>
          <Button variant="outline" size="sm" loading={busy === "test"} disabled={!valid || busy !== null} onClick={onTest}>
            <FlaskConical className="size-4 shrink-0" /> {t("a.tracks.test")}
          </Button>
          {draft.id != null && (
            <Button
              variant="outline"
              size="sm"
              loading={busy === "toggle"}
              disabled={busy !== null || !meta || (!meta.enabled && requireTest && !tested)}
              title={!meta?.enabled && requireTest && !tested ? t("a.publish.needTest") : undefined}
              onClick={onToggle}
            >
              {meta?.enabled ? <EyeOff className="size-4 shrink-0" /> : <Eye className="size-4 shrink-0" />} {t(meta?.enabled ? "a.publish.off" : "a.publish.on")}
            </Button>
          )}
          <Button variant="ghost" size="sm" disabled={busy !== null} onClick={onReset}>
            <FilePlus2 className="size-4 shrink-0" /> {t("a.draft.discard")}
          </Button>
        </div>
        <p className="text-xs text-mute">{t("a.world.hint")}</p>

        {note && (
          <div className="animate-rise rounded-lg border border-line bg-panel2/70 p-3 text-xs text-mute">
            <p className="font-semibold text-ink">{t(note.newVersion ? "a.save.newVersion" : "a.save.sameVersion", { v: note.version })}</p>
            {note.newVersion && <p className="mt-1">{t(note.disabled ? "a.save.newVersionDisabled" : "a.save.newVersionBody")}</p>}
          </div>
        )}
      </Card>
    </div>
  );
}
