declare global {
  interface Window {
    invokeNative?: unknown;
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = !window.invokeNative;

const resource = window.GetParentResourceName?.() ?? 'illenium-appearance';

export async function fetchNui<T>(name: string, data: unknown = {}): Promise<T | undefined> {
  if (isBrowser) {
    const { answer } = await import('./mock');
    return answer(name, data) as T;
  }
  try {
    const response = await fetch(`https://${resource}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    return (await response.json()) as T;
  } catch {
    return undefined;
  }
}
