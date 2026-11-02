import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Inventory, SlotWithItem, CraftSlot } from '../../typings';
import { Locale } from '../../store/locale';
import { applyItemImageFallback } from '../../helpers/itemImageFallback';
import { Items } from '../../store/items';
import othersIcon from '../../assets/svg/others.svg';
import {
  canCraftItem,
  getCraftItemCount,
  getItemCount,
  getItemUrl,
  isSlotWithItem,
  useCurrentTime,
} from '../../helpers';
import { useAppDispatch, useAppSelector } from '../../store';
import { craftItem } from '../../thunks/craftItem';
import { cancelCraft } from '../../thunks/cancelCraft';
import useNuiEvent from '../../hooks/useNuiEvent';
import InventorySlot from '../inventory/InventorySlot';
import Fade from '../utils/transitions/Fade';

type CraftingRecipe = SlotWithItem & {
  xp?: {
    required?: number;
    reward?: number;
  };
  blueprint?: string;
};

type QueueEntry = {
  recipeSlot: number;
  recipe?: string;
  duration?: number;
  craftCount?: number;
  startedAt?: number;
};

type CraftingInventory = Inventory & {
  index?: number;
  crafting?: {
    xp?: {
      enabled: boolean;
      current: number;
      hideLocked?: boolean;
    };
    blueprints?: Record<string, boolean>;
    blueprintLabels?: Record<string, string>;
    queue?: QueueEntry[];
  };
};

type CraftingPanelProps = {
  inventory: CraftingInventory;
  active?: boolean;
};

const getOutputCount = (value: SlotWithItem['count']) => {
  if (typeof value === 'number') return value;
  if (Array.isArray(value)) return value[0] ?? 1;
  return 1;
};

// Owns its own tick so only the running card (progress bar + countdown text)
// re-renders while crafting, instead of the whole panel (recipe grid, ingredient
// grid, search etc included).
const CraftingQueueCard: React.FC<{
  entry: CraftSlot;
  index: number;
  active: boolean;
  onRemove: () => void;
}> = ({ entry, index, active, onRemove }) => {
  const isActive = index === 0 && !!entry.startedAt;
  const duration = entry.duration ?? 3000;
  const now = useCurrentTime(active && isActive ? 250 : null);
  const started = entry.startedAt ?? now;
  const elapsed = isActive ? Math.min(now - started, duration) : 0;
  const progress = Math.min(100, (elapsed / duration) * 100);
  const remainingMs = Math.max(duration - elapsed, 0);
  const label = entry.metadata?.label ?? Items[entry.name]?.label ?? entry.name;
  const borderColor = isActive ? 'var(--color-slot-border-hover)' : 'var(--color-slot-border)';
  const queueState = isActive ? `${Math.max(remainingMs / 1000, 0).toFixed(1)}s` : (Locale.queue || 'Queue').toUpperCase();

  return (
    <div
      className={`crafting-queue-card item-slot-border ${isActive ? 'is-active' : ''}`}
      style={{ '--borderColor': borderColor } as React.CSSProperties}
    >
      <div className="crafting-queue-slot p-1.5 text-secondary text-xs relative w-full h-full">
        <img
          src={getItemUrl({ name: entry.name, metadata: entry.metadata } as SlotWithItem)}
          className="crafting-queue-image"
          alt={entry.name}
          loading="lazy"
          decoding="async"
          draggable={false}
          onError={applyItemImageFallback}
        />
        <p className="crafting-queue-count">{entry.craftCount > 1 ? `x${entry.craftCount}` : ''}</p>
        <p className="crafting-queue-state">{queueState}</p>
        <p className="crafting-queue-title">{label}</p>
        <button type="button" className="crafting-queue-remove" onClick={onRemove}>
          <i className="fa-solid fa-xmark" />
        </button>
        <div className="crafting-queue-progress-bar">
          <span style={{ width: `${progress}%` }} />
        </div>
      </div>
    </div>
  );
};

