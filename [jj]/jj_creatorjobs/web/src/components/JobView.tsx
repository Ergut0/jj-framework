import { useEffect, useState } from 'react';
import { TbCar, TbEdit, TbHistory, TbMapPin, TbMapPins, TbMenu2, TbRoute, TbShoppingCart, TbStairs, TbTrash, TbUsers } from 'react-icons/tb';
import type { Job } from '../types';
import { ConfirmModal, FormModal, type Field } from './Form';
import { JobLogo } from './JobLogo';
import { LogsTab } from './LogsTab';
import { BlipsTab, EmployeesTab, GradesTab, MarketTab, OptionsTab, PointsTab, TeleportsTab, VehiclesTab } from './tabs';

export type Run = (name: string, data: Record<string, unknown>) => Promise<void>;

const TABS = [
  { id: 'employees', label: 'Empleados', icon: TbUsers, bossCanSee: true },
  { id: 'grades', label: 'Rangos', icon: TbStairs },
  { id: 'points', label: 'Puntos', icon: TbMapPin },
  { id: 'blips', label: 'Blips', icon: TbMapPins },
  { id: 'market', label: 'Mercado', icon: TbShoppingCart },
  { id: 'vehicles', label: 'Vehículos', icon: TbCar },
  { id: 'options', label: 'Menú F6', icon: TbMenu2 },
  { id: 'teleports', label: 'Teleports', icon: TbRoute },
  { id: 'logs', label: 'Registro', icon: TbHistory, bossCanSee: true },
];

const money = (value: number) => `$${value.toLocaleString('es-ES')}`;

interface Props {
  job: Job;
  admin: boolean;
  maxLevel: number;
  maxExp: number;
  run: Run;
  onDelete: (job: Job) => Promise<void>;
}

export function JobView({ job, admin, maxLevel, maxExp, run, onDelete }: Props) {
  const [tab, setTab] = useState('employees');
  const [editing, setEditing] = useState(false);
  const [deleting, setDeleting] = useState(false);

  // Cada trabajo se abre por sus empleados
  useEffect(() => setTab('employees'), [job.name]);

  const employees = Array.isArray(job.employees) ? job.employees : [];
  const onDuty = employees.filter((employee) => employee.onduty).length;
  const tabs = admin ? TABS : TABS.filter((entry) => entry.bossCanSee);
  const atMax = job.level >= maxLevel;

  const settingsFields: Field[] = [
    { key: 'label', label: 'Nombre visible', type: 'text', required: true },
    { key: 'img', label: 'Imagen (URL)', type: 'text', placeholder: 'https://...' },
    { key: 'level', label: 'Nivel', type: 'number', min: 1, max: maxLevel, required: true },
    { key: 'experience', label: 'Experiencia', type: 'number', min: 0, max: maxExp, required: true },
  ];

  return (
    <div className="job-view">
      <header className="job-head">
        <JobLogo src={job.img} label={job.label} size={56} />
        <div className="job-title">
          <h2>{job.label}</h2>
          <p>
            <code>{job.name}</code>
            <span className={`badge${job.open ? ' on' : ''}`}>{job.open ? 'Abierto' : 'Cerrado'}</span>
          </p>
        </div>
        {admin && (
          <div className="job-head-actions">
            <button type="button" className="btn-ghost" onClick={() => setEditing(true)}><TbEdit size={15} /> Editar</button>
            <button type="button" className="btn-ghost danger" onClick={() => setDeleting(true)}><TbTrash size={15} /> Borrar</button>
          </div>
        )}
      </header>

      <dl className="stats">
        <div>
          <dt>Cuenta de la empresa</dt>
          <dd>{money(job.money)}</dd>
        </div>
        <div>
          <dt>Empleados</dt>
          <dd>{employees.length} <small>{onDuty} de servicio</small></dd>
        </div>
        <div className="stat-level">
          <dt>Nivel {job.level} de {maxLevel}</dt>
          <dd>
            <div className="level-bar"><i style={{ width: `${atMax ? 100 : Math.min(100, (job.experience / maxExp) * 100)}%` }} /></div>
            <small>{atMax ? 'Nivel máximo' : `${job.experience} / ${maxExp} de experiencia`}</small>
          </dd>
        </div>
      </dl>

      <nav className="tabs">
        {tabs.map(({ id, label, icon: Icon }) => (
          <button key={id} type="button" className={tab === id ? 'active' : ''} onClick={() => setTab(id)}>
            <Icon size={15} /> {label}
          </button>
        ))}
      </nav>

      <div className="tab-body">
        {tab === 'employees' && <EmployeesTab job={job} admin={admin} run={run} />}
        {tab === 'grades' && <GradesTab job={job} run={run} />}
        {tab === 'points' && <PointsTab job={job} run={run} />}
        {tab === 'blips' && <BlipsTab job={job} run={run} />}
        {tab === 'market' && <MarketTab job={job} run={run} />}
        {tab === 'vehicles' && <VehiclesTab job={job} run={run} />}
        {tab === 'options' && <OptionsTab job={job} run={run} />}
        {tab === 'teleports' && <TeleportsTab job={job} run={run} />}
        {tab === 'logs' && <LogsTab job={job} />}
      </div>

      <FormModal
        opened={editing}
        title="Editar trabajo"
        fields={settingsFields}
        initial={{ label: job.label, img: job.img ?? '', level: job.level, experience: job.experience }}
        submitLabel="Guardar"
        onClose={() => setEditing(false)}
        onSubmit={(values) => run('updateJob', { name: job.name, ...values })}
      />

      <ConfirmModal
        opened={deleting}
        title={`Borrar ${job.label}`}
        message="Se borran sus rangos, puntos, blips, mercado y teleports, y sus empleados pasan a desempleados. La cuenta de empresa también desaparece, con el dinero que tenga. No se puede deshacer."
        confirmLabel="Borrar trabajo"
        onClose={() => setDeleting(false)}
        onConfirm={() => onDelete(job)}
      />
    </div>
  );
}
