import { useEffect, useState } from 'react';
import { Button, Group, NumberInput, Slider } from '@mantine/core';
import { FaLocationArrow, FaLocationCrosshairs, FaMapLocationDot, FaPen, FaTrashCan } from 'react-icons/fa6';
import { usePanel } from '../context';
import type { Gang } from '../types';
import { FormModal } from './FormModal';

export function Overview({ gang, onDeleted }: { gang: Gang; onDeleted: () => void }) {
  const { data, run, place, waypoint } = usePanel();
  const { config } = data;
  const [radius, setRadius] = useState(gang.radius);
  const [renaming, setRenaming] = useState(false);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    setRadius(gang.radius);
  }, [gang.id, gang.radius]);

  const boss = gang.members.find((member) => member.rank === config.ranks[config.ranks.length - 1].value);

  return (
    <div className="columns">
      <section className="card">
        <div className="card-title"><h2>Datos</h2></div>
        <dl className="facts">
          <div><dt>Jefe</dt><dd>{boss?.name ?? 'Sin jefe'}</dd></div>
          <div><dt>Miembros</dt><dd>{gang.members.length}</dd></div>
          <div><dt>Puntos</dt><dd>{gang.points.length}</dd></div>
          <div><dt>Grafitis</dt><dd>{gang.graffitis.length} / {config.maxGraffitis}</dd></div>
        </dl>
        <Button mt="md" variant="light" leftSection={<FaPen size={12} />} onClick={() => setRenaming(true)}>Cambiar el nombre</Button>

        <div className="card-title spaced"><h2>Color</h2></div>
        <div className="swatches">
          {config.colors.map((color) => (
            <button
              key={color.value}
              type="button"
              title={color.label}
              aria-label={color.label}
              className={color.value === gang.color ? 'swatch active' : 'swatch'}
              style={{ background: color.hex }}
              onClick={() => color.value !== gang.color && run('color', { gang: gang.id, color: color.value })}
            />
          ))}
        </div>

        <div className="card-title spaced danger-title"><h2>Zona peligrosa</h2></div>
        <Button color="red" variant="light" leftSection={<FaTrashCan size={12} />} onClick={() => setDeleting(true)}>Eliminar la banda</Button>
      </section>

      <section className="card">
        <div className="card-title">
          <h2>Barrio</h2>
          <small className="mono">{gang.x.toFixed(1)}, {gang.y.toFixed(1)}, {gang.z.toFixed(1)}</small>
        </div>
        <Group gap="md" align="center" wrap="nowrap">
          <Slider
            style={{ flex: 1 }}
            min={config.minRadius}
            max={config.maxRadius}
            step={5}
            value={radius}
            onChange={setRadius}
            label={(value) => `${value} m`}
          />
          <NumberInput w={96} min={config.minRadius} max={config.maxRadius} suffix=" m" value={radius} onChange={(value) => setRadius(Number(value) || config.minRadius)} hideControls />
        </Group>
        <Group gap="sm" mt="md">
          <Button c="dark" disabled={radius === gang.radius} onClick={() => run('radius', { gang: gang.id, radius })}>Guardar el radio</Button>
          <Button variant="light" leftSection={<FaLocationCrosshairs size={13} />} onClick={() => place('territory', { gang: gang.id, radius }, `Barrio de ${gang.label}`)}>Mover el barrio</Button>
        </Group>
        <Group gap="sm" mt="sm">
          <Button variant="subtle" color="gray" leftSection={<FaLocationArrow size={12} />} onClick={() => run('teleport', { x: gang.x, y: gang.y, z: gang.z })}>Ir al centro</Button>
          <Button variant="subtle" color="gray" leftSection={<FaMapLocationDot size={13} />} onClick={() => waypoint(gang.x, gang.y)}>Marcar en el mapa</Button>
        </Group>
      </section>

      <FormModal
        opened={renaming}
        title="Cambiar el nombre"
        description="Los grafitis pintados pasan a mostrar el nombre nuevo."
        submitLabel="Guardar"
        fields={[{ name: 'label', label: 'Nombre', required: true, maxLength: 32, initial: gang.label }]}
        onClose={() => setRenaming(false)}
        onSubmit={(values) => run('rename', { gang: gang.id, label: values.label })}
      />
      <FormModal
        opened={deleting}
        title={`Eliminar ${gang.label}`}
        description="Se borran sus miembros, puntos, barrio y grafitis. No se puede deshacer. Los vehículos de sus garajes pasan al garaje público, y lo guardado en sus armarios deja de estar accesible."
        submitLabel="Eliminar"
        danger
        onClose={() => setDeleting(false)}
        onSubmit={async () => {
          const done = await run('delete', { gang: gang.id });
          if (done) onDeleted();
          return done;
        }}
      />
    </div>
  );
}
