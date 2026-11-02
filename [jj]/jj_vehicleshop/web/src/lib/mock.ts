// Datos de ejemplo para trabajar en el navegador, sin el juego
import type { CarouselItem, UILang, VehicleData } from '../types';

export const mockLang: UILang = {
  acceleration: 'Aceleración',
  speed: 'Velocidad',
  handling: 'Conducción',
  braking: 'Frenado',
  seats: 'Asientos',
  buy_button: 'Comprar',
  test_button: 'Probar',
  search_category: 'Buscar categoría',
  search_vehicle: 'Buscar vehículo',
};

export const mockCategories: CarouselItem[] = ['compactos', 'coupe', 'deportivos', 'muscle', 'motos', 'suv', 'superdeportivos'].map((label) => ({ label }));

export const mockVehicles: CarouselItem[] = [
  { label: 'adder', name: 'adder', price: 1000000 },
  { label: 'bmx', name: 'bmx', price: 150 },
  { label: 'sultan', name: 'sultan', price: 50000 },
  { label: 't20', name: 't20', price: 2200000 },
  { label: 'zentorno', name: 'zentorno', price: 725000 },
];

export const mockVehicleData = (item: CarouselItem): VehicleData => ({
  name: item.name!,
  label: item.label,
  price: item.price!,
  brand: 'Truffade',
  class: 'S',
  speed: 220,
  unit: 'kph',
  seats: 2,
  buy: true,
  test: true,
  info: {
    acceleration: { name: 'Aceleración', value: 7.2 },
    handling: { name: 'Conducción', value: 5.1 },
    speed: { name: 'Velocidad', value: 8.9 },
    braking: { name: 'Frenado', value: 3.4 },
  },
});
