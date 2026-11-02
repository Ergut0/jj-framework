import { useMemo, useState, type ReactNode } from 'react';
import { Groups, Slider, Stepper, Swatches } from './controls';
import type { Appearance, Config, Locales, Settings, Tattoo } from './types';

const MAX_MODELS = 80;

interface Common {
  settings: Settings;
  data: Appearance;
  stored: Appearance;
  locales: Locales;
}

// Modelo

export function PedSection({ settings, data, stored, locales, onModel }: Common & { onModel: (model: string) => void }) {
  const [search, setSearch] = useState('');
  const query = search.trim().toLowerCase();
  const models = settings.ped.model.items.filter((model) => String(model).toLowerCase().includes(query));

  return (
    <section className="group group-open">
      <div className="group-body">
        <div className="control-head">
          <span className="control-title">{locales.ped.model}</span>
          <span className="control-value">{data.model}</span>
        </div>
        <input className="search" value={search} placeholder="Buscar modelo" aria-label="Buscar modelo" onChange={(event) => setSearch(event.target.value)} />
        <div className="choices choices-tall">
          {models.slice(0, MAX_MODELS).map((model) => (
            <button type="button" key={model} className={`choice ${data.model === model ? 'choice-active' : ''}`} aria-pressed={data.model === model} onClick={() => onModel(model)}>
              <span>{model}</span>
              {stored.model === model && <small>Actual</small>}
            </button>
          ))}
          {models.length === 0 && <p className="empty">Ningún modelo coincide.</p>}
          {models.length > MAX_MODELS && <p className="empty">Hay {models.length} modelos. Escribe para encontrar el tuyo.</p>}
        </div>
      </div>
    </section>
  );
}

// Herencia

export function HeadBlendSection({ settings, data, stored, locales, onChange }: Common & { onChange: (key: string, value: number) => void }) {
  const t = locales.headBlend;
  const range = settings.headBlend;
  const blend = data.headBlend;
  const original = stored.headBlend;
  const stepper = (key: string, title: string) => <Stepper title={title} range={range[key]} value={blend[key]} stored={original[key]} onChange={(value) => onChange(key, value)} />;
  const slider = (key: string, title: string) => <Slider title={title} range={range[key]} value={blend[key]} stored={original[key]} onChange={(value) => onChange(key, value)} />;

  return (
    <Groups
      items={[
        {
          key: 'shape',
          title: t.shape.title,
          content: (
            <>
              {stepper('shapeFirst', t.shape.firstOption)}
              {stepper('shapeSecond', t.shape.secondOption)}
              {slider('shapeMix', t.shape.mix)}
            </>
          ),
        },
        {
          key: 'skin',
          title: t.skin.title,
          content: (
            <>
              {stepper('skinFirst', t.skin.firstOption)}
              {stepper('skinSecond', t.skin.secondOption)}
              {slider('skinMix', t.skin.mix)}
            </>
          ),
        },
        {
          key: 'race',
          title: t.race.title,
          content: (
            <>
              {stepper('shapeThird', t.race.shape)}
              {stepper('skinThird', t.race.skin)}
              {slider('thirdMix', t.race.mix)}
            </>
          ),
        },
      ]}
    />
  );
}

// Rasgos de la cara

const FACE_GROUPS: [string, [string, string][]][] = [
  ['nose', [['width', 'noseWidth'], ['height', 'nosePeakHigh'], ['size', 'nosePeakSize'], ['boneHeight', 'noseBoneHigh'], ['peakHeight', 'nosePeakLowering'], ['boneTwist', 'noseBoneTwist']]],
  ['eyebrows', [['height', 'eyeBrownHigh'], ['depth', 'eyeBrownForward']]],
  ['cheeks', [['boneHeight', 'cheeksBoneHigh'], ['boneWidth', 'cheeksBoneWidth'], ['width', 'cheeksWidth']]],
  ['eyesAndMouth', [['eyesOpening', 'eyesOpening'], ['lipsThickness', 'lipsThickness']]],
  ['jaw', [['width', 'jawBoneWidth'], ['size', 'jawBoneBackSize']]],
  ['chin', [['lowering', 'chinBoneLowering'], ['length', 'chinBoneLenght'], ['size', 'chinBoneSize'], ['hole', 'chinHole']]],
  ['neck', [['thickness', 'neckThickness']]],
];

