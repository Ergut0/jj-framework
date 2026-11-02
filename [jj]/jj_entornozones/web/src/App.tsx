import { useCallback, useEffect, useState } from 'react';
import { fetchNui, isBrowser, normalizeZones, sampleZones, type Zone, type ZoneShape } from './nui';

const MAX_TEXT = 500;
const COLORS = ['#9B30FF', '#C084FC', '#38D9F5', '#4ADE80', '#FACC15', '#F97316', '#FB7185', '#F4F0FF'];

interface Draft {
  id?: number;
  label: string;
  text: string;
  duration: number;
  color: string;
  enabled: boolean;
  zone?: ZoneShape;
  zoneChanged: boolean;
}

const emptyDraft = (): Draft => ({ label: '', text: '', duration: 10, color: COLORS[0], enabled: true, zoneChanged: false });

const fromZone = (zone: Zone): Draft => ({
  id: zone.id,
  label: zone.label ?? '',
  text: zone.entorno,
  duration: zone.duration,
  color: zone.color,
  enabled: zone.enabled,
  zone: zone.coords,
  zoneChanged: false,
});

// Superficie aproximada de la zona, para hacerse una idea de su tamaño
const area = (shape?: ZoneShape) => {
  if (!shape || shape.points.length < 3) return 0;
  let sum = 0;
  shape.points.forEach((point, index) => {
    const next = shape.points[(index + 1) % shape.points.length];
    sum += point.x * next.y - next.x * point.y;
  });
  return Math.abs(sum) / 2;
};

