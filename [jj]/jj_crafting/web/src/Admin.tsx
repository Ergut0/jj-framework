import { useEffect, useMemo, useState } from 'react';
import { fetchNui, isBrowser, toList } from './nui';

export interface ItemOption {
  name: string;
  label: string;
  image: string;
}

interface BenchType {
  name: string;
  label: string;
  model?: string;
  spawnRange: number;
  slots: number;
  maxWeight: number;
  placementItem?: string;
  hideLocked: boolean;
  recipes: number;
}

interface AdminIngredient {
  name: string;
  amount: number;
  tool: boolean;
}

interface AdminRecipe {
  id?: number;
  type: string;
  item: string;
  ingredients: AdminIngredient[];
  duration: number;
  countMin: number;
  countMax: number;
  xpRequired: number;
  xpReward: number;
  blueprint?: string;
  sort: number;
}

interface AdminBlueprint {
  name: string;
  item: string;
  metadataKey?: string;
  metadataValue?: string;
  consume: number;
}

interface AdminPoint {
  name: string;
  type: string;
  label?: string;
  x: number;
  y: number;
  z: number;
  heading: number;
  anyGang: boolean;
  gangs: number[];
  groups: string[];
}

interface PlacedBench {
  id: string;
  number: number;
  type: string;
  label: string;
  owner?: string;
  x: number;
  y: number;
  z: number;
}

export interface AdminData {
  types: BenchType[];
  recipes: AdminRecipe[];
  blueprints: AdminBlueprint[];
  points: AdminPoint[];
  placed: PlacedBench[];
  settings: {
    xp: { enabled: boolean; hideLocked: boolean; defaultReward: number };
    packing: { enabled: boolean; confirmWithItems: boolean };
  };
  gangs: { id: number; label: string }[];
  jobs: { name: string; label: string }[];
}

type Tab = 'types' | 'recipes' | 'points' | 'blueprints' | 'placed' | 'settings';

const TABS: [Tab, string, string][] = [
  ['recipes', 'Recetas', 'fa-flask'],
  ['types', 'Tipos de mesa', 'fa-table'],
  ['points', 'Puntos de banda', 'fa-location-dot'],
  ['blueprints', 'Planos', 'fa-scroll'],
  ['placed', 'Mesas colocadas', 'fa-hammer'],
  ['settings', 'Ajustes', 'fa-sliders'],
];

export const normalizeAdmin = (data: AdminData): AdminData => ({
  ...data,
  types: toList(data.types),
  recipes: toList<AdminRecipe>(data.recipes).map((recipe) => ({ ...recipe, ingredients: toList(recipe.ingredients) })),
  blueprints: toList(data.blueprints),
  points: toList<AdminPoint>(data.points).map((point) => ({ ...point, gangs: toList(point.gangs), groups: toList(point.groups) })),
  placed: toList(data.placed),
  gangs: toList(data.gangs),
  jobs: toList(data.jobs),
});

// Envía un cambio al servidor. Devuelve la configuración nueva si se ha guardado
async function send(action: string, payload: object): Promise<AdminData | null> {
  if (isBrowser) return null;
  const result = await fetchNui<{ success: boolean; data?: AdminData }>('admin', { action, payload });
  return result?.success && result.data ? normalizeAdmin(result.data) : null;
}

function ItemPicker({ items, value, onChange, placeholder }: { items: ItemOption[]; value: string; onChange: (value: string) => void; placeholder?: string }) {
  const item = items.find((option) => option.name === value);
  return (
    <div className="picker">
      {item ? <img src={item.image} alt="" /> : <span className="picker-empty"><i className="fa-solid fa-cube" /></span>}
      <input className="input" list="jj-crafting-items" value={value} placeholder={placeholder ?? 'Nombre del objeto'} onChange={(event) => onChange(event.target.value.trim())} />
      <small className={item ? '' : 'picker-missing'}>{item ? item.label : value ? 'No existe' : ''}</small>
    </div>
  );
}

function Field({ label, children, hint }: { label: string; children: React.ReactNode; hint?: string }) {
  return (
    <label className="field">
      {label}
      {children}
      {hint && <small className="field-hint">{hint}</small>}
    </label>
  );
}

