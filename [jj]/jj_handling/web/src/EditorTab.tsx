import { useEffect, useMemo, useRef, useState } from 'react';
import type { Call, Flash } from './App';
import { fetchNui, formatValue, isBrowser, normalizeProfile, type OpenMessage, type Parameter, type Profile, type Values, type VehicleState } from './nui';

interface Props {
  message: OpenMessage;
  profiles: Profile[];
  vehicleState?: VehicleState;
  call: Call;
  flash: (text: string, kind?: Flash['kind']) => void;
  onHide: () => void;
  onState: (state: VehicleState) => void;
  onProfiles: (profiles: Profile[]) => void;
}

interface Source {
  label: string;
  presetId?: string;
  profile?: Profile;
  values: Values;   // Solo lo que cambia respecto al original
}

const EPSILON = 1e-6;
const same = (a?: number, b?: number) => a !== undefined && b !== undefined && Math.abs(a - b) < EPSILON;

// Lo que cambia respecto al original
const diffOf = (values: Values, original: Values): Values => {
  const diff: Values = {};
  for (const key of Object.keys(values)) {
    if (!same(values[key], original[key])) diff[key] = values[key];
  }
  return diff;
};

const sameDiff = (a: Values, b: Values) => {
  const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
  for (const key of keys) if (!same(a[key], b[key])) return false;
  return true;
};

// Campo numérico que deja escribir libremente y aplica el valor al salir o con Intro
export function NumberField({ value, step, disabled, label, onCommit }: { value?: number; step: number; disabled?: boolean; label: string; onCommit: (value: number) => void }) {
  const [text, setText] = useState<string | null>(null);
  const commit = () => {
    if (text === null) return;
    const parsed = Number(text.replace(',', '.'));
    if (text.trim() !== '' && Number.isFinite(parsed)) onCommit(parsed);
    setText(null);
  };
  return (
    <input
      type="text"
      inputMode="decimal"
      className="input"
      value={text ?? formatValue(value, step)}
      disabled={disabled}
      aria-label={label}
      onFocus={(event) => event.target.select()}
      onChange={(event) => setText(event.target.value)}
      onBlur={commit}
      onKeyDown={(event) => {
        if (event.key === 'Enter') (event.target as HTMLInputElement).blur();
        if (event.key === 'Escape') {
          event.stopPropagation();
          setText(null);
        }
      }}
    />
  );
}

