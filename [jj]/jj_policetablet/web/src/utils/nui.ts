import { useEffect, useRef } from 'react';

export const isBrowser = () => !window.invokeNative;

export const useNuiEvent = (e, t) => {
  const ref = useRef<any>(() => {});
  useEffect(() => {
    ref.current = t;
  }, [t]);
  useEffect(() => {
    const r = (o) => {
      const { action, data } = o.data;
      if (action && action === e && ref.current) {
        try {
          ref.current(data);
        } catch (error) {
          console.error(`Error in useNuiEvent handler for action ${e}:`, error);
        }
      }
    };
    window.addEventListener('message', r);
    return () => {
      window.removeEventListener('message', r);
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
      return await (await fetch(`https://jj_policetablet/${e}`, n)).json();
    } catch {
      return;
    }
  }
}

export const OPEN_ENTITY_TAB_EVENT = 'openEntityTab';

export const openEntityTab = (e) => {
  window.dispatchEvent(
    new CustomEvent(OPEN_ENTITY_TAB_EVENT, {
      detail: e,
    }),
  );
};
