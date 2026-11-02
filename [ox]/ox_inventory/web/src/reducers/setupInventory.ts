import { CaseReducer, PayloadAction } from '@reduxjs/toolkit';
import { getItemData, itemDurability, safeMetadata } from '../helpers';
import { Items } from '../store/items';
import { ClothingState, Inventory, Slot, State } from '../typings';

const normaliseClothing = (clothing?: ClothingState, curTime: number = Math.floor(Date.now() / 1000)) => {
  if (!clothing) return undefined;

  const items: Record<number, Slot> = {};

  Object.entries(clothing.items || {}).forEach(([slotId, slotData]) => {
    const numericSlot = Number(slotId);
    if (!Number.isFinite(numericSlot)) return;

    const nextSlot = { ...slotData, metadata: safeMetadata(slotData.metadata) };

    if (nextSlot.name) {
      if (typeof Items[nextSlot.name] === 'undefined') {
        getItemData(nextSlot.name);
      }

      nextSlot.durability = itemDurability(nextSlot.metadata, curTime);
    }

    items[numericSlot] = nextSlot;
  });

  return {
    ...clothing,
    items,
  };
};

export const normaliseInventory = (
  inventory?: Inventory,
  curTime: number = Math.floor(Date.now() / 1000)
): Inventory | undefined => {
  if (!inventory) return undefined;

  const itemsBySlot = new Map<number, Slot>();

  Object.values(inventory.items || {}).forEach((entry) => {
    if (!entry || !Number.isFinite(entry.slot)) return;
    itemsBySlot.set(entry.slot, entry);
  });

  const mappedItems = Array.from(Array(inventory.slots), (_, index) => {
    const slot = index + 1;
    const matchedItem = itemsBySlot.get(slot);

    if (!matchedItem?.name) return { slot };

    if (typeof Items[matchedItem.name] === 'undefined') {
      void getItemData(matchedItem.name);
    }

    return {
      ...matchedItem,
      metadata: safeMetadata(matchedItem.metadata),
      durability: itemDurability(matchedItem.metadata, curTime),
    };
  });

  const normalised: Inventory = {
    ...inventory,
    items: mappedItems,
  };

  if (inventory.clothing) {
    const clothing = normaliseClothing(inventory.clothing, curTime);
    if (clothing) normalised.clothing = clothing;
    else delete normalised.clothing;
  } else {
    delete normalised.clothing;
  }

  if (inventory.backpack) {
    const backpack = normaliseInventory(inventory.backpack, curTime);
    if (backpack) normalised.backpack = backpack;
    else delete normalised.backpack;
  } else {
    delete normalised.backpack;
  }

  if (inventory.otherBackpack) {
    const otherBackpack = normaliseInventory(inventory.otherBackpack, curTime);
    if (otherBackpack) normalised.otherBackpack = otherBackpack;
    else delete normalised.otherBackpack;
  } else {
    delete normalised.otherBackpack;
  }

  if (inventory.storage) {
    const storage = normaliseInventory(inventory.storage, curTime);
    if (storage) normalised.storage = storage;
    else delete normalised.storage;
  } else {
    delete normalised.storage;
  }

  return normalised;
};

export const setupInventoryReducer: CaseReducer<
  State,
  PayloadAction<{
    leftInventory?: Inventory;
    rightInventory?: Inventory;
  }>
> = (state, action) => {
  const { leftInventory, rightInventory } = action.payload;
  const curTime = Math.floor(Date.now() / 1000);

  const normalisedLeft = normaliseInventory(leftInventory, curTime);
  if (normalisedLeft) state.leftInventory = normalisedLeft;

  const normalisedRight = normaliseInventory(rightInventory, curTime);
  if (normalisedRight) state.rightInventory = normalisedRight;

  state.shiftPressed = false;
  state.isBusy = false;
};
