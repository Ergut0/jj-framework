import { createContext, useContext } from 'react';
import type { PanelData, Payload } from './types';

export interface PanelContextValue {
  data: PanelData;
  run: (action: string, payload?: Payload) => Promise<boolean>;
  // Oculta el panel para que el administrador vaya hasta el sitio
  place: (action: string, payload: Payload, label: string) => void;
  waypoint: (x: number, y: number) => void;
}

export const PanelContext = createContext<PanelContextValue | null>(null);

export function usePanel() {
  const value = useContext(PanelContext);
  if (!value) throw new Error('usePanel fuera de PanelContext');
  return value;
}
