import { useCallback, useEffect, useMemo, useState } from 'react';
import { AdminView, normalizeAdmin, sampleAdmin, sampleItems, type AdminData, type ItemOption } from './Admin';
import { fetchNui, isBrowser, sampleBench, sampleManage, toList, type BenchData, type Ingredient, type Job, type ManageData, type Recipe, type Role } from './nui';

type View = 'craft' | 'manage' | 'admin' | null;

const MAX_AMOUNT = 10;

const kilos = (grams: number) => `${(grams / 1000).toLocaleString('es-ES', { maximumFractionDigits: 1 })} kg`;

const seconds = (value: number) => {
  if (value < 60) return `${Math.ceil(value)} s`;
  const minutes = Math.floor(value / 60);
  const rest = Math.ceil(value % 60);
  return rest ? `${minutes} min ${rest} s` : `${minutes} min`;
};

const outputCount = (count: Recipe['count']) => (Array.isArray(count) ? `${count[0]}-${count[1]}` : String(count));

const ingredientOk = (ingredient: Ingredient) => ingredient.have >= ingredient.needs;

// Motivo por el que no se puede fabricar, o null si se puede
const blocker = (recipe: Recipe, xp: BenchData['xp']) => {
  if (xp.enabled && xp.current < recipe.xpRequired) return `Necesitas ${recipe.xpRequired} de experiencia`;
  if (recipe.blueprint && recipe.blueprint.uses === 0) return 'Falta el plano en el almacén';
  const missing = toList<Ingredient>(recipe.ingredients).find((ingredient) => !ingredientOk(ingredient));
  if (missing) return `Falta ${missing.label} en el almacén`;
  return null;
};

const normalizeBench = (data: BenchData): BenchData => ({
  ...data,
  recipes: toList<Recipe>(data.recipes).map((recipe) => ({ ...recipe, ingredients: toList<Ingredient>(recipe.ingredients) })),
  queue: toList<Job>(data.queue),
});

const normalizeManage = (data: ManageData): ManageData => ({
  ...data,
  roles: toList<Role>(data.roles).map((role) => ({ ...role, members: toList(role.members) })),
  nearby: toList(data.nearby),
});

function Header({ title, subtitle, onClose, children }: { title: string; subtitle: string; onClose: () => void; children?: React.ReactNode }) {
  return (
    <header className="header">
      <img className="logo" src="./logo.webp" alt="Atlantis Roleplay" />
      <div className="title">
        <small>{subtitle}</small>
        <h1>{title}</h1>
      </div>
      <div className="header-extra">{children}</div>
      <button type="button" className="icon-button" aria-label="Cerrar" onClick={onClose}>
        <i className="fa-solid fa-xmark" />
      </button>
    </header>
  );
}

function Queue({ queue, receivedAt, onCancel }: { queue: Job[]; receivedAt: number; onCancel: (id: number) => void }) {
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    if (queue.length === 0) return;
    const timer = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(timer);
  }, [queue.length]);

  return (
    <section className="queue">
      <h2>
        Cola <small>{queue.length}</small>
      </h2>
      {queue.length === 0 ? (
        <p className="empty">Nada en marcha.</p>
      ) : (
        <div className="queue-list">
          {queue.map((job) => {
            const remaining = job.remaining !== undefined ? Math.max(0, job.remaining - (now - receivedAt) / 1000) : undefined;
            const progress = remaining !== undefined ? 1 - remaining / job.duration : 0;
            return (
              <div key={job.id} className={`job ${remaining !== undefined ? 'job-active' : ''}`}>
                <img src={job.image} alt="" />
                <div className="job-info">
                  <strong>
                    {job.label} <small>x{job.count}</small>
                  </strong>
                  <div className="bar">
                    <div style={{ width: `${Math.min(100, progress * 100)}%` }} />
                  </div>
                  <small>{remaining !== undefined ? `Quedan ${seconds(remaining)}` : `En espera · ${seconds(job.duration)}`}</small>
                </div>
                <button type="button" className="icon-button icon-danger" aria-label={`Cancelar ${job.label}`} title="Cancelar y devolver los materiales" onClick={() => onCancel(job.id)}>
                  <i className="fa-solid fa-xmark" />
                </button>
              </div>
            );
          })}
        </div>
      )}
    </section>
  );
}

