import React, { useEffect, useMemo, useState } from 'react';
import { DragSource, Inventory, InventoryType } from '../../typings';
import InventorySlot from './InventorySlot';
import { getTotalWeight, isSlotWithItem } from '../../helpers';
import { useAppDispatch, useAppSelector } from '../../store';
import { Locale } from '../../store/locale';
import { useIntersection } from '../../hooks/useIntersection';
import { Items } from '../../store/items';
import pocketIcon from '../../assets/svg/pocket.svg';
import backpackIcon from '../../assets/svg/backpack1.svg';
import othersIcon from '../../assets/svg/others.svg';
import { Config } from '../../store/config';
import { openRenameDialog } from '../../store/inventory';
import { useDrop } from 'react-dnd';
import { closeTooltip } from '../../store/tooltip';
import { onDrop } from '../../dnd/onDrop';
import { playDragSound } from '../../helpers/dragSound';

const PAGE_SIZE = 30;
const WEIGHT_SEGMENT_COUNT = 24;
const PANEL_WIDTH_CLASS = 'w-[38.25rem]';
const DEFAULT_GRID_HEIGHT_CLASS = 'h-[21.25rem]';

type InventoryGridProps = {
  inventory: Inventory;
  inv: string;
  inventoryTypeOverride?: InventoryType;
  staticPosition?: boolean;
  frameless?: boolean;
  gridClassName?: string;
  offset?: number;
  limit?: number;
  customTitle?: string;
  style?: React.CSSProperties;
};

