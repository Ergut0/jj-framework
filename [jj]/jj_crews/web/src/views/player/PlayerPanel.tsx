import { useState } from "react";
import { Activity as ActivityIcon, Banknote, Flag, Inbox, LayoutDashboard, ListOrdered, Medal, Users } from "lucide-react";
import { Shell, type NavEntry } from "@/components/Shell";
import { useCrewCtx } from "@/components/ctx";
import { Members } from "@/components/Members";
import { Ranks } from "@/components/Ranks";
import { Card, SectionTitle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import type { Crew, View } from "@/lib/types";
import { NoCrew, InviteList } from "./NoCrew";
import { Overview } from "./Overview";
import { Bank } from "./Bank";
import { Activity, Ranking } from "./Lists";

function useCrewTabs({ crew }: { crew: Crew }) {
  const t = useT();
  const { state } = useApp();
  const ctx = useCrewCtx(crew, false);
  const [tab, setTab] = useState("overview");
  return { ctx, tab, setTab, t, state };
}

export function PlayerPanel({ view, canSwitch, onSwitch, onClose }: { view: View; canSwitch: boolean; onSwitch: (v: View) => void; onClose: () => void }) {
  const { state } = useApp();
  const crew = state.crew ?? null;
  return crew ? (
    <WithCrew crew={crew} view={view} canSwitch={canSwitch} onSwitch={onSwitch} onClose={onClose} />
  ) : (
    <WithoutCrew view={view} canSwitch={canSwitch} onSwitch={onSwitch} onClose={onClose} />
  );
}

interface Props {
  view: View;
  canSwitch: boolean;
  onSwitch: (v: View) => void;
  onClose: () => void;
}

function WithoutCrew({ view, canSwitch, onSwitch, onClose }: Props) {
  const t = useT();
  const { state } = useApp();
  return (
    <Shell
      title={t("app.player")}
      subtitle={state.player.name}
      nav={[{ id: "start", label: t("nocrew.title"), icon: <Flag className="size-4" /> }]}
      active="start"
      onNav={() => {}}
      onClose={onClose}
      view={view}
      canSwitch={canSwitch}
      onSwitch={onSwitch}
    >
      <NoCrew />
    </Shell>
  );
}

function WithCrew({ crew, view, canSwitch, onSwitch, onClose }: Props & { crew: Crew }) {
  const { ctx, tab, setTab, t, state } = useCrewTabs({ crew });
  const nav: NavEntry[] = [
    { id: "overview", label: t("nav.overview"), icon: <LayoutDashboard className="size-4" /> },
    { id: "members", label: t("nav.members"), icon: <Users className="size-4" /> },
    { id: "ranks", label: t("nav.ranks"), icon: <Medal className="size-4" /> },
    { id: "bank", label: t("nav.bank"), icon: <Banknote className="size-4" /> },
    { id: "activity", label: t("nav.activity"), icon: <ActivityIcon className="size-4" /> },
    { id: "ranking", label: t("nav.ranking"), icon: <ListOrdered className="size-4" /> },
    ...(state.invites.length ? [{ id: "invites", label: t("nav.invites"), icon: <Inbox className="size-4" />, badge: state.invites.length }] : []),
  ];

  return (
    <Shell
      title={<span style={{ color: crew.color }}>[{crew.tag}] {crew.name}</span>}
      subtitle={state.player.name}
      nav={nav}
      active={tab}
      onNav={setTab}
      onClose={onClose}
      view={view}
      canSwitch={canSwitch}
      onSwitch={onSwitch}
    >
      {tab === "overview" && <Overview ctx={ctx} />}
      {tab === "members" && <Members ctx={ctx} />}
      {tab === "ranks" && <Ranks ctx={ctx} />}
      {tab === "bank" && <Bank ctx={ctx} />}
      {tab === "activity" && <Activity />}
      {tab === "ranking" && <Ranking />}
      {tab === "invites" && (
        <Card>
          <SectionTitle>{t("invites.title")}</SectionTitle>
          <InviteList invites={state.invites} />
        </Card>
      )}
    </Shell>
  );
}
