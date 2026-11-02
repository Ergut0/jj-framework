export type Values = Record<string, number>;

export interface Parameter {
  key: string;
  category: string;
  label: string;
  desc: string;
  step: number;
  unit?: string;
  int: boolean;
  special: boolean;
  alsoIn?: string[];
}

export interface Category {
  id: string;
  label: string;
  icon: string;
}

export interface Rules {
  applyTemp: boolean;
  saveProfiles: boolean;
  install: boolean;
  modelDefault: boolean;
  editAny: boolean;
  deleteAny: boolean;
  import: boolean;
  export: boolean;
  panel: boolean;
  logs: boolean;
  settings: boolean;
  maxRelative?: number;
}

export interface Profile {
  id: number;
  name: string;
  modelHash: number;
  modelName?: string;
  class?: number;
  preset?: string;
  global: boolean;
  authorName?: string;
  own: boolean;
  version: number;
  createdAt: number;
  updatedAt: number;
  paramCount: number;
  params?: Values;
  modelDefault: boolean;
  plates: string[];
  canEdit: boolean;
  canDelete: boolean;
}

export interface VehicleState {
  temp?: { label: string; by: string; expires?: number; profileId?: number; params?: Values };
  persistent?: { id: number; name: string; source: 'install' | 'model' };
  autoApply: boolean;
}

export interface Preset {
  id: string;
  label: string;
  desc: string;
  compatible: boolean;
  values: Values;
}

export interface Settings {
  autoApply: boolean;
  testMinutes: number;
  mechanicMaxRelative: number;
  mechanicSave: boolean;
  mechanicInstall: boolean;
}

export interface OpenData {
  level: 'mechanic' | 'admin' | 'superadmin';
  rules: Rules;
  settings?: Settings;
  vehicle?: { netId: number; modelHash: number; modelName?: string; plate?: string; class: number; workshop?: string };
  allowed?: string[];
  limits?: Record<string, { min: number; max: number }>;
  profiles?: Profile[];
  state?: VehicleState;
  testMinutes?: number;
}

export interface VehicleInfo {
  label: string;
  modelName?: string;
  plate?: string;
  class: number;
  workshop?: string;
}

export interface OpenMessage {
  data: OpenData;
  parameters: Parameter[];
  categories: Category[];
  speedUnit: string;
  original?: Values;
  current?: Values;
  presets?: Preset[];
  vehicle?: VehicleInfo;
}

export interface LogEntry {
  id: number;
  action: string;
  label: string;
  actor?: string;
  target?: string;
  details?: string;
  createdAt: number;
}

export interface HistoryEntry {
  id: number;
  version: number;
  name: string;
  params: Values;
  editedBy?: string;
  createdAt: number;
}

declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = !window.invokeNative;

const resource = window.GetParentResourceName?.() ?? 'jj_handling';

export type Result<T> = T & { error?: string };

