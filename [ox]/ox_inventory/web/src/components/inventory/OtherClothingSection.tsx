import React, { useState } from 'react';
import { useAppSelector } from '../../store';
import { selectRightInventory } from '../../store/inventory';
import ClothingWearSlot from './ClothingWearSlot';
import { getDefinition } from './clothingDefinitions';
import outfitIcon from '../../assets/svg/outfitsvg.svg';
import { Config } from '../../store/config';

const OtherClothingSection: React.FC = () => {
  const rightInventory = useAppSelector(selectRightInventory);
  const clothingConfig = rightInventory.clothingConfig;
  const clothingState = rightInventory.clothing;
  const [closed, setClosed] = useState(false);
  const isLoadout = Config.layout === 'loadout';

  if (!clothingConfig?.enabled || !clothingConfig.slots || !clothingState) {
    return null;
  }

  const leftLayout = clothingConfig.layout?.left ?? [0, 1, 2, 3, 4];
  const rightLayout = clothingConfig.layout?.right ?? [5, 6, 7, 8, 9];
  const allSlotIds = [...leftLayout, ...rightLayout];

  return (
    <div className={isLoadout ? 'loadout-grid robbed-aux-section robbed-clothing-section' : 'bg-black/70 rounded-lg border border-neutral-500 w-[38.25rem] p-5'}>
      <div className="inventory-panel-header">
        <div className="inventory-panel-top">
          <div className="inventory-panel-main">
            <div className="inventory-title !gap-3 !text-[0.9375rem] !font-bold">
              <i className="inventory-badge">
                <img src={outfitIcon} alt="" />
              </i>
              <div className="inventory-title-copy">
                <p className="inventory-title-name">Clothing</p>
              </div>
            </div>
          </div>
          <div className="inventory-panel-tools">
            <button
              type="button"
              className="inventory-collapse-button"
              onClick={() => setClosed((prev) => !prev)}
            >
              <i className={`fas ${closed ? 'fa-chevron-down' : 'fa-chevron-up'}`} />
            </button>
          </div>
        </div>
      </div>
      <div className="inventory-header-divider" />
      <div
        style={{
          maxHeight: closed ? '0rem' : '50rem',
          overflow: 'hidden',
          transition: 'max-height 0.3s ease, opacity 0.3s ease',
          opacity: closed ? 0 : 1,
        }}
      >
        <div className="robbed-aux-grid grid grid-cols-5 gap-2 pt-1">
          {allSlotIds.map((slotId) => {
            const definition = getDefinition(clothingConfig, slotId);
            if (!definition) return null;
            return (
              <ClothingWearSlot
                key={`other-clothing-${slotId}`}
                slotIndex={slotId}
                definition={definition}
                slot={clothingState.items[slotId]}
                isOtherPlayer
                otherInventoryId={rightInventory.id}
              />
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default OtherClothingSection;
