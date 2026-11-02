import { onDrop } from '../../dnd/onDrop';
import { Items } from '../../store/items';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import { isSlotWithItem, findAvailableSlot } from '../../helpers';
import { setClipboard } from '../../utils/setClipboard';
import { store, useAppDispatch, useAppSelector } from '../../store';
import React, { useEffect, useRef, useState } from 'react';
import { Menu, MenuItem } from '../utils/menu/Menu';
import Fade from '../utils/transitions/Fade';
import { closeContextMenu } from '../../store/contextMenu';
import { openWeaponInspect } from '../../store/weaponInspect';
import { InventoryType, SlotWithItem, Slot } from '../../typings';
import { Config } from '../../store/config';
import { selectItemAmount, setItemAmount, openRenameDialog, closeRenameDialog } from '../../store/inventory';

interface DataProps {
  action: string;
  component?: string;
  slot?: number;
  serial?: string;
  id?: number;
}

interface Button {
  label: string;
  index: number;
  group?: string;
}

interface Group {
  groupName: string | null;
  buttons: ButtonWithIndex[];
}

interface ButtonWithIndex extends Button {
  index: number;
}

interface GroupedButtons extends Array<Group> {}

type MoveResponse = { success: boolean; slot?: number; error?: string };

const InventoryContext: React.FC = () => {
  const contextMenu = useAppSelector((state) => state.contextMenu);
  const lastMenuCoords = React.useRef<{ x: number; y: number } | null>(null);
  if (contextMenu.coords) lastMenuCoords.current = contextMenu.coords;
  const item = contextMenu.item;
  const inventoryType = contextMenu.inventoryType || InventoryType.PLAYER;
  const inventoryId = contextMenu.inventoryId ?? undefined;
  const isPlayerInventory = inventoryType === InventoryType.PLAYER;
  const [showSplit, setShowSplit] = React.useState<boolean | SlotWithItem>(false);
  const splitContextRef = useRef<{ type: string; id: string | number | undefined }>({ type: InventoryType.PLAYER, id: undefined });
  const renameDialog = useAppSelector((state) => state.inventory.renameDialog);
  const dispatch = useAppDispatch();

  const ensureItemInPockets = async (): Promise<number | null> => {
    if (!item) return null;

    if (isPlayerInventory) {
      return item.slot;
    }

    if (!inventoryId || !item.name) {
      return null;
    }

    const state = store.getState().inventory;
    const playerInventory = state.leftInventory;
    const itemData = Items[item.name];

    if (!itemData) {
      return null;
    }

    const playerInventoryId = playerInventory.id || 'player';

    let targetSlot: Slot | undefined = findAvailableSlot(item, itemData, playerInventory.items);
    let fallbackSlot: SlotWithItem | undefined;

    if (!targetSlot) {
      fallbackSlot = playerInventory.items.find((slot): slot is SlotWithItem => isSlotWithItem(slot, true));

      if (!fallbackSlot) {
        return null;
      }

      targetSlot = { slot: fallbackSlot.slot };
    }

    const response = await fetchNui<MoveResponse>('contextMoveToPlayer', {
      fromSlot: item.slot,
      fromType: inventoryType,
      toSlot: targetSlot.slot,
      toType: InventoryType.PLAYER,
      count: item.count ?? 1,
      fromInventory: inventoryId,
      toInventory: playerInventoryId,
    });

    if (!response?.success) {
      return null;
    }

    return response.slot ?? targetSlot.slot;
  };

  const handleClick = async (data: DataProps) => {
    if (!item) return;
    let shouldClose = false;

    switch (data.action) {
      case 'use':
        await fetchNui('contextUseItem', {
          slot: item.slot,
          inventory: inventoryId ?? null,
          inventoryType,
          item,
        });
        shouldClose = true;
        break;
      case 'split':
        splitContextRef.current = { type: inventoryType, id: inventoryId };
        setShowSplit(showSplit === false ? item : false);
        shouldClose = true;
        break;
      case 'give': {
        const isFromBackpack = inventoryType === InventoryType.BACKPACK || inventoryType === InventoryType.OTHER_BACKPACK;
        const slot = isFromBackpack ? item.slot : await ensureItemInPockets();
        if (!slot) return;
        const { inventory: { itemAmount } } = store.getState();
        fetchNui('giveItem', {
          slot,
          count: itemAmount,
          inventory: isFromBackpack ? inventoryId : undefined,
        });
        shouldClose = true;
        break;
      }
      case 'give_nearby': {
        const isFromBackpack = inventoryType === InventoryType.BACKPACK || inventoryType === InventoryType.OTHER_BACKPACK;
        const slot = isFromBackpack ? item.slot : await ensureItemInPockets();
        if (!slot) return;
        const state = store.getState();
        const itemAmount = state.inventory.itemAmount;
        fetchNui('giveItemNearby', {
          slot,
          count: itemAmount,
          inventory: isFromBackpack ? inventoryId : undefined,
        });
        shouldClose = true;
        break;
      }
      case 'drop':
        if (isSlotWithItem(item)) {
          if (inventoryType === InventoryType.BACKPACK || inventoryType === InventoryType.OTHER_BACKPACK) {
            const count = item.count ?? 1;
            await fetchNui('swapItems', {
              fromSlot: item.slot,
              fromType: inventoryType,
              toSlot: 1,
              toType: 'newdrop',
              count,
              fromInventory: inventoryId,
            });
          } else {
            onDrop({
              item: { name: item.name, slot: item.slot },
              inventory: inventoryType,
              inventoryId,
              metadata: item.metadata,
            });
          }
        }
        shouldClose = true;
        break;
      case 'remove': {
        const slot = await ensureItemInPockets();
        if (!slot) return;
        fetchNui('removeComponent', { component: data.component, slot });
        shouldClose = true;
        break;
      }
      case 'removeAmmo': {
        const slot = await ensureItemInPockets();
        if (!slot) return;
        fetchNui('removeAmmo', slot);
        shouldClose = true;
        break;
      }
      case 'copy':
        setClipboard(data.serial || '');
        shouldClose = true;
        break;
      case 'custom': {
        const slot = await ensureItemInPockets();
        if (!slot) return;
        fetchNui('useButton', { id: (data.id || 0) + 1, slot });
        shouldClose = true;
        break;
      }
      case 'rename': {
        const currentLabel = item.metadata?.label || Items[item.name]?.label || item.name || '';
        dispatch(openRenameDialog({ mode: 'item', item, inventoryId: inventoryId ?? null, currentLabel }));
        dispatch(closeContextMenu());
        break;
      }
      case 'inspect': {
        const slot = await ensureItemInPockets();
        if (!slot) return;
        const response = await fetchNui<{ compatibleTypes: string[] } | false>('inspectWeapon', { slot });

        if (response && typeof response === 'object' && response.compatibleTypes) {
          dispatch(openWeaponInspect({ weaponSlot: slot, compatibleTypes: response.compatibleTypes }));
        }

        shouldClose = true;
        break;
      }
    }

    if (shouldClose) {
      dispatch(closeContextMenu());
    }
  };

  const groupButtons = (buttons: any): GroupedButtons => {
    return buttons.reduce((groups: Group[], button: Button, index: number) => {
      if (button.group) {
        const groupIndex = groups.findIndex((group) => group.groupName === button.group);

        if (groupIndex !== -1) {
          groups[groupIndex].buttons.push({ ...button, index });
        } else {
          groups.push({
            groupName: button.group,
            buttons: [{ ...button, index }],
          });
        }
      } else {
        groups.push({
          groupName: null,
          buttons: [{ ...button, index }],
        });
      }

      return groups;
    }, []);
  };

  const canUseItem = !(Config.disableUseInBackpack && (
    inventoryType === InventoryType.BACKPACK ||
    inventoryType === InventoryType.OTHER_BACKPACK ||
    (inventoryType === InventoryType.PLAYER && item?.name !== undefined && Config.backpackItems.includes(item.name))
  ));
  const isUtilityContext = inventoryType === InventoryType.UTILITY || inventoryType === InventoryType.OTHER_UTILITY;
  const canRenameItem = !!(item && item.name && Config.allowItemRename && Items[item.name]?.canRename !== false);

  return (
    <>
      <Menu>
        {canUseItem && <MenuItem onClick={() => void handleClick({ action: 'use' })} label={Locale.ui_use || 'Use'} />}
        {isUtilityContext ? (
          canRenameItem && (
            <MenuItem onClick={() => void handleClick({ action: 'rename' })} label={Locale.ui_rename || 'Rename'} />
          )
        ) : (
          <>
            {item && item.count && item.count > 1 && (
              <MenuItem onClick={() => void handleClick({ action: 'split' })} label={Locale.ui_split || 'Split'} />
            )}
            <MenuItem onClick={() => void handleClick({ action: 'give' })} label={Locale.ui_give || 'Give'} />
            <MenuItem onClick={() => void handleClick({ action: 'give_nearby' })} label={Locale.ui_give_nearby || 'Give Nearby'} />
            <MenuItem onClick={() => void handleClick({ action: 'drop' })} label={Locale.ui_drop || 'Drop'} />
            {item && item.metadata?.ammo > 0 && (
              <MenuItem onClick={() => void handleClick({ action: 'removeAmmo' })} label={Locale.ui_remove_ammo || 'Remove Ammo'} />
            )}
            {item && item.metadata?.serial && (
              <MenuItem onClick={() => void handleClick({ action: 'copy', serial: item.metadata?.serial })} label={Locale.ui_copy || 'Copy'} />
            )}
            {canRenameItem && (
              <MenuItem onClick={() => void handleClick({ action: 'rename' })} label={Locale.ui_rename || 'Rename'} />
            )}
            {item && item.name && Items[item.name]?.weapon && (
              <MenuItem onClick={() => void handleClick({ action: 'inspect' })} label={Locale.ui_inspect_weapon || 'Inspect Weapon'} />
            )}
            {item && item.metadata?.components && item.metadata.components.length > 0 && (
              <Menu label={Locale.ui_removeattachments || 'Remove Attachments'}>
                {item.metadata.components.map((component: string, index: number) => (
                  <MenuItem
                    key={index}
                    onClick={() => void handleClick({ action: 'remove', component })}
                    label={Items[component]?.label || component}
                  />
                ))}
              </Menu>
            )}
            {((item && item.name && Items[item.name]?.buttons?.length) || 0) > 0 && (
              <>
                {item &&
                  item.name &&
                  groupButtons(Items[item.name]?.buttons).map((group: Group, index: number) => (
                    <React.Fragment key={index}>
                      {group.groupName ? (
                        <Menu label={group.groupName}>
                          {group.buttons.map((button: Button) => (
                            <MenuItem
                              key={button.index}
                              onClick={() => void handleClick({ action: 'custom', id: button.index })}
                              label={button.label}
                            />
                          ))}
                        </Menu>
                      ) : (
                        group.buttons.map((button: Button) => (
                          <MenuItem
                            key={button.index}
                            onClick={() => void handleClick({ action: 'custom', id: button.index })}
                            label={button.label}
                          />
                        ))
                      )}
                    </React.Fragment>
                  ))}
              </>
            )}
          </>
        )}
      </Menu>
      <SplitContainer
        data={showSplit as SlotWithItem}
        anchor={lastMenuCoords.current}
        close={() => {
          setShowSplit(false);
          dispatch(setItemAmount(0));
        }}
        split={() => {
          const splitItem = showSplit as SlotWithItem;
          if (!splitItem || typeof splitItem === 'boolean') return;

          const source = {
            inventory: splitContextRef.current.type,
            inventoryId: splitContextRef.current.id,
            item: { name: splitItem.name, slot: splitItem.slot },
            metadata: splitItem.metadata,
          };

          onDrop(source, undefined, true);

          setShowSplit(false);
          dispatch(setItemAmount(0));
        }}
      />
      {renameDialog.open && (
        <RenameDialog
          anchor={renameDialog.coords ?? lastMenuCoords.current}
          mode={renameDialog.mode}
          item={renameDialog.item}
          inventoryId={renameDialog.inventoryId}
          currentLabel={renameDialog.currentLabel}
          close={() => dispatch(closeRenameDialog())}
        />
      )}
    </>
  );
};

