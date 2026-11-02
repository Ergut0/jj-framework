import React, { useEffect, useMemo } from 'react';
import { useAppDispatch, useAppSelector } from '../../store';
import { closeWeaponInspect, selectWeaponInspect } from '../../store/weaponInspect';
import { selectLeftInventory } from '../../store/inventory';
import { Items } from '../../store/items';
import { getItemUrl, isSlotWithItem } from '../../helpers';
import { fetchNui } from '../../utils/fetchNui';
import { useDrag, useDrop } from 'react-dnd';
import { InventoryType } from '../../typings';
import type { DragSource } from '../../typings';
import weaponIcon from '../../assets/svg/weapon.svg';
import { Locale } from '../../store/locale';
import { applyItemImageFallback } from '../../helpers/itemImageFallback';

const DURABILITY_SEGMENT_COUNT = 24;
const SLOT_TYPE_ORDER = ['scope', 'flashlight', 'barrel', 'muzzle', 'grip', 'magazine', 'stock'];
const SLOT_TYPE_LOCALE_KEYS: Record<string, string> = {
  scope: 'weapon_scope',
  flashlight: 'weapon_light',
  barrel: 'weapon_barrel',
  muzzle: 'weapon_muzzle',
  grip: 'weapon_grip',
  magazine: 'weapon_mag',
  stock: 'weapon_stock',
};
const getSlotTypeLabel = (slotType: string) => Locale[SLOT_TYPE_LOCALE_KEYS[slotType] || slotType] || slotType;

type ComponentSlotProps = {
  slotType: string;
  equippedName: string | null;
  weaponSlot: number;
};

const ComponentSlot: React.FC<ComponentSlotProps> = ({ slotType, equippedName, weaponSlot }) => {
  const equippedItemData = equippedName ? Items[equippedName] : null;
  const equippedImage = equippedName ? getItemUrl(equippedName) : null;
  const label = getSlotTypeLabel(slotType);

  const [{ isDragging }, drag] = useDrag(
    () => ({
      type: 'WEAPON_COMPONENT',
      canDrag: () => !!equippedName,
      item: { component: equippedName, weaponSlot, image: equippedImage },
      end: (_item, monitor) => {
        if (monitor.didDrop() && equippedName) {
          const result = monitor.getDropResult<{ targetSlot?: number }>();
          fetchNui('removeComponent', { component: equippedName, slot: weaponSlot, targetSlot: result?.targetSlot });
        }
      },
      collect: (monitor) => ({ isDragging: monitor.isDragging() }),
    }),
    [equippedName, weaponSlot, equippedImage]
  );

  const [{ isOver, canDrop }, drop] = useDrop<DragSource, void, { isOver: boolean; canDrop: boolean }>(
    () => ({
      accept: 'SLOT',
      canDrop: (source) => {
        if (source.inventory !== InventoryType.PLAYER) return false;
        if (equippedName) return false;
        const itemData = Items[source.item.name];
        return itemData?.component === true && itemData?.type === slotType;
      },
      drop: (source) => {
        fetchNui('weaponInspect_addComponent', { componentSlot: source.item.slot, weaponSlot });
      },
      collect: (monitor) => ({ isOver: monitor.isOver(), canDrop: monitor.canDrop() }),
    }),
    [equippedName, weaponSlot, slotType]
  );

  const connectRef = (el: HTMLDivElement | null) => drag(drop(el));
  const active = isOver && canDrop;

  return (
    <div
      ref={connectRef}
      className="relative w-[6.75rem] h-[6.75rem] border border-transparent item-slot-border"
      style={{
        '--borderColor': active
          ? 'var(--accent)'
          : equippedName
          ? 'var(--color-slot-border-hover)'
          : 'var(--color-slot-border)',
        background: active ? 'var(--accent-glow-08)' : undefined,
        opacity: isDragging ? 0.4 : 1,
      } as React.CSSProperties}
      title={equippedName ? `${equippedItemData?.label || equippedName} (${label}) — drag to remove` : `${label} — drag from inventory`}
    >
      {equippedName && equippedImage ? (
        <div className="p-1.5 text-secondary text-xs relative w-full h-full cursor-grab">
          <img
            src={equippedImage}
            className="absolute w-[4.125rem] h-[4.125rem] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-0"
            alt={equippedItemData?.label || equippedName}
            loading="lazy"
            decoding="async"
            draggable={false}
            onError={applyItemImageFallback}
          />
          <p className="absolute text-white w-1/2 bottom-[0.4375rem] left-[0.4375rem] font-semibold z-10 text-[0.6875rem] leading-tight">
            {equippedItemData?.label || equippedName}
          </p>
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center w-full h-full">
          <p className="text-[0.625rem] font-bold text-white/20 uppercase tracking-widest text-center px-1">
            {label}
          </p>
        </div>
      )}
    </div>
  );
};

