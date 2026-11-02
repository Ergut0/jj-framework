import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { BuyResult, fetchNui, isBrowser, Item, sampleItems } from './nui';

type Sort = 'recommended' | 'cheap' | 'expensive' | 'name';

const ALL = 'Todo';
const TOAST_TIME = 3200;

// toLocaleString('es-ES') no agrupa los números de cuatro cifras: 8500 junto a 25.000
const money = (value: number) => String(value).replace(/\B(?=(\d{3})+(?!\d))/g, '.');

function Coin({ size = 16 }: { size?: number }) {
  return (
    <svg className="coin" width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 2 5 12.2 12 16l7-3.8z" fill="currentColor" />
      <path d="M12 17.6 5 13.8 12 22l7-8.2z" fill="currentColor" opacity="0.6" />
    </svg>
  );
}

function Price({ value }: { value: number }) {
  return (
    <span className="price">
      <Coin />
      {money(value)}
    </span>
  );
}

export function App() {
  const [open, setOpen] = useState(isBrowser);
  const [items, setItems] = useState<Item[]>(isBrowser ? sampleItems : []);
  const [balance, setBalance] = useState(isBrowser ? 42000 : 0);
  const [category, setCategory] = useState(ALL);
  const [search, setSearch] = useState('');
  const [sort, setSort] = useState<Sort>('recommended');
  const [selected, setSelected] = useState<Item | null>(null);
  const [buying, setBuying] = useState(false);
  const [toast, setToast] = useState<{ ok: boolean; message: string } | null>(null);
  const toastTimer = useRef<number | undefined>(undefined);

  const showToast = useCallback((ok: boolean, message: string) => {
    window.clearTimeout(toastTimer.current);
    setToast({ ok, message });
    toastTimer.current = window.setTimeout(() => setToast(null), TOAST_TIME);
  }, []);

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const data = event.data;
      if (data.type === 'display') {
        setItems(data.items ?? []);
        setBalance(data.ethereum ?? 0);
        setSelected(null);
        setSearch('');
        setCategory(ALL);
        setOpen(true);
      } else if (data.type === 'money') {
        setBalance(data.ethereum ?? 0);
      } else if (data.type === 'hide') {
        setOpen(false);
      }
    };
    window.addEventListener('message', onMessage);
    return () => window.removeEventListener('message', onMessage);
  }, []);

  const close = useCallback(() => {
    setOpen(false);
    setSelected(null);
    if (!isBrowser) fetchNui('close');
  }, []);

  const confirmBuy = useCallback(async () => {
    if (!selected || buying) return;
    setBuying(true);

    const audio = new Audio('./click.mp3');
    audio.volume = 0.3;
    audio.play().catch(() => {});

    const result: BuyResult | undefined = isBrowser
      ? { ok: true, message: `Has comprado ${selected.label}`, balance: balance - selected.price }
      : await fetchNui<BuyResult>('buyItem', { index: selected.index });

    setBuying(false);
    setSelected(null);
    if (!result) {
      showToast(false, 'No se ha podido completar la compra');
      return;
    }
    if (result.balance !== undefined) setBalance(result.balance);
    showToast(result.ok, result.message);
  }, [selected, buying, balance, showToast]);

  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        if (selected) setSelected(null);
        else close();
      } else if (event.key === 'Enter' && selected) {
        confirmBuy();
      }
    };
    window.addEventListener('keyup', onKey);
    return () => window.removeEventListener('keyup', onKey);
  }, [open, selected, close, confirmBuy]);

  const categories = useMemo(() => {
    const counts = new Map<string, number>();
    for (const item of items) counts.set(item.category, (counts.get(item.category) ?? 0) + 1);
    return [[ALL, items.length] as const, ...counts.entries()];
  }, [items]);

  const visible = useMemo(() => {
    const term = search.trim().toLowerCase();
    const list = items.filter(
      (item) => (category === ALL || item.category === category) && (!term || item.label.toLowerCase().includes(term)),
    );
    if (sort === 'cheap') list.sort((a, b) => a.price - b.price);
    if (sort === 'expensive') list.sort((a, b) => b.price - a.price);
    if (sort === 'name') list.sort((a, b) => a.label.localeCompare(b.label, 'es'));
    return list;
  }, [items, category, search, sort]);

  if (!open) return null;

  return (
    <div className={`screen ${isBrowser ? 'screen-preview' : ''}`}>
      <main className="store">
        <aside className="side">
          <img className="logo" src="./logo.webp" alt="Atlantis Roleplay" />

          <div className="balance">
            <span className="balance-label">Tu saldo</span>
            <strong key={balance} className="balance-value">
              <Coin size={22} />
              {money(balance)}
            </strong>
            <span className="balance-note">Ethereum · se gana jugando</span>
          </div>

          <nav className="categories" aria-label="Categorías">
            {categories.map(([name, count]) => (
              <button
                type="button"
                key={name}
                className={`category ${category === name ? 'category-active' : ''}`}
                onClick={() => setCategory(name)}
              >
                <span>{name}</span>
                <span className="category-count">{count}</span>
              </button>
            ))}
          </nav>

          <p className="hint">
            <kbd>ESC</kbd> para salir
          </p>
        </aside>

        <section className="content">
          <header className="toolbar">
            <h1>Tienda</h1>
            <input
              className="field search"
              type="text"
              placeholder="Buscar artículo"
              aria-label="Buscar artículo"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
            />
            <select className="field" aria-label="Ordenar" value={sort} onChange={(event) => setSort(event.target.value as Sort)}>
              <option value="recommended">Destacados</option>
              <option value="cheap">Más baratos</option>
              <option value="expensive">Más caros</option>
              <option value="name">Por nombre</option>
            </select>
            <button type="button" className="close" aria-label="Cerrar la tienda" onClick={close}>
              ×
            </button>
          </header>

          {visible.length === 0 ? (
            <p className="empty">{items.length === 0 ? 'Ahora mismo no hay artículos a la venta.' : 'No hay artículos con esa búsqueda.'}</p>
          ) : (
            <div className="grid">
              {visible.map((item) => {
                const missing = item.price - balance;
                return (
                  <article key={item.index} className={`card ${missing > 0 ? 'card-short' : ''}`}>
                    <div className="card-image">
                      <img src={`./imgs/${item.img}`} alt="" loading="lazy" />
                    </div>
                    <h2>{item.label}</h2>
                    <Price value={item.price} />
                    {missing > 0 ? (
                      <p className="missing">Te faltan {money(missing)}</p>
                    ) : (
                      <button type="button" className="buy" onClick={() => setSelected(item)}>
                        Comprar
                      </button>
                    )}
                  </article>
                );
              })}
            </div>
          )}
        </section>

        {toast && (
          <div className={`toast ${toast.ok ? 'toast-ok' : 'toast-bad'}`} role="status">
            {toast.message}
          </div>
        )}

        {selected && (
          <div className="overlay" onClick={() => setSelected(null)}>
            <div className="dialog" role="dialog" aria-modal="true" aria-label="Confirmar compra" onClick={(event) => event.stopPropagation()}>
              <img src={`./imgs/${selected.img}`} alt="" />
              <h2>{selected.label}</h2>
              <dl>
                <div>
                  <dt>Precio</dt>
                  <dd>
                    <Price value={selected.price} />
                  </dd>
                </div>
                <div>
                  <dt>Saldo después</dt>
                  <dd>
                    <Price value={balance - selected.price} />
                  </dd>
                </div>
              </dl>
              <div className="dialog-actions">
                <button type="button" className="secondary" onClick={() => setSelected(null)}>
                  Cancelar
                </button>
                <button type="button" className="buy" disabled={buying} onClick={confirmBuy}>
                  {buying ? 'Comprando…' : 'Confirmar compra'}
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
