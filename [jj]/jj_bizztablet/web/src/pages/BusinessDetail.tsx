import { FaDiscord } from 'react-icons/fa6';
import { TbDiscount, TbInfoSquareRounded, TbMapPin, TbPhoneCall, TbShoppingBag } from 'react-icons/tb';
import { openUrl } from '../nui';
import { BackButton, BusinessLogo, callBusiness, markBusiness, StatusBadge, type PageProps } from './common';
import { CATEGORIES } from '../types';

export function BusinessDetail({ data, back, close, job }: PageProps & { job: string }) {
  const business = data.jobs.find((b) => b.name === job);

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

  const total = business.categories.reduce((sum, category) => sum + category.items.length, 0);

  return (
    <section className="page">
      <header className="page-header">
        <BackButton onClick={back} />
      </header>

      <div className="detail">
        <div className="detail-hero">
          <BusinessLogo business={business} className="logo logo-lg" />
          <div className="detail-title">
            <div>
              <h1>{business.label}</h1>
              <StatusBadge status={business.status} />
            </div>
            {business.category && <p>{CATEGORIES[business.category]}</p>}
            <div className="detail-actions">
              {business.status !== 'closed' && (
                <button type="button" className="action action-green" onClick={() => callBusiness(business, close)}>
                  <TbPhoneCall size={20} /> Llamar
                </button>
              )}
              {business.coords && (
                <button type="button" className="action action-blue" onClick={() => markBusiness(business, close)}>
                  <TbMapPin size={20} /> Ver en el mapa
                </button>
              )}
              {business.discordUrl && (
                <button type="button" className="action action-indigo" onClick={() => openUrl(business.discordUrl)}>
                  <FaDiscord size={20} /> Discord
                </button>
              )}
            </div>
          </div>
        </div>

        <h2 className="section-title section-blue">
          <TbInfoSquareRounded size={22} /> Sobre el negocio
        </h2>
        <p className="detail-text">
          {business.description || 'Bienvenido a nuestro negocio. Ofrecemos los mejores productos y servicios de la ciudad.'}
        </p>

        {business.promotions.length > 0 && (
          <>
            <h2 className="section-title section-green">
              <TbDiscount size={22} /> Promociones
            </h2>
            <div className="item-grid">
              {business.promotions.map((promotion) => (
                <div key={promotion.id} className="item-card item-card-promo">
                  <b className="discount">-{Math.round((1 - promotion.promotionalPrice / promotion.originalPrice) * 100)}%</b>
                  <img src={promotion.item.image} alt="" />
                  <div>
                    <h4>{promotion.item.label}</h4>
                    <p>
                      <s>${promotion.originalPrice}</s> <strong className="price-green">${promotion.promotionalPrice}</strong>
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}

        {business.categories.length > 0 && (
          <>
            <h2 className="section-title section-fuchsia">
              <TbShoppingBag size={22} /> Catálogo <small>({total} artículos)</small>
            </h2>
            {business.categories.map((category) => (
              <div key={category.id} className="catalog-group">
                <h3>{category.label}</h3>
                <div className="item-grid">
                  {category.items.map((item) => (
                    <div key={item.name} className="item-card">
                      <img src={item.image} alt="" />
                      <div>
                        <h4>{item.label}</h4>
                        <p>
                          <strong>${item.price}</strong>
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </>
        )}
      </div>
    </section>
  );
}
