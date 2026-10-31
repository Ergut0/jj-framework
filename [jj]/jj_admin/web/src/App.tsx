import { useCallback, useEffect, useMemo, useState } from 'react';
import { notifications } from '@mantine/notifications';
import { FaBan, FaCarSide, FaChartPie, FaClockRotateLeft, FaServer, FaUsers, FaWandMagicSparkles, FaXmark } from 'react-icons/fa6';
import type { IconType } from 'react-icons';
import { AdminContext } from './context';
import { closeMenu, getData, runAction } from './lib/api';
import { isBrowser, useNuiEvent } from './lib/nui';
import type { AdminData } from './types';
import { Bans } from './pages/Bans';
import { Dashboard } from './pages/Dashboard';
import { Logs } from './pages/Logs';
import { Players } from './pages/Players';
import { Self } from './pages/Self';
import { Server } from './pages/Server';
import { Vehicles } from './pages/Vehicles';

const REFRESH_TIME = 4000;

type PageId = 'dashboard' | 'players' | 'self' | 'vehicles' | 'server' | 'bans' | 'logs';

const PAGES: { id: PageId; label: string; icon: IconType }[] = [
  { id: 'dashboard', label: 'Panel', icon: FaChartPie },
  { id: 'players', label: 'Jugadores', icon: FaUsers },
  { id: 'self', label: 'Mis herramientas', icon: FaWandMagicSparkles },
  { id: 'vehicles', label: 'Vehículos', icon: FaCarSide },
  { id: 'server', label: 'Servidor', icon: FaServer },
  { id: 'bans', label: 'Baneos', icon: FaBan },
  { id: 'logs', label: 'Registros', icon: FaClockRotateLeft },
];

export function App() {
  const [visible, setVisible] = useState(isBrowser());
  const [data, setData] = useState<AdminData>();
  const [page, setPage] = useState<PageId>('dashboard');
  const [revision, setRevision] = useState(0);

  const refresh = useCallback(async () => {
    const next = await getData();
    if (next) setData(next);
  }, []);

  useNuiEvent('open', () => setVisible(true));
  useNuiEvent('close', () => setVisible(false));

  useEffect(() => {
    if (!visible) return;
    refresh();
    const timer = setInterval(refresh, REFRESH_TIME);
    return () => clearInterval(timer);
  }, [visible, refresh]);

  const close = useCallback(() => {
    setVisible(isBrowser());
    closeMenu();
  }, []);

  useEffect(() => {
    if (!visible) return;
    const onKeyDown = (event: KeyboardEvent) => {
      // Mantine cierra primero sus ventanas: Esc solo cierra el menú si no hay ninguna abierta
      if (event.key === 'Escape' && !document.querySelector('.mantine-Modal-content')) close();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [visible, close]);

  const run = useCallback(
    async (action: string, payload?: Record<string, unknown>) => {
      const result = await runAction(action, payload);
      if (result.message) {
        notifications.show({ message: result.message, color: result.ok ? 'yellow' : 'red', autoClose: 3500 });
      }
      await refresh();
      setRevision((value) => value + 1);
      return result.ok;
    },
    [refresh],
  );

  const context = useMemo(
    () => (data ? { data, run, refresh, revision, can: (action: string) => data.me.actions.includes(action) } : null),
    [data, run, refresh, revision],
  );

  if (!visible || !context) return null;

  const { me, players, maxPlayers } = context.data;

  return (
    <AdminContext.Provider value={context}>
      <div className="backdrop">
        <main className="shell">
          <aside className="sidebar">
            <div className="brand">
              <span className="brand-mark">JJ</span>
              <div>
                <strong>Administración</strong>
                <small>
                  {players.length}/{maxPlayers} conectados
                </small>
              </div>
            </div>
            <nav className="nav">
              {PAGES.map(({ id, label, icon: Icon }) => (
                <button key={id} type="button" className={page === id ? 'nav-item active' : 'nav-item'} onClick={() => setPage(id)}>
                  <Icon />
                  {label}
                </button>
              ))}
            </nav>
            <div className="profile">
              <strong>{me.name}</strong>
              <small>{me.level === 'admin' ? 'Administrador' : 'Moderador'} · ID {me.id}</small>
            </div>
          </aside>
          <section className="content">
            <button type="button" className="close" onClick={close} aria-label="Cerrar">
              <FaXmark />
            </button>
            {page === 'dashboard' && <Dashboard onNavigate={setPage} />}
            {page === 'players' && <Players />}
            {page === 'self' && <Self />}
            {page === 'vehicles' && <Vehicles />}
            {page === 'server' && <Server />}
            {page === 'bans' && <Bans />}
            {page === 'logs' && <Logs />}
          </section>
        </main>
      </div>
    </AdminContext.Provider>
  );
}
