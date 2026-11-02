import { useState } from "react";
import { Calendar, Coins, Palette, Trophy, Users, Zap, LogOut, Skull, Snowflake } from "lucide-react";
import { Button, Card, ConfirmDialog, Emblem, Field, Input, Modal, StatTile } from "@/components/ui";
import { IdentityForm } from "@/components/IdentityForm";
import type { CrewCtx } from "@/components/ctx";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { date, money, num } from "@/lib/format";
import type { Crew } from "@/lib/types";

export function CrewHeader({ crew }: { crew: Crew }) {
  const t = useT();
  const { config } = useApp();
  const prev = config.levelPoints[crew.level - 1] ?? 0;
  const next = crew.nextLevelPoints;
  const pct = next ? Math.min(100, Math.max(0, ((crew.points - prev) / (next - prev)) * 100)) : 100;
  const leader = crew.members.find((m) => m.isLeader);

  return (
    <Card className="relative overflow-hidden">
      <div className="pointer-events-none absolute -top-16 -right-10 h-48 w-80 -skew-x-[20deg] opacity-20 blur-2xl" style={{ background: crew.color }} />
      <div className="relative flex flex-wrap items-center gap-5">
        <Emblem color={crew.color} tag={crew.tag} logo={crew.logo} size={76} />
        <div className="min-w-0 flex-1">
          <div className="racing-title truncate text-3xl" style={{ color: crew.color }}>
            {crew.name}
          </div>
          <div className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-mute">
            <span className="font-bold text-ink">[{crew.tag}]</span>
            <span>{t("ov.leader")}: {leader?.name ?? "-"}</span>
            <span>#{crew.id}</span>
          </div>
          <div className="mt-3 max-w-md">
            <div className="mb-1 flex justify-between text-[11px] font-semibold tracking-wide text-mute uppercase">
              <span>{t("stat.level")} {crew.level}</span>
              <span>{next ? t("ov.progress", { level: crew.level + 1 }) : t("ov.max_level")}</span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-line">
              <div className="h-full rounded-full transition-all duration-700" style={{ width: `${pct}%`, background: crew.color }} />
            </div>
          </div>
        </div>
      </div>
      {crew.frozen && (
        <div className="relative mt-4 flex items-center gap-2 rounded-lg border border-bad/40 bg-bad/10 px-3 py-2 text-sm text-bad">
          <Snowflake className="size-4" /> {t("ov.frozen")}
        </div>
      )}
    </Card>
  );
}

export function CrewStats({ crew }: { crew: Crew }) {
  const t = useT();
  const { config } = useApp();
  return (
    <div className="grid grid-cols-2 gap-3 lg:grid-cols-3 xl:grid-cols-6">
      <StatTile label={t("stat.level")} value={crew.level} icon={<Zap className="size-3.5" />} />
      <StatTile label={t("stat.points")} value={num(crew.points)} icon={<Trophy className="size-3.5" />} />
      <StatTile label={t("stat.wins")} value={num(crew.wins)} icon={<Trophy className="size-3.5" />} />
      <StatTile label={t("stat.money")} value={money(crew.money, config.currency)} icon={<Coins className="size-3.5" />} />
      <StatTile label={t("stat.members")} value={`${crew.members.length}/${config.maxMembers}`} icon={<Users className="size-3.5" />} />
      <StatTile label={t("stat.created")} value={<span className="text-lg">{date(crew.createdAt, config.locale)}</span>} icon={<Calendar className="size-3.5" />} />
    </div>
  );
}

export function Overview({ ctx }: { ctx: CrewCtx }) {
  const t = useT();
  const { reload } = useApp();
  const { crew } = ctx;
  const [modal, setModal] = useState<"style" | "leave" | "disband" | null>(null);
  const [busy, setBusy] = useState(false);
  const [typed, setTyped] = useState("");

  const leave = async () => {
    setBusy(true);
    const res = await ctx.run("leave", {}, t("ov.left"));
    setBusy(false);
    if (res.ok) await reload();
  };

  const disband = async () => {
    setBusy(true);
    const res = await ctx.run("disband", { confirm: typed }, t("ov.disbanded"));
    setBusy(false);
    if (res.ok) await reload();
  };

  return (
    <div className="flex flex-col gap-4">
      <CrewHeader crew={crew} />
      <CrewStats crew={crew} />
      <div className="flex flex-wrap gap-2">
        {ctx.can("editCrew") && !crew.frozen && (
          <Button variant="outline" onClick={() => setModal("style")}>
            <Palette className="size-4" /> {t("ov.style")}
          </Button>
        )}
        {!ctx.isLeader && (
          <Button variant="danger" onClick={() => setModal("leave")}>
            <LogOut className="size-4" /> {t("ov.leave")}
          </Button>
        )}
        {ctx.isLeader && !crew.frozen && (
          <Button variant="danger" onClick={() => { setTyped(""); setModal("disband"); }}>
            <Skull className="size-4" /> {t("ov.disband")}
          </Button>
        )}
      </div>

      {modal === "style" && (
        <Modal title={t("ov.style")} onClose={() => setModal(null)}>
          <IdentityForm
            mode="style"
            initial={{ name: crew.name, tag: crew.tag, color: crew.color, logo: crew.logo }}
            submitLabel={t("save")}
            onSubmit={async (v) => {
              const res = await ctx.run("updateCrew", { color: v.color, logo: v.logo }, t("ov.style_ok"));
              if (res.ok) {
                setModal(null);
                await ctx.refresh();
              }
            }}
          />
        </Modal>
      )}
      {modal === "leave" && <ConfirmDialog title={t("ov.leave")} message={t("ov.confirm_leave")} danger loading={busy} onConfirm={leave} onClose={() => setModal(null)} />}
      {modal === "disband" && (
        <ConfirmDialog title={t("ov.disband")} message={t("ov.confirm_disband", { name: crew.name })} danger loading={busy} disabled={typed !== crew.name} onConfirm={disband} onClose={() => setModal(null)}>
          <Field label={t("f.name")}>{(id) => <Input id={id} value={typed} onChange={(e) => setTyped(e.target.value)} autoComplete="off" />}</Field>
        </ConfirmDialog>
      )}
    </div>
  );
}
