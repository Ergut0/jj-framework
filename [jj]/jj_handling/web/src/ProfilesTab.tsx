import { useEffect, useMemo, useState } from 'react';
import type { Call, Flash } from './App';
import { NumberField } from './EditorTab';
import { CLASS_NAMES, fetchNui, formatDate, formatValue, normalizeProfile, toList, toValues, type HistoryEntry, type OpenMessage, type Profile, type Values, type VehicleState } from './nui';

interface Props {
  message: OpenMessage;
  profiles: Profile[];
  call: Call;
  flash: (text: string, kind?: Flash['kind']) => void;
  onState: (state: VehicleState) => void;
  onProfiles: (profiles: Profile[]) => void;
  onLoad: (profile: Profile) => void;
}

type Scope = 'model' | 'all' | 'mine' | 'global' | 'default';

interface Draft {
  id?: number;
  version?: number;
  name: string;
  modelName: string;
  class: number;
  global: boolean;
  params: Values;
}

const SCOPES: { id: Scope; label: string }[] = [
  { id: 'model', label: 'Este vehículo' },
  { id: 'all', label: 'Todos' },
  { id: 'mine', label: 'Míos' },
  { id: 'global', label: 'Globales' },
  { id: 'default', label: 'De serie' },
];

export function ProfilesTab({ message, profiles, call, flash, onState, onProfiles, onLoad }: Props) {
  const { data, parameters, vehicle } = message;
  const rules = data.rules;
  const original = message.original;
  const byKey = useMemo(() => Object.fromEntries(parameters.map((param) => [param.key, param])), [parameters]);

  const [scope, setScope] = useState<Scope>(vehicle ? 'model' : 'all');
  const [search, setSearch] = useState('');
  const [results, setResults] = useState<Profile[]>(profiles);
  const [selectedId, setSelectedId] = useState<number | null>(profiles[0]?.id ?? null);
  const [detail, setDetail] = useState<Profile | null>(null);
  const [history, setHistory] = useState<HistoryEntry[] | null>(null);
  const [exported, setExported] = useState<string | null>(null);
  const [importing, setImporting] = useState<string | null>(null);
  const [editing, setEditing] = useState<Draft | null>(null);
  const [confirm, setConfirm] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  // Lista: los del modelo ya están cargados; el resto se busca en el servidor
  useEffect(() => {
    if (scope === 'model') {
      const text = search.trim().toLowerCase();
      setResults(profiles.filter((profile) => !text || `${profile.name} ${profile.authorName ?? ''}`.toLowerCase().includes(text)));
      return;
    }
    const timer = window.setTimeout(async () => {
      const result = await call<{ profiles: Profile[] }>('search', { search, scope }, () => ({
        profiles: profiles.filter((profile) => (scope === 'mine' ? profile.own : scope === 'global' ? profile.global : scope === 'default' ? profile.modelDefault : true)),
      }));
      if (result) setResults(toList<Profile>(result.profiles).map(normalizeProfile));
    }, 250);
    return () => window.clearTimeout(timer);
  }, [scope, search, profiles, call]);

  // Detalle con los valores
  useEffect(() => {
    setHistory(null);
    setExported(null);
    setConfirm(null);
    if (selectedId === null) return setDetail(null);
    const local = [...profiles, ...results].find((profile) => profile.id === selectedId && profile.params);
    if (local) return setDetail(local);
    call<{ profile: Profile }>('get', { id: selectedId }).then((result) => {
      if (result) setDetail(normalizeProfile(result.profile));
    });
  }, [selectedId, profiles, results, call]);

  const sameModel = Boolean(detail && data.vehicle && detail.modelHash === data.vehicle.modelHash);
  const installedHere = Boolean(detail && data.vehicle?.plate && detail.plates.includes(data.vehicle.plate));

  // Mantiene la lista del modelo al día con lo que devuelve el servidor
  const replace = (profile: Profile) => {
    const normalized = normalizeProfile(profile);
    if (data.vehicle && normalized.modelHash === data.vehicle.modelHash) {
      onProfiles([normalized, ...profiles.filter((item) => item.id !== normalized.id)]);
    }
    setResults((list) => [normalized, ...list.filter((item) => item.id !== normalized.id)]);
    setSelectedId(normalized.id);
    setDetail(normalized);
  };

  const run = async <T,>(name: string, payload: unknown, mock: () => T) => {
    if (busy) return undefined;
    setBusy(true);
    setConfirm(null);
    const result = await call<T>(name, payload, mock);
    setBusy(false);
    return result;
  };

  const confirmed = (key: string) => {
    if (confirm === key) return true;
    setConfirm(key);
    return false;
  };

  const duplicate = async () => {
    if (!detail) return;
    const result = await run<{ profile: Profile }>('duplicate', { id: detail.id }, () => ({ profile: { ...detail, id: Date.now(), name: `${detail.name} (copia)`, own: true, global: false, modelDefault: false, plates: [], version: 1 } }));
    if (result) {
      replace(result.profile);
      flash('Perfil duplicado', 'success');
    }
  };

  const remove = async () => {
    if (!detail || !confirmed('delete')) return;
    const result = await run('delete', { id: detail.id }, () => ({ ok: true }));
    if (!result) return;
    onProfiles(profiles.filter((profile) => profile.id !== detail.id));
    setResults((list) => list.filter((profile) => profile.id !== detail.id));
    setSelectedId(null);
    flash('Perfil borrado', 'success');
  };

  const toggleDefault = async () => {
    if (!detail) return;
    const result = await run<{ profile: Profile; state?: VehicleState }>('setModelDefault', { id: detail.id, enabled: !detail.modelDefault }, () => ({ profile: { ...detail, modelDefault: !detail.modelDefault } }));
    if (!result) return;
    if (result.profile) replace(result.profile);
    if (result.state) onState(result.state);
    flash(detail.modelDefault ? 'El modelo vuelve a su handling original' : 'Ahora es el handling de serie del modelo', 'success');
  };

  const install = async (enable: boolean) => {
    if (!detail) return;
    const result = await run<{ state: VehicleState }>(enable ? 'install' : 'uninstall', { id: detail.id }, () => ({ state: { autoApply: true, persistent: enable ? { id: detail.id, name: detail.name, source: 'install' } : undefined } }));
    if (!result) return;
    onState(result.state);
    const plate = data.vehicle?.plate ?? '';
    replace({ ...detail, plates: enable ? [...detail.plates.filter((item) => item !== plate), plate] : detail.plates.filter((item) => item !== plate) });
    flash(enable ? 'Instalado en el vehículo' : 'Quitado del vehículo', 'success');
  };

  const showHistory = async () => {
    if (!detail) return;
    const result = await run<{ history: HistoryEntry[] }>('history', { id: detail.id }, () => ({ history: [{ id: 1, version: detail.version - 1, name: detail.name, params: { fInitialDriveForce: 0.34 }, editedBy: 'Josete', createdAt: Date.now() / 1000 - 7200 }] }));
    if (result) setHistory(toList<HistoryEntry>(result.history).map((entry) => ({ ...entry, params: toValues(entry.params) })));
  };

  const revert = async (entry: HistoryEntry) => {
    if (!detail) return;
    const result = await run<{ profile: Profile }>('revert', { id: detail.id, historyId: entry.id, version: detail.version }, () => ({ profile: { ...detail, params: entry.params, version: detail.version + 1 } }));
    if (result) {
      replace(result.profile);
      flash(`Restaurada la versión ${entry.version}`, 'success');
    }
  };

  const exportProfile = async () => {
    if (!detail) return;
    const result = await run<{ json: string }>('export', { id: detail.id }, () => ({ json: JSON.stringify({ format: 'jj_handling', version: 1, name: detail.name, model: detail.modelName, params: detail.params }) }));
    if (result) setExported(result.json);
  };

  const importProfile = async () => {
    if (importing === null) return;
    const result = await run<{ profile: Profile }>('import', { json: importing }, () => {
      const parsed = JSON.parse(importing);
      return { profile: { id: Date.now(), name: parsed.name, modelHash: 0, modelName: parsed.model, global: false, own: true, version: 1, createdAt: Date.now() / 1000, updatedAt: Date.now() / 1000, paramCount: Object.keys(parsed.params ?? {}).length, params: parsed.params, modelDefault: false, plates: [], canEdit: true, canDelete: true } };
    });
    if (result) {
      replace(result.profile);
      setImporting(null);
      flash('Perfil importado', 'success');
    }
  };

  const saveEditing = async () => {
    if (!editing) return;
    const payload = editing.id
      ? { id: editing.id, version: editing.version, name: editing.name, params: editing.params, global: editing.global, preset: detail?.preset }
      : { name: editing.name, modelName: editing.modelName, class: editing.class, params: editing.params, global: editing.global };
    const result = await run<{ profile: Profile }>('save', payload, () => ({
      profile: { ...(detail ?? { modelHash: 0, own: true, createdAt: Date.now() / 1000, modelDefault: false, plates: [], canEdit: true, canDelete: true, version: 0 }), id: editing.id ?? Date.now(), name: editing.name, modelName: detail?.modelName ?? editing.modelName, global: editing.global, params: editing.params, paramCount: Object.keys(editing.params).length, version: (editing.version ?? 0) + 1, updatedAt: Date.now() / 1000 } as Profile,
    }));
    if (result) {
      replace(result.profile);
      setEditing(null);
      flash('Perfil guardado', 'success');
    }
  };

  const copy = (text: string) => {
    fetchNui('copy', { text });
    navigator.clipboard?.writeText(text).catch(() => undefined);
    flash('Copiado al portapapeles', 'success');
  };

  const params = detail?.params ?? {};

  return (
    <div className="library">
      <aside className="list">
        <div className="scopes">
          {SCOPES.filter((item) => (item.id !== 'model' || vehicle) && (rules.panel || item.id === 'model' || item.id === 'mine' || item.id === 'global')).map((item) => (
            <button type="button" key={item.id} className={`scope ${scope === item.id ? 'scope-active' : ''}`} onClick={() => setScope(item.id)}>
              {item.label}
            </button>
          ))}
        </div>
        <input className="input" value={search} placeholder="Buscar por nombre, modelo o autor" aria-label="Buscar perfiles" onChange={(event) => setSearch(event.target.value)} />
        <div className="list-items">
          {results.map((profile) => (
            <button type="button" key={profile.id} className={`item ${selectedId === profile.id ? 'item-active' : ''}`} onClick={() => setSelectedId(profile.id)}>
              <span className="item-text">
                <strong>{profile.name}</strong>
                <small>
                  {profile.modelName ?? profile.modelHash} · {profile.paramCount} valores · {profile.authorName ?? '—'}
                </small>
              </span>
              <span className="item-tags">
                {profile.modelDefault && <i className="fa-solid fa-industry" title="De serie para el modelo" />}
                {profile.plates.length > 0 && <i className="fa-solid fa-screwdriver-wrench" title={`Instalado en ${profile.plates.join(', ')}`} />}
                {profile.global && <i className="fa-solid fa-globe" title="Global" />}
              </span>
            </button>
          ))}
          {results.length === 0 && <p className="empty">No hay perfiles.</p>}
        </div>
        <div className="actions">
          {rules.panel && (
            <button type="button" className="action action-ghost action-small" onClick={() => { setSelectedId(null); setEditing({ name: '', modelName: data.vehicle?.modelName ?? '', class: data.vehicle?.class ?? 0, global: true, params: {} }); }}>
              <i className="fa-solid fa-plus" /> Nuevo
            </button>
          )}
          {rules.import && (
            <button type="button" className="action action-ghost action-small" onClick={() => setImporting('')}>
              <i className="fa-solid fa-file-import" /> Importar
            </button>
          )}
        </div>
      </aside>

      <section className="detail">
        {editing ? (
          <ProfileEditor draft={editing} creating={!editing.id} parameters={parameters} limits={data.limits} rules={rules} onChange={setEditing} onCancel={() => setEditing(null)} onSave={saveEditing} busy={busy} />
        ) : detail ? (
          <>
            <div className="detail-head">
              <div>
                <small>
                  Perfil #{detail.id} · versión {detail.version}
                </small>
                <h2>{detail.name}</h2>
                <div className="tags">
                  <span className="tag">
                    <i className="fa-solid fa-car" /> {detail.modelName ?? detail.modelHash}
                  </span>
                  {detail.class !== undefined && detail.class !== null && <span className="tag">{CLASS_NAMES[detail.class] ?? `Clase ${detail.class}`}</span>}
                  {detail.global && (
                    <span className="tag tag-accent">
                      <i className="fa-solid fa-globe" /> Global
                    </span>
                  )}
                  {detail.modelDefault && (
                    <span className="tag tag-good">
                      <i className="fa-solid fa-industry" /> De serie
                    </span>
                  )}
                  {detail.plates.map((plate) => (
                    <span key={plate} className="tag tag-good">
                      <i className="fa-solid fa-screwdriver-wrench" /> {plate}
                    </span>
                  ))}
                </div>
              </div>
              <div className="meta">
                <span>Autor: {detail.authorName ?? '—'}</span>
                <span>Creado: {formatDate(detail.createdAt)}</span>
                <span>Modificado: {formatDate(detail.updatedAt)}</span>
              </div>
            </div>

            <div className="detail-actions">
              {sameModel && (
                <button type="button" className="action action-small" onClick={() => onLoad(detail)}>
                  <i className="fa-solid fa-sliders" /> Cargar en el editor
                </button>
              )}
              {sameModel && rules.install && data.vehicle?.plate && (
                <button type="button" className="action action-ghost action-small" disabled={busy} onClick={() => install(!installedHere)}>
                  <i className="fa-solid fa-screwdriver-wrench" /> {installedHere ? 'Quitar de este vehículo' : 'Instalar en este vehículo'}
                </button>
              )}
              {rules.modelDefault && (
                <button type="button" className="action action-ghost action-small" disabled={busy} onClick={toggleDefault}>
                  <i className="fa-solid fa-industry" /> {detail.modelDefault ? 'Quitar de serie' : 'Poner de serie'}
                </button>
              )}
              {detail.canEdit && (
                <button type="button" className="action action-ghost action-small" onClick={() => setEditing({ id: detail.id, version: detail.version, name: detail.name, modelName: detail.modelName ?? '', class: detail.class ?? 0, global: detail.global, params: { ...params } })}>
                  <i className="fa-solid fa-pen" /> Editar valores
                </button>
              )}
              {rules.saveProfiles && (
                <button type="button" className="action action-ghost action-small" disabled={busy} onClick={duplicate}>
                  <i className="fa-solid fa-clone" /> Duplicar
                </button>
              )}
              {rules.export && (
                <button type="button" className="action action-ghost action-small" disabled={busy} onClick={exportProfile}>
                  <i className="fa-solid fa-file-export" /> Exportar
                </button>
              )}
              <button type="button" className="action action-ghost action-small" disabled={busy} onClick={showHistory}>
                <i className="fa-solid fa-clock-rotate-left" /> Historial
              </button>
              {detail.canDelete && (
                <button type="button" className="action action-danger action-small" disabled={busy} onClick={remove}>
                  <i className="fa-solid fa-trash" /> {confirm === 'delete' ? 'Pulsa otra vez' : 'Borrar'}
                </button>
              )}
            </div>

            {exported !== null && (
              <div className="card">
                <h3>JSON para compartir</h3>
                <textarea className="input textarea" readOnly value={exported} onFocus={(event) => event.target.select()} />
                <div className="actions">
                  <button type="button" className="action action-small" onClick={() => copy(exported)}>
                    <i className="fa-solid fa-copy" /> Copiar
                  </button>
                  <button type="button" className="action action-ghost action-small" onClick={() => setExported(null)}>
                    Cerrar
                  </button>
                </div>
              </div>
            )}

            {history !== null && (
              <div className="card">
                <h3>Versiones anteriores</h3>
                {history.length === 0 && <p className="empty">Todavía no tiene versiones anteriores.</p>}
                {history.map((entry) => (
                  <div key={entry.id} className="history-row">
                    <span>
                      <strong>v{entry.version}</strong> · {entry.name} · {Object.keys(entry.params).length} valores
                    </span>
                    <span className="muted">
                      {entry.editedBy ?? '—'} · {formatDate(entry.createdAt)}
                    </span>
                    {detail.canEdit && (
                      <button type="button" className="action action-ghost action-small" disabled={busy} onClick={() => revert(entry)}>
                        <i className="fa-solid fa-rotate-left" /> Restaurar
                      </button>
                    )}
                  </div>
                ))}
              </div>
            )}

            <div className="values-table">
              <div className="values-row values-head">
                <span>Parámetro</span>
                <span>Valor</span>
                {sameModel && original && <span>Serie</span>}
                {sameModel && original && <span>Cambio</span>}
              </div>
              {Object.entries(params)
                .sort(([a], [b]) => parameters.findIndex((param) => param.key === a) - parameters.findIndex((param) => param.key === b))
                .map(([key, value]) => {
                  const param = byKey[key];
                  const base = original?.[key];
                  const delta = base ? ((value - base) / Math.abs(base)) * 100 : null;
                  return (
                    <div key={key} className="values-row">
                      <span>
                        {param?.label ?? key} <code>{key}</code>
                      </span>
                      <strong>
                        {formatValue(value, param?.step ?? 0.01)} {param?.unit ?? ''}
                      </strong>
                      {sameModel && original && <span className="muted">{formatValue(base, param?.step ?? 0.01)}</span>}
                      {sameModel && original && <span className={`delta ${delta === null ? '' : delta >= 0 ? 'delta-up' : 'delta-down'}`}>{delta === null ? '—' : `${delta >= 0 ? '+' : ''}${delta.toFixed(1)} %`}</span>}
                    </div>
                  );
                })}
            </div>
          </>
        ) : (
          <p className="empty">Elige un perfil de la lista.</p>
        )}
      </section>

      {importing !== null && (
        <div className="modal-back">
          <div className="modal">
            <h2>Importar perfil</h2>
            <p className="muted small">Pega el JSON exportado desde jj_handling. Se comprueban todos los valores antes de guardarlo.</p>
            <textarea className="input textarea" autoFocus value={importing} placeholder='{"format":"jj_handling", ...}' onChange={(event) => setImporting(event.target.value)} />
            <div className="actions">
              <button type="button" className="action" disabled={busy || !importing.trim()} onClick={importProfile}>
                <i className="fa-solid fa-file-import" /> Importar
              </button>
              <button type="button" className="action action-ghost" onClick={() => setImporting(null)}>
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Edición de valores sin vehículo, desde el panel
function ProfileEditor({ draft, creating, parameters, limits, rules, busy, onChange, onCancel, onSave }: {
  draft: Draft;
  creating: boolean;
  parameters: OpenMessage['parameters'];
  limits?: Record<string, { min: number; max: number }>;
  rules: OpenMessage['data']['rules'];
  busy: boolean;
  onChange: (draft: Draft) => void;
  onCancel: () => void;
  onSave: () => void;
}) {
  const [adding, setAdding] = useState('');
  const missing = parameters.filter((param) => draft.params[param.key] === undefined);
  const setParam = (key: string, value: number | undefined) => {
    const params = { ...draft.params };
    if (value === undefined) delete params[key];
    else params[key] = value;
    onChange({ ...draft, params });
  };

  return (
    <div className="profile-editor">
      <h2>{creating ? 'Nuevo perfil' : `Editar «${draft.name}»`}</h2>
      <div className="row">
        <label className="field">
          Nombre
          <input className="input" value={draft.name} maxLength={64} onChange={(event) => onChange({ ...draft, name: event.target.value })} />
        </label>
        {creating && (
          <label className="field">
            Modelo (nombre de spawn)
            <input className="input" value={draft.modelName} maxLength={32} placeholder="sultan" onChange={(event) => onChange({ ...draft, modelName: event.target.value.toLowerCase() })} />
          </label>
        )}
        {creating && (
          <label className="field">
            Clase
            <select className="input" value={draft.class} onChange={(event) => onChange({ ...draft, class: Number(event.target.value) })}>
              {Object.entries(CLASS_NAMES).map(([id, name]) => (
                <option key={id} value={id}>
                  {name}
                </option>
              ))}
            </select>
          </label>
        )}
      </div>
      {rules.panel && (
        <button type="button" className={`toggle ${draft.global ? 'toggle-on' : ''}`} aria-pressed={draft.global} onClick={() => onChange({ ...draft, global: !draft.global })}>
          <i className={`fa-solid ${draft.global ? 'fa-toggle-on' : 'fa-toggle-off'}`} /> Global
        </button>
      )}
      <p className="muted small">Valores en unidades del handling.meta. El servidor comprueba los límites de la clase al guardar.</p>

      <div className="values-table">
        {Object.entries(draft.params).map(([key, value]) => {
          const param = parameters.find((item) => item.key === key);
          const limit = limits?.[key];
          return (
            <div key={key} className="values-row values-edit">
              <span>
                {param?.label ?? key} <code>{key}</code>
              </span>
              <NumberField value={value} step={param?.step ?? 0.01} label={param?.label ?? key} onCommit={(next) => setParam(key, param?.int ? Math.round(next) : next)} />
              <span className="muted">{limit ? `${limit.min} – ${limit.max}` : ''}</span>
              <button type="button" className="icon-button small" aria-label="Quitar" onClick={() => setParam(key, undefined)}>
                <i className="fa-solid fa-xmark" />
              </button>
            </div>
          );
        })}
      </div>
      <div className="plant-row">
        <select className="input" value={adding} aria-label="Añadir parámetro" onChange={(event) => setAdding(event.target.value)}>
          <option value="">Añadir parámetro…</option>
          {missing.map((param) => (
            <option key={param.key} value={param.key}>
              {param.label} ({param.key})
            </option>
          ))}
        </select>
        <button type="button" className="action action-ghost action-small" disabled={!adding} onClick={() => { const param = parameters.find((item) => item.key === adding); setParam(adding, limits?.[adding] ? Number(((limits[adding].min + limits[adding].max) / 2).toFixed(3)) : param?.int ? 5 : 1); setAdding(''); }}>
          <i className="fa-solid fa-plus" /> Añadir
        </button>
      </div>
      <div className="actions">
        <button type="button" className="action" disabled={busy || !draft.name.trim() || (creating && !draft.modelName.trim()) || Object.keys(draft.params).length === 0} onClick={onSave}>
          <i className="fa-solid fa-floppy-disk" /> Guardar
        </button>
        <button type="button" className="action action-ghost" onClick={onCancel}>
          Cancelar
        </button>
      </div>
    </div>
  );
}
