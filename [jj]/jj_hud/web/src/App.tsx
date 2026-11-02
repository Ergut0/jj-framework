import { useEffect } from 'react';
import { AnimatePresence, motion } from 'motion/react';
import { CarHud } from './components/CarHud';
import { Clock } from './components/Clock';
import { PlayerHud } from './components/PlayerHud';
import type { HudState, VehicleData } from './store';
import { useHud } from './store';

declare global {
  interface Window {
    invokeNative?: unknown;
  }
}

const isBrowser = () => !window.invokeNative;

// En el navegador no hay juego: datos de ejemplo que se mueven, y C para subir o bajar del coche
function useBrowserDemo() {
  const update = useHud((state) => state.update);

  useEffect(() => {
    if (!isBrowser()) return;
    document.documentElement.classList.add('browser');

    let tick = 0;
    let inside = true;
    update({ visible: true, health: 72, armour: 40, hunger: 58, thirst: 33, stamina: 60, oxygen: 100 });

    const build = (): VehicleData => {
      const rpm = Math.round(50 + 45 * Math.sin(tick / 6));
      return {
        speed: Math.round(95 + 70 * Math.sin(tick / 12)), unit: 'KM/H', rpm, gear: String(1 + Math.floor((tick / 10) % 6)), kind: 'land',
        fuel: 64, engine: 86, running: true, lights: 1, locked: false, hasSeatbelt: true, belted: tick % 40 < 20,
        street: 'Vespucci Boulevard', direction: 'NO',
      };
    };

    const timer = setInterval(() => {
      tick += 1;
      update({ vehicle: inside ? build() : null, microphoneOn: tick % 30 < 8 });
    }, 200);
    const onKey = (event: KeyboardEvent) => {
      if (event.key.toLowerCase() === 'c') inside = !inside;
    };
    window.addEventListener('keydown', onKey);
    return () => {
      clearInterval(timer);
      window.removeEventListener('keydown', onKey);
    };
  }, [update]);
}

export function App() {
  const update = useHud((state) => state.update);
  const visible = useHud((state) => state.visible);
  const mapOpened = useHud((state) => state.mapOpened);
  const vehicle = useHud((state) => state.vehicle);

  useBrowserDemo();

  useEffect(() => {
    const listener = (event: MessageEvent<{ type?: string; data: Partial<HudState> | VehicleData | false }>) => {
      if (event.data.type === 'updateState') {
        update(event.data.data as Partial<HudState>);
      } else if (event.data.type === 'updateVehicle') {
        update({ vehicle: (event.data.data as VehicleData) || null });
      }
    };
    window.addEventListener('message', listener);
    return () => window.removeEventListener('message', listener);
  }, [update]);

  const show = visible && !mapOpened;

  return (
    <main>
      <AnimatePresence>
        {show && (
          <motion.div key="logo" className="logo-group" initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.8 }} transition={{ duration: 0.3 }}>
            <img className="logo" src="./logo.png" alt="Logo" />
            <Clock />
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence>{show && <PlayerHud key="player" />}</AnimatePresence>
      <AnimatePresence>{show && vehicle && <CarHud key="car" vehicle={vehicle} />}</AnimatePresence>
    </main>
  );
}
