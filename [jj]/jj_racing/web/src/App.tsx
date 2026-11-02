import { useCallback, useEffect, useMemo, useState } from "react";
import "./index.css";
import { fetchNui, isEnvBrowser, useNuiEvent, type NuiMessage } from "@/lib/nui";
import { I18nContext, makeT } from "@/lib/i18n";
import { AppProvider } from "@/lib/store";
import type { GameState, HudShow, Locale, Lobby, OpenExtra, RaceResults, TestResult, TrackDraft, View } from "@/lib/types";
import { PlayerPanel } from "@/views/player/PlayerPanel";
import { AdminPanel } from "@/views/admin/AdminPanel";
import { Hud } from "@/views/hud/Hud";
import { startCreatorSim, startHudSim } from "@/lib/mock/hudSim";

interface OpenMessage extends NuiMessage {
  view: View;
  state: GameState;
  extra?: OpenExtra;
}

export function App() {
  const [open, setOpen] = useState(false);
  const [view, setView] = useState<View>("player");
  const [state, setState] = useState<GameState | null>(null);
  const [extra, setExtra] = useState<OpenExtra | null>(null);
  const [results, setResults] = useState<RaceResults | null>(null);
  const [draft, setDraft] = useState<TrackDraft | null>(null);
  const [testResult, setTestResult] = useState<TestResult | null>(null);
  const [locale, setLocale] = useState<Locale>(() => (new URLSearchParams(location.search).get("lang") === "en" ? "en" : "es"));

  const close = useCallback(() => {
    setOpen(false);
    void fetchNui("close");
  }, []);

  useNuiEvent<OpenMessage>("open", (msg) => {
    setState(msg.state);
    setLocale(msg.state.config.locale);
    setView(msg.view === "admin" && msg.state.isAdmin ? "admin" : "player");
    setExtra(msg.extra ?? null);
    if (msg.extra?.results) setResults(msg.extra.results);
    if (msg.extra?.draft) setDraft(msg.extra.draft);
    setTestResult(msg.extra?.testResult ?? null);
    setOpen(true);
  });
  useNuiEvent("close", () => setOpen(false));
  useNuiEvent("refresh", async () => {
    const res = await fetchNui<GameState>("getState");
    if (res.ok) setState(res.data);
  });
  // Estado de la sala empujado por el servidor (false = ya no esta en ninguna)
  useNuiEvent<NuiMessage & { lobby: Lobby | false }>("lobby", (msg) => {
    setState((s) => (s ? { ...s, lobby: msg.lobby || null } : s));
  });
  // Resultados finales: se muestran en la pestana de resultados
  useNuiEvent<NuiMessage & { results: RaceResults }>("results", (msg) => {
    setResults(msg.results);
    setState((s) => (s ? { ...s, hasResult: true } : s));
    setExtra({ tab: "results" });
  });
  // El HUD y el editor no tienen estado del juego: toman el idioma de sus propios mensajes
  useNuiEvent<NuiMessage & { data: HudShow }>("hud:show", (msg) => msg.data?.locale && setLocale(msg.data.locale));
  useNuiEvent<NuiMessage & { data: { locale?: Locale } }>("creator:hud", (msg) => msg.data?.locale && setLocale(msg.data.locale));

  // ESC cierra el panel (los modales gestionan antes su propio ESC con preventDefault)
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !e.defaultPrevented) close();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, close]);

  // Modo desarrollo en navegador: datos simulados
  useEffect(() => {
    if (!isEnvBrowser()) return;
    document.body.classList.add("dev");
    const q = new URLSearchParams(location.search);
    if (q.get("hud")) return void startHudSim();
    if (q.get("creator")) return void startCreatorSim();
    void fetchNui<GameState>("getState").then((res) => {
      if (res.ok) {
        setState(res.data);
        setLocale(res.data.config.locale);
        setView(q.get("view") === "admin" ? "admin" : "player");
        setOpen(true);
      }
    });
  }, []);

  const t = useMemo(() => makeT(locale), [locale]);

  // La vista admin solo se muestra si el servidor confirmo el permiso
  const effectiveView: View = view === "admin" && state?.isAdmin ? "admin" : "player";

  return (
    <I18nContext.Provider value={t}>
      <Hud />
      {open && state && (
        <AppProvider
          state={state}
          onState={setState}
          onClose={close}
          extra={extra}
          results={results}
          onResults={setResults}
          draft={draft}
          onDraft={setDraft}
          testResult={testResult}
          onClearTestResult={() => setTestResult(null)}
        >
          {effectiveView === "admin" ? (
            <AdminPanel onSwitch={setView} onClose={close} />
          ) : (
            <PlayerPanel canSwitch={state.isAdmin} onSwitch={setView} onClose={close} />
          )}
        </AppProvider>
      )}
    </I18nContext.Provider>
  );
}
