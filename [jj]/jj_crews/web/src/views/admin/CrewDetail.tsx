import { useState } from "react";
import { ArrowLeft, Pencil, Snowflake, Trash2 } from "lucide-react";
import { Button, Card, ConfirmDialog, ErrorState, Field, Input, Loading, Modal, SectionTitle, Select } from "@/components/ui";
import { IdentityForm } from "@/components/IdentityForm";
import { Members } from "@/components/Members";
import { Ranks } from "@/components/Ranks";
import { useCrewCtx, type CrewCtx } from "@/components/ctx";
import { CrewHeader, CrewStats } from "@/views/player/Overview";
import { useApp } from "@/lib/store";
import { useAsync } from "@/lib/hooks";
import { useT, type Key } from "@/lib/i18n";
import type { Crew } from "@/lib/types";

function StatEditor({ ctx }: { ctx: CrewCtx }) {
  const t = useT();
  const [stat, setStat] = useState("money");
  const [mode, setMode] = useState("add");
  const [value, setValue] = useState("");
  const [reason, setReason] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    const res = await ctx.run("editStat", { stat, mode, value: Number(value), reason }, t("adm.applied"));
    setBusy(false);
    if (res.ok) {
      setValue("");
      setReason("");
      await ctx.refresh();
    }
  };

  return (
    <Card>
      <SectionTitle>{t("adm.edit_stat")}</SectionTitle>
      <form onSubmit={submit} className="grid gap-4 sm:grid-cols-3">
        <Field label={t("adm.stat")}>
          {(id) => (
            <Select id={id} value={stat} onChange={(e) => setStat(e.target.value)}>
              {(["money", "points", "wins", "level"] as const).map((s) => (
                <option key={s} value={s}>{t(`stat.${s}` as Key)}</option>
              ))}
            </Select>
          )}
        </Field>
        <Field label={t("adm.mode")}>
          {(id) => (
            <Select id={id} value={mode} onChange={(e) => setMode(e.target.value)}>
              <option value="add">{t("adm.mode.add")}</option>
              <option value="set">{t("adm.mode.set")}</option>
            </Select>
          )}
        </Field>
        <Field label={t("adm.value")}>{(id) => <Input id={id} type="number" value={value} onChange={(e) => setValue(e.target.value)} required />}</Field>
        <div className="sm:col-span-3">
          <Field label={t("adm.reason")}>{(id) => <Input id={id} value={reason} onChange={(e) => setReason(e.target.value)} minLength={3} maxLength={120} required />}</Field>
        </div>
        <Button type="submit" loading={busy} disabled={value === "" || reason.trim().length < 3} className="sm:col-span-3 sm:justify-self-end">
          {t("adm.apply")}
        </Button>
      </form>
    </Card>
  );
}

function Detail({ crew, reload, onBack }: { crew: Crew; reload: () => Promise<void>; onBack: () => void }) {
  const t = useT();
  const { call } = useApp();
  const ctx = useCrewCtx(crew, true, reload);
  const [tab, setTab] = useState<"stats" | "members" | "ranks">("stats");
  const [modal, setModal] = useState<"edit" | "delete" | null>(null);
  const [busy, setBusy] = useState(false);

  const toggleFreeze = async () => {
    setBusy(true);
    const res = await ctx.run("freeze", { frozen: !crew.frozen }, t(crew.frozen ? "adm.frozen_off" : "adm.frozen_on"));
    setBusy(false);
    if (res.ok) await reload();
  };

  const remove = async () => {
    setBusy(true);
    const res = await call("adminDelete", { id: crew.id }, t("adm.deleted"));
    setBusy(false);
    if (res.ok) onBack();
  };

  return (
    <div className="flex flex-col gap-4">
      <div>
        <Button variant="ghost" size="sm" onClick={onBack}>
          <ArrowLeft className="size-4" /> {t("adm.back")}
        </Button>
      </div>
      <CrewHeader crew={crew} />
      <CrewStats crew={crew} />
      <div className="flex flex-wrap gap-2">
        <Button variant="outline" onClick={() => setModal("edit")}><Pencil className="size-4" /> {t("adm.edit")}</Button>
        <Button variant="outline" loading={busy} onClick={toggleFreeze}><Snowflake className="size-4" /> {t(crew.frozen ? "adm.unfreeze" : "adm.freeze")}</Button>
        <Button variant="danger" onClick={() => setModal("delete")}><Trash2 className="size-4" /> {t("adm.delete_crew")}</Button>
      </div>

      <div className="flex gap-2 border-b border-line pb-2">
        {(["stats", "members", "ranks"] as const).map((k) => (
          <Button key={k} size="sm" variant={tab === k ? "primary" : "ghost"} onClick={() => setTab(k)}>
            {t(k === "stats" ? "adm.edit_stat" : k === "members" ? "nav.members" : "nav.ranks")}
          </Button>
        ))}
      </div>
      {tab === "stats" && <StatEditor ctx={ctx} />}
      {tab === "members" && <Members ctx={ctx} />}
      {tab === "ranks" && <Ranks ctx={ctx} />}

      {modal === "edit" && (
        <Modal title={t("adm.edit")} onClose={() => setModal(null)}>
          <IdentityForm
            mode="full"
            initial={{ name: crew.name, tag: crew.tag, color: crew.color, logo: crew.logo }}
            submitLabel={t("save")}
            onSubmit={async (v) => {
              const res = await ctx.run("update", { ...v }, t("adm.saved"));
              if (res.ok) {
                setModal(null);
                await reload();
              }
            }}
          />
        </Modal>
      )}
      {modal === "delete" && <ConfirmDialog title={t("adm.delete_crew")} message={t("adm.confirm_delete", { name: crew.name })} danger loading={busy} onConfirm={remove} onClose={() => setModal(null)} />}
    </div>
  );
}

export function CrewDetail({ id, onBack }: { id: number; onBack: () => void }) {
  const { call } = useApp();
  const res = useAsync(() => call<Crew>("adminGetCrew", { id }), [id]);
  if (res.loading && !res.data) return <Loading />;
  if (res.error || !res.data) return <ErrorState message={res.error ?? undefined} onRetry={res.reload} />;
  return <Detail crew={res.data} reload={async () => void (await res.reload())} onBack={onBack} />;
}
