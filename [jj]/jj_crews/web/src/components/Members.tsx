import { useState } from "react";
import { ArrowDown, ArrowUp, Crown, UserMinus, UserPlus } from "lucide-react";
import { Badge, Button, Card, ConfirmDialog, Input, SectionTitle } from "./ui";
import type { CrewCtx } from "./ctx";
import { useT } from "@/lib/i18n";
import { useApp } from "@/lib/store";
import { date } from "@/lib/format";
import type { Member } from "@/lib/types";

type Pending = { kind: "kick" | "transfer"; member: Member } | null;

export function Members({ ctx }: { ctx: CrewCtx }) {
  const t = useT();
  const { config, state } = useApp();
  const { crew } = ctx;
  const [target, setTarget] = useState("");
  const [busy, setBusy] = useState<string | null>(null);
  const [pending, setPending] = useState<Pending>(null);

  const assignable = crew.ranks.filter((r) => !r.isLeader && r.level < ctx.level).sort((a, b) => a.level - b.level);
  const myCid = state.player.citizenid;

  const run = async (key: string, op: string, payload: Record<string, unknown>, okMsg: string) => {
    setBusy(key);
    const res = await ctx.run(op, payload, okMsg);
    setBusy(null);
    if (res.ok) await ctx.refresh();
    return res.ok;
  };

  const invite = async (e: React.FormEvent) => {
    e.preventDefault();
    const value = target.trim();
    if (!value) return;
    const payload = ctx.admin ? { citizenid: value } : { targetId: Number(value) };
    if (await run("invite", "invite", payload, t(ctx.admin ? "adm.saved" : "mem.invite_sent"))) setTarget("");
  };

  const shift = (m: Member, dir: 1 | -1) => {
    const next = dir === 1 ? assignable.find((r) => r.level > m.rankLevel) : [...assignable].reverse().find((r) => r.level < m.rankLevel);
    if (next) void run(`${m.citizenid}:rank`, "setRank", { citizenid: m.citizenid, rankId: next.id }, t("mem.rank_changed"));
  };

  const confirm = async () => {
    if (!pending) return;
    const { kind, member } = pending;
    const ok = kind === "kick"
      ? await run("confirm", "kick", { citizenid: member.citizenid }, t("mem.kicked"))
      : await run("confirm", "transferLeader", { citizenid: member.citizenid }, t("mem.transferred"));
    if (ok) setPending(null);
  };

  return (
    <div className="flex flex-col gap-4">
      {ctx.can("invite") && (
        <Card>
          <SectionTitle>{t(ctx.admin ? "adm.add_member" : "mem.invite")}</SectionTitle>
          <form onSubmit={invite} className="flex gap-2">
            <Input
              value={target}
              onChange={(e) => setTarget(e.target.value)}
              placeholder={t(ctx.admin ? "adm.citizenid" : "mem.invite_id")}
              inputMode={ctx.admin ? "text" : "numeric"}
              maxLength={50}
              aria-label={t(ctx.admin ? "adm.citizenid" : "mem.invite_id")}
            />
            <Button type="submit" loading={busy === "invite"} disabled={!target.trim()}>
              <UserPlus className="size-4" />
              {t(ctx.admin ? "add" : "mem.invite")}
            </Button>
          </form>
        </Card>
      )}

      <Card>
        <SectionTitle action={<span className="text-xs text-mute">{t("mem.count", { n: crew.members.length, max: config.maxMembers })}</span>}>
          {t("nav.members")}
        </SectionTitle>
        <ul className="flex flex-col divide-y divide-line">
          {crew.members.map((m) => {
            const rank = crew.ranks.find((r) => r.id === m.rankId);
            const manageable = !m.isLeader && m.citizenid !== myCid && (ctx.admin || ctx.level > m.rankLevel);
            const canShift = manageable && ctx.can("setRank");
            const canUp = canShift && assignable.some((r) => r.level > m.rankLevel);
            const canDown = canShift && assignable.some((r) => r.level < m.rankLevel);
            return (
              <li key={m.citizenid} className="flex flex-wrap items-center gap-3 py-3">
                <span className={`size-2 shrink-0 rounded-full ${m.online ? "bg-ok shadow-[0_0_8px_var(--color-ok)]" : "bg-line"}`} title={t(m.online ? "mem.online" : "mem.offline")} />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 truncate font-semibold">
                    {m.name}
                    {m.citizenid === myCid && <span className="text-xs font-normal text-mute">({t("you")})</span>}
                    {m.isLeader && <Crown className="size-4 text-warn" />}
                  </div>
                  <div className="text-xs text-mute">{t("mem.joined", { date: date(m.joinedAt, config.locale) })}</div>
                </div>
                <Badge color={m.isLeader ? "#f59e0b" : undefined}>{rank?.name ?? "-"}</Badge>
                <div className="flex gap-1">
                  {canUp && (
                    <Button variant="ghost" size="sm" loading={busy === `${m.citizenid}:rank`} onClick={() => shift(m, 1)} title={t("mem.promote")} aria-label={t("mem.promote")}>
                      <ArrowUp className="size-4" />
                    </Button>
                  )}
                  {canDown && (
                    <Button variant="ghost" size="sm" loading={busy === `${m.citizenid}:rank`} onClick={() => shift(m, -1)} title={t("mem.demote")} aria-label={t("mem.demote")}>
                      <ArrowDown className="size-4" />
                    </Button>
                  )}
                  {ctx.isLeader && !m.isLeader && m.citizenid !== myCid && (
                    <Button variant="outline" size="sm" onClick={() => setPending({ kind: "transfer", member: m })} title={t(ctx.admin ? "adm.make_leader" : "mem.transfer")} aria-label={t(ctx.admin ? "adm.make_leader" : "mem.transfer")}>
                      <Crown className="size-4" />
                    </Button>
                  )}
                  {manageable && ctx.can("kick") && (
                    <Button variant="danger" size="sm" onClick={() => setPending({ kind: "kick", member: m })} title={t("mem.kick")} aria-label={t("mem.kick")}>
                      <UserMinus className="size-4" />
                    </Button>
                  )}
                </div>
              </li>
            );
          })}
        </ul>
      </Card>

      {pending && (
        <ConfirmDialog
          title={t(pending.kind === "kick" ? "mem.kick" : "mem.transfer")}
          message={t(pending.kind === "kick" ? "mem.confirm_kick" : "mem.confirm_transfer", { name: pending.member.name })}
          danger={pending.kind === "kick"}
          loading={busy === "confirm"}
          onConfirm={confirm}
          onClose={() => setPending(null)}
        />
      )}
    </div>
  );
}
