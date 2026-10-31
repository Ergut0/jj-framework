import { useState } from 'react';
import { Button, Group, NumberInput, Switch } from '@mantine/core';
import { notifications } from '@mantine/notifications';
import { FaCopy, FaHeart, FaHeartPulse, FaMapLocationDot } from 'react-icons/fa6';
import { ActionButton } from '../components/ActionButton';
import { useAdmin } from '../context';
import { getCoords } from '../lib/api';

const TOGGLES = [
  { action: 'noclip', label: 'Noclip', hint: 'WASD para moverte, Q y E para subir y bajar, Mayús corre, Ctrl despacio.' },
  { action: 'god', label: 'Modo dios', hint: 'No recibes daño.' },
  { action: 'invisible', label: 'Invisible', hint: 'Los demás jugadores no te ven.' },
  { action: 'players', label: 'Ver jugadores', hint: 'Nombres cercanos y todos los jugadores en el mapa.' },
] as const;

function copyText(text: string) {
  // El navegador de FiveM no siempre permite navigator.clipboard
  const input = document.createElement('textarea');
  input.value = text;
  document.body.appendChild(input);
  input.select();
  document.execCommand('copy');
  input.remove();
}

export function Self() {
  const { data, run, can } = useAdmin();
  const [coords, setCoords] = useState<{ x: number | string; y: number | string; z: number | string }>({ x: '', y: '', z: '' });

  const copy = async (withHeading: boolean) => {
    const current = await getCoords();
    if (!current) return;
    const text = withHeading
      ? `vector4(${current.x.toFixed(2)}, ${current.y.toFixed(2)}, ${current.z.toFixed(2)}, ${current.heading.toFixed(2)})`
      : `vector3(${current.x.toFixed(2)}, ${current.y.toFixed(2)}, ${current.z.toFixed(2)})`;
    copyText(text);
    notifications.show({ message: `Copiado: ${text}`, color: 'yellow', autoClose: 3000 });
  };

  const coordsReady = [coords.x, coords.y, coords.z].every((value) => value !== '');

  return (
    <>
      <header className="page-header">
        <h1>Mis herramientas</h1>
        <p>Solo te afectan a ti. Todas quedan en los registros.</p>
      </header>

      <div className="columns">
        <section className="card">
          <div className="card-title"><h2>Modos</h2></div>
          <div className="toggles">
            {TOGGLES.filter(({ action }) => can(action)).map(({ action, label, hint }) => (
              <Switch key={action} label={label} description={hint} checked={data.toggles[action]} onChange={() => run(action)} />
            ))}
          </div>
        </section>

        <section className="card">
          <div className="card-title"><h2>Personaje</h2></div>
          <div className="action-grid">
            <ActionButton action="heal" icon={<FaHeart />} label="Curarme" onClick={() => run('heal', { target: data.me.id })} />
            <ActionButton action="revive" icon={<FaHeartPulse />} label="Reanimarme" onClick={() => run('revive', { target: data.me.id })} />
            <ActionButton action="tpWaypoint" icon={<FaMapLocationDot />} label="Ir al marcador" onClick={() => run('tpWaypoint')} />
          </div>

          <div className="card-title spaced"><h2>Coordenadas</h2></div>
          <Group gap="sm">
            <Button variant="light" leftSection={<FaCopy />} onClick={() => copy(false)}>Copiar vector3</Button>
            <Button variant="light" leftSection={<FaCopy />} onClick={() => copy(true)}>Copiar vector4</Button>
          </Group>
          {can('tpCoords') && (
            <Group gap="sm" mt="md" align="flex-end" wrap="nowrap">
              <NumberInput label="X" value={coords.x} onChange={(x) => setCoords((current) => ({ ...current, x }))} hideControls />
              <NumberInput label="Y" value={coords.y} onChange={(y) => setCoords((current) => ({ ...current, y }))} hideControls />
              <NumberInput label="Z" value={coords.z} onChange={(z) => setCoords((current) => ({ ...current, z }))} hideControls />
              <Button c="dark" disabled={!coordsReady} onClick={() => run('tpCoords', coords)}>Ir</Button>
            </Group>
          )}
        </section>
      </div>
    </>
  );
}
