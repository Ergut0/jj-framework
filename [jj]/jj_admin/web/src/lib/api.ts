import type { ActionResult, AdminData, Ban, LogEntry, Option } from '../types';
import { fetchNui, isBrowser } from './nui';
import { mockAction, mockBans, mockData, mockItems, mockLogs } from './mock';

export const getData = async (): Promise<AdminData | undefined> =>
  isBrowser() ? mockData() : ((await fetchNui<AdminData | false>('getData')) || undefined);

export const getItems = async (): Promise<Option[]> => (isBrowser() ? mockItems : ((await fetchNui<Option[]>('getItems')) ?? []));

export const getBans = async (): Promise<Ban[]> => (isBrowser() ? mockBans() : ((await fetchNui<Ban[]>('getBans')) ?? []));

export const getLogs = async (): Promise<LogEntry[]> => (isBrowser() ? mockLogs() : ((await fetchNui<LogEntry[]>('getLogs')) ?? []));

export const getCoords = async () =>
  isBrowser()
    ? { x: -269.4, y: -955.3, z: 31.2, heading: 205.8 }
    : await fetchNui<{ x: number; y: number; z: number; heading: number }>('getCoords');

export const runAction = async (action: string, payload?: Record<string, unknown>): Promise<ActionResult> => {
  if (isBrowser()) return mockAction(action, payload ?? {});
  return (await fetchNui<ActionResult>('action', { action, payload: payload ?? {} })) ?? { ok: false, message: 'Sin respuesta' };
};

export const closeMenu = () => {
  if (!isBrowser()) fetchNui('close');
};
