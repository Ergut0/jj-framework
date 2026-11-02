import type { GlobalTeleport, Job, LogEntry } from './types';

// Simulación del servidor para ver la interfaz en el navegador. Con ?jefe en la URL se ve como jefe
const asBoss = new URLSearchParams(window.location.search).has('jefe');

const jobs: Job[] = [
  {
    id: 1,
    name: 'burgershot',
    label: 'Burger Shot',
    open: true,
    level: 2,
    experience: 45,
    money: 18450,
    grades: [
      { id: 0, name: 'empleado', label: 'Empleado', salary: 600, permission: false },
      { id: 1, name: 'encargado', label: 'Encargado', salary: 900, permission: false },
      { id: 2, name: 'jefe', label: 'Jefe', salary: 1200, permission: true },
    ],
    employees: [
      { identifier: 'c1', nombre: 'Lucía Romero', grade: 2, gradeLabel: 'Jefe', onduty: true, online: true },
      { identifier: 'c2', nombre: 'Marcos Vidal', grade: 1, gradeLabel: 'Encargado', onduty: true, online: true },
      { identifier: 'c3', nombre: 'Ana Ruiz', grade: 0, gradeLabel: 'Empleado', onduty: false, online: true },
      { identifier: 'c4', nombre: 'Pablo Gil', grade: 0, gradeLabel: 'Empleado', onduty: false, online: false },
    ],
    points: [
      { id: 1, x: -1193.2, y: -892.1, z: 13.99, heading: 120, typePoint: 'Servicio', radius: 25 },
      { id: 2, x: -1196.5, y: -896.3, z: 13.99, heading: 35, typePoint: 'Inventario', radius: 25 },
      { id: 3, x: -1180, y: -885, z: 14, heading: 0, typePoint: 'Zona Centro', radius: 45 },
    ],
    blips: [{ id: 1, x: -1193.2, y: -892.1, z: 13.99, label: 'Burger Shot', blipsprite: 106, blipcolor: 1 }],
    items: [{ id: 1, name: 'croissant_mixto', label: 'Croissant mixto', price: 12 }],
    vehicles: [{ id: 1, name: 'taco', livery: 0 }],
    perms: [
      { id: 1, typePermission: 'Facturar' },
      { id: 2, typePermission: 'Abrir/Cerrar Negocio' },
    ],
    teleports: [
      {
        id: 1, label: 'Sótano', job_only: true, on_duty_only: false, allow_vehicle: false,
        entrance_x: -1190, entrance_y: -890, entrance_z: 14, entrance_heading: 0,
        exit_x: -1190, exit_y: -890, exit_z: 8, exit_heading: 180,
      },
    ],
  },
  {
    id: 2,
    name: 'taller',
    label: 'Taller Benny',
    open: false,
    level: 1,
    experience: 10,
    money: 2300,
    grades: [{ id: 0, name: 'empleado', label: 'Aprendiz', salary: 500, permission: false }],
    employees: [],
    points: [],
    blips: [],
    items: [],
    vehicles: [],
    perms: [],
    teleports: [],
  },
];

const globalTeleports: GlobalTeleport[] = [
  {
    id: 1, label: 'Club privado', password: 'atlantis', bucket: 5,
    entrance_x: 100, entrance_y: 200, entrance_z: 30, entrance_heading: 0,
    exit_x: 110, exit_y: 210, exit_z: 40, exit_heading: 90,
  },
];

const now = Math.floor(Date.now() / 1000);
const logs: LogEntry[] = [
  { id: 6, category: 'servicio', actor: 'Marcos Vidal', message: 'Ha entrado de servicio', created_at: now - 120 },
  { id: 5, category: 'empleados', actor: 'Lucía Romero', message: 'Ha contratado a Ana Ruiz como Empleado', created_at: now - 900 },
  { id: 4, category: 'facturas', actor: 'Lucía Romero', message: 'Ha enviado una factura de $350 a Pablo Gil: menú para 6', created_at: now - 3600 },
  { id: 3, category: 'dinero', actor: 'Lucía Romero', message: 'Ha ingresado $5000 en la sociedad', created_at: now - 7200 },
  { id: 2, category: 'negocio', actor: 'Lucía Romero', message: 'Ha abierto el negocio', created_at: now - 8000 },
  { id: 1, category: 'config', actor: 'Admin', message: 'Ha creado el trabajo Burger Shot', created_at: now - 90000 },
];

let nextId = 100;

const findJob = (name: unknown) => jobs.find((job) => job.name === name);

const removeById = <T extends { id: number }>(list: T[], id: unknown) => {
  const index = list.findIndex((entry) => entry.id === id);
  if (index >= 0) list.splice(index, 1);
};

