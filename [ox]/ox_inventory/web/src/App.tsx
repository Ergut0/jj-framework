import React, { useEffect, useRef, useState } from 'react';
import InventoryComponent from './components/inventory';
import useNuiEvent from './hooks/useNuiEvent';
import { Items } from './store/items';
import { Locale } from './store/locale';
import { Config } from './store/config';
import { Rarity, setRarityEnabled } from './store/rarity';
import { setImagePath } from './store/imagepath';
import { setupInventory } from './store/inventory';
import { Inventory } from './typings';
import { useAppDispatch, store } from './store';
import { debugData } from './utils/debugData';
import DragPreview from './components/utils/DragPreview';
import { fetchNui } from './utils/fetchNui';
import { useDragDropManager } from 'react-dnd';
import KeyPress from './components/utils/KeyPress';
import BenchPermissionsModal from './components/Crafting/BenchPermissionsModal';
import { ItemNotificationsDisplay } from './components/utils/ItemNotifications';
import { closeTooltip } from './store/tooltip';
import { closeContextMenu } from './store/contextMenu';
import PlayerDropZone from './components/inventory/PlayerDropZone';
import { PlayerTarget } from './components/inventory/PlayerDropZone.types';
import PlacementHud from './components/placement/PlacementHud';
import { DragSource } from './typings';
import { CombineData, setCombineData } from './store/combine';

type ThemeConfig = {
  colors?: Record<string, string>;
  slotContentScale?: {
    image?: number;
    label?: number;
    quantity?: number;
  };
};

type RarityConfig = {
  Enabled: boolean;
  Levels: Record<string, {
    label: string;
    text: string;
    background: string;
    color: string;
    animation?: boolean;
  }>;
};

const applyRarityStyles = (config?: RarityConfig) => {
  if (!config || !config.Enabled) {
    document.getElementById('rarity-styles')?.remove();
    return;
  }

  let style = document.getElementById('rarity-styles');
  if (!style) {
    style = document.createElement('style');
    style.id = 'rarity-styles';
    document.head.appendChild(style);
  }

  let css = '';
  Object.entries(config.Levels).forEach(([key, level]) => {
    const rarityClass = `rarity-${key.toLowerCase()}`;
    const selector = `.item-slot-border.${rarityClass}, .item-slot.${rarityClass}, .utility-slot.${rarityClass}, .clothing-slot-shell.${rarityClass}`;
    css += `${selector} { --borderColor: ${level.color} !important; background: ${level.background} !important; border-color: transparent !important; }\n`;
    css += `${selector} .item-name { color: ${level.text} !important; }\n`;

  });

  style.innerHTML = css;
};

const applyTheme = (theme?: ThemeConfig) => {
  if (!theme) return;
  const root = document.documentElement;

  const colors = theme.colors || {};
  Object.entries(colors).forEach(([key, value]) => {
    if (typeof value === 'string' && value.length > 0) {
      const varName = key.startsWith('--') ? key : `--${key.replace(/_/g, '-')}`;
      root.style.setProperty(varName, value);
    }
  });

  const normalizeScale = (value?: number) =>
    typeof value === 'number' && Number.isFinite(value) && value > 0 ? value : 1;
  const slotContentScale = theme.slotContentScale;

  root.style.setProperty('--slot-image-scale', String(normalizeScale(slotContentScale?.image)));
  root.style.setProperty('--slot-label-scale', String(normalizeScale(slotContentScale?.label)));
  root.style.setProperty('--slot-quantity-scale', String(normalizeScale(slotContentScale?.quantity)));
};

