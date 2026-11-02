import { useCallback, useEffect, useRef, useState } from 'react';
import { EditorTab } from './EditorTab';
import { LogsTab } from './LogsTab';
import { ProfilesTab } from './ProfilesTab';
import { SettingsTab } from './SettingsTab';
import { CLASS_NAMES, fetchNui, isBrowser, normalizeProfile, sampleOpen, toList, toValues, type OpenMessage, type Profile, type Result, type VehicleState } from './nui';

type Tab = 'editor' | 'profiles' | 'logs' | 'settings';

export interface Flash {
  text: string;
  kind: 'success' | 'error' | 'info';
}

// Llamada al juego. En el navegador usa el resultado de ejemplo, si lo hay
export type Call = <T = Record<string, unknown>>(name: string, data?: unknown, mock?: () => T) => Promise<Result<T> | undefined>;

const LEVELS: Record<string, string> = { mechanic: 'Mecánico', admin: 'Administrador', superadmin: 'Superadministrador' };

const normalize = (message: OpenMessage): OpenMessage => ({
  ...message,
  parameters: toList(message.parameters),
  categories: toList(message.categories),
  presets: toList(message.presets).map((preset) => ({ ...(preset as object), values: toValues((preset as { values: unknown }).values) })) as OpenMessage['presets'],
  original: message.original ? toValues(message.original) : undefined,
  current: message.current ? toValues(message.current) : undefined,
  data: {
    ...message.data,
    allowed: toList(message.data.allowed),
    profiles: toList<Profile>(message.data.profiles).map(normalizeProfile),
  },
});

