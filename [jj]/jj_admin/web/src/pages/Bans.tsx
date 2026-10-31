import { useEffect, useState } from 'react';
import { Button } from '@mantine/core';
import { FormModal } from '../components/FormModal';
import { useAdmin } from '../context';
import { getBans } from '../lib/api';
import { formatDate } from '../lib/format';
import type { Ban } from '../types';

export function Bans() {
  const { run, can, revision } = useAdmin();
  const [bans, setBans] = useState<Ban[]>([]);
  const [adding, setAdding] = useState(false);
  const [removing, setRemoving] = useState<Ban | null>(null);

  useEffect(() => {
    getBans().then(setBans);
  }, [revision]);

  return (
    <>
      <header className="page-header with-action">
        <div>
          <h1>Baneos</h1>
          <p>Baneos activos. Se comprueban al conectarse por licencia y Discord.</p>
        </div>
        {can('banOffline') && <Button c="dark" onClick={() => setAdding(true)}>Banear licencia</Button>}
      </header>

      <section className="card table-card">
        <table className="table">
          <thead>
            <tr><th>Jugador</th><th>Motivo</th><th>Por</th><th>Fecha</th><th>Hasta</th><th /></tr>
          </thead>
          <tbody>
            {bans.map((ban) => (
              <tr key={ban.id}>
                <td><strong>{ban.name}</strong><small className="mono block">{ban.license}</small></td>
                <td>{ban.reason}</td>
                <td>{ban.admin}</td>
                <td>{formatDate(ban.created_at)}</td>
                <td>{ban.expires_at ? formatDate(ban.expires_at) : <span className="badge red">Permanente</span>}</td>
                <td className="right">
                  {can('unban') && <Button size="xs" variant="subtle" color="gray" onClick={() => setRemoving(ban)}>Quitar</Button>}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {bans.length === 0 && <p className="empty">No hay baneos activos.</p>}
      </section>

      <FormModal
        opened={adding}
        title="Banear licencia"
        description="Para jugadores que no están conectados."
        submitLabel="Banear"
        danger
        fields={[
          { name: 'license', label: 'Licencia', required: true, placeholder: 'license:xxxxxxxx' },
          { name: 'name', label: 'Nombre', placeholder: 'Para reconocerlo en la lista' },
          { name: 'hours', label: 'Duración', type: 'select', required: true, initial: '0', options: [{ value: '24', label: '1 día' }, { value: '168', label: '7 días' }, { value: '720', label: '30 días' }, { value: '0', label: 'Permanente' }] },
          { name: 'reason', label: 'Motivo', type: 'textarea', required: true },
        ]}
        onClose={() => setAdding(false)}
        onSubmit={(values) => run('banOffline', { ...values, hours: Number(values.hours) })}
      />
      <FormModal
        opened={removing !== null}
        title={`Quitar baneo de ${removing?.name}`}
        description="El jugador podrá volver a conectarse."
        submitLabel="Quitar baneo"
        onClose={() => setRemoving(null)}
        onSubmit={() => run('unban', { id: removing?.id })}
      />
    </>
  );
}
