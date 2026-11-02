import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectLeftInventory, selectRightInventory, setItemAmount } from '../../store/inventory';
import { buyItem } from '../../thunks/buyItem';
import { Locale } from '../../store/locale';
import { InventoryType, SlotWithItem } from '../../typings';
import { getItemUrl, getTotalWeight, isSlotWithItem } from '../../helpers';
import { getCurrencySymbol } from '../../helpers/currency';
import { applyItemImageFallback } from '../../helpers/itemImageFallback';
import { Items } from '../../store/items';
import { isDeepEqual } from '../../helpers/isDeepEqual';
import { useDrag, useDrop } from 'react-dnd';
import type { DragSource } from '../../typings';
import shopBadgeIcon from '../../assets/svg/others.svg';
import { getColor } from '../inventory/InventorySlot';
import { Config } from '../../store/config';
import { isRarityEnabled, normalizeRarity } from '../../store/rarity';

type PaymentMethod = 'cash' | 'bank' | 'dirty';

type ShopEntry = {
  slot: number;
  item: SlotWithItem;
  label: string;
  description?: string;
  category: string;
  count?: number;
  price: number;
  currency?: string;
  weight: number;
  image: string;
};

type BasketLine = {
  slot: number;
  name: string;
  label: string;
  price: number;
  currency?: string;
  weight: number;
  qty: number;
  max: number;
  image: string;
  metadata?: SlotWithItem['metadata'];
};

const ALL_CATEGORY = 'All';
type ShopSortKey = 'name' | 'price' | 'available';
type ShopSortDirection = 'asc' | 'desc';

const clampQty = (value: number, max: number) => {
  if (!Number.isFinite(value)) return 1;
  const next = Math.max(1, Math.floor(value));
  if (max > 0) return Math.min(next, max);
  return next;
};

const formatPrice = (price: number, currency?: string) => {
  const localeKey = Locale.localeString;
  const localeString =
    localeKey && localeKey !== 'localeString' && localeKey !== ''
      ? localeKey
      : (typeof navigator !== 'undefined' ? navigator.language : 'en-US') || 'en-US';
  const localeWithLatinDigits = `${localeString}-u-nu-latn`;

  if (currency && currency !== 'money' && currency !== 'black_money') {
    return price.toLocaleString(localeWithLatinDigits as string);
  }

  const symbol = getCurrencySymbol();
  return `${symbol}${price.toLocaleString(localeWithLatinDigits as string)}`;
};

const resolveCategory = (slot: SlotWithItem) => {
  const metadata = slot.metadata;

  if (metadata?.category && typeof metadata.category === 'string') return metadata.category;
  if (metadata?.type && typeof metadata.type === 'string') return metadata.type;
  if (metadata?.class && typeof metadata.class === 'string') return metadata.class;

  return 'General';
};

const notify = async (type: 'success' | 'error', message: string) => {
  await fetch('https://ox_inventory/notify', {
    method: 'POST',
    body: JSON.stringify({ type, message }),
  });
};

const transparentDragImage =
  typeof window !== 'undefined'
    ? (() => {
      const img = new Image();
      img.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';
      return img;
    })()
    : undefined;

type ShopItemCardProps = {
  entry: ShopEntry;
  inventoryId: string | number;
  isSelected: boolean;
  disabled: boolean;
  onSelect: () => void;
  onDoubleClick: () => void;
  onDragStart: (entry: ShopEntry) => void;
  onDragEnd: () => void;
};