function Check({ label, checked, onChange, detail }: { label: string; checked: boolean; onChange: (value: boolean) => void; detail?: string }) {
  return (
    <button type="button" className={`permission ${checked ? 'permission-on' : ''}`} aria-pressed={checked} onClick={() => onChange(!checked)}>
      <i className={`fa-solid ${checked ? 'fa-square-check' : 'fa-square'}`} />
      <span>
        <strong>{label}</strong>
        {detail && <small>{detail}</small>}
      </span>
    </button>
  );
}

function ListPanel<T>({ items, selected, onSelect, render, keyOf, onNew, newLabel, search }: {
  items: T[];
  selected: string | null;
  onSelect: (key: string) => void;
  render: (item: T) => React.ReactNode;
  keyOf: (item: T) => string;
  onNew: () => void;
  newLabel: string;
  search?: (item: T) => string;
}) {
  const [query, setQuery] = useState('');
  const filtered = search ? items.filter((item) => search(item).toLowerCase().includes(query.trim().toLowerCase())) : items;
  return (
    <aside className="admin-list">
      {search && <input className="input" value={query} placeholder="Buscar" aria-label="Buscar" onChange={(event) => setQuery(event.target.value)} />}
      <div className="admin-list-items">
        {filtered.map((item) => (
          <button type="button" key={keyOf(item)} className={`role ${selected === keyOf(item) ? 'role-active' : ''}`} aria-pressed={selected === keyOf(item)} onClick={() => onSelect(keyOf(item))}>
            {render(item)}
          </button>
        ))}
        {filtered.length === 0 && <p className="empty">No hay nada.</p>}
      </div>
      <button type="button" className={`role role-new ${selected === null ? 'role-active' : ''}`} onClick={onNew}>
        <i className="fa-solid fa-plus" /> {newLabel}
      </button>
    </aside>
  );
}

// Recetas

const emptyRecipe = (type: string): AdminRecipe => ({ type, item: '', ingredients: [{ name: '', amount: 1, tool: false }], duration: 5, countMin: 1, countMax: 1, xpRequired: 0, xpReward: 0, blueprint: '', sort: 0 });