export function FaceSection({ settings, data, stored, locales, onChange }: Common & { onChange: (key: string, value: number) => void }) {
  const t = locales.faceFeatures;
  return (
    <Groups
      items={FACE_GROUPS.map(([group, features]) => ({
        key: group,
        title: t[group].title,
        content: features.map(([label, key]) => <Slider key={key} title={t[group][label]} range={settings.faceFeatures[key]} value={data.faceFeatures[key]} stored={stored.faceFeatures[key]} onChange={(value) => onChange(key, value)} />),
      }))}
    />
  );
}

// Apariencia

// [nombre, tiene color, tiene segundo color], en el orden en que se muestran
const OVERLAY_GROUPS: [string, boolean, boolean][] = [
  ['makeUp', true, true],
  ['blush', true, false],
  ['lipstick', true, false],
  ['beard', true, false],
  ['blemishes', false, false],
  ['ageing', false, false],
  ['complexion', false, false],
  ['sunDamage', false, false],
  ['moleAndFreckles', false, false],
  ['chestHair', true, false],
  ['bodyBlemishes', false, false],
];

interface OverlaysProps extends Common {
  freemode: boolean;
  automaticFade: boolean;
  onHair: (key: string, value: number) => void;
  onOverlay: (overlay: string, key: string, value: number) => void;
  onEyeColor: (value: number) => void;
  onFade: (index: number) => void;
}

export function OverlaysSection({ settings, data, stored, locales, freemode, automaticFade, onHair, onOverlay, onEyeColor, onFade }: OverlaysProps) {
  const t = locales.headOverlays;
  const hair = settings.hair;
  const fades = settings.tattoos.items.ZONE_HAIR ?? [];
  const fadeIndex = (appearance: Appearance) => Math.max(0, fades.findIndex((fade) => fade.name === appearance.tattoos.ZONE_HAIR?.[0]?.name));

  const overlay = (name: string, withColor: boolean, withSecond: boolean): ReactNode => {
    const range = settings.headOverlays[name];
    const value = data.headOverlays[name];
    const original = stored.headOverlays[name];
    return (
      <>
        <Stepper title={t.style} range={range.style} value={value.style} stored={original.style} onChange={(next) => onOverlay(name, 'style', next)} />
        <Slider title={t.opacity} range={range.opacity} value={value.opacity} stored={original.opacity} onChange={(next) => onOverlay(name, 'opacity', next)} />
        {withColor && <Swatches title={t.color} colors={range.color?.items} value={value.color} stored={original.color} onChange={(next) => onOverlay(name, 'color', next)} />}
        {withSecond && <Swatches title={t.secondColor} colors={range.color?.items} value={value.secondColor} stored={original.secondColor} onChange={(next) => onOverlay(name, 'secondColor', next)} />}
      </>
    );
  };

  const items: { key: string; title: string; content: ReactNode }[] = [
    {
      key: 'hair',
      title: t.hair.title,
      content: (
        <>
          <Stepper title={t.hair.style} range={hair.style} value={data.hair.style} stored={stored.hair.style} blacklist={hair.blacklist.drawables} onChange={(value) => onHair('style', value)} />
          <Stepper title={t.hair.texture} range={hair.texture} value={data.hair.texture} stored={stored.hair.texture} blacklist={hair.blacklist.textures} onChange={(value) => onHair('texture', value)} />
          {freemode && (
            <>
              {!automaticFade && fades.length > 0 && <Stepper title={t.hair.fade} range={{ min: 0, max: fades.length - 1 }} value={fadeIndex(data)} stored={fadeIndex(stored)} onChange={onFade} />}
              <Swatches title={t.hair.color} colors={hair.color.items} value={data.hair.color} stored={stored.hair.color} onChange={(value) => onHair('color', value)} />
              <Swatches title={t.hair.highlight} colors={hair.highlight.items} value={data.hair.highlight} stored={stored.hair.highlight} onChange={(value) => onHair('highlight', value)} />
            </>
          )}
        </>
      ),
    },
  ];

  if (freemode) {
    items.push(
      { key: 'eyebrows', title: t.eyebrows, content: overlay('eyebrows', true, false) },
      { key: 'eyeColor', title: t.eyeColor, content: <Stepper title={t.style} range={settings.eyeColor} value={data.eyeColor} stored={stored.eyeColor} onChange={onEyeColor} /> },
      ...OVERLAY_GROUPS.map(([name, withColor, withSecond]) => ({ key: name, title: t[name], content: overlay(name, withColor, withSecond) })),
    );
  }

  return <Groups items={items} />;
}

