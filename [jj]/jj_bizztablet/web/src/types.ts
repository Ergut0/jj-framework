export type Status = 'open' | 'closed' | 'in_event';
export type CategoryKey = 'mechanics' | 'leisure' | 'food' | 'services';

export const CATEGORIES: Record<CategoryKey, string> = {
  mechanics: 'Talleres',
  leisure: 'Ocio',
  food: 'Alimentación',
  services: 'Servicios',
};

export interface Item {
  name: string;
  label: string;
  price: number;
  image: string;
}

export interface MenuCategory {
  id: string;
  label: string;
  items: Item[];
}

export interface Promotion {
  id: string;
  item: Item;
  originalPrice: number;
  promotionalPrice: number;
}

export interface Coords {
  x: number;
  y: number;
  z: number;
}

export interface Business {
  name: string;
  label: string;
  logo: string;
  description: string;
  discordUrl: string;
  category?: CategoryKey | null;
  coords?: Coords | null;
  categories: MenuCategory[];
  promotions: Promotion[];
  market: Item[];
  status: Status;
}

export interface TabletEvent {
  id: number;
  job: string;
  title: string;
  startAt: number;
  endAt: number;
  location: string;
  description: string;
  organizer: string;
  imageUrl: string;
  cancelled: boolean;
}

export interface TabletData {
  jobs: Business[];
  events: TabletEvent[];
  currentJob: string;
  isBoss: boolean;
  hasPerms: boolean;
}

export interface ActionResult {
  success: boolean;
  error?: string;
}

export type Route =
  | { page: 'home' }
  | { page: 'businesses'; category?: CategoryKey }
  | { page: 'business'; job: string }
  | { page: 'edit'; job: string }
  | { page: 'events' };

export type Navigate = (route: Route) => void;
