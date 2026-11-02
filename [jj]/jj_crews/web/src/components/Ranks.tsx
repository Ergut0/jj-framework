import { useState } from "react";
import { Plus, Save, Trash2, Lock } from "lucide-react";
import { Button, Card, ConfirmDialog, Field, Input, SectionTitle, Toggle } from "./ui";
import type { CrewCtx } from "./ctx";
import { useT, type Key } from "@/lib/i18n";
import { useApp } from "@/lib/store";
import type { Permissions, Rank } from "@/lib/types";

function PermissionToggles({ ctx, value, onChange, disabled }: { ctx: CrewCtx; value: Permissions; onChange: (p: Permissions) => void; disabled?: boolean }) {
  const t = useT();
  const { config } = useApp();
  return (
    <div className="grid gap-2 sm:grid-cols-2">
      {config.permissionKeys.map((k) => (
        <div key={k} className={disabled || !ctx.can(k as never) ? "opacity-50" : ""}>
          <Toggle
            checked={!!value[k]}
            // Solo se pueden conceder permisos que el actor posee (el servidor lo vuelve a comprobar)
            onChange={(v) => !disabled && ctx.can(k as never) && onChange({ ...value, [k]: v })}
            label={t(`perm.${k}` as Key)}
          />
        </div>
      ))}
    </div>
  );
}

function RankCard({ ctx, rank }: { ctx: CrewCtx; rank: Rank }) {
  const t = useT();
  const [name, setName] = useState(rank.name);
  const [perms, setPerms] = useState<Permissions>(rank.permissions);
  const [busy, setBusy] = useState<"save" | "delete" | null>(null);
  const [confirm, setConfirm] = useState(false);
  const editable = !rank.isLeader && ctx.can("manageRanks") && (ctx.isLeader || ctx.level > rank.level);
  const dirty = name !== rank.name || JSON.stringify(perms) !== JSON.stringify(rank.permissions);

  const save = async () => {
    setBusy("save");
    const res = await ctx.run("updateRank", { rankId: rank.id, name, permissions: perms }, t("rk.saved"));
    setBusy(null);
    if (res.ok) await ctx.refresh();
  };

  const remove = async () => {
    setBusy("delete");
    const res = await ctx.run("deleteRank", { rankId: rank.id }, t("rk.deleted"));
    setBusy(null);
    if (res.ok) await ctx.refresh();
    setConfirm(false);
  };

  return (
    <Card className="flex flex-col gap-4">
      <div className="flex items-center gap-3">
        <span className="racing-title w-10 text-center text-xl text-accent">{rank.level}</span>
        {editable ? (
          <Input value={name} onChange={(e) => setName(e.target.value)} maxLength={24} aria-label={t("rk.name")} />
        ) : (
          <span className="flex items-center gap-2 font-semibold">
            {rank.isLeader && <Lock className="size-4 text-warn" />}
            {rank.name}
          </span>
        )}
      </div>
      {rank.isLeader ? <p className="text-xs text-mute">{t("rk.locked")}</p> : <PermissionToggles ctx={ctx} value={perms} onChange={setPerms} disabled={!editable} />}
      {editable && (
        <div className="flex justify-end gap-2">
          <Button variant="danger" size="sm" onClick={() => setConfirm(true)} aria-label={t("delete")}>
            <Trash2 className="size-4" />
          </Button>
          <Button size="sm" loading={busy === "save"} disabled={!dirty || name.trim().length < 2} onClick={save}>
            <Save className="size-4" />
            {t("save")}
          </Button>
        </div>
      )}
      {confirm && <ConfirmDialog title={t("delete")} message={t("rk.confirm_delete", { name: rank.name })} danger loading={busy === "delete"} onConfirm={remove} onClose={() => setConfirm(false)} />}
    </Card>
  );
}

export function Ranks({ ctx }: { ctx: CrewCtx }) {
  const t = useT();
  const { config } = useApp();
  const [name, setName] = useState("");
  const [level, setLevel] = useState("");
  const [perms, setPerms] = useState<Permissions>({});
  const [busy, setBusy] = useState(false);
  const maxLevel = Math.min(config.leaderLevel - 1, ctx.isLeader ? 98 : Math.max(ctx.level - 1, 1));

  const create = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    const res = await ctx.run("createRank", { name, level: Number(level), permissions: perms }, t("rk.created"));
    setBusy(false);
    if (res.ok) {
      setName("");
      setLevel("");
      setPerms({});
      await ctx.refresh();
    }
  };

  return (
    <div className="flex flex-col gap-4">
      {ctx.can("manageRanks") && (
        <Card>
          <SectionTitle>{t("rk.new")}</SectionTitle>
          <form onSubmit={create} className="flex flex-col gap-4">
            <div className="grid gap-4 sm:grid-cols-[1fr_10rem]">
              <Field label={t("rk.name")}>{(id) => <Input id={id} value={name} onChange={(e) => setName(e.target.value)} maxLength={24} required />}</Field>
              <Field label={t("rk.level", { max: maxLevel })}>
                {(id) => <Input id={id} type="number" min={1} max={maxLevel} value={level} onChange={(e) => setLevel(e.target.value)} required />}
              </Field>
            </div>
            <PermissionToggles ctx={ctx} value={perms} onChange={setPerms} />
            <Button type="submit" loading={busy} disabled={name.trim().length < 2 || !level} className="self-end">
              <Plus className="size-4" />
              {t("create")}
            </Button>
          </form>
        </Card>
      )}
      <div className="grid gap-4 xl:grid-cols-2">
        {ctx.crew.ranks.map((r) => (
          <RankCard key={`${r.id}:${r.name}:${JSON.stringify(r.permissions)}`} ctx={ctx} rank={r} />
        ))}
      </div>
    </div>
  );
}
