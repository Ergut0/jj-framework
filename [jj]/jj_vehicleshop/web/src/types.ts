export type CarouselType = 'categories' | 'vehicles';

export interface CarouselItem {
  label: string;
  name?: string;
  price?: number;
  coins?: number;
}

export interface VehicleData {
  name: string;
  label: string;
  price: number;
  brand: string;
  class: string;
  info: Record<string, { name: string; value: number }>;
  buy: boolean;
  test: boolean;
  unit: string;
  speed: number;
  seats: number;
}

export type UILang = Record<string, string>;
