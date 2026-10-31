import { createContext, useContext } from 'react';
import type { AdminData } from './types';

export interface AdminContextValue {
  data: AdminData;
  can: (action: string) => boolean;
  run: (action: string, payload?: Record<string, unknown>) => Promise<boolean>;
  refresh: () => Promise<void>;
  revision: number;
}

export const AdminContext = createContext<AdminContextValue | null>(null);

export function useAdmin() {
  const value = useContext(AdminContext);
  if (!value) throw new Error('useAdmin fuera de AdminContext');
  return value;
}
