import React, { useState, useMemo, useEffect } from 'react';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import { InventoryType } from '../../typings';
import ClothingBodyPatch from './ClothingBodyPatch';
import CharacterBody from './CharacterBody';
import ClothingWearSlot from './ClothingWearSlot';
import UtilitySlot from './UtilitySlot';
import PlayerInfoPanel from './PlayerInfoPanel';
import { LoadoutHotkeys } from './LoadoutHotkeys';
import vestIcon from '../../assets/svg/outfitsvg.svg';
import { isSlotWithItem } from '../../helpers';
import useNuiEvent from '../../hooks/useNuiEvent';
import { Locale } from '../../store/locale';
import { getDefinition } from './clothingDefinitions';
import { Config } from '../../store/config';
import { scheduleIdle } from '../../utils/scheduleIdle';

const SEGMENT_COUNT = 24;

const ViewSwitchIcon: React.FC<{ isUtility: boolean }> = ({ isUtility }) => (
  <span className={`inventory-view-switch-icon ${isUtility ? 'is-utility' : ''}`} aria-hidden="true">
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M3 17H8L9.67 14.614M13.33 9.387L15 7H21" />
      <path d="M18 4L21 7L18 10M3 7H8L15 17H21" />
      <path d="M18 20L21 17L18 14" />
    </svg>
  </span>
);

type ClothingPanelProps = {
  forcedView?: 'clothing' | 'utility';
};