// Ropa

interface ClothesProps extends Common {
  config: Config;
  freemode: boolean;
  onDrawable: (id: number, value: number) => void;
  onTexture: (id: number, value: number) => void;
}

// [texto, id del componente, opción de Config.DisableComponents], en el orden en que se muestran
const COMPONENT_GROUPS: [string, number, string][] = [
  ['mask', 1, 'masks'],
  ['scarfAndChains', 7, 'scarfAndChains'],
  ['jackets', 11, 'jackets'],
  ['shirt', 8, 'shirts'],
  ['bodyArmor', 9, 'bodyArmor'],
  ['bags', 5, 'bags'],
  ['upperBody', 3, 'upperBody'],
  ['lowerBody', 4, 'lowerBody'],
  ['shoes', 6, 'shoes'],
  ['decals', 10, 'decals'],
];

export function ClothesSection({ settings, data, stored, locales, config, freemode, onDrawable, onTexture }: ClothesProps) {
  const t = locales.components;

  const content = (id: number) => {
    const range = settings.components.find((item) => item.component_id === id);
    const value = data.components.find((item) => item.component_id === id);
    const original = stored.components.find((item) => item.component_id === id);
    if (!range || !value) return null;
    return (
      <>
        <Stepper title={t.drawable} range={range.drawable} value={value.drawable} stored={original?.drawable} blacklist={range.blacklist.drawables} onChange={(next) => onDrawable(id, next)} />
        <Stepper title={t.texture} range={range.texture} value={value.texture} stored={original?.texture} blacklist={range.blacklist.textures} onChange={(next) => onTexture(id, next)} />
      </>
    );
  };

  const items = COMPONENT_GROUPS.filter(([, id, option]) => config.componentConfig[option] && !(id === 7 && config.hasTracker)).map(([label, id]) => ({ key: label, title: t[label], content: content(id) }));
  if (!freemode) items.unshift({ key: 'head', title: t.head, content: content(0) });

  return <Groups items={items} />;
}

// Accesorios

const PROP_GROUPS: [string, number][] = [
  ['hats', 0],
  ['glasses', 1],
  ['ear', 2],
  ['watches', 6],
  ['bracelets', 7],
];

interface PropsProps extends Common {
  config: Config;
  onDrawable: (id: number, value: number) => void;
  onTexture: (id: number, value: number) => void;
}

export function PropsSection({ settings, data, stored, locales, config, onDrawable, onTexture }: PropsProps) {
  const t = locales.props;
  return (
    <Groups
      items={PROP_GROUPS.filter(([name]) => config.propConfig[name]).map(([name, id]) => {
        const range = settings.props.find((item) => item.prop_id === id);
        const value = data.props.find((item) => item.prop_id === id);
        const original = stored.props.find((item) => item.prop_id === id);
        return {
          key: name,
          title: t[name],
          content:
            range && value ? (
              <>
                <Stepper title={t.drawable} range={range.drawable} value={value.drawable} stored={original?.drawable} blacklist={range.blacklist.drawables} onChange={(next) => onDrawable(id, next)} />
                <Stepper title={t.texture} range={range.texture} value={value.texture} stored={original?.texture} blacklist={range.blacklist.textures} onChange={(next) => onTexture(id, next)} />
              </>
            ) : null,
        };
      })}
    />
  );
}

