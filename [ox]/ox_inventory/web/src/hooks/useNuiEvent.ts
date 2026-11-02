import { MutableRefObject, useEffect, useRef } from 'react';
import { noop } from '../utils/misc';

interface NuiMessageData<T = unknown> {
  action: string;
  data: T;
}

type NuiHandlerSignature<T> = (data: T) => void;

type NuiHandler = (data: unknown) => void;

const nuiHandlers = new Map<string, Set<NuiHandler>>();
let listenerAttached = false;

const handleNuiMessage = (event: MessageEvent<NuiMessageData>) => {
  const message = event.data;
  if (!message || typeof message !== 'object' || typeof message.action !== 'string') return;

  const handlers = nuiHandlers.get(message.action);
  if (!handlers) return;

  handlers.forEach((handler) => handler(message.data));
};

const attachNuiListener = () => {
  if (listenerAttached) return;
  window.addEventListener('message', handleNuiMessage);
  listenerAttached = true;
};

export const useNuiEvent = <T = any>(action: string, handler: (data: T) => void) => {
  const savedHandler: MutableRefObject<NuiHandlerSignature<T>> = useRef(noop);

  useEffect(() => {
    savedHandler.current = handler;
  }, [handler]);

  useEffect(() => {
    attachNuiListener();

    const eventHandler: NuiHandler = (data) => {
      savedHandler.current(data as T);
    };

    let handlers = nuiHandlers.get(action);
    if (!handlers) {
      handlers = new Set();
      nuiHandlers.set(action, handlers);
    }
    handlers.add(eventHandler);

    return () => {
      handlers?.delete(eventHandler);
      if (handlers?.size === 0) nuiHandlers.delete(action);
    };
  }, [action]);
};

export default useNuiEvent;