function CraftView({ data, receivedAt, onData, onClose }: { data: BenchData; receivedAt: number; onData: (data: BenchData) => void; onClose: () => void }) {
  const [selected, setSelected] = useState(data.recipes[0]?.slot ?? 0);
  const [search, setSearch] = useState('');
  const [onlyReady, setOnlyReady] = useState(false);
  const [amount, setAmount] = useState(1);
  const [busy, setBusy] = useState(false);

  const query = search.trim().toLowerCase();
  const recipes = data.recipes.filter((recipe) => recipe.label.toLowerCase().includes(query) && (!onlyReady || !blocker(recipe, data.xp)));
  const recipe = data.recipes.find((item) => item.slot === selected) ?? recipes[0];
  const reason = recipe ? blocker(recipe, data.xp) : null;
  const queueRoom = MAX_AMOUNT - data.queue.length;

  useEffect(() => setAmount(1), [selected]);

  const craft = async () => {
    if (!recipe || reason || busy) return;
    setBusy(true);
    const result = await fetchNui<{ success: boolean; data?: BenchData }>('craft', { slot: recipe.slot, amount });
    setBusy(false);
    if (result?.data) onData(result.data);
    if (isBrowser) {
      onData({ ...data, queue: [...data.queue, { id: Date.now(), name: recipe.name, label: recipe.label, image: recipe.image, count: Number(recipe.count) || 1, duration: recipe.duration }] });
    }
  };

  const cancel = async (id: number) => {
    const result = await fetchNui<{ success: boolean; data?: BenchData }>('cancel', { id });
    if (result?.data) onData(result.data);
    if (isBrowser) onData({ ...data, queue: data.queue.filter((job) => job.id !== id) });
  };

  const weight = data.storage.maxWeight > 0 ? data.storage.weight / data.storage.maxWeight : 0;

  return (
    <div className="window window-craft">
      <Header title={data.label} subtitle="Mesa de crafteo" onClose={onClose}>
        {data.xp.enabled && (
          <span className="chip" title="Experiencia de crafteo">
            <i className="fa-solid fa-star" /> {data.xp.current} XP
          </span>
        )}
        <button type="button" className="storage" onClick={() => fetchNui('openStorage')} title="Los materiales, los planos y lo fabricado están en el almacén de la mesa">
          <i className="fa-solid fa-box-open" />
          <span>
            Almacén
            <span className="bar bar-small">
              <span style={{ width: `${Math.min(100, weight * 100)}%` }} />
            </span>
          </span>
          <small>
            {kilos(data.storage.weight)} / {kilos(data.storage.maxWeight)}
          </small>
        </button>
      </Header>

      <div className="craft-body">
        <section className="recipes">
          <div className="recipe-tools">
            <input className="input" value={search} placeholder="Buscar receta" aria-label="Buscar receta" onChange={(event) => setSearch(event.target.value)} />
            <button type="button" className={`toggle ${onlyReady ? 'toggle-on' : ''}`} aria-pressed={onlyReady} onClick={() => setOnlyReady(!onlyReady)}>
              <i className="fa-solid fa-check" /> Disponibles
            </button>
          </div>
          <div className="recipe-grid">
            {recipes.map((item) => {
              const locked = blocker(item, data.xp);
              return (
                <button type="button" key={item.slot} className={`recipe ${recipe?.slot === item.slot ? 'recipe-active' : ''} ${locked ? 'recipe-locked' : ''}`} aria-pressed={recipe?.slot === item.slot} onClick={() => setSelected(item.slot)}>
                  <img src={item.image} alt="" />
                  <span>{item.label}</span>
                  {data.xp.enabled && data.xp.current < item.xpRequired && (
                    <small className="lock">
                      <i className="fa-solid fa-lock" /> {item.xpRequired}
                    </small>
                  )}
                </button>
              );
            })}
            {recipes.length === 0 && <p className="empty">Ninguna receta coincide.</p>}
          </div>
        </section>

        <section className="detail">
          {recipe ? (
            <>
              <div className="detail-head">
                <img src={recipe.image} alt="" />
                <div>
                  <h2>{recipe.label}</h2>
                  <p className="meta">
                    <span>
                      <i className="fa-solid fa-cube" /> x{outputCount(recipe.count)}
                    </span>
                    <span>
                      <i className="fa-solid fa-clock" /> {seconds(recipe.duration)}
                    </span>
                    {data.xp.enabled && recipe.xpReward > 0 && (
                      <span>
                        <i className="fa-solid fa-star" /> +{recipe.xpReward} XP
                      </span>
                    )}
                  </p>
                  {recipe.description && <p className="description">{recipe.description}</p>}
                </div>
              </div>

              <h3>Materiales del almacén</h3>
              <div className="ingredients">
                {recipe.ingredients.map((ingredient) => (
                  <div key={ingredient.name} className={`ingredient ${ingredientOk(ingredient) ? '' : 'ingredient-missing'}`}>
                    <img src={ingredient.image} alt="" />
                    <span className="ingredient-name">
                      {ingredient.label}
                      {ingredient.tool && <small>Herramienta · gasta un {ingredient.needs} %</small>}
                    </span>
                    <span className="ingredient-count">{ingredient.tool ? `${ingredient.have} %` : `${ingredient.have} / ${ingredient.needs * amount}`}</span>
                  </div>
                ))}
                {recipe.blueprint && (
                  <div className={`ingredient ${recipe.blueprint.uses === 0 ? 'ingredient-missing' : ''}`}>
                    <span className="ingredient-icon">
                      <i className="fa-solid fa-scroll" />
                    </span>
                    <span className="ingredient-name">
                      Plano
                      <small>Tiene que estar en el almacén</small>
                    </span>
                    <span className="ingredient-count">{recipe.blueprint.uses === 0 ? 'Falta' : recipe.blueprint.uses < 0 ? 'Sin límite' : `${recipe.blueprint.uses} usos`}</span>
                  </div>
                )}
                {data.xp.enabled && recipe.xpRequired > 0 && (
                  <div className={`ingredient ${data.xp.current < recipe.xpRequired ? 'ingredient-missing' : ''}`}>
                    <span className="ingredient-icon">
                      <i className="fa-solid fa-star" />
                    </span>
                    <span className="ingredient-name">Experiencia</span>
                    <span className="ingredient-count">
                      {data.xp.current} / {recipe.xpRequired}
                    </span>
                  </div>
                )}
              </div>

              <div className="craft-actions">
                <div className="amount" role="group" aria-label="Cantidad">
                  <button type="button" aria-label="Menos" disabled={amount <= 1} onClick={() => setAmount(amount - 1)}>
                    <i className="fa-solid fa-minus" />
                  </button>
                  <span>{amount}</span>
                  <button type="button" aria-label="Más" disabled={amount >= Math.max(1, queueRoom)} onClick={() => setAmount(amount + 1)}>
                    <i className="fa-solid fa-plus" />
                  </button>
                </div>
                <button type="button" className="action" disabled={Boolean(reason) || busy || queueRoom <= 0} onClick={craft}>
                  <i className="fa-solid fa-hammer" /> Fabricar
                </button>
              </div>
              <p className="hint">{queueRoom <= 0 ? 'La cola está llena' : reason ?? 'Lo fabricado aparece en el almacén de la mesa.'}</p>
            </>
          ) : (
            <p className="empty">Esta mesa no tiene recetas.</p>
          )}
        </section>

        <Queue queue={data.queue} receivedAt={receivedAt} onCancel={cancel} />
      </div>
    </div>
  );
}

