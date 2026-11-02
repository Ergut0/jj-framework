import { useState } from "react";
import { Flag, Inbox, Plus } from "lucide-react";
import { Button, Card, Emblem, Empty, SectionTitle } from "@/components/ui";
import { IdentityForm } from "@/components/IdentityForm";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { money } from "@/lib/format";
import type { Invite } from "@/lib/types";

export function InviteList({ invites }: { invites: Invite[] }) {
  const t = useT();
  const { call, reload } = useApp();
  const [busy, setBusy] = useState<number | null>(null);

  const respond = async (inv: Invite, accept: boolean) => {
    setBusy(inv.id);
    const res = await call("respondInvite", { inviteId: inv.id, accept }, t(accept ? "invites.joined" : "invites.rejected"));
    setBusy(null);
    if (res.ok || accept) await reload();
  };

  if (!invites.length) return <Empty text={t("invites.empty")} />;
  return (
    <ul className="flex flex-col gap-3">
      {invites.map((inv) => (
        <li key={inv.id} className="animate-rise flex flex-wrap items-center gap-4 rounded-lg border border-line bg-panel2/60 p-3">
          <Emblem color={inv.color} tag={inv.crewTag} logo={inv.logo} />
          <div className="min-w-0 flex-1">
            <div className="racing-title truncate" style={{ color: inv.color }}>
              [{inv.crewTag}] {inv.crewName}
            </div>
            <div className="text-xs text-mute">
              {t("invites.from", { name: inv.invitedBy })} · {t("invites.members", { n: inv.members })}
            </div>
          </div>
          <div className="flex gap-2">
            <Button variant="ghost" size="sm" disabled={busy === inv.id} onClick={() => respond(inv, false)}>
              {t("invites.reject")}
            </Button>
            <Button size="sm" loading={busy === inv.id} onClick={() => respond(inv, true)}>
              {t("invites.accept")}
            </Button>
          </div>
        </li>
      ))}
    </ul>
  );
}

/** Vista para jugadores sin crew: fundar uno o aceptar invitaciones */
export function NoCrew() {
  const t = useT();
  const { state, config, call, reload } = useApp();
  const [tab, setTab] = useState<"create" | "invites">(state.invites.length ? "invites" : "create");

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-5">
      <div className="flex flex-col items-center gap-2 pt-2 text-center">
        <Flag className="size-10 text-accent" />
        <h2 className="racing-title text-2xl">{t("nocrew.title")}</h2>
        <p className="text-sm text-mute">{t("nocrew.sub")}</p>
      </div>

      <div className="flex gap-2 self-center">
        <Button variant={tab === "create" ? "primary" : "ghost"} size="sm" onClick={() => setTab("create")}>
          <Plus className="size-4" /> {t("create.title")}
        </Button>
        <Button variant={tab === "invites" ? "primary" : "ghost"} size="sm" onClick={() => setTab("invites")}>
          <Inbox className="size-4" /> {t("invites.title")} {state.invites.length > 0 && `(${state.invites.length})`}
        </Button>
      </div>

      {tab === "create" ? (
        <Card>
          <SectionTitle action={<span className="text-xs text-mute">{t("create.cost")}: <b className="text-ink">{money(config.createCost, config.currency)}</b></span>}>
            {t("create.title")}
          </SectionTitle>
          <IdentityForm
            mode="full"
            submitLabel={t("create.submit")}
            onSubmit={async (v) => {
              const res = await call("createCrew", v, t("create.ok"));
              if (res.ok) await reload();
            }}
          />
        </Card>
      ) : (
        <Card>
          <SectionTitle>{t("invites.title")}</SectionTitle>
          <InviteList invites={state.invites} />
        </Card>
      )}
    </div>
  );
}