export default InventoryContext;

const dialogAnchorStyle = (anchor: { x: number; y: number } | null, height: number): React.CSSProperties | undefined => {
  if (Config.layout !== 'loadout' || !anchor) return undefined;
  return {
    left: Math.max(8, Math.min(anchor.x, window.innerWidth - 268)),
    top: Math.max(8, Math.min(anchor.y, window.innerHeight - height)),
  };
};

const dialogClasses = (anchored: boolean, extra = '') =>
  `font-[Inter] text-white absolute w-[15.625rem] py-5 px-5 flex flex-col items-center justify-center gap-3 ${extra} ${
    Config.layout === 'loadout'
      ? 'loadout-dialog'
      : 'bg-black/75 rounded-lg border border-neutral-600'
  } ${anchored ? '' : 'top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2'}`;

const SplitContainer: React.FC<{
  data: SlotWithItem;
  anchor: { x: number; y: number } | null;
  close: () => void;
  split: () => void;
}> = ({ data, anchor, close, split }) => {
  const itemAmount = useAppSelector(selectItemAmount);
  const dispatch = useAppDispatch();

  useEffect(() => {
    if (data) dispatch(setItemAmount(1));
  }, [data, dispatch]);

  const inputHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    event.target.valueAsNumber =
      isNaN(event.target.valueAsNumber) || event.target.valueAsNumber < 0 ? 0 : Math.floor(event.target.valueAsNumber);
    dispatch(setItemAmount(event.target.valueAsNumber));
  };

  const quickSet = (divider: number) => {
    dispatch(setItemAmount(Math.max(1, Math.floor(data.count / divider))));
  };

  return (
    <>
      <Fade in={data ? true : false}>
        <div
          className={dialogClasses(!!dialogAnchorStyle(anchor, 380))}
          style={dialogAnchorStyle(anchor, 380)}
        >
          <p className="font-semibold text-2xl">{(Locale.ui_split || 'Split').toUpperCase()}</p>
          <div className="flex items-center flex-col gap-2 w-full">
            <p className="text-[0.9375rem]">{Locale.quantity || 'Quantity'}</p>
            <input
              type="number"
              min={1}
              max={data.count}
              value={itemAmount}
              onChange={inputHandler}
              className="bg-black/60 focus:outline-none rounded px-2 py-1 w-1/2 text-center border border-neutral-600"
            />
            <input
              type="range"
              min={1}
              max={data.count}
              value={itemAmount}
              onChange={inputHandler}
              className="split-slider w-full h-1.5 bg-black/65 rounded-full outline outline-1 outline-neutral-700/65 appearance-none cursor-pointer my-2
              [&::-webkit-slider-thumb]:appearance-none
              [&::-webkit-slider-thumb]:w-3.5
              [&::-webkit-slider-thumb]:h-3.5
              [&::-webkit-slider-thumb]:rounded-full"
            />
          </div>
          <div className="w-full flex items-center gap-2">
            <button
              className="split-btn bg-black/65 w-full py-1.5 border border-neutral-600 rounded duration-200"
              onClick={() => quickSet(2)}
            >
              1/2
            </button>
            <button
              className="split-btn bg-black/65 w-full py-1.5 border border-neutral-600 rounded duration-200"
              onClick={() => quickSet(3)}
            >
              1/3
            </button>
            <button
              className="split-btn bg-black/65 w-full py-1.5 border border-neutral-600 rounded duration-200"
              onClick={() => quickSet(4)}
            >
              1/4
            </button>
          </div>
          <div className="w-full flex items-center gap-2">
            <button
              className="split-btn bg-black/65 w-full py-1.5 border border-neutral-600 rounded text-sm duration-200"
              onClick={close}
            >
              {Locale.ui_cancel || 'Cancel'}
            </button>
            <button
              className="split-btn bg-black/65 w-full py-1.5 border border-neutral-600 rounded text-sm duration-200"
              onClick={split}
            >
              {Locale.ui_split || 'Split'}
            </button>
          </div>
        </div>
      </Fade>
    </>
  );
};

