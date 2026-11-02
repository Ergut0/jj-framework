import { Inventory, InventoryType, ItemData, Slot, SlotWithItem, State } from '../typings';
import { isDeepEqual } from './isDeepEqual';
import { store } from '../store';
import { Items } from '../store/items';
import { imagepath } from '../store/imagepath';
import { fetchNui } from '../utils/fetchNui';
import { useEffect, useState } from 'react';

export const canPurchaseItem = (item: Slot, inventory: { type: Inventory['type']; groups: Inventory['groups'] }) => {
  if (inventory.type !== 'shop' || !isSlotWithItem(item)) return true;

  if (item.count !== undefined && item.count === 0) return false;

  if (item.grade === undefined || !inventory.groups) return true;

  const leftInventory = store.getState().inventory.leftInventory;

  if (!leftInventory.groups) return false;

  const reqGroups = Object.keys(inventory.groups);

  if (Array.isArray(item.grade)) {
    for (let i = 0; i < reqGroups.length; i++) {
      const reqGroup = reqGroups[i];

      if (leftInventory.groups[reqGroup] !== undefined) {
        const playerGrade = leftInventory.groups[reqGroup];
        for (let j = 0; j < item.grade.length; j++) {
          const reqGrade = item.grade[j];

          if (playerGrade === reqGrade) return true;
        }
      }
    }

    return false;
  } else {
    for (let i = 0; i < reqGroups.length; i++) {
      const reqGroup = reqGroups[i];
      if (leftInventory.groups[reqGroup] !== undefined) {
        const playerGrade = leftInventory.groups[reqGroup];

        if (playerGrade >= item.grade) return true;
      }
    }

    return false;
  }
};

export const canCraftItem = (
  item: Slot,
  inventoryType: string,
  reserved: Record<string, number> = {},
  sourceInventory?: Inventory
) => {
  if (!isSlotWithItem(item) || inventoryType !== 'crafting') return true;
  if (!item.ingredients) return true;

  const leftInventory = sourceInventory ?? store.getState().inventory.leftInventory;
  const ingredientItems = Object.entries(item.ingredients);

  const missingIngredients = ingredientItems.filter(([ingredientName, requiredCount]) => {
    const globalItem = Items[ingredientName];

    if (requiredCount >= 1) {
      if (globalItem && globalItem.count >= requiredCount) return false;
    }

    const reservedCount = reserved[ingredientName] || 0;

    let totalAvailableCount = 0;
    leftInventory.items.forEach((playerItem) => {
      if (isSlotWithItem(playerItem) && playerItem.name === ingredientName) {
        if (requiredCount < 1) {
          if (playerItem.metadata?.durability >= requiredCount * 100) {
            totalAvailableCount += 1;
          }
        } else if (playerItem.count) {
          totalAvailableCount += playerItem.count;
        }
      }
    });

    totalAvailableCount -= reservedCount;

    return totalAvailableCount < requiredCount;
  });

  return missingIngredients.length === 0;
};

export const isSlotWithItem = (slot: Slot, strict: boolean = false): slot is SlotWithItem =>
  slot && (
    (slot.name !== undefined && slot.weight !== undefined) ||
    (strict && slot.name !== undefined && slot.count !== undefined && slot.weight !== undefined)
  );

export const canStack = (sourceSlot: Slot, targetSlot: Slot) =>
  sourceSlot.name === targetSlot.name && isDeepEqual(sourceSlot.metadata, targetSlot.metadata);

export const getCraftItemCount = (
  item: Slot,
  reserved: Record<string, number> = {},
  sourceInventory?: Inventory
) => {
  if (!isSlotWithItem(item) || !item.ingredients) return 'infinity';

  const leftInventory = sourceInventory ?? store.getState().inventory.leftInventory;
  const ingredientItems = Object.entries(item.ingredients);

  let maxCount = Infinity;

  for (const [ingredient, ingredientCount] of ingredientItems) {
    const inventoryItem = leftInventory.items.find((playerItem) => {
      return isSlotWithItem(playerItem) && playerItem.name === ingredient;
    });

    if (!inventoryItem || inventoryItem.count === undefined) {
      return 0;
    }

    let availableCountInInventory = inventoryItem.count;

    const reservedCount = reserved[ingredient] || 0;
    availableCountInInventory -= reservedCount;

    if (availableCountInInventory < 0) availableCountInInventory = 0;

    const possibleCount = Math.floor(availableCountInInventory / ingredientCount);

    if (possibleCount < maxCount) maxCount = possibleCount;
  }

  return maxCount;
};

export const getItemCount = (itemName: string, sourceInventory?: Inventory) => {
  const leftInventory = sourceInventory ?? store.getState().inventory.leftInventory;

  const matchingItem = leftInventory.items.find((playerItem) => {
    return isSlotWithItem(playerItem) && playerItem.name === itemName;
  });

  return matchingItem?.count ?? 0;
};

