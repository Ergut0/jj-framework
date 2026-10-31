import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react';
import type { KeyboardEvent } from 'react';
import { formatTime, normalizeMessage, renderColored } from './lib/messages';
import { mockAccess, mockMessages, mockSubmit, mockSuggestions } from './lib/mock';
import { announceReady, fetchNui, isBrowser } from './lib/nui';
import type { Access, Channel, ChatMessage, RawMessage, Suggestion } from './types';

const MAX_MESSAGES = 200;
const MAX_HISTORY = 50;
const MAX_SUGGESTIONS = 6;
const FADE_TIME = 12000;
// La tecla que abre el chat no debe acabar escrita en el campo de texto
const FOCUS_DELAY = 80;

type TabId = 'all' | 'local' | 'ooc' | 'pm' | 'job' | 'staff';

const TABS: { id: TabId; label: string; send: string; placeholder: string }[] = [
  { id: 'all', label: 'Todo', send: 'say', placeholder: 'Habla con quien tengas cerca o escribe / para ver los comandos' },
  { id: 'local', label: 'Rol', send: 'say', placeholder: 'Habla con quien tengas cerca' },
  { id: 'ooc', label: 'OOC', send: 'ooc', placeholder: 'Mensaje fuera de personaje' },
  { id: 'pm', label: 'Privados', send: 'reply', placeholder: 'Responde al último mensaje privado' },
  { id: 'job', label: 'Trabajo', send: 'job', placeholder: 'Mensaje para tu trabajo' },
  { id: 'staff', label: 'Staff', send: 'staff', placeholder: 'Mensaje para el staff' },
];

const inTab = (message: ChatMessage, tab: TabId) => tab === 'all' || message.channel === tab;

function Line({ message }: { message: ChatMessage }) {
  return (
    <li className={`line ${message.channel as Channel}`}>
      <time>{formatTime(message.time)}</time>
      <p>
        {message.tag && <span className="tag">{message.tag}</span>}
        {message.author && (
          <strong style={message.color ? { color: message.color } : undefined}>
            {renderColored(message.author)}
            {message.detail && <small> · {message.detail}</small>}
            {message.id !== undefined && <small> ({message.id})</small>}
            {message.text && ': '}
          </strong>
        )}
        {renderColored(message.text)}
      </p>
    </li>
  );
}

