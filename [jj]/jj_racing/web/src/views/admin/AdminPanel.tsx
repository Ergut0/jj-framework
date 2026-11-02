import { useEffect, useState, type ReactNode } from "react";
import { CalendarClock, ClipboardCheck, Flag, PencilRuler, Route, ScrollText, SlidersHorizontal } from "lucide-react";
import { Shell, type NavEntry } from "@/components/Shell";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import type { View } from "@/lib/types";
import { Tracks } from "./Tracks";
import { TrackCreator } from "./TrackCreator";
import { ActiveRaces } from "./ActiveRaces";
import { Events } from "./Events";
import { ResultsReview } from "./ResultsReview";
import { Settings } from "./Settings";
import { Logs } from "./Logs";
import { TestBanner } from "./TrackModals";

const TABS = ["tracks", "creator", "races", "events", "review", "settings", "logs"] as const;
type Tab = (typeof TABS)[number];
const isTab = (v: string | undefined): v is Tab => !!v && (TABS as readonly string[]).includes(v);

const ICONS: Record<Tab, ReactNode> = {
  tracks: <Route className="size-5" />,
  creator: <PencilRuler className="size-5" />,
  races: <Flag className="size-5" />,
  events: <CalendarClock className="size-5" />,
  review: <ClipboardCheck className="size-5" />,
  settings: <SlidersHorizontal className="size-5" />,
  logs: <ScrollText className="size-5" />,
};

export function AdminPanel({ onSwitch, onClose }: { onSwitch: (v: View) => void; onClose: () => void }) {
  const t = useT();
  const { extra, state, testResult, clearTestResult } = useApp();
  const [tab, setTab] = useState<Tab>(() => (isTab(extra?.tab) ? extra.tab : "tracks"));

  // Al volver del editor del mundo o de una prueba, el servidor indica la pestana
  useEffect(() => {
    if (isTab(extra?.tab)) setTab(extra.tab);
  }, [extra]);

  const nav: NavEntry[] = TABS.map((id) => ({ id, label: t(`a.nav.${id}`), icon: ICONS[id] }));

  return (
    <Shell
      title={t("a.title")}
      subtitle={state.me.name}
      nav={nav}
      active={tab}
      onNav={(id) => isTab(id) && setTab(id)}
      onClose={onClose}
      view="admin"
      canSwitch
      onSwitch={onSwitch}
    >
      {testResult && (tab === "tracks" || tab === "creator") && <TestBanner result={testResult} onClear={clearTestResult} />}
      {tab === "tracks" && <Tracks onOpenCreator={() => setTab("creator")} />}
      {tab === "creator" && <TrackCreator />}
      {tab === "races" && <ActiveRaces />}
      {tab === "events" && <Events />}
      {tab === "review" && <ResultsReview />}
      {tab === "settings" && <Settings />}
      {tab === "logs" && <Logs />}
    </Shell>
  );
}
