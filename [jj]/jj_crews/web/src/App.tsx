import { useCallback, useEffect, useMemo, useState } from "react";
import "./index.css";
import { fetchNui, isEnvBrowser, useNuiEvent } from "@/lib/nui";
import { I18nContext, makeT } from "@/lib/i18n";
import { AppProvider } from "@/lib/store";
import type { GameState, View } from "@/lib/types";
import { PlayerPanel } from "@/views/player/PlayerPanel";
import { AdminPanel } from "@/views/admin/AdminPanel";

export function App() {
  const [open, setOpen] = useState(false);
  const [view, setView] = useState<View>("player");
  const [state, setState] = useState<GameState | null>(null);

  const close = useCallback(() => {
    setOpen(false);
    void fetchNui("close");
  }, []);

  useNuiEvent("open", (msg) => {
    setState(msg.state as GameState);
    setView(msg.view === "admin" ? "admin" : "player");
    setOpen(true);
  });
  useNuiEvent("close", () => setOpen(false));
  useNuiEvent("refresh", async () => {
    const res = await fetchNui<GameState>("getState");
    if (res.ok) setState(res.data);
  });

  // ESC cierra la NUI (los modales gestionan antes su propio ESC con preventDefault)
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !e.defaultPrevented) close();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, close]);

  // Modo desarrollo en navegador: abre automaticamente con datos mock
  useEffect(() => {
    if (!isEnvBrowser()) return;
    document.body.classList.add("dev");
    const wanted = new URLSearchParams(location.search).get("view") === "admin" ? "admin" : "player";
    void fetchNui<GameState>("getState").then((res) => {
      if (res.ok) {
        setState(res.data);
        setView(wanted);
        setOpen(true);
      }
    });
  }, []);

  const t = useMemo(() => makeT(state?.config.locale ?? "es"), [state?.config.locale]);

  if (!open || !state) return null;

  // La vista admin solo se muestra si el servidor confirmo el permiso
  const effectiveView: View = view === "admin" && state.isAdmin ? "admin" : "player";

  return (
    <I18nContext.Provider value={t}>
      <AppProvider state={state} onState={setState} onClose={close}>
        {effectiveView === "admin" ? (
          <AdminPanel view={effectiveView} onSwitch={setView} onClose={close} />
        ) : (
          <PlayerPanel view={effectiveView} canSwitch={state.isAdmin} onSwitch={setView} onClose={close} />
        )}
      </AppProvider>
    </I18nContext.Provider>
  );
}
