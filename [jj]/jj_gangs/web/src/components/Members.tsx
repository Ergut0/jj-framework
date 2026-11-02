import { useState } from 'react';
import { ActionIcon, Button, Select, Tooltip } from '@mantine/core';
import { FaTrashCan, FaUserPlus } from 'react-icons/fa6';
import { usePanel } from '../context';
import type { Gang, Member } from '../types';
import { FormModal } from './FormModal';

export function Members({ gang }: { gang: Gang }) {
  const { data, run } = usePanel();
  const { config, players } = data;
  const [adding, setAdding] = useState(false);
  const [kicking, setKicking] = useState<Member | null>(null);

  const rankOptions = config.ranks.map((rank) => ({ value: String(rank.value), label: rank.label }));
  const available = players
    .filter((player) => !gang.members.some((member) => member.source === player.id))
    .map((player) => ({
      value: String(player.id),
      label: `[${player.id}] ${player.name}${player.gang ? ` (en ${player.gang})` : ''}`,
    }));

  return (
    <>
      <div className="toolbar">
        <p>Si nombras a un jefe, el anterior pasa a Sub Jefe. Añadir aquí no pide confirmación al jugador.</p>
        <Button c="dark" leftSection={<FaUserPlus size={13} />} onClick={() => setAdding(true)}>Añadir miembro</Button>
      </div>

      <section className="card table-card">
        <table className="table">
          <thead>
            <tr><th>Nombre</th><th>Estado</th><th>Rango</th><th /></tr>
          </thead>
          <tbody>
            {gang.members.map((member) => (
              <tr key={member.identifier}>
                <td><strong>{member.name}</strong><small className="mono block">{member.identifier}</small></td>
                <td>
                  {member.online
                    ? <span className="badge green">Conectado{member.source ? ` · ID ${member.source}` : ''}</span>
                    : <span className="badge gray">Desconectado</span>}
                </td>
                <td className="rank-cell">
                  <Select
                    size="xs"
                    aria-label={`Rango de ${member.name}`}
                    data={rankOptions}
                    value={String(member.rank)}
                    allowDeselect={false}
                    comboboxProps={{ zIndex: 3500 }}
                    onChange={(value) => value && Number(value) !== member.rank && run('memberRank', { gang: gang.id, identifier: member.identifier, rank: Number(value) })}
                  />
                </td>
                <td className="right">
                  <Tooltip label="Sacar de la banda" zIndex={3500}>
                    <ActionIcon variant="subtle" color="red" aria-label={`Sacar a ${member.name}`} onClick={() => setKicking(member)}><FaTrashCan size={13} /></ActionIcon>
                  </Tooltip>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {gang.members.length === 0 && <p className="empty">Esta banda no tiene miembros. Añade a su jefe para empezar.</p>}
      </section>

      <FormModal
        opened={adding}
        title={`Añadir a ${gang.label}`}
        description="Solo aparecen los jugadores conectados con un personaje. Si ya está en otra banda, pasa a esta."
        submitLabel="Añadir"
        fields={[
          { name: 'target', label: 'Jugador', type: 'select', required: true, searchable: true, options: available },
          { name: 'rank', label: 'Rango', type: 'select', required: true, options: rankOptions, initial: gang.members.length === 0 ? String(config.ranks[config.ranks.length - 1].value) : '0' },
        ]}
        onClose={() => setAdding(false)}
        onSubmit={(values) => run('memberAdd', { gang: gang.id, target: Number(values.target), rank: Number(values.rank) })}
      />
      <FormModal
        opened={kicking !== null}
        title={`Sacar a ${kicking?.name}`}
        description="Dejará de pertenecer a la banda y de ver sus puntos."
        submitLabel="Sacar de la banda"
        danger
        onClose={() => setKicking(null)}
        onSubmit={() => run('memberKick', { gang: gang.id, identifier: kicking?.identifier })}
      />
    </>
  );
}
