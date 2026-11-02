import { getCurrencySymbol } from './currency';

export const formatItemAmount = (itemName?: string, count?: number): string => {
  if (!count || count <= 1) return '';

  const amount = count.toLocaleString('en-us');

  return itemName === 'money' ? `${getCurrencySymbol()}${amount}` : `${amount}x`;
};
