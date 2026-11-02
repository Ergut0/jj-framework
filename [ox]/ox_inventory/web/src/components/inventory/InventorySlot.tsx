import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import { DragSource, Inventory, InventoryType, Slot, SlotWithItem } from '../../typings';
import { useDrag } from 'react-dnd';
import { useAppDispatch } from '../../store';
import { onDrop } from '../../dnd/onDrop';
import { Items } from '../../store/items';
import { canCraftItem, canPurchaseItem, getItemUrl, isSlotWithItem } from '../../helpers';
import { onUse } from '../../dnd/onUse';
import { closeTooltip, openTooltip } from '../../store/tooltip';
import { openContextMenu } from '../../store/contextMenu';
import { Locale } from '../../store/locale';
import { isRarityEnabled, normalizeRarity, Rarity } from '../../store/rarity';
import { formatItemAmount } from '../../helpers/formatItemAmount';
import { getCurrencySymbol } from '../../helpers/currency';
import { applyItemImageFallback } from '../../helpers/itemImageFallback';
import { Config } from '../../store/config';

export const getColor = (rarity?: unknown): { text: string; background: string } => {
  const defaultColor = Rarity.common || { text: '#ffffff', background: 'radial-gradient(#00000050, #51515150)' };

  return Rarity[normalizeRarity(rarity) || 'common'] || defaultColor;
};

export const getItemQuality = (item?: SlotWithItem | null): number | null => {
  if (!item) return null;

  const value =
    item.metadata?.quality ??
    item.durability ??
    item.metadata?.durability ??
    item.metadata?.armorDurability;

  return typeof value === 'number' ? Math.max(0, Math.min(100, value)) : 100;
};

const matchesQuery = (item: Slot | null, query = '') => {
  if (!query || !item || typeof item.name !== 'string') return true;
  return (item.metadata?.label ? item.metadata.label : Items[item.name]?.label || item.name)
    .toLowerCase()
    .includes(query.toLowerCase());
};

const formatWeight = (weight: number) => {
  if (weight <= 0) return '';
  return weight >= 1000
    ? `${(weight / 1000).toLocaleString('en-us', { minimumFractionDigits: 1 })}kg `
    : `${weight.toLocaleString('en-us', { minimumFractionDigits: 1 })}g `;
};

interface SlotProps {
  inventoryId: Inventory['id'];
  inventoryType: Inventory['type'];
  inventoryGroups: Inventory['groups'];
  item: Slot;
  query?: string;
  backgroundImage?: React.ReactNode;
  onClick?: (event: React.MouseEvent<HTMLDivElement>) => void;
  isSelected?: boolean;
  disableAvailabilityFilter?: boolean;
  craftingStorage?: Inventory;
}

type DraggableSlotContentProps = {
  item: SlotWithItem;
  inventoryId: Inventory['id'];
  inventoryType: Inventory['type'];
  itemImage?: string;
  slotMatchesQuery: boolean;
  canDrag: () => boolean;
  onMouseEnter: (event: React.MouseEvent<HTMLDivElement>) => void;
  onMouseLeave: () => void;
  children: React.ReactNode;
};

const DraggableSlotContent: React.FC<DraggableSlotContentProps> = ({
  item,
  inventoryId,
  inventoryType,
  itemImage,
  slotMatchesQuery,
  canDrag,
  onMouseEnter,
  onMouseLeave,
  children,
}) => {
  const [, drag] = useDrag<DragSource>(
    () => ({
      type: 'SLOT',
      item: () => ({
        inventory: inventoryType,
        inventoryId,
        item,
        image: itemImage,
      }),
      canDrag,
    }),
    [inventoryType, inventoryId, item, itemImage, canDrag, slotMatchesQuery]
  );

  return (
    <div
      ref={drag}
      className="p-1.5 text-[#a8a8a8] text-xs relative w-full h-full cursor-pointer"
      onMouseEnter={onMouseEnter}
      onMouseLeave={onMouseLeave}
    >
      {children}
    </div>
  );
};

