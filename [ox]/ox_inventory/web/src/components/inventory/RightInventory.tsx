import React, { Suspense, useEffect, useRef } from 'react';
import InventoryGrid from './InventoryGrid';
import { useAppSelector } from '../../store';
import { selectRightInventory } from '../../store/inventory';
import OtherUtilitySection from './OtherUtilitySection';
import OtherClothingSection from './OtherClothingSection';
import { InventoryType } from '../../typings';
import { Config } from '../../store/config';
import { selectWeaponInspect } from '../../store/weaponInspect';

const loadShopPanel = () => import('../Shop/ShopPanel');
const loadCraftingPanel = () => import('../Crafting/CraftingPanel');
const loadWeaponInspectPanel = () => import('./WeaponInspectPanel');
const loadWeaponInspectPanelClassic = () => import('./WeaponInspectPanelClassic');

const ShopPanel = React.lazy(loadShopPanel);
const CraftingPanel = React.lazy(loadCraftingPanel);
const WeaponInspectPanel = React.lazy(loadWeaponInspectPanel);
const WeaponInspectPanelClassic = React.lazy(loadWeaponInspectPanelClassic);

export const preloadRightInventoryPanels = () => {
  void loadShopPanel();
  void loadCraftingPanel();
  void loadWeaponInspectPanel();
  void loadWeaponInspectPanelClassic();
};

const RightInventory: React.FC<{ active?: boolean }> = ({ active = true }) => {
  const stackRef = useRef<HTMLDivElement>(null);
  const rightInventory = useAppSelector(selectRightInventory);
  const weaponInspectOpen = useAppSelector(selectWeaponInspect).open;
  const backpack = rightInventory.backpack;
  const isLoadout = Config.layout === 'loadout';
  const gridHeightClass = 'h-[21.25rem]';
  // robbing a player: always cap their pockets to 3 visible rows (regardless
  // of whether they also have a backpack/utility/clothing), so there's
  // actually room left in the stack for those sections without heavy scrolling.
  const isRobbingPlayer = isLoadout && rightInventory?.type === 'otherplayer';
  const mainGridHeightClass = isRobbingPlayer
    ? 'h-[23.12rem]'
    : isLoadout && (!backpack || backpack.slots <= 0)
      ? 'h-[43rem]'
      : gridHeightClass;
  const showAuxiliarySections =
    rightInventory?.type !== 'crafting' &&
    rightInventory?.type !== 'shop';
  const hasExtraGrid = showAuxiliarySections && backpack && backpack.slots > 0;
  const showLoadoutWeaponInspect = isLoadout && weaponInspectOpen;

  useEffect(() => {
    if (!import.meta.env.DEV || new URLSearchParams(window.location.search).get('robScroll') !== '1') return;

    const timeout = window.setTimeout(() => {
      if (stackRef.current) stackRef.current.scrollTop = stackRef.current.scrollHeight;
    }, 250);

    return () => window.clearTimeout(timeout);
  }, [rightInventory.id, backpack?.id]);

  if (rightInventory?.type === 'shop') {
    return (
      <Suspense fallback={null}>
        <ShopPanel />
      </Suspense>
    );
  }

  if (rightInventory?.type === 'crafting') {
    if (isLoadout) {
      return (
        <Suspense fallback={null}>
          <CraftingPanel inventory={rightInventory} active={active} />
        </Suspense>
      );
    }
    return (
      <div
        className="absolute top-1/2 left-[82%] max-h-[86%] overflow-y-auto pr-2 no-scrollbar"
        style={{ transform: 'translate(-50%, -50%)' }}
      >
        <Suspense fallback={null}>
          <CraftingPanel inventory={rightInventory} active={active} />
        </Suspense>
      </div>
    );
  }

  return (
    <div
      ref={stackRef}
      className={`absolute top-1/2 right-8 flex flex-col gap-4 max-h-[86%] overflow-y-auto pr-2 no-scrollbar${isLoadout ? ` loadout-side-stack loadout-side-stack--right${hasExtraGrid ? ' loadout-side-stack--has-extra' : ''}${showLoadoutWeaponInspect ? ' weapon-inspect-active' : ''}` : ''}`}
      style={{
        transform: 'translateY(-50%)',
      }}
    >
      {showLoadoutWeaponInspect ? (
        <Suspense fallback={null}>
          <WeaponInspectPanel />
        </Suspense>
      ) : (
        <>
          <InventoryGrid
            inventory={rightInventory}
            inv={'right'}
            staticPosition
            frameless={isLoadout}
            gridClassName={mainGridHeightClass}
          />
          {showAuxiliarySections && backpack && backpack.slots > 0 && (
            <InventoryGrid
              inventory={backpack}
              inv={'right_backpack'}
              inventoryTypeOverride={InventoryType.OTHER_BACKPACK}
              staticPosition
              frameless={isLoadout}
              gridClassName={gridHeightClass}
            />
          )}
          {showAuxiliarySections && <OtherUtilitySection />}
          {showAuxiliarySections && <OtherClothingSection />}
          {!isLoadout && weaponInspectOpen && (
            <Suspense fallback={null}>
              <WeaponInspectPanelClassic />
            </Suspense>
          )}
        </>
      )}
    </div>
  );
};

export default React.memo(RightInventory);
