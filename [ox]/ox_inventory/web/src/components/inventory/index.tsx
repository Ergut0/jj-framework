import React, { Suspense, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import useNuiEvent from '../../hooks/useNuiEvent';
import InventoryControl from './InventoryControl';
import InventoryHotbar from './InventoryHotbar';
import { useAppDispatch, useAppSelector } from '../../store';
import {
  closeSplitDialog,
  refreshSlots,
  setAdditionalMetadata,
  setLeftBackpack,
  setRightBackpack,
  setBackpackLabel,
  setupInventory,
  selectLeftInventory,
  selectRightInventory,
} from '../../store/inventory';
import { useExitListener } from '../../hooks/useExitListener';
import type { Inventory as InventoryProps } from '../../typings';
import RightInventory, { preloadRightInventoryPanels } from './RightInventory';
import LeftInventory from './LeftInventory';
import Tooltip from '../utils/Tooltip';
import { closeTooltip } from '../../store/tooltip';
import InventoryContext from './InventoryContext';
import { closeContextMenu } from '../../store/contextMenu';
import Fade from '../utils/transitions/Fade';
import SplitDialog from './SplitDialog';
import { closeWeaponInspect, openWeaponInspect } from '../../store/weaponInspect';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import { Combine } from '../../store/combine';
import { Config } from '../../store/config';
import { scheduleIdle } from '../../utils/scheduleIdle';
import { getItemUrl, isSlotWithItem } from '../../helpers';

const loadClothingPanel = () => import('./ClothingPanel');
const loadCombinePanel = () => import('../Combine/CombinePanel');
const loadLoadoutCenter = () => import('./LoadoutCenter');
const ClothingPanel = React.lazy(loadClothingPanel);
const CombinePanel = React.lazy(loadCombinePanel);
const LoadoutCenter = React.lazy(loadLoadoutCenter);
const Inventory: React.FC = () => {
  const [inventoryVisible, setInventoryVisible] = useState(false);
  const [activeView, setActiveView] = useState<'inventories' | 'clothing' | 'utility' | 'combine'>('inventories');
  const [clothingPanelView, setClothingPanelView] = useState<'clothing' | 'utility'>('utility');
  const [clothingMounted, setClothingMounted] = useState(false);
  const [combineMounted, setCombineMounted] = useState(false);
  const dispatch = useAppDispatch();
  const leftInventory = useAppSelector(selectLeftInventory);
  const rightInventory = useAppSelector(selectRightInventory);
  const isLoadout = Config.layout === 'loadout';
  const showLoadoutCenter = isLoadout && rightInventory?.type !== 'shop';
  const shopOpen = isLoadout && rightInventory?.type === 'shop';
  const rightPanelVisible = activeView === 'inventories' || (isLoadout && activeView === 'clothing');
  const debugWeaponInspect = import.meta.env.DEV && new URLSearchParams(window.location.search).get('inspect') === '1';

  useEffect(() => {
    document.body.classList.toggle('loadout-ui', isLoadout);
    // fetch the loadout-center chunk as soon as we know we'll need it,
    // rather than waiting for the inventory to open - it renders
    // immediately (no mount-gate like Clothing/Combine have), so a lazy
    // import kicked off only on open would flash blank on first use.
    if (isLoadout) void loadLoadoutCenter();
  }, [isLoadout]);

  useEffect(() => {
    document.body.classList.toggle('inventory-open', inventoryVisible);
    return () => document.body.classList.remove('inventory-open');
  }, [inventoryVisible]);
  const hasClothing = Boolean(
    leftInventory.clothingConfig?.enabled &&
      leftInventory.clothingConfig?.slots &&
      Object.keys(leftInventory.clothingConfig.slots).length
  );
  const hasUtility = Boolean(leftInventory.utility);
  const hasClothingPanel = hasClothing || hasUtility;
  const hasCombinePanel = Combine.enabled;

  const inventoryViewLabel = Locale.inventory || 'Inventory';
  const clothingViewLabel = Locale.ui_clothing || 'Clothing';
  const utilityViewLabel = Locale.utility || 'Utility';
  const combineViewLabel = Locale.combine || 'Combine';

  const viewTabs = useMemo(() => {
    const tabs: { id: 'inventories' | 'clothing' | 'utility' | 'combine'; label: string }[] = [
      { id: 'inventories', label: inventoryViewLabel },
    ];
    if (hasUtility && !isLoadout) tabs.push({ id: 'utility', label: utilityViewLabel });
    if (hasCombinePanel) tabs.push({ id: 'combine', label: combineViewLabel });
    if (hasClothing) tabs.push({ id: 'clothing', label: clothingViewLabel });
    return tabs;
  }, [hasClothing, hasUtility, hasCombinePanel, isLoadout, inventoryViewLabel, clothingViewLabel, utilityViewLabel, combineViewLabel]);

  const activateView = useCallback((view: 'inventories' | 'clothing' | 'utility' | 'combine') => {
    if (view === 'clothing' || view === 'utility') {
      setClothingPanelView(view);
    }

    setActiveView(view);
  }, []);

  const cycleView = useCallback(
    (dir: number) => {
      const idx = viewTabs.findIndex((tab) => tab.id === activeView);
      const safeIdx = idx < 0 ? 0 : idx;
      const nextView = viewTabs[(safeIdx + dir + viewTabs.length) % viewTabs.length].id;
      activateView(nextView);
    },
    [activateView, activeView, viewTabs]
  );

  useNuiEvent<boolean>('setInventoryVisible', setInventoryVisible);
  useNuiEvent<false>('closeInventory', () => {
    setInventoryVisible(false);
    setActiveView('inventories');
    dispatch(closeContextMenu());
    dispatch(closeTooltip());
    dispatch(closeSplitDialog());
    dispatch(closeWeaponInspect());
  });
  useExitListener(setInventoryVisible);

  useNuiEvent<{
    leftInventory?: InventoryProps;
    rightInventory?: InventoryProps;
  }>('setupInventory', (data) => {
    const setupStartedAt = Config.performanceProfiling ? performance.now() : 0;

    dispatch(setupInventory(data));
    !inventoryVisible && setInventoryVisible(true);

    if (Config.performanceProfiling) {
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          void fetchNui('inventoryRenderProfile', {
            duration: performance.now() - setupStartedAt,
          });
        });
      });
    }
  });

  useNuiEvent('refreshSlots', (data) => dispatch(refreshSlots(data)));

  useNuiEvent<InventoryProps | false>('setPlayerBackpack', (backpack) => {
    const nextBackpack = backpack === false ? undefined : backpack;
    dispatch(setLeftBackpack(nextBackpack));
  });

  useNuiEvent<InventoryProps | false>('setOtherBackpack', (backpack) => {
    const nextBackpack = backpack === false ? undefined : backpack;
    dispatch(setRightBackpack(nextBackpack));
  });

  useNuiEvent<{ inventoryId: string; label: string }>('setBackpackLabel', (data) => {
    dispatch(setBackpackLabel(data));
  });

  useNuiEvent('displayMetadata', (data: Array<{ metadata: string; value: string }>) => {
    dispatch(setAdditionalMetadata(data));
  });

  useEffect(() => {
    if (!inventoryVisible || viewTabs.length <= 1 || shopOpen) return;

    const handleKeyDown = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)) {
        return;
      }

      const key = event.key.toLowerCase();

      if (key === 'q') {
        cycleView(-1);
      } else if (key === 'e') {
        cycleView(1);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [inventoryVisible, viewTabs, cycleView, shopOpen]);

  useEffect(() => {
    if (!hasClothing && activeView === 'clothing') {
      setActiveView('inventories');
    }
    if (!hasUtility && activeView === 'utility') {
      setActiveView('inventories');
    }
    if (!hasCombinePanel && activeView === 'combine') {
      setActiveView('inventories');
    }
  }, [activeView, hasClothing, hasUtility, hasCombinePanel]);

  useEffect(() => {
    if (!inventoryVisible) {
      setActiveView('inventories');
      dispatch(closeTooltip());
      dispatch(closeContextMenu());
    }
  }, [dispatch, inventoryVisible]);

  useEffect(() => {
    if (!debugWeaponInspect || !inventoryVisible) return;
    dispatch(
      openWeaponInspect({
        weaponSlot: 9,
        compatibleTypes: ['scope', 'flashlight', 'barrel', 'muzzle', 'grip', 'magazine', 'stock'],
      })
    );
  }, [debugWeaponInspect, dispatch, inventoryVisible]);

  useEffect(() => {
    // fires as soon as the inventory mounts (which happens at resource
    // start, well before the player ever opens it) instead of waiting for
    // first open, so these chunks are already cached by then.
    let cancelIdle: (() => void) | undefined;
    const timeout = window.setTimeout(() => {
      cancelIdle = scheduleIdle(() => {
        preloadRightInventoryPanels();
        void loadClothingPanel();
        void loadCombinePanel();
      });
    }, 500);

    return () => {
      window.clearTimeout(timeout);
      cancelIdle?.();
    };
  }, []);

  const warmedItemImages = useRef(false);
  useEffect(() => {
    if (warmedItemImages.current || !leftInventory.items.length) return;
    warmedItemImages.current = true;

    let cancelIdle: (() => void) | undefined;
    const timeout = window.setTimeout(() => {
      cancelIdle = scheduleIdle(() => {
        for (const item of leftInventory.items) {
          if (!isSlotWithItem(item)) continue;
          const url = getItemUrl(item);
          if (url) new Image().src = url;
        }
      });
    }, 500);

    return () => {
      window.clearTimeout(timeout);
      cancelIdle?.();
    };
  }, [leftInventory.items]);

  useEffect(() => {
    if (hasClothingPanel && (activeView === 'clothing' || activeView === 'utility')) {
      setClothingMounted(true);
    }
    if (hasCombinePanel && activeView === 'combine') {
      setCombineMounted(true);
    }
  }, [activeView, hasClothingPanel, hasCombinePanel]);

  useEffect(() => {
    if (!inventoryVisible || !hasClothingPanel || clothingMounted) return;

    let cancelIdle: (() => void) | undefined;
    const timeout = window.setTimeout(() => {
      cancelIdle = scheduleIdle(() => setClothingMounted(true), 1500);
    }, 900);

    return () => {
      window.clearTimeout(timeout);
      cancelIdle?.();
    };
  }, [clothingMounted, hasClothingPanel, inventoryVisible]);

  useEffect(() => {
    if (!inventoryVisible || !hasCombinePanel || combineMounted) return;

    let cancelIdle: (() => void) | undefined;
    const timeout = window.setTimeout(() => {
      cancelIdle = scheduleIdle(() => setCombineMounted(true), 2000);
    }, 1400);

    return () => {
      window.clearTimeout(timeout);
      cancelIdle?.();
    };
  }, [combineMounted, hasCombinePanel, inventoryVisible]);

  useEffect(() => {
    if (!(inventoryVisible && hasClothingPanel && activeView === 'clothing')) {
      fetchNui('setClothingPreview', { enabled: false }).catch(() => undefined);
      return;
    }

    const timeout = window.setTimeout(() => {
      fetchNui('setClothingPreview', { enabled: true }).catch(() => undefined);
    }, 400);

    return () => window.clearTimeout(timeout);
  }, [activeView, hasClothingPanel, inventoryVisible]);

  return (
    <>
      <Fade in={inventoryVisible}>
        <div className={`inventory-container${isLoadout ? ` is-loadout${Config.loadoutSideTilt ? ' has-side-tilt' : ''}${shopOpen ? ' is-shop-open' : ''}` : ''}`}>
          <div className="inventory-backdrop" />
          <div className="inventory-stage">
            {viewTabs.length > 1 && !shopOpen && (
              <div className="inventory-view-toggle">
                <button
                  type="button"
                  className="view-nav-key view-nav-prev"
                  onClick={() => cycleView(-1)}
                  aria-label="Previous tab (Q)"
                >
                  <span>Q</span>
                </button>
                <div className="view-tabs">
                  {viewTabs.map((tab) => (
                    <button
                      key={tab.id}
                      type="button"
                      className={`view-tab ${activeView === tab.id ? 'is-active' : ''}`}
                      onClick={() => activateView(tab.id)}
                    >
                      {tab.label}
                    </button>
                  ))}
                </div>
                <button
                  type="button"
                  className="view-nav-key view-nav-next"
                  onClick={() => cycleView(1)}
                  aria-label="Next tab (E)"
                >
                  <span>E</span>
                </button>
              </div>
            )}
            <LeftInventory />
            <InventoryControl />
            <div className={`inventory-view-panel ${activeView === 'inventories' ? 'view-visible' : 'view-hidden'}`}>
              {showLoadoutCenter && (
                <Suspense fallback={null}>
                  <LoadoutCenter />
                </Suspense>
              )}
            </div>
            <div
              className={`inventory-view-panel ${
                rightPanelVisible ? 'view-visible' : 'view-hidden'
              }`}
            >
              <RightInventory active={inventoryVisible && rightPanelVisible} />
            </div>
            {hasClothingPanel && clothingMounted && (
              <div
                className={`inventory-view-panel ${
                  activeView === 'clothing' || activeView === 'utility' ? 'view-visible' : 'view-hidden'
                }`}
              >
                <Suspense fallback={null}>
                  <ClothingPanel forcedView={clothingPanelView} />
                </Suspense>
              </div>
            )}
            {hasCombinePanel && combineMounted && (
              <div className={`inventory-view-panel ${activeView === 'combine' ? 'view-visible' : 'view-hidden'}`}>
                <Suspense fallback={null}>
                  <CombinePanel active={inventoryVisible && activeView === 'combine'} />
                </Suspense>
              </div>
            )}
          </div>
          {inventoryVisible && <Tooltip />}
          <InventoryContext />
          <SplitDialog />
        </div>
      </Fade>
      <InventoryHotbar />
    </>
  );
};

export default Inventory;
