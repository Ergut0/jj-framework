import React, { useEffect, useMemo } from 'react';
import { useDrag, useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { closeWeaponInspect, selectWeaponInspect } from '../../store/weaponInspect';
import { selectLeftInventory } from '../../store/inventory';
import { Items } from '../../store/items';
import { getItemUrl, isSlotWithItem } from '../../helpers';
import { fetchNui } from '../../utils/fetchNui';
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

const localeText = (key: string, fallback: string) => {
  const value = Locale[key];
  return value && value !== key ? value : fallback;
};

const getSlotTypeLabel = (slotType: string) => {
  const key = SLOT_TYPE_LOCALE_KEYS[slotType] || slotType;
  return localeText(key, slotType.replace(/_/g, ' '));
};

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
        if (!monitor.didDrop() || !equippedName) return;
        const result = monitor.getDropResult<{ targetSlot?: number }>();
        fetchNui('removeComponent', { component: equippedName, slot: weaponSlot, targetSlot: result?.targetSlot });
      },
      collect: (monitor) => ({ isDragging: monitor.isDragging() }),
    }),
    [equippedName, weaponSlot, equippedImage]
  );

  const [{ isOver, canDrop }, drop] = useDrop<DragSource, void, { isOver: boolean; canDrop: boolean }>(
    () => ({
      accept: 'SLOT',
      canDrop: (source) => {
        if (source.inventory !== InventoryType.PLAYER || equippedName) return false;
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

  const connectRef = (element: HTMLDivElement | null) => drag(drop(element));
  const active = isOver && canDrop;

  return (
    <div
      ref={connectRef}
      className={`weapon-component-slot item-slot-border${equippedName ? ' has-component' : ''}${active ? ' is-drop-target' : ''}`}
      style={
        {
          '--borderColor': active
            ? 'var(--color-primary)'
            : equippedName
              ? 'rgba(255, 255, 255, 0.3)'
              : 'var(--color-slot-border)',
          opacity: isDragging ? 0.4 : 1,
        } as React.CSSProperties
      }
      title={equippedName ? `${equippedItemData?.label || equippedName} (${label}) - drag to remove` : `${label} - drag from inventory`}
    >
      <span className="weapon-component-slot__type">{label}</span>
      {equippedName && equippedImage ? (
        <div className="weapon-component-slot__content cursor-grab">
          <img
            src={equippedImage}
            className="weapon-component-slot__image"
            alt={equippedItemData?.label || equippedName}
            loading="lazy"
            decoding="async"
            draggable={false}
            onError={applyItemImageFallback}
          />
          <p className="weapon-component-slot__name">{equippedItemData?.label || equippedName}</p>
        </div>
      ) : (
        <div className="weapon-component-slot__empty">
          <i className="fas fa-plus" />
          <span>{localeText('ui_empty', 'Empty')}</span>
        </div>
      )}
    </div>
  );
};

const WeaponInspectPanel: React.FC = () => {
  const dispatch = useAppDispatch();
  const { open, weaponSlot, compatibleTypes } = useAppSelector(selectWeaponInspect);
  const leftInventory = useAppSelector(selectLeftInventory);

  const weaponItem = useMemo(() => {
    if (weaponSlot === null) return null;
    const slot = leftInventory.items.find((entry) => entry.slot === weaponSlot);
    return slot && isSlotWithItem(slot) ? slot : null;
  }, [leftInventory.items, weaponSlot]);

  useEffect(() => {
    if (open && weaponSlot !== null && !weaponItem) dispatch(closeWeaponInspect());
  }, [open, weaponSlot, weaponItem, dispatch]);

  const equippedComponents: string[] = useMemo(() => weaponItem?.metadata?.components ?? [], [weaponItem]);

  const orderedTypes = useMemo(
    () =>
      [...compatibleTypes].sort((a, b) => {
        const firstIndex = SLOT_TYPE_ORDER.indexOf(a);
        const secondIndex = SLOT_TYPE_ORDER.indexOf(b);
        return (firstIndex === -1 ? 99 : firstIndex) - (secondIndex === -1 ? 99 : secondIndex);
      }),
    [compatibleTypes]
  );

  if (!open || !weaponItem || weaponSlot === null) return null;

  const weaponLabel = weaponItem.metadata?.label || Items[weaponItem.name]?.label || weaponItem.name;
  const durability =
    weaponItem.durability !== undefined ? Math.max(0, Math.min(100, weaponItem.durability)) : 100;
  const filledSegments = Math.min(
    DURABILITY_SEGMENT_COUNT,
    Math.max(durability > 0 ? 1 : 0, Math.ceil((durability / 100) * DURABILITY_SEGMENT_COUNT))
  );
  const durabilityClass = durability > 75 ? 'high' : durability > 25 ? 'medium' : 'low';
  const weaponImage = getItemUrl(weaponItem);
  const attachmentCount = orderedTypes.reduce(
    (count, type) => count + (equippedComponents.some((component) => Items[component]?.type === type) ? 1 : 0),
    0
  );
  const ammoCount = typeof weaponItem.metadata?.ammo === 'number' ? weaponItem.metadata.ammo : null;

  return (
    <div className="weapon-inspect-panel">
      <header className="weapon-inspect-header">
        <div className="weapon-inspect-heading">
          <span className="weapon-inspect-eyebrow">{weaponLabel}</span>
          <div className="weapon-inspect-title-row">
            <span className="weapon-inspect-badge"><img src={weaponIcon} alt="" /></span>
            <h2>{localeText('ui_inspect_weapon', 'Weapon Inspection')}</h2>
          </div>
          {typeof weaponItem.metadata?.serial === 'string' && (
            <div className="weapon-inspect-serial">
              <i className="fas fa-barcode" />
              <span>{weaponItem.metadata.serial}</span>
            </div>
          )}
        </div>
        <div className="weapon-inspect-tools">
          <span className={`wi-durability-badge wi-dur-${durabilityClass}`}>{Math.round(durability)}%</span>
          <button type="button" className="weapon-inspect-close" onClick={() => dispatch(closeWeaponInspect())} aria-label="Close">
            <i className="fas fa-times" />
          </button>
        </div>
        <div
          className="weapon-inspect-durability"
          role="progressbar"
          aria-valuemin={0}
          aria-valuemax={100}
          aria-valuenow={Math.round(durability)}
        >
          {Array.from({ length: DURABILITY_SEGMENT_COUNT }, (_, index) => (
            <span key={`dur-${index}`} className={index < filledSegments ? 'is-filled' : ''} />
          ))}
        </div>
      </header>

      <div className="weapon-inspect-divider" />

      <div className="weapon-inspect-layout">
        <section className="weapon-inspect-weapon">
          <div className="weapon-display-header">
            <span className="weapon-inspect-section-label">{localeText('ui_weapon', 'Primary Weapon')}</span>
          </div>
          <div className="weapon-inspect-display">
            <div className="weapon-inspect-image-grid">
              <img
                src={weaponImage}
                alt={weaponLabel}
                loading="lazy"
                decoding="async"
                draggable={false}
                onError={applyItemImageFallback}
              />
            </div>
            <div className="weapon-inspect-nameplate">
              <strong>{weaponLabel}</strong>
              <div>
                <span>{`Slot ${weaponSlot}`}</span>
                {ammoCount !== null && <span><i className="fas fa-bullseye" /> {ammoCount}</span>}
              </div>
            </div>
          </div>
        </section>

        <section className="weapon-attachments">
          <div className="weapon-attachments-header">
            <div>
              <span>{localeText('ui_attachments', 'Attachments')}</span>
              <small>{localeText('ui_drag_components', 'Drag components into compatible slots')}</small>
            </div>
            <b>{attachmentCount}/{orderedTypes.length}</b>
          </div>

          {orderedTypes.length > 0 ? (
            <div className="weapon-attachments-grid">
              {orderedTypes.map((type) => {
                const equippedName = equippedComponents.find((component) => Items[component]?.type === type) ?? null;
                return <ComponentSlot key={type} slotType={type} equippedName={equippedName} weaponSlot={weaponSlot} />;
              })}
            </div>
          ) : (
            <div className="wi-no-attachments">
              <i className="fas fa-ban" />
              <span>{localeText('ui_no_attachments', 'No attachments available')}</span>
            </div>
          )}
        </section>
      </div>
    </div>
  );
};

export default WeaponInspectPanel;
