import { useEffect, useState } from 'react';
import { ActionMenu } from './components/ActionMenu';
import { DispatchAlerts } from './components/DispatchAlerts';
import { Radar } from './components/Radar';
import { RadioHud } from './components/RadioHud';
import { useAlertsStore } from './store/alerts';
import { useTalkingStore } from './store/talking';
import { fetchNui, isBrowser, useNuiEvent } from './utils/nui';

export function App() {
  const { setAlerts } = useAlertsStore();
  const [menuOpen, setMenuOpen] = useState<any>(!!isBrowser());
  const [dispatchOpen, setDispatchOpen] = useState<any>(!!isBrowser());
  const [playerLoaded, setPlayerLoaded] = useState<any>(!!isBrowser());
  const [radarVisible, setRadarVisible] = useState<any>(!!isBrowser());
  useNuiEvent('playerLoaded', function () {
    setPlayerLoaded(true);
  });
  useNuiEvent('alternMenuAction', function () {
    setMenuOpen(!menuOpen);
  });
  useNuiEvent('radarShow', function (e) {
    setRadarVisible(e);
  });
  const { setTalking } = useTalkingStore();
  useNuiEvent('setRadioTalking', function (e) {
    setTalking(e.source, e.talking);
  });
  useEffect(() => {
    const e = (event) => {
      if (event.key === 'Escape' && menuOpen) {
        setMenuOpen(false);
        if (!isBrowser()) {
          fetchNui('closeMenu');
        }
      }
    };
    window.addEventListener('keydown', e);
    return () => window.removeEventListener('keydown', e);
  }, [menuOpen]);
  useNuiEvent('dispatchMenuShow', function (e) {
    if (e) {
      setAlerts(e);
    }
    setDispatchOpen(true);
  });
  useNuiEvent('dispatchMenuHide', function () {
    setDispatchOpen(false);
  });
  // Los mensajes enviados antes de cargar la página se pierden: el cliente los repite al recibir este aviso
  useEffect(() => {
    fetchNui('uiReady', {});
  }, []);
  if (!playerLoaded) {
    return null;
  }
  return (
    <>
      {dispatchOpen && <DispatchAlerts />}
      {dispatchOpen && <RadioHud />}
      {radarVisible && <Radar />}
      <ActionMenu active={menuOpen} />
    </>
  );
}
