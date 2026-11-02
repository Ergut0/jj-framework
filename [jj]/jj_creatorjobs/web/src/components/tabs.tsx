import { useState } from 'react';
import { TbArrowsExchange, TbUserCheck, TbUserMinus, TbUserPlus } from 'react-icons/tb';
import { api } from '../nui';
import type { Blip, Employee, Grade, Job, MarketItem, Perm, Point, Teleport, Vehicle } from '../types';
import { asList } from '../types';
import { ConfirmModal, FormModal, type Field } from './Form';
import type { Run } from './JobView';
import { Section, type Column } from './Section';

interface TabProps {
  job: Job;
  run: Run;
}

const money = (value: number) => `$${value.toLocaleString('es-ES')}`;
const coordsText = (x: number, y: number, z: number) => `${x.toFixed(1)}, ${y.toFixed(1)}, ${z.toFixed(1)}`;

// Empleados

export function EmployeesTab({ job, admin, run }: TabProps & { admin: boolean }) {
  const employees = asList<Employee>(job.employees);
  const grades = asList<Grade>(job.grades);
  const [search, setSearch] = useState('');
  const [hiring, setHiring] = useState(false);
  const [changing, setChanging] = useState<Employee | null>(null);
  const [firing, setFiring] = useState<Employee | null>(null);

  // Un jefe no puede nombrar a otro jefe ni tocar a otro jefe
  const assignable = grades.filter((grade) => admin || !grade.permission);
  const gradeOptions = assignable.map((grade) => ({ value: String(grade.id), label: grade.label }));
  const isLocked = (employee: Employee) => !admin && grades.some((grade) => grade.id === employee.grade && grade.permission);

  const term = search.trim().toLowerCase();
  const visible = term ? employees.filter((employee) => employee.nombre.toLowerCase().includes(term)) : employees;

  const hireFields: Field[] = [
    { key: 'src', label: 'ID del jugador', type: 'number', required: true, min: 1, hint: admin ? 'Tiene que estar conectado.' : 'Tiene que estar conectado y a menos de 10 metros.' },
    { key: 'grade', label: 'Rango', type: 'select', required: true, options: gradeOptions },
  ];

  return (
    <div className="section">
      <header className="section-head">
        <div>
          <h3>Empleados</h3>
          <p>Contrata, despide y cambia de rango, también a quien no esté conectado.</p>
        </div>
        <button type="button" className="btn-primary" onClick={() => setHiring(true)}>
          <TbUserPlus size={15} /> Contratar
        </button>
      </header>

      {employees.length > 4 && (
        <input className="table-search" value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Buscar empleado" />
      )}

      {visible.length === 0 ? (
        <p className="section-empty">{term ? 'Ningún empleado coincide' : 'Este trabajo aún no tiene empleados.'}</p>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Nombre</th>
                <th>Rango</th>
                <th>Estado</th>
                <th className="actions-col" />
              </tr>
            </thead>
            <tbody>
              {visible.map((employee) => (
                <tr key={employee.identifier}>
                  <td><strong>{employee.nombre}</strong></td>
                  <td>{employee.gradeLabel}</td>
                  <td>
                    <span className={`status ${employee.online ? (employee.onduty ? 'on' : 'idle') : ''}`}>
                      {employee.online ? (employee.onduty ? 'De servicio' : 'Fuera de servicio') : 'Desconectado'}
                    </span>
                  </td>
                  <td className="actions-col">
                    {!isLocked(employee) && (
                      <div className="row-actions">
                        <button type="button" className="icon-btn" title="Cambiar rango" onClick={() => setChanging(employee)}>
                          <TbArrowsExchange size={15} />
                        </button>
                        <button type="button" className="icon-btn danger" title="Despedir" onClick={() => setFiring(employee)}>
                          <TbUserMinus size={15} />
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <FormModal
        opened={hiring}
        title="Contratar"
        fields={hireFields}
        initial={{ grade: gradeOptions[0]?.value }}
        submitLabel="Contratar"
        onClose={() => setHiring(false)}
        onSubmit={(values) => run('hirePlayer', { jobName: job.name, src: values.src, grade: Number(values.grade) })}
      />

      <FormModal
        opened={changing !== null}
        title={`Cambiar rango de ${changing?.nombre ?? ''}`}
        fields={[{ key: 'grade', label: 'Rango', type: 'select', required: true, options: gradeOptions }]}
        initial={{ grade: changing ? String(changing.grade) : undefined }}
        submitLabel="Cambiar rango"
        onClose={() => setChanging(null)}
        onSubmit={async (values) => {
          if (changing) await run('promotePlayer', { jobName: job.name, id: changing.identifier, gradeId: Number(values.grade) });
        }}
      />

      <ConfirmModal
        opened={firing !== null}
        title="Despedir empleado"
        message={`¿Seguro que quieres despedir a ${firing?.nombre ?? ''}? Pasará a estar sin trabajo.`}
        confirmLabel="Despedir"
        onClose={() => setFiring(null)}
        onConfirm={async () => {
          if (firing) await run('firePlayer', { jobName: job.name, id: firing.identifier });
        }}
      />
    </div>
  );
}

// Rangos

export function GradesTab({ job, run }: TabProps) {
  const columns: Column<Grade>[] = [
    { label: 'Nivel', width: '70px', render: (grade) => grade.id },
    { label: 'Nombre', render: (grade) => <strong>{grade.label}</strong> },
    { label: 'Interno', render: (grade) => <code>{grade.name}</code> },
    { label: 'Sueldo', render: (grade) => money(grade.salary) },
    { label: 'Permisos', render: (grade) => (grade.permission ? <span className="badge on">Jefe</span> : <span className="muted">—</span>) },
  ];

  const baseFields: Field[] = [
    { key: 'label', label: 'Nombre visible', type: 'text', required: true, placeholder: 'Encargado' },
    { key: 'name', label: 'Nombre interno', type: 'text', required: true, placeholder: 'encargado', pattern: /^[A-Za-z0-9_]+$/, hint: 'Solo letras, números y guiones bajos.' },
    { key: 'salary', label: 'Sueldo', type: 'number', required: true, min: 0 },
  ];

  return (
    <Section<Grade>
      title="Rangos"
      description="El nivel se asigna solo. Con permisos de jefe se gestiona la empresa, los empleados y la caja fuerte."
      addLabel="Añadir rango"
      emptyText="Este trabajo no tiene rangos."
      rows={asList<Grade>(job.grades)}
      columns={columns}
      fields={baseFields}
      editFields={[...baseFields, { key: 'permission', label: 'Permisos de jefe', type: 'switch' }]}
      defaults={{ salary: 0 }}
      toForm={(grade) => ({ label: grade.label, name: grade.name, salary: grade.salary, permission: grade.permission })}
      onCreate={(values) => run('insertGrade', { jobName: job.name, id: values.name, label: values.label, salary: values.salary })}
      onEdit={(grade, values) => run('updateGrade', { jobName: job.name, idGrade: grade.id, ...values, permission: values.permission === true })}
      onDelete={(grade) => run('deleteGrade', { jobName: job.name, idGrade: grade.id })}
      canDelete={(grade) => grade.id !== 0}
      deleteMessage={(grade) => `¿Seguro que quieres borrar ${grade.label}? Quien lo tenga pasará al rango de nivel 0.`}
      extraActions={(grade) => (
        <button type="button" className="icon-btn" title="Ponerme este rango" onClick={() => run('setJob', { jobName: job.name, id: grade.id })}>
          <TbUserCheck size={15} />
        </button>
      )}
    />
  );
}

// Puntos

const POINT_TYPES: { value: string; label: string }[] = [
  { value: 'Servicio', label: 'Servicio: entrar y salir de servicio' },
  { value: 'Inventario', label: 'Inventario: almacén de la empresa' },
  { value: 'Mercado', label: 'Mercado: pedir productos' },
  { value: 'Ropero', label: 'Ropero: ropa y taquilla personal' },
  { value: 'Jefe', label: 'Jefe: cuenta, empleados y caja fuerte' },
  { value: 'Garaje', label: 'Garaje: vehículos de la empresa' },
  { value: 'GuardarVehiculo', label: 'Guardar vehículo de la empresa' },
  { value: 'Garaje Personal', label: 'Garaje personal de los empleados' },
  { value: 'Garaje Compraventa', label: 'Garaje de compraventa' },
  { value: 'Zona Centro', label: 'Zona de trabajo: al salir, fuera de servicio' },
  { value: 'Crafteo', label: 'Crafteo (necesita josete_crafteos)' },
  { value: 'Tuneo', label: 'Tuneo: tunear cualquier vehículo' },
];

export function PointsTab({ job, run }: TabProps) {
  const fields: Field[] = [
    { key: 'typePoint', label: 'Tipo', type: 'select', required: true, options: POINT_TYPES },
    { key: 'radius', label: 'Radio de la zona (metros)', type: 'number', min: 1, required: true, when: (values) => values.typePoint === 'Zona Centro' },
    { key: 'coords', label: 'Posición', type: 'coords', keys: ['x', 'y', 'z', 'heading'] },
  ];

  const columns: Column<Point>[] = [
    { label: 'Tipo', render: (point) => <strong>{point.typePoint}</strong> },
    { label: 'Posición', render: (point) => <code>{coordsText(point.x, point.y, point.z)}</code> },
    { label: 'Radio', width: '80px', render: (point) => (point.typePoint === 'Zona Centro' ? `${point.radius} m` : <span className="muted">—</span>) },
  ];

  return (
    <Section<Point>
      title="Puntos"
      description="Lugares donde los empleados interactúan con la tecla E. Fuera de servicio solo se ven Servicio, Ropero y Jefe."
      addLabel="Añadir punto"
      emptyText="Este trabajo no tiene puntos. Empieza por uno de Servicio."
      rows={asList<Point>(job.points)}
      columns={columns}
      fields={fields}
      defaults={{ radius: 25, heading: 0 }}
      toForm={(point) => ({ ...point })}
      onCreate={(values) => run('createPoint', { job: job.name, ...values })}
      onEdit={(point, values) => run('updatePoint', { job: job.name, id: point.id, ...values })}
      onDelete={(point) => run('deletePoint', { job: job.name, id: point.id })}
      onTeleport={(point) => api.tp(point)}
    />
  );
}

// Blips

const BLIP_SPRITES = [
  { value: '52', label: 'Tienda (52)' },
  { value: '106', label: 'Comida (106)' },
  { value: '93', label: 'Bar (93)' },
  { value: '72', label: 'Taller (72)' },
  { value: '446', label: 'Llave inglesa (446)' },
  { value: '326', label: 'Concesionario (326)' },
  { value: '198', label: 'Taxi (198)' },
  { value: '61', label: 'Hospital (61)' },
  { value: '60', label: 'Policía (60)' },
  { value: '408', label: 'Maletín (408)' },
  { value: '475', label: 'Edificio (475)' },
];

const BLIP_COLOURS = [
  { value: '2', label: 'Verde' },
  { value: '1', label: 'Rojo' },
  { value: '3', label: 'Azul' },
  { value: '5', label: 'Amarillo' },
  { value: '17', label: 'Naranja' },
  { value: '27', label: 'Morado' },
  { value: '48', label: 'Rosa' },
  { value: '39', label: 'Gris' },
];

export function BlipsTab({ job, run }: TabProps) {
  const fields: Field[] = [
    { key: 'labelBlip', label: 'Nombre en el mapa', type: 'text', required: true },
    { key: 'valueBlip', label: 'Icono', type: 'select', required: true, options: BLIP_SPRITES },
    { key: 'colorBlip', label: 'Color con el negocio abierto', type: 'select', required: true, options: BLIP_COLOURS, hint: 'Cerrado se ve en blanco.' },
    { key: 'coords', label: 'Posición', type: 'coords', keys: ['x', 'y', 'z'] },
  ];

  const spriteLabel = (sprite: number) => BLIP_SPRITES.find((entry) => entry.value === String(sprite))?.label ?? `Icono ${sprite}`;
  const colourLabel = (colour: number) => BLIP_COLOURS.find((entry) => entry.value === String(colour))?.label ?? `Color ${colour}`;

  const toPayload = (values: Record<string, unknown>) => ({
    ...values,
    valueBlip: Number(values.valueBlip),
    colorBlip: Number(values.colorBlip),
  });

  return (
    <Section<Blip>
      title="Blips"
      description="Marcas del mapa que ven todos los jugadores."
      addLabel="Añadir blip"
      emptyText="Este trabajo no tiene blips."
      rows={asList<Blip>(job.blips)}
      columns={[
        { label: 'Nombre', render: (blip) => <strong>{blip.label}</strong> },
        { label: 'Icono', render: (blip) => spriteLabel(blip.blipsprite) },
        { label: 'Color', render: (blip) => colourLabel(blip.blipcolor) },
        { label: 'Posición', render: (blip) => <code>{coordsText(blip.x, blip.y, blip.z)}</code> },
      ]}
      fields={fields}
      defaults={{ labelBlip: job.label, valueBlip: '52', colorBlip: '2' }}
      toForm={(blip) => ({ labelBlip: blip.label, valueBlip: String(blip.blipsprite), colorBlip: String(blip.blipcolor), x: blip.x, y: blip.y, z: blip.z })}
      onCreate={(values) => run('createBlip', { job: job.name, ...toPayload(values) })}
      onEdit={(blip, values) => run('updateBlip', { job: job.name, id: blip.id, ...toPayload(values) })}
      onDelete={(blip) => run('deleteBlip', { job: job.name, id: blip.id })}
      onTeleport={(blip) => api.tp(blip)}
    />
  );
}

// Mercado

export function MarketTab({ job, run }: TabProps) {
  return (
    <Section<MarketItem>
      title="Mercado"
      description="Productos que la empresa pide con su dinero y recoge en una lonja."
      addLabel="Añadir producto"
      emptyText="El mercado de este trabajo está vacío."
      rows={asList<MarketItem>(job.items)}
      columns={[
        { label: 'Producto', render: (item) => <strong>{item.label}</strong> },
        { label: 'Objeto', render: (item) => <code>{item.name}</code> },
        { label: 'Precio', render: (item) => money(item.price) },
      ]}
      fields={[
        { key: 'name', label: 'Objeto de ox_inventory', type: 'text', required: true, placeholder: 'croissant_mixto' },
        { key: 'price', label: 'Precio por unidad', type: 'number', required: true, min: 0 },
      ]}
      editFields={[{ key: 'price', label: 'Precio por unidad', type: 'number', required: true, min: 0 }]}
      defaults={{ price: 0 }}
      toForm={(item) => ({ price: item.price })}
      onCreate={(values) => run('createItemMarket', { jobName: job.name, ...values })}
      onEdit={(item, values) => run('updateItemMarket', { jobName: job.name, id: item.id, ...values })}
      onDelete={(item) => run('deleteItemMarket', { jobName: job.name, id: item.id })}
    />
  );
}

// Vehículos

export function VehiclesTab({ job, run }: TabProps) {
  return (
    <Section<Vehicle>
      title="Vehículos"
      description="Se sacan en los puntos de Garaje, y solo estando de servicio."
      addLabel="Añadir vehículo"
      emptyText="Este trabajo no tiene vehículos."
      rows={asList<Vehicle>(job.vehicles)}
      columns={[
        { label: 'Modelo', render: (vehicle) => <strong>{vehicle.name}</strong> },
        { label: 'Vinilo', render: (vehicle) => vehicle.livery },
      ]}
      fields={[
        { key: 'name', label: 'Modelo', type: 'text', required: true, placeholder: 'taco' },
        { key: 'livery', label: 'Vinilo', type: 'number', min: 0 },
      ]}
      defaults={{ livery: 0 }}
      onCreate={(values) => run('insertVehicle', { jobName: job.name, ...values })}
      onDelete={(vehicle) => run('deleteVehicle', { jobName: job.name, id: vehicle.id })}
    />
  );
}

// Menú F6

const OPTIONS: { value: string; description: string }[] = [
  { value: 'Facturar', description: 'Enviar facturas a los clientes' },
  { value: 'Cachear', description: 'Registrar a alguien con las manos arriba' },
  { value: 'Compraventa', description: 'Comprar y vender vehículos de jugadores' },
  { value: 'Reparar', description: 'Reparar el vehículo cercano' },
  { value: 'Abrir cerradura', description: 'Forzar un vehículo cercano' },
  { value: 'Incautar', description: 'Enviar un vehículo al depósito' },
  { value: 'Limpiar', description: 'Limpiar el vehículo cercano' },
  { value: 'Desvolcar', description: 'Enderezar el vehículo cercano' },
  { value: 'Esposar', description: 'Esposar a alguien cercano' },
  { value: 'Abrir/Cerrar Negocio', description: 'Avisar a todos de que el negocio abre o cierra' },
  { value: 'Enviar anuncio', description: 'Enviar un anuncio a todo el servidor' },
];

export function OptionsTab({ job, run }: TabProps) {
  const perms = asList<Perm>(job.perms);
  const available = OPTIONS.filter((option) => !perms.some((perm) => perm.typePermission === option.value));

  return (
    <Section<Perm>
      title="Menú F6"
      description="Lo que pueden hacer todos los empleados de servicio con la tecla F6."
      addLabel={available.length ? 'Añadir opción' : undefined}
      emptyText="Este trabajo no tiene opciones, así que F6 no abre nada."
      rows={perms}
      columns={[
        { label: 'Opción', render: (perm) => <strong>{perm.typePermission}</strong> },
        { label: 'Para qué sirve', render: (perm) => <span className="muted">{OPTIONS.find((option) => option.value === perm.typePermission)?.description ?? ''}</span> },
      ]}
      fields={[{
        key: 'type',
        label: 'Opción',
        type: 'select',
        required: true,
        options: available.map((option) => ({ value: option.value, label: `${option.value}: ${option.description}` })),
      }]}
      onCreate={available.length ? (values) => run('insertOption', { jobName: job.name, type: values.type }) : undefined}
      onDelete={(perm) => run('deletePerm', { jobName: job.name, id: perm.id })}
    />
  );
}

// Teleports

export const TELEPORT_COORD_FIELDS: Field[] = [
  { key: 'entrance', label: 'Entrada', type: 'coords', keys: ['entrance_x', 'entrance_y', 'entrance_z', 'entrance_heading'] },
  { key: 'exit', label: 'Salida', type: 'coords', keys: ['exit_x', 'exit_y', 'exit_z', 'exit_heading'] },
];

export function TeleportsTab({ job, run }: TabProps) {
  const fields: Field[] = [
    { key: 'label', label: 'Nombre', type: 'text', required: true },
    ...TELEPORT_COORD_FIELDS,
    { key: 'job_only', label: 'Solo para este trabajo', type: 'switch', hint: 'Si no, lo puede usar cualquier jugador.' },
    { key: 'on_duty_only', label: 'Solo de servicio', type: 'switch' },
    { key: 'allow_vehicle', label: 'Permitir vehículos', type: 'switch' },
  ];

  return (
    <Section<Teleport>
      title="Teleports"
      description="Conectan dos puntos en los dos sentidos."
      addLabel="Añadir teleport"
      emptyText="Este trabajo no tiene teleports."
      rows={asList<Teleport>(job.teleports)}
      columns={[
        { label: 'Nombre', render: (teleport) => <strong>{teleport.label}</strong> },
        { label: 'Acceso', render: (teleport) => (teleport.job_only ? 'Empleados' : 'Público') },
        { label: 'Servicio', render: (teleport) => (teleport.on_duty_only ? 'Obligatorio' : <span className="muted">No</span>) },
        { label: 'Vehículos', render: (teleport) => (teleport.allow_vehicle ? 'Sí' : <span className="muted">No</span>) },
      ]}
      fields={fields}
      defaults={{ job_only: true, on_duty_only: false, allow_vehicle: false, entrance_heading: 0, exit_heading: 0 }}
      toForm={(teleport) => ({ ...teleport })}
      onCreate={(values) => run('createTeleport', { job: job.name, ...values })}
      onEdit={(teleport, values) => run('updateTeleport', { job: job.name, id: teleport.id, ...values })}
      onDelete={(teleport) => run('deleteTeleport', { job: job.name, id: teleport.id })}
      onTeleport={(teleport) => api.tp({ x: teleport.entrance_x, y: teleport.entrance_y, z: teleport.entrance_z })}
    />
  );
}
