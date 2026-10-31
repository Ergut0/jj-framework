import { useEffect, useMemo, useState } from 'react';
import { TextInput } from '@mantine/core';
import {
  FaArrowRightToBracket, FaBan, FaBoxOpen, FaBriefcase, FaCarSide, FaDoorOpen, FaEye, FaGift, FaHeart, FaHeartPulse,
  FaLocationArrow, FaMagnifyingGlass, FaMoneyBillWave, FaSkull, FaSnowflake, FaToggleOn, FaTrashCan,
} from 'react-icons/fa6';
import { ActionButton } from '../components/ActionButton';
import { FormModal, type Field, type FieldValue } from '../components/FormModal';
import { useAdmin } from '../context';
import { getItems } from '../lib/api';
import { formatMoney } from '../lib/format';
import type { Option, Player } from '../types';

const BAN_OPTIONS = [
  { value: '1', label: '1 hora' },
  { value: '24', label: '1 día' },
  { value: '168', label: '7 días' },
  { value: '720', label: '30 días' },
  { value: '0', label: 'Permanente' },
];

type ModalId = 'money' | 'job' | 'item' | 'vehicle' | 'kick' | 'ban' | 'kill' | 'clearInventory' | null;

export function Players() {
  const { data, run, can } = useAdmin();
  const [search, setSearch] = useState('');
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [modal, setModal] = useState<ModalId>(null);
  const [items, setItems] = useState<Option[]>([]);

  useEffect(() => {
    if (can('giveItem')) getItems().then(setItems);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase();
    if (!term) return data.players;
    return data.players.filter((player) =>
      [String(player.id), player.name, player.fivemName, player.identifier, player.license, player.job?.label]
        .some((value) => value?.toLowerCase().includes(term)),
    );
  }, [data.players, search]);

  const selected = data.players.find((player) => player.id === selectedId) ?? null;

  const act = (action: string, extra?: Record<string, unknown>) => run(action, { target: selected?.id, ...extra });

  const jobFields: Field[] = [
    { name: 'job', label: 'Trabajo', type: 'select', required: true, searchable: true, options: data.jobs.map((job) => ({ value: job.name, label: job.label })) },
    {
      name: 'grade',
      label: 'Grado',
      type: 'select',
      required: true,
      dependsOn: (values) =>
        (data.jobs.find((job) => job.name === values.job)?.grades ?? []).map((grade) => ({ value: String(grade.value), label: grade.label })),
    },
  ];

  const moneyFields: Field[] = [
    { name: 'mode', label: 'Operación', type: 'select', required: true, initial: 'add', options: [{ value: 'add', label: 'Añadir' }, { value: 'remove', label: 'Quitar' }, { value: 'set', label: 'Fijar saldo' }] },
    { name: 'account', label: 'Cuenta', type: 'select', required: true, initial: 'cash', options: data.accounts.map((account) => ({ value: account.name, label: account.label })) },
    { name: 'amount', label: 'Cantidad', type: 'number', required: true, min: 0 },
  ];

  const banFields: Field[] = [
    { name: 'hours', label: 'Duración', type: 'select', required: true, initial: '24', options: BAN_OPTIONS },
    { name: 'reason', label: 'Motivo', type: 'textarea', required: true, placeholder: 'Se muestra al jugador' },
  ];

  const submit = (action: string) => (values: Record<string, FieldValue>) => act(action, values);

  return (
    <>
      <header className="page-header">
        <h1>Jugadores</h1>
        <p>Busca por ID, nombre, licencia o trabajo.</p>
      </header>

      <div className="players">
        <section className="card player-list">
          <TextInput
            placeholder="Buscar jugador"
            leftSection={<FaMagnifyingGlass size={13} />}
            value={search}
            onChange={(event) => setSearch(event.currentTarget.value)}
          />
          <ul>
            {filtered.map((player) => (
              <li key={player.id}>
                <button type="button" className={player.id === selectedId ? 'player-row active' : 'player-row'} onClick={() => setSelectedId(player.id)}>
                  <span className="player-id">{player.id}</span>
                  <span className="player-name">
                    <strong>{player.name}</strong>
                    <small>{player.loaded ? player.job?.label : 'Eligiendo personaje'}</small>
                  </span>
                  {player.down && <span className="badge red">Herido</span>}
                  {player.frozen && <span className="badge blue">Congelado</span>}
                  {player.level !== 'none' && <span className="badge">{player.level === 'admin' ? 'Admin' : 'Mod'}</span>}
                </button>
              </li>
            ))}
            {filtered.length === 0 && <li className="empty">No hay jugadores que coincidan.</li>}
          </ul>
        </section>

        {selected ? (
          <PlayerDetail player={selected} onAct={act} onModal={setModal} />
        ) : (
          <section className="card placeholder">Elige un jugador para ver sus datos y acciones.</section>
        )}
      </div>

      <FormModal opened={modal === 'money'} title={`Dinero de ${selected?.name}`} submitLabel="Aplicar" fields={moneyFields} onClose={() => setModal(null)} onSubmit={submit('money')} />
      <FormModal opened={modal === 'job'} title={`Trabajo de ${selected?.name}`} submitLabel="Cambiar trabajo" fields={jobFields} onClose={() => setModal(null)} onSubmit={(values) => act('setJob', { job: values.job, grade: Number(values.grade) })} />
      <FormModal
        opened={modal === 'item'}
        title={`Dar objeto a ${selected?.name}`}
        submitLabel="Dar objeto"
        fields={[
          { name: 'item', label: 'Objeto', type: 'select', required: true, searchable: true, options: items },
          { name: 'count', label: 'Cantidad', type: 'number', required: true, min: 1, initial: 1 },
        ]}
        onClose={() => setModal(null)}
        onSubmit={submit('giveItem')}
      />
      <FormModal
        opened={modal === 'vehicle'}
        title={`Dar vehículo a ${selected?.name}`}
        description="El vehículo aparecerá en su garaje con una matrícula nueva."
        submitLabel="Dar vehículo"
        fields={[{ name: 'model', label: 'Modelo', required: true, placeholder: 'adder' }]}
        onClose={() => setModal(null)}
        onSubmit={submit('giveVehicle')}
      />
      <FormModal
        opened={modal === 'kick'}
        title={`Expulsar a ${selected?.name}`}
        submitLabel="Expulsar"
        danger
        fields={[{ name: 'reason', label: 'Motivo', type: 'textarea', required: true, placeholder: 'Se muestra al jugador' }]}
        onClose={() => setModal(null)}
        onSubmit={async (values) => {
          const done = await act('kick', values);
          if (done) setSelectedId(null);
          return done;
        }}
      />
      <FormModal
        opened={modal === 'ban'}
        title={`Banear a ${selected?.name}`}
        submitLabel="Banear"
        danger
        fields={banFields}
        onClose={() => setModal(null)}
        onSubmit={async (values) => {
          const done = await act('ban', { reason: values.reason, hours: Number(values.hours) });
          if (done) setSelectedId(null);
          return done;
        }}
      />
      <FormModal opened={modal === 'kill'} title={`Matar a ${selected?.name}`} description="El jugador caerá al suelo como si hubiera muerto." submitLabel="Matar" danger onClose={() => setModal(null)} onSubmit={() => act('kill')} />
      <FormModal opened={modal === 'clearInventory'} title={`Vaciar inventario de ${selected?.name}`} description="Se borrarán todos sus objetos menos el efectivo. No se puede deshacer." submitLabel="Vaciar" danger onClose={() => setModal(null)} onSubmit={() => act('clearInventory')} />
    </>
  );
}

