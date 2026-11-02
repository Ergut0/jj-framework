import { useCallback, useEffect, useState } from 'react';
import { TbRefresh } from 'react-icons/tb';
import { api } from '../nui';
import type { Job, LogEntry } from '../types';
import { asList } from '../types';

const CATEGORIES = [
  { id: 'servicio', label: 'Servicio' },
  { id: 'empleados', label: 'Empleados' },
  { id: 'dinero', label: 'Dinero' },
  { id: 'facturas', label: 'Facturas' },
  { id: 'vehiculos', label: 'Vehículos' },
  { id: 'negocio', label: 'Negocio' },
  { id: 'config', label: 'Cambios' },
];

const categoryLabel = (id: string) => CATEGORIES.find((category) => category.id === id)?.label ?? id;

const dateFormat = new Intl.DateTimeFormat('es-ES', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });

export function LogsTab({ job }: { job: Job }) {
  const [logs, setLogs] = useState<LogEntry[] | null>(null);
  const [category, setCategory] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLogs(asList(await api.getLogs<LogEntry[]>(job.name)));
  }, [job.name]);

  useEffect(() => {
    load();
  }, [load]);

  const visible = (logs ?? []).filter((entry) => !category || entry.category === category);

  return (
    <div className="section">
      <header className="section-head">
        <div>
          <h3>Registro</h3>
          <p>Las últimas 300 acciones de esta empresa.</p>
        </div>
        <button type="button" className="btn-ghost" onClick={load}>
          <TbRefresh size={15} /> Actualizar
        </button>
      </header>

      <div className="log-filters">
        <button type="button" className={category === null ? 'active' : ''} onClick={() => setCategory(null)}>Todo</button>
        {CATEGORIES.map((entry) => (
          <button key={entry.id} type="button" className={category === entry.id ? 'active' : ''} onClick={() => setCategory(entry.id)}>
            {entry.label}
          </button>
        ))}
      </div>

      {logs !== null && visible.length === 0 ? (
        <p className="section-empty">{category ? 'No hay nada de este tipo.' : 'Todavía no hay nada registrado.'}</p>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th style={{ width: '110px' }}>Fecha</th>
                <th style={{ width: '100px' }}>Tipo</th>
                <th style={{ width: '170px' }}>Quién</th>
                <th>Qué</th>
              </tr>
            </thead>
            <tbody>
              {visible.map((entry) => (
                <tr key={entry.id}>
                  <td className="muted">{dateFormat.format(entry.created_at * 1000)}</td>
                  <td><span className={`log-tag ${entry.category}`}>{categoryLabel(entry.category)}</span></td>
                  <td><strong>{entry.actor}</strong></td>
                  <td className="log-message">{entry.message}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
