import React, { useEffect, useMemo } from 'react';
import { useDrag, useDrop } from 'react-dnd';
import { useMergeRefs } from '@floating-ui/react';
import { DragSource, InventoryType, Slot, SlotWithItem, UtilityConfig } from '../../typings';
import { getItemUrl, isSlotWithItem } from '../../helpers';
import { fetchNui } from '../../utils/fetchNui';
import { Items } from '../../store/items';
import { getColor } from './InventorySlot';
import { useAppDispatch, useAppSelector } from '../../store';
import { openContextMenu } from '../../store/contextMenu';
import { formatItemAmount } from '../../helpers/formatItemAmount';
import { applyItemImageFallback } from '../../helpers/itemImageFallback';
import { playDragSound } from '../../helpers/dragSound';
import { Config } from '../../store/config';
import { isRarityEnabled, normalizeRarity } from '../../store/rarity';

const transparentDragImage =
  typeof window !== 'undefined'
    ? (() => {
      const img = new Image();
      img.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';
      return img;
    })()
    : undefined;

type UtilitySlotProps = {
  slotIndex: number;
  slot: Slot;
  inventoryType: InventoryType;
  config?: UtilityConfig;
};

const utilityIconAssets = import.meta.glob('../../assets/svg/*.{svg,png}', {
  eager: true,
  import: 'default',
}) as Record<string, string>;

const iconMap = Object.entries(utilityIconAssets).reduce<Record<string, string>>((acc, [assetPath, assetUrl]) => {
  const fileName = assetPath.split('/').pop()?.toLowerCase();
  if (!fileName) return acc;

  acc[fileName] = assetUrl;

  const baseName = fileName.replace(/\.[^.]+$/, '');
  if (!acc[baseName]) {
    acc[baseName] = assetUrl;
  }

  return acc;
}, {});