function RecipesTab({ data, items, onData }: { data: AdminData; items: ItemOption[]; onData: (data: AdminData) => void }) {
  const [type, setType] = useState(data.types[0]?.name ?? '');
  const recipes = data.recipes.filter((recipe) => recipe.type === type);
  const [selected, setSelected] = useState<string | null>(recipes[0] ? String(recipes[0].id) : null);
  const [draft, setDraft] = useState<AdminRecipe>(recipes[0] ?? emptyRecipe(type));
  const label = (name: string) => items.find((item) => item.name === name)?.label ?? name;

  useEffect(() => {
    const recipe = data.recipes.find((item) => String(item.id) === selected);
    setDraft(recipe ? { ...recipe, blueprint: recipe.blueprint ?? '', ingredients: recipe.ingredients.map((ingredient) => ({ ...ingredient })) } : emptyRecipe(type));
  }, [selected, data, type]);

  const changeType = (next: string) => {
    setType(next);
    const first = data.recipes.find((recipe) => recipe.type === next);
    setSelected(first ? String(first.id) : null);
  };

  const setIngredient = (index: number, change: Partial<AdminIngredient>) => {
    setDraft({ ...draft, ingredients: draft.ingredients.map((ingredient, i) => (i === index ? { ...ingredient, ...change } : ingredient)) });
  };

  const save = async () => {
    const next = await send('saveRecipe', { ...draft, type });
    if (next) {
      onData(next);
      if (!draft.id) {
        const created = next.recipes.filter((recipe) => recipe.type === type).reduce((max, recipe) => ((recipe.id ?? 0) > (max?.id ?? 0) ? recipe : max), undefined as AdminRecipe | undefined);
        if (created) setSelected(String(created.id));
      }
    }
  };

  return (
    <div className="admin-grid">
      <div className="admin-column">
        <select className="input select" aria-label="Tipo de mesa" value={type} onChange={(event) => changeType(event.target.value)}>
          {data.types.map((kind) => (
            <option key={kind.name} value={kind.name}>
              {kind.label}
            </option>
          ))}
        </select>
        <ListPanel
          items={recipes}
          selected={selected}
          onSelect={setSelected}
          keyOf={(recipe) => String(recipe.id)}
          render={(recipe) => (
            <>
              <span>{label(recipe.item)}</span>
              <small>
                {recipe.ingredients.length} materiales · {recipe.duration} s
              </small>
            </>
          )}
          search={(recipe) => label(recipe.item)}
          onNew={() => setSelected(null)}
          newLabel="Nueva receta"
        />
      </div>

      <section className="admin-form">
        <div className="form-grid">
          <Field label="Objeto que se fabrica">
            <ItemPicker items={items} value={draft.item} onChange={(item) => setDraft({ ...draft, item })} />
          </Field>
          <div className="form-row">
            <Field label="Salen (mínimo)">
              <input className="input" type="number" min={1} value={draft.countMin} onChange={(event) => setDraft({ ...draft, countMin: Number(event.target.value) })} />
            </Field>
            <Field label="Salen (máximo)">
              <input className="input" type="number" min={1} value={draft.countMax} onChange={(event) => setDraft({ ...draft, countMax: Number(event.target.value) })} />
            </Field>
            <Field label="Tiempo (s)">
              <input className="input" type="number" min={0.5} step={0.5} value={draft.duration} onChange={(event) => setDraft({ ...draft, duration: Number(event.target.value) })} />
            </Field>
          </div>
          <div className="form-row">
            <Field label="Experiencia necesaria">
              <input className="input" type="number" min={0} value={draft.xpRequired} onChange={(event) => setDraft({ ...draft, xpRequired: Number(event.target.value) })} />
            </Field>
            <Field label="Experiencia que da">
              <input className="input" type="number" min={0} value={draft.xpReward} onChange={(event) => setDraft({ ...draft, xpReward: Number(event.target.value) })} />
            </Field>
            <Field label="Orden">
              <input className="input" type="number" value={draft.sort} onChange={(event) => setDraft({ ...draft, sort: Number(event.target.value) })} />
            </Field>
          </div>
          <Field label="Plano necesario">
            <select className="input select" value={draft.blueprint ?? ''} onChange={(event) => setDraft({ ...draft, blueprint: event.target.value })}>
              <option value="">Ninguno</option>
              {data.blueprints.map((blueprint) => (
                <option key={blueprint.name} value={blueprint.name}>
                  {blueprint.name}
                </option>
              ))}
            </select>
          </Field>
        </div>

        <h3>Materiales</h3>
        <div className="ingredient-editor">
          {draft.ingredients.map((ingredient, index) => (
            <div key={index} className="ingredient-row">
              <ItemPicker items={items} value={ingredient.name} onChange={(name) => setIngredient(index, { name })} placeholder="Material" />
              <input className="input amount-input" type="number" min={1} max={ingredient.tool ? 100 : 10000} value={ingredient.amount} aria-label={ingredient.tool ? 'Desgaste en %' : 'Cantidad'} onChange={(event) => setIngredient(index, { amount: Number(event.target.value) })} />
              <button type="button" className={`toggle ${ingredient.tool ? 'toggle-on' : ''}`} aria-pressed={ingredient.tool} title="Una herramienta no se gasta entera: pierde ese porcentaje de durabilidad" onClick={() => setIngredient(index, { tool: !ingredient.tool, amount: ingredient.tool ? 1 : 5 })}>
                <i className="fa-solid fa-wrench" /> {ingredient.tool ? '% desgaste' : 'Unidades'}
              </button>
              <button type="button" className="icon-button icon-danger" aria-label="Quitar material" onClick={() => setDraft({ ...draft, ingredients: draft.ingredients.filter((_, i) => i !== index) })}>
                <i className="fa-solid fa-trash" />
              </button>
            </div>
          ))}
          <button type="button" className="role role-new" onClick={() => setDraft({ ...draft, ingredients: [...draft.ingredients, { name: '', amount: 1, tool: false }] })}>
            <i className="fa-solid fa-plus" /> Añadir material
          </button>
        </div>

        <div className="row-actions">
          <button type="button" className="action" disabled={!type} onClick={save}>
            {draft.id ? 'Guardar receta' : 'Crear receta'}
          </button>
          {draft.id && (
            <button type="button" className="action action-danger" onClick={async () => {
              const next = await send('deleteRecipe', { id: draft.id });
              if (next) {
                onData(next);
                setSelected(null);
              }
            }}>
              Borrar
            </button>
          )}
        </div>
      </section>
    </div>
  );
}

// Tipos de mesa

const emptyType = (): BenchType => ({ name: '', label: '', model: '', spawnRange: 50, slots: 30, maxWeight: 100000, placementItem: '', hideLocked: false, recipes: 0 });

