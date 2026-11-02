import { createAsyncThunk } from '@reduxjs/toolkit';
import { fetchNui } from '../utils/fetchNui';

export const combineItem = createAsyncThunk(
  'inventory/combineItem',
  async (data: { recipe: string; count: number }, { rejectWithValue }) => {
    try {
      const response = await fetchNui<boolean>('combineItem', data);

      if (response === false) {
        return rejectWithValue(response);
      }

      return true;
    } catch (error) {
      return rejectWithValue(false);
    }
  }
);
