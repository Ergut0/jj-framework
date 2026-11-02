import React, { useEffect, useRef, useState } from 'react';
import { getItemUrl, isSlotWithItem } from '../../helpers';
import useNuiEvent from '../../hooks/useNuiEvent';
import { Items } from '../../store/items';
import WeightBar from '../utils/WeightBar';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import { Slot, SlotWithItem } from '../../typings';
import SlideUp from '../utils/transitions/SlideUp';
import { getColor, getItemQuality } from './InventorySlot';
import { formatItemAmount } from '../../helpers/formatItemAmount';
import { applyItemImageFallback } from '../../helpers/itemImageFallback';
import { shallowEqual } from 'react-redux';
import { Config } from '../../store/config';
import { isRarityEnabled, normalizeRarity } from '../../store/rarity';

const InventoryHotbar: React.FC = () => {
  const isLoadout = Config.layout === 'loadout';
  const rarityEnabled = isRarityEnabled();
  const [hotbarVisible, setHotbarVisible] = useState(false);
  const items = useAppSelector((state) => selectLeftInventory(state).items.slice(0, 5), shallowEqual);

  const handleRef = useRef<number>();
  useNuiEvent('toggleHotbar', () => {
    if (hotbarVisible) {
      setHotbarVisible(false);
    } else {
      if (handleRef.current) clearTimeout(handleRef.current);
      setHotbarVisible(true);
      handleRef.current = window.setTimeout(() => setHotbarVisible(false), 3000);
    }
  });

  useEffect(
    () => () => {
      if (handleRef.current) clearTimeout(handleRef.current);
    },
    []
  );

  if (isLoadout) {
    return (
      <SlideUp in={hotbarVisible}>
        <div className="loadout-hotbar absolute bottom-[3%] left-0 right-0 mx-auto w-fit">
          {items.map((item, index) => {
            const rarity = rarityEnabled ? normalizeRarity(Items[item.name as string]?.rarity) || 'common' : 'common';
            const quality = isSlotWithItem(item) ? getItemQuality(item as SlotWithItem) : null;
            return (
              <div
                className={`loadout-hotbar-slot${isSlotWithItem(item) ? ' has-item' : ''}`}
                style={{ '--rarityColor': getColor(rarity)?.text || 'rgba(255, 255, 255, 0.4)' } as React.CSSProperties}
                key={`hotbar-${item.slot}`}
              >
                <span className="loadout-hotbar-key">{index + 1}</span>
                {isSlotWithItem(item) && (
                  <>
                    <img
                      src={getItemUrl(item as SlotWithItem)}
                      onError={applyItemImageFallback}
                      className="loadout-hotbar-image slot-content-image slot-content-image--centered"
                      alt={item.name}
                      loading="lazy"
                      decoding="async"
                      draggable={false}
                    />
                    <span className="loadout-hotbar-count slot-content-quantity slot-content-quantity--bottom-right">{formatItemAmount(item.name, item.count)}</span>
                    {quality !== null && (
                      <span className="loadout-hotbar-quality" aria-label={`Quality ${Math.round(quality)}%`}>
                        <span style={{ width: `${quality}%` }} />
                      </span>
                    )}
                  </>
                )}
              </div>
            );
          })}
        </div>
      </SlideUp>
    );
  }

  return (
    <SlideUp in={hotbarVisible}>
      <div className="flex items-center justify-center gap-2 w-full absolute bottom-[2%]">
        {items.map((item) => {
          const rarity = rarityEnabled ? normalizeRarity(Items[item.name as string]?.rarity) || 'common' : 'common';

          return (
            <div
            className="relative w-[7.1875rem] h-[7.1875rem] rounded-[0.1875rem] border border-transparent item-slot-border hotbar-slot"
            style={
              {
                background: rarityEnabled && rarity !== 'common' ? getColor(rarity).background : '',
                '--borderColor': rarityEnabled ? getColor(rarity)?.text || '' : 'var(--color-slot-border)',
              } as React.CSSProperties
            }
            key={`hotbar-${item.slot}`}
          >
            {isSlotWithItem(item) && (
              <div className="p-1.5 text-secondary text-xs relative w-full h-full">
                <img
                  src={`${item?.name ? getItemUrl(item as SlotWithItem) : 'none'}`}
                  onError={applyItemImageFallback}
                  className="slot-content-image slot-content-image--centered absolute w-[4.375rem] h-[4.375rem] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-0"
                  alt={item.name}
                  loading="lazy"
                  decoding="async"
                  draggable={false}
                />
                <div className="leading-3 font-[350] relative z-10">
                  {rarityEnabled && (
                    <p
                      className="absolute top-0 right-0 text-[0.625rem] font-medium"
                      style={{
                        color: rarity === 'common' ? 'var(--tx)' : getColor(rarity).text,
                      }}
                    >
                      {rarity.toUpperCase()}
                    </p>
                  )}
                  <p className="slot-content-quantity">{formatItemAmount(item.name, item.count)}</p>
                  <p className="text-[0.6875rem]">
                    {item.weight > 0
                      ? item.weight >= 1000
                        ? `${(item.weight / 1000).toLocaleString('en-us', {
                          minimumFractionDigits: 1,
                        })}kg `
                        : `${item.weight.toLocaleString('en-us', {
                          minimumFractionDigits: 1,
                        })}g `
                      : ''}
                  </p>
                </div>
                <p className="slot-content-label absolute w-1/2 bottom-[0.4375rem] left-[0.4375rem] font-semibold z-10" style={{ color: 'var(--accent-label)' }}>
                  {item.metadata?.label ? item.metadata.label : Items[item.name]?.label || item.name}
                </p>
                {item?.durability !== undefined && (
                  <div className="absolute h-1 w-full bottom-0 left-0">
                    <div
                      className="h-full"
                      style={{
                        backgroundColor: rarityEnabled ? getColor(rarity).text : '#ffffff',
                        width: `${item.durability}%`,
                      }}
                    ></div>
                  </div>
                )}
              </div>
            )}
            </div>
          );
        })}
      </div>
    </SlideUp>
  );
};

export default InventoryHotbar;