export function App() {
  const [message, setMessage] = useState<OpenMessage | null>(isBrowser ? normalize(sampleOpen) : null);
  const [session, setSession] = useState(0);
  const [hidden, setHidden] = useState(false);
  const [tab, setTab] = useState<Tab>('editor');
  const [telemetry, setTelemetry] = useState({ speed: isBrowser ? 87 : 0, gear: isBrowser ? 3 : 0, rpm: isBrowser ? 0.64 : 0 });
  const [profiles, setProfiles] = useState<Profile[]>(isBrowser ? (normalize(sampleOpen).data.profiles ?? []) : []);
  const [vehicleState, setVehicleState] = useState<VehicleState | undefined>(isBrowser ? sampleOpen.data.state : undefined);
  const [flash, setFlash] = useState<Flash | null>(null);
  const flashTimer = useRef<number | undefined>(undefined);

  const showFlash = useCallback((text: string, kind: Flash['kind'] = 'info') => {
    setFlash({ text, kind });
    window.clearTimeout(flashTimer.current);
    flashTimer.current = window.setTimeout(() => setFlash(null), kind === 'error' ? 6000 : 3500);
  }, []);

  const close = useCallback(() => {
    setMessage(null);
    fetchNui('close');
  }, []);

  const call: Call = useCallback(
    async (name, data = {}, mock) => {
      if (isBrowser) return mock ? (mock() as never) : undefined;
      const result = await fetchNui(name, data);
      if (!result) {
        showFlash('Sin respuesta del servidor', 'error');
        return undefined;
      }
      if (result.error) {
        showFlash(result.error, 'error');
        return undefined;
      }
      return result as never;
    },
    [showFlash],
  );

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const data = event.data;
      if (data.action === 'open') {
        const next = normalize(data as OpenMessage);
        setMessage(next);
        setProfiles(next.data.profiles ?? []);
        setVehicleState(next.data.state);
        setTab(next.vehicle ? 'editor' : 'profiles');
        setHidden(false);
        setSession((value) => value + 1);
      } else if (data.action === 'close') {
        setMessage(null);
      } else if (data.action === 'show') {
        setHidden(false);
      } else if (data.action === 'telemetry') {
        setTelemetry({ speed: data.speed, gear: data.gear, rpm: data.rpm });
      } else if (data.action === 'tempCleared') {
        setVehicleState((state) => (state ? { ...state, temp: undefined } : state));
        showFlash('Se han quitado los cambios temporales del vehículo', 'info');
      }
    };
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && !hidden) close();
    };
    window.addEventListener('message', onMessage);
    window.addEventListener('keydown', onKeyDown);
    return () => {
      window.removeEventListener('message', onMessage);
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [close, hidden, showFlash]);

  if (!message) return null;

  const hide = () => {
    setHidden(true);
    fetchNui('hide');
  };

  const { data, vehicle } = message;
  const rules = data.rules;
  const unit = message.speedUnit === 'mph' ? 'mph' : 'km/h';

  // Mientras se prueba conduciendo solo queda una barra pequeña arriba
  if (hidden) {
    return (
      <div className="test-bar">
        <i className="fa-solid fa-flask" />
        <span>
          Modo prueba · <strong>{telemetry.speed}</strong> {unit} · marcha {telemetry.gear}
        </span>
      </div>
    );
  }

  const stateLabel = vehicleState?.temp
    ? { icon: 'fa-flask', text: `Temporal: ${vehicleState.temp.label}`, kind: 'warn' }
    : vehicleState?.persistent
      ? { icon: vehicleState.persistent.source === 'install' ? 'fa-screwdriver-wrench' : 'fa-industry', text: `${vehicleState.persistent.source === 'install' ? 'Instalado' : 'De serie'}: ${vehicleState.persistent.name}`, kind: 'good' }
      : { icon: 'fa-circle-check', text: 'Handling original', kind: '' };

  return (
    <div className={isBrowser ? 'preview' : undefined}>
      <div className="window">
        <header className="header">
          <img className="logo" src="./logo.webp" alt="Atlantis Roleplay" />
          <div className="title">
            <small>{LEVELS[data.level] ?? 'Editor'}</small>
            <h1>Handling</h1>
          </div>

          {vehicle ? (
            <>
              <div className="vehicle-chip">
                <i className="fa-solid fa-car-side" />
                <div>
                  <strong>{vehicle.label}</strong>
                  <small>
                    {vehicle.modelName ?? 'modelo desconocido'} · {CLASS_NAMES[vehicle.class] ?? `Clase ${vehicle.class}`}
                    {vehicle.workshop ? ` · ${vehicle.workshop}` : ''}
                  </small>
                </div>
                {vehicle.plate && <span className="plate">{vehicle.plate}</span>}
              </div>
              <div className="telemetry" title="Velocidad actual">
                <strong>{telemetry.speed}</strong>
                <small>{unit}</small>
                <span className="gear">{telemetry.gear === 0 ? 'R' : telemetry.gear}</span>
                <span className="rpm">
                  <span style={{ width: `${Math.min(100, telemetry.rpm * 100)}%` }} />
                </span>
              </div>
              <span className={`state-chip ${stateLabel.kind ? `state-${stateLabel.kind}` : ''}`}>
                <i className={`fa-solid ${stateLabel.icon}`} /> {stateLabel.text}
              </span>
            </>
          ) : (
            <span className="state-chip">
              <i className="fa-solid fa-circle-info" /> Sube a un vehículo como conductor para usar el editor
            </span>
          )}

          <button type="button" className="icon-button" aria-label="Cerrar" onClick={close}>
            <i className="fa-solid fa-xmark" />
          </button>
        </header>

        <nav className="tabs">
          {vehicle && (
            <button type="button" className={`tab ${tab === 'editor' ? 'tab-active' : ''}`} onClick={() => setTab('editor')}>
              <i className="fa-solid fa-sliders" /> Editor
            </button>
          )}
          <button type="button" className={`tab ${tab === 'profiles' ? 'tab-active' : ''}`} onClick={() => setTab('profiles')}>
            <i className="fa-solid fa-layer-group" /> Perfiles
          </button>
          {rules.logs && (
            <button type="button" className={`tab ${tab === 'logs' ? 'tab-active' : ''}`} onClick={() => setTab('logs')}>
              <i className="fa-solid fa-clock-rotate-left" /> Registros
            </button>
          )}
          {rules.settings && (
            <button type="button" className={`tab ${tab === 'settings' ? 'tab-active' : ''}`} onClick={() => setTab('settings')}>
              <i className="fa-solid fa-shield-halved" /> Ajustes globales
            </button>
          )}
        </nav>

        {vehicle && message.original && message.current && (
          <div className="tab-page" hidden={tab !== 'editor'}>
            <EditorTab key={session} message={message} profiles={profiles} vehicleState={vehicleState} call={call} flash={showFlash} onHide={hide} onState={setVehicleState} onProfiles={setProfiles} />
          </div>
        )}
        {tab === 'profiles' && (
          <ProfilesTab
            message={message}
            profiles={profiles}
            call={call}
            flash={showFlash}
            onState={setVehicleState}
            onProfiles={setProfiles}
            onLoad={(profile) => {
              window.dispatchEvent(new CustomEvent('jj-load-profile', { detail: profile }));
              setTab('editor');
            }}
          />
        )}
        {tab === 'logs' && <LogsTab call={call} />}
        {tab === 'settings' && data.settings && <SettingsTab initial={data.settings} call={call} flash={showFlash} />}

        {flash && (
          <div className={`flash flash-${flash.kind}`} role="status">
            <i className={`fa-solid ${flash.kind === 'error' ? 'fa-triangle-exclamation' : flash.kind === 'success' ? 'fa-circle-check' : 'fa-circle-info'}`} />
            <span>{flash.text}</span>
          </div>
        )}
      </div>
    </div>
  );
}
