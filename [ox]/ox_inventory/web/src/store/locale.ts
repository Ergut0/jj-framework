const rawLocale: { [key: string]: string } = {};

const subscribers = new Set<() => void>();

export function subscribeLocale(cb: () => void) {
  subscribers.add(cb);
  return () => { subscribers.delete(cb); };
}

export const Locale: { [key: string]: string } = new Proxy(rawLocale, {
  get(target, prop: string | symbol) {
    if (typeof prop === 'string') {
      return target[prop] ?? prop;
    }
    return undefined as any;
  },
  set(target, prop: string | symbol, value) {
    if (typeof prop === 'string') {
      target[prop] = String(value);
      setTimeout(() => {
        subscribers.forEach((cb) => cb());
      }, 0);
      return true;
    }
    return false;
  },
});