const CraftingPanel: React.FC<CraftingPanelProps> = ({ inventory, active = true }) => {
  const dispatch = useAppDispatch();
  const storageFromStore = useAppSelector((state) => state.inventory.leftInventory.backpack);
  const storageInventory = storageFromStore ?? inventory.storage;

  const recipes = useMemo(
    () => inventory.items.filter((slot): slot is CraftingRecipe => isSlotWithItem(slot)),
    [inventory.items]
  );

  const craftingInfo = inventory.crafting;
  const xpInfo = craftingInfo?.xp;
  const xpEnabled = xpInfo?.enabled ?? false;
  const playerXp = xpInfo?.current ?? 0;
  const hideLocked = xpInfo?.hideLocked ?? false;

  const formattedPlayerXp = useMemo(() => {
    if (typeof playerXp !== 'number' || !Number.isFinite(playerXp)) {
      return '0';
    }

    return Math.max(0, Math.floor(playerXp)).toLocaleString();
  }, [playerXp]);

  const [blueprintMap, setBlueprintMap] = useState<Record<string, boolean>>(craftingInfo?.blueprints ?? {});
  const blueprintLabels = craftingInfo?.blueprintLabels ?? {};

  const [search, setSearch] = useState('');
  const [selectedRecipe, setSelectedRecipe] = useState<CraftingRecipe | null>(null);
  const [countToCraft, setCountToCraft] = useState(1);
  const [craftQueue, setCraftQueue] = useState<CraftSlot[]>([]);
  const [queueStrip, setQueueStrip] = useState<HTMLDivElement | null>(null);

  const mapServerQueue = useCallback(
    (serverQueue?: QueueEntry[]) => {
      if (!serverQueue || !serverQueue.length) {
        return [] as CraftSlot[];
      }

      return serverQueue.map((entry) => {
        const recipeSlot = entry.recipeSlot;
        const recipe = inventory.items && inventory.items[recipeSlot - 1];
        const base = recipe && isSlotWithItem(recipe) ? recipe : ({} as SlotWithItem);
        const baseCraftCount = getOutputCount(base.count);

        return {
          slot: base.slot ?? recipeSlot,
          name: base.name ?? entry.recipe ?? '',
          count: base.count ?? 1,
          weight: base.weight ?? 0,
          durability: base.durability,
          price: base.price,
          currency: base.currency,
          ingredients: base.ingredients,
          duration: (entry.duration ? entry.duration * 1000 : base.duration) as any,
          metadata: base.metadata,
          craftCount: Math.max(1, entry.craftCount ?? baseCraftCount),
          startedAt: entry.startedAt ? entry.startedAt * 1000 : undefined,
        } as CraftSlot;
      });
    },
    [inventory.items]
  );

  useEffect(() => {
    const container = queueStrip;
    if (!container) return;

    const onWheel = (event: WheelEvent) => {
      if (Math.abs(event.deltaY) <= Math.abs(event.deltaX)) return;
      if (container.scrollWidth <= container.clientWidth) return;

      event.preventDefault();
      event.stopPropagation();
      container.scrollLeft += event.deltaY;
    };

    container.addEventListener('wheel', onWheel, { passive: false });

    return () => {
      container.removeEventListener('wheel', onWheel);
    };
  }, [queueStrip]);

  useEffect(() => {
    if (craftingInfo?.blueprints) {
      setBlueprintMap(craftingInfo.blueprints);
    }
  }, [craftingInfo?.blueprints]);

  useEffect(() => {
    setCraftQueue(mapServerQueue(craftingInfo?.queue));
  }, [craftingInfo?.queue, mapServerQueue]);

  useNuiEvent<any>('updateCraftQueue', (serverQueue) => {
    if (!Array.isArray(serverQueue)) {
      setCraftQueue([]);
      return;
    }

    setCraftQueue(mapServerQueue(serverQueue));
  });

  useNuiEvent<Record<string, boolean>>('updateBlueprints', (newBlueprints) => {
    setBlueprintMap(newBlueprints);
  });

  const getLockInfo = useCallback(
    (recipe: CraftingRecipe) => {
      const requiredXp = recipe.xp?.required ?? 0;
      const meetsXp = !xpEnabled || playerXp >= requiredXp;
      const blueprintKey = recipe.blueprint;
      const hasBlueprint = !blueprintKey || !!blueprintMap[blueprintKey];

      return {
        requiredXp,
        meetsXp,
        blueprintKey,
        hasBlueprint,
        locked: !(meetsXp && hasBlueprint),
      };
    },
    [xpEnabled, playerXp, blueprintMap]
  );

  const filteredRecipes = useMemo(() => {
    const query = search.trim().toLowerCase();

    return recipes.filter((recipe) => {
      const label = recipe.metadata?.label ?? Items[recipe.name]?.label ?? recipe.name;

      if (query && !label?.toLowerCase().includes(query)) {
        return false;
      }

      const locks = getLockInfo(recipe);
      if (hideLocked && !locks.hasBlueprint) {
        return false;
      }

      return true;
    });
  }, [recipes, search, hideLocked, getLockInfo]);

  useEffect(() => {
    if (!filteredRecipes.length) {
      setSelectedRecipe(null);
      return;
    }

    if (!selectedRecipe || !filteredRecipes.find((recipe) => recipe.slot === selectedRecipe.slot)) {
      setSelectedRecipe(filteredRecipes[0]);
      setCountToCraft(1);
    }
  }, [filteredRecipes, selectedRecipe]);

  const reservedIngredients = useMemo(() => {
    const map: Record<string, number> = {};

    craftQueue.forEach((entry) => {
      if (!entry.ingredients) return;

      Object.entries(entry.ingredients).forEach(([name, amount]) => {
        map[name] = (map[name] || 0) + amount * entry.craftCount;
      });
    });

    return map;
  }, [craftQueue]);

  const rawMaxCraftable = useMemo(() => {
    if (!selectedRecipe || !storageInventory) return 0;
    return getCraftItemCount(selectedRecipe, reservedIngredients, storageInventory);
  }, [selectedRecipe, reservedIngredients, storageInventory]);

  const maxCraftable = typeof rawMaxCraftable === 'number' ? rawMaxCraftable : Number.POSITIVE_INFINITY;

  useEffect(() => {
    if (!selectedRecipe || maxCraftable === 0) {
      setCountToCraft(1);
      return;
    }

    if (Number.isFinite(maxCraftable)) {
      setCountToCraft((prev) => Math.max(1, Math.min(prev, maxCraftable)));
    }
  }, [selectedRecipe, maxCraftable]);

  const selectedLockInfo = selectedRecipe ? getLockInfo(selectedRecipe) : null;

  const canQueueSelected =
    !!selectedRecipe &&
    !!storageInventory &&
    canCraftItem(selectedRecipe, inventory.type, reservedIngredients, storageInventory) &&
    maxCraftable !== 0 &&
    !selectedLockInfo?.locked;

  const formatDuration = useCallback((duration?: number) => {
    if (!duration || !Number.isFinite(duration)) return null;

    const totalSeconds = Math.max(1, Math.ceil(duration / 1000));

    if (totalSeconds < 60) {
      return `${totalSeconds}s`;
    }

    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;

    return seconds === 0 ? `${minutes}m` : `${minutes}m ${seconds}s`;
  }, []);

  const getRecipeVisualState = useCallback(
    (recipe: CraftingRecipe) => {
      const locks = getLockInfo(recipe);
      const hasIngredients =
        !!storageInventory && canCraftItem(recipe, inventory.type, reservedIngredients, storageInventory);

      if (locks.locked) {
        return {
          tone: 'locked' as const,
          label: Locale.locked || 'Locked',
        };
      }

      if (hasIngredients) {
        return {
          tone: 'ready' as const,
          label: Locale.ready || 'Ready',
        };
      }

      return {
        tone: 'missing' as const,
        label: Locale.not_enough || 'Missing',
      };
    },
    [getLockInfo, inventory.type, reservedIngredients, storageInventory]
  );

  const handleAdjustCount = (delta: number) => {
    setCountToCraft((prev) => {
      const next = prev + delta;
      if (next < 1) return 1;
      if (Number.isFinite(maxCraftable)) {
        return Math.min(next, maxCraftable);
      }
      return next;
    });
  };

  const handleCountInput = (value: string) => {
    const parsed = Number(value.replace(/\D/g, ''));

    if (!Number.isFinite(parsed) || parsed <= 0) {
      setCountToCraft(1);
      return;
    }

    if (Number.isFinite(maxCraftable)) {
      setCountToCraft(Math.min(parsed, maxCraftable));
    } else {
      setCountToCraft(parsed);
    }
  };

  const handleAddToQueue = () => {
    if (!selectedRecipe || !storageInventory || !canQueueSelected) return;

    const craftCount = Number.isFinite(maxCraftable)
      ? Math.min(countToCraft, maxCraftable || 1)
      : countToCraft;

    dispatch(
      craftItem({
        benchId: inventory.id,
        benchIndex: inventory.index,
        recipeSlot: selectedRecipe.slot,
        storageId: storageInventory.id,
        count: Math.max(1, craftCount),
      })
    );
  };

  const removeFromQueue = (index: number) => {
    dispatch(
      cancelCraft({
        benchId: inventory.id,
        jobIndex: index + 1,
      })
    );
  };

  const selectedLabel =
    selectedRecipe &&
    (selectedRecipe.metadata?.label ?? Items[selectedRecipe.name]?.label ?? selectedRecipe.name);

  const selectedDescription =
    selectedRecipe?.metadata?.description ??
    Items[selectedRecipe?.name || '']?.description;

  const selectedDurationLabel = selectedRecipe ? formatDuration(selectedRecipe.duration as number | undefined) : null;
  const selectedOutputCount = selectedRecipe ? getOutputCount(selectedRecipe.count) : 1;
  const selectedRecipeState = selectedRecipe ? getRecipeVisualState(selectedRecipe) : null;
  const selectedBlueprintLabel = selectedLockInfo?.blueprintKey
    ? blueprintLabels[selectedLockInfo.blueprintKey] ?? selectedLockInfo.blueprintKey
    : null;

  const ingredientEntries = useMemo(() => {
    if (!selectedRecipe?.ingredients) return [];
    return Object.entries(selectedRecipe.ingredients).sort(([, left], [, right]) => left - right);
  }, [selectedRecipe]);

  const maxLabel =
    rawMaxCraftable === 'infinity'
      ? 'INF'
      : typeof rawMaxCraftable === 'number'
        ? rawMaxCraftable.toLocaleString('en-US')
        : String(rawMaxCraftable || 0);

  const renderQueue = () => {
    if (!craftQueue.length) {
      return <p className="crafting-queue-empty">{Locale.queue_empty || 'The queue is empty.'}</p>;
    }

    return (
      <div ref={setQueueStrip} className="crafting-queue-strip">
        {craftQueue.map((entry, index) => (
          <CraftingQueueCard
            key={`${entry.slot}-${index}`}
            entry={entry}
            index={index}
            active={active}
            onRemove={() => removeFromQueue(index)}
          />
        ))}
      </div>
    );
  };

  const renderIngredientGrid = () => {
    if (!ingredientEntries.length) {
      return (
        <p className="crafting-no-ingredients">
          {(Locale.no_items_required || 'No items required').toUpperCase()}
        </p>
      );
    }

    return (
      <div className={`crafting-ingredient-grid ${ingredientEntries.length > 10 ? 'is-scrollable' : ''}`}>
        {ingredientEntries.map(([name, amount]) => {
          const reservedCount = reservedIngredients[name] || 0;
          const availableCount = storageInventory ? Math.max(getItemCount(name, storageInventory) - reservedCount, 0) : 0;
          const requiredTotal = amount * countToCraft;
          const hasEnough = availableCount >= requiredTotal;
          const label = Items[name]?.label ?? name;

          return (
            <div
              key={name}
              className={`crafting-slot crafting-ingredient-slot ${hasEnough ? 'is-ready' : 'is-missing'}`}
              data-active={hasEnough ? 'true' : 'false'}
              style={
                {
                  '--borderColor': hasEnough
                    ? 'rgba(var(--color-primary-rgb), 0.24)'
                    : 'var(--bdr)',
                } as React.CSSProperties
              }
            >
              <img src={getItemUrl(name)} alt={label} className="crafting-ingredient-image" loading="lazy" decoding="async" draggable={false} onError={applyItemImageFallback} />
              <span className="crafting-ingredient-count">
                {availableCount}/{requiredTotal}
              </span>
              <span className="crafting-ingredient-name">{label}</span>
            </div>
          );
        })}
      </div>
    );
  };

  const headerSection = (
    <>
      <div className="inventory-panel-header crafting-panel-header">
        <div className="inventory-panel-top">
          <div className="inventory-panel-main">
            <div className="inventory-title !gap-3 !text-[0.9375rem] !font-bold">
              <i className="inventory-badge">
                <img src={othersIcon} alt="" />
              </i>
              <div className="inventory-title-copy">
                <p className="inventory-title-name">{inventory.label || Locale.crafting_bench || 'Crafting Bench'}</p>
                {xpEnabled && (
                  <div className="inventory-title-weight crafting-panel-xp">
                    <i className="fa-solid fa-star" />
                    <span>{formattedPlayerXp} XP</span>
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
                value={search}
                placeholder={Locale.craft_search_placeholder || 'Search recipes...'}
                onChange={(event) => setSearch(event.target.value)}
              />
            </div>
          </div>
        </div>
      </div>
      <div className="inventory-header-divider" />
    </>
  );

  const recipeGridSection = (
    <div className="crafting-recipe-grid">
        {filteredRecipes.length === 0 ? (
          <p className="crafting-grid-empty">{(Locale.no_items_found || 'No items found').toUpperCase()}</p>
        ) : (
          filteredRecipes.map((recipe) => {
            const isSelected = selectedRecipe?.slot === recipe.slot;
            const lockInfo = getLockInfo(recipe);

            return (
              <div
                key={`${inventory.type}-${inventory.id}-${recipe.slot}`}
                className={`crafting-recipe-cell ${isSelected ? 'is-selected' : ''} ${lockInfo.locked ? 'is-locked' : ''}`}
              >
                <InventorySlot
                  item={recipe}
                  inventoryType={inventory.type}
                  inventoryGroups={inventory.groups}
                  inventoryId={inventory.id}
                  query={search}
                  isSelected={isSelected}
                  disableAvailabilityFilter
                  onClick={() => {
                    if (lockInfo.locked) return;
                    setSelectedRecipe(recipe);
                    setCountToCraft(1);
                  }}
                />
              </div>
            );
          })
        )}
      </div>
  );

  const focusSection = (
    <div className={`crafting-focus ${!selectedRecipe ? 'is-empty' : ''}`}>
        <Fade in={!selectedRecipe}>
          <div className="crafting-focus-empty">
            <p>{(Locale.select_item_to_craft || 'Select an item to craft').toUpperCase()}</p>
            <i className="fa-regular fa-square-plus" />
          </div>
        </Fade>

        <Fade in={!!selectedRecipe}>
          {selectedRecipe && (
            <div className="crafting-focus-body">
              <div className="crafting-focus-header">
                <div className="crafting-focus-copy">
                  <p className="crafting-focus-title">{selectedLabel}</p>
                  {selectedDescription && <p className="crafting-focus-description">{selectedDescription}</p>}
                </div>
                <div className="crafting-focus-output">
                  <span>{(Locale.quantity || 'Quantity').toUpperCase()}</span>
                  <strong>{selectedOutputCount}</strong>
                </div>
              </div>

              <div className="crafting-focus-meta">
                {selectedDurationLabel && (
                  <span className="crafting-meta-chip is-time">
                    {(Locale.crafting_time || 'Crafting Time').toUpperCase()}: {selectedDurationLabel}
                  </span>
                )}
                {selectedRecipeState && (
                  <span className={`crafting-meta-chip is-${selectedRecipeState.tone}`}>{selectedRecipeState.label}</span>
                )}
                <span className="crafting-meta-chip">{(Locale.craft_max || 'Max craftable').toUpperCase()}: {maxLabel}</span>
              </div>

              <p className="crafting-focus-label">{(Locale.item_required || 'Items required').toUpperCase()}</p>
              {renderIngredientGrid()}

              <div className="crafting-focus-requirements">
                {selectedBlueprintLabel && selectedLockInfo && (
                  <div className={`crafting-requirement-chip ${selectedLockInfo.hasBlueprint ? 'is-ready' : 'is-missing'}`}>
                    <i className="fa-solid fa-scroll" />
                    <span>{selectedBlueprintLabel}</span>
                  </div>
                )}
                {xpEnabled && selectedLockInfo?.requiredXp ? (
                  <div className={`crafting-requirement-chip ${selectedLockInfo.meetsXp ? 'is-ready' : 'is-missing'}`}>
                    <i className="fa-solid fa-star" />
                    <span>{(Locale.crafting_requires_xp || 'Requires %s XP').replace('%s', String(selectedLockInfo.requiredXp))}</span>
                  </div>
                ) : null}
              </div>

              <div className="crafting-focus-actions">
                <div className="crafting-quantity-panel">
                  <p>{(Locale.quantity || 'Quantity').toUpperCase()}</p>
                  <div className="crafting-quantity-input">
                    <button type="button" onClick={() => handleAdjustCount(-1)} disabled={countToCraft <= 1}>
                      <i className="fa-solid fa-minus" />
                    </button>
                    <input type="text" value={countToCraft} onChange={(event) => handleCountInput(event.target.value)} />
                    <button
                      type="button"
                      onClick={() => handleAdjustCount(1)}
                      disabled={Number.isFinite(maxCraftable) && countToCraft >= maxCraftable}
                    >
                      <i className="fa-solid fa-plus" />
                    </button>
                  </div>
                </div>

                <button type="button" className="crafting-submit" onClick={handleAddToQueue} disabled={!canQueueSelected}>
                  {(Locale.add_to_queue || 'Add to queue').toUpperCase()}
                </button>
              </div>
            </div>
          )}
        </Fade>
      </div>
  );

  const queueSection = (
    <div className={`crafting-queue-block ${craftQueue.length === 0 ? 'is-empty' : ''}`}>
      <p className="crafting-queue-label">{(Locale.queue || 'Queue').toUpperCase()}</p>
      {renderQueue()}
    </div>
  );

  return (
    <div className="crafting-panel">
      {headerSection}
      {recipeGridSection}
      <div className="crafting-divider" />
      {focusSection}
      <div className="crafting-divider" />
      {queueSection}
    </div>
  );
};

export default CraftingPanel;
