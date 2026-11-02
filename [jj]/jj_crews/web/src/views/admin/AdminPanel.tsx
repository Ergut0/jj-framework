import { useState } from "react";
import { ScrollText, Settings as SettingsIcon, Trophy } from "lucide-react";
import { Shell } from "@/components/Shell";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import type { View } from "@/lib/types";
import { CrewList } from "./CrewList";
import { CrewDetail } from "./CrewDetail";
import { Logs } from "./Logs";
import { Settings } from "./Settings";

/** Solo se monta si el servidor confirmo `isAdmin`; cada accion se vuelve a validar en el servidor */
export function AdminPanel({ view, onSwitch, onClose }: { view: View; onSwitch: (v: View) => void; onClose: () => void }) {
  const t = useT();
  const { state } = useApp();
  const [tab, setTab] = useState("crews");
  const [selected, setSelected] = useState<number | null>(null);

  if (!state.isAdmin) return null;

  return (
    <Shell
      title={t("app.admin")}
      subtitle={state.player.name}
      nav={[
        { id: "crews", label: t("nav.crews"), icon: <Trophy className="size-4" /> },
        { id: "logs", label: t("nav.logs"), icon: <ScrollText className="size-4" /> },
        { id: "settings", label: t("nav.settings"), icon: <SettingsIcon className="size-4" /> },
      ]}
      active={tab}
      onNav={(id) => {
        setTab(id);
        setSelected(null);
      }}
      onClose={onClose}
      view={view}
      canSwitch
      onSwitch={onSwitch}
    >
      {tab === "crews" && (selected ? <CrewDetail key={selected} id={selected} onBack={() => setSelected(null)} /> : <CrewList onOpen={setSelected} />)}
      {tab === "logs" && <Logs />}
      {tab === "settings" && <Settings />}
    </Shell>
  );
}