const UtilitySlot: React.FC<UtilitySlotProps> = ({ slotIndex, slot, inventoryType, config }) => {
  const dispatch = useAppDispatch();
  const { leftInventory, rightInventory } = useAppSelector(state => state.inventory);
  const hasItem = isSlotWithItem(slot);
  const slotItem = hasItem ? (slot as SlotWithItem) : null;
  const zeroIndex = slotIndex - 1;

  const resolveConfigValue = <T,>(
    collection:
      | Record<string, T | undefined>
      | Record<number, T | undefined>
      | Array<T | undefined>
      | undefined
  ): T | undefined => {
    if (!collection) return undefined;

    if (Array.isArray(collection)) {
      return collection[zeroIndex] ?? collection[slotIndex];
    }

    const asRecord = collection as Record<string | number, T | undefined>;
    const indexKey = slotIndex.toString();
    const zeroKey = zeroIndex.toString();
    const direct =
      asRecord[indexKey] ??
      asRecord[zeroKey] ??
      asRecord[slotIndex] ??
      asRecord[zeroIndex];

    if (direct !== undefined) {
      return direct;
    }

    const numericCandidates = Object.entries(asRecord)
      .map(([key, value]) => ({ key: Number(key), value }))
      .filter((entry) => !Number.isNaN(entry.key))
      .sort((a, b) => a.key - b.key);

    if (numericCandidates.length > 0) {
      return (
        numericCandidates[zeroIndex]?.value ??
        numericCandidates.find((entry) => entry.key === slotIndex)?.value ??
        numericCandidates.find((entry) => entry.key === zeroIndex)?.value
      );
    }

    const orderedEntries = Object.entries(asRecord);
    return orderedEntries[zeroIndex]?.[1] ?? orderedEntries[slotIndex]?.[1];
  };

  const [{ isOver }, drop] = useDrop<DragSource, void, { isOver: boolean }>(
    () => ({
      accept: 'SLOT',
      collect: (monitor) => ({
        isOver: monitor.isOver(),
      }),
      canDrop: (source) => (inventoryType === InventoryType.PLAYER && source.inventory === InventoryType.PLAYER) || inventoryType === InventoryType.OTHER_UTILITY,
      drop: (source) => {
        if (inventoryType !== InventoryType.PLAYER && inventoryType !== InventoryType.OTHER_UTILITY) return;

        const isOther = inventoryType === InventoryType.OTHER_UTILITY;
        const action = isOther ? 'moveToOtherUtilitySlot' : 'moveToUtilitySlot';

        let fromInventory = source.inventoryId;
        if (!fromInventory) {
          if (source.inventory === InventoryType.PLAYER) fromInventory = leftInventory.id;
          else fromInventory = rightInventory.id;
        }

        const toInventory = isOther ? rightInventory.id : leftInventory.id;

        playDragSound();
        fetchNui<boolean>(action, {
          toSlot: slotIndex,
          fromSlot: source.item.slot,
          fromInventory,
          toInventory,
          utilitySlot: slotIndex
        });
      },
    }),
    [inventoryType, slotIndex]
  );

  const [{ isDragging }, drag, preview] = useDrag<DragSource, void, { isDragging: boolean }>(
    () => ({
      type: 'SLOT',
      collect: (monitor) => ({ isDragging: monitor.isDragging() }),
      canDrag: () => (inventoryType === InventoryType.PLAYER || inventoryType === InventoryType.OTHER_UTILITY) && hasItem,
      item: () => {
        if (!hasItem || !slotItem) return null;
        return {
          inventory: inventoryType === InventoryType.OTHER_UTILITY ? InventoryType.OTHER_UTILITY : InventoryType.UTILITY,
          item: { name: slotItem.name, slot: slotItem.slot },
          metadata: slotItem.metadata,
          image: `url(${getItemUrl(slotItem) || 'none'})`,
        };
      },
    }),
    [hasItem, inventoryType, slotItem]
  );

  useEffect(() => {
    if (transparentDragImage) {
      preview(transparentDragImage, { captureDraggingState: true });
    }
  }, [preview]);

  const refs = useMergeRefs([drop, drag, preview]);

  const resolvedLabelRaw = resolveConfigValue(config?.labels);
  const configuredLabel = typeof resolvedLabelRaw === 'string' ? resolvedLabelRaw : resolvedLabelRaw ? String(resolvedLabelRaw) : '';

  const iconKeyRaw = resolveConfigValue(config?.icons);
  const iconKey = typeof iconKeyRaw === 'string' ? iconKeyRaw.trim() : undefined;
  const iconMapKey = iconKey ? iconKey.toLowerCase() : undefined;
  const fallbackIcon = iconMap['others'] ?? iconMap['others.svg'];
  const iconSource =
    (iconMapKey && iconMap[iconMapKey]) ||
    (iconKey && iconKey.includes('/') ? iconKey : fallbackIcon);

  const iconSizeRaw = resolveConfigValue(config?.iconSizes);
  const iconSize = typeof iconSizeRaw === 'number' && iconSizeRaw > 0 ? iconSizeRaw : undefined;
  const iconStyle = iconSize ? { width: `${iconSize}px`, height: `${iconSize}px` } : undefined;

  const itemLabel = useMemo(() => {
    if (!hasItem || !slotItem) return '';
    return slotItem.metadata?.label ?? Items[slotItem.name]?.label ?? slotItem.name;
  }, [hasItem, slotItem]);

  const amountText = formatItemAmount(slotItem?.name, slotItem?.count);
  const weightText = useMemo(() => {
    if (!hasItem || !slotItem?.weight) return '';
    if (slotItem.weight >= 1000) {
      return `${(slotItem.weight / 1000).toLocaleString('en-us', {
        minimumFractionDigits: 1,
      })}kg `;
    }
    return `${slotItem.weight.toLocaleString('en-us', {
      minimumFractionDigits: 1,
    })}g `;
  }, [hasItem, slotItem]);

  const quality =
    slotItem?.metadata?.quality ??
    slotItem?.durability ??
    slotItem?.metadata?.durability ??
    slotItem?.metadata?.armorDurability;
  const durability = hasItem
    ? typeof quality === 'number'
      ? Math.max(Math.min(quality, 100), 0)
      : 100
    : null;

  const rarityEnabled = isRarityEnabled();
  const rarity = slotItem
    ? rarityEnabled ? normalizeRarity(slotItem.metadata?.rarity || Items[slotItem.name]?.rarity) || 'common' : 'common'
    : undefined;
  const rarityColors = getColor(rarity);
  const borderColor =
    rarity && rarity !== 'common' ? rarityColors.text : 'var(--color-slot-border)';
  const isLoadout = Config.layout === 'loadout';
  const slotBackground = isLoadout || !rarityEnabled ? undefined : rarityColors.background;

  const handleContextMenu = (event: React.MouseEvent<HTMLDivElement>) => {
    event.preventDefault();

    if (inventoryType !== InventoryType.PLAYER || !slotItem) return;

    dispatch(openContextMenu({
      item: slotItem,
      coords: { x: event.clientX, y: event.clientY },
      inventoryId: leftInventory.id || 'player',
      inventoryType: InventoryType.UTILITY,
    }));
  };

  return (
    <div className="utility-slot-wrap">
      {configuredLabel && <div className="utility-slot-title">{configuredLabel}</div>}
      <div
        ref={refs}
        onContextMenu={handleContextMenu}
        className={`utility-slot relative w-[6.75rem] h-[6.75rem] border border-transparent item-slot-border utility-slot-shell${hasItem && isLoadout && rarityEnabled ? ' has-item rarity-framed' : ''}${isOver ? ' drag-over' : ''}${rarityEnabled && rarity ? ` rarity-${rarity}` : ''}`}
        data-slot={slot.slot}
        data-slot-index={slot.slot}
        data-inventory-type={inventoryType}
        data-inventory-id=""
        data-utility={slotIndex}
        style={{
          opacity: isDragging ? 0.4 : 1,
          background: slotBackground,
          '--borderColor': borderColor,
          '--rarityColor': rarityColors.text,
        } as React.CSSProperties}
      >
        {isLoadout && durability !== null && (
          <span className="slot-quality-bar" aria-label={`Quality ${Math.round(durability)}%`}>
            <span style={{ width: `${durability}%` }} />
          </span>
        )}
        {!hasItem && iconSource && (
          <img
            className="utility-slot-icon"
            src={iconSource}
            alt=""
            style={iconStyle}
          />
        )}
        {hasItem && slotItem && (
          <div className="p-1.5 text-secondary text-xs relative w-full h-full cursor-pointer">
            {iconSource && (
              <img
                className="utility-slot-icon"
                src={iconSource}
                alt=""
                style={iconStyle}
              />
            )}
            <img
              src={`${slotItem?.name ? getItemUrl(slotItem) : 'none'}`}
              className="item-slot-image slot-content-image slot-content-image--centered absolute w-[4.125rem] h-[4.125rem] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-0"
              alt={slotItem.name}
              loading="lazy"
              decoding="async"
              draggable={false}
              onError={applyItemImageFallback}
            />

            <div className="leading-3 font-[350] relative z-10">
              {rarityEnabled && rarity && (
                <p
                  className="absolute top-0 right-0 text-[0.625rem] font-medium"
                  style={{
                    color: rarity === 'common' ? 'var(--tx)' : getColor(rarity).text,
                  }}
                >
                  {rarity.toUpperCase()}
                </p>
              )}
              <div>
                <p className='slot-content-quantity text-[0.6875rem]'>{amountText}</p>
                {inventoryType !== 'player' && inventoryType !== 'container' && (
                  <p className='text-[0.6875rem]'>{weightText}</p>
                )}
              </div>
            </div>

            {(inventoryType === 'player' || inventoryType === 'container') && (
              <p className='text-[0.6875rem] absolute bottom-1.5 right-1.5'>
                {weightText}
              </p>
            )}

            <p className="slot-content-label absolute text-white w-1/2 bottom-[0.4375rem] left-[0.4375rem] font-semibold z-10">
              {itemLabel}
            </p>

            {!isLoadout && durability !== null && (
              <div className="absolute h-1 w-full bottom-0 left-0">
                <div
                  className="h-full"
                  style={{
                    backgroundColor: rarityColors.text,
                    width: `${durability}%`,
                  }}
                />
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default UtilitySlot;
