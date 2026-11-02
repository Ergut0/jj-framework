import { useCallback, useEffect, useState } from 'react';
import { fetchNui, isBrowser, normalizeState, sampleState, type Flag, type Settings, type State } from './nui';

type Tab = 'flags' | 'gangs' | 'settings';

const NUMBER_FIELDS: { key: keyof Settings; label: string; unit: string; hint: string }[] = [
  { key: 'SecondsToCapture', label: 'Duración de la captura', unit: 's', hint: 'Tiempo dentro de la zona para quedarse la bandera' },
  { key: 'SecondsToPlant', label: 'Tiempo para plantar', unit: 's', hint: 'Lo que dura la animación sin moverse' },
  { key: 'SecondsBetweenPlants', label: 'Espera entre plantes', unit: 's', hint: 'Por banda, entre bandera y bandera' },
  { key: 'SecondsBetweenAttacks', label: 'Espera entre ataques', unit: 's', hint: 'Una banda tras empezar un ataque' },
  { key: 'SecondsBetweenDefends', label: 'Protección tras un ataque', unit: 's', hint: 'Una banda tras recibir un ataque' },
  { key: 'RadiusFlag', label: 'Radio de la zona', unit: 'm', hint: 'Quien está dentro cuenta en la captura' },
  { key: 'MaxFlagsPerGang', label: 'Máximo por banda', unit: '', hint: 'Banderas que puede plantar cada banda' },
];

const formatTime = (seconds: number) => `${Math.floor(seconds / 60)}:${String(Math.max(0, seconds % 60)).padStart(2, '0')}`;
const formatCoords = (flag: Flag) => `${flag.coords.x.toFixed(0)}, ${flag.coords.y.toFixed(0)}, ${flag.coords.z.toFixed(0)}`;

