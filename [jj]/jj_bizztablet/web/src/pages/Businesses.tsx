import { useMemo, useState } from 'react';
import { Modal, TextInput } from '@mantine/core';
import { TbBuildingStore, TbEdit, TbMapPin, TbPhoneCall, TbSearch } from 'react-icons/tb';
import { BackButton, BusinessLogo, callBusiness, markBusiness, StatusBadge, type PageProps } from './common';
import { CATEGORIES, type Business, type CategoryKey, type Status } from '../types';

const ORDER: Record<Status, number> = { in_event: 0, open: 1, closed: 2 };
const sortByStatus = (list: Business[]) => [...list].sort((a, b) => ORDER[a.status] - ORDER[b.status]);

function BusinessCard({ business, index, navigate, close }: { business: Business; index: number } & Pick<PageProps, 'navigate' | 'close'>) {
  const closed = business.status === 'closed';

  return (
    <article
      className="business-card"
      style={{ animationDelay: `${Math.min(index, 12) * 45}ms` }}
      onClick={() => navigate({ page: 'business', job: business.name })}
    >
      <div className="business-card-head">
        <BusinessLogo business={business} className="logo logo-md" />
        <h2>{business.label}</h2>
        <StatusBadge status={business.status} />
      </div>
      <div className="business-card-actions">
        <button
          type="button"
          className="action action-green"
          disabled={closed}
          onClick={(event) => {
            event.stopPropagation();
            callBusiness(business, close);
          }}
        >
          <TbPhoneCall size={18} /> Llamar
        </button>
        <button
          type="button"
          className="action action-blue"
          disabled={!business.coords}
          onClick={(event) => {
            event.stopPropagation();
            markBusiness(business, close);
          }}
        >
          <TbMapPin size={18} /> Ubicación
        </button>
      </div>
    </article>
  );
}

function PickerModal({ opened, onClose, businesses, onPick }: { opened: boolean; onClose: () => void; businesses: Business[]; onPick: (business: Business) => void }) {
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState<CategoryKey | 'all'>('all');

  const filtered = useMemo(() => {
    const text = search.toLowerCase();
    return sortByStatus(
      businesses.filter(
        (b) =>
          (b.label.toLowerCase().includes(text) || b.name.toLowerCase().includes(text)) &&
          (category === 'all' || b.category === category),
      ),
    );
  }, [businesses, search, category]);

  return (
    <Modal opened={opened} onClose={onClose} title="Seleccionar negocio" size="xl" centered classNames={{ content: 'modal', header: 'modal-header' }}>
      <div className="picker-filters">
        <TextInput
          leftSection={<TbSearch size={16} />}
          placeholder="Buscar por nombre..."
          value={search}
          onChange={(event) => setSearch(event.currentTarget.value)}
        />
        <div className="chips">
          <button type="button" className={`chip${category === 'all' ? ' chip-on' : ''}`} onClick={() => setCategory('all')}>
            Todos
          </button>
          {(Object.keys(CATEGORIES) as CategoryKey[]).map((key) => (
            <button key={key} type="button" className={`chip${category === key ? ' chip-on' : ''}`} onClick={() => setCategory(key)}>
              {CATEGORIES[key]}
            </button>
          ))}
        </div>
      </div>

      {filtered.length === 0 ? (
        <p className="empty">No se encontraron negocios</p>
      ) : (
        <div className="picker-grid">
          {filtered.map((business) => (
            <button key={business.name} type="button" className="picker-row" onClick={() => onPick(business)}>
              <BusinessLogo business={business} className="logo logo-sm" />
              <span>
                <strong>{business.label}</strong>
                <small>{business.name}</small>
              </span>
              <StatusBadge status={business.status} />
            </button>
          ))}
        </div>
      )}
    </Modal>
  );
}

export function Businesses({ data, navigate, back, close, category }: PageProps & { category?: CategoryKey }) {
  const [picking, setPicking] = useState(false);
  const list = sortByStatus(category ? data.jobs.filter((b) => b.category === category) : data.jobs);
  const ownBusiness = data.jobs.some((b) => b.name === data.currentJob);

  return (
    <section className="page">
      <header className="page-header">
        <BackButton onClick={back}>Volver a inicio</BackButton>
        <h1>
          <TbBuildingStore size={26} />
          {category ? CATEGORIES[category] : 'Todos los negocios'}
        </h1>
        <div className="page-header-actions">
          {data.hasPerms && (
            <button type="button" className="action action-green" onClick={() => setPicking(true)}>
              <TbEdit size={18} /> Editar negocios
            </button>
          )}
          {data.isBoss && ownBusiness && (
            <button type="button" className="action action-fuchsia" onClick={() => navigate({ page: 'edit', job: data.currentJob })}>
              <TbBuildingStore size={18} /> Gestionar tu negocio
            </button>
          )}
        </div>
      </header>

      {list.length === 0 ? (
        <p className="empty">Todavía no hay negocios en esta categoría</p>
      ) : (
        <div className="business-grid">
          {list.map((business, index) => (
            <BusinessCard key={business.name} business={business} index={index} navigate={navigate} close={close} />
          ))}
        </div>
      )}

      <PickerModal
        opened={picking}
        onClose={() => setPicking(false)}
        businesses={data.jobs}
        onPick={(business) => {
          setPicking(false);
          navigate({ page: 'edit', job: business.name });
        }}
      />
    </section>
  );
}
