import { useCallback, useEffect, useState } from 'react';
import { fetchNui, isBrowser } from './nui';
import { ClothesSection, FaceSection, HeadBlendSection, OverlaysSection, PedSection, PropsSection, TattoosSection } from './sections';
import type { Appearance, ComponentSettings, Config, HairSettings, Locales, PropSettings, Settings, Tattoo, Tattoos } from './types';

type BodyPart = 'head' | 'body' | 'bottom';
type SectionId = 'ped' | 'headBlend' | 'faceFeatures' | 'headOverlays' | 'components' | 'props' | 'tattoos';

const NO_PARTS: Record<BodyPart, boolean> = { head: false, body: false, bottom: false };
const NO_ROTATION = { left: false, right: false };

const SECTION_ICONS: Record<SectionId, string> = {
  ped: 'fa-person',
  headBlend: 'fa-dna',
  faceFeatures: 'fa-face-smile',
  headOverlays: 'fa-scissors',
  components: 'fa-shirt',
  props: 'fa-glasses',
  tattoos: 'fa-dragon',
};

const CAMERAS: [BodyPart, string, string][] = [
  ['head', 'Cabeza', 'fa-user'],
  ['body', 'Torso', 'fa-person'],
  ['bottom', 'Piernas', 'fa-person-walking'],
];

const CLOTHES: [BodyPart, string, string][] = [
  ['head', 'Cabeza', 'fa-hat-cowboy'],
  ['body', 'Torso', 'fa-shirt'],
  ['bottom', 'Piernas', 'fa-socks'],
];

// Lua envía las tablas vacías como lista aunque aquí se usen como objeto
const normalize = (appearance: Appearance): Appearance => ({
  ...appearance,
  tattoos: Array.isArray(appearance.tattoos) ? {} : appearance.tattoos ?? {},
});

