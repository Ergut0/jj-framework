import { Inventory } from './inventory';
import { Slot, SlotWithItem } from './slot';

export type State = {
  leftInventory: Inventory;
  rightInventory: Inventory;
  itemAmount: number;
  shiftPressed: boolean;
  isBusy: boolean;
  additionalMetadata: Array<{ metadata: string; value: string }>;
  history?: {
    leftInventory: Inventory;
    rightInventory: Inventory;
  };
  splitDialog: {
    open: boolean;
    item: SlotWithItem | null;
    amount: number;
    inventoryType: Inventory['type'];
  };
  renameDialog: {
    open: boolean;
    mode: 'item' | 'backpack';
    item: SlotWithItem | null;
    inventoryId: string | number | null;
    currentLabel: string;
    coords: { x: number; y: number } | null;
  };
};
