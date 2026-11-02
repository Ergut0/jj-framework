export interface Range {
  min: number;
  max: number;
  factor?: number;
}

export interface Blacklist {
  drawables: number[];
  textures: number[];
}

export interface Tattoo {
  name: string;
  label: string;
  zone: string;
  collection: string;
  hashMale: string;
  hashFemale: string;
  opacity?: number;
}

export interface ComponentSettings {
  component_id: number;
  drawable: Range;
  texture: Range;
  blacklist: Blacklist;
}

export interface PropSettings {
  prop_id: number;
  drawable: Range;
  texture: Range;
  blacklist: Blacklist;
}

export type Rgb = [number, number, number];

export interface HairSettings {
  style: Range;
  texture: Range;
  color: { items: Rgb[] };
  highlight: { items: Rgb[] };
  blacklist: Blacklist;
}

export interface OverlaySettings {
  style: Range;
  opacity: Range;
  color?: { items: Rgb[] };
}

export interface Settings {
  ped: { model: { items: string[] } };
  components: ComponentSettings[];
  props: PropSettings[];
  headBlend: Record<string, Range>;
  faceFeatures: Record<string, Range>;
  headOverlays: Record<string, OverlaySettings>;
  hair: HairSettings;
  eyeColor: Range;
  tattoos: { items: Record<string, Tattoo[]>; opacity: Range };
}

export interface Component {
  component_id: number;
  drawable: number;
  texture: number;
}

export interface Prop {
  prop_id: number;
  drawable: number;
  texture: number;
}

export interface Overlay {
  style: number;
  opacity: number;
  color: number;
  secondColor: number;
}

export type Tattoos = Record<string, Tattoo[]>;

export interface Appearance {
  model: string;
  headBlend: Record<string, number>;
  faceFeatures: Record<string, number>;
  headOverlays: Record<string, Overlay>;
  components: Component[];
  props: Prop[];
  hair: { style: number; color: number; highlight: number; texture: number };
  tattoos: Tattoos;
  eyeColor: number;
}

export interface Config {
  ped: boolean;
  headBlend: boolean;
  faceFeatures: boolean;
  headOverlays: boolean;
  components: boolean;
  props: boolean;
  tattoos: boolean;
  enableExit: boolean;
  hasTracker: boolean;
  automaticFade: boolean;
  componentConfig: Record<string, boolean>;
  propConfig: Record<string, boolean>;
}

// Textos de locales/*.lua: la estructura la marca cada idioma
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type Locales = any;
