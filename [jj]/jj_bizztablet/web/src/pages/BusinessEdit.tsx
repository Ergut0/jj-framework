import { useState } from 'react';
import { Modal, NumberInput, Select, TextInput, Textarea } from '@mantine/core';
import { notifications } from '@mantine/notifications';
import { FaDiscord } from 'react-icons/fa6';
import {
  TbCategory,
  TbCheck,
  TbCurrentLocation,
  TbDeviceFloppy,
  TbDiscount,
  TbInfoSquareRounded,
  TbList,
  TbMinus,
  TbPhoto,
  TbPlus,
} from 'react-icons/tb';
import { fetchNui } from '../nui';
import { BackButton, type PageProps } from './common';
import { CATEGORIES, type ActionResult, type CategoryKey, type Coords, type Item, type MenuCategory, type Promotion } from '../types';

let nextKey = 0;
const newId = (prefix: string) => `${prefix}-new-${++nextKey}`;

function ItemsModal({ opened, market, selected, onClose, onConfirm }: { opened: boolean; market: Item[]; selected: Item[]; onClose: () => void; onConfirm: (items: Item[]) => void }) {
  const [current, setCurrent] = useState(selected);
  const [search, setSearch] = useState('');
  const text = search.toLowerCase();
  const visible = market.filter((item) => item.label.toLowerCase().includes(text) || item.name.toLowerCase().includes(text));

  return (
    <Modal opened={opened} onClose={onClose} title="Seleccionar artículos" size="xl" centered classNames={{ content: 'modal', header: 'modal-header' }}>
      <TextInput placeholder="Buscar artículos..." value={search} onChange={(event) => setSearch(event.currentTarget.value)} mb="md" />

      {visible.length === 0 ? (
        <p className="empty">No se encontraron artículos</p>
      ) : (
        <div className="picker-grid">
          {visible.map((item) => {
            const chosen = current.find((c) => c.name === item.name);
            return (
              <div key={item.name} className={`pick-item${chosen ? ' pick-item-on' : ''}`}>
                <img src={item.image} alt="" />
                <div>
                  <strong>{item.label}</strong>
                  {chosen ? (
                    <NumberInput
                      size="xs"
                      prefix="$"
                      min={0}
                      allowDecimal={false}
                      value={chosen.price}
                      aria-label={`Precio de ${item.label}`}
                      onChange={(value) =>
                        setCurrent((list) => list.map((c) => (c.name === item.name ? { ...c, price: Number(value) || 0 } : c)))
                      }
                    />
                  ) : (
                    <small>${item.price}</small>
                  )}
                </div>
                <button
                  type="button"
                  className={`icon-button ${chosen ? 'icon-red' : 'icon-green'}`}
                  aria-label={chosen ? `Quitar ${item.label}` : `Añadir ${item.label}`}
                  onClick={() =>
                    setCurrent((list) => (chosen ? list.filter((c) => c.name !== item.name) : [...list, item]))
                  }
                >
                  {chosen ? <TbMinus size={18} /> : <TbPlus size={18} />}
                </button>
              </div>
            );
          })}
        </div>
      )}

      <footer className="modal-footer">
        <span>{current.length === 1 ? '1 artículo seleccionado' : `${current.length} artículos seleccionados`}</span>
        <div>
          <button type="button" className="action" onClick={onClose}>
            Cancelar
          </button>
          <button
            type="button"
            className="action action-fuchsia"
            onClick={() => {
              onConfirm(current);
              onClose();
            }}
          >
            <TbCheck size={18} /> Confirmar
          </button>
        </div>
      </footer>
    </Modal>
  );
}