const ShopItemCard: React.FC<ShopItemCardProps> = ({
  entry,
  inventoryId,
  isSelected,
  disabled,
  onSelect,
  onDoubleClick,
  onDragStart,
  onDragEnd,
}) => {
  const outOfStock = entry.count !== undefined && entry.count <= 0;

  const [{ isDragging }, drag, preview] = useDrag<DragSource, void, { isDragging: boolean }>(
    () => ({
      type: 'SLOT',
      item: () => {
        onDragStart(entry);
        return {
          inventory: InventoryType.SHOP,
          inventoryId,
          item: { slot: entry.slot, name: entry.item.name },
          metadata: entry.item.metadata,
        };
      },
      canDrag: !disabled && !outOfStock,
      collect: (monitor) => ({
        isDragging: monitor.isDragging(),
      }),
      end: () => {
        onDragEnd();
      },
    }),
    [disabled, entry, inventoryId, onDragEnd, onDragStart, outOfStock]
  );

  useEffect(() => {
    if (transparentDragImage) {
      preview(transparentDragImage, { captureDraggingState: true });
    }
  }, [preview]);

  const setRefs = useCallback(
    (node: HTMLDivElement | null) => {
      if (node) drag(node);
    },
    [drag]
  );

  const rarity = isRarityEnabled() ? normalizeRarity(Items[entry.item.name]?.rarity) : undefined;
  const rarityColor = rarity && rarity !== 'common' ? getColor(rarity).text : 'var(--color-slot-border)';

  return (
    <div
      ref={setRefs}
      className={`relative w-[6.75rem] h-[6.75rem] border border-transparent item-slot-border shop-slot${outOfStock ? ' opacity-40' : ''}${isDragging ? ' opacity-50' : ''}`}
      style={{
        '--borderColor': isSelected ? 'var(--color-slot-border-hover)' : rarityColor,
        cursor: disabled || outOfStock ? 'not-allowed' : 'pointer',
      } as React.CSSProperties}
      onClick={!disabled && !outOfStock ? onSelect : undefined}
      onDoubleClick={!disabled && !outOfStock ? onDoubleClick : undefined}
      data-slot={entry.slot}
      data-slot-index={entry.slot}
      data-inventory-type={InventoryType.SHOP}
      data-inventory-id={inventoryId !== undefined && inventoryId !== null ? String(inventoryId) : ''}
    >
      <div className="shop-price-badge">
        {formatPrice(entry.price, entry.currency)}
      </div>

      <div className="p-1.5 text-secondary text-xs relative w-full h-full pointer-events-none">
        {entry.image && (
          <img
            src={entry.image}
            className="slot-content-image slot-content-image--centered absolute w-[4.125rem] h-[4.125rem] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-0"
            alt={entry.label}
            loading="lazy"
            decoding="async"
            draggable={false}
            onError={applyItemImageFallback}
          />
        )}

        <div className="leading-3 font-[350] relative z-10">
          {rarity ? (
            <p
              className="absolute top-0 right-0 text-[0.625rem] font-medium"
              style={{ color: rarity === 'common' ? 'var(--tx)' : getColor(rarity).text }}
            >
              {rarity.toUpperCase()}
            </p>
          ) : entry.count !== undefined ? (
            <p className="slot-content-quantity slot-content-quantity--right absolute top-0 right-0 text-[0.625rem] font-medium text-white/60">
              {entry.count}x
            </p>
          ) : null}
        </div>

        <p className="slot-content-label slot-content-label--center absolute bottom-1 left-0 right-0 text-[0.625rem] font-medium truncate leading-3 text-center" style={{ color: 'var(--accent-label)' }}>
          {entry.label}
        </p>
      </div>
    </div>
  );
};

type ShopProductCardProps = {
  entry: ShopEntry;
  inventoryId: string | number;
  disabled: boolean;
  addLabel: string;
  onAdd: (entry: ShopEntry, qty: number) => void;
};

type ShopSortButtonProps = {
  label: string;
  icon: string;
  sortKey: ShopSortKey;
  activeSort: ShopSortKey;
  direction: ShopSortDirection;
  disabled?: boolean;
  onClick: (sortKey: ShopSortKey) => void;
};

const ShopSortButton: React.FC<ShopSortButtonProps> = ({
  label,
  icon,
  sortKey,
  activeSort,
  direction,
  disabled,
  onClick,
}) => (
  <button
    type="button"
    className={`shop-sort-btn${activeSort === sortKey ? ' active' : ''}`}
    onClick={() => onClick(sortKey)}
    disabled={disabled}
  >
    <i className={`fas ${icon}`} />
    <span>{label}</span>
    {activeSort === sortKey ? (
      <i className={`fas ${direction === 'asc' ? 'fa-arrow-up' : 'fa-arrow-down'} shop-sort-dir`} />
    ) : null}
  </button>
);

const ShopProductCard: React.FC<ShopProductCardProps> = React.memo(({
  entry,
  inventoryId,
  disabled,
  addLabel,
  onAdd,
}) => {
  const [qty, setQty] = useState(1);
  const outOfStock = entry.count !== undefined && entry.count <= 0;
  const max = entry.count ?? 999;

  return (
    <div
      className={`shop-card${outOfStock ? ' is-out' : ''}`}
      data-slot={entry.slot}
      data-slot-index={entry.slot}
      data-inventory-type={InventoryType.SHOP}
      data-inventory-id={inventoryId !== undefined && inventoryId !== null ? String(inventoryId) : ''}
    >
      <span className="shop-card-price">{formatPrice(entry.price, entry.currency)}</span>
      {entry.count !== undefined && <span className="shop-card-stock slot-content-quantity slot-content-quantity--right">{entry.count}x</span>}
      <div className="shop-card-media">
        {entry.image && (
          <img
            className="shop-card-img slot-content-image"
            src={entry.image}
            alt={entry.label}
            loading="lazy"
            decoding="async"
            draggable={false}
            onError={applyItemImageFallback}
          />
        )}
        <p className="shop-card-name slot-content-label slot-content-label--center">{entry.label}</p>
      </div>
      <div className="shop-card-side">
        <div className="shop-card-qty">
          <button
            type="button"
            disabled={disabled || outOfStock || qty <= 1}
            onClick={() => setQty((prev) => clampQty(prev - 1, max))}
          >
            <i className="fas fa-minus" />
          </button>
          <input
            type="text"
            value={qty}
            onChange={(event) => setQty(clampQty(Number(event.target.value.replace(/\D/g, '')) || 1, max))}
            disabled={disabled || outOfStock}
          />
          <button
            type="button"
            disabled={disabled || outOfStock || qty >= max}
            onClick={() => setQty((prev) => clampQty(prev + 1, max))}
          >
            <i className="fas fa-plus" />
          </button>
        </div>
        <button
          type="button"
          className="shop-card-add"
          disabled={disabled || outOfStock}
          onClick={() => onAdd(entry, qty)}
        >
          <i className="fas fa-plus" />
          <span>{addLabel}</span>
        </button>
      </div>
    </div>
  );
});