function TypesTab({ data, items, onData }: { data: AdminData; items: ItemOption[]; onData: (data: AdminData) => void }) {
  const [selected, setSelected] = useState<string | null>(data.types[0]?.name ?? null);
  const [draft, setDraft] = useState<BenchType>(emptyType());
  const [placeable, setPlaceable] = useState(true);

  useEffect(() => {
    const kind = data.types.find((item) => item.name === selected);
    setDraft(kind ? { ...kind, model: kind.model ?? '', placementItem: kind.placementItem ?? '' } : emptyType());
    setPlaceable(kind ? Boolean(kind.placementItem) : true);
  }, [selected, data]);

  const save = async () => {
    const next = await send('saveType', { ...draft, placementItem: placeable ? draft.placementItem : '', model: placeable ? draft.model : '' });
    if (next) {
      onData(next);
      setSelected(draft.name);
    }
  };

  return (
    <div className="admin-grid">
      <ListPanel
        items={data.types}
        selected={selected}
        onSelect={setSelected}
        keyOf={(kind) => kind.name}
        render={(kind) => (
          <>
            <span>{kind.label}</span>
            <small>
              {kind.placementItem ? 'Se coloca' : 'Punto fijo'} · {kind.recipes} recetas
            </small>
          </>
        )}
        onNew={() => setSelected(null)}
        newLabel="Nuevo tipo"
      />

      <section className="admin-form">
        <div className="form-row">
          <Field label="Nombre interno" hint="Letras, números y _. No se puede cambiar.">
            <input className="input" value={draft.name} disabled={selected !== null} maxLength={32} onChange={(event) => setDraft({ ...draft, name: event.target.value })} />
          </Field>
          <Field label="Nombre visible">
            <input className="input" value={draft.label} maxLength={64} onChange={(event) => setDraft({ ...draft, label: event.target.value })} />
          </Field>
        </div>

        <div className="segments-row" role="group" aria-label="Cómo se usa">
          <button type="button" className={placeable ? 'segment-on' : ''} aria-pressed={placeable} onClick={() => setPlaceable(true)}>
            <i className="fa-solid fa-user" /> Civiles: se coloca con un objeto
          </button>
          <button type="button" className={!placeable ? 'segment-on' : ''} aria-pressed={!placeable} onClick={() => setPlaceable(false)}>
            <i className="fa-solid fa-location-dot" /> Bandas: punto fijo del mapa
          </button>
        </div>

        {placeable && (
          <div className="form-grid">
            <Field label="Objeto que la coloca">
              <ItemPicker items={items} value={draft.placementItem ?? ''} onChange={(placementItem) => setDraft({ ...draft, placementItem })} />
            </Field>
            <div className="form-row">
              <Field label="Modelo del objeto" hint="Nombre del prop de GTA, por ejemplo prop_tool_bench02">
                <input className="input" value={draft.model ?? ''} maxLength={64} onChange={(event) => setDraft({ ...draft, model: event.target.value })} />
              </Field>
              <Field label="Distancia de carga (m)">
                <input className="input" type="number" min={5} max={300} value={draft.spawnRange} onChange={(event) => setDraft({ ...draft, spawnRange: Number(event.target.value) })} />
              </Field>
            </div>
          </div>
        )}

        <div className="form-row">
          <Field label="Huecos del almacén">
            <input className="input" type="number" min={1} max={200} value={draft.slots} onChange={(event) => setDraft({ ...draft, slots: Number(event.target.value) })} />
          </Field>
          <Field label="Peso del almacén (kg)">
            <input className="input" type="number" min={1} value={draft.maxWeight / 1000} onChange={(event) => setDraft({ ...draft, maxWeight: Math.round(Number(event.target.value) * 1000) })} />
          </Field>
        </div>

        <Check label="Ocultar recetas sin experiencia" detail="Quien no tiene la experiencia no las ve" checked={draft.hideLocked} onChange={(hideLocked) => setDraft({ ...draft, hideLocked })} />

        <div className="row-actions">
          <button type="button" className="action" onClick={save}>
            {selected ? 'Guardar tipo' : 'Crear tipo'}
          </button>
          {selected && (
            <button type="button" className="action action-danger" onClick={async () => {
              const next = await send('deleteType', { name: selected });
              if (next) {
                onData(next);
                setSelected(next.types[0]?.name ?? null);
              }
            }}>
              Borrar
            </button>
          )}
        </div>
      </section>
    </div>
  );
}

