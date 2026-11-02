import { useMemo, useState } from "react";
import { Card, ConfirmDialog, SectionTitle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { fetchNui } from "@/lib/nui";
import { useAsync } from "@/lib/hooks";
import type { NuiResponse, TrackDetail, TrackDraft } from "@/lib/types";
import { TrackForm } from "./TrackForm";
import { CheckpointEditor } from "./CheckpointEditor";
import { GridEditor } from "./GridEditor";
import { ImportCard } from "./ImportExport";
import { CreatorSidebar, type SaveNote } from "./CreatorSidebar";
import { draftFromDetail, draftSignature, newDraft, validateDraft } from "./draft";

type Busy = "save" | "test" | "toggle" | null;

export function TrackCreator() {
  const t = useT();
  const { config, call, toast, draft: ctxDraft, setDraft } = useApp();
  const blank = useMemo(() => newDraft(config), [config]);
  const draft = ctxDraft ?? blank;
  const [selected, setSelected] = useState<number | null>(null);
  const [minor, setMinor] = useState(false);
  const [busy, setBusy] = useState<Busy>(null);
  const [note, setNote] = useState<SaveNote | null>(null);
  const [confirm, setConfirm] = useState<"reset" | "test" | null>(null);

  // Version / estado de prueba / publicacion de la version guardada
  const meta = useAsync(
    () => (draft.id != null ? fetchNui<TrackDetail | null>("adminGetTrack", { id: draft.id }) : Promise.resolve<NuiResponse<TrackDetail | null>>({ ok: true, data: null })),
    [draft.id],
  );
  const saved = meta.data;

  const problems = useMemo(() => validateDraft(draft, config), [draft, config]);
  const signature = draftSignature(draft);
  const dirty = draft.id == null ? signature !== draftSignature(blank) : saved ? signature !== draftSignature(draftFromDetail(saved)) : true;

  const update = (patch: Partial<TrackDraft>) => setDraft({ ...draft, ...patch });

  const load = (track: TrackDetail) => {
    setDraft(draftFromDetail(track));
    meta.setData(track);
    setSelected(null);
    setNote(null);
    setMinor(false);
  };

  const doSave = async (): Promise<TrackDetail | null> => {
    const res = await call<{ track: TrackDetail; newVersion: boolean }>("adminSaveTrack", { ...draft, name: draft.name.trim(), minor: draft.id != null && minor });
    if (!res.ok) return null;
    const { track, newVersion } = res.data;
    load(track);
    setNote({ version: track.version, newVersion, disabled: newVersion && config.creator.requireTest });
    toast(t("a.save.ok"), "ok");
    return track;
  };

  const save = async () => {
    setBusy("save");
    await doSave();
    setBusy(null);
  };

  const runTest = async () => {
    setConfirm(null);
    setBusy("test");
    let id = draft.id;
    if (id == null || dirty) {
      const track = await doSave();
      if (!track) return setBusy(null);
      id = track.id;
    }
    await call("adminTestTrack", { id }, t("a.tracks.testStarted"));
    setBusy(null);
  };

  const toggle = async () => {
    if (!saved) return;
    setBusy("toggle");
    const res = await call("adminToggleTrack", { id: saved.id, enabled: !saved.enabled }, t(saved.enabled ? "a.tracks.disabledOk" : "a.tracks.enabledOk"));
    setBusy(null);
    if (res.ok) void meta.reload();
  };

  const reset = () => {
    setDraft(newDraft(config));
    meta.setData(null);
    setSelected(null);
    setNote(null);
    setMinor(false);
    setConfirm(null);
  };

  return (
    <div>
      <SectionTitle>{draft.id != null ? t("a.creator.editing", { name: draft.name || `#${draft.id}` }) : t("a.creator.new")}</SectionTitle>
      <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_340px]">
        <div className="flex min-w-0 flex-col gap-4">
          <Card>
            <SectionTitle>{t("a.form.section")}</SectionTitle>
            <TrackForm draft={draft} onChange={update} />
          </Card>
          <Card>
            <SectionTitle>{t("a.cp.title")}</SectionTitle>
            <CheckpointEditor checkpoints={draft.checkpoints} onChange={(checkpoints) => update({ checkpoints })} selected={selected} onSelect={setSelected} />
          </Card>
          <Card>
            <SectionTitle>{t("a.grid.title")}</SectionTitle>
            <GridEditor grid={draft.grid} onChange={(grid) => update({ grid })} />
          </Card>
          <ImportCard onImported={load} />
        </div>
        <div className="lg:sticky lg:top-0 lg:max-h-[calc(min(100vh,848px)-12rem)] lg:self-start lg:overflow-y-auto lg:pr-1">
          <CreatorSidebar
            draft={draft}
            meta={saved}
            problems={problems}
            dirty={dirty}
            selected={selected}
            minor={minor}
            onMinor={setMinor}
            busy={busy}
            note={note}
            onSave={() => void save()}
            onWorld={() => void call("creatorEnter", draft)}
            onTest={() => setConfirm("test")}
            onToggle={() => void toggle()}
            onReset={() => (dirty ? setConfirm("reset") : reset())}
          />
        </div>
      </div>

      {confirm === "reset" && <ConfirmDialog danger title={t("a.draft.discardTitle")} message={t("a.draft.discardMsg")} onConfirm={reset} onClose={() => setConfirm(null)} />}
      {confirm === "test" && <ConfirmDialog title={t("a.tracks.testTitle")} message={t(dirty ? "a.creator.testMsgSave" : "a.creator.testMsg")} onConfirm={() => void runTest()} onClose={() => setConfirm(null)} />}
    </div>
  );
}
