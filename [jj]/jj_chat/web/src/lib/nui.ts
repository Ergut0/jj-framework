declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = () => !window.invokeNative;

const READY_RETRY = 500;

// La página puede cargar antes de que el cliente registre sus callbacks: se repite hasta que responda
export function announceReady() {
  if (isBrowser()) return () => undefined;

  let stopped = false;
  const attempt = async () => {
    while (!stopped) {
      const response = await fetch(`https://${window.GetParentResourceName!()}/ready`, { method: 'post', body: '{}' }).catch(() => undefined);
      if (response?.ok) return;
      await new Promise((resolve) => setTimeout(resolve, READY_RETRY));
    }
  };
  attempt();
  return () => {
    stopped = true;
  };
}

export function fetchNui(event: string, data?: unknown) {
  if (isBrowser()) return;
  fetch(`https://${window.GetParentResourceName!()}/${event}`, {
    method: 'post',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  }).catch(() => undefined);
}