// Puntos de banda

const emptyPoint = (type: string): AdminPoint => ({ name: '', type, label: '', x: 0, y: 0, z: 0, heading: 0, anyGang: false, gangs: [], groups: [] });

function PointsTab({ data, onData }: { data: AdminData; onData: (data: AdminData) => void }) {
  const pointTypes = data.types.filter((kind) => !kind.placementItem);
  const [selected, setSelected] = useState<string | null>(data.points[0]?.name ?? null);
  const [draft, setDraft] = useState<AdminPoint>(emptyPoint(pointTypes[0]?.name ?? ''));

  useEffect(() => {
    const point = data.points.find((item) => item.name === selected);
    setDraft(point ? { ...point, label: point.label ?? '' } : emptyPoint(pointTypes[0]?.name ?? data.types[0]?.name ?? ''));
  }, [selected, data]); // eslint-disable-line react-hooks/exhaustive-deps

  const toggle = <T,>(list: T[], value: T) => (list.includes(value) ? list.filter((item) => item !== value) : [...list, value]);

  const usePosition = async () => {
    const position = await fetchNui<{ x: number; y: number; z: number; heading: number }>('myPosition');
    if (position) setDraft({ ...draft, x: round(position.x), y: round(position.y), z: round(position.z), heading: round(position.heading) });
  };

  const save = async () => {
    const next = await send('savePoint', draft);
    if (next) {
      onData(next);
      setSelected(draft.name);
    }
  };

  const gangName = (id: number) => data.gangs.find((gang) => gang.id === id)?.label ?? `Banda ${id}`;

  return (
    <div className="admin-grid">
      <ListPanel
        items={data.points}
        selected={selected}
        onSelect={setSelected}
        keyOf={(point) => point.name}
        render={(point) => (
          <>
            <span>{point.label || point.name}</span>
            <small>{point.anyGang ? 'Cualquier banda' : point.gangs.length ? point.gangs.map(gangName).join(', ') : point.groups.length ? point.groups.join(', ') : 'Todo el mundo'}</small>
          </>
        )}
        onNew={() => setSelected(null)}
        newLabel="Nuevo punto"
      />

      <section className="admin-form">
        <div className="form-row">
          <Field label="Nombre interno" hint="Letras, números y _. Si lo cambias, el punto pierde su almacén.">
            <input className="input" value={draft.name} disabled={selected !== null} maxLength={32} onChange={(event) => setDraft({ ...draft, name: event.target.value })} />
          </Field>
          <Field label="Nombre visible" hint="Vacío para usar el del tipo">
            <input className="input" value={draft.label ?? ''} maxLength={64} onChange={(event) => setDraft({ ...draft, label: event.target.value })} />
          </Field>
        </div>
        <Field label="Tipo de mesa" hint="Sus recetas y su almacén">
          <select className="input select" value={draft.type} onChange={(event) => setDraft({ ...draft, type: event.target.value })}>
            {data.types.map((kind) => (
              <option key={kind.name} value={kind.name}>
                {kind.label}
                {kind.placementItem ? ' (se coloca)' : ''}
              </option>
            ))}
          </select>
        </Field>

        <div className="form-row coords-row">
          {(['x', 'y', 'z', 'heading'] as const).map((key) => (
            <Field key={key} label={key === 'heading' ? 'Rumbo' : key.toUpperCase()}>
              <input className="input" type="number" step={0.01} value={draft[key]} onChange={(event) => setDraft({ ...draft, [key]: Number(event.target.value) })} />
            </Field>
          ))}
          <button type="button" className="action action-ghost" onClick={usePosition} title="Copia tu posición de ahora">
            <i className="fa-solid fa-crosshairs" /> Mi posición
          </button>
        </div>

        <h3>Quién puede usarla</h3>
        <Check label="Cualquier banda" checked={draft.anyGang} onChange={(anyGang) => setDraft({ ...draft, anyGang })} />
        {!draft.anyGang && (
          <div className="chips">
            {data.gangs.length === 0 && <p className="empty">No hay bandas creadas en jj_gangs.</p>}
            {data.gangs.map((gang) => (
              <button type="button" key={gang.id} className={`chip-toggle ${draft.gangs.includes(gang.id) ? 'chip-on' : ''}`} aria-pressed={draft.gangs.includes(gang.id)} onClick={() => setDraft({ ...draft, gangs: toggle(draft.gangs, gang.id) })}>
                {gang.label}
              </button>
            ))}
          </div>
        )}
        <small className="field-hint">Trabajos (opcional)</small>
        <div className="chips">
          {data.jobs.map((job) => (
            <button type="button" key={job.name} className={`chip-toggle ${draft.groups.includes(job.name) ? 'chip-on' : ''}`} aria-pressed={draft.groups.includes(job.name)} onClick={() => setDraft({ ...draft, groups: toggle(draft.groups, job.name) })}>
              {job.label}
            </button>
          ))}
        </div>
        <p className="field-hint">Sin bandas ni trabajos marcados la puede usar todo el mundo.</p>

        <div className="row-actions">
          <button type="button" className="action" onClick={save}>
            {selected ? 'Guardar punto' : 'Crear punto'}
          </button>
          {selected && (
            <>
              <button type="button" className="action action-ghost" onClick={() => fetchNui('teleport', { x: draft.x, y: draft.y, z: draft.z })}>
                Ir
              </button>
              <button type="button" className="action action-danger" onClick={async () => {
                const next = await send('deletePoint', { name: selected });
                if (next) {
                  onData(next);
                  setSelected(next.points[0]?.name ?? null);
                }
              }}>
                Borrar
              </button>
            </>
          )}
        </div>
      </section>
    </div>
  );
}

