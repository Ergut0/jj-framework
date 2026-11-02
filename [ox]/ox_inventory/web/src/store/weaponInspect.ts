import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface WeaponInspectState {
  open: boolean;
  weaponSlot: number | null;
  compatibleTypes: string[];
}

const initialState: WeaponInspectState = {
  open: false,
  weaponSlot: null,
  compatibleTypes: [],
};

export const weaponInspectSlice = createSlice({
  name: 'weaponInspect',
  initialState,
  reducers: {
    openWeaponInspect(
      state,
      action: PayloadAction<{ weaponSlot: number; compatibleTypes: string[] }>
    ) {
      state.open = true;
      state.weaponSlot = action.payload.weaponSlot;
      state.compatibleTypes = action.payload.compatibleTypes;
    },
    closeWeaponInspect(state) {
      state.open = false;
      state.weaponSlot = null;
      state.compatibleTypes = [];
    },
  },
});

export const { openWeaponInspect, closeWeaponInspect } = weaponInspectSlice.actions;
export const selectWeaponInspect = (state: { weaponInspect: WeaponInspectState }) =>
  state.weaponInspect;
export default weaponInspectSlice.reducer;
