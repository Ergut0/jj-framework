import { useEffect, useState } from 'react';
import { Group, Title } from '@mantine/core';
import type { CarouselItem, CarouselType } from '../types';

const imageExists = (url: string) =>
  new Promise<boolean>((resolve) => {
    const image = new Image();
    image.onload = () => resolve(true);
    image.onerror = () => resolve(false);
    image.src = url;
  });

// Primero la imagen propia en web/public/vehicles y, si no hay, la de la documentación de FiveM
async function findImage(name: string) {
  const local = `vehicles/${name}.png`;
  if (await imageExists(local)) return local;
  const remote = `https://docs.fivem.net/vehicles/${name}.webp`;
  return (await imageExists(remote)) ? remote : '';
}

interface Props {
  item: CarouselItem;
  type: CarouselType;
  tall: boolean;
  sign: string;
  onSelect: (item: CarouselItem) => void;
}

export function Card({ item, type, tall, sign, onSelect }: Props) {
  const [image, setImage] = useState('');

  useEffect(() => {
    let active = true;
    if (type === 'vehicles' && item.name) {
      findImage(item.name).then((url) => active && setImage(url));
    }
    return () => {
      active = false;
    };
  }, [item.name, type]);

  const size = { width: tall ? 340 : 280, height: tall ? 200 : 140 };

  if (type === 'categories') {
    return (
      <button type="button" className="card category" style={size} onClick={() => onSelect(item)}>
        <span className="category-label">{item.label}</span>
      </button>
    );
  }

  return (
    <button type="button" className="card" style={size} onClick={() => onSelect(item)}>
      <Group justify="flex-end" className="card-top">
        <Title order={2} fw={500} fs="italic" c="var(--accent)" className="veh-price">
          {sign}{item.price?.toLocaleString('es-ES')}
        </Title>
        {item.coins ? <span className="veh-coins">o {item.coins.toLocaleString('es-ES')} CP</span> : null}
      </Group>
      <Title order={2} fw={500} fs="italic" c="gray.3" className="veh-label">{item.label.charAt(0).toUpperCase() + item.label.slice(1)}</Title>
      {image && <span className="veh-image" style={{ backgroundImage: `url(${image})` }} />}
    </button>
  );
}
