import { useCallback, useEffect, useRef, useState } from 'react';
import { fetchNui, isBrowser } from './nui';

interface Saved {
  frequency: number;
  label: string;
}

interface Invite {
  frequency: number;
  from: string;
}

type Tab = 'keypad' | 'saved' | 'invites';

const KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0'];

// En el mismo orden que radioAnimations en client/main.lua
const ANIMATIONS = ['Mano', 'Oreja', 'Pecho'];

const SAMPLE_SAVED: Saved[] = [
  { frequency: 145.5, label: 'Los del barrio' },
  { frequency: 88.2, label: 'Taller de Nora' },
];
const SAMPLE_INVITES: Invite[] = [{ frequency: 212.4, from: 'Lucía Ferrer' }];

const format = (frequency: number) => frequency.toFixed(1);

// Tres cifras y un decimal como máximo
const addKey = (draft: string, key: string) => {
  const next = draft + key;
  return /^\d{0,3}(\.\d?)?$/.test(next) ? next : draft;
};

// Lua envía las tablas vacías como objeto o como lista según el caso
const toList = <T,>(list: unknown): T[] => (Array.isArray(list) ? list : list && typeof list === 'object' ? (Object.values(list) as T[]) : []);

export function App() {
  const [open, setOpen] = useState(isBrowser);
  const [joined, setJoined] = useState<number | null>(isBrowser ? 145.5 : null);
  const [draft, setDraft] = useState(isBrowser ? '145.5' : '');
  const [count, setCount] = useState(isBrowser ? 3 : 0);
  const [limits, setLimits] = useState({ min: 1, max: 999.9, saved: 20, label: 24 });
  const [saved, setSaved] = useState<Saved[]>(isBrowser ? SAMPLE_SAVED : []);
  const [invites, setInvites] = useState<Invite[]>(isBrowser ? SAMPLE_INVITES : []);
  const [tab, setTab] = useState<Tab>('keypad');
  const [label, setLabel] = useState('');
  const [target, setTarget] = useState('');
  const [volume, setVolume] = useState(100);
  const [animation, setAnimation] = useState(0);
  const [transmitting, setTransmitting] = useState(false);
  const [receiving, setReceiving] = useState<Set<number>>(() => new Set());
  const [busy, setBusy] = useState(false);
  const panel = useRef<HTMLDivElement>(null);

  const value = Number(draft);
  const valid = draft !== '' && draft !== '.' && value >= limits.min && value <= limits.max;

  const stopTyping = useCallback(() => {
    fetchNui('setTyping', { typing: false });
  }, []);

  const close = useCallback(() => {
    setOpen(false);
    fetchNui('closeRadio');
  }, []);

  // Al cambiar de pestaña el campo desaparece sin perder el foco: el personaje tiene que poder volver a andar
  useEffect(() => {
    stopTyping();
  }, [tab, stopTyping]);

  const tune = useCallback(async (frequency: number) => {
    setDraft(format(frequency));
    if (isBrowser) {
      setJoined(frequency);
      setCount(1);
      return;
    }
    setBusy(true);
    // Solo se marca si el servidor acepta: sin radio se queda como estaba
    const result = await fetchNui<{ success: boolean; frequency?: number; count?: number }>('joinFrequency', { frequency });
    setBusy(false);
    if (result?.success && result.frequency !== undefined) {
      setJoined(result.frequency);
      setCount(result.count ?? 1);
      setReceiving(new Set());
    }
  }, []);

  const powerOff = useCallback(async () => {
    if (!isBrowser) await fetchNui('leaveFrequency');
    setJoined(null);
    setCount(0);
    setTransmitting(false);
    setReceiving(new Set());
  }, []);

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const data = event.data;
      switch (data.action) {
        case 'open': {
          const shown = data.frequency || data.lastFrequency;
          const pendingInvites = toList<Invite>(data.invites);
          setJoined(data.frequency || null);
          setDraft(shown ? format(shown) : '');
          setCount(data.count);
          setLimits({ min: data.min, max: data.max, saved: data.maxSaved, label: data.maxLabel });
          setSaved(toList<Saved>(data.saved));
          setInvites(pendingInvites);
          setTab(pendingInvites.length > 0 ? 'invites' : 'keypad');
          setLabel('');
          setTarget('');
          setVolume(data.volume);
          setAnimation(data.animIndex);
          setTransmitting(false);
          setReceiving(new Set());
          setOpen(true);
          break;
        }
        case 'close':
          setOpen(false);
          break;
        case 'count':
          setCount(data.count);
          break;
        case 'invites':
          setInvites(toList<Invite>(data.invites));
          break;
        case 'setFrequency':
          setJoined(data.frequency || null);
          setTransmitting(false);
          setReceiving(new Set());
          break;
        case 'talking':
          if (data.own) {
            setTransmitting(data.talking);
          } else {
            setReceiving((current) => {
              const next = new Set(current);
              if (data.talking) next.add(data.id);
              else next.delete(data.id);
              return next;
            });
          }
          break;
      }
    };
    window.addEventListener('message', onMessage);
    return () => window.removeEventListener('message', onMessage);
  }, []);

  useEffect(() => {
    if (!open) return;
    const onMouseDown = (event: MouseEvent) => {
      if (!panel.current?.contains(event.target as Node)) close();
    };
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        close();
        return;
      }
      // Las teclas de la radio solo cuentan en el teclado y fuera de los campos de texto
      if (tab !== 'keypad' || event.target instanceof HTMLInputElement) return;
      if (event.key === 'Backspace') setDraft((current) => current.slice(0, -1));
      else if (event.key === 'Enter') {
        if (valid && !busy) tune(value);
      } else if (/^[\d.,]$/.test(event.key)) {
        setDraft((current) => addKey(current, event.key === ',' ? '.' : event.key));
      }
    };
    document.addEventListener('mousedown', onMouseDown);
    document.addEventListener('keydown', onKeyDown);
    return () => {
      document.removeEventListener('mousedown', onMouseDown);
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [open, close, tune, valid, value, busy, tab]);

  const changeVolume = async (name: 'volumeUp' | 'volumeDown') => {
    if (isBrowser) {
      setVolume((current) => Math.max(5, Math.min(100, current + (name === 'volumeUp' ? 5 : -5))));
      return;
    }
    const result = await fetchNui<{ volume: number }>(name);
    if (result) setVolume(result.volume);
  };

  const chooseAnimation = async (index: number) => {
    if (isBrowser) {
      setAnimation(index);
      return;
    }
    const result = await fetchNui<{ success: boolean }>('setAnimation', { animIndex: index });
    if (result?.success) setAnimation(index);
  };

  const saveFrequency = async () => {
    const name = label.trim();
    if (!valid || !name) return;
    if (isBrowser) {
      setSaved((current) => [...current.filter((entry) => entry.frequency !== value), { frequency: value, label: name }]);
      setLabel('');
      return;
    }
    const result = await fetchNui<{ success: boolean; saved?: unknown }>('saveFrequency', { frequency: value, label: name });
    if (result?.success) {
      setSaved(toList<Saved>(result.saved));
      setLabel('');
    }
  };

  const deleteFrequency = async (frequency: number) => {
    if (isBrowser) {
      setSaved((current) => current.filter((entry) => entry.frequency !== frequency));
      return;
    }
    const result = await fetchNui<{ success: boolean; saved?: unknown }>('deleteFrequency', { frequency });
    if (result?.success) setSaved(toList<Saved>(result.saved));
  };

  const invitePlayer = async () => {
    const id = Number(target);
    if (!id || joined === null) return;
    if (isBrowser) {
      setTarget('');
      return;
    }
    const result = await fetchNui<{ success: boolean }>('invitePlayer', { target: id });
    if (result?.success) setTarget('');
  };

  const answerInvite = async (frequency: number, accept: boolean) => {
    if (isBrowser) {
      if (accept) {
        setJoined(frequency);
        setDraft(format(frequency));
        setCount(2);
        setSaved((current) => (current.some((entry) => entry.frequency === frequency) ? current : [...current, { frequency, label: invites.find((invite) => invite.frequency === frequency)?.from ?? '' }]));
      }
      setInvites((current) => current.filter((invite) => invite.frequency !== frequency));
      return;
    }
    const result = await fetchNui<{ success: boolean; frequency?: number; count?: number; saved?: unknown }>('answerInvite', { frequency, accept });
    if (!result?.success) return;
    setInvites((current) => current.filter((invite) => invite.frequency !== frequency));
    if (accept && result.frequency !== undefined) {
      setJoined(result.frequency);
      setDraft(format(result.frequency));
      setCount(result.count ?? 1);
      setReceiving(new Set());
      setSaved(toList<Saved>(result.saved));
    }
  };

  const on = joined !== null;
  const pending = on && (!valid || value !== joined);
  const savedEntry = valid ? saved.find((entry) => entry.frequency === value) : undefined;
  const full = saved.length >= limits.saved && !savedEntry;

  let hint = 'Escribe una frecuencia y pulsa Sintonizar';
  if (draft !== '' && !valid) hint = `Elige entre ${format(limits.min)} y ${format(limits.max)} MHz`;
  else if (on && !pending) hint = 'Mantén Bloq Mayús para hablar';
  else if (pending) hint = `Sigues en ${format(joined)} hasta que sintonices`;

  return (
    <div className={isBrowser ? 'preview' : undefined}>
      <div id="radio" ref={panel} className={open ? 'active' : undefined}>
        <div className="antenna" />

        <div className="body">
          <header className="top">
            <img className="logo" src="./logo.webp" alt="Atlantis Roleplay" />
            <button type="button" className="close" aria-label="Cerrar" onClick={close}>
              <i className="fa-solid fa-xmark" />
            </button>
          </header>

          <div className="screen" data-on={on}>
            <div className="screen-row">
              <span className={`badge ${transmitting ? 'badge-tx' : ''}`}>TX</span>
              <span className={`badge ${receiving.size > 0 ? 'badge-rx' : ''}`}>RX</span>
              <span className="screen-state">{on ? 'Conectada' : 'Apagada'}</span>
            </div>
            <div className="frequency">
              <strong>{draft || '---.-'}</strong>
              <span>MHz</span>
            </div>
            <div className="screen-row screen-row-bottom">
              <span>
                <i className="fa-solid fa-user" /> {on ? `${count} en línea` : 'Sin señal'}
              </span>
              <span>
                <i className="fa-solid fa-volume-high" /> {volume}%
              </span>
            </div>
          </div>

          <p className="hint">{hint}</p>

          <div className="tabs" role="tablist">
            <button type="button" role="tab" aria-selected={tab === 'keypad'} className={`tab ${tab === 'keypad' ? 'tab-active' : ''}`} onClick={() => setTab('keypad')}>
              Teclado
            </button>
            <button type="button" role="tab" aria-selected={tab === 'saved'} className={`tab ${tab === 'saved' ? 'tab-active' : ''}`} onClick={() => setTab('saved')}>
              Guardadas
            </button>
            <button type="button" role="tab" aria-selected={tab === 'invites'} className={`tab ${tab === 'invites' ? 'tab-active' : ''}`} onClick={() => setTab('invites')}>
              Invitar
              {invites.length > 0 && <span className="tab-count">{invites.length}</span>}
            </button>
          </div>

          <div className="tab-content">
            {tab === 'keypad' && (
              <div className="keypad">
                {KEYS.map((key) => (
                  <button type="button" key={key} className="key" onClick={() => setDraft((current) => addKey(current, key))}>
                    {key}
                  </button>
                ))}
                <button type="button" className="key" aria-label="Borrar" onClick={() => setDraft((current) => current.slice(0, -1))}>
                  <i className="fa-solid fa-delete-left" />
                </button>
              </div>
            )}

            {tab === 'saved' && (
              <>
                <form
                  className="form"
                  onSubmit={(event) => {
                    event.preventDefault();
                    saveFrequency();
                  }}
                >
                  <input
                    className="input"
                    value={label}
                    maxLength={limits.label}
                    placeholder={valid ? `Nombre para ${format(value)}` : 'Elige antes una frecuencia'}
                    aria-label="Nombre de la frecuencia"
                    onFocus={() => fetchNui('setTyping', { typing: true })}
                    onBlur={stopTyping}
                    onChange={(event) => setLabel(event.target.value)}
                  />
                  <button type="submit" className="form-button" disabled={!valid || !label.trim() || full}>
                    {savedEntry ? 'Renombrar' : 'Guardar'}
                  </button>
                </form>

                <div className="list">
                  {saved.length === 0 ? (
                    <p className="empty">Aún no tienes frecuencias guardadas.</p>
                  ) : (
                    saved.map((entry) => (
                      <div key={entry.frequency} className={`row ${entry.frequency === joined ? 'row-active' : ''}`}>
                        <button type="button" className="row-main" disabled={busy} aria-label={`Sintonizar ${entry.label}`} onClick={() => tune(entry.frequency)}>
                          <strong>{entry.label}</strong>
                          <small>{format(entry.frequency)} MHz</small>
                        </button>
                        <button
                          type="button"
                          className="row-icon"
                          aria-label={`Renombrar ${entry.label}`}
                          onClick={() => {
                            setDraft(format(entry.frequency));
                            setLabel(entry.label);
                          }}
                        >
                          <i className="fa-solid fa-pen" />
                        </button>
                        <button type="button" className="row-icon row-danger" aria-label={`Borrar ${entry.label}`} onClick={() => deleteFrequency(entry.frequency)}>
                          <i className="fa-solid fa-trash" />
                        </button>
                      </div>
                    ))
                  )}
                </div>
                <p className="note">
                  {saved.length} de {limits.saved} guardadas
                </p>
              </>
            )}

            {tab === 'invites' && (
              <>
                <form
                  className="form"
                  onSubmit={(event) => {
                    event.preventDefault();
                    invitePlayer();
                  }}
                >
                  <input
                    className="input"
                    value={target}
                    inputMode="numeric"
                    maxLength={5}
                    placeholder={on ? 'Id de tu amigo' : 'Conéctate para invitar'}
                    aria-label="Id del jugador"
                    disabled={!on}
                    onFocus={() => fetchNui('setTyping', { typing: true })}
                    onBlur={stopTyping}
                    onChange={(event) => setTarget(event.target.value.replace(/\D/g, ''))}
                  />
                  <button type="submit" className="form-button" disabled={!on || !Number(target)}>
                    Invitar
                  </button>
                </form>

                <div className="list">
                  {invites.length === 0 ? (
                    <p className="empty">No tienes invitaciones pendientes.</p>
                  ) : (
                    invites.map((invite) => (
                      <div key={invite.frequency} className="row">
                        <div className="row-main">
                          <strong>{invite.from}</strong>
                          <small>Te invita a {format(invite.frequency)} MHz</small>
                        </div>
                        <button type="button" className="row-icon row-good" aria-label={`Aceptar la invitación de ${invite.from}`} onClick={() => answerInvite(invite.frequency, true)}>
                          <i className="fa-solid fa-check" />
                        </button>
                        <button type="button" className="row-icon row-danger" aria-label={`Rechazar la invitación de ${invite.from}`} onClick={() => answerInvite(invite.frequency, false)}>
                          <i className="fa-solid fa-xmark" />
                        </button>
                      </div>
                    ))
                  )}
                </div>
                <p className="note">Al aceptar, la frecuencia se guarda sola.</p>
              </>
            )}
          </div>

          <div className="main-buttons">
            <button type="button" className={`power ${on ? 'power-on' : ''}`} aria-label={on ? 'Apagar la radio' : 'Encender la radio'} aria-pressed={on} disabled={!on && !valid} onClick={() => (on ? powerOff() : tune(value))}>
              <i className="fa-solid fa-power-off" />
            </button>
            <button type="button" className="tune" disabled={!valid || busy || (on && !pending)} onClick={() => tune(value)}>
              {on && !pending ? 'Sintonizada' : 'Sintonizar'}
            </button>
          </div>

          <div className="control">
            <span className="control-label">Volumen</span>
            <button type="button" className="step" aria-label="Bajar volumen" onClick={() => changeVolume('volumeDown')}>
              <i className="fa-solid fa-minus" />
            </button>
            <div className="meter">
              <div className="meter-fill" style={{ width: `${volume}%` }} />
            </div>
            <button type="button" className="step" aria-label="Subir volumen" onClick={() => changeVolume('volumeUp')}>
              <i className="fa-solid fa-plus" />
            </button>
          </div>

          <div className="control">
            <span className="control-label">Al hablar</span>
            <div className="segments">
              {ANIMATIONS.map((name, index) => (
                <button type="button" key={name} className={`segment ${animation === index ? 'segment-active' : ''}`} onClick={() => chooseAnimation(index)}>
                  {name}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
