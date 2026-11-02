import React from 'react';
import { useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import { closeTooltip } from '../../store/tooltip';
import { DragSource, InventoryType, Inventory } from '../../typings';
import { onDrop } from '../../dnd/onDrop';
import { playDragSound } from '../../helpers/dragSound';
import InventorySlot from './InventorySlot';
import { Locale } from '../../store/locale';

const HOTKEY_COUNT = 5;

export const LoadoutHotkeys: React.FC = () => {
  const dispatch = useAppDispatch();
  const leftInventory = useAppSelector(selectLeftInventory);
  const hotkeyItems = leftInventory.items.slice(0, HOTKEY_COUNT);
  const hotkeyLabel =
    Locale.ui_hotkey && Locale.ui_hotkey !== 'ui_hotkey' ? Locale.ui_hotkey : 'Hotkey';


  const [, drop] = useDrop<DragSource, void>(
    () => ({
      accept: ['SLOT', 'WEAPON_COMPONENT'],
      drop: (source, monitor) => {
        if (monitor.getItemType() === 'WEAPON_COMPONENT') return;

        const clientOffset = monitor.getClientOffset();
        const slotElement = clientOffset
          ? document
            .elementFromPoint(clientOffset.x, clientOffset.y)
            ?.closest<HTMLElement>('[data-inventory-slot]')
          : null;
        const targetSlot = Number(slotElement?.dataset.inventorySlot);

        if (!Number.isFinite(targetSlot)) return;

        playDragSound();
        dispatch(closeTooltip());
        onDrop(source, {
          inventory: InventoryType.PLAYER,
          inventoryId: leftInventory.id,
          item: { slot: targetSlot },
        });
      },
      canDrop: (source, monitor) => {
        if (monitor.getItemType() === 'WEAPON_COMPONENT') return false;

        const clientOffset = monitor.getClientOffset();
        const slotElement = clientOffset
          ? document
            .elementFromPoint(clientOffset.x, clientOffset.y)
            ?.closest<HTMLElement>('[data-inventory-slot]')
          : null;
        const targetSlot = Number(slotElement?.dataset.inventorySlot);

        return (
          Number.isFinite(targetSlot) &&
          (source.item.slot !== targetSlot || source.inventory !== InventoryType.PLAYER) &&
          source.inventory !== InventoryType.SHOP &&
          source.inventory !== InventoryType.CRAFTING
        );
      },
    }),
    [dispatch, leftInventory.id]
  );

  return (
    <div className="loadout-hotkeys" ref={drop}>
      {hotkeyItems.map((item, index) => (
        <div className="loadout-hotkey" key={`loadout-hotkey-${item.slot}`}>
          <div className="utility-slot-title">{`${hotkeyLabel} ${index + 1}`}</div>
          <InventorySlot
            item={item}
            inventoryType={InventoryType.PLAYER as Inventory['type']}
            inventoryGroups={leftInventory.groups}
            inventoryId={leftInventory.id}
          />
        </div>
      ))}
    </div>
  );
};

export default LoadoutHotkeys;
