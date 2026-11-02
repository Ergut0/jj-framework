import { Locale } from '../store/locale';

export const getCurrencySymbol = (): string => {
  const symbol = Locale.currency_symbol;
  if (symbol && symbol !== 'currency_symbol') return symbol;

  const legacySymbol = Locale.$;
  if (legacySymbol && legacySymbol !== '$') return legacySymbol;

  return '$';
};
