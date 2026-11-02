
import { isEnvBrowser } from './misc';

const fetch = window.fetch;
// @ts-expect-error
window.fetch = () => {};
// @ts-expect-error
window.XMLHttpRequest = window.fetch;

const resourceName = (window as any).GetParentResourceName ? (window as any).GetParentResourceName() : 'ox_inventory';

export async function fetchNui<T>(eventName: string, data?: unknown): Promise<T> {
  if (isEnvBrowser()) return undefined as any;

  try {
    const resp = await fetch(`https://${resourceName}/${eventName}`, {
      method: 'post',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify(data),
    });

    const respFormatted = await resp.json();

    return respFormatted;
  } catch (error) {
    throw Error(`Failed to fetch NUI callback ${eventName}! (${error})`);
  }
}
