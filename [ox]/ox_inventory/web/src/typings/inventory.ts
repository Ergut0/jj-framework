import { Slot, CraftSlot } from './slot';
import { UtilityConfig, UtilityState } from './utility';
import { ClothingConfig, ClothingState } from './clothing';

export enum InventoryType {
  PLAYER = 'player',
  SHOP = 'shop',
  CONTAINER = 'container',
  CRAFTING = 'crafting',
  UTILITY = 'utility',
  OTHER_UTILITY = 'otherUtility',
  CLOTHING = 'clothing',
  OTHER_CLOTHING = 'otherClothing',
  BACKPACK = 'backpack',
  OTHER_BACKPACK = 'otherBackpack',
}

export type Inventory = {
  id: string;
  type: string;
  slots: number;
  items: Slot[];
  maxWeight?: number;
  label?: string;
  groups?: Record<string, number>;
  utility?: UtilityState;
  utilityConfig?: UtilityConfig;
  clothingConfig?: ClothingConfig;
  clothing?: ClothingState;
  backpack?: Inventory;
  otherBackpack?: Inventory;
  storage?: Inventory;
  hideAll?: boolean;
  allowDirtyMoney?: boolean;
  paymentMethods?: {
    cash?: boolean;
    bank?: boolean;
    dirty?: boolean;
    black_money?: boolean;
  };
  crafting?: {
    xp?: {
      enabled: boolean;
      current: number;
      hideLocked?: boolean;
    };
    blueprints?: Record<string, boolean>;
    queue?: any[];
  };
};
