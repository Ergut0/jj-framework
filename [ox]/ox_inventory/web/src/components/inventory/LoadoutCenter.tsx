import React from 'react';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import { InventoryType } from '../../typings';
import CharacterBody from './CharacterBody';
import UtilitySlot from './UtilitySlot';
import PlayerInfoPanel from './PlayerInfoPanel';
import { LoadoutHotkeys } from './LoadoutHotkeys';

const UTILITY_COLUMN_SIZE = 4;

const LoadoutCenter: React.FC = () => {
  const leftInventory = useAppSelector(selectLeftInventory);
  const utility = leftInventory.utility;

  const renderUtilityColumn = (columnOffset: number) => {
    if (!utility) return null;
    return (
      <div className="clothing-slot-column">
        {Array.from({ length: UTILITY_COLUMN_SIZE }, (_, i) => {
          const slotIndex = columnOffset + i + 1;
          const slot = utility.items?.[columnOffset + i];
          if (!slot) return null;
          return (
            <UtilitySlot
              key={`loadout-utility-${slotIndex}`}
              slotIndex={slotIndex}
              slot={slot}
              inventoryType={InventoryType.PLAYER}
              config={utility.config}
            />
          );
        })}
      </div>
    );
  };

  return (
    <div className="loadout-center">
      <PlayerInfoPanel />
      <div className="loadout-body">
        {renderUtilityColumn(0)}
        <CharacterBody />
        {renderUtilityColumn(UTILITY_COLUMN_SIZE)}
      </div>
      <LoadoutHotkeys />
    </div>
  );
};

export default React.memo(LoadoutCenter);