const InventoryGrid: React.FC<InventoryGridProps> = ({
  inventory,
  inv,
  inventoryTypeOverride,
  staticPosition,
  frameless,
  gridClassName,
  offset,
  limit,
  customTitle,
  style,
}) => {
  const weight = useMemo(
    () => (inventory.maxWeight !== undefined ? Math.floor(getTotalWeight(inventory.items) * 1000) / 1000 : 0),
    [inventory.maxWeight, inventory.items]
  );

  const [page, setPage] = useState(0);
  const [closed, setClosed] = useState(false);
  const [query, setQuery] = useState('');
  const dispatch = useAppDispatch();
  const isBackpack = inv === 'backpack';
  const { ref, entry } = useIntersection({ threshold: 0.5 });
  const isBusy = useAppSelector((state) => state.inventory.isBusy);
  const inventoryType = (inventoryTypeOverride || inventory.type || InventoryType.PLAYER) as InventoryType;
  const isLeftPanel = inv === 'left' || inv === 'backpack' || inv === 'crafting_storage';
  const weightPercent = inventory.maxWeight ? Math.min(100, (weight / inventory.maxWeight) * 100) : 0;
  const filledWeightSegments = inventory.maxWeight
    ? Math.min(
      WEIGHT_SEGMENT_COUNT,
      Math.max(weightPercent > 0 ? 1 : 0, Math.ceil((weightPercent / 100) * WEIGHT_SEGMENT_COUNT))
    )
    : 0;
  const weightSegments = useMemo(() => Array.from({ length: WEIGHT_SEGMENT_COUNT }, (_, index) => index), []);
  const normalizedQuery = useMemo(() => query.trim().toLowerCase(), [query]);
  const [, drop] = useDrop<DragSource, { targetSlot: number } | void>(
    () => ({
      accept: ['SLOT', 'WEAPON_COMPONENT'],
      drop: (source, monitor) => {
        const clientOffset = monitor.getClientOffset();
        const slotElement = clientOffset
          ? document
            .elementFromPoint(clientOffset.x, clientOffset.y)
            ?.closest<HTMLElement>('[data-inventory-slot]')
          : null;
        const targetSlot = Number(slotElement?.dataset.inventorySlot);

        if (!Number.isFinite(targetSlot)) return;
        if (monitor.getItemType() === 'WEAPON_COMPONENT') return { targetSlot };

        playDragSound();
        dispatch(closeTooltip());
        onDrop(source, {
          inventory: inventoryType,
          inventoryId: inventory.id,
          item: { slot: targetSlot },
        });
      },
      canDrop: (source, monitor) => {
        if (monitor.getItemType() === 'WEAPON_COMPONENT') {
          return inventoryType === InventoryType.PLAYER;
        }

        const clientOffset = monitor.getClientOffset();
        const slotElement = clientOffset
          ? document
            .elementFromPoint(clientOffset.x, clientOffset.y)
            ?.closest<HTMLElement>('[data-inventory-slot]')
          : null;
        const targetSlot = Number(slotElement?.dataset.inventorySlot);

        return (
          Number.isFinite(targetSlot) &&
          (source.item.slot !== targetSlot || source.inventory !== inventoryType) &&
          source.inventory !== InventoryType.SHOP &&
          source.inventory !== InventoryType.CRAFTING &&
          inventoryType !== InventoryType.SHOP &&
          inventoryType !== InventoryType.CRAFTING
        );
      },
    }),
    [dispatch, inventory.id, inventoryType]
  );

  useEffect(() => {
    if (entry && entry.isIntersecting) {
      setPage((prev) => prev + 1);
    }
  }, [entry]);

  const filteredInventoryItems = useMemo(() => {
    const start = offset || 0;
    const end = limit ? start + limit : start + (page + 1) * PAGE_SIZE;
    const visibleItems = inventory.items.slice(start, end);

    if (!normalizedQuery) return visibleItems;

    return visibleItems.filter((item) => {
      const label = item.metadata?.label ?? Items[item.name as string]?.label ?? item.name ?? '';
      return label.toLowerCase().includes(normalizedQuery);
    });
  }, [inventory.items, limit, normalizedQuery, offset, page]);

  const fallbackTitle = inventoryType === InventoryType.PLAYER
    ? Locale.pockets || 'Pockets'
    : inventoryType === InventoryType.BACKPACK || inventoryType === InventoryType.OTHER_BACKPACK
      ? Locale.backpack || 'Backpack'
      : Locale.inventory || 'Inventory';
  const loadoutOwnerName = frameless && inventoryType === InventoryType.PLAYER ? inventory.label : undefined;
  const title = customTitle || (loadoutOwnerName ? fallbackTitle : inventory.label) || fallbackTitle;
  const badgeIcon = inventoryType === InventoryType.PLAYER
    ? pocketIcon
    : inventoryType === InventoryType.BACKPACK || inventoryType === InventoryType.OTHER_BACKPACK
      ? backpackIcon
      : othersIcon;

  return (
    <div
      className={`${frameless ? 'loadout-grid' : 'bg-black/70 rounded-lg border border-neutral-500 p-5'} ${PANEL_WIDTH_CLASS} ${!staticPosition ? `absolute top-1/2 ${isLeftPanel ? 'left-[18%]' : 'left-[82%]'}` : ''
        }`}
      style={{
        pointerEvents: isBusy ? 'none' : 'auto',
        transform: !staticPosition
          ? 'translate(-50%, -50%)'
          : undefined,
        ...style,
      }}
    >
      <div className="inventory-panel-header">
        <div className="inventory-panel-top">
          <div className="inventory-panel-main">
            <div className="inventory-title !gap-3 !text-[0.9375rem] !font-bold">
              <i className="inventory-badge">
                <img src={badgeIcon} alt="" />
              </i>
              <div className="inventory-title-copy">
                <div className="flex items-center gap-1">
                  <p className="inventory-title-name">{title}</p>
                  {isBackpack && Config.allowBackpackRename && (
                    <button
                      type="button"
                      className="text-white/40 hover:text-white/80 duration-150 leading-none"
                      style={{ fontSize: '0.7rem', paddingBottom: '0.1rem' }}
                      onClick={(event) =>
                        dispatch(
                          openRenameDialog({
                            mode: 'backpack',
                            item: null,
                            inventoryId: inventory.id,
                            currentLabel: inventory.label || title,
                            coords: { x: event.clientX, y: event.clientY },
                          })
                        )
                      }
                      aria-label={Locale.ui_rename_backpack}
                    >
                      <i className="fas fa-pencil-alt" />
                    </button>
                  )}
                </div>
                {inventory.maxWeight && (
                  <div className="inventory-title-weight">
                    <i className="fas fa-weight-hanging" />
                    <span>
                      {(weight / 1000).toFixed(2)}/{(inventory.maxWeight / 1000).toFixed(2)}kg
                    </span>
                  </div>
                )}
              </div>
            </div>
          </div>
          <div className="inventory-panel-tools">
            <div className="inventory-search-dock">
              <i className="fas fa-search" />
              <input
                type="text"
                className="inventory-search-input"
                onChange={(event) => setQuery(event.target.value)}
                value={query}
                placeholder={Locale.ui_search}
              />
            </div>
            <button
              type="button"
              className="inventory-collapse-button"
              onClick={() => setClosed((prev) => !prev)}
              aria-label={closed ? Locale.ui_expand_inventory : Locale.ui_collapse_inventory}
            >
              <i className={`fas ${closed ? 'fa-chevron-down' : 'fa-chevron-up'}`} />
            </button>
          </div>
        </div>
        {inventory.maxWeight && (
          <div className="inventory-panel-bottom">
            <div className="inventory-capacity">
              <div
                className="inventory-capacity-track"
                role="progressbar"
                aria-valuemin={0}
                aria-valuemax={100}
                aria-valuenow={Math.round(weightPercent)}
              >
                {weightSegments.map((index) => (
                  <span
                    key={`weight-segment-${index}`}
                    className={`inventory-capacity-segment ${index < filledWeightSegments ? 'is-filled' : ''}`}
                  />
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
      <div className="inventory-header-divider" />
      <AccordionSection open={!closed}>
        {(() => {
          const gridEl = (
            <div
              ref={drop}
              className={`grid grid-cols-5 content-start auto-rows-[6.75rem] overflow-y-auto pr-1 gap-2 ${gridClassName || DEFAULT_GRID_HEIGHT_CLASS}`}
            >
              {filteredInventoryItems.map((item, index) => {
                const slotRef = index === filteredInventoryItems.length - 1 ? ref : null;

                if (!isSlotWithItem(item)) {
                  return (
                    <div
                      key={item.slot}
                      ref={slotRef}
                      data-inventory-slot={item.slot}
                      className="relative w-[6.75rem] h-[6.75rem] border border-transparent item-slot-border"
                    />
                  );
                }

                return (
                  <InventorySlot
                    key={item.slot}
                    item={item}
                    ref={slotRef}
                    inventoryType={inventoryType as Inventory['type']}
                    inventoryGroups={inventory.groups}
                    inventoryId={inventory.id}
                  />
                );
              })}
            </div>
          );

          return frameless && isLeftPanel ? <div className="grid-scroll">{gridEl}</div> : gridEl;
        })()}
      </AccordionSection>
    </div>
  );
};

export default React.memo(InventoryGrid);

const AccordionSection: React.FC<{ open: boolean; children: React.ReactNode }> = ({ open, children }) => {
  if (!open) return null;

  return <>{children}</>;
};
