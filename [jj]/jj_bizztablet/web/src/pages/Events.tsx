import { useEffect, useState } from 'react';
import { Modal, TextInput, Textarea } from '@mantine/core';
import { notifications } from '@mantine/notifications';
import {
  TbBan,
  TbCalendarEvent,
  TbChevronDown,
  TbClock,
  TbEdit,
  TbMapPin,
  TbPhoto,
  TbPlus,
  TbTrash,
  TbUsers,
} from 'react-icons/tb';
import { fetchNui } from '../nui';
import { BackButton, type PageProps } from './common';
import type { ActionResult, TabletEvent } from '../types';

type Phase = 'upcoming' | 'ongoing' | 'completed';

const PHASE: Record<Phase, string> = { upcoming: 'Próximo', ongoing: 'En curso', completed: 'Finalizado' };
const HOUR = 3600000;

const phaseOf = (event: TabletEvent): Phase => {
  const now = Date.now();
  if (now < event.startAt) return 'upcoming';
  return now <= event.endAt ? 'ongoing' : 'completed';
};

// Formato que espera <input type="datetime-local">, en la hora local del jugador
const toLocalInput = (time: number) => {
  const date = new Date(time);
  return new Date(time - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
};

const formatDate = (time: number) =>
  new Date(time).toLocaleDateString('es-ES', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
const formatTime = (time: number) => new Date(time).toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });

interface FormState {
  title: string;
  start: string;
  end: string;
  location: string;
  organizer: string;
  description: string;
  imageUrl: string;
}

const emptyForm: FormState = { title: '', start: '', end: '', location: '', organizer: '', description: '', imageUrl: '' };

function EventModal({ opened, event, onClose, onSave }: { opened: boolean; event?: TabletEvent; onClose: () => void; onSave: (values: Partial<TabletEvent>) => void }) {
  const [form, setForm] = useState<FormState>(emptyForm);
  const [errors, setErrors] = useState<Partial<Record<keyof FormState, string>>>({});

  useEffect(() => {
    if (!opened) return;
    setErrors({});
    setForm(
      event
        ? {
            title: event.title,
            start: toLocalInput(event.startAt),
            end: toLocalInput(event.endAt),
            location: event.location,
            organizer: event.organizer,
            description: event.description,
            imageUrl: event.imageUrl,
          }
        : emptyForm,
    );
  }, [opened, event]);

  const set = (field: keyof FormState, value: string) => {
    setForm((current) => {
      const next = { ...current, [field]: value };
      // Al elegir el inicio se propone una duración de tres horas
      if (field === 'start' && value && !current.end) next.end = toLocalInput(new Date(value).getTime() + 3 * HOUR);
      return next;
    });
    setErrors((current) => ({ ...current, [field]: undefined, ...(field === 'start' ? { end: undefined } : {}) }));
  };

  const submit = () => {
    const found: typeof errors = {};
    if (!form.title.trim()) found.title = 'El título es obligatorio';
    if (!form.start) found.start = 'La fecha de inicio es obligatoria';
    if (!form.end) found.end = 'La fecha de fin es obligatoria';
    else if (form.start && new Date(form.end).getTime() <= new Date(form.start).getTime()) found.end = 'Tiene que terminar después de empezar';
    if (!form.location.trim()) found.location = 'El lugar es obligatorio';
    if (!form.organizer.trim()) found.organizer = 'El colaborador es obligatorio';
    setErrors(found);
    if (Object.keys(found).length > 0) return;

    onSave({
      title: form.title,
      startAt: new Date(form.start).getTime(),
      endAt: new Date(form.end).getTime(),
      location: form.location,
      organizer: form.organizer,
      description: form.description,
      imageUrl: form.imageUrl,
    });
  };

  return (
    <Modal opened={opened} onClose={onClose} title={event ? 'Editar evento' : 'Crear nuevo evento'} size="lg" centered classNames={{ content: 'modal', header: 'modal-header' }}>
      <div className="event-form">
        <TextInput label="Título del evento" required maxLength={80} placeholder="Ej: Fiesta de fin de año" value={form.title} error={errors.title} onChange={(e) => set('title', e.currentTarget.value)} />
        <div className="event-form-dates">
          <TextInput label="Empieza" required type="datetime-local" value={form.start} error={errors.start} onChange={(e) => set('start', e.currentTarget.value)} />
          <TextInput label="Termina" required type="datetime-local" value={form.end} error={errors.end} onChange={(e) => set('end', e.currentTarget.value)} />
        </div>
        <TextInput label="Lugar" required maxLength={80} placeholder="Ej: Vanilla Unicorn" value={form.location} error={errors.location} onChange={(e) => set('location', e.currentTarget.value)} />
        <TextInput label="Colabora" required maxLength={80} placeholder="Ej: Burger Shot" value={form.organizer} error={errors.organizer} onChange={(e) => set('organizer', e.currentTarget.value)} />
        <Textarea label="Descripción" rows={3} maxLength={1000} placeholder="Describe el evento..." value={form.description} onChange={(e) => set('description', e.currentTarget.value)} />
        <TextInput label="URL del cartel" placeholder="https://example.com/image.jpg" value={form.imageUrl} onChange={(e) => set('imageUrl', e.currentTarget.value)} />
      </div>
      <footer className="modal-footer">
        <span>* Campos obligatorios</span>
        <div>
          <button type="button" className="action" onClick={onClose}>
            Cancelar
          </button>
          <button type="button" className="action action-fuchsia" onClick={submit}>
            {event ? 'Guardar' : 'Crear'}
          </button>
        </div>
      </footer>
    </Modal>
  );
}

