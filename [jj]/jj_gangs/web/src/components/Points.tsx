import { useState } from 'react';
import { ActionIcon, Button, Tooltip } from '@mantine/core';
import { FaBoxArchive, FaFlask, FaLocationArrow, FaLocationCrosshairs, FaMapLocationDot, FaPlus, FaShirt, FaTrashCan, FaUserTie, FaWarehouse } from 'react-icons/fa6';
import type { IconType } from 'react-icons';
import { usePanel } from '../context';
import type { Gang, Point } from '../types';
import { FormModal } from './FormModal';

const ICONS: Record<string, IconType> = {
  boss: FaUserTie,
  stash: FaBoxArchive,
  wardrobe: FaShirt,
  garage: FaWarehouse,
  lab: FaFlask,
};

export function Points({ gang }: { gang: Gang }) {
  const { data, run, place, waypoint } = usePanel();
  const { config } = data;
  const [adding, setAdding] = useState(false);
  const [removing, setRemoving] = useState<Point | null>(null);

  const typeLabel = (type: string) => config.pointTypes.find((option) => option.value === type)?.label ?? type;
  const pointLabel = (point: Point) => {
    const lab = point.lab && config.labs.find((option) => option.value === point.lab)?.label;
    return lab ? `${typeLabel(point.type)}: ${lab}` : typeLabel(point.type);
  };

  const groups = config.pointTypes
    .map((option) => ({ ...option, points: gang.points.filter((point) => point.type === option.value) }));

  return (
    <>
      <div className="toolbar">
        <p>Los puntos solo los ven los miembros de la banda. El garaje aparece donde lo colocas y mirando hacia donde mires.</p>
        <Button c="dark" leftSection={<FaPlus size={12} />} onClick={() => setAdding(true)}>Añadir punto</Button>
      </div>

      <div className="point-types">
        {groups.map(({ value, label, points }) => {
          const Icon = ICONS[value] ?? FaLocationCrosshairs;
          return (
            <section key={value} className="card">
              <div className="card-title">
                <h2 className="with-icon"><Icon /> {label}</h2>
                <small className={points.length === 0 ? 'missing' : undefined}>{points.length === 0 ? 'Sin colocar' : points.length}</small>
              </div>
              {points.map((point) => (
                <div key={point.id} className="row">
                  <div className="row-text">
                    <strong>{pointLabel(point)}</strong>
                    <small className="mono">{point.x.toFixed(1)}, {point.y.toFixed(1)}, {point.z.toFixed(1)}</small>
                  </div>
                  <Tooltip label="Ir al punto" zIndex={3500}>
                    <ActionIcon variant="subtle" color="gray" aria-label="Ir al punto" onClick={() => run('teleport', { x: point.x, y: point.y, z: point.z })}><FaLocationArrow size={13} /></ActionIcon>
                  </Tooltip>
                  <Tooltip label="Marcar en el mapa" zIndex={3500}>
                    <ActionIcon variant="subtle" color="gray" aria-label="Marcar en el mapa" onClick={() => waypoint(point.x, point.y)}><FaMapLocationDot size={14} /></ActionIcon>
                  </Tooltip>
                  <Tooltip label="Mover" zIndex={3500}>
                    <ActionIcon variant="subtle" color="gray" aria-label="Mover" onClick={() => place('movePoint', { gang: gang.id, point: point.id }, `Mover: ${pointLabel(point)}`)}><FaLocationCrosshairs size={14} /></ActionIcon>
                  </Tooltip>
                  <Tooltip label="Eliminar" zIndex={3500}>
                    <ActionIcon variant="subtle" color="red" aria-label="Eliminar" onClick={() => setRemoving(point)}><FaTrashCan size={13} /></ActionIcon>
                  </Tooltip>
                </div>
              ))}
            </section>
          );
        })}
      </div>

      <FormModal
        opened={adding}
        title="Añadir punto"
        description="Al continuar se oculta el panel: ve hasta el sitio y pulsa E para colocarlo."
        submitLabel="Ir a colocarlo"
        fields={[
          { name: 'type', label: 'Tipo', type: 'select', required: true, options: config.pointTypes },
          { name: 'lab', label: 'Droga que fabrica', type: 'select', required: true, options: config.labs, visible: (values) => values.type === 'lab' },
        ]}
        onClose={() => setAdding(false)}
        onSubmit={(values) => {
          const type = String(values.type);
          place('addPoint', { gang: gang.id, type, lab: type === 'lab' ? values.lab : undefined }, `Nuevo punto: ${typeLabel(type)}`);
        }}
      />
      <FormModal
        opened={removing !== null}
        title="Eliminar punto"
        description={removing?.type === 'garage'
          ? 'Los vehículos guardados aquí pasan al garaje público.'
          : removing?.type === 'stash'
            ? 'Lo guardado en este armario deja de estar accesible.'
            : '¿Seguro que quieres eliminar este punto?'}
        submitLabel="Eliminar"
        danger
        onClose={() => setRemoving(null)}
        onSubmit={() => run('removePoint', { gang: gang.id, point: removing?.id })}
      />
    </>
  );
}
