import { useState } from 'react';
import type { Call, Flash } from './App';
import type { Settings } from './nui';

export function SettingsTab({ initial, call, flash }: { initial: Settings; call: Call; flash: (text: string, kind?: Flash['kind']) => void }) {
  const [settings, setSettings] = useState(initial);
  const [saved, setSaved] = useState(initial);
  const [busy, setBusy] = useState(false);
  const dirty = JSON.stringify(settings) !== JSON.stringify(saved);

  const toggle = (key: 'autoApply' | 'mechanicSave' | 'mechanicInstall') => setSettings({ ...settings, [key]: !settings[key] });

  const save = async () => {
    setBusy(true);
    const result = await call<{ settings: Settings }>('settings', settings, () => ({ settings }));
    setBusy(false);
    if (!result) return;
    setSettings(result.settings);
    setSaved(result.settings);
    flash('Ajustes guardados', 'success');
  };

  return (
    <section className="page">
      <p className="muted small">Se guardan en el servidor y mandan sobre config.lua. Solo los ven los superadministradores.</p>
      <div className="settings">
        <div className="setting">
          <span>
            <strong>Aplicar perfiles automáticamente</strong>
            <small>Perfiles instalados en matrículas y de serie de cada modelo al subir como conductor</small>
          </span>
          <button type="button" className={`toggle ${settings.autoApply ? 'toggle-on' : ''}`} aria-pressed={settings.autoApply} onClick={() => toggle('autoApply')}>
            <i className={`fa-solid ${settings.autoApply ? 'fa-toggle-on' : 'fa-toggle-off'}`} /> {settings.autoApply ? 'Sí' : 'No'}
          </button>
        </div>
        <div className="setting">
          <span>
            <strong>Duración de las pruebas</strong>
            <small>Minutos hasta que los cambios temporales se quitan solos (0 = nunca)</small>
          </span>
          <span className="number">
            <input type="number" className="input" min={0} max={240} value={settings.testMinutes} onChange={(event) => setSettings({ ...settings, testMinutes: Number(event.target.value) })} />
            <em>min</em>
          </span>
        </div>
        <div className="setting">
          <span>
            <strong>Margen de los mecánicos</strong>
            <small>Cuánto pueden alejar cada valor del original</small>
          </span>
          <span className="number">
            <input type="number" className="input" min={5} max={200} value={Math.round(settings.mechanicMaxRelative * 100)} onChange={(event) => setSettings({ ...settings, mechanicMaxRelative: Number(event.target.value) / 100 })} />
            <em>%</em>
          </span>
        </div>
        <div className="setting">
          <span>
            <strong>Los mecánicos guardan perfiles</strong>
            <small>Perfiles propios para los modelos que tunean</small>
          </span>
          <button type="button" className={`toggle ${settings.mechanicSave ? 'toggle-on' : ''}`} aria-pressed={settings.mechanicSave} onClick={() => toggle('mechanicSave')}>
            <i className={`fa-solid ${settings.mechanicSave ? 'fa-toggle-on' : 'fa-toggle-off'}`} /> {settings.mechanicSave ? 'Sí' : 'No'}
          </button>
        </div>
        <div className="setting">
          <span>
            <strong>Los mecánicos instalan perfiles</strong>
            <small>Dejar un perfil puesto en la matrícula del cliente</small>
          </span>
          <button type="button" className={`toggle ${settings.mechanicInstall ? 'toggle-on' : ''}`} aria-pressed={settings.mechanicInstall} onClick={() => toggle('mechanicInstall')}>
            <i className={`fa-solid ${settings.mechanicInstall ? 'fa-toggle-on' : 'fa-toggle-off'}`} /> {settings.mechanicInstall ? 'Sí' : 'No'}
          </button>
        </div>
      </div>
      <div className="actions">
        <button type="button" className="action" disabled={busy || !dirty} onClick={save}>
          <i className="fa-solid fa-floppy-disk" /> Guardar ajustes
        </button>
        <button type="button" className="action action-ghost" disabled={busy || !dirty} onClick={() => setSettings(saved)}>
          <i className="fa-solid fa-rotate-left" /> Deshacer
        </button>
      </div>
    </section>
  );
}
