import React, { useState } from 'react';
import { useAppSelector } from '../../store';
import { selectRightInventory } from '../../store/inventory';
import UtilitySlot from './UtilitySlot';
import { InventoryType } from '../../typings';
import vestIcon from '../../assets/svg/vest.svg';
import { Config } from '../../store/config';

const OtherUtilitySection: React.FC = () => {
  const rightInventory = useAppSelector(selectRightInventory);
  const utility = rightInventory.utility;
  const config = utility?.config;
  const [closed, setClosed] = useState(false);
  const isLoadout = Config.layout === 'loadout';

  if (!utility || utility.slots <= 0) {
    return null;
  }

  const totalSlots = utility.slots;
  const allSlots = Array.from({ length: totalSlots }, (_, i) => i + 1);

  return (
    <div className={isLoadout ? 'loadout-grid robbed-aux-section robbed-utility-section' : 'bg-black/70 rounded-lg border border-neutral-500 w-[38.25rem] p-5'}>
      <div className="inventory-panel-header">
        <div className="inventory-panel-top">
          <div className="inventory-panel-main">
            <div className="inventory-title !gap-3 !text-[0.9375rem] !font-bold">
              <i className="inventory-badge">
                <img src={vestIcon} alt="" />
              </i>
              <div className="inventory-title-copy">
                <p className="inventory-title-name">Utility</p>
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
          maxHeight: closed ? '0rem' : '37.5rem',
          overflow: 'hidden',
          transition: 'max-height 0.3s ease, opacity 0.3s ease',
          opacity: closed ? 0 : 1,
        }}
      >
        <div className="robbed-aux-grid grid grid-cols-5 gap-2 pt-1">
          {allSlots.map((slotIndex) => (
            <UtilitySlot
              key={`other-utility-${slotIndex}`}
              slotIndex={slotIndex}
              slot={utility.items[slotIndex - 1]}
              inventoryType={InventoryType.OTHER_UTILITY}
              config={config}
            />
          ))}
        </div>
      </div>
    </div>
  );
};

export default OtherUtilitySection;
