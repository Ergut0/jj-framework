import { useEffect, useRef } from 'react';

export const isBrowser = () => !window.invokeNative;

export const useNuiEvent = (e, t) => {
  const ref = useRef<any>(noop);
  useEffect(() => {
    ref.current = t;
  }, [t]);
  useEffect(() => {
    const t = (t) => {
      const { action, data } = t.data;
      if (action && action === e && ref.current) {
        try {
          ref.current(data);
        } catch (error) {
          const n = error;
          console.error(`Error in useNuiEvent handler for action ${e}:`, n);
        }
      }
    };
    window.addEventListener('message', t);
    return () => {
      window.removeEventListener('message', t);
    };
  }, [e]);
};

export async function fetchNui(e, t?) {
  const n: any = {
    method: 'post',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(t),
  };
  if (!isBrowser()) {
    try {
      return await (await fetch(`https://jj_policedispatch/${e}`, n)).json();
    } catch {
      return;
    }
  }
}

export function noop() {}
