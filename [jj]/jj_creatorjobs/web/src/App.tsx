import { useCallback, useEffect, useState } from 'react';
import { TbBuildingStore, TbWorld, TbX } from 'react-icons/tb';
import { FormModal, type Field } from './components/Form';
import { GlobalTeleports } from './components/GlobalTeleports';
import { JobView } from './components/JobView';
import { Sidebar } from './components/Sidebar';
import { api, isBrowser } from './nui';
import type { Job, Panel } from './types';
import { asList } from './types';

const CREATE_JOB_FIELDS: Field[] = [
  { key: 'jobLabel', label: 'Nombre visible', type: 'text', required: true, placeholder: 'Burger Shot' },
  { key: 'job', label: 'Nombre interno', type: 'text', required: true, placeholder: 'burgershot', hint: 'Solo letras, números y guiones bajos. No se puede cambiar después.', pattern: /^[A-Za-z0-9_]+$/ },
];

export function App() {
  const [visible, setVisible] = useState(isBrowser());
  const [panel, setPanel] = useState<Panel | null>(null);
  const [denied, setDenied] = useState(false);
  const [selected, setSelected] = useState<string | 'global' | null>(null);
  const [job, setJob] = useState<Job | null>(null);
  const [creating, setCreating] = useState(false);

  const close = useCallback(() => {
    setVisible(false);
    if (!isBrowser()) api.close();
  }, []);

  const loadPanel = useCallback(async () => {
    const result = await api.getPanel<Panel>();
    if (!result) {
      setDenied(true);
      setPanel(null);
      return null;
    }
    setDenied(false);
    setPanel(result);
    if (result.job) {
      setSelected(result.job.name);
      setJob(result.job);
    }
    return result;
  }, []);

  const loadJob = useCallback(async (name: string) => {
    const result = await api.getJob<Job>(name);
    setJob(result || null);
  }, []);

  useEffect(() => {
    const onMessage = (event: MessageEvent<{ action?: string; data?: unknown }>) => {
      if (event.data.action === 'setVisible') setVisible(event.data.data === true);
    };
    window.addEventListener('message', onMessage);
    return () => window.removeEventListener('message', onMessage);
  }, []);

  useEffect(() => {
    if (visible) loadPanel();
  }, [visible, loadPanel]);

  useEffect(() => {
    if (!visible) return;
    if (selected && selected !== 'global' && panel?.admin) loadJob(selected);
  }, [selected, visible, panel?.admin, loadJob]);

  // ESC cierra el panel, salvo si hay una ventana abierta encima: entonces solo se cierra esa ventana
  useEffect(() => {
    if (!visible) return;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && !document.querySelector('[role="dialog"]')) close();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [visible, close]);

  // Tras cada cambio se vuelven a pedir los datos: el servidor ya ha terminado de guardarlos
  const run = useCallback(async (name: string, data: Record<string, unknown>) => {
    await api.action(name, data);
    if (panel?.admin) await loadPanel();
    if (selected && selected !== 'global') {
      if (panel?.admin) await loadJob(selected);
      else await loadPanel();
    }
  }, [panel?.admin, selected, loadJob, loadPanel]);

  const deleteJob = useCallback(async (target: Job) => {
    await api.action('deleteJob', { id: target.id });
    setSelected(null);
    setJob(null);
    await loadPanel();
  }, [loadPanel]);

  if (!visible) return null;

  const isAdmin = panel?.admin === true;
  const jobs = asList(panel?.jobs);

  return (
    <main className="backdrop">
      <div className={`shell${isAdmin ? '' : ' shell-boss'}`}>
        {isAdmin && (
          <Sidebar
            jobs={jobs}
            selected={selected}
            onSelect={(name) => {
              setJob(null);
              setSelected(name);
            }}
            onCreate={() => setCreating(true)}
            onGlobal={() => setSelected('global')}
          />
        )}

        <section className="content">
          <button className="close" type="button" onClick={close} aria-label="Cerrar">
            <TbX size={18} />
          </button>

          {denied && (
            <div className="empty-screen">
              <TbBuildingStore size={42} />
              <h2>No tienes acceso</h2>
              <p>Este panel es para administradores y para el jefe de cada empresa.</p>
            </div>
          )}

          {!denied && selected === 'global' && <GlobalTeleports onAction={async (name, data) => { await api.action(name, data); }} />}

          {!denied && selected !== 'global' && job && panel && (
            <JobView job={job} admin={isAdmin} maxLevel={panel.maxLevel} maxExp={panel.maxExp} run={run} onDelete={deleteJob} />
          )}

          {!denied && !selected && panel && (
            <div className="empty-screen">
              {jobs.length ? <TbBuildingStore size={42} /> : <TbWorld size={42} />}
              <h2>{jobs.length ? 'Elige un trabajo' : 'Aún no hay trabajos'}</h2>
              <p>{jobs.length ? 'Selecciónalo en la lista para gestionar sus empleados, rangos y puntos.' : 'Crea el primero con el botón de la izquierda.'}</p>
            </div>
          )}
        </section>
      </div>

      <FormModal
        opened={creating}
        title="Crear trabajo"
        description="Se crea con los rangos Empleado, Encargado y Jefe, que podrás cambiar después."
        fields={CREATE_JOB_FIELDS}
        submitLabel="Crear trabajo"
        onClose={() => setCreating(false)}
        onSubmit={async (values) => {
          const name = String(values.job).toLowerCase();
          await run('createJob', { job: name, jobLabel: values.jobLabel });
          setSelected(name);
        }}
      />
    </main>
  );
}
