import { useEffect, useState } from 'react';
import { FaBan, FaHeartPulse, FaShieldHalved, FaUsers } from 'react-icons/fa6';
import { useAdmin } from '../context';
import { getLogs } from '../lib/api';
import { ACTION_LABELS, formatDate } from '../lib/format';
import type { LogEntry } from '../types';

export function Dashboard({ onNavigate }: { onNavigate: (page: 'players' | 'bans' | 'logs') => void }) {
  const { data, revision } = useAdmin();
  const [logs, setLogs] = useState<LogEntry[]>([]);

  useEffect(() => {
    getLogs().then(setLogs);
  }, [revision]);

  const downPlayers = data.players.filter((player) => player.down);

  return (
    <>
      <header className="page-header">
        <h1>Panel</h1>
        <p>Resumen del servidor en este momento.</p>
      </header>

      <div className="tiles">
        <button type="button" className="tile" onClick={() => onNavigate('players')}>
          <FaUsers />
          <strong>{data.players.length}<small>/{data.maxPlayers}</small></strong>
          <span>Conectados</span>
        </button>
        <div className="tile">
          <FaShieldHalved />
          <strong>{data.stats.police}</strong>
          <span>Policías de servicio</span>
        </div>
        <div className="tile">
          <FaHeartPulse />
          <strong>{data.stats.ambulance}</strong>
          <span>Médicos de servicio</span>
        </div>
        <button type="button" className="tile" onClick={() => onNavigate('bans')}>
          <FaBan />
          <strong>{data.stats.bans}</strong>
          <span>Baneos activos</span>
        </button>
      </div>

      <div className="columns">
        <section className="card">
          <div className="card-title">
            <h2>Actividad reciente</h2>
            <button type="button" className="link" onClick={() => onNavigate('logs')}>Ver todo</button>
          </div>
          {logs.length === 0 && <p className="empty">Todavía no hay registros.</p>}
          <ul className="activity">
            {logs.slice(0, 7).map((log) => (
              <li key={log.id}>
                <div>
                  <strong>{log.admin}</strong> · {ACTION_LABELS[log.action] ?? log.action}
                  {log.target && <> · {log.target}</>}
                </div>
                <time>{formatDate(log.created_at)}</time>
              </li>
            ))}
          </ul>
        </section>

        <section className="card">
          <div className="card-title">
            <h2>Heridos ahora</h2>
          </div>
          {downPlayers.length === 0 && <p className="empty">No hay nadie herido.</p>}
          <ul className="activity">
            {downPlayers.map((player) => (
              <li key={player.id}>
                <div><strong>{player.name}</strong> · ID {player.id}</div>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </>
  );
}
