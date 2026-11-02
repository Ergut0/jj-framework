import { create } from 'zustand';

export const useLockStore = create<any>((e) => ({
  unlocked: false,
  changeLock: () =>
    e((e) => ({
      unlocked: !e.unlocked,
    })),
}));
