// Datos para ver la interfaz en el navegador. En el juego no se cargan
import locales from './mockLocales.json';
import type { Appearance, ComponentSettings, Config, PropSettings, Rgb, Settings, Tattoo } from './types';

const FACE = ['noseWidth', 'nosePeakHigh', 'nosePeakSize', 'noseBoneHigh', 'nosePeakLowering', 'noseBoneTwist', 'eyeBrownHigh', 'eyeBrownForward', 'cheeksBoneHigh', 'cheeksBoneWidth', 'cheeksWidth', 'eyesOpening', 'lipsThickness', 'jawBoneWidth', 'jawBoneBackSize', 'chinBoneLowering', 'chinBoneLenght', 'chinBoneSize', 'chinHole', 'neckThickness'];
const OVERLAYS = ['blemishes', 'beard', 'eyebrows', 'ageing', 'makeUp', 'blush', 'complexion', 'sunDamage', 'lipstick', 'moleAndFreckles', 'chestHair', 'bodyBlemishes'];
const COMPONENTS = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
const PROPS = [0, 1, 2, 6, 7];

const hsl = (h: number, s: number, l: number): Rgb => {
  const a = s * Math.min(l, 1 - l);
  const f = (n: number) => {
    const k = (n + h / 30) % 12;
    return Math.round(255 * (l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1)));
  };
  return [f(0), f(8), f(4)];
};

const hair = Array.from({ length: 64 }, (_, i) => hsl(20 + i * 5, 0.55, 0.15 + (i % 8) * 0.08));
const makeUp = Array.from({ length: 64 }, (_, i) => hsl(i * 6, 0.7, 0.45));
const colored: Record<string, Rgb[]> = { beard: hair, eyebrows: hair, chestHair: hair, makeUp, blush: makeUp, lipstick: makeUp };

const blacklist = { drawables: [] as number[], textures: [] as number[] };
const component = (id: number): ComponentSettings => ({ component_id: id, drawable: { min: 0, max: 120 }, texture: { min: 0, max: 8 }, blacklist });
const prop = (id: number): PropSettings => ({ prop_id: id, drawable: { min: -1, max: 60 }, texture: { min: -1, max: 6 }, blacklist });
const hairSettings = { style: { min: 0, max: 75 }, color: { items: hair }, highlight: { items: hair }, texture: { min: 0, max: 4 }, blacklist };

const tattoo = (name: string, label: string, zone: string): Tattoo => ({ name, label, zone, collection: 'mpbeach_overlays', hashMale: `${name}_M`, hashFemale: `${name}_F` });

const settings: Settings = {
  ped: { model: { items: ['mp_m_freemode_01', 'mp_f_freemode_01', 'a_m_y_hipster_01', 'a_f_y_beach_01', 's_m_y_cop_01', 's_f_y_cop_01', 'u_m_y_zombie_01'] } },
  components: COMPONENTS.map(component),
  props: PROPS.map(prop),
  headBlend: {
    shapeFirst: { min: 0, max: 45 },
    shapeSecond: { min: 0, max: 45 },
    shapeThird: { min: 0, max: 45 },
    skinFirst: { min: 0, max: 45 },
    skinSecond: { min: 0, max: 45 },
    skinThird: { min: 0, max: 45 },
    shapeMix: { min: 0, max: 1, factor: 0.1 },
    skinMix: { min: 0, max: 1, factor: 0.1 },
    thirdMix: { min: 0, max: 1, factor: 0.1 },
  },
  faceFeatures: Object.fromEntries(FACE.map((feature) => [feature, { min: -1, max: 1, factor: 0.1 }])),
  headOverlays: Object.fromEntries(
    OVERLAYS.map((overlay) => [overlay, { style: { min: 0, max: 28 }, opacity: { min: 0, max: 1, factor: 0.1 }, ...(colored[overlay] ? { color: { items: colored[overlay] } } : {}) }]),
  ),
  hair: hairSettings,
  eyeColor: { min: 0, max: 30 },
  tattoos: {
    items: {
      ZONE_TORSO: [tattoo('torso_00', 'Tridente del pecho', 'ZONE_TORSO'), tattoo('torso_01', 'Ancla', 'ZONE_TORSO'), tattoo('torso_02', 'Alas', 'ZONE_TORSO')],
      ZONE_HEAD: [tattoo('head_00', 'Estrella', 'ZONE_HEAD')],
      ZONE_LEFT_ARM: [tattoo('larm_00', 'Rosa', 'ZONE_LEFT_ARM')],
      ZONE_RIGHT_ARM: [tattoo('rarm_00', 'Calavera', 'ZONE_RIGHT_ARM')],
      ZONE_LEFT_LEG: [tattoo('lleg_00', 'Serpiente', 'ZONE_LEFT_LEG')],
      ZONE_RIGHT_LEG: [tattoo('rleg_00', 'Dragón', 'ZONE_RIGHT_LEG')],
      ZONE_HAIR: [tattoo('hair_00', 'Sin degradado', 'ZONE_HAIR'), tattoo('hair_01', 'Degradado', 'ZONE_HAIR')],
    },
    opacity: { min: 0.1, max: 1, factor: 0.1 },
  },
};

const appearance: Appearance = {
  model: 'mp_m_freemode_01',
  headBlend: { shapeFirst: 0, shapeSecond: 0, shapeThird: 0, skinFirst: 0, skinSecond: 0, skinThird: 0, shapeMix: 0.5, skinMix: 0.5, thirdMix: 0 },
  faceFeatures: Object.fromEntries(FACE.map((feature) => [feature, 0])),
  headOverlays: Object.fromEntries(OVERLAYS.map((overlay) => [overlay, { style: 0, opacity: 0, color: 0, secondColor: 0 }])),
  components: COMPONENTS.map((id) => ({ component_id: id, drawable: 0, texture: 0 })),
  props: PROPS.map((id) => ({ prop_id: id, drawable: -1, texture: -1 })),
  hair: { style: 0, color: 0, highlight: 0, texture: 0 },
  tattoos: {},
  eyeColor: 0,
};

const enabled = (keys: string[]) => Object.fromEntries(keys.map((key) => [key, true]));

const config: Config = {
  ped: true,
  headBlend: true,
  faceFeatures: true,
  headOverlays: true,
  components: true,
  props: true,
  tattoos: true,
  enableExit: true,
  hasTracker: false,
  automaticFade: false,
  componentConfig: enabled(['masks', 'upperBody', 'lowerBody', 'bags', 'shoes', 'scarfAndChains', 'shirts', 'bodyArmor', 'decals', 'jackets']),
  propConfig: enabled(['hats', 'glasses', 'ear', 'watches', 'bracelets']),
};

export function answer(name: string, data: unknown): unknown {
  switch (name) {
    case 'appearance_get_locales':
      return locales;
    case 'appearance_get_settings':
      return { appearanceSettings: settings };
    case 'appearance_get_data':
      return { config, appearanceData: appearance };
    case 'appearance_change_model':
      return { appearanceSettings: settings, appearanceData: { ...appearance, model: data } };
    case 'appearance_change_component':
      return component((data as { component_id: number }).component_id);
    case 'appearance_change_prop':
      return prop((data as { prop_id: number }).prop_id);
    case 'appearance_change_hair':
      return hairSettings;
    case 'appearance_apply_tattoo':
      return true;
    default:
      return 1;
  }
}