export async function fetchNui<T = Record<string, unknown>>(name: string, data: unknown = {}): Promise<Result<T> | undefined> {
  if (isBrowser) return undefined;
  try {
    const response = await fetch(`https://${resource}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    return (await response.json()) as Result<T>;
  } catch {
    return undefined;
  }
}

// Lua manda las tablas vacías como objeto o como lista según el caso
export const toList = <T,>(list: unknown): T[] => (Array.isArray(list) ? list : list && typeof list === 'object' ? (Object.values(list) as T[]) : []);
export const toValues = (values: unknown): Values => (values && typeof values === 'object' && !Array.isArray(values) ? (values as Values) : {});

export const normalizeProfile = (profile: Profile): Profile => ({ ...profile, params: profile.params ? toValues(profile.params) : undefined, plates: toList<string>(profile.plates) });

export const decimalsOf = (step: number) => Math.max(0, Math.min(5, -Math.floor(Math.log10(step))));

export const formatValue = (value: number | undefined, step: number) => (value === undefined || Number.isNaN(value) ? '—' : value.toFixed(decimalsOf(step)));

export const formatDate = (seconds?: number) =>
  seconds ? new Date(seconds * 1000).toLocaleString('es-ES', { day: '2-digit', month: '2-digit', year: '2-digit', hour: '2-digit', minute: '2-digit' }) : '—';

export const CLASS_NAMES: Record<number, string> = {
  0: 'Compacto', 1: 'Sedán', 2: 'SUV', 3: 'Coupé', 4: 'Muscle', 5: 'Clásico deportivo', 6: 'Deportivo', 7: 'Superdeportivo',
  8: 'Moto', 9: 'Todoterreno', 10: 'Industrial', 11: 'Utilitario', 12: 'Furgoneta', 17: 'Servicio', 18: 'Emergencias',
  19: 'Militar', 20: 'Comercial', 22: 'Fórmula',
};

// Datos para ver la interfaz en el navegador
const P = (key: string, category: string, label: string, step: number, desc: string, extra: Partial<Parameter> = {}): Parameter => ({ key, category, label, step, desc, int: false, special: false, ...extra });

export const sampleParameters: Parameter[] = [
  P('fInitialDriveForce', 'performance', 'Fuerza del motor', 0.005, 'Aceleración. Multiplica la fuerza que llega a las ruedas.'),
  P('fDriveInertia', 'performance', 'Inercia del motor', 0.01, 'Lo rápido que sube de vueltas. Más alto, respuesta más viva.'),
  P('fInitialDriveMaxFlatVel', 'performance', 'Velocidad máxima teórica', 1, 'Velocidad punta en llano según el meta.', { unit: 'km/h' }),
  P('fClutchChangeRateScaleUpShift', 'performance', 'Cambio a marcha superior', 0.1, 'Rapidez del embrague al subir de marcha.'),
  P('fClutchChangeRateScaleDownShift', 'performance', 'Cambio a marcha inferior', 0.1, 'Rapidez del embrague al reducir.'),
  P('fDriveBiasFront', 'traction', 'Reparto de tracción delantera', 0.01, '0 = trasera, 1 = delantera, 0.5 = 4x4 al 50 %.'),
  P('nInitialDriveGears', 'traction', 'Número de marchas', 1, 'Se aplica también la marcha más alta.', { int: true, special: true }),
  P('fTractionCurveMax', 'traction', 'Agarre máximo', 0.01, 'Agarre en curva y al acelerar en el punto óptimo de deslizamiento.'),
  P('fTractionCurveMin', 'traction', 'Agarre mínimo', 0.01, 'Agarre cuando la rueda ya desliza.'),
  P('fTractionCurveLateral', 'traction', 'Curva de agarre lateral', 0.1, 'Ángulo de deslizamiento con más agarre.', { unit: '°', alsoIn: ['steering'] }),
  P('fTractionSpringDeltaMax', 'traction', 'Elasticidad del neumático', 0.01, 'Distancia que se deforma el neumático antes de perder agarre.'),
  P('fLowSpeedTractionLossMult', 'traction', 'Pérdida de agarre a baja velocidad', 0.01, 'Patinaje al arrancar. 0 = sin patinar.'),
  P('fTractionLossMult', 'traction', 'Pérdida de agarre en superficie', 0.01, 'Cuánto afecta tierra, hierba o mojado al agarre.'),
  P('fBrakeForce', 'brakes', 'Fuerza de frenado', 0.01, 'Potencia del freno de servicio.'),
  P('fBrakeBiasFront', 'brakes', 'Reparto de frenada delantero', 0.01, 'Parte de la frenada en el eje delantero.'),
  P('fHandBrakeForce', 'brakes', 'Fuerza del freno de mano', 0.01, 'Potencia del freno de mano.'),
  P('fSuspensionForce', 'suspension', 'Rigidez', 0.05, 'Fuerza de los muelles. Más alto, más dura.'),
  P('fSuspensionCompDamp', 'suspension', 'Amortiguación en compresión', 0.05, 'Resistencia del amortiguador al hundirse.'),
  P('fSuspensionReboundDamp', 'suspension', 'Amortiguación en rebote', 0.05, 'Resistencia del amortiguador al extenderse.'),
  P('fSuspensionUpperLimit', 'suspension', 'Recorrido superior', 0.005, 'Lo que puede subir la rueda.'),
  P('fSuspensionLowerLimit', 'suspension', 'Recorrido inferior', 0.005, 'Lo que puede bajar la rueda.'),
  P('fSuspensionRaise', 'suspension', 'Altura de la carrocería', 0.005, 'Positivo sube el coche, negativo lo baja.'),
  P('fSuspensionBiasFront', 'suspension', 'Reparto de rigidez delantero', 0.01, 'Más alto, el eje delantero es más duro.'),
  P('fAntiRollBarForce', 'suspension', 'Barra estabilizadora', 0.01, 'Reduce la inclinación de la carrocería en curva.'),
  P('fAntiRollBarBiasFront', 'suspension', 'Reparto de la barra delantero', 0.01, 'Más delante tiende a subvirar, más detrás a sobrevirar.'),
  P('fSteeringLock', 'steering', 'Ángulo de giro', 0.5, 'Máximo giro de las ruedas.', { unit: '°' }),
  P('fRollCentreHeightFront', 'steering', 'Centro de balanceo delantero', 0.01, 'Más alto, menos balanceo delante.'),
  P('fRollCentreHeightRear', 'steering', 'Centro de balanceo trasero', 0.01, 'Más alto, menos balanceo detrás.'),
  P('fMass', 'weight', 'Masa', 10, 'Peso del vehículo.', { unit: 'kg', special: true }),
  P('fInitialDragCoeff', 'weight', 'Resistencia aerodinámica', 0.1, 'Frena el coche a alta velocidad.', { alsoIn: ['performance'] }),
  P('fDownforceModifier', 'weight', 'Carga aerodinámica', 0.1, 'Agarre extra a alta velocidad.'),
];

export const sampleCategories: Category[] = [
  { id: 'performance', label: 'Rendimiento', icon: 'fa-gauge-high' },
  { id: 'traction', label: 'Tracción y transmisión', icon: 'fa-gears' },
  { id: 'brakes', label: 'Frenado', icon: 'fa-circle-stop' },
  { id: 'suspension', label: 'Suspensión', icon: 'fa-car-burst' },
  { id: 'steering', label: 'Dirección y estabilidad', icon: 'fa-arrows-turn-to-dots' },
  { id: 'weight', label: 'Peso y resistencia', icon: 'fa-weight-hanging' },
];

const sampleOriginal: Values = {
  fInitialDriveForce: 0.32, fDriveInertia: 1, fInitialDriveMaxFlatVel: 154, fClutchChangeRateScaleUpShift: 3.5, fClutchChangeRateScaleDownShift: 3.5,
  fDriveBiasFront: 0.35, nInitialDriveGears: 6, fTractionCurveMax: 2.45, fTractionCurveMin: 2.2, fTractionCurveLateral: 22.5, fTractionSpringDeltaMax: 0.15,
  fLowSpeedTractionLossMult: 1, fTractionLossMult: 1, fBrakeForce: 0.9, fBrakeBiasFront: 0.45, fHandBrakeForce: 0.7, fSuspensionForce: 2.4,
  fSuspensionCompDamp: 1.4, fSuspensionReboundDamp: 2.2, fSuspensionUpperLimit: 0.1, fSuspensionLowerLimit: -0.12, fSuspensionRaise: 0,
  fSuspensionBiasFront: 0.5, fAntiRollBarForce: 0.8, fAntiRollBarBiasFront: 0.6, fSteeringLock: 40, fRollCentreHeightFront: 0.3, fRollCentreHeightRear: 0.3,
  fMass: 1400, fInitialDragCoeff: 8.5, fDownforceModifier: 1,
};

const sampleLimits: Record<string, { min: number; max: number }> = {
  fInitialDriveForce: { min: 0.01, max: 1.5 }, fDriveInertia: { min: 0.1, max: 2 }, fInitialDriveMaxFlatVel: { min: 50, max: 500 },
  fClutchChangeRateScaleUpShift: { min: 0.5, max: 15 }, fClutchChangeRateScaleDownShift: { min: 0.5, max: 15 }, fDriveBiasFront: { min: 0, max: 1 },
  nInitialDriveGears: { min: 1, max: 8 }, fTractionCurveMax: { min: 0.5, max: 5 }, fTractionCurveMin: { min: 0.5, max: 5 }, fTractionCurveLateral: { min: 5, max: 45 },
  fTractionSpringDeltaMax: { min: 0.01, max: 1 }, fLowSpeedTractionLossMult: { min: 0, max: 5 }, fTractionLossMult: { min: 0, max: 5 }, fBrakeForce: { min: 0.05, max: 5 },
  fBrakeBiasFront: { min: 0, max: 1 }, fHandBrakeForce: { min: 0, max: 5 }, fSuspensionForce: { min: 0.5, max: 10 }, fSuspensionCompDamp: { min: 0.1, max: 10 },
  fSuspensionReboundDamp: { min: 0.1, max: 10 }, fSuspensionUpperLimit: { min: 0, max: 0.5 }, fSuspensionLowerLimit: { min: -0.5, max: 0 },
  fSuspensionRaise: { min: -0.2, max: 0.2 }, fSuspensionBiasFront: { min: 0, max: 1 }, fAntiRollBarForce: { min: 0, max: 5 }, fAntiRollBarBiasFront: { min: 0, max: 1 },
  fSteeringLock: { min: 10, max: 75 }, fRollCentreHeightFront: { min: -0.5, max: 1 }, fRollCentreHeightRear: { min: -0.5, max: 1 }, fMass: { min: 200, max: 6000 },
  fInitialDragCoeff: { min: 0, max: 100 }, fDownforceModifier: { min: 0, max: 100 },
};

const now = Math.floor(Date.now() / 1000);

export const sampleOpen: OpenMessage = {
  data: {
    level: 'superadmin',
    rules: { applyTemp: true, saveProfiles: true, install: true, modelDefault: true, editAny: true, deleteAny: true, import: true, export: true, panel: true, logs: true, settings: true },
    settings: { autoApply: true, testMinutes: 20, mechanicMaxRelative: 0.35, mechanicSave: true, mechanicInstall: true },
    vehicle: { netId: 12, modelHash: 970598228, modelName: 'sultan', plate: 'ATL 042', class: 1, workshop: "Benny's" },
    allowed: Object.keys(sampleOriginal),
    limits: sampleLimits,
    profiles: [
      { id: 3, name: 'Sultan calle firme', modelHash: 970598228, modelName: 'sultan', class: 1, preset: 'sport', global: true, authorName: 'Josete', own: true, version: 4, createdAt: now - 86400 * 6, updatedAt: now - 3600, paramCount: 6, params: { fInitialDriveForce: 0.36, fTractionCurveMax: 2.6, fTractionCurveMin: 2.31, fBrakeForce: 0.99, fSuspensionForce: 2.76, fSuspensionRaise: -0.015 }, modelDefault: true, plates: [], canEdit: true, canDelete: true },
      { id: 7, name: 'Sultan drift taller', modelHash: 970598228, modelName: 'sultan', class: 1, preset: 'drift', global: false, authorName: 'Marcos (Bennys)', own: false, version: 1, createdAt: now - 86400, updatedAt: now - 86400, paramCount: 8, params: { fDriveBiasFront: 0, fSteeringLock: 55, fTractionCurveMax: 1.96, fTractionCurveMin: 1.58, fTractionCurveLateral: 22, fHandBrakeForce: 1.05, fLowSpeedTractionLossMult: 1.4, fInitialDriveForce: 0.368 }, modelDefault: false, plates: ['ATL 042'], canEdit: true, canDelete: true },
    ],
    state: { persistent: { id: 7, name: 'Sultan drift taller', source: 'install' }, autoApply: true },
    testMinutes: 20,
  },
  parameters: sampleParameters,
  categories: sampleCategories,
  speedUnit: 'kmh',
  original: sampleOriginal,
  current: { ...sampleOriginal, fDriveBiasFront: 0, fSteeringLock: 55, fTractionCurveMax: 1.96, fTractionCurveMin: 1.58, fTractionCurveLateral: 22, fHandBrakeForce: 1.05, fLowSpeedTractionLossMult: 1.4, fInitialDriveForce: 0.368 },
  presets: [
    { id: 'original', label: 'Original', desc: 'El handling de serie del vehículo.', compatible: true, values: {} },
    { id: 'sport', label: 'Deportivo', desc: 'Algo más de motor, agarre y frenos. Suspensión más firme.', compatible: true, values: { fInitialDriveForce: 0.3584, fTractionCurveMax: 2.597, fTractionCurveMin: 2.31, fBrakeForce: 0.99, fSuspensionForce: 2.76, fSuspensionRaise: -0.015, fAntiRollBarForce: 0.96 } },
    { id: 'sport_advanced', label: 'Deportivo avanzado', desc: 'Más potencia, cambios rápidos y menos balanceo.', compatible: true, values: { fInitialDriveForce: 0.4, fInitialDriveMaxFlatVel: 163, fClutchChangeRateScaleUpShift: 5.6, fTractionCurveMax: 2.744, fBrakeForce: 1.08, fSuspensionForce: 3.12, fSuspensionRaise: -0.03 } },
    { id: 'drift', label: 'Drift', desc: 'Propulsión trasera, más giro y agarre progresivo.', compatible: true, values: { fDriveBiasFront: 0, fSteeringLock: 55, fTractionCurveMax: 1.96, fTractionCurveMin: 1.584, fTractionCurveLateral: 22, fHandBrakeForce: 1.05 } },
    { id: 'racing', label: 'Racing', desc: 'Máximo agarre y frenada. Bajo y rígido.', compatible: true, values: { fInitialDriveForce: 0.384, fTractionCurveMax: 2.891, fBrakeForce: 1.125, fBrakeBiasFront: 0.6, fSuspensionRaise: -0.04 } },
    { id: 'drag', label: 'Drag', desc: 'Salida fuerte en línea recta. Gira peor.', compatible: true, values: { fInitialDriveForce: 0.448, fLowSpeedTractionLossMult: 0.5, fSteeringLock: 32 } },
    { id: 'offroad', label: 'Off-road', desc: 'Más altura y recorrido, suspensión blanda.', compatible: true, values: { fSuspensionRaise: 0.05, fTractionLossMult: 0.4, fDriveBiasFront: 0.5 } },
    { id: 'rally', label: 'Rally', desc: 'Buen agarre en tierra y freno de mano fuerte.', compatible: true, values: { fTractionLossMult: 0.6, fHandBrakeForce: 0.91, fBrakeBiasFront: 0.55 } },
    { id: 'realistic', label: 'Conducción realista', desc: 'Algo menos de agarre y frenada.', compatible: true, values: { fBrakeForce: 0.81, fTractionCurveMax: 2.3275, fSteeringLock: 38 } },
  ],
  vehicle: { label: 'Sultan', modelName: 'sultan', plate: 'ATL 042', class: 1, workshop: "Benny's" },
};

export const sampleLogs: LogEntry[] = [
  { id: 41, action: 'apply', label: 'Cambios temporales', actor: 'Josete', target: 'ATL 042', details: '{"label":"Drift"}', createdAt: now - 120 },
  { id: 40, action: 'install', label: 'Perfil instalado', actor: 'Marcos (Bennys)', target: 'ATL 042', details: '{"profile":"#7 Sultan drift taller"}', createdAt: now - 86000 },
  { id: 39, action: 'model_default', label: 'Perfil de serie', actor: 'Josete', target: 'sultan', details: '{"profile":"#3 Sultan calle firme"}', createdAt: now - 90000 },
  { id: 38, action: 'update', label: 'Perfil editado', actor: 'Josete', target: '#3 Sultan calle firme', details: '{"model":"sultan"}', createdAt: now - 95000 },
];
