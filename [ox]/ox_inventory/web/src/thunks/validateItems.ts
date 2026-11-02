import { createAsyncThunk } from '@reduxjs/toolkit';
import { refreshSlots, setContainerWeight } from '../store/inventory';
import type { ItemsPayload } from '../reducers/refreshSlots';
import { fetchNui } from '../utils/fetchNui';

export const validateMove = createAsyncThunk(
  'inventory/validateMove',
  async (
    data: {
      fromSlot: number;
      fromType: string;
      toSlot: number;
      toType: string;
      count: number;
      fromInventory?: string | number;
      toInventory?: string | number;
    },
    { rejectWithValue, dispatch }
  ) => {
    try {
      const response = await fetchNui<boolean | number | { items: ItemsPayload[] }>('swapItems', data);

      if (response === false) return rejectWithValue(response);

      if (typeof response === 'number') dispatch(setContainerWeight(response));
      else if (response && typeof response === 'object' && response.items) dispatch(refreshSlots({ items: response.items }));
    } catch (error) {
      return rejectWithValue(false);
    }
  }
);
