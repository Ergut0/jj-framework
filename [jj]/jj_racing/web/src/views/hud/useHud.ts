import { useCallback, useEffect, useRef, useState } from "react";
import { useNuiEvent, type NuiMessage } from "@/lib/nui";
import type { HudProgress, HudShow, HudStandings } from "@/lib/types";
import { RaceClock } from "./clock";

export interface FinishInfo {
  time: number;
  order?: number;
  bestLap?: number;
}

export interface HudState {
  visible: boolean;
  show: HudShow | null;
  started: boolean;
  countdown: number | null;
  go: boolean;
  progress: HudProgress | null;
  standings: HudStandings | null;
  finish: FinishInfo | null;
  out: string | null;
  /** se incrementa en cada pit stop para reiniciar el aviso */
  pit: number;
}

const INITIAL: HudState = {
  visible: false,
  show: null,
  started: false,
  countdown: null,
  go: false,
  progress: null,
  standings: null,
  finish: null,
  out: null,
  pit: 0,
};

type Msg<T> = NuiMessage & { data: T };

const GO_MS = 1200;
const PIT_MS = 3200;

/** Escucha los hud:* de Lua. El reloj vive fuera del estado de React para no renderizar por frame. */
export function useHud() {
  const [state, setState] = useState<HudState>(INITIAL);
  const [pitVisible, setPitVisible] = useState(false);
  const clock = useRef(new RaceClock()).current;
  const timers = useRef<{ go?: ReturnType<typeof setTimeout>; pit?: ReturnType<typeof setTimeout> }>({});

  const clearTimers = useCallback(() => {
    clearTimeout(timers.current.go);
    clearTimeout(timers.current.pit);
  }, []);
  useEffect(() => clearTimers, [clearTimers]);

  useNuiEvent<Msg<HudShow>>("hud:show", ({ data }) => {
    clearTimers();
    clock.reset();
    setPitVisible(false);
    setState({ ...INITIAL, visible: true, show: data });
  });

  useNuiEvent<Msg<{ n: number }>>("hud:countdown", ({ data }) => {
    setState((s) => (s.visible ? { ...s, countdown: data.n } : s));
  });

  useNuiEvent("hud:go", () => {
    clock.start();
    clearTimeout(timers.current.go);
    timers.current.go = setTimeout(() => setState((s) => ({ ...s, go: false })), GO_MS);
    setState((s) => (s.visible ? { ...s, started: true, countdown: null, go: true } : s));
  });

  useNuiEvent<Msg<HudProgress>>("hud:progress", ({ data }) => {
    clock.sync(data.total, data.lapTime != null);
    setState((s) => (s.visible ? { ...s, progress: data } : s));
  });

  useNuiEvent<Msg<HudStandings>>("hud:standings", ({ data }) => {
    setState((s) => (s.visible ? { ...s, standings: data } : s));
  });

  useNuiEvent<Msg<FinishInfo>>("hud:finish", ({ data }) => {
    clock.freeze(data.time);
    setState((s) => (s.visible ? { ...s, finish: data, out: null } : s));
  });

  useNuiEvent<Msg<{ reason?: string }>>("hud:out", ({ data }) => {
    clock.freeze();
    setState((s) => (s.visible ? { ...s, out: data.reason ?? "", finish: null } : s));
  });

  useNuiEvent("hud:pit", () => {
    clearTimeout(timers.current.pit);
    timers.current.pit = setTimeout(() => setPitVisible(false), PIT_MS);
    setPitVisible(true);
    setState((s) => ({ ...s, pit: s.pit + 1 }));
  });

  useNuiEvent("hud:hide", () => {
    clearTimers();
    clock.reset();
    setPitVisible(false);
    setState(INITIAL);
  });

  return { state, clock, pitVisible };
}