const WeaponInspectPanelClassic: React.FC = () => {
  const dispatch = useAppDispatch();
  const { open, weaponSlot, compatibleTypes } = useAppSelector(selectWeaponInspect);
  const leftInventory = useAppSelector(selectLeftInventory);

  const weaponItem = useMemo(() => {
    if (weaponSlot === null) return null;
    const slot = leftInventory.items.find((s) => s.slot === weaponSlot);
    return slot && isSlotWithItem(slot) ? slot : null;
  }, [leftInventory.items, weaponSlot]);

  useEffect(() => {
    if (open && weaponSlot !== null && !weaponItem) dispatch(closeWeaponInspect());
  }, [open, weaponSlot, weaponItem, dispatch]);

  const equippedComponents: string[] = useMemo(
    () => weaponItem?.metadata?.components ?? [],
    [weaponItem]
  );

  const orderedTypes = useMemo(() => {
    return [...compatibleTypes].sort((a, b) => {
      const ia = SLOT_TYPE_ORDER.indexOf(a);
      const ib = SLOT_TYPE_ORDER.indexOf(b);
      return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib);
    });
  }, [compatibleTypes]);

  if (!open || !weaponItem || weaponSlot === null) return null;

  const weaponLabel = weaponItem.metadata?.label || Items[weaponItem.name]?.label || weaponItem.name;
  const durability =
    weaponItem.durability !== undefined ? Math.max(0, Math.min(100, weaponItem.durability)) : null;
  const durabilityPercent = durability ?? 0;
  const filledSegments =
    durability !== null
      ? Math.min(
          DURABILITY_SEGMENT_COUNT,
          Math.max(durabilityPercent > 0 ? 1 : 0, Math.ceil((durabilityPercent / 100) * DURABILITY_SEGMENT_COUNT))
        )
      : 0;
  const durabilityClass =
    durability === null ? '' : durability > 75 ? 'high' : durability > 25 ? 'medium' : 'low';
  const weaponImage = getItemUrl(weaponItem);

  return (
    <div className="bg-black/70 rounded-lg border border-neutral-500 w-[37.5rem] p-5">

      <div className="inventory-panel-header">
        <div className="inventory-panel-top">
          <div className="inventory-panel-main">
            <div className="inventory-title !gap-3 !text-[0.9375rem] !font-bold">
              <i className="inventory-badge">
                <img src={weaponIcon} alt="" />
              </i>
              <div className="inventory-title-copy">
                <p className="inventory-title-name">{Locale.ui_inspect_weapon}</p>
                {typeof weaponItem.metadata?.serial === 'string' && (
                  <div className="inventory-title-weight">
                    <i className="fas fa-barcode" />
                    <span>{weaponItem.metadata.serial}</span>
                  </div>
                )}
              </div>
            </div>
          </div>
          <div className="inventory-panel-tools">
            {durability !== null && (
              <span className={`wi-durability-badge wi-dur-${durabilityClass}`}>
                {Math.round(durability)}%
              </span>
            )}
            <button
              type="button"
              className="inventory-collapse-button"
              onClick={() => dispatch(closeWeaponInspect())}
              aria-label="Close"
            >
              <i className="fas fa-times" />
            </button>
          </div>
        </div>

        {durability !== null && (
          <div className="inventory-panel-bottom">
            <div className="inventory-capacity">
              <div
                className="inventory-capacity-track"
                role="progressbar"
                aria-valuemin={0}
                aria-valuemax={100}
                aria-valuenow={Math.round(durabilityPercent)}
              >
                {Array.from({ length: DURABILITY_SEGMENT_COUNT }, (_, i) => (
                  <span
                    key={`dur-${i}`}
                    className={`inventory-capacity-segment${i < filledSegments ? ` is-filled wi-dur-seg-${durabilityClass}` : ''}`}
                  />
                ))}
              </div>
            </div>
          </div>
        )}
      </div>

      <div className="inventory-header-divider" />

      <div className="flex gap-3 items-stretch">

        <div
          className="wi-display flex flex-col"
          style={{ width: '12.5rem', flexShrink: 0, marginBottom: 0 }}
        >
          <div className="wi-display-img flex-1" style={{ height: 'auto', minHeight: '9rem' }}>
            {weaponImage && <img src={weaponImage} alt={weaponLabel} loading="lazy" decoding="async" draggable={false} onError={applyItemImageFallback} />}
          </div>
          <div className="wi-display-nameplate">
            <span>{weaponLabel}</span>
          </div>
        </div>

        <div className="flex-1 flex flex-col justify-center">
          {orderedTypes.length > 0 ? (
            <div className="grid grid-cols-3 gap-2.5">
              {orderedTypes.map((type) => {
                const equippedName = equippedComponents.find((c) => Items[c]?.type === type) ?? null;
                return (
                  <ComponentSlot
                    key={type}
                    slotType={type}
                    equippedName={equippedName}
                    weaponSlot={weaponSlot}
                  />
                );
              })}
            </div>
          ) : (
            <div className="wi-no-attachments">
              <span className="material-symbols-rounded">block</span>
              <span>{Locale.ui_no_attachments}</span>
            </div>
          )}
        </div>

      </div>

    </div>
  );
};

export default WeaponInspectPanelClassic;
