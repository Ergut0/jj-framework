import { useCallback, useEffect, useState } from 'react';
import { api } from '../nui';
import type { GlobalTeleport } from '../types';
import { asList } from '../types';
import type { Field, FormValues } from './Form';
import { Section } from './Section';
import { TELEPORT_COORD_FIELDS } from './tabs';

const FIELDS: Field[] = [
  { key: 'label', label: 'Nombre', type: 'text', required: true },
  ...TELEPORT_COORD_FIELDS,
  { key: 'password', label: 'Contraseña', type: 'password', hint: 'Vacía para que entre cualquiera.' },
  { key: 'bucket', label: 'Mundo (routing bucket)', type: 'number', min: 0, hint: '0 es el mundo normal. Con otro número, dentro no se ve a quien está fuera.' },
];

export function GlobalTeleports({ onAction }: { onAction: (name: string, data: FormValues) => Promise<void> }) {
  const [teleports, setTeleports] = useState<GlobalTeleport[]>([]);

  const load = useCallback(async () => {
    setTeleports(asList(await api.getGlobalTeleports<GlobalTeleport[]>()));
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const run = async (name: string, data: FormValues) => {
    await onAction(name, data);
    await load();
  };

  return (
    <div className="job-view">
      <header className="job-head">
        <div className="job-title">
          <h2>Teleports globales</h2>
          <p>No pertenecen a ningún trabajo. El servidor comprueba la contraseña.</p>
        </div>
      </header>
      <div className="tab-body">
        <Section<GlobalTeleport>
          title="Teleports"
          description="Disponibles para todos los jugadores."
          addLabel="Añadir teleport"
          emptyText="No hay teleports globales."
          rows={teleports}
          columns={[
            { label: 'Nombre', render: (teleport) => <strong>{teleport.label}</strong> },
            { label: 'Contraseña', render: (teleport) => (teleport.password ? 'Sí' : <span className="muted">No</span>) },
            { label: 'Mundo', render: (teleport) => teleport.bucket },
          ]}
          fields={FIELDS}
          defaults={{ bucket: 0, entrance_heading: 0, exit_heading: 0, password: '' }}
          toForm={(teleport) => ({ ...teleport, password: teleport.password ?? '' })}
          onCreate={(values) => run('createGlobalTeleport', values)}
          onEdit={(teleport, values) => run('updateGlobalTeleport', { id: teleport.id, ...values })}
          onDelete={(teleport) => run('deleteGlobalTeleport', { id: teleport.id })}
          onTeleport={(teleport) => api.tp({ x: teleport.entrance_x, y: teleport.entrance_y, z: teleport.entrance_z })}
        />
      </div>
    </div>
  );
}
