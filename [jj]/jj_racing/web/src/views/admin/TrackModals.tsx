import { useRef, useState } from "react";
import { CheckCircle2, Copy, Eraser, XCircle, X } from "lucide-react";
import { Button, CrewTag, DataState, Modal, fieldClass } from "@/components/ui";
import { cn } from "@/lib/utils";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { fetchNui } from "@/lib/nui";
import { useAsync } from "@/lib/hooks";
import { dateTime, formatTime } from "@/lib/format";
import type { LeaderboardPayload, TestResult } from "@/lib/types";
import { IconButton, ReasonDialog, copyText } from "./fields";

export function ExportModal({ name, json, onClose }: { name: string; json: string; onClose: () => void }) {
  const t = useT();
  const { toast } = useApp();
  const ref = useRef<HTMLTextAreaElement>(null);
  return (
    <Modal title={t("a.export.title", { name })} onClose={onClose} wide>
      <p className="mb-3 text-sm text-mute">{t("a.export.hint")}</p>
      <textarea ref={ref} readOnly value={json} rows={10} className={cn(fieldClass, "resize-y font-mono text-xs")} onFocus={(e) => e.currentTarget.select()} />
      <div className="mt-4 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          {t("close")}
        </Button>
        <Button
          onClick={async () => {
            const ok = await copyText(json, ref.current);
            toast(ok ? t("copied") : t("a.export.copyFailed"), ok ? "ok" : "error");
          }}
        >
          <Copy className="size-4" /> {t("copy")}
        </Button>
      </div>
    </Modal>
  );
}

export function LeaderboardModal({ trackId, onClose, onChanged }: { trackId: number; onClose: () => void; onChanged: () => void }) {
  const t = useT();
  const { call, config } = useApp();
  const { data, error, loading, reload } = useAsync(() => fetchNui<LeaderboardPayload>("adminLeaderboard", { trackId }), [trackId]);
  const [voiding, setVoiding] = useState<{ citizenid: string; name: string } | null>(null);
  const [busy, setBusy] = useState(false);

  if (voiding) {
    return (
      <ReasonDialog
        title={t("a.record.voidTitle")}
        message={t("a.record.voidMsg", { name: voiding.name })}
        loading={busy}
        onClose={() => setVoiding(null)}
        onConfirm={async (reason) => {
          setBusy(true);
          const res = await call("adminVoidRecord", { trackId, citizenid: voiding.citizenid, reason }, t("a.record.voided"));
          setBusy(false);
          if (res.ok) {
            setVoiding(null);
            void reload();
            onChanged();
          }
        }}
      />
    );
  }

  return (
    <Modal title={t("a.lb.title", { name: data?.track.name ?? "…" })} onClose={onClose} wide>
      <DataState loading={loading} error={error} hasData={!!data} empty={!!data && data.rows.length === 0} emptyText={t("a.lb.empty")} onRetry={reload}>
        {data && (
          <>
            <p className="mb-3 text-xs text-mute">{t("a.lb.version", { v: data.track.version })}</p>
            <ul className="flex flex-col gap-1.5">
              {data.rows.map((r) => (
                <li key={r.citizenid ?? r.position} className="flex items-center gap-3 rounded-lg border border-line bg-panel2/60 px-3 py-2 text-sm">
                  <span className="racing-title tabular w-6 text-center text-mute">{r.position}</span>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 truncate font-semibold">
                      {r.name} <CrewTag tag={r.crewTag} color={r.crewColor} />
                    </div>
                    <div className="truncate text-xs text-mute">
                      {r.citizenid} · {r.vehicle} · {t(`class.${r.vehicleClass}`)} · {dateTime(r.at, config.locale)}
                    </div>
                  </div>
                  <span className="tabular font-mono">{formatTime(r.time)}</span>
                  {r.citizenid && (
                    <IconButton danger label={t("a.record.void")} onClick={() => setVoiding({ citizenid: r.citizenid!, name: r.name })}>
                      <Eraser className="size-4" />
                    </IconButton>
                  )}
                </li>
              ))}
            </ul>
          </>
        )}
      </DataState>
    </Modal>
  );
}

export function TestBanner({ result, onClear }: { result: TestResult; onClear: () => void }) {
  const t = useT();
  const Icon = result.ok ? CheckCircle2 : XCircle;
  return (
    <div role="status" className={`animate-rise mb-4 flex items-start gap-3 rounded-xl border px-4 py-3 text-sm ${result.ok ? "border-ok/40 bg-ok/10" : "border-bad/40 bg-bad/10"}`}>
      <Icon className={`mt-0.5 size-5 shrink-0 ${result.ok ? "text-ok" : "text-bad"}`} />
      <div className="min-w-0 flex-1">
        <div className="racing-title">{t(result.ok ? "a.test.ok" : "a.test.fail", { id: result.trackId })}</div>
        <div className="text-mute">
          {result.ok ? t("a.test.okDetail", { time: formatTime(result.time), ref: formatTime(result.reference) }) : t("a.test.failDetail")}
        </div>
      </div>
      <IconButton label={t("a.test.clear")} onClick={onClear}>
        <X className="size-4" />
      </IconButton>
    </div>
  );
}
