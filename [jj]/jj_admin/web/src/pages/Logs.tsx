import { useEffect, useMemo, useState } from 'react';
import { TextInput } from '@mantine/core';
import { FaMagnifyingGlass } from 'react-icons/fa6';
import { useAdmin } from '../context';
import { getLogs } from '../lib/api';
import { ACTION_LABELS, formatDate } from '../lib/format';
import type { LogEntry } from '../types';

export function Logs() {
  const { revision } = useAdmin();
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [search, setSearch] = useState('');

  useEffect(() => {
    getLogs().then(setLogs);
  }, [revision]);

  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase();
    if (!term) return logs;
    return logs.filter((log) =>
      [log.admin, ACTION_LABELS[log.action] ?? log.action, log.target, log.details].some((value) => value?.toLowerCase().includes(term)),
    );
  }, [logs, search]);

  return (
    <>
      <header className="page-header with-action">
        <div>
          <h1>Registros</h1>
          <p>Las últimas acciones de los administradores.</p>
        </div>
        <TextInput placeholder="Buscar" leftSection={<FaMagnifyingGlass size={13} />} value={search} onChange={(event) => setSearch(event.currentTarget.value)} />
      </header>

      <section className="card table-card">
        <table className="table">
          <thead>
            <tr><th>Fecha</th><th>Administrador</th><th>Acción</th><th>Objetivo</th><th>Detalles</th></tr>
          </thead>
          <tbody>
            {filtered.map((log) => (
              <tr key={log.id}>
                <td className="nowrap">{formatDate(log.created_at)}</td>
                <td>{log.admin}</td>
                <td>{ACTION_LABELS[log.action] ?? log.action}</td>
                <td>{log.target ?? '—'}</td>
                <td>{log.details ?? '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && <p className="empty">No hay registros.</p>}
      </section>
    </>
  );
}
