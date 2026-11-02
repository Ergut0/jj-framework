import { createSlice, current, isFulfilled, isPending, isRejected, PayloadAction } from '@reduxjs/toolkit';
import type { RootState } from '.';
import {
  moveSlotsReducer,
  refreshSlotsReducer,
  setupInventoryReducer,
  stackSlotsReducer,
  swapSlotsReducer,
} from '../reducers';
import { normaliseInventory } from '../reducers/setupInventory';
import { State } from '../typings';
import { Inventory } from '../typings/inventory';
import { SlotWithItem } from '../typings/slot';

const initialState: State = {
  leftInventory: {
    id: '',
    type: '',
    slots: 0,
    maxWeight: 0,
    items: [],
    backpack: undefined,
  },
  rightInventory: {
    id: '',
    type: '',
    slots: 0,
    maxWeight: 0,
    items: [],
    backpack: undefined,
  },
  additionalMetadata: new Array(),
  itemAmount: 0,
  shiftPressed: false,
  isBusy: false,
  splitDialog: {
    open: false,
    item: null,
    amount: 1,
    inventoryType: 'player',
  },
  renameDialog: {
    open: false,
    mode: 'item' as 'item' | 'backpack',
    item: null,
    inventoryId: null,
    currentLabel: '',
    coords: null as { x: number; y: number } | null,
  },
};

export const inventorySlice = createSlice({
  name: 'inventory',
  initialState,
  reducers: {
    stackSlots: stackSlotsReducer,
    swapSlots: swapSlotsReducer,
    setupInventory: setupInventoryReducer,
    moveSlots: moveSlotsReducer,
    refreshSlots: refreshSlotsReducer,
    setAdditionalMetadata: (state, action: PayloadAction<Array<{ metadata: string; value: string }>>) => {
      const metadata = [];

      for (let i = 0; i < action.payload.length; i++) {
        const entry = action.payload[i];
        if (!state.additionalMetadata.find((el) => el.value === entry.value)) metadata.push(entry);
      }

      state.additionalMetadata = [...state.additionalMetadata, ...metadata];
    },
    setItemAmount: (state, action: PayloadAction<number>) => {
      state.itemAmount = action.payload;
    },
    setShiftPressed: (state, action: PayloadAction<boolean>) => {
      state.shiftPressed = action.payload;
    },
    setContainerWeight: (state, action: PayloadAction<number>) => {
      const container = state.leftInventory.items.find((item) => item.metadata?.container === state.rightInventory.id);

      if (!container) return;

      container.weight = action.payload;
    },
    setLeftBackpack: (state, action: PayloadAction<Inventory | undefined>) => {
      const normalised = normaliseInventory(action.payload);
      if (normalised) {
        state.leftInventory.backpack = normalised;
      } else {
        delete state.leftInventory.backpack;
      }
    },
    setRightBackpack: (state, action: PayloadAction<Inventory | undefined>) => {
      const normalised = normaliseInventory(action.payload);
      if (normalised) {
        state.rightInventory.backpack = normalised;
      } else {
        delete state.rightInventory.backpack;
      }
    },
    setBackpackLabel: (state, action: PayloadAction<{ inventoryId: string; label: string }>) => {
      const { inventoryId, label } = action.payload;
      if (state.leftInventory.backpack?.id === inventoryId) {
        state.leftInventory.backpack.label = label;
      }
      if (state.rightInventory.backpack?.id === inventoryId) {
        state.rightInventory.backpack.label = label;
      }
    },
    openSplitDialog: (
      state,
      action: PayloadAction<{ item: SlotWithItem; inventoryType: Inventory['type'] }>
    ) => {
      const { item, inventoryType } = action.payload;
      const baseAmount = Math.floor((item?.count ?? 1) / 2);
      state.splitDialog.open = true;
      state.splitDialog.item = item;
      state.splitDialog.amount = baseAmount > 0 ? baseAmount : 1;
      state.splitDialog.inventoryType = inventoryType;
    },
    closeSplitDialog: (state) => {
      state.splitDialog.open = false;
      state.splitDialog.item = null;
      state.splitDialog.amount = 1;
      state.splitDialog.inventoryType = 'player';
    },
    openRenameDialog: (
      state,
      action: PayloadAction<{ mode: 'item' | 'backpack'; item: SlotWithItem | null; inventoryId: string | number | null; currentLabel: string; coords?: { x: number; y: number } | null }>
    ) => {
      state.renameDialog.open = true;
      state.renameDialog.mode = action.payload.mode;
      state.renameDialog.item = action.payload.item;
      state.renameDialog.inventoryId = action.payload.inventoryId;
      state.renameDialog.currentLabel = action.payload.currentLabel;
      state.renameDialog.coords = action.payload.coords ?? null;
    },
    closeRenameDialog: (state) => {
      state.renameDialog.open = false;
      state.renameDialog.item = null;
      state.renameDialog.inventoryId = null;
      state.renameDialog.currentLabel = '';
      state.renameDialog.coords = null;
    },
    setSplitAmount: (state, action: PayloadAction<number>) => {
      state.splitDialog.amount = Math.floor(action.payload);
    },
  },
  extraReducers: (builder) => {
    builder.addMatcher(isPending, (state) => {
      state.isBusy = true;

      state.history = {
        leftInventory: current(state.leftInventory),
        rightInventory: current(state.rightInventory),
      };
    });
    builder.addMatcher(isFulfilled, (state) => {
      state.isBusy = false;
    });
    builder.addMatcher(isRejected, (state) => {
      if (state.history && state.history.leftInventory && state.history.rightInventory) {
        state.leftInventory = state.history.leftInventory;
        state.rightInventory = state.history.rightInventory;
      }
      state.isBusy = false;
    });
  },
});

export const {
  setAdditionalMetadata,
  setItemAmount,
  setShiftPressed,
  setupInventory,
  swapSlots,
  moveSlots,
  stackSlots,
  refreshSlots,
  setContainerWeight,
  setLeftBackpack,
  setRightBackpack,
  setBackpackLabel,
  openSplitDialog,
  closeSplitDialog,
  setSplitAmount,
  openRenameDialog,
  closeRenameDialog,
} = inventorySlice.actions;
export const selectLeftInventory = (state: RootState) => state.inventory.leftInventory;
export const selectRightInventory = (state: RootState) => state.inventory.rightInventory;
export const selectItemAmount = (state: RootState) => state.inventory.itemAmount;
export const selectIsBusy = (state: RootState) => state.inventory.isBusy;

export default inventorySlice.reducer;
