import { useEffect, useState } from 'react';
import { Button, Group, Modal, NumberInput, PasswordInput, Select, Switch, Text, TextInput } from '@mantine/core';
import { TbCurrentLocation } from 'react-icons/tb';
import { api } from '../nui';
import type { Coords } from '../types';

export type FormValues = Record<string, unknown>;

export interface Field {
  key: string;
  label: string;
  type: 'text' | 'password' | 'number' | 'select' | 'switch' | 'coords';
  required?: boolean;
  placeholder?: string;
  hint?: string;
  pattern?: RegExp;
  min?: number;
  max?: number;
  options?: { value: string; label: string }[];
  // Solo para coords: claves de x, y, z y, si tiene, orientación
  keys?: [string, string, string, string?];
  // Oculta el campo según lo que haya en el formulario
  when?: (values: FormValues) => boolean;
}

interface FormModalProps {
  opened: boolean;
  title: string;
  description?: string;
  fields: Field[];
  initial?: FormValues;
  submitLabel: string;
  onClose: () => void;
  onSubmit: (values: FormValues) => Promise<void> | void;
}

const round = (value: number) => Math.round(value * 100) / 100;

function CoordsField({ field, values, setValue }: { field: Field; values: FormValues; setValue: (key: string, value: unknown) => void }) {
  const keys = field.keys ?? ['x', 'y', 'z', 'heading'];
  const names = ['X', 'Y', 'Z', 'Orientación'];

  const useMyPosition = async () => {
    const coords = await api.getCoords<Coords>();
    setValue(keys[0], round(coords.x));
    setValue(keys[1], round(coords.y));
    setValue(keys[2], round(coords.z));
    if (keys[3]) setValue(keys[3], round(coords.heading));
  };

  return (
    <fieldset className="coords-field">
      <legend>{field.label}</legend>
      <div className="coords-grid">
        {keys.map((key, index) => key && (
          <NumberInput
            key={key}
            label={names[index]}
            size="xs"
            hideControls
            decimalScale={2}
            value={values[key] as number | undefined}
            onChange={(value) => setValue(key, value)}
          />
        ))}
      </div>
      <Button size="xs" variant="light" leftSection={<TbCurrentLocation size={14} />} onClick={useMyPosition}>
        Usar mi posición
      </Button>
    </fieldset>
  );
}

function isMissing(field: Field, values: FormValues) {
  if (field.type === 'coords') {
    return (field.keys ?? ['x', 'y', 'z']).slice(0, 3).some((key) => typeof values[key as string] !== 'number');
  }
  if (!field.required) return false;
  const value = values[field.key];
  return value === undefined || value === null || value === '';
}

export function FormModal({ opened, title, description, fields, initial, submitLabel, onClose, onSubmit }: FormModalProps) {
  const [values, setValues] = useState<FormValues>({});
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (opened) {
      setValues(initial ?? {});
      setError(null);
      setSaving(false);
    }
    // Solo al abrir: mientras tanto, los datos de fuera no deben pisar lo que se está escribiendo
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [opened]);

  const setValue = (key: string, value: unknown) => setValues((current) => ({ ...current, [key]: value }));
  const visibleFields = fields.filter((field) => !field.when || field.when(values));

  const submit = async () => {
    const missing = visibleFields.find((field) => isMissing(field, values));
    if (missing) {
      setError(`Falta rellenar: ${missing.label}`);
      return;
    }
    const invalid = visibleFields.find((field) => field.pattern && !field.pattern.test(String(values[field.key] ?? '')));
    if (invalid) {
      setError(invalid.hint ?? `${invalid.label} no es válido`);
      return;
    }

    setSaving(true);
    await onSubmit(values);
    setSaving(false);
    onClose();
  };

  return (
    <Modal opened={opened} onClose={onClose} title={title} centered size="md" radius="md" overlayProps={{ backgroundOpacity: 0.55, blur: 2 }}>
      <form
        className="form"
        onSubmit={(event) => {
          event.preventDefault();
          submit();
        }}
      >
        {description && <Text size="sm" c="dimmed">{description}</Text>}

        {visibleFields.map((field) => {
          const value = values[field.key];
          switch (field.type) {
            case 'coords':
              return <CoordsField key={field.key} field={field} values={values} setValue={setValue} />;
            case 'switch':
              return <Switch key={field.key} label={field.label} description={field.hint} checked={value === true} onChange={(event) => setValue(field.key, event.currentTarget.checked)} />;
            case 'select':
              return <Select key={field.key} label={field.label} description={field.hint} placeholder={field.placeholder} data={field.options ?? []} value={value === undefined ? null : String(value)} onChange={(next) => setValue(field.key, next)} comboboxProps={{ zIndex: 3000 }} searchable allowDeselect={false} withAsterisk={field.required} />;
            case 'number':
              return <NumberInput key={field.key} label={field.label} description={field.hint} placeholder={field.placeholder} min={field.min} max={field.max} value={value as number | undefined} onChange={(next) => setValue(field.key, next)} withAsterisk={field.required} />;
            case 'password':
              return <PasswordInput key={field.key} label={field.label} description={field.hint} placeholder={field.placeholder} value={(value as string) ?? ''} onChange={(event) => setValue(field.key, event.currentTarget.value)} />;
            default:
              return <TextInput key={field.key} label={field.label} description={field.hint} placeholder={field.placeholder} value={(value as string) ?? ''} onChange={(event) => setValue(field.key, event.currentTarget.value)} withAsterisk={field.required} />;
          }
        })}

        {error && <Text size="sm" c="red.4">{error}</Text>}

        <Group justify="flex-end" mt="xs">
          <Button variant="subtle" color="gray" onClick={onClose}>Cancelar</Button>
          <Button type="submit" loading={saving}>{submitLabel}</Button>
        </Group>
      </form>
    </Modal>
  );
}

interface ConfirmProps {
  opened: boolean;
  title: string;
  message: string;
  confirmLabel: string;
  onClose: () => void;
  onConfirm: () => Promise<void> | void;
}

export function ConfirmModal({ opened, title, message, confirmLabel, onClose, onConfirm }: ConfirmProps) {
  const [saving, setSaving] = useState(false);

  return (
    <Modal opened={opened} onClose={onClose} title={title} centered size="sm" radius="md" overlayProps={{ backgroundOpacity: 0.55, blur: 2 }}>
      <Text size="sm">{message}</Text>
      <Group justify="flex-end" mt="md">
        <Button variant="subtle" color="gray" onClick={onClose}>Cancelar</Button>
        <Button
          color="red"
          loading={saving}
          onClick={async () => {
            setSaving(true);
            await onConfirm();
            setSaving(false);
            onClose();
          }}
        >
          {confirmLabel}
        </Button>
      </Group>
    </Modal>
  );
}