export function EditorTab({ message, profiles, vehicleState, call, flash, onHide, onState, onProfiles }: Props) {
  const original = message.original!;
  const { data, parameters, categories } = message;
  const rules = data.rules;
  const limits = data.limits ?? {};
  const allowed = useMemo(() => new Set(data.allowed ?? []), [data.allowed]);
  const presets = message.presets ?? [];

  const [applied, setApplied] = useState<Values>(message.current!);
  const [draft, setDraft] = useState<Values>(message.current!);
  const [source, setSource] = useState<Source | null>(() => {
    const temp = vehicleState?.temp;
    const persistent = vehicleState?.persistent && profiles.find((profile) => profile.id === vehicleState.persistent?.id);
    if (temp) return { label: temp.label, values: diffOf(message.current!, original), profile: profiles.find((profile) => profile.id === temp.profileId) };
    if (persistent) return { label: persistent.name, profile: persistent, values: persistent.params ?? {} };
    return null;
  });
  const [category, setCategory] = useState(categories[0]?.id ?? 'performance');
  const [viewOriginal, setViewOriginal] = useState(false);
  const [compare, setCompare] = useState<Source | null>(null);
  const [side, setSide] = useState<'A' | 'B'>('A');
  const [warnings, setWarnings] = useState<string[]>([]);
  const [errors, setErrors] = useState<string[]>([]);
  const [saving, setSaving] = useState<{ name: string; global: boolean; asNew: boolean } | null>(null);
  const [busy, setBusy] = useState(false);
  const previewTimer = useRef<number | undefined>(undefined);

  const draftDiff = useMemo(() => diffOf(draft, original), [draft, original]);
  const dirty = !sameDiff(draftDiff, diffOf(applied, original));
  const label = Object.keys(draftDiff).length === 0 ? 'Original' : source && sameDiff(draftDiff, source.values) ? source.label : 'Personalizado';

  // Límites de cada parámetro con lo que permite el nivel (por ejemplo, ±35 % para mecánicos)
  const rangeOf = (param: Parameter) => {
    const limit = limits[param.key] ?? { min: 0, max: 1 };
    let { min, max } = limit;
    const base = original[param.key];
    if (rules.maxRelative && base) {
      const spread = Math.abs(base) * rules.maxRelative;
      min = Math.max(min, base - spread);
      max = Math.min(max, base + spread);
    }
    return { min, max };
  };

  // Vista previa en vivo: el vehículo cambia mientras se mueven los valores
  const shown = viewOriginal ? original : compare && side === 'B' ? { ...original, ...compare.values } : draft;
  useEffect(() => {
    window.clearTimeout(previewTimer.current);
    previewTimer.current = window.setTimeout(async () => {
      const result = await fetchNui<{ ok: boolean; warnings?: string[]; errors?: string[] }>('preview', { values: diffOf(shown, original) });
      if (shown !== draft) return;
      if (isBrowser) {
        setWarnings(draft.fBrakeForce > 2 ? ['Fuerza de frenado muy alta: el vehículo puede clavarse o volcar al frenar'] : draft.fSteeringLock > 55 ? ['Ángulo de giro muy grande: inestable a alta velocidad (normal en drift)'] : []);
        setErrors(draft.fTractionCurveMin > draft.fTractionCurveMax ? ['El agarre mínimo no puede ser mayor que el máximo'] : []);
        return;
      }
      setWarnings(result?.warnings ? Object.values(result.warnings) : []);
      setErrors(result?.errors ? Object.values(result.errors) : []);
    }, 70);
    return () => window.clearTimeout(previewTimer.current);
  }, [shown, draft, original]);

  // Cargar un perfil desde la pestaña de perfiles
  useEffect(() => {
    const onLoad = (event: Event) => {
      const profile = (event as CustomEvent<Profile>).detail;
      loadSource({ label: profile.name, profile, values: profile.params ?? {} });
    };
    window.addEventListener('jj-load-profile', onLoad);
    return () => window.removeEventListener('jj-load-profile', onLoad);
  });

  const loadSource = (next: Source) => {
    const values: Values = { ...original };
    for (const [key, value] of Object.entries(next.values)) {
      if (allowed.has(key)) values[key] = value;
    }
    setDraft(values);
    setSource(next);
    setViewOriginal(false);
    setSide('A');
  };

  const setValue = (param: Parameter, raw: number) => {
    if (Number.isNaN(raw)) return;
    const { min, max } = rangeOf(param);
    const value = Math.min(max, Math.max(min, param.int ? Math.round(raw) : raw));
    setDraft((current) => ({ ...current, [param.key]: value }));
    setSide('A');
    setViewOriginal(false);
  };

  const apply = async () => {
    if (busy) return;
    setBusy(true);
    const result = await call<{ state: VehicleState }>('applyTemp', { params: draftDiff, label, profileId: source?.profile?.id }, () => ({ state: { ...(vehicleState ?? { autoApply: true }), temp: { label, by: 'Tú', params: draftDiff } } }));
    setBusy(false);
    if (!result) return;
    setApplied(draft);
    onState(result.state);
    flash(`Aplicado al vehículo: ${label}`, 'success');
  };

  const restore = async () => {
    if (busy) return;
    setBusy(true);
    const result = await call<{ state: VehicleState }>('restore', {}, () => ({ state: { ...(vehicleState ?? { autoApply: true }), temp: undefined } }));
    setBusy(false);
    if (!result) return;
    onState(result.state);
    // Vuelve a lo guardado para el vehículo, o al original si no tiene nada
    const persistent = result.state.persistent && profiles.find((profile) => profile.id === result.state.persistent?.id);
    const values = persistent?.params ? { ...original, ...persistent.params } : original;
    setApplied(values);
    setDraft(values);
    setSource(persistent ? { label: persistent.name, profile: persistent, values: persistent.params ?? {} } : null);
    setCompare(null);
    flash('Restaurado', 'success');
  };

  const openSave = () => {
    const profile = source?.profile;
    setSaving({ name: profile?.name ?? `${message.vehicle?.label ?? 'Vehículo'} ${label === 'Original' ? '' : label}`.trim(), global: profile?.global ?? false, asNew: !profile?.canEdit });
  };

  const save = async () => {
    if (!saving || busy) return;
    const profile = !saving.asNew ? source?.profile : undefined;
    setBusy(true);
    const result = await call<{ profile: Profile }>(
      'save',
      { id: profile?.id, version: profile?.version, name: saving.name, params: draftDiff, preset: source?.presetId ?? source?.profile?.preset, global: saving.global },
      () => ({ profile: { id: Date.now(), name: saving.name, modelHash: data.vehicle!.modelHash, modelName: data.vehicle!.modelName, global: saving.global, own: true, version: (profile?.version ?? 0) + 1, createdAt: Date.now() / 1000, updatedAt: Date.now() / 1000, paramCount: Object.keys(draftDiff).length, params: draftDiff, modelDefault: false, plates: [], canEdit: true, canDelete: true } }),
    );
    setBusy(false);
    if (!result) return;
    const saved = normalizeProfile(result.profile);
    onProfiles([saved, ...profiles.filter((item) => item.id !== saved.id)]);
    setSource({ label: saved.name, profile: saved, values: saved.params ?? draftDiff });
    setSaving(null);
    flash(profile ? 'Perfil actualizado' : 'Perfil guardado', 'success');
  };

  const chooseCompare = (value: string) => {
    setSide('A');
    if (!value) return setCompare(null);
    const [kind, id] = value.split(':');
    if (kind === 'applied') return setCompare({ label: 'Lo aplicado', values: diffOf(applied, original) });
    if (kind === 'original') return setCompare({ label: 'Original', values: {} });
    if (kind === 'preset') {
      const preset = presets.find((item) => item.id === id);
      if (preset) setCompare({ label: preset.label, presetId: preset.id, values: preset.values });
    }
    if (kind === 'profile') {
      const profile = profiles.find((item) => String(item.id) === id);
      if (profile) setCompare({ label: profile.name, profile, values: profile.params ?? {} });
    }
  };

  const changedIn = (categoryId: string) => parameters.filter((param) => (param.category === categoryId || param.alsoIn?.includes(categoryId)) && draftDiff[param.key] !== undefined).length;
  const visible = parameters.filter((param) => param.category === category || param.alsoIn?.includes(category));
  const expires = vehicleState?.temp?.expires;
  const compareValues = compare ? { ...original, ...compare.values } : null;

  return (
    <div className="editor">
      <aside className="categories">
        {categories.map((item) => {
          const count = changedIn(item.id);
          return (
            <button type="button" key={item.id} className={`category ${category === item.id ? 'category-active' : ''}`} onClick={() => setCategory(item.id)}>
              <i className={`fa-solid ${item.icon}`} />
              <span>{item.label}</span>
              {count > 0 && <span className="count">{count}</span>}
            </button>
          );
        })}
        <div className="legend">
          <span>
            <i className="fa-solid fa-lock" /> Sin permiso
          </span>
          <span>
            <i className="fa-solid fa-triangle-exclamation" /> Tratamiento especial
          </span>
          {rules.maxRelative ? <span>Límite: ±{Math.round(rules.maxRelative * 100)} % del original</span> : null}
        </div>
      </aside>

      <section className="params">
        {visible.map((param) => {
          const locked = !allowed.has(param.key);
          const { min, max } = rangeOf(param);
          const value = draft[param.key];
          const base = original[param.key];
          const changed = !same(value, base);
          const delta = base ? ((value - base) / Math.abs(base)) * 100 : 0;
          const other = compareValues?.[param.key];
          return (
            <div key={param.key} className={`param ${changed ? 'param-changed' : ''} ${locked ? 'param-locked' : ''}`}>
              <div className="param-head">
                <div>
                  <strong>
                    {param.label}
                    {param.special && <i className="fa-solid fa-triangle-exclamation special" title="Tratamiento especial: lee la descripción" />}
                    {locked && <i className="fa-solid fa-lock" title="Tu nivel no puede cambiar este valor" />}
                  </strong>
                  <code>{param.key}</code>
                </div>
                <div className="param-values">
                  {changed && <span className={`delta ${delta >= 0 ? 'delta-up' : 'delta-down'}`}>{base ? `${delta >= 0 ? '+' : ''}${delta.toFixed(1)} %` : 'cambiado'}</span>}
                  <span className="muted">Serie {formatValue(base, param.step)}</span>
                  {other !== undefined && (
                    <span className={`compare-value ${same(other, value) ? 'compare-same' : ''}`} title={`Valor en ${compare?.label}`}>
                      B {formatValue(other, param.step)}
                    </span>
                  )}
                </div>
              </div>
              <p className="param-desc">{param.desc}</p>
              <div className="param-input">
                <div className="slider-wrap">
                  <input type="range" className="slider" min={min} max={max} step={param.step} value={value ?? 0} disabled={locked} aria-label={param.label} style={{ ['--fill' as string]: `${((value - min) / (max - min || 1)) * 100}%` }} onChange={(event) => setValue(param, Number(event.target.value))} />
                  <div className="range-hint">
                    <span>{formatValue(min, param.step)}</span>
                    <span>{formatValue(max, param.step)}</span>
                  </div>
                </div>
                <div className="number">
                  <NumberField value={value} step={param.step} disabled={locked} label={`${param.label}, valor`} onCommit={(next) => setValue(param, next)} />
                  {param.unit && <em>{param.unit}</em>}
                </div>
                <button type="button" className="icon-button small" title="Volver al valor de serie" disabled={locked || !changed} onClick={() => setValue(param, base)}>
                  <i className="fa-solid fa-rotate-left" />
                </button>
              </div>
            </div>
          );
        })}

        {category === 'traction' && (
          <div className="param param-derived">
            <div className="param-head">
              <div>
                <strong>Reparto de tracción trasero</strong>
                <code>fDriveBiasRear</code>
              </div>
              <div className="param-values">
                <span className="value-big">{formatValue(1 - (draft.fDriveBiasFront ?? 0), 0.01)}</span>
              </div>
            </div>
            <p className="param-desc">Valor derivado: lo calcula el juego a partir del reparto delantero (1 − delantero). No se edita por separado.</p>
          </div>
        )}

        {category === 'steering' && (
          <div className="info-box">
            <i className="fa-solid fa-circle-info" />
            <p>
              Más <strong>ángulo de giro</strong> cierra las curvas pero vuelve el coche nervioso. Subir el <strong>centro de balanceo delantero</strong> o la barra delantera tiende a <strong>subvirar</strong>; subirlos detrás tiende a <strong>sobrevirar</strong>. Son tendencias: el resultado depende del resto del handling, así que pruébalo conduciendo.
            </p>
          </div>
        )}
      </section>

      <aside className="side">
        <div className="card">
          <div className="card-row">
            <span className="muted">Perfil activo</span>
            <strong className={label === 'Personalizado' ? 'accent' : ''}>{label}</strong>
          </div>
          <div className="card-row">
            <span className="muted">Estado</span>
            <span className={`status ${dirty ? 'status-warn' : vehicleState?.temp ? 'status-temp' : 'status-ok'}`}>
              {dirty ? 'Cambios sin aplicar' : vehicleState?.temp ? 'Aplicado (temporal)' : 'Sin cambios'}
            </span>
          </div>
          {expires && (
            <div className="card-row">
              <span className="muted">La prueba acaba</span>
              <span>{new Date(expires * 1000).toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' })}</span>
            </div>
          )}
          <div className="card-row">
            <span className="muted">Valores cambiados</span>
            <span>{Object.keys(draftDiff).length}</span>
          </div>
        </div>

        <div className="card">
          <h3>Perfiles preconfigurados</h3>
          <div className="presets">
            {presets.map((preset) => (
              <button type="button" key={preset.id} className={`preset ${source?.presetId === preset.id && label === preset.label ? 'preset-active' : ''}`} disabled={!preset.compatible} title={preset.compatible ? preset.desc : 'No es para esta clase de vehículo'} onClick={() => loadSource({ label: preset.label, presetId: preset.id, values: preset.values })}>
                {preset.label}
              </button>
            ))}
          </div>
          {profiles.length > 0 && (
            <>
              <h3>Perfiles de este modelo</h3>
              <div className="model-profiles">
                {profiles.slice(0, 5).map((profile) => (
                  <button type="button" key={profile.id} className={`model-profile ${source?.profile?.id === profile.id ? 'preset-active' : ''}`} onClick={() => loadSource({ label: profile.name, profile, values: profile.params ?? {} })}>
                    <span>{profile.name}</span>
                    <small>
                      {profile.modelDefault && <i className="fa-solid fa-industry" title="De serie" />} {profile.global ? 'Global' : profile.authorName}
                    </small>
                  </button>
                ))}
              </div>
            </>
          )}
        </div>

        <div className="card">
          <h3>Comparar</h3>
          <select className="input" value={compare ? (compare.presetId ? `preset:${compare.presetId}` : compare.profile ? `profile:${compare.profile.id}` : compare.label === 'Original' ? 'original:' : 'applied:') : ''} aria-label="Comparar con" onChange={(event) => chooseCompare(event.target.value)}>
            <option value="">No comparar</option>
            <option value="applied:">Lo aplicado ahora</option>
            <option value="original:">Original</option>
            {presets.filter((preset) => preset.id !== 'original' && preset.compatible).map((preset) => (
              <option key={preset.id} value={`preset:${preset.id}`}>
                Preset: {preset.label}
              </option>
            ))}
            {profiles.map((profile) => (
              <option key={profile.id} value={`profile:${profile.id}`}>
                Perfil: {profile.name}
              </option>
            ))}
          </select>
          {compare && (
            <div className="ab">
              <button type="button" className={`ab-side ${side === 'A' ? 'ab-active' : ''}`} onClick={() => setSide('A')}>
                A · {label}
              </button>
              <button type="button" className={`ab-side ${side === 'B' ? 'ab-active' : ''}`} onClick={() => setSide('B')}>
                B · {compare.label}
              </button>
            </div>
          )}
          <button type="button" className={`toggle ${viewOriginal ? 'toggle-on' : ''}`} aria-pressed={viewOriginal} onClick={() => setViewOriginal(!viewOriginal)}>
            <i className={`fa-solid ${viewOriginal ? 'fa-eye' : 'fa-eye-slash'}`} /> {viewOriginal ? 'Viendo el original' : 'Ver el original un momento'}
          </button>
        </div>

        {(errors.length > 0 || warnings.length > 0) && (
          <div className="card alerts">
            {errors.map((text) => (
              <p key={text} className="alert alert-error">
                <i className="fa-solid fa-circle-xmark" /> {text}
              </p>
            ))}
            {warnings.map((text) => (
              <p key={text} className="alert">
                <i className="fa-solid fa-triangle-exclamation" /> {text}
              </p>
            ))}
          </div>
        )}

        <div className="actions">
          <button type="button" className="action" disabled={busy || !rules.applyTemp || errors.length > 0 || !dirty} onClick={apply}>
            <i className="fa-solid fa-bolt" /> Aplicar
          </button>
          <button type="button" className="action action-ghost" disabled={busy || !rules.saveProfiles || errors.length > 0 || Object.keys(draftDiff).length === 0} onClick={openSave}>
            <i className="fa-solid fa-floppy-disk" /> Guardar
          </button>
        </div>
        <div className="actions">
          <button type="button" className="action action-ghost" disabled={busy || !dirty} onClick={() => { setDraft(applied); setCompare(null); }} title="Deshace lo que no se ha aplicado">
            <i className="fa-solid fa-xmark" /> Cancelar
          </button>
          <button type="button" className="action action-ghost" disabled={busy} onClick={restore} title="Quita los cambios temporales del vehículo">
            <i className="fa-solid fa-rotate-left" /> Restablecer
          </button>
        </div>
        <button type="button" className="action action-outline" onClick={onHide} title="Oculta el editor sin perder los cambios para probar el coche">
          <i className="fa-solid fa-road" /> Probar conduciendo
        </button>
      </aside>

      {saving && (
        <div className="modal-back">
          <div className="modal">
            <h2>Guardar perfil</h2>
            <label className="field">
              Nombre
              <input className="input" autoFocus value={saving.name} maxLength={64} onChange={(event) => setSaving({ ...saving, name: event.target.value })} />
            </label>
            {source?.profile?.canEdit && (
              <div className="segmented">
                <button type="button" className={!saving.asNew ? 'segmented-on' : ''} onClick={() => setSaving({ ...saving, asNew: false })}>
                  Actualizar «{source.profile.name}»
                </button>
                <button type="button" className={saving.asNew ? 'segmented-on' : ''} onClick={() => setSaving({ ...saving, asNew: true })}>
                  Guardar como nuevo
                </button>
              </div>
            )}
            {rules.panel && (
              <button type="button" className={`toggle ${saving.global ? 'toggle-on' : ''}`} aria-pressed={saving.global} onClick={() => setSaving({ ...saving, global: !saving.global })}>
                <i className={`fa-solid ${saving.global ? 'fa-toggle-on' : 'fa-toggle-off'}`} /> Global: lo pueden cargar todos los que usen el editor
              </button>
            )}
            <p className="muted small">
              Se guardan {Object.keys(draftDiff).length} valores para el modelo {message.vehicle?.modelName ?? ''}. Guardar no lo aplica a nadie: para eso, instálalo en el vehículo o ponlo de serie desde Perfiles.
            </p>
            <div className="actions">
              <button type="button" className="action" disabled={busy || !saving.name.trim()} onClick={save}>
                <i className="fa-solid fa-floppy-disk" /> Guardar
              </button>
              <button type="button" className="action action-ghost" onClick={() => setSaving(null)}>
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