const round = (value: number) => Math.round(value * 100) / 100;

// Planos

const emptyBlueprint = (): AdminBlueprint => ({ name: '', item: 'blueprint', metadataKey: 'blueprint', metadataValue: '', consume: 5 });

function BlueprintsTab({ data, items, onData }: { data: AdminData; items: ItemOption[]; onData: (data: AdminData) => void }) {
  const [selected, setSelected] = useState<string | null>(data.blueprints[0]?.name ?? null);
  const [draft, setDraft] = useState<AdminBlueprint>(emptyBlueprint());
  const [target, setTarget] = useState('');

  useEffect(() => {
    const blueprint = data.blueprints.find((item) => item.name === selected);
    setDraft(blueprint ? { ...blueprint, metadataKey: blueprint.metadataKey ?? '', metadataValue: blueprint.metadataValue ?? '' } : emptyBlueprint());
  }, [selected, data]);

  const save = async () => {
    const next = await send('saveBlueprint', draft);
    if (next) {
      onData(next);
      setSelected(draft.name);
    }
  };

  return (
    <div className="admin-grid">
      <ListPanel
        items={data.blueprints}
        selected={selected}
        onSelect={setSelected}
        keyOf={(blueprint) => blueprint.name}
        render={(blueprint) => (
          <>
            <span>{blueprint.name}</span>
            <small>{blueprint.consume > 0 ? `Gasta un ${blueprint.consume} % por uso` : 'No se gasta'}</small>
          </>
        )}
        onNew={() => setSelected(null)}
        newLabel="Nuevo plano"
      />

      <section className="admin-form">
        <Field label="Nombre interno" hint="Es el que eligen las recetas. Letras, números y _.">
          <input className="input" value={draft.name} disabled={selected !== null} maxLength={32} onChange={(event) => setDraft({ ...draft, name: event.target.value })} />
        </Field>
        <Field label="Objeto del plano">
          <ItemPicker items={items} value={draft.item} onChange={(item) => setDraft({ ...draft, item })} />
        </Field>
        <div className="form-row">
          <Field label="Clave en los datos del objeto" hint="Con blueprint, varios planos usan el mismo objeto">
            <input className="input" value={draft.metadataKey ?? ''} maxLength={32} onChange={(event) => setDraft({ ...draft, metadataKey: event.target.value })} />
          </Field>
          <Field label="Valor que lo distingue">
            <input className="input" value={draft.metadataValue ?? ''} maxLength={64} onChange={(event) => setDraft({ ...draft, metadataValue: event.target.value })} />
          </Field>
        </div>
        <Field label="Desgaste por uso (%)" hint="0 para que no se gaste nunca">
          <input className="input" type="number" min={0} max={100} step={0.5} value={draft.consume} onChange={(event) => setDraft({ ...draft, consume: Number(event.target.value) })} />
        </Field>

        <div className="row-actions">
          <button type="button" className="action" onClick={save}>
            {selected ? 'Guardar plano' : 'Crear plano'}
          </button>
          {selected && (
            <button type="button" className="action action-danger" onClick={async () => {
              const next = await send('deleteBlueprint', { name: selected });
              if (next) {
                onData(next);
                setSelected(next.blueprints[0]?.name ?? null);
              }
            }}>
              Borrar
            </button>
          )}
        </div>

        {selected && (
          <>
            <h3>Dar este plano</h3>
            <div className="form-row">
              <input className="input" inputMode="numeric" value={target} placeholder="Id del jugador" aria-label="Id del jugador" onChange={(event) => setTarget(event.target.value.replace(/\D/g, ''))} />
              <button type="button" className="action action-ghost" disabled={!target} onClick={() => send('giveBlueprint', { name: selected, target: Number(target) })}>
                Dar
              </button>
            </div>
          </>
        )}
      </section>
    </div>
  );
}

