import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import { Combine, CombineRecipe } from '../../store/combine';
import { Items } from '../../store/items';
import { Locale } from '../../store/locale';
import { getItemUrl, isSlotWithItem, useCurrentTime } from '../../helpers';
import { applyItemImageFallback } from '../../helpers/itemImageFallback';
import { combineItem } from '../../thunks/combineItem';
import { fetchNui } from '../../utils/fetchNui';
import othersIcon from '../../assets/svg/others.svg';
import { Config } from '../../store/config';
import '../../styles/combine.scss';

const ALL_CATEGORY = '__all__';
const FAVORITES_KEY = 'ox_combine_favorites';
const QUEUE_LIMIT = 6;

const GRID_ORDER = [4, 1, 7, 3, 5, 0, 2, 6, 8];

type QueueEntry = {
  uid: number;
  recipeId: string;
  label: string;
  image?: string;
  count: number;
  duration: number;
  startedAt: number | null;
};

const loadFavorites = (): Set<string> => {
  try {
    const raw = localStorage.getItem(FAVORITES_KEY);
    return new Set(raw ? JSON.parse(raw) : []);
  } catch {
    return new Set();
  }
};

const recipeLabel = (recipe: CombineRecipe) =>
  recipe.label || Items[recipe.result]?.label || recipe.result;

// Owns its own tick so only this small bar re-renders while a combine is in
// progress, instead of the whole panel (recipe grid included).
const QueueProgress: React.FC<{ startedAt: number; duration: number; active: boolean }> = ({
  startedAt,
  duration,
  active,
}) => {
  const now = useCurrentTime(active ? 100 : 1000);
  const progress = Math.min(100, ((now - startedAt) / duration) * 100);
  return (
    <div className="combine-queue-progress">
      <span style={{ width: `${progress}%` }} />
    </div>
  );
};