function EventCard({ event, data, onEdit, onCancel, onDelete }: { event: TabletEvent; data: PageProps['data']; onEdit: () => void; onCancel: () => void; onDelete: () => void }) {
  const phase = phaseOf(event);
  const canManage = data.hasPerms || (data.isBoss && event.job === data.currentJob);
  const editable = !event.cancelled && phase !== 'completed' && canManage;

  return (
    <article className={`event-card${event.cancelled ? ' event-card-cancelled' : ''}`}>
      <div className="event-poster">
        {event.imageUrl ? <img src={event.imageUrl} alt="" /> : <TbPhoto size={48} />}
        {event.cancelled ? <b className="event-cancelled">CANCELADO</b> : <b className={`event-phase phase-${phase}`}>{PHASE[phase]}</b>}
      </div>
      <div className="event-body">
        <div className="event-head">
          <h2>{event.title}</h2>
          <div>
            {editable && (
              <>
                <button type="button" className="icon-button icon-blue" aria-label={`Editar ${event.title}`} onClick={onEdit}>
                  <TbEdit size={18} />
                </button>
                <button type="button" className="icon-button icon-fuchsia" aria-label={`Cancelar ${event.title}`} onClick={onCancel}>
                  <TbBan size={18} />
                </button>
              </>
            )}
            {data.hasPerms && (
              <button type="button" className="icon-button icon-red" aria-label={`Eliminar ${event.title}`} onClick={onDelete}>
                <TbTrash size={18} />
              </button>
            )}
          </div>
        </div>
        <p><TbCalendarEvent size={18} /> {formatDate(event.startAt)}</p>
        <p><TbClock size={18} /> {formatTime(event.startAt)} - {formatTime(event.endAt)}</p>
        <p><TbMapPin size={18} /> {event.location}</p>
        <p className="event-organizer"><TbUsers size={18} /> Colabora: {event.organizer}</p>
        {event.description && <p className="event-description">{event.description}</p>}
      </div>
    </article>
  );
}

function Collapsible({ title, red, children }: { title: string; red?: boolean; children: React.ReactNode }) {
  const [open, setOpen] = useState(false);

  return (
    <div className="event-group">
      <button type="button" className={`event-toggle${red ? ' event-toggle-red' : ''}`} aria-expanded={open} onClick={() => setOpen(!open)}>
        {title}
        <TbChevronDown size={20} style={{ transform: open ? 'rotate(180deg)' : undefined }} />
      </button>
      {open && children}
    </div>
  );
}

export function Events({ data, back }: PageProps) {
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<TabletEvent>();

  const sorted = [...data.events].sort((a, b) => a.startAt - b.startAt);
  const active = sorted.filter((e) => !e.cancelled && phaseOf(e) !== 'completed');
  const finished = sorted.filter((e) => !e.cancelled && phaseOf(e) === 'completed').reverse();
  const cancelled = sorted.filter((e) => e.cancelled);

  const report = (result: ActionResult | undefined, done: string) =>
    notifications.show(
      result?.success
        ? { color: 'green', message: done }
        : { color: 'red', message: result?.error || 'No se pudo completar la acción' },
    );

  const save = async (values: Partial<TabletEvent>) => {
    if (editing) {
      report(await fetchNui<ActionResult>('tablet:updateEvent', { ...values, id: editing.id }), 'Evento actualizado');
    } else {
      report(await fetchNui<ActionResult>('tablet:createEvent', values), 'Evento creado');
    }
    setFormOpen(false);
  };

  const card = (event: TabletEvent) => (
    <EventCard
      key={event.id}
      event={event}
      data={data}
      onEdit={() => {
        setEditing(event);
        setFormOpen(true);
      }}
      onCancel={async () => report(await fetchNui<ActionResult>('tablet:cancelEvent', event.id), 'Evento cancelado')}
      onDelete={async () => report(await fetchNui<ActionResult>('tablet:deleteEvent', event.id), 'Evento eliminado')}
    />
  );

  return (
    <section className="page">
      <header className="page-header">
        <BackButton onClick={back} />
        <h1><TbCalendarEvent size={28} /> Eventos</h1>
        <div className="page-header-actions">
          {(data.isBoss || data.hasPerms) && (
            <button
              type="button"
              className="action action-fuchsia"
              onClick={() => {
                setEditing(undefined);
                setFormOpen(true);
              }}
            >
              <TbPlus size={18} /> Crear evento
            </button>
          )}
        </div>
      </header>

      <div className="event-list">
        {data.events.length === 0 && <p className="empty">Todavía no hay eventos</p>}
        {active.length > 0 && (
          <div className="event-group">
            <h2 className="event-group-title">Eventos activos</h2>
            {active.map(card)}
          </div>
        )}
        {finished.length > 0 && <Collapsible title={`Eventos finalizados (${finished.length})`}>{finished.map(card)}</Collapsible>}
        {cancelled.length > 0 && <Collapsible red title={`Eventos cancelados (${cancelled.length})`}>{cancelled.map(card)}</Collapsible>}
      </div>

      <EventModal opened={formOpen} event={editing} onClose={() => setFormOpen(false)} onSave={save} />
    </section>
  );
}
