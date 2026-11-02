import { useState } from "react";
import { Upload } from "lucide-react";
import { Button, Card, SectionTitle, fieldClass } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { cn } from "@/lib/utils";
import type { TrackDetail } from "@/lib/types";

/** Importa un circuito desde JSON (`format: "races.track"`, `schema: 1`); queda desactivado y sin probar */
export function ImportCard({ onImported }: { onImported: (track: TrackDetail) => void }) {
  const t = useT();
  const { call } = useApp();
  const [json, setJson] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    setBusy(true);
    const res = await call<{ track: TrackDetail }>("adminImportTrack", { json: json.trim() }, t("a.import.ok"));
    setBusy(false);
    if (!res.ok) return;
    setJson("");
    onImported(res.data.track);
  };

  return (
    <Card>
      <SectionTitle>{t("a.import.title")}</SectionTitle>
      <p className="mb-3 text-sm text-mute">{t("a.import.hint")}</p>
      <textarea
        value={json}
        onChange={(e) => setJson(e.target.value)}
        rows={5}
        spellCheck={false}
        aria-label={t("a.import.title")}
        placeholder='{"format":"races.track","schema":1,...}'
        className={cn(fieldClass, "resize-y font-mono text-xs")}
      />
      <div className="mt-3 flex justify-end">
        <Button size="sm" loading={busy} disabled={json.trim().length < 2} onClick={() => void submit()}>
          <Upload className="size-4" /> {t("import")}
        </Button>
      </div>
    </Card>
  );
}
