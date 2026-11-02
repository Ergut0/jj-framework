import alimentacion from '../assets/alimentacion.webp';
import evento from '../assets/evento.webp';
import ocio from '../assets/ocio.webp';
import palmeras from '../assets/palmeras.webp';
import persons from '../assets/persons.webp';
import servicios from '../assets/servicios.webp';
import talleres from '../assets/talleres.webp';
import type { CategoryKey, Navigate } from '../types';

interface Tile {
  title: string;
  image: string;
  wide?: boolean;
  category?: CategoryKey;
}

const TILES: Tile[] = [
  { title: 'TALLERES', image: talleres, category: 'mechanics' },
  { title: 'OCIO', image: ocio, category: 'leisure' },
  { title: 'ALIMENTACIÓN', image: alimentacion, category: 'food' },
  { title: 'SERVICIOS', image: servicios, category: 'services' },
  { title: 'EVENTOS', image: evento, wide: true },
];

export function Home({ navigate }: { navigate: Navigate }) {
  return (
    <section className="home">
      <img className="home-palms" src={palmeras} alt="" />
      <img className="home-people" src={persons} alt="" />

      <div className="home-grid">
        {TILES.map((tile, index) => (
          <button
            key={tile.title}
            type="button"
            className={`home-tile${tile.wide ? ' home-tile-wide' : ''}`}
            style={{ animationDelay: `${index * 70}ms` }}
            onClick={() =>
              navigate(tile.category ? { page: 'businesses', category: tile.category } : { page: 'events' })
            }
          >
            <img src={tile.image} alt="" />
            <span>{tile.title}</span>
          </button>
        ))}
      </div>
    </section>
  );
}