function runAction(name: string, d: Record<string, any>) {
  const job = findJob(d.jobName ?? d.job ?? d.name);
  switch (name) {
    case 'createJob':
      jobs.push({
        id: nextId++, name: d.job, label: d.jobLabel, open: true, level: 1, experience: 0, money: 0,
        grades: [
          { id: 0, name: 'empleado', label: 'Empleado', salary: 600, permission: false },
          { id: 1, name: 'jefe', label: 'Jefe', salary: 1200, permission: true },
        ],
        employees: [], points: [], blips: [], items: [], vehicles: [], perms: [], teleports: [],
      });
      break;
    case 'deleteJob':
      removeById(jobs, d.id);
      break;
    case 'updateJob':
      if (job) Object.assign(job, { label: d.label, img: d.img, level: d.level, experience: d.experience });
      break;
    case 'insertGrade':
      job?.grades.push({ id: job.grades.length, name: d.id, label: d.label, salary: d.salary, permission: false });
      break;
    case 'updateGrade':
      if (job) Object.assign(job.grades.find((grade) => grade.id === d.idGrade) ?? {}, { name: d.name, label: d.label, salary: d.salary, permission: d.permission });
      break;
    case 'deleteGrade':
      if (job) removeById(job.grades, d.idGrade);
      break;
    case 'hirePlayer':
      job?.employees.push({ identifier: `c${nextId++}`, nombre: `Jugador ${d.src}`, grade: d.grade, gradeLabel: job.grades.find((grade) => grade.id === d.grade)?.label ?? '', onduty: true, online: true });
      break;
    case 'firePlayer':
      if (job) job.employees = job.employees.filter((employee) => employee.identifier !== d.id);
      break;
    case 'promotePlayer':
      if (job) Object.assign(job.employees.find((employee) => employee.identifier === d.id) ?? {}, { grade: d.gradeId, gradeLabel: job.grades.find((grade) => grade.id === d.gradeId)?.label });
      break;
    case 'createPoint':
      job?.points.push({ id: nextId++, x: d.x, y: d.y, z: d.z, heading: d.heading, typePoint: d.typePoint, radius: d.radius ?? 25 });
      break;
    case 'updatePoint':
      if (job) Object.assign(job.points.find((point) => point.id === d.id) ?? {}, d);
      break;
    case 'deletePoint':
      if (job) removeById(job.points, d.id);
      break;
    case 'createBlip':
      job?.blips.push({ id: nextId++, x: d.x, y: d.y, z: d.z, label: d.labelBlip, blipsprite: d.valueBlip, blipcolor: d.colorBlip });
      break;
    case 'updateBlip':
      if (job) Object.assign(job.blips.find((blip) => blip.id === d.id) ?? {}, { x: d.x, y: d.y, z: d.z, label: d.labelBlip, blipsprite: d.valueBlip, blipcolor: d.colorBlip });
      break;
    case 'deleteBlip':
      if (job) removeById(job.blips, d.id);
      break;
    case 'createItemMarket':
      job?.items.push({ id: nextId++, name: d.name, label: d.name, price: d.price });
      break;
    case 'updateItemMarket':
      if (job) Object.assign(job.items.find((item) => item.id === d.id) ?? {}, { price: d.price });
      break;
    case 'deleteItemMarket':
      if (job) removeById(job.items, d.id);
      break;
    case 'insertVehicle':
      job?.vehicles.push({ id: nextId++, name: d.name, livery: d.livery ?? 0 });
      break;
    case 'deleteVehicle':
      if (job) removeById(job.vehicles, d.id);
      break;
    case 'insertOption':
      job?.perms.push({ id: nextId++, typePermission: d.type });
      break;
    case 'deletePerm':
      if (job) removeById(job.perms, d.id);
      break;
    case 'createTeleport':
      job?.teleports.push({ ...d, id: nextId++ } as never);
      break;
    case 'updateTeleport':
      if (job) Object.assign(job.teleports.find((teleport) => teleport.id === d.id) ?? {}, d);
      break;
    case 'deleteTeleport':
      if (job) removeById(job.teleports, d.id);
      break;
    case 'createGlobalTeleport':
      globalTeleports.push({ ...d, id: nextId++ } as never);
      break;
    case 'updateGlobalTeleport':
      Object.assign(globalTeleports.find((teleport) => teleport.id === d.id) ?? {}, d);
      break;
    case 'deleteGlobalTeleport':
      removeById(globalTeleports, d.id);
      break;
  }
}

const copy = <T>(value: T): T => JSON.parse(JSON.stringify(value));

export function mockRequest(name: string, data: unknown): unknown {
  switch (name) {
    case 'getPanel':
      return asBoss
        ? { admin: false, job: copy(jobs[0]), maxLevel: 4, maxExp: 100 }
        : { admin: true, jobs: jobs.map(({ id, name: jobName, label, img, open }) => ({ id, name: jobName, label, img, open })), maxLevel: 4, maxExp: 100 };
    case 'getJob':
      return copy(findJob(data)) ?? false;
    case 'getGlobalTeleports':
      return copy(globalTeleports);
    case 'getLogs':
      return data === 'burgershot' ? copy(logs) : [];
    case 'getCoords':
      return { x: 215.67, y: -791.04, z: 30.83, heading: 158.5 };
    case 'action': {
      const { name: actionName, data: actionData } = data as { name: string; data: Record<string, unknown> };
      runAction(actionName, actionData);
      return true;
    }
    default:
      return {};
  }
}