export function BusinessEdit({ data, back, job }: PageProps & { job: string }) {
  const business = data.jobs.find((b) => b.name === job);
  const [coords, setCoords] = useState<Coords | null>(business?.coords ?? null);
  const [logo, setLogo] = useState(business?.logo ?? '');
  const [description, setDescription] = useState(business?.description ?? '');
  const [discordUrl, setDiscordUrl] = useState(business?.discordUrl ?? '');
  const [category, setCategory] = useState<CategoryKey | null>(business?.category ?? null);
  const [categories, setCategories] = useState<MenuCategory[]>(() => business?.categories.map((c) => ({ ...c })) ?? []);
  const [promotions, setPromotions] = useState<Promotion[]>(business?.promotions ?? []);
  const [itemsFor, setItemsFor] = useState<string | null>(null);
  const [addingPromotion, setAddingPromotion] = useState(false);
  const [saving, setSaving] = useState(false);

  if (!business) {
    return (
      <section className="page">
        <header className="page-header">
          <BackButton onClick={back} />
        </header>
        <p className="empty">Negocio no encontrado</p>
      </section>
    );
  }

  const editingCategory = categories.find((c) => c.id === itemsFor);
  const market = business.market;

  const patchPromotion = (id: string, field: 'originalPrice' | 'promotionalPrice', value: number) =>
    setPromotions((list) => list.map((p) => (p.id === id ? { ...p, [field]: value } : p)));

  const save = async () => {
    if (promotions.some((p) => p.promotionalPrice >= p.originalPrice)) {
      notifications.show({ color: 'red', message: 'El precio de la promoción tiene que ser menor que el original' });
      return;
    }
    if (categories.some((c) => !c.label.trim())) {
      notifications.show({ color: 'red', message: 'Pon nombre a todas las categorías' });
      return;
    }

    setSaving(true);
    const result = await fetchNui<ActionResult>('business:update', {
      ...business,
      description,
      discordUrl,
      category,
      categories,
      promotions,
      logo,
      coords,
    });
    setSaving(false);

    if (result?.success) {
      notifications.show({ color: 'green', message: 'Negocio actualizado correctamente' });
      back();
    } else {
      notifications.show({ color: 'red', message: result?.error || 'Error al actualizar el negocio' });
    }
  };

  return (
    <section className="page">
      <header className="page-header">
        <BackButton onClick={back} />
        <h1>Editar negocio</h1>
      </header>

      <div className="edit-form">
        <TextInput label="Nombre del negocio" value={business.label} disabled />
        <Textarea
          label={<span className="field-label"><TbInfoSquareRounded size={16} /> Sobre el negocio</span>}
          placeholder="Describe tu negocio..."
          rows={4}
          maxLength={1000}
          value={description}
          onChange={(event) => setDescription(event.currentTarget.value)}
        />
        <TextInput
          label={<span className="field-label"><FaDiscord size={16} /> Enlace de Discord</span>}
          placeholder="https://discord.gg/..."
          value={discordUrl}
          onChange={(event) => setDiscordUrl(event.currentTarget.value)}
        />

        {data.hasPerms && (
          <>
            <Select
              label={<span className="field-label"><TbCategory size={16} /> Categoría del negocio</span>}
              placeholder="Sin categoría"
              clearable
              data={Object.entries(CATEGORIES).map(([value, label]) => ({ value, label }))}
              value={category}
              onChange={(value) => setCategory(value as CategoryKey | null)}
              comboboxProps={{ withinPortal: false }}
            />
            <div className="field">
              <span className="field-label"><TbCurrentLocation size={16} /> Ubicación</span>
              <button
                type="button"
                className="coords-button"
                onClick={async () => {
                  const position = await fetchNui<Coords>('tablet:getCoords');
                  if (position) {
                    setCoords(position);
                    notifications.show({ color: 'green', message: 'Ubicación actualizada' });
                  }
                }}
              >
                <span>
                  {coords ? `x: ${coords.x.toFixed(2)}, y: ${coords.y.toFixed(2)}, z: ${coords.z.toFixed(2)}` : 'Sin ubicación'}
                </span>
                <small>Usar mi posición</small>
              </button>
            </div>
            <TextInput
              label={<span className="field-label"><TbPhoto size={16} /> URL del logo</span>}
              placeholder="https://example.com/logo.png"
              value={logo}
              onChange={(event) => setLogo(event.currentTarget.value)}
            />
            {logo && <img className="logo logo-lg logo-preview" src={logo} alt="Vista previa del logo" />}
          </>
        )}

        <div className="form-section">
          <h2><TbDiscount size={20} /> Promociones activas</h2>
          <button type="button" className="action action-green" disabled={market.length === 0} onClick={() => setAddingPromotion(true)}>
            <TbPlus size={18} /> Añadir promoción
          </button>
        </div>
        {market.length === 0 && (
          <p className="hint">Este negocio no tiene artículos: añádelos en el punto de Mercado del creador de trabajos.</p>
        )}
        {promotions.length === 0 ? (
          <p className="empty empty-small">No hay promociones</p>
        ) : (
          promotions.map((promotion) => (
            <div key={promotion.id} className="promo-row">
              <img src={promotion.item.image} alt="" />
              <strong>{promotion.item.label}</strong>
              <NumberInput
                label="Original"
                size="xs"
                prefix="$"
                min={0}
                allowDecimal={false}
                value={promotion.originalPrice}
                onChange={(value) => patchPromotion(promotion.id, 'originalPrice', Number(value) || 0)}
              />
              <NumberInput
                label="Promoción"
                size="xs"
                prefix="$"
                min={0}
                allowDecimal={false}
                value={promotion.promotionalPrice}
                onChange={(value) => patchPromotion(promotion.id, 'promotionalPrice', Number(value) || 0)}
              />
              <b className="discount discount-inline">
                -{promotion.originalPrice > 0 ? Math.round((1 - promotion.promotionalPrice / promotion.originalPrice) * 100) : 0}%
              </b>
              <button
                type="button"
                className="icon-button icon-red"
                aria-label={`Quitar promoción de ${promotion.item.label}`}
                onClick={() => setPromotions((list) => list.filter((p) => p.id !== promotion.id))}
              >
                <TbMinus size={18} />
              </button>
            </div>
          ))
        )}

        <div className="form-section">
          <h2><TbList size={20} /> Categorías del menú</h2>
          <button
            type="button"
            className="action action-fuchsia"
            onClick={() => setCategories((list) => [...list, { id: newId('category'), label: '', items: [] }])}
          >
            <TbPlus size={18} /> Añadir categoría
          </button>
        </div>
        {categories.length === 0 ? (
          <p className="empty empty-small">No hay categorías</p>
        ) : (
          categories.map((menu) => (
            <div key={menu.id} className="menu-row">
              <div>
                <TextInput
                  placeholder="Nombre de la categoría"
                  aria-label="Nombre de la categoría"
                  maxLength={60}
                  value={menu.label}
                  style={{ flex: 1 }}
                  onChange={(event) => {
                    const label = event.currentTarget.value;
                    setCategories((list) => list.map((c) => (c.id === menu.id ? { ...c, label } : c)));
                  }}
                />
                <button type="button" className="action action-green" disabled={market.length === 0} onClick={() => setItemsFor(menu.id)}>
                  <TbPlus size={18} /> Artículos ({menu.items.length})
                </button>
                <button
                  type="button"
                  className="icon-button icon-red"
                  aria-label={`Quitar categoría ${menu.label}`}
                  onClick={() => setCategories((list) => list.filter((c) => c.id !== menu.id))}
                >
                  <TbMinus size={18} />
                </button>
              </div>
              {menu.items.length > 0 && (
                <div className="menu-items">
                  {menu.items.map((item) => (
                    <span key={item.name}>
                      <img src={item.image} alt="" /> {item.label} <em>${item.price}</em>
                    </span>
                  ))}
                </div>
              )}
            </div>
          ))
        )}

        <div className="form-buttons">
          <button type="button" className="action action-green" disabled={saving} onClick={save}>
            <TbDeviceFloppy size={20} /> {saving ? 'Guardando...' : 'Guardar cambios'}
          </button>
          <button type="button" className="action" onClick={back}>
            Cancelar
          </button>
        </div>
      </div>

      {editingCategory && (
        <ItemsModal
          key={editingCategory.id}
          opened
          market={market}
          selected={editingCategory.items}
          onClose={() => setItemsFor(null)}
          onConfirm={(items) => setCategories((list) => list.map((c) => (c.id === editingCategory.id ? { ...c, items } : c)))}
        />
      )}

      <Modal opened={addingPromotion} onClose={() => setAddingPromotion(false)} title="Artículo a promocionar" size="xl" centered classNames={{ content: 'modal', header: 'modal-header' }}>
        <div className="picker-grid">
          {market.map((item) => (
            <button
              key={item.name}
              type="button"
              className="picker-row"
              onClick={() => {
                setPromotions((list) => [
                  ...list,
                  { id: newId('promo'), item, originalPrice: Math.round(item.price * 1.2) || 1, promotionalPrice: item.price },
                ]);
                setAddingPromotion(false);
              }}
            >
              <img className="logo logo-sm logo-square" src={item.image} alt="" />
              <span>
                <strong>{item.label}</strong>
                <small>${item.price}</small>
              </span>
              <TbPlus size={20} />
            </button>
          ))}
        </div>
      </Modal>
    </section>
  );
}