const InventorySlot: React.ForwardRefRenderFunction<HTMLDivElement, SlotProps> = (
  { item, inventoryId, inventoryType, inventoryGroups, query = '', backgroundImage, onClick, isSelected, disableAvailabilityFilter, craftingStorage },
  ref
) => {
  const dispatch = useAppDispatch();
  const timerRef = useRef<number | null>(null);
  const isHoveredRef = useRef<boolean>(false);
  const isLoadout = Config.layout === 'loadout';
  const rarityEnabled = isRarityEnabled();
  const hasItem = isSlotWithItem(item);
  const itemData = typeof item.name === 'string' ? Items[item.name] : undefined;
  const rarity = rarityEnabled ? normalizeRarity(item.metadata?.rarity || itemData?.rarity) || 'common' : 'common';
  const rarityColor = useMemo(() => getColor(rarity), [rarity]);
  const itemImage = useMemo(() => (hasItem ? getItemUrl(item as SlotWithItem) : undefined), [hasItem, item]);
  const itemLabel = item.metadata?.label ?? itemData?.label ?? item.name;
  const itemWeight = useMemo(() => formatWeight(item.weight || 0), [item.weight]);
  const itemAmount = useMemo(
    () => (hasItem ? formatItemAmount(item.name as string, item.count) : ''),
    [hasItem, item.count, item.name]
  );
  const quality = hasItem ? getItemQuality(item as SlotWithItem) : null;

  useEffect(() => {
    return () => {
      isHoveredRef.current = false;

      if (timerRef.current) {
        clearTimeout(timerRef.current);
        timerRef.current = null;
      }
    };
  }, []);

  const slotMatchesQuery = useMemo(() => matchesQuery(item, query), [item, query]);

  const isAvailable = useMemo(
    () =>
      canPurchaseItem(item, { type: inventoryType, groups: inventoryGroups }) &&
      canCraftItem(item, inventoryType, {}, craftingStorage),
    [craftingStorage, inventoryGroups, inventoryType, item]
  );

  const canDrag = useCallback(() => {
    return (
      hasItem &&
      inventoryType !== 'crafting' &&
      isAvailable &&
      slotMatchesQuery
    );
  }, [hasItem, inventoryType, isAvailable, slotMatchesQuery]);

  const handleContext = (event: React.MouseEvent<HTMLDivElement>) => {
    event.preventDefault();
    if ((inventoryType !== 'player' && inventoryType !== 'backpack') || !isSlotWithItem(item)) return;

    dispatch(openContextMenu({ item, coords: { x: event.clientX, y: event.clientY }, inventoryId, inventoryType }));
  };

  const handleClick = (event: React.MouseEvent<HTMLDivElement>) => {
    dispatch(closeTooltip());
    if (timerRef.current) clearTimeout(timerRef.current);

    if (onClick) {
      onClick(event);
      return;
    }

    if (event.ctrlKey && isSlotWithItem(item) && inventoryType !== 'shop' && inventoryType !== 'crafting') {
      onDrop({ item: item, inventory: inventoryType });
    } else if (event.altKey && isSlotWithItem(item) && inventoryType === 'player') {
      onUse(item);
    }
  };

  return (
    <div
      ref={ref}
      data-inventory-slot={item.slot}
      onContextMenu={handleContext}
      onClick={handleClick}
      className={`relative w-[6.75rem] h-[6.75rem] border border-transparent item-slot-border${hasItem && isLoadout && rarityEnabled ? ` has-item rarity-framed rarity-${rarity}` : ''}`}
      style={
        {
          '--borderColor': isSelected
            ? 'var(--color-slot-border-hover)'
            : slotMatchesQuery
              ? rarityEnabled && rarity !== 'common' && hasItem ? rarityColor.text : 'var(--color-slot-border)'
              : undefined,
          '--rarityColor': rarityColor.text,
          filter: !disableAvailabilityFilter && !isAvailable ? 'brightness(80%) grayscale(100%)' : undefined,
        } as React.CSSProperties
      }
    >
      {isLoadout && quality !== null && inventoryType !== InventoryType.CRAFTING && (
        <span className="slot-quality-bar" aria-label={`Quality ${Math.round(quality)}%`}>
          <span style={{ width: `${quality}%` }} />
        </span>
      )}
      {!hasItem && backgroundImage && (
        <div className='absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none'>
          {backgroundImage}
        </div>
      )}
      {hasItem && slotMatchesQuery && (
        <DraggableSlotContent
          item={item as SlotWithItem}
          inventoryId={inventoryId}
          inventoryType={inventoryType}
          itemImage={itemImage}
          slotMatchesQuery={slotMatchesQuery}
          canDrag={canDrag}
          onMouseEnter={() => {
            isHoveredRef.current = true;
            timerRef.current = window.setTimeout(() => {
              if (isHoveredRef.current) {
                dispatch(openTooltip({ item: item as SlotWithItem, inventoryType }));
              }
            }, 500);
          }}
          onMouseLeave={() => {
            isHoveredRef.current = false;
            if (timerRef.current) {
              clearTimeout(timerRef.current);
              timerRef.current = null;
            }
            dispatch(closeTooltip());
          }}
        >
          <img
            src={itemImage || 'none'}
            className="item-slot-image slot-content-image slot-content-image--centered absolute w-[4.125rem] h-[4.125rem] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-0"
            alt={item.name}
            loading="lazy"
            decoding="async"
            draggable={false}
            onError={applyItemImageFallback}
          />

          {inventoryType === 'player' && item.slot <= 5 && <div className="absolute text-black font-medium top-0 left-0 w-4 h-5 flex items-center justify-center"
            style={{
              backgroundColor: rarityColor.text,
              borderBottomRightRadius: '0.5rem'
            }}>{item.slot}</div>}

          <div className="leading-3 font-[350] relative z-10">
            {rarityEnabled && (
              <p
                className="absolute top-0 right-0 text-[0.625rem] font-medium"
                style={{
                  color:
                    rarity === 'common'
                      ? '#ffffff'
                      : rarityColor.text,
                }}
              >
                {rarity.toUpperCase()}
              </p>
            )}
            <div className={`${inventoryType === 'player' && item.slot <= 5 && 'absolute left-3.5'}`}>
              <p className='slot-content-quantity text-[0.6875rem]'>{itemAmount}</p>
              {inventoryType !== 'player' && inventoryType !== 'container' && (
                <p className='text-[0.6875rem]'>{itemWeight}</p>
              )}
            </div>
          </div>

          {(inventoryType === 'player' || inventoryType === 'container') && (
            <p className='text-[0.6875rem] absolute bottom-1.5 right-1.5'>{itemWeight}</p>
          )}

          <p className="slot-content-label absolute text-white w-1/2 bottom-[0.4375rem] left-[0.4375rem] font-semibold z-10">
            {itemLabel}
          </p>

          {!isLoadout && item?.durability !== undefined && (
            <div className="absolute h-1 w-full bottom-0 left-0">
              <div
                className="h-full"
                style={{
                  backgroundColor: rarityColor.text,
                  width: `${item.durability}%`,
                }}
              ></div>
            </div>
          )}

          {inventoryType === 'shop' && item?.price !== undefined && (
            <div className="absolute z-10 bottom-1.5 right-1.5">
              {item?.currency !== 'money' && item.currency !== 'black_money' && item.price > 0 && item.currency ? (
                <div className="flex items-center gap-1">
                  <img
                    src={item.currency ? getItemUrl(item.currency) : 'none'}
                    alt="item-image"
                    loading="lazy"
                    decoding="async"
                    draggable={false}
                    onError={applyItemImageFallback}
                    style={{
                      imageRendering: '-webkit-optimize-contrast',
                      height: 'auto',
                      width: '2vh',
                      backfaceVisibility: 'hidden',
                      transform: 'translateZ(0)',
                    }}
                  />
                  <p>{item.price.toLocaleString('en-us')}</p>
                </div>
              ) : (
                <>
                  {item.price > 0 && (
                    <div className="flex items-center gap-1">
                      <p>
                        {getCurrencySymbol()}
                        {item.price.toLocaleString('en-us')}
                      </p>
                    </div>
                  )}
                </>
              )}
            </div>
          )}
        </DraggableSlotContent>
      )}
      {inventoryType === 'crafting' && !isAvailable && (
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-white/50 text-4xl z-30">
        </div>
      )}
    </div>
  );
};

export default React.memo(React.forwardRef(InventorySlot));