if (import.meta.env.DEV) {
  const debugParams = new URLSearchParams(window.location.search);
  const debugInventoryFixture = debugParams.get('fixture') === 'inventory';
  const debugCraftingFixture = debugParams.get('fixture') === 'crafting';
  const debugLayout = debugParams.get('layout') === 'classic' ? 'classic' : 'loadout';
  const debugSideTilt = debugParams.get('tilt') === '1';
  const debugNotificationFixture = debugParams.get('notify') === '1';
  const debugRobbingFixture = debugParams.get('rob') === '1';
  const debugPermissionsFixture = debugParams.get('permissions');
  const debugShowcaseFixture = debugParams.get('showcase') === '1';

  const showcaseWearables = debugShowcaseFixture ? {
    clothingConfig: {
      enabled: true,
      slotOffset: 200,
      layout: { left: [1, 2, 3], right: [4, 5, 6] },
      slots: {
        1: { label: 'Jacket', itemName: 'jacket', component: 11 },
        2: { label: 'Gloves', itemName: 'gloves', component: 3 },
        3: { label: 'Pants', itemName: 'pants', component: 4 },
        4: { label: 'Shoes', itemName: 'shoes', component: 6 },
        5: { label: 'Hat', itemName: 'hat', prop: 0 },
        6: { label: 'Mask', itemName: 'mask', component: 1 },
      },
    },
    clothing: {
      offset: 200,
      items: {
        1: { slot: 1, name: 'jacket', count: 1, weight: 400 },
        2: { slot: 2, name: 'gloves', count: 1, weight: 100 },
        3: { slot: 3, name: 'pants', count: 1, weight: 350 },
        4: { slot: 4, name: 'shoes', count: 1, weight: 400 },
        5: { slot: 5, name: 'hat', count: 1, weight: 120 },
        6: { slot: 6, name: 'mask', count: 1, weight: 80 },
      },
    },
  } : {};

  const robbingRightInventory = {
    id: 'target-player-27',
    type: 'otherplayer',
    slots: 30,
    label: 'Target Player',
    weight: 13456,
    maxWeight: 85000,
    items: [
      { slot: 1, name: 'money', count: 2840, weight: 0 },
      { slot: 2, name: 'ammo-9', count: 24, weight: 288, metadata: { durability: 76 } },
      { slot: 3, name: 'armour', count: 1, weight: 4000, metadata: { durability: 54 } },
      { slot: 6, name: 'WEAPON_PISTOL', count: 1, weight: 1130, metadata: { ammo: 8, durability: 61 } },
      { slot: 8, name: 'ammo-45', count: 16, weight: 240, metadata: { durability: 88 } },
    ],
    backpack: {
      id: 'target-backpack-27',
      type: 'otherBackpack',
      slots: 10,
      label: 'Target Backpack',
      weight: 4418,
      maxWeight: 50000,
      items: [
        { slot: 1, name: 'ammo-rifle', count: 30, weight: 600, metadata: { durability: 82 } },
        { slot: 4, name: 'WEAPON_KNIFE', count: 1, weight: 1000, metadata: { durability: 70 } },
      ],
    },
    utility: {
      slots: 8,
      offset: 100,
      items: Array.from({ length: 8 }, (_, index) => ({ slot: index + 1 })),
      config: {
        labels: {
          1: 'Vest',
          2: 'Backpack',
          3: 'Phone',
          4: 'Parachute',
          5: 'Pocket',
          6: 'Tablet',
          7: 'Keys',
          8: 'Radio',
        },
      },
    },
  };

  debugData<any>([
    {
    action: 'init',
    data: {
      locale: {
        currency_symbol: '$',
        inventory: 'Inventory',
        combine: 'Combine',
        utility: 'Utility',
        ui_clothing: 'Clothing',
        ui_slots: 'Slots',
        ui_search: 'Search...',
        ui_inspect_weapon: 'Weapon Inspection',
        ui_no_attachments: 'No attachments available',
      },
      imagepath: 'images',
      theme: {
        colors: {
          '--color-primary': '#84cc16',
          '--color-primary-rgb': '132, 204, 22',
          '--color-body-scan': '#84cc16',
        },
      },
      rarity: {
        Enabled: true,
        Levels: {
          common: { label: 'Common', text: '#ffffff', color: '#636363', background: 'transparent' },
          uncommon: { label: 'Uncommon', text: '#84cc16', color: '#84cc16', background: 'transparent' },
          rare: { label: 'Rare', text: '#0ea5e9', color: '#0ea5e9', background: 'transparent' },
          epic: { label: 'Epic', text: '#c026d3', color: '#c026d3', background: 'transparent' },
          legendary: { label: 'Legendary', text: '#eab308', color: '#eab308', background: 'transparent' },
        },
      },
      combine: debugShowcaseFixture ? {
        enabled: true,
        categories: [
          { id: 'field', label: 'Field Gear' },
          { id: 'medical', label: 'Medical' },
          { id: 'equipment', label: 'Equipment' },
        ],
        recipes: [
          {
            id: 'field-radio',
            result: 'radio',
            label: 'Field Radio',
            category: 'field',
            duration: 2400,
            ingredients: [{ item: 'phone', count: 1 }, { item: 'ammo-9', count: 6 }],
          },
          {
            id: 'trauma-kit',
            result: 'bandage',
            count: 2,
            label: 'Trauma Kit',
            category: 'medical',
            duration: 1800,
            ingredients: [{ item: 'bandage', count: 2 }],
          },
          {
            id: 'repair-kit',
            result: 'armor_repair_kit',
            label: 'Armor Repair Kit',
            category: 'equipment',
            duration: 3200,
            ingredients: [{ item: 'armour', count: 1 }, { item: 'ammo-45', count: 8 }],
          },
          {
            id: 'heavy-vest',
            result: 'heavyarmour',
            label: 'Heavy Armor',
            category: 'equipment',
            duration: 4200,
            ingredients: [{ item: 'armour', count: 1 }, { item: 'ammo-rifle', count: 10 }],
          },
        ],
      } : {},
      config: {
        layout: debugLayout,
        loadoutSideTilt: debugSideTilt,
      },
      items: {
        money: { name: 'money', label: 'Money', stack: true, rarity: 'common' },
        armour: { name: 'armour', label: 'Armour', stack: true, rarity: 'legendary' },
        'ammo-9': { name: 'ammo-9', label: '9mm', stack: true, rarity: 'rare' },
        'ammo-45': { name: 'ammo-45', label: '.45 ACP', stack: true, rarity: 'uncommon' },
        'ammo-rifle': { name: 'ammo-rifle', label: '5.56x45', stack: true },
        'ammo-rifle2': { name: 'ammo-rifle2', label: '7.62x39', stack: true },
        'ammo-shotgun': { name: 'ammo-shotgun', label: '12 Gauge', stack: true },
        WEAPON_PISTOL: { name: 'WEAPON_PISTOL', label: 'Service Pistol', stack: false, rarity: 'rare' },
        at_flashlight: { name: 'at_flashlight', label: 'Tactical Light', stack: false, component: true, type: 'flashlight' },
        at_clip_extended_pistol: { name: 'at_clip_extended_pistol', label: 'Extended Magazine', stack: false, component: true, type: 'magazine' },
        WEAPON_BAT: { name: 'WEAPON_BAT', label: 'Bat', stack: false },
        WEAPON_DAGGER: { name: 'WEAPON_DAGGER', label: 'Dagger', stack: false },
        WEAPON_HATCHET: { name: 'WEAPON_HATCHET', label: 'Hatchet', stack: false },
        WEAPON_KNIFE: { name: 'WEAPON_KNIFE', label: 'Knife', stack: false },
        bandage: { name: 'bandage', label: 'Bandage', stack: true },
        phone: { name: 'phone', label: 'Phone', stack: false },
        parachute: { name: 'parachute', label: 'Parachute', stack: false },
        radio: { name: 'radio', label: 'Radio', stack: false },
        armor_repair_kit: { name: 'armor_repair_kit', label: 'Armor Repair Kit', stack: true },
        heavyarmour: { name: 'heavyarmour', label: 'Heavy Armor', stack: true },
        backpack_small: { name: 'backpack_small', label: 'Small Backpack', stack: false },
        backpack_medium: { name: 'backpack_medium', label: 'Medium Backpack', stack: false },
        jacket: { name: 'jacket', label: 'Jacket', stack: false },
        gloves: { name: 'gloves', label: 'Gloves', stack: false },
        pants: { name: 'pants', label: 'Pants', stack: false },
        shoes: { name: 'shoes', label: 'Shoes', stack: false },
        hat: { name: 'hat', label: 'Hat', stack: false },
        mask: { name: 'mask', label: 'Mask', stack: false },
      },
      leftInventory: {
        id: 'player',
        type: 'player',
        slots: 30,
        label: 'Pockets',
        weight: 1360,
        maxWeight: 85000,
        items: [
          { slot: 1, name: 'money', count: 5422, weight: 0 },
          { slot: 6, name: 'armour', count: 1, weight: 4000, durability: 72 },
          { slot: 7, name: 'ammo-9', count: 36, weight: 432, durability: 45 },
          { slot: 8, name: 'ammo-45', count: 18, weight: 270, durability: 90 },
          {
            slot: 9,
            name: 'WEAPON_PISTOL',
            count: 1,
            weight: 1130,
            durability: 68,
            metadata: {
              serial: 'LSPD-24-08317',
              ammo: 12,
              durability: 68,
              components: ['at_flashlight', 'at_clip_extended_pistol'],
            },
          },
          ...(debugShowcaseFixture ? [
            { slot: 10, name: 'phone', count: 1, weight: 190 },
            { slot: 11, name: 'bandage', count: 6, weight: 690 },
            { slot: 12, name: 'ammo-rifle', count: 30, weight: 600 },
          ] : []),
        ],
        ...showcaseWearables,
      },
    },
  },
  {
    action: 'setupInventory',
    data: {
      leftInventory: {
        id: 'player',
        type: 'player',
        slots: 30,
        label: 'Pockets',
        weight: 1360,
        maxWeight: 85000,
        items: [
          { slot: 1, name: 'money', count: 5422, weight: 0 },
          { slot: 6, name: 'armour', count: 1, weight: 4000, durability: 72 },
          { slot: 7, name: 'ammo-9', count: 36, weight: 432, durability: 45 },
          { slot: 8, name: 'ammo-45', count: 18, weight: 270, durability: 90 },
          {
            slot: 9,
            name: 'WEAPON_PISTOL',
            count: 1,
            weight: 1130,
            durability: 68,
            metadata: {
              serial: 'LSPD-24-08317',
              ammo: 12,
              durability: 68,
              components: ['at_flashlight', 'at_clip_extended_pistol'],
            },
          },
          ...(debugShowcaseFixture ? [
            { slot: 10, name: 'phone', count: 1, weight: 190 },
            { slot: 11, name: 'bandage', count: 6, weight: 690 },
            { slot: 12, name: 'ammo-rifle', count: 30, weight: 600 },
          ] : []),
        ],
        ...showcaseWearables,
        backpack: {
          id: 'backpack',
          type: 'backpack',
          slots: 10,
          label: 'Small Backpack',
          weight: 0,
          maxWeight: 50000,
          items: [],
        },
        utility: {
          slots: 8,
          offset: 100,
          items: Array.from({ length: 8 }, (_, index) => ({ slot: index + 1 })),
          config: {
            labels: {
              1: 'Vest',
              2: 'Backpack',
              3: 'Phone',
              4: 'Parachute',
              5: 'Pocket',
              6: 'Tablet',
              7: 'Keys',
              8: 'Radio',
            },
          },
        },
      },
      rightInventory: debugRobbingFixture ? robbingRightInventory : debugInventoryFixture ? {
        id: 'ground',
        type: 'drop',
        slots: 30,
        label: 'Ground',
        weight: 0,
        maxWeight: 85000,
        items: [],
      } : debugCraftingFixture ? {
        id: 'basic-crafting-bench',
        type: 'crafting',
        slots: 10,
        label: 'Basic Crafting Bench',
        weight: 0,
        maxWeight: 0,
        index: 1,
        crafting: {
          xp: { enabled: true, current: 182, hideLocked: false },
          blueprints: {},
          queue: [],
        },
        items: [
          { slot: 1, name: 'bandage', count: 1, weight: 115, duration: 2500, ingredients: {} },
          { slot: 2, name: 'phone', count: 1, weight: 190, duration: 5000, ingredients: {} },
          { slot: 3, name: 'parachute', count: 1, weight: 8000, duration: 9000, ingredients: {} },
          { slot: 4, name: 'radio', count: 1, weight: 1000, duration: 4500, ingredients: {} },
          { slot: 5, name: 'armor_repair_kit', count: 1, weight: 1200, duration: 6500, ingredients: {} },
          { slot: 6, name: 'armour', count: 1, weight: 3000, duration: 8000, ingredients: {} },
          { slot: 7, name: 'heavyarmour', count: 1, weight: 4500, duration: 12000, ingredients: {} },
          { slot: 8, name: 'backpack_small', count: 1, weight: 500, duration: 6000, ingredients: {} },
          { slot: 9, name: 'backpack_medium', count: 1, weight: 750, duration: 7500, ingredients: {} },
        ],
      } : {
        id: 'ammo-shop',
        type: 'shop',
        slots: 9,
        label: 'Ammunation',
        weight: 0,
        maxWeight: 0,
        paymentMethods: { cash: true, bank: true },
        items: [
          { slot: 1, name: 'ammo-45', weight: 40, price: 8, count: 100, metadata: { category: 'Ammunition' } },
          { slot: 2, name: 'ammo-shotgun', weight: 40, price: 10, count: 100, metadata: { category: 'Ammunition' } },
          { slot: 3, name: 'ammo-rifle', weight: 40, price: 11, count: 100, metadata: { category: 'Ammunition' } },
          { slot: 4, name: 'ammo-rifle2', weight: 40, price: 12, count: 100, metadata: { category: 'Ammunition' } },
          { slot: 5, name: 'ammo-9', weight: 40, price: 6, count: 100, metadata: { category: 'Ammunition' } },
          { slot: 6, name: 'WEAPON_BAT', weight: 1000, price: 118, count: 5, metadata: { category: 'Melee Weapons' } },
          { slot: 7, name: 'WEAPON_DAGGER', weight: 1000, price: 294, count: 5, metadata: { category: 'Melee Weapons' } },
          { slot: 8, name: 'WEAPON_HATCHET', weight: 1000, price: 352, count: 5, metadata: { category: 'Melee Weapons' } },
          { slot: 9, name: 'WEAPON_KNIFE', weight: 1000, price: 221, count: 5, metadata: { category: 'Melee Weapons' } },
        ],
      },
    },
    },
    ...(debugNotificationFixture ? [{
      action: 'itemNotify',
      data: [{ slot: 6, name: 'armour', count: 1, weight: 4000, durability: 72 }, 'Received', 2],
    }] : []),
    ...(debugPermissionsFixture ? [{
      action: 'openBenchPermissions',
      data: {
        benchId: debugPermissionsFixture === 'storage' ? 'storage:warehouse-alpha' : 'bench:mechanic-bay-01',
        benchLabel: debugPermissionsFixture === 'storage' ? 'Warehouse Alpha' : 'Mechanic Workbench',
        owner: { identifier: 'citizen:DM001', name: 'DM Owner', online: true, serverId: 12 },
        roles: [
          {
            id: 1,
            name: 'Supervisor',
            canUse: true,
            canMove: true,
            canPack: true,
            canManage: true,
            memberCount: 2,
            members: [
              { identifier: 'citizen:DM014', name: 'Alex Morgan', online: true, serverId: 28, addedBy: 'DM Owner' },
              { identifier: 'citizen:DM022', name: 'Sam Reed', online: false, addedBy: 'DM Owner' },
            ],
          },
          {
            id: 2,
            name: 'Worker',
            canUse: true,
            canMove: false,
            canPack: false,
            canManage: false,
            memberCount: 1,
            members: [
              { identifier: 'citizen:DM031', name: 'Jordan Lee', online: true, serverId: 41, addedBy: 'Alex Morgan' },
            ],
          },
          {
            id: 3,
            name: 'Visitor',
            canUse: true,
            canMove: false,
            canPack: false,
            canManage: false,
            memberCount: 0,
            members: [],
          },
        ],
        onlinePlayers: [
          { identifier: 'citizen:DM014', name: 'Alex Morgan', serverId: 28, roleId: 1 },
          { identifier: 'citizen:DM031', name: 'Jordan Lee', serverId: 41, roleId: 2 },
          { identifier: 'citizen:DM044', name: 'Taylor Kim', serverId: 55 },
        ],
        canTransfer: true,
        isOwner: true,
        playerPermissions: {
          canUse: true,
          canMove: true,
          canPack: true,
          canManage: true,
          isOwner: true,
        },
      },
    }] : []),
  ]);
}

