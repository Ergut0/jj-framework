import { useEffect, useRef, useState } from "react";
import { BarChart3, Flag, Map as MapIcon, Medal, Swords, Trophy, Users } from "lucide-react";
import { Shell, type NavEntry } from "@/components/Shell";
import { CrewTag } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import type { View } from "@/lib/types";
import { Catalog } from "./Catalog";
import { Races } from "./Races";
import { Lobby } from "./Lobby";
import { Crews } from "./Crews";
import { Results } from "./Results";
import { Stats } from "./Stats";
import { Rankings } from "./Rankings";
import { clearTrackCache } from "./trackData";

const TABS = ["catalog", "races", "lobby", "crews", "results", "stats", "rankings"];

export function PlayerPanel({ canSwitch, onSwitch, onClose }: { canSwitch: boolean; onSwitch: (v: View) => void; onClose: () => void }) {
  const t = useT();
  const { state, config, extra, results } = useApp();
  const { lobby, crew } = state;
  const [tab, setTab] = useState(() => (extra?.tab && TABS.includes(extra.tab) ? extra.tab : lobby ? "lobby" : "catalog"));
  const prev = useRef({ results, lobbyId: lobby?.id ?? null, extra });

  useEffect(() => clearTrackCache(), []);

  // Cambios empujados por el servidor: resultados nuevos, pestana solicitada, sala nueva o desaparecida
  useEffect(() => {
    const p = prev.current;
    const lobbyId = lobby?.id ?? null;
    if (results && results !== p.results) setTab("results");
    else if (extra !== p.extra && extra?.tab && TABS.includes(extra.tab)) setTab(extra.tab);
    else if (lobbyId !== null && lobbyId !== p.lobbyId) setTab("lobby");
    else if (lobbyId === null && p.lobbyId !== null) setTab((cur) => (cur === "lobby" ? "races" : cur));
    prev.current = { results, lobbyId, extra };
  }, [results, lobby?.id, extra]);

  const crewsOn = config.crewsEnabled && !!crew;
  const incoming = state.challenges.incoming.length;
  const nav: NavEntry[] = [
    { id: "catalog", label: t("p.nav.catalog"), icon: <MapIcon className="size-4" /> },
    { id: "races", label: t("p.nav.races"), icon: <Flag className="size-4" /> },
    ...(lobby
      ? [
          {
            id: "lobby",
            label: t("p.nav.lobby"),
            badge: lobby.players.length,
            icon: (
              <span className="relative">
                <Users className="size-4" />
                <span className="absolute -top-1 -right-1 size-2 animate-pulse rounded-full bg-accent" />
              </span>
            ),
          },
        ]
      : []),
    ...(crewsOn ? [{ id: "crews", label: t("p.nav.crews"), icon: <Swords className="size-4" />, badge: incoming }] : []),
    { id: "results", label: t("p.nav.results"), icon: <Trophy className="size-4" /> },
    { id: "stats", label: t("p.nav.stats"), icon: <BarChart3 className="size-4" /> },
    { id: "rankings", label: t("p.nav.rankings"),     icon: <Medal className="size-4" /> },
      ];
  const active = nav.some((n) => n.id === tab) ? tab : "catalog";
  const goLobby = () => setTab("lobby");

  return (
    <Shell
      title={t("app.player")}
      subtitle={
        <span className="flex items-center gap-2">
          {state.me.name}
          {crew && <CrewTag tag={crew.tag} color={crew.color} />}
        </span>
      }
      nav={nav}
      active={active}
      onNav={setTab}
      onClose={onClose}
      view="player"
      canSwitch={canSwitch}
      onSwitch={onSwitch}
    >
      {active === "catalog" && <Catalog onEnterLobby={goLobby} />}
      {active === "races" && <Races onEnterLobby={goLobby} />}
      {active === "lobby" && lobby && <Lobby lobby={lobby} />}
      {active === "crews" && <Crews onEnterLobby={goLobby} />}
      {active === "results" && <Results />}
      {active === "stats" && <Stats />}
      {active === "rankings" && <Rankings />}
    </Shell>
  );
}