export function App() {
  const [visible, setVisible] = useState(false);
  const [locales, setLocales] = useState<Locales>();
  const [config, setConfig] = useState<Config>();
  const [settings, setSettings] = useState<Settings>();
  const [data, setData] = useState<Appearance>();
  const [stored, setStored] = useState<Appearance>();
  const [section, setSection] = useState<SectionId>('components');
  const [camera, setCamera] = useState(NO_PARTS);
  const [rotation, setRotation] = useState(NO_ROTATION);
  const [removed, setRemoved] = useState(NO_PARTS);
  const [dialog, setDialog] = useState<'save' | 'exit' | null>(null);

  const load = useCallback(async (asynchronous: boolean) => {
    const getLocales = fetchNui<Locales>('appearance_get_locales').then((result) => {
      if (result) setLocales(result);
    });
    const getSettings = fetchNui<{ appearanceSettings: Settings }>('appearance_get_settings').then((result) => {
      if (result) setSettings(result.appearanceSettings);
    });
    const getData = async () => {
      const result = await fetchNui<{ config: Config; appearanceData: Appearance }>('appearance_get_data');
      if (!result) return;
      const appearance = normalize(result.appearanceData);
      setConfig(result.config);
      setStored(appearance);
      setData(appearance);
    };

    // Con Config.AsynchronousLoading los datos del personaje esperan a los ajustes
    if (asynchronous) {
      await getSettings;
      await getData();
    } else {
      await getData();
    }
    await getLocales;
  }, []);

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const { type, payload } = event.data ?? {};
      if (type === 'appearance_display') {
        setVisible(true);
        load(Boolean(payload?.asynchronous));
      } else if (type === 'appearance_hide') {
        setVisible(false);
        setConfig(undefined);
        setData(undefined);
        setStored(undefined);
        setCamera(NO_PARTS);
        setRotation(NO_ROTATION);
        setRemoved(NO_PARTS);
        setDialog(null);
      }
    };
    window.addEventListener('message', onMessage);
    if (isBrowser) {
      setVisible(true);
      load(false);
    }
    return () => window.removeEventListener('message', onMessage);
  }, [load]);

  useEffect(() => {
    if (!visible) return;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setDialog(null);
        return;
      }
      // Escribiendo en un buscador, la a y la d son letras
      const target = event.target;
      if (target instanceof HTMLInputElement && target.type !== 'range') return;
      if (event.key === 'd') fetchNui('rotate_right');
      else if (event.key === 'a') fetchNui('rotate_left');
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [visible]);

  if (!visible || !config || !settings || !data || !stored || !locales) return isBrowser ? <div className="preview" /> : null;

  const freemode = data.model === 'mp_m_freemode_01' || data.model === 'mp_f_freemode_01';
  const male = data.model === 'mp_m_freemode_01';

  const sections: { id: SectionId; title: string }[] = [];
  if (config.ped) sections.push({ id: 'ped', title: locales.ped.title });
  if (freemode && config.headBlend) sections.push({ id: 'headBlend', title: locales.headBlend.title });
  if (freemode && config.faceFeatures) sections.push({ id: 'faceFeatures', title: locales.faceFeatures.title });
  if (config.headOverlays) sections.push({ id: 'headOverlays', title: locales.headOverlays.title });
  if (config.components) sections.push({ id: 'components', title: locales.components.title });
  if (config.props) sections.push({ id: 'props', title: locales.props.title });
  if (freemode && config.tattoos) sections.push({ id: 'tattoos', title: locales.tattoos.title });

  // Las tiendas abren solo una parte: barbería, ropa o tatuajes
  const active = sections.find((item) => item.id === section) ?? sections[0];

  const common = { settings, data, stored, locales };

  const changeModel = async (model: string) => {
    const result = await fetchNui<{ appearanceSettings: Settings; appearanceData: Appearance }>('appearance_change_model', model);
    if (!result) return;
    setSettings(result.appearanceSettings);
    setData(normalize(result.appearanceData));
  };

  const changeHeadBlend = (key: string, value: number) => {
    const headBlend = { ...data.headBlend, [key]: value };
    setData({ ...data, headBlend });
    fetchNui('appearance_change_head_blend', headBlend);
  };

  const changeFace = (key: string, value: number) => {
    const faceFeatures = { ...data.faceFeatures, [key]: value };
    setData({ ...data, faceFeatures });
    fetchNui('appearance_change_face_feature', faceFeatures);
  };

  const changeHair = async (key: string, value: number) => {
    const hair = { ...data.hair, [key]: value };
    setData({ ...data, hair });
    const result = await fetchNui<HairSettings>('appearance_change_hair', hair);
    if (result) setSettings((current) => current && { ...current, hair: result });
  };

  const changeOverlay = (overlay: string, key: string, value: number) => {
    const headOverlays = { ...data.headOverlays, [overlay]: { ...data.headOverlays[overlay], [key]: value } };
    setData({ ...data, headOverlays });
    fetchNui('appearance_change_head_overlay', headOverlays);
  };

  const changeEyeColor = (value: number) => {
    setData({ ...data, eyeColor: value });
    fetchNui('appearance_change_eye_color', value);
  };

  const changeFade = async (index: number) => {
    const fade = settings.tattoos.items.ZONE_HAIR?.[index];
    if (!fade) return;
    const tattoos: Tattoos = { ...data.tattoos, ZONE_HAIR: [fade] };
    await fetchNui('appearance_apply_tattoo', tattoos);
    setData({ ...data, tattoos });
  };

  // Cambiar de prenda vuelve a la primera textura, porque cada prenda tiene las suyas
  const changeComponent = async (id: number, change: { drawable?: number; texture?: number }) => {
    const current = data.components.find((item) => item.component_id === id);
    if (!current) return;
    const next = { ...current, ...change };
    setData({ ...data, components: data.components.map((item) => (item.component_id === id ? next : item)) });
    const result = await fetchNui<ComponentSettings>('appearance_change_component', next);
    if (result) setSettings((value) => value && { ...value, components: value.components.map((item) => (item.component_id === id ? result : item)) });
  };

  const changeProp = async (id: number, change: { drawable?: number; texture?: number }) => {
    const current = data.props.find((item) => item.prop_id === id);
    if (!current) return;
    const next = { ...current, ...change };
    setData({ ...data, props: data.props.map((item) => (item.prop_id === id ? next : item)) });
    const result = await fetchNui<PropSettings>('appearance_change_prop', next);
    if (result) setSettings((value) => value && { ...value, props: value.props.map((item) => (item.prop_id === id ? result : item)) });
  };

  const applyTattoo = async (tattoo: Tattoo, opacity: number) => {
    const withOpacity = { ...tattoo, opacity };
    const tattoos: Tattoos = { ...data.tattoos, [tattoo.zone]: [...(data.tattoos[tattoo.zone] ?? []), withOpacity] };
    // El servidor cobra el tatuaje: si no le llega el dinero, no se pone
    const paid = await fetchNui<boolean>('appearance_apply_tattoo', { tattoo: withOpacity, updatedTattoos: tattoos });
    if (paid) setData({ ...data, tattoos });
  };

  const previewTattoo = (tattoo: Tattoo, opacity: number) => {
    fetchNui('appearance_preview_tattoo', { data: data.tattoos, tattoo: { ...tattoo, opacity } });
  };

  const deleteTattoo = async (tattoo: Tattoo) => {
    const tattoos: Tattoos = { ...data.tattoos, [tattoo.zone]: (data.tattoos[tattoo.zone] ?? []).filter((item) => item.name !== tattoo.name) };
    await fetchNui('appearance_delete_tattoo', tattoos);
    setData({ ...data, tattoos });
  };

  const clearTattoos = async () => {
    const tattoos: Tattoos = {};
    for (const zone of Object.keys(data.tattoos)) {
      tattoos[zone] = zone === 'ZONE_HAIR' ? data.tattoos[zone] : [];
    }
    await fetchNui('appearance_delete_tattoo', tattoos);
    setData({ ...data, tattoos });
  };

  const toggleCamera = (part: BodyPart) => {
    const wasActive = camera[part];
    setCamera({ ...NO_PARTS, [part]: !wasActive });
    setRotation(NO_ROTATION);
    fetchNui('appearance_set_camera', wasActive ? 'default' : part);
  };

  const toggleRotation = (side: 'left' | 'right') => {
    const wasActive = rotation[side];
    setRotation({ ...NO_ROTATION, [side]: !wasActive });
    if (wasActive) fetchNui('appearance_set_camera', 'current');
    else fetchNui('appearance_rotate_camera', side);
  };

  const toggleClothes = (part: BodyPart) => {
    const wasRemoved = removed[part];
    setRemoved({ ...removed, [part]: !wasRemoved });
    if (wasRemoved) fetchNui('appearance_wear_clothes', { data, key: part });
    else fetchNui('appearance_remove_clothes', part);
  };

  const confirm = async () => {
    if (dialog === 'save') await fetchNui('appearance_save', data);
    else if (dialog === 'exit') await fetchNui('appearance_exit');
    setDialog(null);
  };

  const texts = dialog ? locales.modal[dialog] : null;

  return (
    <div className={isBrowser ? 'preview' : undefined}>
      <div className="layout">
        {sections.length > 1 && (
          <nav className="rail" aria-label="Secciones">
            {sections.map((item) => (
              <button type="button" key={item.id} className={`rail-item ${active?.id === item.id ? 'rail-item-active' : ''}`} aria-pressed={active?.id === item.id} onClick={() => setSection(item.id)}>
                <i className={`fa-solid ${SECTION_ICONS[item.id]}`} />
                <span>{item.title}</span>
              </button>
            ))}
          </nav>
        )}

        <main className="panel">
          <header className="panel-head">
            <img className="logo" src="./logo.webp" alt="Atlantis Roleplay" />
            <div className="panel-title">
              <small>Personaje</small>
              <h1>{active?.title}</h1>
            </div>
          </header>

          <div className="panel-body" key={`${active?.id}-${data.model}`}>
            {active?.id === 'ped' && <PedSection {...common} onModel={changeModel} />}
            {active?.id === 'headBlend' && <HeadBlendSection {...common} onChange={changeHeadBlend} />}
            {active?.id === 'faceFeatures' && <FaceSection {...common} onChange={changeFace} />}
            {active?.id === 'headOverlays' && <OverlaysSection {...common} freemode={freemode} automaticFade={config.automaticFade} onHair={changeHair} onOverlay={changeOverlay} onEyeColor={changeEyeColor} onFade={changeFade} />}
            {active?.id === 'components' && <ClothesSection {...common} config={config} freemode={freemode} onDrawable={(id, value) => changeComponent(id, { drawable: value, texture: 0 })} onTexture={(id, value) => changeComponent(id, { texture: value })} />}
            {active?.id === 'props' && <PropsSection {...common} config={config} onDrawable={(id, value) => changeProp(id, { drawable: value, texture: 0 })} onTexture={(id, value) => changeProp(id, { texture: value })} />}
            {active?.id === 'tattoos' && <TattoosSection {...common} male={male} onApply={applyTattoo} onPreview={previewTattoo} onDelete={deleteTattoo} onClear={clearTattoos} />}
          </div>

          <footer className="panel-foot">
            <button type="button" className="action" onClick={() => setDialog('save')}>
              <i className="fa-solid fa-floppy-disk" /> {locales.modal.save.title}
            </button>
            {config.enableExit && (
              <button type="button" className="action action-ghost action-icon" aria-label={locales.modal.exit.title} title={locales.modal.exit.title} onClick={() => setDialog('exit')}>
                <i className="fa-solid fa-xmark" />
              </button>
            )}
          </footer>
        </main>

        <aside className="tools">
          <div className="tool-group">
            <h2>Cámara</h2>
            {CAMERAS.map(([part, label, icon]) => (
              <button type="button" key={part} className={`tool ${camera[part] ? 'tool-active' : ''}`} aria-pressed={camera[part]} onClick={() => toggleCamera(part)}>
                <i className={`fa-solid ${icon}`} />
                <span>{label}</span>
              </button>
            ))}
          </div>

          <div className="tool-group">
            <h2>Girar</h2>
            <button type="button" className={`tool ${rotation.left ? 'tool-active' : ''}`} aria-pressed={rotation.left} onClick={() => toggleRotation('left')}>
              <i className="fa-solid fa-rotate-left" />
              <span>Izquierda</span>
            </button>
            <button type="button" className={`tool ${rotation.right ? 'tool-active' : ''}`} aria-pressed={rotation.right} onClick={() => toggleRotation('right')}>
              <i className="fa-solid fa-rotate-right" />
              <span>Derecha</span>
            </button>
            <button type="button" className="tool" onClick={() => fetchNui('appearance_turn_around')}>
              <i className="fa-solid fa-arrows-rotate" />
              <span>Dar la vuelta</span>
            </button>
          </div>

          <div className="tool-group">
            <h2>Quitar ropa</h2>
            {CLOTHES.map(([part, label, icon]) => (
              <button type="button" key={part} className={`tool ${removed[part] ? 'tool-active' : ''}`} aria-pressed={removed[part]} onClick={() => toggleClothes(part)}>
                <i className={`fa-solid ${icon}`} />
                <span>{label}</span>
              </button>
            ))}
          </div>

          <p className="tools-hint">
            <kbd>A</kbd> <kbd>D</kbd> giran al personaje
          </p>
        </aside>
      </div>

      {texts && (
        <div className="dialog-back" role="dialog" aria-modal="true" aria-labelledby="dialog-title">
          <div className="dialog">
            <h2 id="dialog-title">{texts.title}</h2>
            <p>{texts.description}</p>
            <div className="dialog-actions">
              <button type="button" className="action" onClick={confirm}>
                {locales.modal.accept}
              </button>
              <button type="button" className="action action-ghost" onClick={() => setDialog(null)}>
                {locales.modal.decline}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
