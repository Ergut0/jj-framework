import { useEffect, useState } from "react";
import { Save } from "lucide-react";
import { Button, Card, ErrorState, Field, Input, Loading, SectionTitle, Toggle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useAsync } from "@/lib/hooks";
import { useT, type Key } from "@/lib/i18n";
import type { SettingsPayload, SettingsValues } from "@/lib/types";

const NUMERIC = ["maxMembers", "createCost", "nameMin", "nameMax", "maxRanks", "inviteExpiryMinutes"] as const;

export function Settings() {
  const t = useT();
  const { call, reload } = useApp();
  const res = useAsync(() => call<SettingsPayload>("adminGetSettings"), []);
  const [form, setForm] = useState<SettingsValues | null>(null);
  const [banned, setBanned] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (res.data) {
      setForm(res.data.values);
      setBanned(res.data.values.bannedNames.join("\n"));
    }
  }, [res.data]);

  if (res.loading && !form) return <Loading />;
  if (res.error || !form || !res.data) return <ErrorState message={res.error ?? undefined} onRetry={res.reload} />;

  const schema = res.data.schema;

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    const settings = {
      ...form,
      bannedNames: banned.split("\n").map((s) => s.trim()).filter(Boolean),
    };
    const r = await call("adminSaveSettings", { settings }, t("adm.saved"));
    setBusy(false);
    if (r.ok) {
      await res.reload();
      await reload();
    }
  };

  return (
    <Card>
      <SectionTitle>{t("adm.settings.title")}</SectionTitle>
      <p className="mb-5 -mt-2 text-sm text-mute">{t("adm.settings.hint")}</p>
      <form onSubmit={save} className="flex flex-col gap-5">
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {NUMERIC.map((k) => (
            <Field key={k} label={t(`set.${k}` as Key)}>
              {(id) => (
                <Input id={id} type="number" min={schema[k]?.min} max={schema[k]?.max} value={form[k]} onChange={(e) => setForm({ ...form, [k]: Number(e.target.value) })} required />
              )}
            </Field>
          ))}
        </div>
        <Toggle checked={form.allowLogo} onChange={(v) => setForm({ ...form, allowLogo: v })} label={t("set.allowLogo")} />
        <Field label={t("set.bannedNames")}>
          {(id) => (
            <textarea
              id={id}
              rows={6}
              value={banned}
              onChange={(e) => setBanned(e.target.value)}
              className="w-full rounded-md border border-line bg-bg/70 px-3 py-2 font-mono text-sm outline-none focus:border-accent"
            />
          )}
        </Field>
        <Button type="submit" loading={busy} className="self-end">
          <Save className="size-4" /> {t("save")}
        </Button>
      </form>
    </Card>
  );
}
