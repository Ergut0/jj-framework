import { useCallback, useEffect, useState } from 'react';
import city from './assets/city.webp';
import { fetchNui, isBrowser, useNuiEvent } from './nui';
import { mockData } from './mock';
import { Home } from './pages/Home';
import { Businesses } from './pages/Businesses';
import { BusinessDetail } from './pages/BusinessDetail';
import { BusinessEdit } from './pages/BusinessEdit';
import { Events } from './pages/Events';
import type { Business, Route, Status, TabletData, TabletEvent } from './types';

const parseRoute = (path: string): Route => {
  if (path === '/tablet/events') return { page: 'events' };

  const job = path.match(/^\/tablet\/businesses\/([^/]+)$/);
  if (job) return { page: 'business', job: job[1] };

  return { page: 'home' };
};

export function App() {
  const [data, setData] = useState<TabletData | null>(null);
  const [history, setHistory] = useState<Route[]>([{ page: 'home' }]);
  const route = history[history.length - 1];

  const navigate = useCallback((next: Route) => setHistory((current) => [...current, next]), []);
  const back = useCallback(() => setHistory((current) => (current.length > 1 ? current.slice(0, -1) : current)), []);

  const close = useCallback(() => {
    setData(null);
    fetchNui('tablet:close');
  }, []);

  const open = useCallback((next: TabletData) => {
    setHistory([{ page: 'home' }]);
    setData({ ...next, jobs: next.jobs ?? [], events: next.events ?? [] });
  }, []);

  useNuiEvent<TabletData>('tablet:open', open);
  useNuiEvent<string>('tablet:setRoute', useCallback((path) => setHistory([{ page: 'home' }, parseRoute(path)]), []));
  useNuiEvent<TabletEvent[]>(
    'tablet:updateEvents',
    useCallback((events) => setData((current) => current && { ...current, events: events ?? [] }), []),
  );
  useNuiEvent<Business>(
    'tablet:updateJob',
    useCallback(
      (job) =>
        setData((current) => current && { ...current, jobs: current.jobs.map((b) => (b.name === job.name ? job : b)) }),
      [],
    ),
  );
  useNuiEvent<{ name: string; status: Status }>(
    'tablet:updateJobStatus',
    useCallback(
      ({ name, status }) =>
        setData((current) => current && { ...current, jobs: current.jobs.map((b) => (b.name === name ? { ...b, status } : b)) }),
      [],
    ),
  );

  useEffect(() => {
    if (isBrowser()) open(mockData());
  }, [open]);

  useEffect(() => {
    if (!data) return;

    const onKey = (event: KeyboardEvent) => {
      // Con una ventana abierta, Escape solo cierra esa ventana
      if (event.key === 'Escape' && !document.querySelector('.mantine-Modal-content')) close();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [data, close]);

  if (!data) return null;

  // Llamar o marcar la ruta cierra la tablet para que se vea el juego
  const props = { data, navigate, back, close };

  return (
    <main className="tablet">
      <div className="tablet-background" style={{ backgroundImage: `url(${city})` }} />
      {route.page === 'home' && <Home navigate={navigate} />}
      {route.page === 'businesses' && <Businesses {...props} category={route.category} />}
      {route.page === 'business' && <BusinessDetail {...props} job={route.job} />}
      {route.page === 'edit' && <BusinessEdit key={route.job} {...props} job={route.job} />}
      {route.page === 'events' && <Events {...props} />}
    </main>
  );
}