const PERMISSIONS: [keyof Pick<Role, 'canUse' | 'canMove' | 'canPack' | 'canManage'>, string, string][] = [
  ['canUse', 'Usar', 'Fabricar y abrir el almacén'],
  ['canMove', 'Mover', 'Cambiar la mesa de sitio'],
  ['canPack', 'Recoger', 'Guardarla como objeto'],
  ['canManage', 'Gestionar', 'Roles y miembros'],
];

function ManageView({ data, onData, onClose }: { data: ManageData; onData: (data: ManageData) => void; onClose: () => void }) {
  const [selected, setSelected] = useState<number | 'new'>(data.roles[0]?.id ?? 'new');
  const role = data.roles.find((item) => item.id === selected);
  const [draft, setDraft] = useState({ name: '', canUse: true, canMove: false, canPack: false, canManage: false });
  const [transferTo, setTransferTo] = useState<number | ''>('');

  useEffect(() => {
    if (role) setDraft({ name: role.name, canUse: role.canUse, canMove: role.canMove, canPack: role.canPack, canManage: role.canManage });
    else setDraft({ name: '', canUse: true, canMove: false, canPack: false, canManage: false });
  }, [role, selected]);

  const call = async (name: string, payload: object) => {
    const result = await fetchNui<{ success: boolean; data?: ManageData }>(name, payload);
    if (result?.data) {
      const next = normalizeManage(result.data);
      onData(next);
      return next;
    }
  };

  const permissions = { use: draft.canUse, move: draft.canMove, pack: draft.canPack, manage: draft.canManage };

  const save = async () => {
    if (selected === 'new') {
      const next = await call('createRole', { name: draft.name, permissions });
      if (next) setSelected(next.roles[next.roles.length - 1]?.id ?? 'new');
    } else {
      await call('updateRole', { roleId: selected, name: draft.name, permissions });
    }
  };

  const changed = role ? role.name !== draft.name || PERMISSIONS.some(([key]) => role[key] !== draft[key]) : true;

  return (
    <div className="window window-manage">
      <Header title={data.label} subtitle={`Dueño: ${data.owner}`} onClose={onClose} />

      <div className="manage-body">
        <aside className="roles">
          <h2>Roles</h2>
          {data.roles.map((item) => (
            <button type="button" key={item.id} className={`role ${selected === item.id ? 'role-active' : ''}`} aria-pressed={selected === item.id} onClick={() => setSelected(item.id)}>
              <span>{item.name}</span>
              <small>
                {item.members.length} {item.members.length === 1 ? 'persona' : 'personas'}
              </small>
            </button>
          ))}
          <button type="button" className={`role role-new ${selected === 'new' ? 'role-active' : ''}`} onClick={() => setSelected('new')}>
            <i className="fa-solid fa-plus" /> Nuevo rol
          </button>
        </aside>

        <section className="role-editor">
          <label className="field">
            Nombre del rol
            <input className="input" value={draft.name} maxLength={32} placeholder="Por ejemplo: Aprendiz" onChange={(event) => setDraft({ ...draft, name: event.target.value })} />
          </label>

          <div className="permissions">
            {PERMISSIONS.map(([key, label, detail]) => (
              <button type="button" key={key} className={`permission ${draft[key] ? 'permission-on' : ''}`} aria-pressed={draft[key]} onClick={() => setDraft({ ...draft, [key]: !draft[key] })}>
                <i className={`fa-solid ${draft[key] ? 'fa-square-check' : 'fa-square'}`} />
                <span>
                  <strong>{label}</strong>
                  <small>{detail}</small>
                </span>
              </button>
            ))}
          </div>

          <div className="row-actions">
            <button type="button" className="action" disabled={!changed} onClick={save}>
              {selected === 'new' ? 'Crear rol' : 'Guardar cambios'}
            </button>
            {role && (
              <button type="button" className="action action-danger" disabled={role.members.length > 0} title={role.members.length > 0 ? 'Quita antes a sus miembros' : undefined} onClick={async () => {
                const next = await call('deleteRole', { roleId: role.id });
                if (next) setSelected(next.roles[0]?.id ?? 'new');
              }}>
                Borrar
              </button>
            )}
          </div>

          {role && (
            <>
              <h3>Miembros</h3>
              <div className="members">
                {role.members.length === 0 && <p className="empty">Nadie tiene este rol.</p>}
                {role.members.map((member) => (
                  <div key={member.identifier} className="member">
                    <span className={`dot ${member.online ? 'dot-on' : ''}`} />
                    <span className="member-name">{member.name}</span>
                    <button type="button" className="icon-button icon-danger" aria-label={`Quitar a ${member.name}`} onClick={() => call('setMember', { identifier: member.identifier, roleId: null })}>
                      <i className="fa-solid fa-user-minus" />
                    </button>
                  </div>
                ))}
              </div>
            </>
          )}
        </section>

        <aside className="nearby">
          <h2>Gente cerca</h2>
          {data.nearby.length === 0 && <p className="empty">No hay nadie cerca de la mesa.</p>}
          {data.nearby.map((player) => (
            <div key={player.id} className="near">
              <span className="member-name">
                {player.name} <small>#{player.id}</small>
              </span>
              <select className="input select" aria-label={`Rol de ${player.name}`} value={player.roleId ?? ''} onChange={(event) => call('setMember', { target: player.id, roleId: event.target.value === '' ? null : Number(event.target.value) })}>
                <option value="">Sin acceso</option>
                {data.roles.map((item) => (
                  <option key={item.id} value={item.id}>
                    {item.name}
                  </option>
                ))}
              </select>
            </div>
          ))}

          {data.isOwner && data.nearby.length > 0 && (
            <div className="transfer">
              <h3>Regalar la mesa</h3>
              <select className="input select" aria-label="Nuevo dueño" value={transferTo} onChange={(event) => setTransferTo(event.target.value === '' ? '' : Number(event.target.value))}>
                <option value="">Elige a alguien</option>
                {data.nearby.map((player) => (
                  <option key={player.id} value={player.id}>
                    {player.name}
                  </option>
                ))}
              </select>
              <button type="button" className="action action-danger" disabled={transferTo === ''} onClick={() => call('transfer', { target: transferTo })}>
                Dársela
              </button>
            </div>
          )}
        </aside>
      </div>
    </div>
  );
}