function PlacedTab({ data, onData }: { data: AdminData; onData: (data: AdminData) => void }) {
  return (
    <div className="admin-table">
      {data.placed.length === 0 && <p className="empty">No hay mesas colocadas.</p>}
      {data.placed.map((bench) => (
        <div key={bench.id} className="placed-row">
          <strong>#{bench.number}</strong>
          <span>{bench.label}</span>
          <small>{bench.owner ?? 'Sin dueño'}</small>
          <small>
            {Math.round(bench.x)}, {Math.round(bench.y)}, {Math.round(bench.z)}
          </small>
          <button type="button" className="action action-ghost" onClick={() => fetchNui('teleport', { x: bench.x, y: bench.y, z: bench.z })}>
            Ir
          </button>
          <button type="button" className="action action-danger" title="Lo que haya en su almacén queda en el suelo" onClick={async () => {
            const next = await send('removePlaced', { id: bench.id });
            if (next) onData(next);
          }}>
            Quitar
          </button>
        </div>
      ))}
    </div>
  );
}

function SettingsTab({ data, onData }: { data: AdminData; onData: (data: AdminData) => void }) {
  const [draft, setDraft] = useState(data.settings);

  useEffect(() => setDraft(data.settings), [data]);

  return (
    <section className="admin-form admin-settings">
      <h3>Experiencia</h3>
      <Check label="Experiencia activada" detail="Las recetas pueden pedir experiencia y la dan al fabricar" checked={draft.xp.enabled} onChange={(enabled) => setDraft({ ...draft, xp: { ...draft.xp, enabled } })} />
      <Check label="Ocultar recetas sin experiencia" detail="En todas las mesas" checked={draft.xp.hideLocked} onChange={(hideLocked) => setDraft({ ...draft, xp: { ...draft.xp, hideLocked } })} />
      <Field label="Experiencia por defecto al fabricar">
        <input className="input" type="number" min={0} value={draft.xp.defaultReward} onChange={(event) => setDraft({ ...draft, xp: { ...draft.xp, defaultReward: Number(event.target.value) } })} />
      </Field>

      <h3>Mesas de civiles</h3>
      <Check label="Se pueden recoger" detail="Vuelven a ser un objeto" checked={draft.packing.enabled} onChange={(enabled) => setDraft({ ...draft, packing: { ...draft.packing, enabled } })} />
      <Check label="Pedir confirmación si el almacén tiene cosas" detail="Al recogerla, lo que hay queda en el suelo" checked={draft.packing.confirmWithItems} onChange={(confirmWithItems) => setDraft({ ...draft, packing: { ...draft.packing, confirmWithItems } })} />

      <div className="row-actions">
        <button type="button" className="action" onClick={async () => {
          const next = await send('saveSettings', draft);
          if (next) onData(next);
        }}>
          Guardar ajustes
        </button>
      </div>
    </section>
  );
}

