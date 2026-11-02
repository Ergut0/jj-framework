import { useState } from 'react';
import { ActionIcon, Tooltip } from '@mantine/core';
import { FaLocationArrow, FaMapLocationDot, FaTrashCan } from 'react-icons/fa6';
import { usePanel } from '../context';
import type { Gang, Graffiti } from '../types';
import { FormModal } from './FormModal';

const STAND_DISTANCE = 1.5; // Metros delante de la pared al teletransportarse

export function Graffitis({ gang }: { gang: Gang }) {
  const { data, run, waypoint } = usePanel();
  const [removing, setRemoving] = useState<Graffiti | null>(null);

  return (
    <>
      <div className="toolbar">
        <p>Los pinta la banda con <code>/graffiti</code>. Lleva {gang.graffitis.length} de {data.config.maxGraffitis}. Al borrarlos desde aquí no se avisa a nadie.</p>
      </div>

      <section className="card table-card">
        <table className="table">
          <thead>
            <tr><th>Imagen</th><th>Autor</th><th>Coordenadas</th><th /></tr>
          </thead>
          <tbody>
            {gang.graffitis.map((graffiti, index) => (
              <tr key={graffiti.id}>
                <td>
                  <div className="graffiti-cell">
                    {graffiti.url
                      ? <img className="thumb" src={graffiti.url} alt={`Grafiti ${index + 1}`} referrerPolicy="no-referrer" />
                      : <span className="thumb tag" style={{ color: gang.hex }}>{gang.label}</span>}
                    {graffiti.url && <small className="mono url" title={graffiti.url}>{graffiti.url}</small>}
                  </div>
                </td>
                <td>{graffiti.author ?? '—'}</td>
                <td className="mono">{graffiti.x.toFixed(1)}, {graffiti.y.toFixed(1)}, {graffiti.z.toFixed(1)}</td>
                <td className="right">
                  <Tooltip label="Ir al grafiti" zIndex={3500}>
                    <ActionIcon
                      variant="subtle"
                      color="gray"
                      aria-label="Ir al grafiti"
                      onClick={() => run('teleport', {
                        x: graffiti.x + graffiti.nx * STAND_DISTANCE,
                        y: graffiti.y + graffiti.ny * STAND_DISTANCE,
                        z: graffiti.z,
                      })}
                    >
                      <FaLocationArrow size={13} />
                    </ActionIcon>
                  </Tooltip>
                  <Tooltip label="Marcar en el mapa" zIndex={3500}>
                    <ActionIcon variant="subtle" color="gray" aria-label="Marcar en el mapa" onClick={() => waypoint(graffiti.x, graffiti.y)}><FaMapLocationDot size={14} /></ActionIcon>
                  </Tooltip>
                  <Tooltip label="Borrar" zIndex={3500}>
                    <ActionIcon variant="subtle" color="red" aria-label="Borrar" onClick={() => setRemoving(graffiti)}><FaTrashCan size={13} /></ActionIcon>
                  </Tooltip>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {gang.graffitis.length === 0 && <p className="empty">Esta banda no tiene grafitis.</p>}
      </section>

      <FormModal
        opened={removing !== null}
        title="Borrar grafiti"
        description="Desaparece para todos los jugadores."
        submitLabel="Borrar"
        danger
        onClose={() => setRemoving(null)}
        onSubmit={() => run('removeGraffiti', { gang: gang.id, graffiti: removing?.id })}
      />
    </>
  );
}
