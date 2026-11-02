import { canStack, findAvailableSlot, getItemData, getTargetInventory, isSlotWithItem } from '../helpers';
import { validateMove } from '../thunks/validateItems';
import { store } from '../store';
import { DragSource, DropTarget, InventoryType } from '../typings';
import { moveSlots, stackSlots, swapSlots } from '../store/inventory';
import { Items } from '../store/items';
import { fetchNui } from '../utils/fetchNui';

export const onDrop = async (source: DragSource, target?: DropTarget, splitting?: boolean) => {
  const { inventory: state } = store.getState();

  if (source.inventory === InventoryType.UTILITY) {
    const utilityData = state.leftInventory.utility;
    const offset = utilityData?.offset ?? 0;
    let utilitySlot = source.metadata?.utilitySlot;

    if (!utilitySlot && offset && source.item.slot >= offset) {
      utilitySlot = source.item.slot - offset;
    }

    if (utilitySlot && utilitySlot > 0) {
      const toType = target?.inventory ?? 'newdrop';
      const targetInventory = toType === 'newdrop'
        ? undefined
        : getTargetInventory(
          state,
          InventoryType.PLAYER,
          target?.inventory,
          state.leftInventory.id,
          target?.inventoryId
        ).targetInventory;

      fetchNui('moveFromUtilitySlot', {
        utilitySlot,
        toSlot: target?.item.slot ?? null,
        toInventory: targetInventory?.id,
        toType,
      });
    }

    return;
  }

  if (source.inventory === InventoryType.OTHER_UTILITY) {
    const utilityData = state.rightInventory.utility;
    const offset = utilityData?.offset ?? 0;
    let utilitySlot = source.metadata?.utilitySlot;

    if (!utilitySlot && offset && source.item.slot >= offset) {
      utilitySlot = source.item.slot - offset;
    }

    const { targetInventory } = getTargetInventory(
      state,
      source.inventory,
      target?.inventory,
      source.inventoryId,
      target?.inventoryId
    );

    fetchNui('moveFromOtherUtilitySlot', {
      utilitySlot,
      toSlot: target?.item.slot ?? null,
      fromInventory: state.rightInventory.id,
      toInventory: targetInventory?.id,
    });

    return;
  }

  if (source.inventory === InventoryType.CLOTHING) {
    const { targetInventory } = getTargetInventory(
      state,
      InventoryType.PLAYER,
      target?.inventory,
      state.leftInventory.id,
      target?.inventoryId
    );

    fetchNui('moveFromClothingSlot', {
      clothingSlot: source.metadata?.clothingSlot,
      toSlot: target?.item.slot ?? null,
      toInventory: targetInventory?.id,
    });

    return;
  }

  if (source.inventory === InventoryType.OTHER_CLOTHING) {
    const { targetInventory } = getTargetInventory(
      state,
      InventoryType.PLAYER,
      target?.inventory,
      state.leftInventory.id,
      target?.inventoryId
    );

    fetchNui('moveFromOtherClothingSlot', {
      clothingSlot: source.metadata?.clothingSlot,
      fromInventory: source.inventoryId ?? state.rightInventory.id,
      toSlot: target?.item.slot ?? null,
      toInventory: targetInventory?.id,
    });

    return;
  }

  if (target?.inventory === InventoryType.UTILITY || target?.inventory === InventoryType.OTHER_UTILITY) {
    const isOther = target.inventory === InventoryType.OTHER_UTILITY;
    const utilityData = isOther ? state.rightInventory.utility : state.leftInventory.utility;
    const offset = utilityData?.offset ?? 0;

    let utilitySlot = target.item.slot;
    if (offset && utilitySlot >= offset) {
      utilitySlot = utilitySlot - offset;
    }

    const { sourceInventory } = getTargetInventory(
      state,
      source.inventory,
      target.inventory,
      source.inventoryId,
      target.inventoryId
    );

    if (sourceInventory && utilitySlot) {
      const eventName = isOther ? 'moveToOtherUtilitySlot' : 'moveToUtilitySlot';

      const payload: any = {
        fromSlot: source.item.slot,
        toSlot: utilitySlot,
        fromInventory: sourceInventory.id,
      };

      if (isOther) {
        payload.toInventory = state.rightInventory.id;
      }

      fetchNui(eventName, payload);
    }
    return;
  }

  let { sourceInventory, targetInventory } = getTargetInventory(
    state,
    source.inventory,
    target?.inventory,
    source.inventoryId,
    target?.inventoryId
  );

  if (!targetInventory) return;

  if (splitting) {
    targetInventory = sourceInventory;
  }

  const sourceSlot = sourceInventory.items[source.item.slot - 1];

  if (!isSlotWithItem(sourceSlot, true)) {
    return;
  }

  const sourceName = sourceSlot.name;
  let sourceData = Items[sourceName];

  if (sourceData === undefined) {
    sourceData = (await getItemData(sourceName)) ?? Items[sourceName];
  }

  if (!sourceData) return;

  if (sourceSlot.metadata?.container !== undefined) {
    if (targetInventory.type === InventoryType.CONTAINER)
      return;

    if (state.rightInventory.id === sourceSlot.metadata.container)
      return;
  }

  const targetSlot = target
    ? targetInventory.items[target.item.slot - 1]
    : findAvailableSlot(sourceSlot, sourceData, targetInventory.items, splitting);

  if (targetSlot === undefined) return;

  if (targetSlot.metadata?.container !== undefined && state.rightInventory.id === targetSlot.metadata.container)
    return;

  const count =
    state.shiftPressed && sourceSlot.count > 1 && sourceInventory.type !== 'shop'
      ? Math.floor(sourceSlot.count / 2)
      : state.itemAmount === 0 || state.itemAmount > sourceSlot.count
        ? sourceSlot.count
        : state.itemAmount;

  const data = {
    fromSlot: sourceSlot,
    toSlot: targetSlot,
    fromType: sourceInventory.type,
    toType: targetInventory.type,
    count: count,
    fromInventory: source.inventoryId ?? sourceInventory.id,
    toInventory: target?.inventoryId ?? targetInventory.id,
  };

  store.dispatch(
    validateMove({
      ...data,
      fromSlot: sourceSlot.slot,
      toSlot: targetSlot.slot,
    })
  );

  isSlotWithItem(targetSlot, true)
    ? sourceData.stack && canStack(sourceSlot, targetSlot)
      ? store.dispatch(
        stackSlots({
          ...data,
          toSlot: targetSlot,
        })
      )
      : store.dispatch(
        swapSlots({
          ...data,
          toSlot: targetSlot,
        })
      )
    : store.dispatch(moveSlots(data));
};