export function App() {
  const [open, setOpen] = useState(isBrowser);
  const [hidden, setHidden] = useState(false);
  const [zones, setZones] = useState<Zone[]>(isBrowser ? sampleZones : []);
  const [selected, setSelected] = useState<number | null>(isBrowser ? sampleZones[0].id : null);
  const [draft, setDraft] = useState<Draft>(isBrowser ? fromZone(sampleZones[0]) : emptyDraft());
  const [search, setSearch] = useState('');
  const [showZones, setShowZones] = useState(false);
  const [busy, setBusy] = useState(false);

  const close = useCallback(() => {
    setOpen(false);
    fetchNui('close');
  }, []);

  const select = useCallback((zone: Zone | null) => {
    setSelected(zone ? zone.id : null);
    setDraft(zone ? fromZone(zone) : emptyDraft());
  }, []);

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const message = event.data;
      if (message.action === 'open') {
        const list = normalizeZones(message.zones);
        setZones(list);
        setShowZones(Boolean(message.showZones));
        setSelected(list[0]?.id ?? null);
        setDraft(list[0] ? fromZone(list[0]) : emptyDraft());
        setHidden(false);
        setOpen(true);
      } else if (message.action === 'close') {
        setOpen(false);
      } else if (message.action === 'hide') {
        setHidden(true);
      } else if (message.action === 'drawn') {
        setHidden(false);
        if (message.zone) {
          const zone = { ...message.zone, points: normalizeZones([{ coords: message.zone }])[0].coords.points } as ZoneShape;
          setDraft((current) => ({ ...current, zone, zoneChanged: true }));
        }
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
  }, [close]);

  const applyZones = (list: unknown, keepId?: number) => {
    const next = normalizeZones(list);
    setZones(next);
    const target = next.find((zone) => zone.id === keepId) ?? next.reduce<Zone | null>((last, zone) => (!last || zone.id > last.id ? zone : last), null);
    select(target);
  };

  const save = async () => {
    if (busy) return;
    setBusy(true);
    const payload = {
      id: draft.id,
      label: draft.label,
      text: draft.text,
      duration: draft.duration,
      color: draft.color,
      enabled: draft.enabled,
      zone: draft.zoneChanged ? draft.zone : undefined,
    };
    const result = await fetchNui<{ success: boolean; zones?: unknown }>('save', payload);
    setBusy(false);
    if (result?.success) applyZones(result.zones, draft.id);
    if (isBrowser) {
      const zone: Zone = { id: draft.id ?? Date.now(), label: draft.label || undefined, entorno: draft.text, coords: draft.zone ?? sampleZones[0].coords, duration: draft.duration, color: draft.color, enabled: draft.enabled };
      const next = draft.id ? zones.map((item) => (item.id === draft.id ? zone : item)) : [...zones, zone];
      setZones(next);
      select(zone);
    }
  };

  const remove = async () => {
    if (!draft.id || busy) return;
    setBusy(true);
    const result = await fetchNui<{ success: boolean; zones?: unknown }>('delete', { id: draft.id });
    setBusy(false);
    if (result?.success) {
      const next = normalizeZones(result.zones);
      setZones(next);
      select(next[0] ?? null);
    }
    if (isBrowser) {
      const next = zones.filter((zone) => zone.id !== draft.id);
      setZones(next);
      select(next[0] ?? null);
    }
  };

  const draw = () => {
    if (isBrowser) {
      setDraft({ ...draft, zone: sampleZones[1].coords, zoneChanged: true });
      return;
    }
    fetchNui('draw');
  };

  const toggleZones = () => {
    const next = !showZones;
    setShowZones(next);
    fetchNui('toggleZones', { show: next });
  };

  if (!open) return null;

  const query = search.trim().toLowerCase();
  const filtered = zones.filter((zone) => `${zone.label ?? ''} ${zone.entorno}`.toLowerCase().includes(query));
  const textLength = draft.text.length;
  const canSave = draft.text.trim().length > 0 && textLength <= MAX_TEXT && Boolean(draft.zone);
  const size = Math.round(area(draft.zone));

  return (
    <div className={isBrowser ? 'preview' : undefined}>
      <div className={`window ${hidden ? 'window-hidden' : ''}`}>
        <header className="header">
          <img className="logo" src="./logo.webp" alt="Atlantis Roleplay" />
          <div className="title">
            <small>Administración</small>
            <h1>Zonas de entorno</h1>
          </div>
          <button type="button" className={`toggle ${showZones ? 'toggle-on' : ''}`} aria-pressed={showZones} onClick={toggleZones} title="Dibuja las zonas en el mundo, solo para ti">
            <i className={`fa-solid ${showZones ? 'fa-eye' : 'fa-eye-slash'}`} /> Mostrar zonas
          </button>
          <button type="button" className="icon-button" aria-label="Cerrar" onClick={close}>
            <i className="fa-solid fa-xmark" />
          </button>
        </header>

        <div className="body">
          <aside className="list">
            <input className="input" value={search} placeholder="Buscar zona" aria-label="Buscar zona" onChange={(event) => setSearch(event.target.value)} />
            <div className="list-items">
              {filtered.map((zone) => (
                <button type="button" key={zone.id} className={`zone ${selected === zone.id ? 'zone-active' : ''} ${zone.enabled ? '' : 'zone-off'}`} aria-pressed={selected === zone.id} onClick={() => select(zone)}>
                  <span className="dot" style={{ background: zone.color }} />
                  <span className="zone-text">
                    <strong>{zone.label || `Zona ${zone.id}`}</strong>
                    <small>{zone.entorno}</small>
                  </span>
                  {!zone.enabled && <i className="fa-solid fa-power-off" title="Desactivada" />}
                </button>
              ))}
              {filtered.length === 0 && <p className="empty">{zones.length === 0 ? 'Aún no hay zonas.' : 'Ninguna zona coincide.'}</p>}
            </div>
            <button type="button" className={`zone zone-new ${selected === null ? 'zone-active' : ''}`} onClick={() => select(null)}>
              <i className="fa-solid fa-plus" /> Nueva zona
            </button>
          </aside>

          <section className="form">
            <div className="row">
              <label className="field">
                Nombre
                <input className="input" value={draft.label} maxLength={64} placeholder="Solo para encontrarla. También sale como título del aviso" onChange={(event) => setDraft({ ...draft, label: event.target.value })} />
              </label>
              <button type="button" className={`toggle switch ${draft.enabled ? 'toggle-on' : ''}`} aria-pressed={draft.enabled} onClick={() => setDraft({ ...draft, enabled: !draft.enabled })}>
                <i className={`fa-solid ${draft.enabled ? 'fa-toggle-on' : 'fa-toggle-off'}`} /> {draft.enabled ? 'Activa' : 'Desactivada'}
              </button>
            </div>

            <label className="field">
              Texto del entorno
              <textarea className="input textarea" value={draft.text} maxLength={MAX_TEXT} placeholder="Lo que nota quien entra: olores, ruidos, gente, ambiente..." onChange={(event) => setDraft({ ...draft, text: event.target.value })} />
              <small className={`counter ${textLength > MAX_TEXT ? 'counter-bad' : ''}`}>
                {textLength} / {MAX_TEXT}
              </small>
            </label>

            <div className="row">
              <label className="field">
                Duración del aviso: {draft.duration} s
                <input type="range" className="range" min={3} max={60} value={draft.duration} onChange={(event) => setDraft({ ...draft, duration: Number(event.target.value) })} />
              </label>
              <div className="field">
                Color
                <div className="colors">
                  {COLORS.map((color) => (
                    <button type="button" key={color} className={`color ${draft.color === color ? 'color-active' : ''}`} style={{ background: color }} aria-label={`Color ${color}`} aria-pressed={draft.color === color} onClick={() => setDraft({ ...draft, color })} />
                  ))}
                  <input type="color" className="color-picker" value={draft.color.toLowerCase()} aria-label="Otro color" onChange={(event) => setDraft({ ...draft, color: event.target.value.toUpperCase() })} />
                </div>
              </div>
            </div>

            <div className="notice-preview" style={{ borderLeftColor: draft.color }}>
              <i className="fa-solid fa-map-location-dot" style={{ color: draft.color }} />
              <div>
                {draft.label && <strong>{draft.label}</strong>}
                <p>{draft.text || 'Así verán el aviso los jugadores.'}</p>
              </div>
            </div>

            <div className={`shape ${draft.zone ? '' : 'shape-missing'}`}>
              <i className="fa-solid fa-draw-polygon" />
              <span>
                {draft.zone ? (
                  <>
                    <strong>
                      Zona dibujada{draft.zoneChanged ? ' (sin guardar)' : ''}
                    </strong>
                    <small>
                      {draft.zone.points.length} puntos · unos {size.toLocaleString('es-ES')} m² · {Math.round(draft.zone.thickness)} m de alto
                    </small>
                  </>
                ) : (
                  <>
                    <strong>Falta dibujar la zona</strong>
                    <small>Con la cámara libre: C pone o quita puntos, la rueda cambia la altura y G termina</small>
                  </>
                )}
              </span>
              <button type="button" className="action action-ghost" onClick={draw}>
                <i className="fa-solid fa-pen-ruler" /> {draft.zone ? 'Redibujar' : 'Dibujar'}
              </button>
              {draft.zone && (
                <button type="button" className="action action-ghost" onClick={() => fetchNui('teleport', { points: draft.zone?.points })}>
                  <i className="fa-solid fa-location-arrow" /> Ir
                </button>
              )}
            </div>

            <div className="actions">
              <button type="button" className="action" disabled={!canSave || busy} onClick={save}>
                <i className="fa-solid fa-floppy-disk" /> {draft.id ? 'Guardar cambios' : 'Crear zona'}
              </button>
              <button type="button" className="action action-ghost" disabled={!draft.text.trim()} onClick={() => fetchNui('preview', { label: draft.label, text: draft.text, duration: draft.duration, color: draft.color })}>
                <i className="fa-solid fa-bell" /> Probar aviso
              </button>
              {draft.id && (
                <button type="button" className="action action-danger" disabled={busy} onClick={remove}>
                  <i className="fa-solid fa-trash" /> Borrar
                </button>
              )}
            </div>
          </section>
        </div>
      </div>
    </div>
  );
}