function PlayerDetail({ player, onAct, onModal }: { player: Player; onAct: (action: string) => void; onModal: (modal: ModalId) => void }) {
  const { data } = useAdmin();
  const noCharacter = !player.loaded;

  return (
    <section className="card player-detail">
      <div className="detail-head">
        <span className="player-id large">{player.id}</span>
        <div>
          <h2>{player.name}</h2>
          <small>{player.fivemName} · {player.identifier ?? 'Sin personaje cargado'}</small>
        </div>
      </div>

      <dl className="facts">
        <div><dt>Trabajo</dt><dd>{player.job ? `${player.job.label} · ${player.job.gradeLabel}` : '—'}</dd></div>
        <div><dt>Servicio</dt><dd>{player.job ? (player.job.onDuty ? 'De servicio' : 'Fuera de servicio') : '—'}</dd></div>
        <div><dt>Vida</dt><dd>{player.health ?? '—'}</dd></div>
        <div><dt>Chaleco</dt><dd>{player.armour ?? '—'}</dd></div>
        <div><dt>Ping</dt><dd>{player.ping} ms</dd></div>
        {data.accounts.map((account) => (
          <div key={account.name}>
            <dt>{account.label}</dt>
            <dd>{player.accounts ? formatMoney(player.accounts[account.name] ?? 0) : '—'}</dd>
          </div>
        ))}
        <div className="wide"><dt>Licencia</dt><dd className="mono">{player.license ?? '—'}</dd></div>
      </dl>

      <h3>Moverse</h3>
      <div className="action-grid">
        <ActionButton action="goto" icon={<FaLocationArrow />} label="Ir al jugador" onClick={() => onAct('goto')} />
        <ActionButton action="bring" icon={<FaArrowRightToBracket />} label="Traer" onClick={() => onAct('bring')} />
        <ActionButton action="spectate" icon={<FaEye />} label="Espectar" onClick={() => onAct('spectate')} />
        <ActionButton action="freeze" icon={<FaSnowflake />} label={player.frozen ? 'Descongelar' : 'Congelar'} active={player.frozen} onClick={() => onAct('freeze')} />
      </div>

      <h3>Estado</h3>
      <div className="action-grid">
        <ActionButton action="revive" icon={<FaHeartPulse />} label="Reanimar" disabled={noCharacter} onClick={() => onAct('revive')} />
        <ActionButton action="heal" icon={<FaHeart />} label="Curar" disabled={noCharacter} onClick={() => onAct('heal')} />
        <ActionButton action="setDuty" icon={<FaToggleOn />} label="Cambiar servicio" disabled={noCharacter} onClick={() => onAct('setDuty')} />
        <ActionButton action="setJob" icon={<FaBriefcase />} label="Cambiar trabajo" disabled={noCharacter} onClick={() => onModal('job')} />
      </div>

      <h3>Dinero y objetos</h3>
      <div className="action-grid">
        <ActionButton action="money" icon={<FaMoneyBillWave />} label="Dinero" disabled={noCharacter} onClick={() => onModal('money')} />
        <ActionButton action="giveItem" icon={<FaGift />} label="Dar objeto" disabled={noCharacter} onClick={() => onModal('item')} />
        <ActionButton action="viewInventory" icon={<FaBoxOpen />} label="Ver inventario" disabled={noCharacter} onClick={() => onAct('viewInventory')} />
        <ActionButton action="giveVehicle" icon={<FaCarSide />} label="Dar vehículo" disabled={noCharacter} onClick={() => onModal('vehicle')} />
      </div>

      <h3>Sanciones</h3>
      <div className="action-grid">
        <ActionButton action="kick" icon={<FaDoorOpen />} label="Expulsar" danger onClick={() => onModal('kick')} />
        <ActionButton action="ban" icon={<FaBan />} label="Banear" danger onClick={() => onModal('ban')} />
        <ActionButton action="kill" icon={<FaSkull />} label="Matar" danger disabled={noCharacter} onClick={() => onModal('kill')} />
        <ActionButton action="clearInventory" icon={<FaTrashCan />} label="Vaciar inventario" danger disabled={noCharacter} onClick={() => onModal('clearInventory')} />
      </div>
    </section>
  );
}
