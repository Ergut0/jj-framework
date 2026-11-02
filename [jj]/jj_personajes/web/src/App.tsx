import { useCallback, useEffect, useMemo, useState } from 'react';
import { countries } from './countries';
import { fetchNui, isBrowser, sample, type Character, type ScreenData } from './nui';

type View = 'select' | 'create' | 'arrival' | 'closed';

const FOCUS_DELAY = 900;

// Lua envía las tablas vacías como objeto o como lista según el caso
const toList = <T,>(list: unknown): T[] => (Array.isArray(list) ? list : list && typeof list === 'object' ? (Object.values(list) as T[]) : []);

// A mano porque es-ES no separa los miles en números de cuatro cifras
const money = (value: number) => `${String(Math.trunc(value)).replace(/\B(?=(\d{3})+(?!\d))/g, '.')} $`;

const getAge = (birthdate: string) => {
  const match = birthdate.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);
  if (!match) return null;
  const [day, month, year] = [Number(match[1]), Number(match[2]), Number(match[3])];
  const date = new Date(year, month - 1, day);
  if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) return null;
  const today = new Date();
  let age = today.getFullYear() - year;
  if (today.getMonth() + 1 < month || (today.getMonth() + 1 === month && today.getDate() < day)) age -= 1;
  return age;
};

const timeAgo = (seconds?: number) => {
  if (seconds === undefined) return 'Aún no ha pisado la ciudad';
  if (seconds < 3600) return 'Hace un momento';
  if (seconds < 86400) {
    const hours = Math.floor(seconds / 3600);
    return `Hace ${hours} ${hours === 1 ? 'hora' : 'horas'}`;
  }
  const days = Math.floor(seconds / 86400);
  return `Hace ${days} ${days === 1 ? 'día' : 'días'}`;
};

// La fecha se escribe solo con números y las barras se ponen solas
const maskDate = (value: string) => {
  const digits = value.replace(/\D/g, '').slice(0, 8);
  if (digits.length <= 2) return digits;
  if (digits.length <= 4) return `${digits.slice(0, 2)}/${digits.slice(2)}`;
  return `${digits.slice(0, 2)}/${digits.slice(2, 4)}/${digits.slice(4)}`;
};

const machineLine = (firstName: string, lastName: string) => {
  const clean = (text: string) => text.normalize('NFD').replace(/[^a-zA-Z ]/g, '').trim().toUpperCase().replace(/ +/g, '<');
  return `ATL<<${clean(lastName)}<<${clean(firstName)}`.padEnd(38, '<').slice(0, 38);
};

function Dossier({ character }: { character: Character }) {
  const age = getAge(character.birthdate);
  return (
    <section className="card dossier">
      <small className="eyebrow">Expediente · {character.identifier}</small>
      <h1>{character.name}</h1>
      <p className="subtitle">
        {age !== null ? `${age} años` : 'Edad desconocida'}
        {character.nationality ? ` · ${character.nationality}` : ''}
      </p>

      <dl className="facts">
        <div>
          <dt>
            <i className="fa-solid fa-briefcase" /> Trabajo
          </dt>
          <dd>
            {character.job}
            {character.grade && <small>{character.grade}</small>}
          </dd>
        </div>
        <div className="facts-half">
          <dt>
            <i className="fa-solid fa-wallet" /> Efectivo
          </dt>
          <dd>{money(character.cash)}</dd>
        </div>
        <div className="facts-half">
          <dt>
            <i className="fa-solid fa-building-columns" /> Banco
          </dt>
          <dd>{money(character.bank)}</dd>
        </div>
        <div>
          <dt>
            <i className="fa-solid fa-location-dot" /> Lo dejaste en
          </dt>
          <dd>
            {character.place ?? 'Lugar desconocido'}
            <small>{timeAgo(character.secondsAgo)}</small>
          </dd>
        </div>
      </dl>
    </section>
  );
}

