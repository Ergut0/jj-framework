import { useCallback, useEffect, useState } from 'react';
import type { Call } from './App';
import { formatDate, sampleLogs, toList, type LogEntry } from './nui';

// Convierte los detalles guardados en JSON en un texto corto
const describe = (details?: string) => {
  if (!details) return '';
  try {
    const data = JSON.parse(details) as Record<string, unknown>;
    return Object.entries(data)
      .map(([key, value]) => (value && typeof value === 'object' ? `${key}: ${Object.keys(value).length} valores` : `${key}: ${String(value)}`))
      .join(' · ');
  } catch {
    return details;
  }
};

export function LogsTab({ call }: { call: Call }) {
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [actions, setActions] = useState<Record<string, string>>({});
  const [action, setAction] = useState('');
  const [search, setSearch] = useState('');
  const [open, setOpen] = useState<number | null>(null);

  const load = useCallback(async () => {
    const result = await call<{ logs: LogEntry[]; actions: Record<string, string> }>('logs', { action: action || undefined, search: search || undefined }, () => ({
      logs: sampleLogs.filter((log) => (!action || log.action === action) && (!search || JSON.stringify(log).toLowerCase().includes(search.toLowerCase()))),
      actions: Object.fromEntries(sampleLogs.map((log) => [log.action, log.label])),
    }));
    if (!result) return;
    setLogs(toList<LogEntry>(result.logs));
    setActions(result.actions ?? {});
  }, [action, search, call]);

  useEffect(() => {
    const timer = window.setTimeout(load, 250);
    return () => window.clearTimeout(timer);
  }, [load]);

  return (
    <section className="page">
      <div className="filters">
        <select className="input" value={action} aria-label="Filtrar por acción" onChange={(event) => setAction(event.target.value)}>
          <option value="">Todas las acciones</option>
          {Object.entries(actions).map(([key, label]) => (
            <option key={key} value={key}>
              {label}
            </option>
          ))}
        </select>
        <input className="input" value={search} placeholder="Buscar por persona, matrícula o perfil" aria-label="Buscar en los registros" onChange={(event) => setSearch(event.target.value)} />
        <button type="button" className="action action-ghost action-small" onClick={load}>
          <i className="fa-solid fa-rotate" /> Actualizar
        </button>
      </div>

      <div className="logs">
        {logs.map((log) => (
          <button type="button" key={log.id} className={`log ${open === log.id ? 'log-open' : ''}`} onClick={() => setOpen(open === log.id ? null : log.id)}>
            <span className="muted">{formatDate(log.createdAt)}</span>
            <span className={`tag log-${log.action}`}>{log.label}</span>
            <strong>{log.actor ?? 'Sistema'}</strong>
            <span>{log.target ?? '—'}</span>
            <span className="log-details">{open === log.id ? log.details : describe(log.details)}</span>
          </button>
        ))}
        {logs.length === 0 && <p className="empty">No hay registros.</p>}
      </div>
    </section>
  );
}
