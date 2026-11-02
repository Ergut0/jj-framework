import React from 'react';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import InventoryGrid from './InventoryGrid';
import { InventoryType } from '../../typings';
import { Config } from '../../store/config';

const LeftInventory: React.FC = () => {
  const leftInventory = useAppSelector(selectLeftInventory);
  const backpack = leftInventory.backpack;
  const craftingStorage = leftInventory.storage;
  const isLoadout = Config.layout === 'loadout';
  const hotkeySlotCount = 5;
  const gridHeightClass = 'h-[21.25rem]';
  const mainGridHeightClass = isLoadout && !backpack && !craftingStorage ? 'h-[43rem]' : gridHeightClass;
  const hasExtraGrid = (backpack && backpack.slots > 0) || (craftingStorage && craftingStorage.slots > 0);

  return (
    <div
      className={`absolute top-1/2 left-8 flex flex-col gap-3 max-h-[94%] overflow-y-auto pr-2 no-scrollbar${isLoadout ? ` loadout-side-stack loadout-side-stack--left${hasExtraGrid ? ' loadout-side-stack--has-extra' : ''}` : ''}`}
      style={{
        transform: 'translateY(-50%)',
      }}
    >
      <InventoryGrid
        inventory={leftInventory}
        inv={'left'}
        inventoryTypeOverride={InventoryType.PLAYER}
        staticPosition
        frameless={isLoadout}
        gridClassName={mainGridHeightClass}
        offset={isLoadout ? hotkeySlotCount : undefined}
      />
      {backpack && backpack.slots > 0 && (
        <InventoryGrid
          inventory={backpack}
          inv={'backpack'}
          inventoryTypeOverride={InventoryType.BACKPACK}
          staticPosition
          frameless={isLoadout}
          gridClassName={gridHeightClass}
        />
      )}
      {craftingStorage && craftingStorage.slots > 0 && (
        <InventoryGrid
          inventory={craftingStorage}
          inv={'crafting_storage'}
          staticPosition
          frameless={isLoadout}
          gridClassName={gridHeightClass}
        />
      )}
    </div>
  );
};

export default React.memo(LeftInventory);