const ShopPanel: React.FC = () => {
  const dispatch = useAppDispatch();
  const left = useAppSelector(selectLeftInventory);
  const right = useAppSelector(selectRightInventory);
  const isLoadout = Config.layout === 'loadout';
  const dragQuantityRef = useRef<number>(1);
  const debugBasketSeededRef = useRef(false);
  const t = (key: string, fallback: string) => {
    const value = Locale[key];
    return value && value !== key ? value : fallback;
  };

  const [selectedSlot, setSelectedSlot] = useState<number | null>(null);
  const [shopQty, setShopQty] = useState<number>(1);
  const [shopSearch, setShopSearch] = useState<string>('');
  const [shopCategory, setShopCategory] = useState<string>(ALL_CATEGORY);
  const [shopSort, setShopSort] = useState<ShopSortKey>('name');
  const [shopSortDirection, setShopSortDirection] = useState<ShopSortDirection>('asc');
  const [basket, setBasket] = useState<BasketLine[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const outOfStockText = t('shop_nostock', 'Item is out of stock');
  const noSpaceText = t('shop_no_space', 'No inventory space available');
  const noPaymentText = t('shop_no_payment', 'No payment method available');
  const shopPaymentMethods = right.paymentMethods ?? {};
  const canPayCash = shopPaymentMethods.cash !== false;
  const canPayBank = shopPaymentMethods.bank !== false;
  const canPayDirty =
    shopPaymentMethods.dirty === true ||
    shopPaymentMethods.black_money === true ||
    right.allowDirtyMoney === true;
  const defaultPaymentMethod: PaymentMethod | null = canPayCash ? 'cash' : canPayBank ? 'bank' : canPayDirty ? 'dirty' : null;

  const shopEntries = useMemo<ShopEntry[]>(() => {
    return right.items
      .filter((slot): slot is SlotWithItem => isSlotWithItem(slot as any))
      .map((slot) => {
        const itemData = Items[slot.name];
        const label = slot.metadata?.label || itemData?.label || slot.name;
        const description = slot.metadata?.description || itemData?.description;

        return {
          slot: slot.slot,
          item: slot,
          label,
          description,
          category: resolveCategory(slot),
          count: slot.count,
          price: slot.price ?? 0,
          currency: slot.currency,
          weight: slot.weight ?? 0,
          image: getItemUrl(slot) || '',
        };
      });
  }, [right.items]);

  useEffect(() => {
    setSelectedSlot(null);
    setShopQty(1);
    setShopSearch('');
    setShopCategory(right.hideAll ? '' : ALL_CATEGORY);
    setShopSort('name');
    setShopSortDirection('asc');
    setBasket([]);
    debugBasketSeededRef.current = false;
    dragQuantityRef.current = 1;
    dispatch(setItemAmount(0));
    return () => {
      dispatch(setItemAmount(0));
    };
  }, [dispatch, right.id, right.hideAll]);

  useEffect(() => {
    const isLocalPreview =
      import.meta.env.DEV &&
      typeof window !== 'undefined' &&
      window.location.hostname === '127.0.0.1' &&
      right.id === 'ammo-shop';

    if (!isLocalPreview || debugBasketSeededRef.current || shopEntries.length === 0) return;

    debugBasketSeededRef.current = true;
    const previewQuantities = [2, 1, 3, 1];
    setBasket(
      shopEntries.slice(0, previewQuantities.length).map((entry, index) => ({
        slot: entry.slot,
        name: entry.item.name,
        label: entry.label,
        price: entry.price,
        currency: entry.currency,
        weight: entry.weight,
        qty: Math.min(previewQuantities[index], entry.count ?? previewQuantities[index]),
        max: entry.count ?? 999,
        image: entry.image,
        metadata: entry.item.metadata,
      }))
    );
  }, [right.id, shopEntries]);

  useEffect(() => {
    setBasket((prev) => {
      const mapped = prev
        .map((line) => {
          const entry = shopEntries.find((item) => item.slot === line.slot);
          if (!entry) return null;
          const max = entry.count ?? 999;
          const qty = Math.min(line.qty, max > 0 ? max : line.qty);
          if (max === 0 || qty <= 0) return null;

          const updated: BasketLine = {
            ...line,
            max,
            qty,
            price: entry.price,
            currency: entry.currency,
            weight: entry.weight,
            label: entry.label,
            image: entry.image,
            metadata: entry.item.metadata,
          };

          return updated;
        })
        .filter((line): line is BasketLine => line !== null);

      return mapped;
    });
  }, [shopEntries]);

  const categories = useMemo(() => {
    const set = new Set<string>();
    if (!right.hideAll) {
      set.add(ALL_CATEGORY);
    }
    shopEntries.forEach((entry) => set.add(entry.category));
    return Array.from(set);
  }, [shopEntries, right.hideAll]);

  useEffect(() => {
    if (categories.length > 0 && !categories.includes(shopCategory)) {
      setShopCategory(categories[0]);
    }
  }, [categories, shopCategory]);

  const filteredShopItems = useMemo(() => {
    const query = shopSearch.trim().toLowerCase();
    const filtered = shopEntries.filter((entry) => {
      if (shopCategory !== ALL_CATEGORY && entry.category !== shopCategory) return false;
      if (!query) return true;

      const haystack = [
        entry.label,
        entry.item.name,
        entry.description,
        entry.item.metadata?.description,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();

      return haystack.includes(query);
    });

    return [...filtered].sort((a, b) => {
      let result = 0;

      if (shopSort === 'price') {
        result = a.price - b.price;
      } else if (shopSort === 'available') {
        const aCount = a.count ?? 999999;
        const bCount = b.count ?? 999999;
        result = aCount - bCount;
      } else {
        result = a.label.localeCompare(b.label);
      }

      return shopSortDirection === 'asc' ? result : -result;
    });
  }, [shopEntries, shopCategory, shopSearch, shopSort, shopSortDirection]);

  const selectedEntry = useMemo(
    () => shopEntries.find((entry) => entry.slot === selectedSlot) ?? null,
    [shopEntries, selectedSlot]
  );

  const rightWeight = useMemo(() => getTotalWeight(right.items), [right.items]);
  const rightWeightPercent = right.maxWeight ? Math.min((rightWeight / right.maxWeight) * 100, 100) : 0;
  const rightWeightClass =
    rightWeightPercent < 50 ? 'low' : rightWeightPercent < 75 ? 'medium' : 'high';

  const basketSubtotal = useMemo(
    () => basket.reduce((sum, line) => sum + line.price * line.qty, 0),
    [basket]
  );
  const basketTotalWeight = useMemo(
    () => basket.reduce((sum, line) => sum + line.weight * line.qty, 0),
    [basket]
  );

  const useAnimatedNumber = (target: number, duration = 400) => {
    const [displayed, setDisplayed] = useState(target);
    const rafRef = useRef<number | null>(null);
    const currentRef = useRef(target);
    const fromRef = useRef(target);
    const startTimeRef = useRef(0);

    useEffect(() => {
      if (currentRef.current === target) return;

      if (rafRef.current) cancelAnimationFrame(rafRef.current);

      fromRef.current = currentRef.current;
      startTimeRef.current = performance.now();
      const from = fromRef.current;
      const to = target;

      const animate = (now: number) => {
        const elapsed = now - startTimeRef.current;
        const progress = Math.min(elapsed / duration, 1);
        const eased = 1 - Math.pow(1 - progress, 3);
        const value = from + (to - from) * eased;
        currentRef.current = value;
        setDisplayed(value);

        if (progress < 1) {
          rafRef.current = requestAnimationFrame(animate);
        } else {
          currentRef.current = to;
          setDisplayed(to);
        }
      };

      rafRef.current = requestAnimationFrame(animate);
      return () => {
        if (rafRef.current) cancelAnimationFrame(rafRef.current);
      };
    }, [target, duration]);

    return displayed;
  };

  const animatedCost = useAnimatedNumber(basketSubtotal);
  const animatedWeight = useAnimatedNumber(basketTotalWeight);
  const basketCount = useMemo(
    () => basket.reduce((sum, line) => sum + line.qty, 0),
    [basket]
  );

  const upsertBasketLine = useCallback(
    (entry: ShopEntry, qty: number) => {
      if (!entry || qty <= 0) return;
      if (entry.count !== undefined && entry.count <= 0) {
        notify('error', outOfStockText);
        return;
      }

      const hardMax = entry.count ?? 999;
      const safeQty = clampQty(qty, hardMax || qty);
      if (safeQty <= 0) return;

      setBasket((prev) => {
        const idx = prev.findIndex((line) => line.slot === entry.slot);
        if (idx > -1) {
          const next = [...prev];
          const combined = clampQty(next[idx].qty + safeQty, hardMax || 999);
          next[idx] = {
            ...next[idx],
            qty: combined,
            max: hardMax || 999,
            price: entry.price,
            currency: entry.currency,
            weight: entry.weight,
            label: entry.label,
            image: entry.image,
            metadata: entry.item.metadata,
          };
          return next;
        }

        const line: BasketLine = {
          slot: entry.slot,
          name: entry.item.name,
          label: entry.label,
          price: entry.price,
          currency: entry.currency,
          weight: entry.weight,
          qty: safeQty,
          max: hardMax || 999,
          image: entry.image,
          metadata: entry.item.metadata,
        };

        return [...prev, line];
      });
    },
    [outOfStockText]
  );

  const handleDragStart = useCallback(
    (entry: ShopEntry) => {
      const max = entry.count ?? 999;
      const qty = clampQty(shopQty, max || shopQty);
      dragQuantityRef.current = qty;
      dispatch(setItemAmount(qty));
    },
    [dispatch, shopQty]
  );

  const handleDragEnd = useCallback(() => {
    dragQuantityRef.current = 1;
    dispatch(setItemAmount(0));
  }, [dispatch]);

  const [{ isOver: isBasketOver }, basketDropRef] = useDrop<DragSource, void, { isOver: boolean }>(
    () => ({
      accept: 'SLOT',
      canDrop: (source) => !isLoadout && source.inventory === InventoryType.SHOP,
      drop: (source) => {
        if (isLoadout) return;
        const entry = shopEntries.find((item) => item.slot === source.item.slot);
        if (!entry) return;

        const max = entry.count ?? dragQuantityRef.current;
        if (max <= 0) {
          notify('error', outOfStockText);
          return;
        }

        const qty = clampQty(dragQuantityRef.current, max || dragQuantityRef.current);
        upsertBasketLine(entry, qty);
      },
      collect: (monitor) => ({
        isOver: !isLoadout && monitor.isOver({ shallow: true }),
      }),
    }),
    [isLoadout, outOfStockText, shopEntries, upsertBasketLine]
  );

  const pickTargetSlot = useCallback(
    (entry: ShopEntry, preferEmpty: boolean) => {
      const items = left.items;
      const metadata = entry.item.metadata;
      const itemData = Items[entry.item.name];

      if (!preferEmpty && itemData?.stack) {
        const stackTarget = items.find(
          (slot) =>
            isSlotWithItem(slot) &&
            slot.name === entry.item.name &&
            isDeepEqual(slot.metadata, metadata)
        );

        if (stackTarget) return stackTarget.slot;
      }

      const emptySlot = items.find((slot) => !slot?.name);
      return emptySlot ? emptySlot.slot : null;
    },
    [left.items]
  );

  const attemptPurchase = useCallback(
    async (entry: ShopEntry, quantity: number, payment: PaymentMethod = 'cash') => {
      const targetSlot = pickTargetSlot(entry, false);

      if (!targetSlot) {
        await notify('error', noSpaceText);
        return false;
      }

      try {
        await dispatch(
          buyItem({
            fromSlot: entry.slot,
            fromType: right.type,
            toSlot: targetSlot,
            toType: left.type || InventoryType.PLAYER,
            count: quantity,
            payment,
          })
        ).unwrap();

        return true;
      } catch {
        return false;
      }
    },
    [dispatch, left.type, noSpaceText, pickTargetSlot, right.type]
  );

  const handleSelect = (slot: number) => {
    setSelectedSlot((prev) => (prev === slot ? null : slot));
    setShopQty(1);
  };

  const handleAddSelectedToBasket = () => {
    if (!selectedEntry) return;
    upsertBasketLine(selectedEntry, shopQty);
  };

  const handleSortChange = (sortKey: ShopSortKey) => {
    if (shopSort === sortKey) {
      setShopSortDirection((prev) => (prev === 'asc' ? 'desc' : 'asc'));
      return;
    }

    setShopSort(sortKey);
    setShopSortDirection(sortKey === 'price' ? 'asc' : 'asc');
  };

  const handleUpdateBasketQty = (index: number, value: number) => {
    setBasket((prev) => {
      const next = [...prev];
      const line = next[index];
      if (!line) return prev;
      const max = line.max || 999;
      next[index] = { ...line, qty: clampQty(value, max) };
      return next;
    });
  };

  const handleRemoveFromBasket = (index: number) => {
    setBasket((prev) => prev.filter((_, idx) => idx !== index));
  };

  const handleBuySelected = async () => {
    if (!selectedEntry || isProcessing) return;

    const max = selectedEntry.count ?? shopQty;
    if (max === 0) {
      notify('error', outOfStockText);
      return;
    }

    const qty = clampQty(shopQty, max || shopQty);

    setIsProcessing(true);
    if (!defaultPaymentMethod) {
      await notify('error', noPaymentText);
      setIsProcessing(false);
      return;
    }

    const success = await attemptPurchase(selectedEntry, qty, defaultPaymentMethod);
    setIsProcessing(false);

    if (success) {
      setSelectedSlot(null);
      setShopQty(1);
    }
  };

  const handleCheckout = async (method: PaymentMethod) => {
    if (!basket.length || isProcessing) return;
    setIsProcessing(true);

    const snapshot = [...basket];
    let halted = false;

    for (const line of snapshot) {
      let remaining = line.qty;

      while (remaining > 0) {
        const entry = shopEntries.find((item) => item.slot === line.slot);
        if (!entry) {
          setBasket((prev) => prev.filter((b) => b.slot !== line.slot));
          break;
        }

        const available = entry.count ?? remaining;
        if (available <= 0) {
          setBasket((prev) => prev.filter((b) => b.slot !== line.slot));
          break;
        }

        const qty = clampQty(remaining, available);
        const success = await attemptPurchase(entry, qty, method);

        if (!success) {
          halted = true;
          remaining = 0;
          break;
        }

        remaining -= qty;
        setBasket((prev) => {
          const next = [...prev];
          const idx = next.findIndex((b) => b.slot === line.slot);
          if (idx === -1) return prev;

          if (remaining <= 0) {
            next.splice(idx, 1);
          } else {
            next[idx] = { ...next[idx], qty: remaining };
          }

          return next;
        });
      }

      if (halted) break;
    }

    setIsProcessing(false);
  };

  const renderCategoryLabel = (category: string) => {
    if (category === ALL_CATEGORY) return t('all', 'All');
    if (category === 'General') return t('general', 'General');
    return category;
  };

  if (!right || right.type !== 'shop') return null;

  const cartList =
    basket.length === 0 ? (
      <div className="basket-empty">
        <i className="fas fa-hand-pointer" />
        <p>{t('shop_cart_help', 'Select items and use Add to Cart to build your order.')}</p>
      </div>
    ) : (
      <div className="cart-list basket-list">
        {basket.map((line, index) => (
          <div key={`basket-${line.slot}`} className="cart-item basket-item">
            <div className="cart-left">
              <span className="cart-line-number">{String(index + 1).padStart(2, '0')}</span>
              <div className="cart-thumb">
                {line.image ? (
                  <img
                    src={line.image}
                    alt={line.label}
                    loading="lazy"
                    decoding="async"
                    draggable={false}
                    onError={applyItemImageFallback}
                  />
                ) : null}
              </div>
              <div className="cart-meta">
                <div className="cart-name">{line.label}</div>
                <div className="cart-weight">
                  {(line.weight / 1000).toFixed(2)} {t('shop_weight_each', 'kg each')}
                </div>
              </div>
            </div>
            <div className="cart-right">
              <div className="qty-box qty-inline">
                <button
                  onClick={() => handleUpdateBasketQty(index, line.qty - 1)}
                  disabled={line.qty <= 1 || isProcessing}
                >
                  <i className="fas fa-minus" />
                </button>
                <input
                  type="number"
                  min={1}
                  max={line.max}
                  value={line.qty}
                  onChange={(event) => handleUpdateBasketQty(index, Number(event.target.value))}
                  disabled={isProcessing}
                />
                <button
                  onClick={() => handleUpdateBasketQty(index, line.qty + 1)}
                  disabled={line.qty >= line.max || isProcessing}
                >
                  <i className="fas fa-plus" />
                </button>
              </div>

              <div className="price-chip">{formatPrice(line.price * line.qty, line.currency)}</div>

              <button
                className="icon-btn danger btn-x"
                title={t('remove', 'Remove')}
                onClick={() => handleRemoveFromBasket(index)}
                disabled={isProcessing}
              >
                <i className="fas fa-xmark" />
              </button>
            </div>
          </div>
        ))}
      </div>
    );

  const cartTotals = (
    <>
      <div className="total-line">
        <span>{t('total_cost', 'Total cost')}</span>
        <strong>{formatPrice(Math.round(animatedCost))}</strong>
      </div>
      <div className="total-line">
        <span>{t('total_weight', 'Total weight')}</span>
        <strong>{(animatedWeight / 1000).toFixed(2)}kg</strong>
      </div>
    </>
  );

  const payActions = (
    <div className="pay-actions">
      {canPayBank ? (
        <button
          className="btn-pay bank btn-outline"
          onClick={() => handleCheckout('bank')}
          disabled={basket.length === 0 || isProcessing}
        >
          <i className="fas fa-wallet" /> {t('pay_bank', 'Pay Bank')}
        </button>
      ) : null}
      {canPayDirty ? (
        <button
          className="btn-pay dirty btn-outline"
          onClick={() => handleCheckout('dirty')}
          disabled={basket.length === 0 || isProcessing}
        >
          <i className="fas fa-mask" /> {t('pay_dirty', 'Pay Dirty Money')}
        </button>
      ) : null}
      {canPayCash ? (
        <button
          className="btn-pay cash btn-primary"
          onClick={() => handleCheckout('cash')}
          disabled={basket.length === 0 || isProcessing}
        >
          <i className="fas fa-money-bill-wave" /> {t('pay_cash', 'Pay Cash')}
        </button>
      ) : null}
    </div>
  );

  const shopToolbar = (
    <div className="shop-toolbar">
      <button type="button" className="shop-help-chip" disabled={isProcessing} title={t('shop_help', 'Shop options')}>
        <i className="fas fa-question" />
      </button>
      <ShopSortButton
        label={t('name', 'Name')}
        icon="fa-sort-alpha-down"
        sortKey="name"
        activeSort={shopSort}
        direction={shopSortDirection}
        disabled={isProcessing}
        onClick={handleSortChange}
      />
      <ShopSortButton
        label={t('price', 'Price')}
        icon="fa-tag"
        sortKey="price"
        activeSort={shopSort}
        direction={shopSortDirection}
        disabled={isProcessing}
        onClick={handleSortChange}
      />
      <ShopSortButton
        label={t('available', 'Available')}
        icon="fa-list-check"
        sortKey="available"
        activeSort={shopSort}
        direction={shopSortDirection}
        disabled={isProcessing}
        onClick={handleSortChange}
      />
    </div>
  );

  if (isLoadout) {
    return (
      <>
        <div className="shop-stage">
          <div className="shop-stage-header">
            <div className="shop-stage-title-row">
              <p className="shop-stage-title">{right.label || t('shop', 'Shop')}</p>
              {right.maxWeight ? (
                <span className="shop-stage-weight">
                  <i className="fas fa-weight-hanging" /> {(rightWeight / 1000).toFixed(2)}/
                  {(right.maxWeight / 1000).toFixed(0)}kg
                </span>
              ) : null}
            </div>
            <div className="shop-header-options">
              {shopToolbar}
              <div className="shop-stage-search">
                <i className="fas fa-search" />
                <input
                  type="text"
                  placeholder={t('shop_search_placeholder', 'Search shop...')}
                  value={shopSearch}
                  onChange={(event) => setShopSearch(event.target.value)}
                  disabled={isProcessing}
                />
              </div>
            </div>
            <div className="shop-cats">
              {categories.map((category) => (
                <button
                  key={category}
                  className={`cat-pill ${shopCategory === category ? 'active' : ''}`}
                  onClick={() => setShopCategory(category)}
                  disabled={isProcessing}
                >
                  {renderCategoryLabel(category)}
                </button>
              ))}
            </div>
          </div>
          <div className="shop-card-grid">
            {filteredShopItems.length ? (
              filteredShopItems.map((entry) => (
                <ShopProductCard
                  key={`shop-card-${entry.slot}`}
                  entry={entry}
                  inventoryId={right.id}
                  disabled={isProcessing}
                  addLabel={t('shop_add_cart', 'Add to cart')}
                  onAdd={upsertBasketLine}
                />
              ))
            ) : (
              <div className="shop-empty-results">
                <i className="fas fa-magnifying-glass" />
                <span>{t('shop_no_results', 'No matching shop items')}</span>
              </div>
            )}
          </div>
        </div>
        <aside
          className={`shop-cart-panel${isBasketOver ? ' highlight-drop' : ''}`}
        >
          <div className="shop-cart-header">
            <div className="shop-cart-heading">
              <p>{t('shop_receipt', 'Receipt of Purchase')}</p>
              <span>
                {basketCount > 0
                  ? `${basketCount} ${t('shop_items_selected', 'items selected')}`
                  : t('shop_receipt_empty', 'Ready for your order')}
              </span>
            </div>
            <span className="cart-count">{String(basketCount).padStart(2, '0')}</span>
          </div>
          <div className="shop-cart-columns" aria-hidden="true">
            <span>{t('item', 'Item')}</span>
            <span>{t('quantity_short', 'Qty')}</span>
            <span>{t('total', 'Total')}</span>
          </div>
          {cartList}
          <div className="shop-cart-footer">
            <div className="receipt-summary">{cartTotals}</div>
            {payActions}
          </div>
        </aside>
      </>
    );
  }

  return (
    <aside className="shop-panel">
      <div className="inventory-header shop-inventory-header">
        <div className="header-content">
          <div className="inventory-title">
            <i className="inventory-badge">
              <img src={shopBadgeIcon} alt="Shop badge" />
            </i>
            <span>{right.label || t('shop', 'Shop')}</span>
          </div>
        </div>
        {right.maxWeight ? (
          <div className="weight-bar-wrapper">
            <i className="fas fa-weight-hanging" />
            <div className="weight-info">
              <span className="weight-text">
                {(rightWeight / 1000).toFixed(2)}/{(right.maxWeight / 1000).toFixed(0)}kg
              </span>
              <div className="weight-bar">
                <div
                  className={`weight-bar-fill ${rightWeightClass}`}
                  style={{ width: `${rightWeightPercent}%` }}
                />
              </div>
            </div>
          </div>
        ) : null}
      </div>

      <div className="shop-controls">
        <div className="shop-search">
          <i className="shop-control-icon fa-solid fa-magnifying-glass" />
          <input
            type="text"
            placeholder={t('shop_search_placeholder', 'Search shop...')}
            value={shopSearch}
            onChange={(event) => setShopSearch(event.target.value)}
            disabled={isProcessing}
          />
        </div>

        <div className="shop-qty-global" title={t('shop_qty_help', 'Quantity used for quick purchases')}>
          <label>{t('quantity_short', t('quantity', 'Qty'))}</label>
          <div className="qty-box">
            <button
              onClick={() => setShopQty((prev) => clampQty(prev - 1, selectedEntry?.count ?? 999))}
              disabled={isProcessing}
            >
              <i className="shop-control-icon fa-solid fa-minus" />
            </button>
            <input
              type="number"
              min={1}
              max={selectedEntry?.count ?? 999}
              value={shopQty}
              onChange={(event) =>
                setShopQty(clampQty(Number(event.target.value), selectedEntry?.count ?? 999))
              }
              disabled={isProcessing}
            />
            <button
              onClick={() => setShopQty((prev) => clampQty(prev + 1, selectedEntry?.count ?? 999))}
              disabled={isProcessing}
            >
              <i className="shop-control-icon fa-solid fa-plus" />
            </button>
          </div>
        </div>
      </div>

      <div className="shop-cats">
        {categories.map((category) => (
          <button
            key={category}
            className={`cat-pill ${shopCategory === category ? 'active' : ''}`}
            onClick={() => setShopCategory(category)}
            disabled={isProcessing}
          >
            {renderCategoryLabel(category)}
          </button>
        ))}
      </div>

      <div className="shop-grid">
        {filteredShopItems.map((entry) => {
          const isSelected = selectedSlot === entry.slot;
          return (
            <ShopItemCard
              key={`shop-${entry.slot}`}
              entry={entry}
              inventoryId={right.id}
              isSelected={isSelected}
              disabled={isProcessing}
              onSelect={() => handleSelect(entry.slot)}
              onDoubleClick={() => handleBuySelected()}
              onDragStart={handleDragStart}
              onDragEnd={handleDragEnd}
            />
          );
        })}
      </div>

      <div
        ref={basketDropRef}
        className={`cart-section basket-dock${isBasketOver ? ' highlight-drop' : ''}`}
      >
        <div className="cart-header">
          {t('shop_cart', 'Shopping Cart')}
          {basketCount > 0 ? <span className="cart-count">{basketCount}</span> : null}
        </div>
        <div className="cart-divider" />

        {basket.length === 0 ? (
          <div className="basket-empty">
            <i className="fas fa-hand-pointer" />
            <p>{t('shop_cart_help', 'Select items and use Add to Cart to build your order.')}</p>
          </div>
        ) : (
          <div className="cart-list basket-list">
            {basket.map((line, index) => (
              <div key={`basket-${line.slot}`} className="cart-item basket-item">
                <div className="cart-left">
                  <div className="cart-thumb">
                    {line.image ? <img src={line.image} alt={line.label} loading="lazy" decoding="async" draggable={false} onError={applyItemImageFallback} /> : null}
                  </div>
                  <div className="cart-meta">
                    <div className="cart-name">{line.label}</div>
                    <div className="cart-weight">
                      {(line.weight / 1000).toFixed(2)} {t('shop_weight_each', 'kg each')}
                    </div>
                  </div>
                </div>
                <div className="cart-right">
                  <div className="qty-box qty-inline">
                    <button
                      onClick={() => handleUpdateBasketQty(index, line.qty - 1)}
                      disabled={line.qty <= 1 || isProcessing}
                    >
                      <i className="shop-control-icon fa-solid fa-minus" />
                    </button>
                    <input
                      type="number"
                      min={1}
                      max={line.max}
                      value={line.qty}
                      onChange={(event) =>
                        handleUpdateBasketQty(index, Number(event.target.value))
                      }
                      disabled={isProcessing}
                    />
                    <button
                      onClick={() => handleUpdateBasketQty(index, line.qty + 1)}
                      disabled={line.qty >= line.max || isProcessing}
                    >
                      <i className="shop-control-icon fa-solid fa-plus" />
                    </button>
                  </div>

                  <div className="price-chip">
                    {formatPrice(line.price * line.qty, line.currency)}
                  </div>

                  <button
                    className="icon-btn danger btn-x"
                    title={t('remove', 'Remove')}
                    onClick={() => handleRemoveFromBasket(index)}
                    disabled={isProcessing}
                  >
                    <i className="shop-control-icon fa-solid fa-xmark" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        <div className="total-line">
          <span>{t('total_cost', 'Total cost')}</span>
          <strong>{formatPrice(Math.round(animatedCost))}</strong>
        </div>

        <div className="total-line">
          <span>{t('total_weight', 'Total weight')}</span>
          <strong>{(animatedWeight / 1000).toFixed(2)}kg</strong>
        </div>

        <div className="pay-actions">
          {canPayBank ? (
            <button
              className="btn-pay bank btn-outline"
              onClick={() => handleCheckout('bank')}
              disabled={basket.length === 0 || isProcessing}
            >
              <i className="fas fa-wallet" /> {t('pay_bank', 'Pay Bank')}
            </button>
          ) : null}
          {canPayDirty ? (
            <button
              className="btn-pay dirty btn-outline"
              onClick={() => handleCheckout('dirty')}
              disabled={basket.length === 0 || isProcessing}
            >
              <i className="fas fa-mask" /> {t('pay_dirty', 'Pay Dirty Money')}
            </button>
          ) : null}
          {canPayCash ? (
            <button
              className="btn-pay cash btn-primary"
              onClick={() => handleCheckout('cash')}
              disabled={basket.length === 0 || isProcessing}
            >
              <i className="fas fa-money-bill-wave" /> {t('pay_cash', 'Pay Cash')}
            </button>
          ) : null}
        </div>
      </div>
    </aside>
  );
};

export default ShopPanel;
