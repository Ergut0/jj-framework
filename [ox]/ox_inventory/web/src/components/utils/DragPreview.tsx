import React, { useLayoutEffect, useMemo, useRef } from 'react';
import { useDragLayer, useDragDropManager } from 'react-dnd';
import { DragSource, InventoryType } from '../../typings';
import { getColor } from '../inventory/InventorySlot';
import { Items } from '../../store/items';
import { getItemUrl, isSlotWithItem } from '../../helpers';
import { getCurrencySymbol } from '../../helpers/currency';
import { applyItemImageFallback } from '../../helpers/itemImageFallback';
import { useAppSelector } from '../../store';
import { SlotWithItem } from '../../typings';
import { Config } from '../../store/config';
import { formatItemAmount } from '../../helpers/formatItemAmount';
import { isRarityEnabled, normalizeRarity } from '../../store/rarity';

interface DragLayerProps {
  data: DragSource;
  isDragging: boolean;
}

const DragPreview: React.FC = () => {
  const element = useRef<HTMLDivElement>(null);
  const isLoadout = Config.layout === 'loadout';
  const manager = useDragDropManager();

  // Only collect item/isDragging here, so React re-renders on drag start/end
  // rather than on every pointer move.
  const { data, isDragging } = useDragLayer<DragLayerProps>((monitor) => ({
    data: monitor.getItem(),
    isDragging: monitor.isDragging(),
  }));

  // Position is written straight to the node on every offset change instead
  // of going through React state, so the preview tracks the cursor 1:1
  // instead of lagging a render behind it (same technique upstream
  // ox_inventory uses for its drag preview).
  useLayoutEffect(() => {
    if (!isDragging) return;
    const monitor = manager.getMonitor();
    const el = element.current;
    const apply = () => {
      const offset = monitor.getClientOffset();
      if (el && offset) {
        el.style.transform = `translate3d(${offset.x}px, ${offset.y}px, 0) translate(-50%, -50%)`;
      }
    };
    apply();
    return (monitor as any).subscribeToOffsetChange(apply);
  }, [isDragging, manager]);

  const slotWithItem = useAppSelector((state) => {
    if (!isDragging || !data?.item) return null;
    const { leftInventory, rightInventory } = state.inventory;
    const slotNum = data.item.slot;
    const type = data.inventory;

    if (type === InventoryType.CLOTHING) return null;

    const allInvs = [
      leftInventory,
      leftInventory.backpack,
      rightInventory,
      rightInventory.backpack,
      leftInventory.utility,
      rightInventory.utility,
    ];

    for (const inv of allInvs) {
      if (!inv) continue;
      const found = inv.items.find((s) => s && s.slot === slotNum && s.name === data.item.name);
      if (found && isSlotWithItem(found)) return found as SlotWithItem;
    }
    return null;
  });

  const item = slotWithItem;
  const anyData = data as (DragSource & { component?: string }) | null;
  const itemName = data?.item?.name ?? anyData?.component ?? undefined;
  const itemMeta = itemName ? Items[itemName] : undefined;

  const rarityEnabled = isRarityEnabled();
  const rarity = rarityEnabled
    ? normalizeRarity(item ? item.metadata?.rarity || itemMeta?.rarity : itemMeta?.rarity) || 'common'
    : 'common';
  const color = useMemo(() => getColor(rarity).text, [rarity]);

  const label = item?.metadata?.label || itemMeta?.label || itemName || '';

  const formatWeight = (weight: number) => {
    if (!weight || weight <= 0) return '';
    if (weight >= 1000) return `${(weight / 1000).toLocaleString('en-us', { minimumFractionDigits: 1 })}kg`;
    return `${weight.toLocaleString('en-us', { minimumFractionDigits: 1 })}g`;
  };

  const priceDisplay = useMemo(() => {
    if (data?.inventory !== InventoryType.SHOP || !item || !item.price || item.price <= 0) return null;

    if (item.currency && item.currency !== 'money' && item.currency !== 'black_money') {
      return (
        <div className="flex items-center gap-1">
          <img
            src={getItemUrl(item.currency)}
            alt="currency"
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
      );
    }
    return (
      <div className="flex items-center gap-1">
        <p>{getCurrencySymbol()}{item.price.toLocaleString('en-us')}</p>
      </div>
    );
  }, [item, data?.inventory]);

  if (!isDragging) return null;
  if (!data?.item && !(data as (DragSource & { component?: string }) | null)?.component) return null;

  const rawImage = data.image
    ? data.image.replace(/^url\((['"]?)(.*?)\1\)$/, '$2')
    : undefined;
  const imageSrc = rawImage || (itemName ? getItemUrl(itemName) : undefined);

  if (!isLoadout) {
    return (
      <div
        className="relative w-[7.1875rem] h-[7.1875rem] rounded-[0.1875rem] border border-transparent item-slot-border pointer-events-none"
        ref={element}
        style={{
          '--borderColor': rarityEnabled ? color : 'var(--color-slot-border)',
          position: 'fixed',
          top: 0,
          left: 0,
          zIndex: 10000,
        } as React.CSSProperties}
      >
        <div className="p-1.5 text-secondary text-xs">
          {imageSrc && (
            <img
              src={imageSrc}
              onError={applyItemImageFallback}
              alt={label}
              className="slot-content-image slot-content-image--centered absolute w-[4.375rem] h-[4.375rem] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-10"
              decoding="async"
              draggable={false}
            />
          )}
          <div className="leading-3 font-[350]">
            {rarityEnabled && (
              <p
                className="absolute top-[0.3125rem] right-[0.3125rem] text-[0.625rem] font-medium"
                style={{ color: rarity === 'common' ? 'var(--tx)' : color }}
              >
                {rarity.toUpperCase()}
              </p>
            )}
            {item && (
              <>
                <p className="slot-content-quantity">{item.count > 1 ? item.count.toLocaleString('en-us') + 'x' : ''}</p>
                <p className="text-[0.6875rem]">{formatWeight(item.weight)}</p>
              </>
            )}
          </div>
          <p className="slot-content-label absolute w-1/2 bottom-[0.4375rem] left-[0.4375rem] font-semibold z-10" style={{ color: 'var(--accent-label)' }}>{label}</p>
          {item?.durability !== undefined && (
            <div className="absolute h-1 w-full bottom-0 left-0">
              <div className="h-full" style={{ backgroundColor: color, width: `${item.durability}%` }} />
            </div>
          )}
          {priceDisplay && (
            <div className="absolute z-10 bottom-1.5 right-1.5 text-[0.625rem]">{priceDisplay}</div>
          )}
        </div>
      </div>
    );
  }


  return (
    <div
      className={`drag-item-clone relative border border-transparent item-slot-border${rarityEnabled ? ` has-item rarity-framed rarity-${rarity}` : ''} pointer-events-none`}
      ref={element}
      style={{
        width: '7.4rem',
        height: '7.4rem',
        '--borderColor': rarityEnabled && rarity !== 'common' ? color : 'var(--color-slot-border)',
        '--rarityColor': color,
        position: 'fixed',
        top: 0,
        left: 0,
        zIndex: 10000,
      } as React.CSSProperties}
    >
      {item?.durability !== undefined && (
        <span className="slot-quality-bar" aria-hidden="true">
          <span style={{ width: `${item.durability}%` }} />
        </span>
      )}
      <div className="p-1.5 text-secondary text-xs relative w-full h-full">
        {imageSrc && (
          <img
            src={imageSrc}
            onError={applyItemImageFallback}
            alt={label}
            className="slot-content-image slot-content-image--centered absolute w-[4.125rem] h-[4.125rem] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-0"
            decoding="async"
            draggable={false}
          />
        )}
        <div className="leading-3 font-[350] relative z-10">
          {rarityEnabled && (
            <p
              className="absolute top-0 right-0 text-[0.625rem] font-medium"
              style={{ color: rarity === 'common' ? 'var(--tx)' : color }}
            >
              {rarity.toUpperCase()}
            </p>
          )}
          <div>
            <p className="slot-content-quantity text-[0.6875rem]">{item ? formatItemAmount(itemName, item.count) : ''}</p>
            <p className="text-[0.6875rem]">{formatWeight(item?.weight || 0)}</p>
          </div>
        </div>
        <p className="slot-content-label absolute text-white w-1/2 bottom-[0.4375rem] left-[0.4375rem] font-semibold z-10">{label}</p>
        {priceDisplay && (
          <div className="absolute z-10 bottom-1.5 right-1.5 text-[0.625rem]">{priceDisplay}</div>
        )}
      </div>
    </div>
  );
};

export default DragPreview;