function CreateForm({ data, onCancel, onCreated }: { data: ScreenData; onCancel: () => void; onCreated: (name: string) => void }) {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [birthdate, setBirthdate] = useState('');
  const [nationality, setNationality] = useState('');
  const [gender, setGender] = useState(0);
  const [busy, setBusy] = useState(false);

  const age = getAge(birthdate);
  const ageValid = age !== null && age >= data.minAge && age <= data.maxAge;
  const valid = firstName.trim().length >= 2 && lastName.trim().length >= 2 && ageValid;

  let problem = '';
  if (birthdate.length === 10 && !ageValid) problem = `La edad debe estar entre ${data.minAge} y ${data.maxAge} años`;

  const changeGender = (next: number) => {
    setGender(next);
    fetchNui('previewGender', { gender: next });
  };

  const submit = async () => {
    if (!valid || busy) return;
    setBusy(true);
    const result = await fetchNui<{ success: boolean }>('createCharacter', {
      firstname: firstName.trim(),
      lastname: lastName.trim(),
      birthdate,
      gender,
      nationality: nationality.trim(),
    });
    setBusy(false);
    if (result?.success) onCreated(`${firstName.trim()} ${lastName.trim()}`);
  };

  return (
    <section className="card creator">
      <div className="id-card">
        <header>
          <img src="./logo.webp" alt="" />
          <span>
            Documento de identidad
            <small>San Andreas</small>
          </span>
        </header>
        <div className="id-body">
          <div className="id-photo">
            <i className={`fa-solid ${gender === 1 ? 'fa-person-dress' : 'fa-person'}`} />
          </div>
          <div className="id-lines">
            <span>
              <small>Apellidos</small>
              {lastName || '—'}
            </span>
            <span>
              <small>Nombre</small>
              {firstName || '—'}
            </span>
            <div className="id-row">
              <span>
                <small>Nacimiento</small>
                {birthdate || '—'}
              </span>
              <span>
                <small>Sexo</small>
                {gender === 1 ? 'M' : 'H'}
              </span>
            </div>
            <span>
              <small>Nacionalidad</small>
              {nationality || '—'}
            </span>
          </div>
        </div>
        <footer>{machineLine(firstName, lastName)}</footer>
      </div>

      <form
        className="form"
        onSubmit={(event) => {
          event.preventDefault();
          submit();
        }}
      >
        <div className="field-row">
          <label>
            Nombre
            <input autoFocus value={firstName} maxLength={30} onChange={(event) => setFirstName(event.target.value)} />
          </label>
          <label>
            Apellidos
            <input value={lastName} maxLength={30} onChange={(event) => setLastName(event.target.value)} />
          </label>
        </div>
        <div className="field-row">
          <label>
            Nacimiento
            <input value={birthdate} inputMode="numeric" placeholder="DD/MM/AAAA" onChange={(event) => setBirthdate(maskDate(event.target.value))} />
          </label>
          <label>
            Nacionalidad
            <input list="countries" value={nationality} maxLength={60} onChange={(event) => setNationality(event.target.value)} />
            <datalist id="countries">
              {countries.map((country) => (
                <option key={country.code} value={country.display} />
              ))}
            </datalist>
          </label>
        </div>

        <div className="segments" role="group" aria-label="Sexo">
          <button type="button" className={gender === 0 ? 'segment-active' : ''} aria-pressed={gender === 0} onClick={() => changeGender(0)}>
            <i className="fa-solid fa-mars" /> Hombre
          </button>
          <button type="button" className={gender === 1 ? 'segment-active' : ''} aria-pressed={gender === 1} onClick={() => changeGender(1)}>
            <i className="fa-solid fa-venus" /> Mujer
          </button>
        </div>

        <p className="form-note">{problem || 'Su aspecto lo eliges justo después de aparecer.'}</p>

        <div className="form-actions">
          <button type="button" className="action action-ghost" onClick={onCancel}>
            Volver
          </button>
          <button type="submit" className="action" disabled={!valid || busy}>
            Crear personaje
          </button>
        </div>
      </form>
    </section>
  );
}

