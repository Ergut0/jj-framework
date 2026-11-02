import { useState } from "react";
import { Copy, FileJson, FlaskConical, Pencil, Plus, Power, Trophy, Trash2 } from "lucide-react";
import { Badge, Button, Card, ConfirmDialog, DataState, DifficultyBadge, Pagination, SearchInput, Select, SectionTitle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { fetchNui } from "@/lib/nui";
import { useAsync, useDebounced } from "@/lib/hooks";
import { distance, formatTime, money } from "@/lib/format";
import type { Paginated, TrackDetail, TrackSummary } from "@/lib/types";
import { IconButton } from "./fields";
import { draftFromDetail } from "./draft";
import { ExportModal, LeaderboardModal } from "./TrackModals";

const SORTS = ["name", "difficulty", "length", "newest"] as const;
const STATUSES = ["enabled", "disabled", "untested"] as const;

type Dialog =
  | { kind: "delete"; track: TrackSummary }
  | { kind: "test"; track: TrackSummary }
  | { kind: "export"; name: string; json: string }
  | { kind: "board"; id: number };

export function Tracks({ onOpenCreator }: { onOpenCreator: () => void }) {
  const t = useT();
  const { config, call, setDraft } = useApp();
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("");
  const [difficulty, setDifficulty] = useState("");
  const [status, setStatus] = useState("");
  const [sort, setSort] = useState<string>("name");
  const [page, setPage] = useState(1);
  const [dialog, setDialog] = useState<Dialog | null>(null);
  const [busy, setBusy] = useState(false);
  const q = useDebounced(search.trim(), 300);

  const list = useAsync(() => fetchNui<Paginated<TrackSummary>>("adminListTracks", { search: q, category, difficulty, status, sort, page }), [q, category, difficulty, status, sort, page]);
  const data = list.data;

  const filter = (setter: (v: string) => void) => (v: string) => {
    setter(v);
    setPage(1);
  };

  const edit = async (id: number) => {
    const res = await call<TrackDetail>("adminGetTrack", { id });
    if (!res.ok) return;
    setDraft(draftFromDetail(res.data));
    onOpenCreator();
  };

  const run = async (action: string, payload: unknown, okMsg?: string) => {
    const res = await call(action, payload, okMsg);
    if (res.ok) void list.reload();
    return res;
  };

  const exportTrack = async (track: TrackSummary) => {
    const res = await call<{ json: string }>("adminExportTrack", { id: track.id });
    if (res.ok) setDialog({ kind: "export", name: track.name, json: res.data.json });
  };

  const confirmDelete = async (track: TrackSummary) => {
    setBusy(true);
    await run("adminDeleteTrack", { id: track.id }, t("a.tracks.deleted"));
    setBusy(false);
    setDialog(null);
  };

  const confirmTest = async (track: TrackSummary) => {
    setBusy(true);
    const res = await call("adminTestTrack", { id: track.id }, t("a.tracks.testStarted"));
    setBusy(false);
    if (res.ok) setDialog(null);
  };

  return (
    <div>
      <SectionTitle
        action={
          <Button size="sm" onClick={onOpenCreator}>
            <Plus className="size-4" /> {t("a.tracks.new")}
          </Button>
        }
      >
        {t("a.nav.tracks")}
      </SectionTitle>

      <div className="mb-4 flex flex-col gap-2">
        <SearchInput value={search} onChange={(e) => filter(setSearch)(e.target.value)} placeholder={t("a.tracks.search")} aria-label={t("search")} />
        <div className="grid grid-cols-2 gap-2 lg:grid-cols-4">
          <Select aria-label={t("a.f.category")} value={category} onChange={(e) => filter(setCategory)(e.target.value)}>
            <option value="">{t("a.f.category")}: {t("all")}</option>
            {config.categories.map((c) => (
              <option key={c} value={c}>{t(`cat.${c}`)}</option>
            ))}
          </Select>
          <Select aria-label={t("a.f.difficulty")} value={difficulty} onChange={(e) => filter(setDifficulty)(e.target.value)}>
            <option value="">{t("a.f.difficulty")}: {t("all")}</option>
            {config.difficulties.map((d) => (
              <option key={d} value={d}>{t(`diff.${d}`)}</option>
            ))}
          </Select>
          <Select aria-label={t("a.f.status")} value={status} onChange={(e) => filter(setStatus)(e.target.value)}>
            <option value="">{t("a.f.status")}: {t("all")}</option>
            {STATUSES.map((s) => (
              <option key={s} value={s}>{t(`a.st.${s}`)}</option>
            ))}
          </Select>
          <Select aria-label={t("a.f.sort")} value={sort} onChange={(e) => filter(setSort)(e.target.value)}>
            {SORTS.map((s) => (
              <option key={s} value={s}>{t("a.f.sort")}: {t(`a.sort.${s}`)}</option>
            ))}
          </Select>
        </div>
      </div>

      <DataState loading={list.loading} error={list.error} hasData={!!data} empty={!!data && data.items.length === 0} emptyText={t("a.tracks.empty")} onRetry={list.reload}>
        <div className="flex flex-col gap-3">
          {data?.items.map((tr) => (
            <TrackRow
              key={tr.id}
              track={tr}
              currency={config.currency}
              onEdit={() => void edit(tr.id)}
              onDuplicate={() => void run("adminDuplicateTrack", { id: tr.id }, t("a.tracks.duplicated"))}
              onToggle={() => void run("adminToggleTrack", { id: tr.id, enabled: !tr.enabled }, t(tr.enabled ? "a.tracks.disabledOk" : "a.tracks.enabledOk"))}
              onDelete={() => setDialog({ kind: "delete", track: tr })}
              onExport={() => void exportTrack(tr)}
              onTest={() => setDialog({ kind: "test", track: tr })}
              onBoard={() => setDialog({ kind: "board", id: tr.id })}
            />
          ))}
        </div>
        {data && <Pagination page={data.page} total={data.total} pageSize={data.pageSize} onChange={setPage} />}
      </DataState>

      {dialog?.kind === "delete" && (
        <ConfirmDialog danger loading={busy} title={t("a.tracks.deleteTitle")} message={t("a.tracks.deleteMsg", { name: dialog.track.name })} onConfirm={() => void confirmDelete(dialog.track)} onClose={() => setDialog(null)} />
      )}
      {dialog?.kind === "test" && (
        <ConfirmDialog loading={busy} title={t("a.tracks.testTitle")} message={t("a.tracks.testMsg", { name: dialog.track.name })} onConfirm={() => void confirmTest(dialog.track)} onClose={() => setDialog(null)} />
      )}
      {dialog?.kind === "export" && <ExportModal name={dialog.name} json={dialog.json} onClose={() => setDialog(null)} />}
      {dialog?.kind === "board" && <LeaderboardModal trackId={dialog.id} onClose={() => setDialog(null)} onChanged={() => void list.reload()} />}
    </div>
  );
}

interface RowProps {
  track: TrackSummary;
  currency: string;
  onEdit: () => void;
  onDuplicate: () => void;
  onToggle: () => void;
  onDelete: () => void;
  onExport: () => void;
  onTest: () => void;
  onBoard: () => void;
}

function TrackRow({ track: tr, currency, onEdit, onDuplicate, onToggle, onDelete, onExport, onTest, onBoard }: RowProps) {
  const t = useT();
  return (
    <Card className="flex flex-col gap-3 p-4 lg:flex-row lg:items-center">
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-2">
          <span className="racing-title truncate pr-1 text-base">{tr.name}</span>
          <Badge color={tr.enabled ? "#22c55e" : "#8d8da3"}>{t(tr.enabled ? "a.st.enabled" : "a.st.draft")}</Badge>
          {!tr.tested && <Badge color="#f59e0b">{t("a.st.untested")}</Badge>}
          {tr.inUse && <Badge color="#3cc8ff">{t("a.st.inUse")}</Badge>}
        </div>
        <div className="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-mute">
          <span>{t(`cat.${tr.category}`)}</span>
          <DifficultyBadge difficulty={tr.difficulty} />
          <span>{t(`class.${tr.vehicleClass}`)}</span>
          <span>v{tr.version}</span>
          <span>{distance(tr.length)}</span>
          <span>{t("a.tracks.cps", { n: tr.checkpointCount })}</span>
          <span>{money(tr.basePrize, currency)}</span>
        </div>
        <div className="mt-1 flex flex-wrap gap-x-4 text-xs text-mute">
          <span>
            {t("a.tracks.record")}: <span className="tabular text-ink">{tr.record ? `${formatTime(tr.record.time)} · ${tr.record.name}` : "—"}</span>
          </span>
          <span>
            {t("a.tracks.reference")}: <span className="tabular text-ink">{formatTime(tr.referenceTime)}</span>
          </span>
        </div>
      </div>
      <div className="flex shrink-0 flex-wrap items-center gap-0.5">
        <IconButton label={t("edit")} onClick={onEdit}><Pencil className="size-4" /></IconButton>
        <IconButton label={t("duplicate")} onClick={onDuplicate}><Copy className="size-4" /></IconButton>
        <IconButton label={t(tr.enabled ? "a.tracks.disable" : "a.tracks.enable")} onClick={onToggle}><Power className={`size-4 ${tr.enabled ? "text-ok" : ""}`} /></IconButton>
        <IconButton label={t("a.tracks.test")} onClick={onTest}><FlaskConical className="size-4" /></IconButton>
        <IconButton label={t("a.tracks.leaderboard")} onClick={onBoard}><Trophy className="size-4" /></IconButton>
        <IconButton label={t("export")} onClick={onExport}><FileJson className="size-4" /></IconButton>
        <IconButton danger label={t("delete")} onClick={onDelete}><Trash2 className="size-4" /></IconButton>
      </div>
    </Card>
  );
}