export function App() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [open, setOpen] = useState(false);
  const [visible, setVisible] = useState(isBrowser());
  const [faded, setFaded] = useState(false);
  const [tab, setTab] = useState<TabId>('all');
  const [unread, setUnread] = useState<Partial<Record<TabId, boolean>>>({});
  const [input, setInput] = useState('');
  const [access, setAccess] = useState<Access>({ staff: false, job: false });
  const [suggestions, setSuggestions] = useState<Suggestion[]>([]);
  const [maxLength, setMaxLength] = useState(300);
  const [selected, setSelected] = useState(0);

  const historyRef = useRef<string[]>([]);
  const historyIndex = useRef(-1);
  const inputRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLUListElement>(null);
  const stickToBottom = useRef(true);
  const fadeTimer = useRef<ReturnType<typeof setTimeout>>(undefined);
  const tabRef = useRef(tab);
  tabRef.current = tab;

  const wake = useCallback(() => {
    setFaded(false);
    clearTimeout(fadeTimer.current);
    fadeTimer.current = setTimeout(() => setFaded(true), FADE_TIME);
  }, []);

  const addMessage = useCallback(
    (raw: RawMessage) => {
      const message = normalizeMessage(raw);
      if (!message) return;
      setMessages((current) => [...current, message].slice(-MAX_MESSAGES));
      if (message.channel !== 'system' && message.channel !== tabRef.current && tabRef.current !== 'all') {
        setUnread((current) => ({ ...current, [message.channel]: true }));
      }
      wake();
    },
    [wake],
  );

  const openChat = useCallback((nextSuggestions: Suggestion[], nextMax?: number) => {
    setSuggestions(nextSuggestions);
    if (nextMax) setMaxLength(nextMax);
    setInput('');
    setSelected(0);
    historyIndex.current = -1;
    stickToBottom.current = true;
    setOpen(true);
    setTimeout(() => inputRef.current?.focus(), FOCUS_DELAY);
  }, []);

  const closeChat = useCallback(() => {
    setOpen(false);
    setInput('');
    wake();
  }, [wake]);

  useEffect(() => {
    const listener = (event: MessageEvent) => {
      const data = event.data;
      if (data.action === 'message') addMessage(data.message);
      else if (data.action === 'clear') setMessages([]);
      else if (data.action === 'open') openChat(data.suggestions ?? [], data.maxLength);
      else if (data.action === 'access') {
        setAccess(data.access);
        setSuggestions(data.suggestions ?? []);
      } else if (data.action === 'close') closeChat();
      else if (data.action === 'visible') setVisible(data.visible);
    };
    window.addEventListener('message', listener);
    const stopAnnouncing = announceReady();
    return () => {
      stopAnnouncing();
      window.removeEventListener('message', listener);
    };
  }, [addMessage, openChat, closeChat]);

  // En el navegador no hay juego: se abre con T y empieza con mensajes de ejemplo
  useEffect(() => {
    if (!isBrowser()) return;
    document.documentElement.classList.add('browser');
    setMessages([]);
    mockMessages.forEach(addMessage);
    setAccess(mockAccess);
    openChat(mockSuggestions);
    const onKeyDown = (event: globalThis.KeyboardEvent) => {
      if (event.key.toLowerCase() === 't' && document.activeElement !== inputRef.current) {
        event.preventDefault();
        openChat(mockSuggestions);
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [addMessage, openChat]);

  const tabs = useMemo(
    () => TABS.filter(({ id }) => (id !== 'job' || access.job) && (id !== 'staff' || access.staff)),
    [access],
  );
  const currentTab = TABS.find(({ id }) => id === tab)!;
  // Cerrado siempre se ve todo, para no perder mensajes por la pestaña elegida
  const shown = useMemo(() => messages.filter((message) => inTab(message, open ? tab : 'all')), [messages, tab, open]);

  useLayoutEffect(() => {
    const list = listRef.current;
    if (list && (stickToBottom.current || !open)) list.scrollTop = list.scrollHeight;
  }, [shown, open]);

  useEffect(() => {
    // Una pestaña puede dejar de existir si el jugador cambia de trabajo o pierde permisos
    if (!tabs.some(({ id }) => id === tab)) setTab('all');
  }, [tabs, tab]);

  const selectTab = (id: TabId) => {
    setTab(id);
    setUnread((current) => ({ ...current, [id]: false }));
    stickToBottom.current = true;
    inputRef.current?.focus();
  };

  // Sugerencias

  const words = input.split(' ');
  const commandName = words[0].toLowerCase();
  const isCommand = input.startsWith('/');
  const matches = useMemo(
    () => (isCommand && words.length === 1 ? suggestions.filter(({ name }) => name.startsWith(commandName)).slice(0, MAX_SUGGESTIONS) : []),
    [isCommand, words.length, suggestions, commandName],
  );
  const exact = isCommand && words.length > 1 ? suggestions.find(({ name }) => name === commandName) : undefined;
  const activeParam = words.length - 2;

  const complete = (name: string) => {
    setInput(`${name} `);
    setSelected(0);
    inputRef.current?.focus();
  };

  // Teclado

  const moveHistory = (direction: number) => {
    const history = historyRef.current;
    const next = historyIndex.current + direction;
    if (next < -1 || next >= history.length) return;
    historyIndex.current = next;
    setInput(next === -1 ? '' : history[history.length - 1 - next]);
  };

  const submit = () => {
    const text = input.trim();
    if (text) {
      historyRef.current = [...historyRef.current.filter((entry) => entry !== text), text].slice(-MAX_HISTORY);
      if (isBrowser()) addMessage(mockSubmit(currentTab.send, text));
    }
    fetchNui('submit', { text, channel: currentTab.send });
    closeChat();
  };

  const onKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter') {
      submit();
    } else if (event.key === 'Escape') {
      fetchNui('close');
      closeChat();
    } else if (event.key === 'Tab') {
      event.preventDefault();
      if (matches[selected]) {
        complete(matches[selected].name);
      } else {
        const index = tabs.findIndex(({ id }) => id === tab);
        selectTab(tabs[(index + 1) % tabs.length].id);
      }
    } else if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
      event.preventDefault();
      const direction = event.key === 'ArrowUp' ? 1 : -1;
      if (matches.length > 0) {
        setSelected((current) => (current - direction + matches.length) % matches.length);
      } else {
        moveHistory(direction);
      }
    }
  };

  if (!visible) return null;

  return (
    <main className={`chat${open ? ' open' : ''}${!open && faded ? ' faded' : ''}`}>
      {open && (
        <nav className="tabs">
          {tabs.map(({ id, label }) => (
            <button key={id} type="button" className={id === tab ? 'active' : undefined} onClick={() => selectTab(id)}>
              {label}
              {unread[id] && <i aria-label="Mensajes sin leer" />}
            </button>
          ))}
        </nav>
      )}

      <ul
        ref={listRef}
        className="messages"
        onScroll={(event) => {
          const list = event.currentTarget;
          stickToBottom.current = list.scrollHeight - list.scrollTop - list.clientHeight < 24;
        }}
      >
        {shown.map((message) => (
          <Line key={message.key} message={message} />
        ))}
        {open && shown.length === 0 && <li className="empty">Aún no hay mensajes aquí.</li>}
      </ul>

      {open && (
        <div className="composer">
          <input
            ref={inputRef}
            value={input}
            maxLength={maxLength}
            placeholder={currentTab.placeholder}
            spellCheck={false}
            onChange={(event) => {
              setInput(event.target.value);
              setSelected(0);
              historyIndex.current = -1;
            }}
            onKeyDown={onKeyDown}
            onBlur={() => inputRef.current?.focus()}
          />

          {matches.length > 0 && (
            <ul className="suggestions">
              {matches.map(({ name, help, params }, index) => (
                <li key={name}>
                  <button type="button" className={index === selected ? 'active' : undefined} onMouseDown={(event) => event.preventDefault()} onClick={() => complete(name)}>
                    <strong>{name}</strong>
                    {params.map((param) => (
                      <code key={param.name}>{param.name}</code>
                    ))}
                    {help && <span>{help}</span>}
                  </button>
                </li>
              ))}
            </ul>
          )}

          {exact && exact.params.length > 0 && (
            <div className="suggestions params">
              <strong>{exact.name}</strong>
              {exact.params.map((param, index) => (
                <code key={param.name} className={index === activeParam ? 'active' : undefined}>
                  {param.name}
                </code>
              ))}
              {exact.help && <span>{exact.help}</span>}
            </div>
          )}
        </div>
      )}
    </main>
  );
}