const CombinePanel: React.FC<{ active?: boolean }> = ({ active = true }) => {
  const dispatch = useAppDispatch();
  const leftInventory = useAppSelector(selectLeftInventory);

  const t = (key: string, fallback: string) => {
    const value = Locale[key];
    return value && value !== key ? value : fallback;
  };

  const [search, setSearch] = useState('');
  const [category, setCategory] = useState<string>(ALL_CATEGORY);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [favorites, setFavorites] = useState<Set<string>>(loadFavorites);
  const [showFavoritesOnly, setShowFavoritesOnly] = useState(false);
  const [queue, setQueue] = useState<QueueEntry[]>([]);
  const uidRef = useRef(1);
  const processingRef = useRef(false);

  const ownedCounts = useMemo(() => {
    const map: Record<string, number> = {};
    for (const slot of leftInventory.items) {
      if (isSlotWithItem(slot) && typeof slot.count === 'number') {
        map[slot.name] = (map[slot.name] || 0) + slot.count;
      }
    }
    return map;
  }, [leftInventory.items]);

  const categories = useMemo(() => Combine.categories, []);
  const categoryLabels = useMemo(() => {
    const map: Record<string, string> = {};
    categories.forEach((c) => (map[c.id] = c.label));
    return map;
  }, [categories]);

  const toggleFavorite = (id: string) => {
    setFavorites((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      try {
        localStorage.setItem(FAVORITES_KEY, JSON.stringify([...next]));
      } catch {
      }
      return next;
    });
  };

  const filteredRecipes = useMemo(() => {
    const query = search.trim().toLowerCase();
    return Combine.recipes.filter((recipe) => {
      if (category !== ALL_CATEGORY && recipe.category !== category) return false;
      if (showFavoritesOnly && !favorites.has(recipe.id)) return false;
      if (!query) return true;
      return recipeLabel(recipe).toLowerCase().includes(query) || recipe.result.toLowerCase().includes(query);
    });
  }, [search, category, showFavoritesOnly, favorites]);

  const groupedRecipes = useMemo(() => {
    const groups: { id: string; label: string; recipes: CombineRecipe[] }[] = [];
    const order = categories.map((c) => c.id);
    const seen = new Set<string>();
    const sortFav = (a: CombineRecipe, b: CombineRecipe) =>
      Number(favorites.has(b.id)) - Number(favorites.has(a.id));

    order.forEach((id) => {
      seen.add(id);
      const recipes = filteredRecipes.filter((r) => r.category === id).sort(sortFav);
      if (recipes.length) groups.push({ id, label: categoryLabels[id] || id, recipes });
    });

    const leftover = filteredRecipes.filter((r) => !seen.has(r.category || 'other')).sort(sortFav);
    if (leftover.length) groups.push({ id: 'other', label: t('combine_other', 'Other'), recipes: leftover });

    return groups;
  }, [filteredRecipes, categories, categoryLabels, favorites]);

  const selectedRecipe = useMemo(
    () => Combine.recipes.find((r) => r.id === selectedId) || null,
    [selectedId]
  );

  useEffect(() => {
    if (!filteredRecipes.length) return;
    if (!selectedRecipe || !filteredRecipes.some((r) => r.id === selectedRecipe.id)) {
      setSelectedId(filteredRecipes[0].id);
    }
  }, [filteredRecipes, selectedRecipe]);

  const maxCombinable = useMemo(() => {
    if (!selectedRecipe) return 0;
    let max = Infinity;
    for (const ing of selectedRecipe.ingredients) {
      const need = ing.count || 1;
      if (need <= 0) continue;
      max = Math.min(max, Math.floor((ownedCounts[ing.item] || 0) / need));
    }
    return Number.isFinite(max) ? max : 0;
  }, [selectedRecipe, ownedCounts]);

  const canCombine = !!selectedRecipe && maxCombinable >= 1 && queue.length < QUEUE_LIMIT;

  const gridCells = useMemo<(string | null)[]>(() => {
    const cells: (string | null)[] = Array(9).fill(null);
    if (!selectedRecipe) return cells;

    if (selectedRecipe.layout && selectedRecipe.layout.length) {
      for (let i = 0; i < 9; i++) {
        const cell = selectedRecipe.layout[i];
        cells[i] = cell && typeof cell === 'string' ? cell : null;
      }
      return cells;
    }

    selectedRecipe.ingredients.forEach((ing, index) => {
      const pos = GRID_ORDER[index] ?? index;
      if (pos < 9) cells[pos] = ing.item;
    });
    return cells;
  }, [selectedRecipe]);

  const ingredientNeed = useMemo(() => {
    const map: Record<string, number> = {};
    selectedRecipe?.ingredients.forEach((ing) => (map[ing.item] = ing.count || 1));
    return map;
  }, [selectedRecipe]);

  const enqueue = () => {
    if (!selectedRecipe || !canCombine) return;
    setQueue((prev) => [
      ...prev,
      {
        uid: uidRef.current++,
        recipeId: selectedRecipe.id,
        label: recipeLabel(selectedRecipe),
        image: getItemUrl(selectedRecipe.result),
        count: 1,
        duration: selectedRecipe.duration && selectedRecipe.duration > 0 ? selectedRecipe.duration : 1500,
        startedAt: null,
      },
    ]);
  };

  const removeFromQueue = (uid: number) => {
    setQueue((prev) => prev.filter((q) => q.uid !== uid));
  };

  useEffect(() => {
    if (!queue.length || processingRef.current) return;
    const front = queue[0];

    if (front.startedAt === null) {
      setQueue((prev) => prev.map((q, i) => (i === 0 ? { ...q, startedAt: Date.now() } : q)));
      return;
    }

    const finish = () => {
      processingRef.current = true;
      dispatch(combineItem({ recipe: front.recipeId, count: front.count }))
        .unwrap()
        .catch(() => undefined)
        .finally(() => {
          setQueue((prev) => prev.filter((q) => q.uid !== front.uid));
          processingRef.current = false;
        });
    };

    // Scheduled once for the exact remaining duration instead of polling -
    // no re-render tied to a ticking clock is needed just to detect
    // completion; the progress bar's own tick is handled separately.
    const remaining = front.duration - (Date.now() - front.startedAt);
    if (remaining <= 0) {
      finish();
      return;
    }

    const timer = setTimeout(finish, remaining);
    return () => clearTimeout(timer);
  }, [queue, dispatch]);

  const isCombining = queue.length > 0;
  useEffect(() => {
    fetchNui('combineAnim', { active: isCombining }).catch(() => undefined);
  }, [isCombining]);

  useEffect(() => {
    return () => {
      fetchNui('combineAnimStop', {}).catch(() => undefined);
    };
  }, []);

  if (!Combine.enabled) return null;

  const isLoadout = Config.layout === 'loadout';
  const selectedTitle = selectedRecipe ? recipeLabel(selectedRecipe) : '';

  const renderCodexItem = (recipe: CombineRecipe) => {
    const isSelected = recipe.id === selectedId;
    const can = recipe.ingredients.every((ing) => (ownedCounts[ing.item] || 0) >= (ing.count || 1));
    const isFav = favorites.has(recipe.id);
    const count = recipe.count || 1;
    return (
      <div
        key={recipe.id}
        className={`combine-codex-item item-slot-border ${isSelected ? 'is-selected' : ''} ${can ? 'is-ready' : 'is-missing'}`}
        style={
          {
            '--borderColor': isSelected
              ? 'var(--color-slot-border-hover)'
              : can
                ? 'rgba(var(--color-primary-rgb), 0.4)'
                : 'var(--color-slot-border)',
          } as React.CSSProperties
        }
        onClick={() => setSelectedId(recipe.id)}
      >
        <button
          type="button"
          className={`combine-fav ${isFav ? 'is-active' : ''}`}
          onClick={(e) => {
            e.stopPropagation();
            toggleFavorite(recipe.id);
          }}
          title={t('combine_favorite', 'Favorite')}
        >
          <i className={isFav ? 'fa-solid fa-star' : 'fa-regular fa-star'} />
        </button>
        <div className="combine-codex-inner">
          <img
            className="combine-codex-img"
            src={getItemUrl(recipe.result)}
            alt={recipeLabel(recipe)}
            loading="lazy"
            decoding="async"
            draggable={false}
            onError={applyItemImageFallback}
          />
          {count > 1 && <span className="combine-codex-count">x{count}</span>}
          <p className="combine-codex-name">{recipeLabel(recipe)}</p>
        </div>
      </div>
    );
  };

  return (
    <>
      <div className="combine-stage">
        {selectedRecipe ? (
          <>
            <div className="combine-stage-title">{selectedTitle}</div>

            <div className="combine-input-grid">
              {gridCells.map((cell, i) => {
                if (!cell)
                  return (
                    <div
                      key={i}
                      className="combine-cell item-slot-border is-empty"
                      style={{ '--borderColor': 'var(--color-slot-border)' } as React.CSSProperties}
                    />
                  );
                const need = ingredientNeed[cell] || 1;
                const have = ownedCounts[cell] || 0;
                const ok = have >= need;
                return (
                  <div
                    key={i}
                    className="combine-cell item-slot-border"
                    style={{ '--borderColor': 'var(--color-slot-border)' } as React.CSSProperties}
                    title={Items[cell]?.label || cell}
                  >
                    {need > 1 ? <span className="combine-cell-mult">x{need}</span> : null}
                    <img
                      src={getItemUrl(cell)}
                      alt={cell}
                      loading="lazy"
                      decoding="async"
                      draggable={false}
                      onError={applyItemImageFallback}
                      style={{ opacity: ok ? 1 : 0.25 }}
                    />
                    <span className="combine-cell-have">{have}/{need}</span>
                  </div>
                );
              })}
            </div>

            <button type="button" className="combine-btn" onClick={enqueue} disabled={!canCombine}>
              {t('combine_action', 'Combine').toUpperCase()}
            </button>
          </>
        ) : (
          <div className="combine-stage-empty">
            <i className="fa-regular fa-square-plus" />
            <p>{t('combine_select', 'Select an item to combine').toUpperCase()}</p>
          </div>
        )}

        <div className="combine-queue">
          <div className="combine-queue-head">
            <i className="fa-solid fa-layer-group" /> {t('combine_queue', 'Crafting Queue').toUpperCase()}
          </div>
          <div className="combine-queue-strip">
            {Array.from({ length: Math.max(3, queue.length) }).map((_, i) => {
              const entry = queue[i];
              if (!entry) {
                return (
                  <div
                    key={`empty-${i}`}
                    className="combine-queue-card item-slot-border is-empty"
                    style={{ '--borderColor': 'var(--color-slot-border)' } as React.CSSProperties}
                  >
                    <i className="fa-solid fa-layer-group" />
                  </div>
                );
              }
              const isRunning = i === 0 && entry.startedAt !== null;
              return (
                <div
                  key={entry.uid}
                  className={`combine-queue-card item-slot-border ${isRunning ? 'is-active' : ''}`}
                  style={{ '--borderColor': 'var(--color-slot-border)' } as React.CSSProperties}
                >
                  <img src={entry.image} alt={entry.label} decoding="async" draggable={false} onError={applyItemImageFallback} />
                  <button type="button" className="combine-queue-remove" onClick={() => removeFromQueue(entry.uid)}>
                    <i className="fa-solid fa-xmark" />
                  </button>
                  <span className="combine-queue-name">{entry.label}</span>
                  {isRunning ? (
                    <QueueProgress startedAt={entry.startedAt as number} duration={entry.duration} active={active} />
                  ) : (
                    <div className="combine-queue-progress">
                      <span style={{ width: '0%' }} />
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </div>

      <div className="combine-codex-panel">
        <div className="inventory-panel-header combine-codex-head">
          <div className="inventory-panel-top">
            <div className="inventory-panel-main">
              <div className="inventory-title !gap-3 !text-[0.9375rem] !font-bold">
                <i className="inventory-badge">
                  <img src={othersIcon} alt="" />
                </i>
                <div className="inventory-title-copy">
                  <p className="inventory-title-name">{t('combine_codex', 'Combine Index')}</p>
                </div>
              </div>
            </div>
            <button
              type="button"
              className={`combine-codex-favbtn ${showFavoritesOnly ? 'is-active' : ''}`}
              onClick={() => setShowFavoritesOnly((v) => !v)}
              title={t('combine_favorites_only', 'Show favorites only')}
            >
              <i className={showFavoritesOnly ? 'fa-solid fa-star' : 'fa-regular fa-star'} />
            </button>
          </div>

          <div className="combine-codex-controls">
            {!isLoadout && (
              <select className="combine-filter-select" value={category} onChange={(e) => setCategory(e.target.value)}>
                <option value={ALL_CATEGORY}>{t('all', 'All')}</option>
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.label}
                  </option>
                ))}
              </select>
            )}
            {isLoadout && (
              <div className="combine-codex-cats">
                <button
                  type="button"
                  className={`codex-cat-plate ${category === ALL_CATEGORY ? 'is-active' : ''}`}
                  onClick={() => setCategory(ALL_CATEGORY)}
                >
                  {t('all', 'All')}
                </button>
                {categories.map((c) => (
                  <button
                    key={c.id}
                    type="button"
                    className={`codex-cat-plate ${category === c.id ? 'is-active' : ''}`}
                    onClick={() => setCategory(c.id)}
                  >
                    {c.label}
                  </button>
                ))}
              </div>
            )}
            <div className="inventory-search-dock combine-search-dock">
              <i className="fas fa-search" />
              <input
                type="text"
                className="inventory-search-input"
                value={search}
                placeholder={t('combine_search', 'Search...')}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
          </div>
        </div>

        <div className="inventory-header-divider" />

        {isLoadout && selectedRecipe && (
          <div className={`codex-blueprint ${maxCombinable >= 1 ? 'is-ready' : ''}`}>
            <div className="codex-blueprint-media">
              <img
                src={getItemUrl(selectedRecipe.result)}
                alt={selectedTitle}
                decoding="async"
                draggable={false}
                onError={applyItemImageFallback}
              />
            </div>
            <div className="codex-blueprint-info">
              <p className="codex-blueprint-name">{selectedTitle}</p>
              <div className="codex-blueprint-ings">
                {selectedRecipe.ingredients.map((ing) => {
                  const have = ownedCounts[ing.item] || 0;
                  const need = ing.count || 1;
                  return (
                    <span
                      key={ing.item}
                      className={`codex-blueprint-ing ${have >= need ? 'is-ok' : 'is-missing'}`}
                      title={Items[ing.item]?.label || ing.item}
                    >
                      <img src={getItemUrl(ing.item)} alt="" draggable={false} onError={applyItemImageFallback} />
                      {have}/{need}
                    </span>
                  );
                })}
              </div>
              <p className={`codex-blueprint-status ${maxCombinable >= 1 ? 'is-ready' : ''}`}>
                {(maxCombinable >= 1
                  ? t('combine_ready', 'Ready to combine')
                  : t('combine_missing', 'Missing materials')
                ).toUpperCase()}
              </p>
            </div>
          </div>
        )}

        <div className="combine-codex-list">
          {groupedRecipes.length === 0 ? (
            <p className="combine-codex-empty">{t('no_items_found', 'No items found').toUpperCase()}</p>
          ) : (
            groupedRecipes.map((group) => {
              const readyCount = group.recipes.filter((r) =>
                r.ingredients.every((ing) => (ownedCounts[ing.item] || 0) >= (ing.count || 1))
              ).length;
              return (
                <div key={group.id} className="combine-codex-group">
                  <p className="combine-codex-cat">
                    {group.label}
                    {isLoadout && (
                      <span className={`codex-cat-count ${readyCount > 0 ? 'has-ready' : ''}`}>
                        {readyCount}/{group.recipes.length}
                      </span>
                    )}
                  </p>
                  <div className="combine-codex-grid">{group.recipes.map(renderCodexItem)}</div>
                </div>
              );
            })
          )}
        </div>
      </div>
    </>
  );
};

export default CombinePanel;
