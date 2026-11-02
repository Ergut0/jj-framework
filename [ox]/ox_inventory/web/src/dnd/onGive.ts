import { store } from '../store';
import { DragSource } from '../typings';
import { fetchNui } from '../utils/fetchNui';

export const onGive = (source: DragSource) => {
  const {
    inventory: { itemAmount },
  } = store.getState();
  fetchNui('giveItem', {
    slot: source.item.slot,
    count: itemAmount,
    inventory: source.inventoryId,
  });
};
