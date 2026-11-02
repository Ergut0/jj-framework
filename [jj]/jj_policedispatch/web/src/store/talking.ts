import { create } from 'zustand';

export const useTalkingStore = create<any>((e) => ({
  talkingPlayers: {},
  setTalking: (t, n) =>
    e((e) => ({
      talkingPlayers: {
        ...e.talkingPlayers,
        [t]: n,
      },
    })),
}));