const ClothingPanel: React.FC<ClothingPanelProps> = ({ forcedView }) => {
  const leftInventory = useAppSelector(selectLeftInventory);
  const isBusy = useAppSelector((state) => state.inventory.isBusy);
  const clothingConfig = leftInventory.clothingConfig;
  const clothingState = leftInventory.clothing;
  const [internalView, setInternalView] = useState<'clothing' | 'utility'>('utility');
  const view = forcedView ?? internalView;
  const setView = setInternalView;
  const [query, setQuery] = useState('');
  const [forcedViewsMounted, setForcedViewsMounted] = useState({
    clothing: forcedView === 'clothing',
    utility: forcedView !== 'clothing',
  });

  const utility = leftInventory.utility;

  useNuiEvent('closeInventory', () => setInternalView('utility'));

  useEffect(() => {
    if (!forcedView || forcedViewsMounted[forcedView]) return;

    setForcedViewsMounted((current) => ({ ...current, [forcedView]: true }));
  }, [forcedView, forcedViewsMounted]);

  useEffect(() => {
    if (!forcedView || !clothingConfig?.enabled || (forcedViewsMounted.clothing && forcedViewsMounted.utility)) return;

    return scheduleIdle(
      () => setForcedViewsMounted({ clothing: true, utility: true }),
      1200
    );
  }, [clothingConfig?.enabled, forcedView, forcedViewsMounted.clothing, forcedViewsMounted.utility]);

  const leftLayout = clothingConfig?.layout?.left || [1, 2, 3];
  const rightLayout = clothingConfig?.layout?.right || [4, 5, 6];
  const allSlotIds = [...leftLayout, ...rightLayout];

  const totalSlots = useMemo(() => allSlotIds.filter((id) => !!getDefinition(clothingConfig, id)).length, [allSlotIds, clothingConfig]);
  const filledSlots = useMemo(() =>
    allSlotIds.filter((id) => {
      const slot = clothingState?.items?.[id];
      return slot && isSlotWithItem(slot);
    }).length,
    [allSlotIds, clothingState]
  );
  const utilityTotalSlots = utility?.slots || utility?.items?.length || 0;
  const utilityFilledSlots = useMemo(
    () => (utility?.items || []).filter((slot) => slot && isSlotWithItem(slot)).length,
    [utility?.items]
  );

  const filledSegments = totalSlots > 0
    ? Math.min(SEGMENT_COUNT, Math.max(filledSlots > 0 ? 1 : 0, Math.ceil((filledSlots / totalSlots) * SEGMENT_COUNT)))
    : 0;
  const activeTitle = view === 'clothing' ? Locale.ui_clothing : Locale.utility;
  const activeIcon = view === 'clothing' ? 'fa-tshirt' : 'fa-box';
  const activeFilledSlots = view === 'clothing' ? filledSlots : utilityFilledSlots;
  const activeTotalSlots = view === 'clothing' ? totalSlots : utilityTotalSlots;
  const activeSegments = view === 'clothing'
    ? filledSegments
    : activeTotalSlots > 0
      ? Math.min(SEGMENT_COUNT, Math.max(activeFilledSlots > 0 ? 1 : 0, Math.ceil((activeFilledSlots / activeTotalSlots) * SEGMENT_COUNT)))
      : 0;

  const hasClothing = Boolean(clothingConfig?.enabled && clothingConfig?.slots && Object.keys(clothingConfig.slots).length > 0);

  const filterSlot = (slotId: number): boolean => {
    if (!query) return true;
    const definition = getDefinition(clothingConfig, slotId);
    if (!definition) return false;
    const label = definition.label || '';
    return label.toLowerCase().includes(query.toLowerCase());
  };

  if (!hasClothing && !utility) {
    return null;
  }

  const isLoadout = Config.layout === 'loadout';

  return (
    <div
      className={`clothing-panel-shell clothing-panel-shell--view-${view} ${view === 'clothing' ? 'clothing-panel-shell--cutout' : ''} ${
        isLoadout
          ? 'clothing-panel-shell--loadout left-1/2 -translate-x-1/2'
          : 'right-8 rounded-lg border border-neutral-500'
      } absolute top-1/2 -translate-y-1/2 flex flex-col w-[33.5rem] p-5`}
      style={{
        pointerEvents: isBusy ? 'none' : 'auto',
      }}
    >
      <div className="inventory-panel-header">
        <div className="inventory-panel-top">
          <div className="inventory-panel-main">
            <div className="inventory-title !gap-3 !text-[0.9375rem] !font-bold">
              <i className="inventory-badge">
                <img src={vestIcon} alt="" />
              </i>
              <div className="inventory-title-copy">
                <p className="inventory-title-name">{activeTitle}</p>
                <div className="inventory-title-weight">
                  <i className={`fas ${activeIcon}`} />
                  <span>{activeFilledSlots}/{activeTotalSlots} {Locale.ui_slots}</span>
                </div>
              </div>
            </div>
          </div>
          <div className="inventory-panel-tools">
            <div className="inventory-search-dock">
              <i className="fas fa-search" />
              <input
                type="text"
                className="inventory-search-input"
                onChange={(e) => setQuery(e.target.value)}
                value={query}
                placeholder={Locale.ui_search}
              />
            </div>
            {hasClothing && !forcedView && (
              <button
                type="button"
                className="inventory-collapse-button"
                onClick={() => setView((prev) => prev === 'clothing' ? 'utility' : 'clothing')}
                title={view === 'clothing' ? Locale.ui_switch_to_utility : Locale.ui_switch_to_clothing}
                aria-label={view === 'clothing' ? Locale.ui_switch_to_utility : Locale.ui_switch_to_clothing}
              >
                <ViewSwitchIcon isUtility={view === 'utility'} />
              </button>
            )}
          </div>
        </div>
        <div className="inventory-panel-bottom">
          <div className="inventory-capacity">
            <div
              className="inventory-capacity-track"
              role="progressbar"
              aria-valuemin={0}
              aria-valuemax={100}
              aria-valuenow={activeTotalSlots > 0 ? Math.round((activeFilledSlots / activeTotalSlots) * 100) : 0}
            >
              {Array.from({ length: SEGMENT_COUNT }, (_, i) => (
                <span key={i} className={`inventory-capacity-segment ${i < activeSegments ? 'is-filled' : ''}`} />
              ))}
            </div>
          </div>
        </div>
      </div>
      <div className="inventory-header-divider" />

      <div style={{ overflow: 'hidden' }}>
        {hasClothing ? (
        <div
          style={{
            display: 'flex',
            width: forcedView ? '100%' : '200%',
            transform: forcedView ? 'none' : view === 'clothing' ? 'translateX(0)' : 'translateX(-50%)',
            transition: forcedView ? 'none' : 'transform 0.35s cubic-bezier(0.4, 0, 0.2, 1)',
          }}
        >
          {(!forcedView || view === 'clothing' || forcedViewsMounted.clothing) && (
          <div
            className="flex flex-col items-center gap-4 pt-1"
            style={{
              width: forcedView ? '100%' : '50%',
              flexShrink: 0,
              display: forcedView && view !== 'clothing' ? 'none' : 'flex',
            }}
            aria-hidden={forcedView ? view !== 'clothing' : undefined}
          >
            <div className="clothing-panel-layout">
              <div className="clothing-slot-column">
                {leftLayout.map((slotId) => {
                  const definition = getDefinition(clothingConfig, slotId);
                  if (!definition) return null;
                  return (
                    <div key={`clothing-left-${slotId}`} style={{ opacity: filterSlot(slotId) ? 1 : 0.25, transition: 'opacity 0.15s' }}>
                      <ClothingWearSlot
                        slotIndex={slotId}
                        definition={definition}
                        slot={clothingState?.items?.[slotId]}
                      />
                    </div>
                  );
                })}
              </div>

              <ClothingBodyPatch isActive={view === 'clothing'} />

              <div className="clothing-slot-column">
                {rightLayout.map((slotId) => {
                  const definition = getDefinition(clothingConfig, slotId);
                  if (!definition) return null;
                  return (
                    <div key={`clothing-right-${slotId}`} style={{ opacity: filterSlot(slotId) ? 1 : 0.25, transition: 'opacity 0.15s' }}>
                      <ClothingWearSlot
                        slotIndex={slotId}
                        definition={definition}
                        slot={clothingState?.items?.[slotId]}
                      />
                    </div>
                  );
                })}
              </div>
            </div>
            {isLoadout && view === 'clothing' && <LoadoutHotkeys />}
          </div>
          )}

          {(!forcedView || view === 'utility' || forcedViewsMounted.utility) && (
          <div
            className="flex flex-col items-center gap-4 pt-1"
            style={{
              width: forcedView ? '100%' : '50%',
              flexShrink: 0,
              display: forcedView && view !== 'utility' ? 'none' : 'flex',
            }}
            aria-hidden={forcedView ? view !== 'utility' : undefined}
          >
            <div className="clothing-panel-layout">
              <div className="clothing-slot-column">
                {Array.from({ length: 4 }, (_, i) => {
                  const slotIndex = i + 1;
                  const slot = utility?.items?.[i];
                  if (!slot) return null;
                  return (
                    <UtilitySlot
                      key={`utility-left-${slotIndex}`}
                      slotIndex={slotIndex}
                      slot={slot}
                      inventoryType={InventoryType.PLAYER}
                      config={utility?.config}
                    />
                  );
                })}
              </div>

              <CharacterBody />

              <div className="clothing-slot-column">
                {Array.from({ length: 4 }, (_, i) => {
                  const slotIndex = i + 5;
                  const slot = utility?.items?.[i + 4];
                  if (!slot) return null;
                  return (
                    <UtilitySlot
                      key={`utility-right-${slotIndex}`}
                      slotIndex={slotIndex}
                      slot={slot}
                      inventoryType={InventoryType.PLAYER}
                      config={utility?.config}
                    />
                  );
                })}
              </div>
            </div>
            <PlayerInfoPanel />
          </div>
          )}
        </div>
        ) : (
        <div className="flex flex-col items-center gap-4 pt-1">
          <div className="clothing-panel-layout">
            <div className="clothing-slot-column">
              {Array.from({ length: 4 }, (_, i) => {
                const slotIndex = i + 1;
                const slot = utility?.items?.[i];
                if (!slot) return null;
                return (
                  <UtilitySlot
                    key={`utility-left-${slotIndex}`}
                    slotIndex={slotIndex}
                    slot={slot}
                    inventoryType={InventoryType.PLAYER}
                    config={utility?.config}
                  />
                );
              })}
            </div>

            <CharacterBody />

            <div className="clothing-slot-column">
              {Array.from({ length: 4 }, (_, i) => {
                const slotIndex = i + 5;
                const slot = utility?.items?.[i + 4];
                if (!slot) return null;
                return (
                  <UtilitySlot
                    key={`utility-right-${slotIndex}`}
                    slotIndex={slotIndex}
                    slot={slot}
                    inventoryType={InventoryType.PLAYER}
                    config={utility?.config}
                  />
                );
              })}
            </div>
          </div>
          <PlayerInfoPanel />
        </div>
        )}
      </div>
    </div>
  );
};

export default ClothingPanel;
