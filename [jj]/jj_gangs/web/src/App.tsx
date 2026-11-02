import { useCallback, useEffect, useMemo, useState } from 'react';
import { Button, Tabs, TextInput } from '@mantine/core';
import { notifications } from '@mantine/notifications';
import { FaMagnifyingGlass, FaPlus, FaXmark } from 'react-icons/fa6';
import { FormModal } from './components/FormModal';
import { Graffitis } from './components/Graffitis';
import { Members } from './components/Members';
import { Overview } from './components/Overview';
import { Points } from './components/Points';
import { PanelContext } from './context';
import { mockAction, mockData } from './lib/mock';
import { fetchNui, isBrowser, useNuiEvent } from './lib/nui';
import type { ActionResult, PanelData, Payload } from './types';

const REFRESH_TIME = 5000;

const asList = <T,>(value: T[] | undefined) => (Array.isArray(value) ? value : []);

// Una tabla vacía de Lua puede llegar como objeto: aquí siempre son listas
function normalize(data: PanelData): PanelData {
  return {
    ...data,
    players: asList(data.players),
    gangs: asList(data.gangs).map((gang) => ({
      ...gang,
      points: asList(gang.points),
      members: asList(gang.members),
      graffitis: asList(gang.graffitis),
    })),
  };
}

const loadData = async () => {
  const data = isBrowser() ? mockData() : await fetchNui<PanelData | false>('getData');
  return data ? normalize(data) : undefined;
};