// Tatuajes

interface TattoosProps extends Common {
  male: boolean;
  onApply: (tattoo: Tattoo, opacity: number) => void;
  onPreview: (tattoo: Tattoo, opacity: number) => void;
  onDelete: (tattoo: Tattoo) => void;
  onClear: () => void;
}

export function TattoosSection({ settings, data, locales, male, onApply, onPreview, onDelete, onClear }: TattoosProps) {
  const t = locales.tattoos;

  const zones = useMemo(() => {
    const list: [string, Tattoo[]][] = [];
    for (const [zone, tattoos] of Object.entries(settings.tattoos.items)) {
      if (zone === 'ZONE_HAIR') continue;
      const available = tattoos.filter((tattoo) => (male ? tattoo.hashMale !== '' : tattoo.hashFemale !== ''));
      if (available.length > 0) list.push([zone, available]);
    }
    return list;
  }, [settings.tattoos.items, male]);

  const [zone, setZone] = useState(zones[0]?.[0] ?? '');
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState<Tattoo | null>(null);
  const [opacity, setOpacity] = useState(settings.tattoos.opacity.min);

  const applied = data.tattoos[zone] ?? [];
  const appliedTotal = Object.entries(data.tattoos).reduce((total, [name, list]) => (name === 'ZONE_HAIR' ? total : total + list.length), 0);
  const query = search.trim().toLowerCase();
  const tattoos = (zones.find(([name]) => name === zone)?.[1] ?? []).filter((tattoo) => tattoo.label.toLowerCase().includes(query));
  const isApplied = (tattoo: Tattoo) => applied.some((item) => item.name === tattoo.name);

  const select = (tattoo: Tattoo) => {
    const current = applied.find((item) => item.name === tattoo.name)?.opacity ?? settings.tattoos.opacity.min;
    setSelected(tattoo);
    setOpacity(current);
    onPreview(tattoo, current);
  };

  return (
    <section className="group group-open">
      <div className="group-body">
        <div className="chips">
          {zones.map(([name]) => {
            const count = data.tattoos[name]?.length ?? 0;
            return (
              <button
                type="button"
                key={name}
                className={`chip ${zone === name ? 'chip-active' : ''}`}
                aria-pressed={zone === name}
                onClick={() => {
                  setZone(name);
                  setSelected(null);
                  setSearch('');
                }}
              >
                {t.items[name] ?? name}
                {count > 0 && <small>{count}</small>}
              </button>
            );
          })}
        </div>

        <input className="search" value={search} placeholder="Buscar tatuaje" aria-label="Buscar tatuaje" onChange={(event) => setSearch(event.target.value)} />

        <div className="choices">
          {tattoos.map((tattoo) => (
            <button type="button" key={tattoo.name} className={`choice ${selected?.name === tattoo.name ? 'choice-active' : ''}`} aria-pressed={selected?.name === tattoo.name} onClick={() => select(tattoo)}>
              <span>{tattoo.label}</span>
              {isApplied(tattoo) && <i className="fa-solid fa-check" aria-label="Puesto" />}
            </button>
          ))}
          {tattoos.length === 0 && <p className="empty">Ningún tatuaje coincide.</p>}
        </div>

        <Slider
          title={t.opacity}
          range={settings.tattoos.opacity}
          value={opacity}
          onChange={(value) => {
            setOpacity(value);
            if (selected) onPreview(selected, value);
          }}
        />

        <div className="tattoo-actions">
          {selected && isApplied(selected) ? (
            <button type="button" className="action action-danger" onClick={() => onDelete(selected)}>
              {t.delete}
            </button>
          ) : (
            <button type="button" className="action" disabled={!selected} onClick={() => selected && onApply(selected, opacity)}>
              {t.apply}
            </button>
          )}
          <button type="button" className="action action-ghost" disabled={appliedTotal === 0} onClick={onClear}>
            {t.deleteAll}
          </button>
        </div>
      </div>
    </section>
  );
}