const RenameDialog: React.FC<{
  mode: 'item' | 'backpack';
  item: SlotWithItem | null;
  inventoryId: string | number | null;
  currentLabel: string;
  anchor: { x: number; y: number } | null;
  close: () => void;
}> = ({ mode, item, inventoryId, currentLabel, anchor, close }) => {
  const [value, setValue] = useState(currentLabel);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
    inputRef.current?.select();
  }, []);

  const confirm = async () => {
    const trimmed = value.trim();
    if (!trimmed) return;
    if (mode === 'item' && item) {
      await fetchNui('renameItem', { slot: item.slot, label: trimmed, inventoryId: inventoryId ?? null });
    } else if (mode === 'backpack') {
      await fetchNui('renameBackpack', { inventoryId, label: trimmed });
    }
    close();
  };

  return (
    <Fade in>
      <div
        className={dialogClasses(!!dialogAnchorStyle(anchor, 260), 'z-50')}
        style={dialogAnchorStyle(anchor, 260)}
      >
        <p className="font-semibold text-2xl">{(Locale.ui_rename || 'Rename').toUpperCase()}</p>
        <div className="flex items-center flex-col gap-2 w-full">
          <p className="text-[0.9375rem]">{Locale.ui_rename_label || 'Name'}</p>
          <input
            ref={inputRef}
            type="text"
            maxLength={32}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') void confirm(); if (e.key === 'Escape') close(); }}
            className="bg-black/60 focus:outline-none rounded px-2 py-1 w-full text-center border border-neutral-600"
          />
        </div>
        <div className="w-full flex items-center gap-2">
          <button
            className="bg-black/65 w-full py-1.5 border border-neutral-600 rounded text-sm split-btn duration-200"
            onClick={close}
          >
            {Locale.ui_cancel || 'Cancel'}
          </button>
          <button
            className="bg-black/65 w-full py-1.5 border border-neutral-600 rounded text-sm split-btn duration-200"
            onClick={() => void confirm()}
          >
            {Locale.ui_confirm || 'Confirm'}
          </button>
        </div>
      </div>
    </Fade>
  );
};