export function App() {
  const [visible, setVisible] = useState(isBrowser());
  const [data, setData] = useState<PanelData>();
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [tab, setTab] = useState<string | null>('overview');
  const [search, setSearch] = useState('');
  const [creating, setCreating] = useState(false);

  const refresh = useCallback(async () => {
    const next = await loadData();
    if (next) setData(next);
  }, []);

  const showResult = useCallback((result: ActionResult) => {
    if (result.message) {
      notifications.show({ message: result.message, color: result.ok ? 'yellow' : 'red', autoClose: 3500 });
    }
    if (result.ok && result.id) {
      setSelectedId(result.id);
      setTab('overview');
    }
  }, []);

  useNuiEvent<{ result?: ActionResult } | undefined>('open', (message) => {
    setVisible(true);
    if (message?.result) showResult(message.result);
  });
  useNuiEvent('close', () => setVisible(false));

  useEffect(() => {
    if (!visible) return;
    refresh();
    const timer = setInterval(refresh, REFRESH_TIME);
    return () => clearInterval(timer);
  }, [visible, refresh]);

  const close = useCallback(() => {
    setVisible(isBrowser());
    if (!isBrowser()) fetchNui('close');
  }, []);

  useEffect(() => {
    if (!visible) return;
    const onKeyDown = (event: KeyboardEvent) => {
      // Mantine cierra primero sus ventanas: Esc solo cierra el panel si no hay ninguna abierta
      if (event.key === 'Escape' && !document.querySelector('.mantine-Modal-content')) close();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [visible, close]);

  const run = useCallback(async (action: string, payload: Payload = {}) => {
    const result = isBrowser()
      ? mockAction(action, payload)
      : (await fetchNui<ActionResult>('action', { action, payload })) ?? { ok: false, message: 'Sin respuesta' };
    showResult(result);
    await refresh();
    return result.ok;
  }, [refresh, showResult]);

  const place = useCallback((action: string, payload: Payload, label: string) => {
    if (isBrowser()) {
      run(action, payload);
    } else {
      fetchNui('place', { action, payload, label });
    }
  }, [run]);

  const waypoint = useCallback((x: number, y: number) => {
    if (isBrowser()) {
      notifications.show({ message: 'Marcado en el mapa', color: 'yellow', autoClose: 2000 });
    } else {
      fetchNui('waypoint', { x, y });
      notifications.show({ message: 'Marcado en el mapa', color: 'yellow', autoClose: 2000 });
    }
  }, []);

  const context = useMemo(() => (data ? { data, run, place, waypoint } : null), [data, run, place, waypoint]);

  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase();
    return (data?.gangs ?? []).filter((gang) => gang.label.toLowerCase().includes(term));
  }, [data, search]);

  if (!visible || !context || !data) return null;

  const selected = data.gangs.find((gang) => gang.id === selectedId) ?? null;
  const { config } = data;
  const onlineCount = (id: number) => data.gangs.find((gang) => gang.id === id)?.members.filter((member) => member.online).length ?? 0;

  return (
    <PanelContext.Provider value={context}>
      <div className="backdrop">
        <main className="shell">
          <aside className="sidebar">
            <div className="brand">
              <span className="brand-mark">JJ</span>
              <div>
                <strong>Bandas</strong>
                <small>{data.gangs.length} en total</small>
              </div>
            </div>
            <Button fullWidth c="dark" leftSection={<FaPlus size={12} />} onClick={() => setCreating(true)}>Crear banda</Button>
            <TextInput mt="sm" placeholder="Buscar" leftSection={<FaMagnifyingGlass size={12} />} value={search} onChange={(event) => setSearch(event.currentTarget.value)} />
            <nav className="gang-list">
              {filtered.map((gang) => (
                <button key={gang.id} type="button" className={gang.id === selectedId ? 'gang-item active' : 'gang-item'} onClick={() => setSelectedId(gang.id)}>
                  <span className="dot" style={{ background: gang.hex }} />
                  <span className="gang-text">
                    <strong>{gang.label}</strong>
                    <small>{gang.members.length} miembros · {onlineCount(gang.id)} conectados</small>
                  </span>
                </button>
              ))}
              {filtered.length === 0 && <p className="empty">{data.gangs.length === 0 ? 'Todavía no hay bandas.' : 'Sin resultados.'}</p>}
            </nav>
          </aside>

          <section className="content">
            <button type="button" className="close" onClick={close} aria-label="Cerrar"><FaXmark /></button>

            {selected ? (
              <>
                <header className="page-header">
                  <span className="dot large" style={{ background: selected.hex }} />
                  <h1>{selected.label}</h1>
                </header>
                <Tabs value={tab} onChange={setTab} keepMounted={false}>
                  <Tabs.List mb="md">
                    <Tabs.Tab value="overview">Resumen</Tabs.Tab>
                    <Tabs.Tab value="points">Puntos ({selected.points.length})</Tabs.Tab>
                    <Tabs.Tab value="members">Miembros ({selected.members.length})</Tabs.Tab>
                    <Tabs.Tab value="graffitis">Grafitis ({selected.graffitis.length})</Tabs.Tab>
                  </Tabs.List>
                  <Tabs.Panel value="overview"><Overview gang={selected} onDeleted={() => setSelectedId(null)} /></Tabs.Panel>
                  <Tabs.Panel value="points"><Points gang={selected} /></Tabs.Panel>
                  <Tabs.Panel value="members"><Members gang={selected} /></Tabs.Panel>
                  <Tabs.Panel value="graffitis"><Graffitis gang={selected} /></Tabs.Panel>
                </Tabs>
              </>
            ) : (
              <div className="placeholder">
                <h1>Panel de bandas</h1>
                <p>Elige una banda de la lista o crea una nueva para gestionar su barrio, sus puntos y sus miembros.</p>
              </div>
            )}
          </section>
        </main>
      </div>

      <FormModal
        opened={creating}
        title="Crear banda"
        description="Al continuar se oculta el panel: ve al centro del barrio y pulsa E. Verás el círculo mientras caminas."
        submitLabel="Ir a colocar el barrio"
        fields={[
          { name: 'label', label: 'Nombre', required: true, maxLength: 32, placeholder: 'Ballas' },
          { name: 'color', label: 'Color', type: 'select', required: true, initial: '1', options: config.colors.map((color) => ({ value: String(color.value), label: color.label })) },
          { name: 'radius', label: 'Radio del barrio en metros', type: 'number', required: true, min: config.minRadius, max: config.maxRadius, initial: config.defaultRadius },
        ]}
        onClose={() => setCreating(false)}
        onSubmit={(values) => {
          const label = String(values.label).trim();
          if (label.length < 2) {
            notifications.show({ message: 'El nombre debe tener al menos 2 caracteres', color: 'red' });
            return false;
          }
          if (data.gangs.some((gang) => gang.label.toLowerCase() === label.toLowerCase())) {
            notifications.show({ message: 'Ya existe una banda con ese nombre', color: 'red' });
            return false;
          }
          place('create', { label, color: Number(values.color), radius: Number(values.radius) }, `Barrio de ${label}`);
        }}
      />
    </PanelContext.Provider>
  );
}
