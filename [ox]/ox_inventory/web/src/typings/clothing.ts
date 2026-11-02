import { Slot } from './slot';

export type ClothingSlotDefinition = {
  label: string;
  itemName?: string;
  component?: number;
  prop?: number;
  icon?: string;
};

export type ClothingConfig = {
  enabled?: boolean;
  slotOffset?: number;
  layout?: {
    left?: number[];
    right?: number[];
  };
  slots?: Record<number, ClothingSlotDefinition>;
};

export type ClothingState = {
  offset: number;
  items: Record<number, Slot>;
};

export type ClothingAppearanceEntry = {
  drawable: number;
  texture: number;
};

export type ClothingAppearance = {
  components?: Record<string, ClothingAppearanceEntry>;
  props?: Record<string, ClothingAppearanceEntry>;
};