export function App() {
  const [open, setOpen] = useState(isBrowser);
  const [state, setState] = useState<State>(sampleState);
  const [tab, setTab] = useState<Tab>('flags');
  const [selected, setSelected] = useState<number | null>(isBrowser ? 2 : null);
  const [owner, setOwner] = useState<number | null>(null);
  const [plantGang, setPlantGang] = useState<number | null>(null);
  const [settings, setSettings] = useState<Settings>(sampleState.settings);
  const [dirty, setDirty] = useState(false);
  const [confirm, setConfirm] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const close = useCallback(() => {
    setOpen(false);
    fetchNui('close');
  }, []);

  // Las actualizaciones automáticas no pisan los ajustes que se están editando
  const apply = useCallback((next: State, resetSettings: boolean) => {
    const normalized = normalizeState(next);
    setState(normalized);
    if (resetSettings) {
      setSettings(normalized.settings);
      setDirty(false);
    }
  }, []);

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const message = event.data;
      if (message.action === 'open') {
        apply(message.state, true);
        const flags = normalizeState(message.state).flags;
        setSelected(flags[0]?.id ?? null);
        setConfirm(null);
        setOpen(true);
      } else if (message.action === 'state') {
        setState(normalizeState(message.state));
      } else if (message.action === 'close') {
        setOpen(false);
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
  }, [apply, close]);

  const run = async (name: string, data: Record<string, unknown> = {}, resetSettings = false) => {
    if (busy) return false;
    setBusy(true);
    setConfirm(null);
    const result = await fetchNui<{ success: boolean; state?: State }>(name, data);
    setBusy(false);
    if (result?.success && result.state) apply(result.state, resetSettings);
    return Boolean(result?.success);
  };

  // Doble clic para lo que no se puede deshacer
  const confirmed = (key: string) => {
    if (confirm === key) return true;
    setConfirm(key);
    return false;
  };

  if (!open) return null;

  const flag = state.flags.find((item) => item.id === selected) ?? null;
  const gangs = [...state.gangs].sort((a, b) => a.label.localeCompare(b.label));
  const capturing = state.flags.filter((item) => item.capture).length;
  const ownerValue = owner ?? gangs.find((gang) => gang.id !== flag?.gang)?.id ?? null;
  const plantValue = plantGang ?? gangs.find((gang) => !gang.excluded)?.id ?? null;
  const total = state.settings.SecondsToCapture || 1;

  const changeSetting = (key: keyof Settings, value: number | boolean) => {
    setSettings({ ...settings, [key]: value });
    setDirty(true);
  };

  return (
    <div className={isBrowser ? 'preview' : undefined}>
      <div className="window">
        <header className="header">
          <img className="logo" src="./logo.webp" alt="Atlantis Roleplay" />
          <div className="title">
            <small>Administración</small>
            <h1>Captura de banderas</h1>
          </div>
          <span className={`status ${state.active ? 'status-on' : ''}`}>
            <span className="status-dot" /> {state.active ? 'Evento activo' : 'Evento parado'}
          </span>
          {state.active ? (
            <button type="button" className="toggle toggle-bad" disabled={busy} onClick={() => confirmed('stop') && run('stop')}>
              <i className="fa-solid fa-flag-checkered" /> {confirm === 'stop' ? '¿Seguro? Pulsa otra vez' : 'Terminar evento'}
            </button>
          ) : (
            <button type="button" className="toggle toggle-on" disabled={busy} onClick={() => (!state.settings.ClearOnStart || state.flags.length === 0 || confirmed('start')) && run('start')}>
              <i className="fa-solid fa-play" /> {confirm === 'start' ? 'Se borrarán las banderas. ¿Seguro?' : 'Comenzar evento'}
            </button>
          )}
          <button type="button" className="icon-button" aria-label="Cerrar" onClick={close}>
            <i className="fa-solid fa-xmark" />
          </button>
        </header>

        <nav className="tabs">
          <button type="button" className={`tab ${tab === 'flags' ? 'tab-active' : ''}`} onClick={() => setTab('flags')}>
            <i className="fa-solid fa-flag" /> Banderas <span className="count">{state.flags.length}</span>
            {capturing > 0 && <span className="count count-warn">{capturing} en captura</span>}
          </button>
          <button type="button" className={`tab ${tab === 'gangs' ? 'tab-active' : ''}`} onClick={() => setTab('gangs')}>
            <i className="fa-solid fa-ranking-star" /> Clasificación y bandas
          </button>
          <button type="button" className={`tab ${tab === 'settings' ? 'tab-active' : ''}`} onClick={() => setTab('settings')}>
            <i className="fa-solid fa-sliders" /> Ajustes {dirty && <span className="count count-warn">sin guardar</span>}
          </button>
        </nav>

        {tab === 'flags' && (
          <div className="body">
            <aside className="list">
              <div className="list-items">
                {state.flags.map((item) => (
                  <button type="button" key={item.id} className={`zone ${selected === item.id ? 'zone-active' : ''}`} aria-pressed={selected === item.id} onClick={() => { setSelected(item.id); setOwner(null); }}>
                    <span className="dot" style={{ background: item.hex }} />
                    <span className="zone-text">
                      <strong>{item.label}</strong>
                      <small>
                        #{item.id} · {formatCoords(item)}
                      </small>
                    </span>
                    {item.capture && (
                      <span className={`badge ${item.capture.contested ? 'badge-paused' : ''}`} title={item.capture.contested ? 'Detenida: hay defensores' : 'En captura'}>
                        <i className={`fa-solid ${item.capture.contested ? 'fa-shield-halved' : 'fa-crosshairs'}`} /> {formatTime(item.capture.secondsLeft)}
                      </span>
                    )}
                  </button>
                ))}
                {state.flags.length === 0 && <p className="empty">No hay banderas puestas.</p>}
              </div>

              <div className="plant">
                <small>Poner una bandera donde estás</small>
                <div className="plant-row">
                  <select className="input" value={plantValue ?? ''} aria-label="Banda de la nueva bandera" onChange={(event) => setPlantGang(Number(event.target.value))}>
                    {gangs.map((gang) => (
                      <option key={gang.id} value={gang.id}>
                        {gang.label}
                      </option>
                    ))}
                  </select>
                  <button type="button" className="action action-small" disabled={busy || plantValue === null} onClick={() => run('placeFlag', { gang: plantValue })}>
                    <i className="fa-solid fa-flag" /> Poner
                  </button>
                </div>
              </div>
            </aside>

            <section className="form">
              {flag ? (
                <>
                  <div className="flag-head" style={{ borderLeftColor: flag.hex }}>
                    <i className="fa-solid fa-flag" style={{ color: flag.hex }} />
                    <div>
                      <small>Bandera #{flag.id}</small>
                      <strong>{flag.label}</strong>
                      <span>{formatCoords(flag)}</span>
                    </div>
                    <button type="button" className="action action-ghost action-small" onClick={() => fetchNui('teleport', { coords: flag.coords })}>
                      <i className="fa-solid fa-location-arrow" /> Ir
                    </button>
                  </div>

                  {flag.capture ? (
                    <div className={`capture ${flag.capture.contested ? 'capture-paused' : ''}`}>
                      <div className="capture-top">
                        <span>
                          <i className={`fa-solid ${flag.capture.contested ? 'fa-shield-halved' : 'fa-crosshairs'}`} />
                          <strong style={{ color: flag.capture.attackerHex }}>{flag.capture.attackerLabel}</strong> {flag.capture.contested ? 'está atacando, pero hay defensores en la zona' : 'está capturando la bandera'}
                        </span>
                        <strong>{formatTime(flag.capture.secondsLeft)}</strong>
                      </div>
                      <div className="bar">
                        <div className="bar-fill" style={{ width: `${Math.min(100, ((total - flag.capture.secondsLeft) / total) * 100)}%`, background: flag.capture.attackerHex }} />
                      </div>
                      <button type="button" className="action action-ghost action-small" disabled={busy} onClick={() => run('cancelCapture', { id: flag.id })}>
                        <i className="fa-solid fa-ban" /> Cancelar captura
                      </button>
                    </div>
                  ) : (
                    <p className="hint">
                      <i className="fa-solid fa-circle-info" /> Nadie la está capturando ahora mismo.
                    </p>
                  )}

                  <div className="field">
                    Cambiar de dueño
                    <div className="plant-row">
                      <select className="input" value={ownerValue ?? ''} aria-label="Nuevo dueño" onChange={(event) => setOwner(Number(event.target.value))}>
                        {gangs.map((gang) => (
                          <option key={gang.id} value={gang.id}>
                            {gang.label}
                            {gang.id === flag.gang ? ' (actual)' : ''}
                          </option>
                        ))}
                      </select>
                      <button type="button" className="action action-small" disabled={busy || ownerValue === null || ownerValue === flag.gang} onClick={() => run('setOwner', { id: flag.id, gang: ownerValue })}>
                        <i className="fa-solid fa-right-left" /> Dar
                      </button>
                    </div>
                  </div>

                  <div className="actions">
                    <button type="button" className="action action-danger" disabled={busy} onClick={() => confirmed(`delete-${flag.id}`) && run('deleteFlag', { id: flag.id })}>
                      <i className="fa-solid fa-trash" /> {confirm === `delete-${flag.id}` ? 'Pulsa otra vez para borrarla' : 'Borrar bandera'}
                    </button>
                  </div>
                </>
              ) : (
                <p className="empty">Elige una bandera de la lista.</p>
              )}

              {state.flags.length > 0 && (
                <div className="actions actions-end">
                  <button type="button" className="action action-ghost action-small" disabled={busy} onClick={() => confirmed('deleteAll') && run('deleteAll')}>
                    <i className="fa-solid fa-broom" /> {confirm === 'deleteAll' ? `¿Borrar las ${state.flags.length}? Pulsa otra vez` : 'Borrar todas las banderas'}
                  </button>
                </div>
              )}
            </section>
          </div>
        )}

        {tab === 'gangs' && (
          <section className="page">
            <div className="table">
              <div className="table-row table-head">
                <span>#</span>
                <span>Banda</span>
                <span>Banderas</span>
                <span>Conectados</span>
                <span>Participa</span>
              </div>
              {state.gangs.map((gang, index) => (
                <div key={gang.id} className={`table-row ${gang.excluded ? 'table-off' : ''}`}>
                  <span className={`rank ${index < 3 && gang.flags > 0 ? `rank-${index + 1}` : ''}`}>{index + 1}</span>
                  <span className="gang">
                    <span className="dot" style={{ background: gang.hex }} /> {gang.label}
                  </span>
                  <span>
                    <strong>{gang.flags}</strong>
                    <span className="mini-bar">
                      <span style={{ width: `${(gang.flags / Math.max(1, state.settings.MaxFlagsPerGang)) * 100}%`, background: gang.hex }} />
                    </span>
                  </span>
                  <span className="muted">
                    <i className="fa-solid fa-user" /> {gang.online}
                  </span>
                  <span>
                    <button type="button" className={`toggle switch ${gang.excluded ? '' : 'toggle-on'}`} aria-pressed={!gang.excluded} disabled={busy} onClick={() => run('setExcluded', { gang: gang.id, excluded: !gang.excluded })}>
                      <i className={`fa-solid ${gang.excluded ? 'fa-toggle-off' : 'fa-toggle-on'}`} /> {gang.excluded ? 'No' : 'Sí'}
                    </button>
                  </span>
                </div>
              ))}
              {state.gangs.length === 0 && <p className="empty">No hay bandas creadas en jj_gangs.</p>}
            </div>
            <p className="hint">
              <i className="fa-solid fa-circle-info" /> Las bandas que no participan no ven las banderas ni pueden plantar ni capturar. Sus banderas siguen puestas.
            </p>
          </section>
        )}

        {tab === 'settings' && (
          <section className="page">
            <div className="settings">
              {NUMBER_FIELDS.map((field) => (
                <label key={field.key} className="setting">
                  <span>
                    <strong>{field.label}</strong>
                    <small>{field.hint}</small>
                  </span>
                  <span className="number">
                    <input type="number" className="input" min={0} value={settings[field.key] as number} onChange={(event) => changeSetting(field.key, Number(event.target.value))} />
                    <em>{field.unit}</em>
                  </span>
                  {field.unit === 's' && <small className="muted">{formatTime(Number(settings[field.key]) || 0)} min</small>}
                </label>
              ))}
            </div>

            <div className="switches">
              <button type="button" className={`toggle ${settings.PauseWhenDefended ? 'toggle-on' : ''}`} aria-pressed={settings.PauseWhenDefended} onClick={() => changeSetting('PauseWhenDefended', !settings.PauseWhenDefended)}>
                <i className={`fa-solid ${settings.PauseWhenDefended ? 'fa-toggle-on' : 'fa-toggle-off'}`} /> La captura se para si hay defensores en la zona
              </button>
              <button type="button" className={`toggle ${settings.ClearOnStart ? 'toggle-on' : ''}`} aria-pressed={settings.ClearOnStart} onClick={() => changeSetting('ClearOnStart', !settings.ClearOnStart)}>
                <i className={`fa-solid ${settings.ClearOnStart ? 'fa-toggle-on' : 'fa-toggle-off'}`} /> Borrar las banderas al comenzar un evento
              </button>
            </div>

            <div className="actions">
              <button type="button" className="action" disabled={busy || !dirty} onClick={() => run('saveSettings', { settings }, true)}>
                <i className="fa-solid fa-floppy-disk" /> Guardar ajustes
              </button>
              <button type="button" className="action action-ghost" disabled={busy || !dirty} onClick={() => { setSettings(state.settings); setDirty(false); }}>
                <i className="fa-solid fa-rotate-left" /> Deshacer cambios
              </button>
            </div>
          </section>
        )}
      </div>
    </div>
  );
}
