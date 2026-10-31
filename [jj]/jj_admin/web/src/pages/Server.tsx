import { useState } from 'react';
import { Button, Group, NumberInput, Select, Textarea } from '@mantine/core';
import { FaFloppyDisk } from 'react-icons/fa6';
import { ActionButton } from '../components/ActionButton';
import { useAdmin } from '../context';

const ANNOUNCE_TYPES = [
  { value: 'anuncio', label: 'Anuncio' },
  { value: 'evento', label: 'Evento' },
  { value: 'mantenimiento', label: 'Mantenimiento' },
  { value: 'urgente', label: 'Urgente' },
];

export function Server() {
  const { data, run, can } = useAdmin();
  const [kind, setKind] = useState<string | null>('anuncio');
  const [message, setMessage] = useState('');
  const [hour, setHour] = useState<number | string>(12);
  const [minute, setMinute] = useState<number | string>(0);

  const send = async () => {
    if (await run('announce', { kind, message })) setMessage('');
  };

  return (
    <>
      <header className="page-header">
        <h1>Servidor</h1>
        <p>Estos cambios afectan a todos los jugadores.</p>
      </header>

      <div className="columns">
        {can('announce') && (
          <section className="card">
            <div className="card-title"><h2>Enviar anuncio</h2></div>
            <Select label="Tipo" data={ANNOUNCE_TYPES} value={kind} onChange={setKind} allowDeselect={false} />
            <Textarea mt="sm" label="Mensaje" placeholder="Lo verán todos los jugadores" autosize minRows={3} maxLength={220} value={message} onChange={(event) => setMessage(event.currentTarget.value)} />
            <Button mt="md" c="dark" disabled={!message.trim()} onClick={send}>Enviar anuncio</Button>
          </section>
        )}

        <section className="card">
          {can('weather') && (
            <>
              <div className="card-title"><h2>Clima</h2></div>
              <Select
                data={data.weatherOptions}
                placeholder="Automático"
                value={data.weather || null}
                allowDeselect={false}
                onChange={(weather) => weather && run('weather', { weather })}
              />
              <Button mt="sm" variant="subtle" color="gray" disabled={!data.weather} onClick={() => run('weather', { weather: false })}>Volver a automático</Button>
            </>
          )}

          {can('time') && (
            <>
              <div className="card-title spaced">
                <h2>Hora</h2>
                <small>{data.time ? `Fijada a las ${String(data.time.hour).padStart(2, '0')}:${String(data.time.minute).padStart(2, '0')}` : 'Automática'}</small>
              </div>
              <Group gap="sm" align="flex-end">
                <NumberInput w={90} label="Hora" min={0} max={23} value={hour} onChange={setHour} />
                <NumberInput w={90} label="Minuto" min={0} max={59} value={minute} onChange={setMinute} />
                <Button c="dark" onClick={() => run('time', { hour, minute })}>Fijar</Button>
                <Button variant="subtle" color="gray" disabled={!data.time} onClick={() => run('time', { hour: false })}>Automática</Button>
              </Group>
            </>
          )}

          <div className="action-grid spaced">
            <ActionButton action="saveAll" icon={<FaFloppyDisk />} label="Guardar jugadores" onClick={() => run('saveAll')} />
          </div>
        </section>
      </div>
    </>
  );
}