export const findAvailableSlot = (item: Slot, data: ItemData, items: Slot[], splitting?: boolean) => {
  if (!data.stack || splitting) {
    return items.find((target) => target.name === undefined);
  }

  const stackableSlot = items.find(
    (target) => target.name === item.name && isDeepEqual(target.metadata, item.metadata)
  );

  return stackableSlot || items.find((target) => target.name === undefined);
};

export const getTargetInventory = (
  state: State,
  sourceType: Inventory['type'],
  targetType?: Inventory['type'],
  sourceId?: string | number,
  targetId?: string | number
): { sourceInventory: Inventory; targetInventory: Inventory | null } => {
  const normaliseId = (id: string | number) => id.toString();

  const resolveById = (id?: string | number): Inventory | null => {
    if (id === undefined || id === null) return null;
    if (id === 'player') return state.leftInventory;

    const sought = normaliseId(id);

    const candidates: Array<Inventory | undefined> = [
      state.leftInventory,
      state.leftInventory.backpack,
      state.leftInventory.storage,
      state.rightInventory,
      state.rightInventory.backpack,
    ];

    for (let i = 0; i < candidates.length; i++) {
      const inventory = candidates[i];
      if (inventory && inventory.id !== undefined && normaliseId(inventory.id) === sought) return inventory;
    }

    return null;
  };

  const resolveInventory = (type?: Inventory['type'], id?: string | number): Inventory | null => {
    const byId = resolveById(id);
    if (byId) return byId;

    if (!type) return null;

    switch (type) {
      case InventoryType.PLAYER:
        return state.leftInventory;
      case InventoryType.BACKPACK:
        return state.leftInventory.backpack ?? null;
      case InventoryType.OTHER_BACKPACK:
        return state.rightInventory.backpack ?? null;
      case InventoryType.OTHER_UTILITY:
      case InventoryType.UTILITY:
        return null;
      default:
        return state.rightInventory;
    }
  };

  const sourceInventory = resolveInventory(sourceType, sourceId) ?? state.leftInventory;

  let targetInventory = resolveInventory(targetType, targetId);

  if (!targetInventory) {
    targetInventory = sourceType === InventoryType.PLAYER ? state.rightInventory : state.leftInventory;
  }

  return { sourceInventory, targetInventory };
};

export const metaText = (value: unknown): string | null => {
  if (typeof value === 'string') return value;
  if (typeof value === 'number' || typeof value === 'boolean') return String(value);
  return null;
};

export const safeMetadata = (metadata: any) => {
  if (!metadata || typeof metadata !== 'object' || Array.isArray(metadata)) return metadata;

  const unsafeLabel = metadata.label !== undefined && metaText(metadata.label) === null;
  const unsafeDescription = metadata.description !== undefined && metaText(metadata.description) === null;

  if (!unsafeLabel && !unsafeDescription) return metadata;

  const copy = { ...metadata };
  if (unsafeLabel) delete copy.label;
  if (unsafeDescription) delete copy.description;
  return copy;
};

export const itemDurability = (metadata: any, curTime: number) => {
  if (metadata?.durability === undefined) return;

  let durability = metadata.durability;

  if (durability > 100 && metadata.degrade)
    durability = ((metadata.durability - curTime) / (60 * metadata.degrade)) * 100;

  if (durability < 0) durability = 0;

  return durability;
};

export const getTotalWeight = (items: Inventory['items']) =>
  items.reduce((totalWeight, slot) => (isSlotWithItem(slot) ? totalWeight + slot.weight : totalWeight), 0);

export const isContainer = (inventory: Inventory) => inventory.type === InventoryType.CONTAINER;

export const getItemData = async (itemName: string) => {
  const resp: ItemData | null = await fetchNui('getItemData', itemName);

  if (resp?.name) {
    Items[itemName] = resp;
    return resp;
  }
};

export const getItemUrl = (item: string | SlotWithItem) => {
  const isObj = typeof item === 'object';

  if (isObj) {
    if (!item.name) return;

    const metadata = item.metadata;

    if (metadata?.imageurl) return `${metadata.imageurl}`;
    if (metadata?.image) return `${imagepath}/${metadata.image}.png`;
  }

  const itemName = isObj ? (item.name as string) : item;
  const itemData = Items[itemName];

  if (!itemData) return `${imagepath}/${itemName}.png`;
  if (itemData.image) return itemData.image;

  itemData.image = `${imagepath}/${itemName}.png`;

  return itemData.image;
};

export const useCurrentTime = (interval: number | null = 100) => {
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    if (!interval) return;
    const timer = setInterval(() => setNow(Date.now()), interval);
    return () => clearInterval(timer);
  }, [interval]);

  return now;
};
