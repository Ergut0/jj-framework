import { useCallback, useEffect, useMemo, useState } from 'react';
import { Carousel } from '@mantine/carousel';
import { Card } from './components/Card';
import { VehicleInfo } from './components/VehicleInfo';
import { mockCategories, mockLang, mockVehicleData, mockVehicles } from './lib/mock';
import { fetchNui, isBrowser, useNuiEvent } from './lib/nui';
import type { CarouselItem, CarouselType, UILang, VehicleData } from './types';

const TALL_HEIGHT = 1000;

export function App() {
  const [open, setOpen] = useState(isBrowser());
  const [hidden, setHidden] = useState(false);
  const [type, setType] = useState<CarouselType>('categories');
  const [items, setItems] = useState<CarouselItem[]>(isBrowser() ? mockCategories : []);
  const [search, setSearch] = useState('');
  const [lang, setLang] = useState<UILang>(isBrowser() ? mockLang : {});
  const [sign, setSign] = useState('$');
  const [vehicle, setVehicle] = useState<VehicleData | null>(null);
  const [tall, setTall] = useState(window.innerHeight > TALL_HEIGHT);

  useEffect(() => {
    if (!isBrowser()) return;
    document.documentElement.classList.add('browser');
  }, []);

  useNuiEvent<{ state: boolean; lang: UILang; sign: string }>('openDealership', (data) => {
    setOpen(data.state);
    setHidden(false);
    setLang(data.lang);
    setSign(data.sign ?? '');
    setTall(window.innerHeight > TALL_HEIGHT);
  });
  useNuiEvent<{ type: CarouselType; elements: CarouselItem[] }>('setCarousel', (data) => {
    setType(data.type);
    setItems(Array.isArray(data.elements) ? data.elements : []);
    setSearch('');
  });
  useNuiEvent<VehicleData>('vehData', setVehicle);
  // Mientras está abierto el diálogo de pago de jj_paymethods
  useNuiEvent<boolean>('setHidden', setHidden);
  useNuiEvent('close', () => {
    setOpen(false);
    setHidden(false);
    setVehicle(null);
  });

  const showCategories = useCallback(() => {
    setVehicle(null);
    if (isBrowser()) {
      setType('categories');
      setItems(mockCategories);
      setSearch('');
    } else {
      fetchNui('showCategories');
    }
  }, []);

  useEffect(() => {
    if (!open || hidden) return;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return;
      if (type === 'categories') {
        setOpen(isBrowser());
        if (!isBrowser()) fetchNui('close');
      } else {
        showCategories();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [open, hidden, type, showCategories]);

  const select = (item: CarouselItem) => {
    if (type === 'categories') {
      if (isBrowser()) {
        setType('vehicles');
        setItems(mockVehicles);
        setSearch('');
      } else {
        fetchNui('openCategory', { category: item.label });
      }
    } else if (isBrowser()) {
      setVehicle(mockVehicleData(item));
    } else {
      fetchNui('showVehicle', { name: item.name, label: item.label, price: item.price });
    }
  };

  const buy = () => {
    if (!isBrowser()) fetchNui('buyVehicle', { name: vehicle?.name, price: vehicle?.price });
  };

  const test = () => {
    if (!isBrowser()) fetchNui('testDrive', { name: vehicle?.name });
  };

  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase();
    return term ? items.filter((item) => item.label.toLowerCase().includes(term)) : items;
  }, [items, search]);

  if (!open || hidden) return null;

  return (
    <>
      {vehicle && <VehicleInfo vehicle={vehicle} lang={lang} tall={tall} onBuy={buy} onTest={test} />}

      <div className="dock">
        <input
          type="text"
          className="search"
          placeholder={type === 'categories' ? lang.search_category : lang.search_vehicle}
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        {filtered.length > 0 && (
          <Carousel
            key={type}
            mb={10}
            slideSize={tall ? '340px' : '280px'}
            slideGap="xs"
            controlsOffset="sm"
            controlSize={20}
            emblaOptions={{ dragFree: true, align: 'start' }}
          >
            {filtered.map((item) => (
              <Carousel.Slide key={item.name ?? item.label}>
                <Card item={item} type={type} tall={tall} sign={sign} onSelect={select} />
              </Carousel.Slide>
            ))}
          </Carousel>
        )}
      </div>
    </>
  );
}