export function App() {
  const [view, setView] = useState<View>(isBrowser ? 'select' : 'closed');
  const [data, setData] = useState<ScreenData | null>(isBrowser ? sample : null);
  const [selected, setSelected] = useState(0);
  const [arrival, setArrival] = useState<{ name: string; place?: string } | null>(null);
  const [busy, setBusy] = useState(false);

  const characters = useMemo(() => toList<Character>(data?.characters), [data]);
  const slots = data?.slots ?? 0;
  const current = characters[selected];

  const focus = useCallback((index: number, greet: boolean) => {
    fetchNui('focusSlot', { index: index + 1, greet });
  }, []);

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const message = event.data;
      if (message.action === 'open') {
        const list = toList<Character>(message.data.characters);
        // Empieza en el último personaje que se usó
        let last = 0;
        list.forEach((character, index) => {
          if ((character.secondsAgo ?? Infinity) < (list[last].secondsAgo ?? Infinity)) last = index;
        });
        setData(message.data);
        setSelected(last);
        setBusy(false);
        setView('select');
        window.setTimeout(() => focus(last, true), FOCUS_DELAY);
      } else if (message.action === 'arrival') {
        setArrival({ name: message.name, place: message.place });
        setView('arrival');
      } else if (message.action === 'close') {
        setView('closed');
      }
    };
    window.addEventListener('message', onMessage);
    fetchNui('uiReady');
    return () => window.removeEventListener('message', onMessage);
  }, [focus]);

  const select = useCallback(
    (index: number) => {
      setSelected(index);
      focus(index, true);
    },
    [focus],
  );

  const startCreate = useCallback(() => {
    fetchNui('startDraft', { index: selected + 1, gender: 0 });
    setView('create');
  }, [selected]);

  const enter = useCallback(async () => {
    if (!current || busy) return;
    setBusy(true);
    const result = await fetchNui<{ success: boolean }>('enterCharacter', { identifier: current.identifier });
    if (!result?.success) {
      setBusy(false);
    } else if (isBrowser) {
      setArrival({ name: current.name, place: current.place });
      setView('arrival');
    }
  }, [current, busy]);

  useEffect(() => {
    if (view !== 'select') return;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'ArrowLeft') select((selected - 1 + slots) % slots);
      else if (event.key === 'ArrowRight') select((selected + 1) % slots);
      else if (event.key === 'Enter') {
        if (current) enter();
        else startCreate();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [view, selected, slots, current, select, enter, startCreate]);

  const locked = Math.max(0, (data?.maxSlots ?? 0) - slots);

  return (
    <div className={isBrowser ? 'preview' : undefined}>
      {view !== 'closed' && view !== 'arrival' && <div className="vignette" />}

      {view === 'select' && data && (
        <>
          <header className="brand">
            <img src="./logo.webp" alt="Atlantis Roleplay" />
            <span>Elige quién quieres ser hoy</span>
          </header>

          <div className="side">
            {current ? (
              <Dossier character={current} />
            ) : (
              <section className="card dossier">
                <small className="eyebrow">Hueco libre</small>
                <h1>Una vida por empezar</h1>
                <p className="subtitle">Todavía no hay nadie aquí. Crea un personaje nuevo: tiene su propio dinero, trabajo, inventario y vehículos.</p>
              </section>
            )}
            {current ? (
              <button type="button" className="action action-big" disabled={busy} onClick={enter}>
                Entrar en la ciudad <i className="fa-solid fa-arrow-right" />
              </button>
            ) : (
              <button type="button" className="action action-big" onClick={startCreate}>
                <i className="fa-solid fa-plus" /> Crear personaje
              </button>
            )}
          </div>

          <nav className="lineup" aria-label="Personajes">
            {Array.from({ length: slots }, (_, index) => {
              const character = characters[index];
              return (
                <button type="button" key={index} className={`slot ${selected === index ? 'slot-active' : ''} ${character ? '' : 'slot-empty'}`} aria-pressed={selected === index} onClick={() => select(index)}>
                  <i className={`fa-solid ${character ? (character.gender === 1 ? 'fa-person-dress' : 'fa-person') : 'fa-plus'}`} />
                  <span>
                    <strong>{character ? character.name : 'Hueco libre'}</strong>
                    <small>{character ? character.job : 'Crear personaje'}</small>
                  </span>
                </button>
              );
            })}
            {Array.from({ length: locked }, (_, index) => (
              <div key={`locked-${index}`} className="slot slot-locked" title="Hueco bloqueado">
                <i className="fa-solid fa-lock" />
              </div>
            ))}
          </nav>

          <p className="keys">
            <kbd>←</kbd> <kbd>→</kbd> cambiar · <kbd>Enter</kbd> {current ? 'entrar' : 'crear'}
          </p>
        </>
      )}

      {view === 'create' && data && (
        <div className="side">
          <CreateForm
            data={data}
            onCancel={() => {
              fetchNui('cancelDraft');
              setView('select');
            }}
            onCreated={(name) => {
              // En el juego la llegada la abre el cliente
              if (isBrowser) {
                setArrival({ name, place: 'Aeropuerto' });
                setView('arrival');
              }
            }}
          />
        </div>
      )}

      {view === 'arrival' && arrival && (
        <div className="arrival">
          <div className="bar bar-top" />
          <div className="bar bar-bottom" />
          <div className="arrival-text">
            <small>Bienvenido a Atlantis</small>
            <strong>{arrival.name}</strong>
            {arrival.place && (
              <span>
                <i className="fa-solid fa-location-dot" /> {arrival.place}
              </span>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
