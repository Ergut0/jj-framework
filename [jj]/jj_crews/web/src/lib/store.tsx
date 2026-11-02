import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from "react";
import { CheckCircle2, Info, XCircle } from "lucide-react";
import { fetchNui } from "./nui";
import { useT } from "./i18n";
import type { GameConfig, GameState, NuiResponse } from "./types";

type ToastKind = "ok" | "error" | "info";
interface Toast {
  id: number;
  kind: ToastKind;
  text: string;
}

export interface AppContextValue {
  state: GameState;
  config: GameConfig;
  reload: () => Promise<void>;
  toast: (text: string, kind?: ToastKind) => void;
  /** Llama a Lua; muestra un toast de error si falla y de exito si se indica okMsg */
  call: <T = unknown>(action: string, data?: unknown, okMsg?: string) => Promise<NuiResponse<T>>;
  close: () => void;
}

const AppContext = createContext<AppContextValue | null>(null);

export function useApp(): AppContextValue {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error("useApp fuera de AppProvider");
  return ctx;
}

const toastIcon = { ok: CheckCircle2, error: XCircle, info: Info } as const;
const toastColor = { ok: "text-ok", error: "text-bad", info: "text-accent" } as const;

export function AppProvider({
  state,
  onState,
  onClose,
  children,
}: {
  state: GameState;
  onState: (s: GameState) => void;
  onClose: () => void;
  children: ReactNode;
}) {
  const t = useT();
  const [toasts, setToasts] = useState<Toast[]>([]);
  const seq = useRef(0);
  const mounted = useRef(true);
  useEffect(() => () => void (mounted.current = false), []);

  const toast = useCallback((text: string, kind: ToastKind = "info") => {
    const id = ++seq.current;
    setToasts((l) => [...l.slice(-3), { id, kind, text }]);
    setTimeout(() => mounted.current && setToasts((l) => l.filter((x) => x.id !== id)), 4200);
  }, []);

  const reload = useCallback(async () => {
    const res = await fetchNui<GameState>("getState");
    if (res.ok) onState(res.data);
  }, [onState]);

  const call = useCallback(
    async <T,>(action: string, data: unknown = {}, okMsg?: string) => {
      const res = await fetchNui<T>(action, data);
      if (!res.ok) toast(res.error === "timeout" ? t("error.timeout") : res.error || t("error.generic"), "error");
      else if (okMsg) toast(okMsg, "ok");
      return res;
    },
    [toast, t],
  );

  return (
    <AppContext.Provider value={{ state, config: state.config, reload, toast, call, close: onClose }}>
      {children}
      <div className="pointer-events-none fixed right-5 bottom-5 z-[100] flex w-80 max-w-[calc(100vw-2.5rem)] flex-col gap-2">
        {toasts.map((x) => {
          const Icon = toastIcon[x.kind];
          return (
            <div
              key={x.id}
              role="status"
              className="animate-slide flex items-start gap-3 rounded-lg border border-line bg-panel2/95 px-4 py-3 text-sm shadow-xl backdrop-blur"
            >
              <Icon className={`mt-0.5 size-4 shrink-0 ${toastColor[x.kind]}`} />
              <span>{x.text}</span>
            </div>
          );
        })}
      </div>
    </AppContext.Provider>
  );
}
