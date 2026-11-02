import { create } from 'zustand';

export const useReferenceStore = create<any>((e) => ({
  referenceBlipId: 1,
  referenceColorId: 0,
  refTurned: true,
  setBlipId: (t) =>
    e({
      referenceBlipId: t,
    }),
  setBlipColor: (t) =>
    e({
      referenceColorId: t,
    }),
  changeRefStatus: () =>
    e((e) => ({
      refTurned: !e.refTurned,
    })),
}));