const ZONE_HALF_W = 70;
const ZONE_HEAD_ABOVE = 30;
const ZONE_BODY_BELOW = 220;

const isOverPlayer = (cursorX: number, cursorY: number, t: PlayerTarget): boolean => {
  const vw = window.innerWidth;
  const vh = window.innerHeight;
  const px = t.screenX * vw;
  const py = t.screenY * vh;
  return (
    cursorX >= px - ZONE_HALF_W && cursorX <= px + ZONE_HALF_W &&
    cursorY >= py - ZONE_HEAD_ABOVE && cursorY <= py + ZONE_BODY_BELOW
  );
};

const INPUT_TAGS = new Set(['INPUT', 'TEXTAREA', 'SELECT']);

const App: React.FC = () => {
  const dispatch = useAppDispatch();
  const manager = useDragDropManager();
  const [playerTargets, setPlayerTargets] = useState<PlayerTarget[]>([]);
  const [hoveredServerId, setHoveredServerId] = useState<number | null>(null);
  const wasDraggingRef = useRef(false);
  const playerTargetsRef = useRef<PlayerTarget[]>([]);
  const mousePosRef = useRef<{ x: number; y: number } | null>(null);
  const dragItemRef = useRef<DragSource | null>(null);
  const giveOverrideRef = useRef(false);


  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Alt') giveOverrideRef.current = true;
    };
    const onKeyUp = (event: KeyboardEvent) => {
      if (event.key === 'Alt') giveOverrideRef.current = false;
    };
    const onBlur = () => {
      giveOverrideRef.current = false;
    };
    window.addEventListener('keydown', onKeyDown);
    window.addEventListener('keyup', onKeyUp);
    window.addEventListener('blur', onBlur);
    return () => {
      window.removeEventListener('keydown', onKeyDown);
      window.removeEventListener('keyup', onKeyUp);
      window.removeEventListener('blur', onBlur);
    };
  }, []);

  useEffect(() => {
    const monitor = manager.getMonitor();

    const isOverInventorySlot = (x: number, y: number): boolean => {
      const el = document.elementFromPoint(x, y) as HTMLElement | null;
      return !!el?.closest('.item-slot-border');
    };

    const unsubOffset = (monitor as any).subscribeToOffsetChange(() => {
      if (!wasDraggingRef.current) return;
      const offset = monitor.getClientOffset();
      if (!offset) return;
      mousePosRef.current = offset;

      const item = monitor.getItem() as DragSource | null;
      if (item) dragItemRef.current = item;

      let found: number | null = null;
      if (giveOverrideRef.current || !isOverInventorySlot(offset.x, offset.y)) {
        for (const t of playerTargetsRef.current) {
          if (isOverPlayer(offset.x, offset.y, t)) { found = t.serverId; break; }
        }
      }
      setHoveredServerId(found);
    });

    const unsubState = monitor.subscribeToStateChange(() => {
      const dragging = monitor.isDragging();
      if (dragging === wasDraggingRef.current) return;
      wasDraggingRef.current = dragging;
      fetchNui('setItemDragging', { dragging });

      if (!dragging) {
        const item = dragItemRef.current;
        const pos = mousePosRef.current;
        if (item && pos && (giveOverrideRef.current || !isOverInventorySlot(pos.x, pos.y))) {
          for (const t of playerTargetsRef.current) {
            if (isOverPlayer(pos.x, pos.y, t)) {
              const itemAmount = store.getState().inventory.itemAmount;
              fetchNui('dropItemOnPlayer', {
                serverId: t.serverId,
                slot: item.item.slot,
                count: itemAmount > 0 ? itemAmount : 0,
                inventory: item.inventoryId ?? null,
              });
              break;
            }
          }
        }
        dragItemRef.current = null;
        setPlayerTargets([]);
        setHoveredServerId(null);
        mousePosRef.current = null;
      }
    });

    return () => {
      unsubOffset();
      unsubState();
    };
  }, [manager]);

  useNuiEvent<PlayerTarget[]>('setPlayerDropTargets', (data) => {
    const targets = data ?? [];
    playerTargetsRef.current = targets;
    setPlayerTargets(targets);
  });

  useEffect(() => {
    const onFocusIn = (e: FocusEvent) => {
      if (INPUT_TAGS.has((e.target as HTMLElement)?.tagName)) {
        fetchNui('inputFocus', { focused: true });
      }
    };
    const onFocusOut = (e: FocusEvent) => {
      if (INPUT_TAGS.has((e.target as HTMLElement)?.tagName)) {
        fetchNui('inputFocus', { focused: false });
      }
    };
    document.addEventListener('focusin', onFocusIn);
    document.addEventListener('focusout', onFocusOut);
    return () => {
      document.removeEventListener('focusin', onFocusIn);
      document.removeEventListener('focusout', onFocusOut);
    };
  }, []);

  useNuiEvent<{
    locale: { [key: string]: string };
    items: typeof Items;
    leftInventory: Inventory;
    imagepath: string;
    theme?: ThemeConfig;
    rarity?: RarityConfig;
    combine?: CombineData;
    config?: { layout?: 'classic' | 'loadout'; disableUseInBackpack?: boolean; backpackItems?: string[]; allowItemRename?: boolean; allowBackpackRename?: boolean; loadoutSideTilt?: boolean; performanceProfiling?: boolean };
  }>('init', ({ locale, items, leftInventory, imagepath, theme, rarity, combine, config }) => {
    for (const name in locale) Locale[name] = locale[name];
    for (const name in items) Items[name] = items[name];

    setCombineData(combine);

    if (config?.layout === 'loadout' || config?.layout === 'classic') {
      Config.layout = config.layout;
    }
    if (config?.disableUseInBackpack !== undefined) {
      Config.disableUseInBackpack = config.disableUseInBackpack;
    }
    if (config?.backpackItems) {
      Config.backpackItems = config.backpackItems;
    }
    if (config?.allowItemRename !== undefined) {
      Config.allowItemRename = config.allowItemRename;
    }
    if (config?.allowBackpackRename !== undefined) {
      Config.allowBackpackRename = config.allowBackpackRename;
    }
    if (config?.loadoutSideTilt !== undefined) {
      Config.loadoutSideTilt = config.loadoutSideTilt;
    }
    if (config?.performanceProfiling !== undefined) {
      Config.performanceProfiling = config.performanceProfiling;
    }

    setImagePath(imagepath);
    applyTheme(theme);
    applyRarityStyles(rarity);
    setRarityEnabled(rarity?.Enabled === true);

    Object.keys(Rarity).forEach((k) => delete Rarity[k]);
    if (rarity?.Enabled && rarity?.Levels) {
      Object.entries(rarity.Levels).forEach(([key, level]) => {
        Rarity[key.toLowerCase()] = { text: level.text || level.color, background: level.background };
      });
    } else if (!rarity || rarity.Enabled === false) {
      Rarity['common'] = { text: '#ffffff', background: 'radial-gradient(#00000050, #51515150)' };
    }

    dispatch(setupInventory({ leftInventory }));
  });

  useEffect(() => {
    fetchNui('uiLoaded', {});
  }, []);

  useNuiEvent('closeInventory', () => {
    dispatch(closeTooltip());
    dispatch(closeContextMenu());
    manager.dispatch({ type: 'dnd-core/END_DRAG' });
  });

  useNuiEvent<{
    items?: Array<{ inventory: string | number; item: { slot: number } }>;
  }>('refreshSlots', ({ items }) => {
    if (!Array.isArray(items)) return;

    const monitor = manager.getMonitor();
    if (!monitor.isDragging()) return;

    const source = monitor.getItem() as DragSource | null;
    if (!source) return;

    const sourceInventoryId = source.inventoryId ?? source.inventory;
    const sourceWasRefreshed = items.some(
      (entry) =>
        entry.item.slot === source.item.slot &&
        String(entry.inventory) === String(sourceInventoryId)
    );

    if (sourceWasRefreshed) manager.dispatch({ type: 'dnd-core/END_DRAG' });
  });

  return (
    <>
      <div
        style={{
          position: 'fixed',
          inset: 0,
        }}
      >
        <div className="app-wrapper">
          <InventoryComponent />
          <KeyPress />
        </div>
        <BenchPermissionsModal />
        <ItemNotificationsDisplay />
      </div>
      <DragPreview />
      {playerTargets.map((t) => (
        <PlayerDropZone key={t.serverId} target={t} isHovered={hoveredServerId === t.serverId} />
      ))}
      <PlacementHud />
    </>
  );
};

addEventListener("dragstart", function (event) {
  event.preventDefault()
})

export default App;