export function App() {
  const [view, setView] = useState<View>(isBrowser ? 'craft' : null);
  const [bench, setBench] = useState<BenchData | null>(isBrowser ? sampleBench : null);
  const [manage, setManage] = useState<ManageData | null>(isBrowser ? sampleManage : null);
  const [receivedAt, setReceivedAt] = useState(Date.now());
  const [admin, setAdmin] = useState<AdminData | null>(isBrowser ? sampleAdmin : null);
  const [items, setItems] = useState<ItemOption[]>(isBrowser ? sampleItems : []);

  const close = useCallback(() => {
    setView(null);
    fetchNui('close');
  }, []);

  const updateBench = useCallback((data: BenchData) => {
    setBench(normalizeBench(data));
    setReceivedAt(Date.now());
  }, []);

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const message = event.data;
      if (message.action === 'open') {
        if (message.view === 'craft') updateBench(message.data);
        else if (message.view === 'admin') {
          setAdmin(normalizeAdmin(message.data));
          setItems(toList<ItemOption>(message.items));
        } else setManage(normalizeManage(message.data));
        setView(message.view);
      } else if (message.action === 'close') {
        setView(null);
      } else if (message.action === 'queue') {
        setBench((current) => current && { ...current, queue: toList<Job>(message.data) });
        setReceivedAt(Date.now());
      } else if (message.action === 'xp') {
        setBench((current) => current && { ...current, xp: { ...current.xp, current: message.data } });
      }
    };
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') close();
    };
    window.addEventListener('message', onMessage);
    window.addEventListener('keydown', onKeyDown);
    return () => {
      window.removeEventListener('message', onMessage);
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [close, updateBench]);

  const content = useMemo(() => {
    if (view === 'craft' && bench) return <CraftView key={bench.id} data={bench} receivedAt={receivedAt} onData={updateBench} onClose={close} />;
    if (view === 'manage' && manage) return <ManageView key={manage.id} data={manage} onData={setManage} onClose={close} />;
    if (view === 'admin' && admin) return <AdminView data={admin} items={items} onData={setAdmin} onClose={close} />;
    return null;
  }, [view, bench, manage, admin, items, receivedAt, updateBench, close]);

  return (
    <div className={isBrowser ? 'preview' : undefined}>
      {isBrowser && (
        <div className="preview-switch">
          <button type="button" onClick={() => setView('craft')}>
            Mesa
          </button>
          <button type="button" onClick={() => setView('manage')}>
            Gestión
          </button>
          <button type="button" onClick={() => setView('admin')}>
            Admin
          </button>
        </div>
      )}
      {content}
    </div>
  );
}