export function AdminView({ data, items, onData, onClose }: { data: AdminData; items: ItemOption[]; onData: (data: AdminData) => void; onClose: () => void }) {
  const [tab, setTab] = useState<Tab>('recipes');

  const datalist = useMemo(
    () => (
      <datalist id="jj-crafting-items">
        {items.map((item) => (
          <option key={item.name} value={item.name}>
            {item.label}
          </option>
        ))}
      </datalist>
    ),
    [items],
  );

  return (
    <div className="window window-admin">
      <header className="header">
        <img className="logo" src="./logo.webp" alt="Atlantis Roleplay" />
        <div className="title">
          <small>Administración</small>
          <h1>Crafteo</h1>
        </div>
        <nav className="tabs" aria-label="Secciones">
          {TABS.map(([id, label, icon]) => (
            <button type="button" key={id} className={`tab ${tab === id ? 'tab-active' : ''}`} aria-pressed={tab === id} onClick={() => setTab(id)}>
              <i className={`fa-solid ${icon}`} /> {label}
            </button>
          ))}
        </nav>
        <button type="button" className="icon-button" aria-label="Cerrar" onClick={onClose}>
          <i className="fa-solid fa-xmark" />
        </button>
      </header>
      {datalist}
      <div className="admin-body">
        {tab === 'recipes' && <RecipesTab data={data} items={items} onData={onData} />}
        {tab === 'types' && <TypesTab data={data} items={items} onData={onData} />}
        {tab === 'points' && <PointsTab data={data} onData={onData} />}
        {tab === 'blueprints' && <BlueprintsTab data={data} items={items} onData={onData} />}
        {tab === 'placed' && <PlacedTab data={data} onData={onData} />}
        {tab === 'settings' && <SettingsTab data={data} onData={onData} />}
      </div>
    </div>
  );
}

// Datos para ver el panel en el navegador
export const sampleItems: ItemOption[] = [
  ['scrapmetal', 'Chatarra'], ['WEAPON_HAMMER', 'Martillo'], ['lockpick', 'Ganzúa'], ['bandage', 'Venda'], ['radio', 'Radio'],
  ['armour', 'Chaleco antibalas'], ['weapon_pistol', 'Pistola'], ['bench_basic', 'Mesa básica'], ['blueprint', 'Plano'],
].map(([name, label]) => ({ name, label, image: `https://placehold.co/64x64/1b1131/c084fc?text=${encodeURIComponent(label.slice(0, 3))}` }));

export const sampleAdmin: AdminData = {
  types: [
    { name: 'basic', label: 'Mesa de crafteo básica', model: 'prop_tool_bench02', spawnRange: 35, slots: 30, maxWeight: 100000, placementItem: 'bench_basic', hideLocked: false, recipes: 2 },
    { name: 'gang', label: 'Mesa de la banda', spawnRange: 50, slots: 50, maxWeight: 200000, hideLocked: false, recipes: 1 },
  ],
  recipes: [
    { id: 1, type: 'basic', item: 'bandage', ingredients: [{ name: 'scrapmetal', amount: 2, tool: false }, { name: 'WEAPON_HAMMER', amount: 5, tool: true }], duration: 4, countMin: 1, countMax: 1, xpRequired: 0, xpReward: 3, sort: 1 },
    { id: 2, type: 'basic', item: 'radio', ingredients: [{ name: 'scrapmetal', amount: 6, tool: false }], duration: 5.5, countMin: 1, countMax: 1, xpRequired: 0, xpReward: 7, sort: 2 },
    { id: 3, type: 'gang', item: 'weapon_pistol', ingredients: [{ name: 'scrapmetal', amount: 30, tool: false }], duration: 60, countMin: 1, countMax: 1, xpRequired: 40, xpReward: 20, blueprint: 'weapon_pistol', sort: 1 },
  ],
  blueprints: [{ name: 'weapon_pistol', item: 'blueprint', metadataKey: 'blueprint', metadataValue: 'weapon_pistol', consume: 5 }],
  points: [{ name: 'tridentes', type: 'gang', label: 'Taller de Los Tridentes', x: -1155.92, y: -2005.34, z: 13.18, heading: 315, anyGang: false, gangs: [1], groups: [] }],
  placed: [{ id: 'placed:4', number: 4, type: 'basic', label: 'Mesa de crafteo básica', owner: 'JJ7K2M9QX', x: 213.4, y: -810.2, z: 30.7 }],
  settings: { xp: { enabled: true, hideLocked: true, defaultReward: 0 }, packing: { enabled: true, confirmWithItems: true } },
  gangs: [{ id: 1, label: 'Los Tridentes' }, { id: 2, label: 'Ballas' }],
  jobs: [{ name: 'police', label: 'Policía' }, { name: 'ambulance', label: 'EMS' }],
};
