import { useCallback, useEffect, useRef, useState } from 'react';
import { fetchNui, isBrowser, RadioPlayer, sampleFrequencies } from './nui';

const ACTIONS = [
  ['arrastrar', 'Arrastrar', 'Agarrar o soltar', 'fa-people-pulling'],
  ['esposar', 'Esposar', 'Poner o quitar', 'fa-handcuffs'],
  ['vehiculo', 'Vehículo', 'Meter o sacar', 'fa-car-side'],
  ['bolsa', 'Bolsa', 'En la cabeza', 'fa-bag-shopping'],
] as const;

// En el mismo orden que radioAnimations en client/main.lua
const ANIMATIONS = ['Mano', 'Oreja', 'Pecho'];

const SAMPLE_ID = 1;

// Lua envía las tablas vacías como objeto o como lista según el caso
const toList = (players: unknown): RadioPlayer[] =>
  Array.isArray(players) ? players : players && typeof players === 'object' ? (Object.values(players) as RadioPlayer[]) : [];

const toFrequencies = (data: unknown): RadioPlayer[][] => toList(data).map(toList);

export function App() {
  const [open, setOpen] = useState(isBrowser);
  const [gang, setGang] = useState(isBrowser ? 'Los Tridentes' : 'Mi banda');
  const [playerId, setPlayerId] = useState(isBrowser ? SAMPLE_ID : 0);
  const [joined, setJoined] = useState<number | null>(isBrowser ? 1 : null);
  const [frequencies, setFrequencies] = useState<RadioPlayer[][]>(isBrowser ? sampleFrequencies : []);
  const [talking, setTalking] = useState<Set<number>>(() => new Set(isBrowser ? [12] : []));
  const [volume, setVolume] = useState(100);
  const [animation, setAnimation] = useState(0);
  const [headbag, setHeadbag] = useState(false);
  const panel = useRef<HTMLDivElement>(null);

  const close = useCallback(() => {
    setOpen(false);
    fetchNui('closeRadioUI');
  }, []);

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const data = event.data;
      switch (data.action) {
        case 'open':
          setGang(data.gang);
          setPlayerId(data.playerId);
          setJoined(data.frequency || null);
          setFrequencies(toFrequencies(data.frequencies));
          setVolume(data.volume);
          setAnimation(data.animIndex);
          setTalking(new Set());
          setOpen(true);
          break;
        case 'close':
          setOpen(false);
          break;
        case 'updateFrequencies':
          setFrequencies(toFrequencies(data.frequencies));
          break;
        case 'setFrequency':
          setJoined(data.frequency || null);
          break;
        case 'playerTalking':
          setTalking((current) => {
            const next = new Set(current);
            if (data.talking) next.add(data.id);
            else next.delete(data.id);
            return next;
          });
          break;
        case 'headbag':
          setHeadbag(data.active);
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
      if (event.key === 'Escape') close();
    };
    document.addEventListener('mousedown', onMouseDown);
    document.addEventListener('keydown', onKeyDown);
    return () => {
      document.removeEventListener('mousedown', onMouseDown);
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [open, close]);

  const toggleFrequency = async (frequency: number) => {
    if (isBrowser) {
      setJoined(joined === frequency ? null : frequency);
      return;
    }
    if (joined === frequency) {
      await fetchNui('leaveFrequency');
      setJoined(null);
      return;
    }
    // Solo se marca si el servidor acepta: sin radio se queda como estaba
    const result = await fetchNui<{ success: boolean; frequency?: number }>('joinFrequency', { frequency });
    if (result?.success && result.frequency) setJoined(result.frequency);
  };

  const changeVolume = async (name: 'volumeUp' | 'volumeDown') => {
    if (isBrowser) {
      setVolume((value) => Math.max(5, Math.min(100, value + (name === 'volumeUp' ? 5 : -5))));
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
    const result = await fetchNui<{ success: boolean }>('playAnimation', { animIndex: index });
    if (result?.success) setAnimation(index);
  };

  const occupied = frequencies.map((players, index) => ({ frequency: index + 1, players })).filter(({ players }) => players.length > 0);

  return (
    <>
      {headbag && <div className="headbag" />}

      <div className={isBrowser ? 'preview' : undefined}>
        <div id="gang-panel" ref={panel} className={open ? 'active' : undefined}>
          <header className="header">
            <img className="logo" src="./logo.webp" alt="Atlantis Roleplay" />
            <div className="gang">
              <span className="gang-label">Tu banda</span>
              <strong className="gang-name">{gang}</strong>
              <span className={`status ${joined !== null ? 'status-on' : ''}`}>
                <span className="status-dot" />
                {joined !== null ? `Frecuencia ${joined}` : 'Desconectado'}
              </span>
            </div>
            <button type="button" className="close" aria-label="Cerrar" onClick={close}>
              <i className="fa-solid fa-xmark" />
            </button>
          </header>

          <section className="section">
            <h3>Acciones</h3>
            <div className="actions">
              {ACTIONS.map(([action, label, detail, icon]) => (
                <button type="button" key={action} className="action" onClick={() => fetchNui('action', { action })}>
                  <i className={`fa-solid ${icon}`} />
                  <span className="action-text">
                    <strong>{label}</strong>
                    <small>{detail}</small>
                  </span>
                </button>
              ))}
            </div>
          </section>

          <section className="section section-radio">
            <h3>Radio</h3>

            <div className="channels">
              {frequencies.map((players, index) => {
                const frequency = index + 1;
                return (
                  <button
                    type="button"
                    key={frequency}
                    className={`channel ${joined === frequency ? 'channel-active' : ''}`}
                    aria-label={joined === frequency ? `Salir de la frecuencia ${frequency}` : `Entrar en la frecuencia ${frequency}`}
                    aria-pressed={joined === frequency}
                    onClick={() => toggleFrequency(frequency)}
                  >
                    <strong>{frequency}</strong>
                    <small>{players.length > 0 ? players.length : '–'}</small>
                  </button>
                );
              })}
            </div>

            <div className="members">
              {occupied.length === 0 ? (
                <p className="empty">Nadie conectado. Pulsa una frecuencia para entrar.</p>
              ) : (
                occupied.map(({ frequency, players }) => (
                  <div key={frequency} className={`group ${joined === frequency ? 'group-active' : ''}`}>
                    <h4>Frecuencia {frequency}</h4>
                    {players.map((player) => (
                      <div key={player.id} className={`member ${talking.has(player.id) ? 'member-talking' : ''}`}>
                        <span className="member-name">
                          {player.name}
                          {player.id === playerId && <em> (Tú)</em>}
                        </span>
                        {talking.has(player.id) && <i className="fa-solid fa-microphone" aria-label="Hablando" />}
                      </div>
                    ))}
                  </div>
                ))
              )}
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
              <span className="volume-value">{volume}%</span>
            </div>

            <div className="control">
              <span className="control-label">Al hablar</span>
              <div className="segments">
                {ANIMATIONS.map((label, index) => (
                  <button type="button" key={label} className={`segment ${animation === index ? 'segment-active' : ''}`} onClick={() => chooseAnimation(index)}>
                    {label}
                  </button>
                ))}
              </div>
            </div>
          </section>
        </div>
      </div>
    </>
  );
}
