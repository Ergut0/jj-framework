import { useEffect, useState } from 'react';
import { Button, Group, Modal, NumberInput, Select, Stack, Text, TextInput, Textarea } from '@mantine/core';

export type FieldValue = string | number | null;

export interface Field {
  name: string;
  label: string;
  type?: 'text' | 'number' | 'select' | 'textarea';
  options?: { value: string; label: string }[];
  placeholder?: string;
  required?: boolean;
  searchable?: boolean;
  min?: number;
  initial?: FieldValue;
  // Los campos pueden depender de lo elegido en otros, como el grado según el trabajo
  dependsOn?: (values: Record<string, FieldValue>) => { value: string; label: string }[];
}

interface Props {
  opened: boolean;
  title: string;
  description?: string;
  submitLabel: string;
  danger?: boolean;
  fields?: Field[];
  onClose: () => void;
  onSubmit: (values: Record<string, FieldValue>) => Promise<boolean> | boolean;
}

const initialValues = (fields: Field[]) => Object.fromEntries(fields.map((field) => [field.name, field.initial ?? null]));

export function FormModal({ opened, title, description, submitLabel, danger, fields = [], onClose, onSubmit }: Props) {
  const [values, setValues] = useState<Record<string, FieldValue>>({});
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (opened) setValues(initialValues(fields));
    // Solo se reinicia al abrir: los campos se reconstruyen en cada refresco de datos
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [opened]);

  const isEmpty = (field: Field) => {
    const value = values[field.name];
    return value === null || value === undefined || value === '';
  };
  const valid = fields.every((field) => !field.required || !isEmpty(field));

  const submit = async () => {
    if (!valid || busy) return;
    setBusy(true);
    const closed = await onSubmit(values);
    setBusy(false);
    if (closed) onClose();
  };

  const change = (name: string, value: FieldValue) =>
    setValues((current) => {
      const next = { ...current, [name]: value };
      // Lo elegido en un campo dependiente deja de valer al cambiar el campo del que depende
      fields.filter((field) => field.dependsOn && field.name !== name).forEach((field) => (next[field.name] = null));
      return next;
    });

  return (
    <Modal opened={opened} onClose={onClose} title={title} centered zIndex={3000} overlayProps={{ backgroundOpacity: 0.55 }}>
      <Stack gap="md">
        {description && <Text size="sm" c="dimmed">{description}</Text>}
        {fields.map((field) => {
          const options = field.dependsOn ? field.dependsOn(values) : field.options;
          if (field.type === 'select') {
            return (
              <Select
                key={field.name}
                label={field.label}
                placeholder={field.placeholder}
                data={options ?? []}
                searchable={field.searchable}
                required={field.required}
                value={values[field.name] === null || values[field.name] === undefined ? null : String(values[field.name])}
                onChange={(value) => change(field.name, value)}
                comboboxProps={{ zIndex: 3500 }}
                nothingFoundMessage="Sin resultados"
              />
            );
          }
          if (field.type === 'number') {
            return (
              <NumberInput
                key={field.name}
                label={field.label}
                placeholder={field.placeholder}
                required={field.required}
                min={field.min}
                value={values[field.name] ?? ''}
                onChange={(value) => change(field.name, value === '' ? null : value)}
              />
            );
          }
          if (field.type === 'textarea') {
            return (
              <Textarea
                key={field.name}
                label={field.label}
                placeholder={field.placeholder}
                required={field.required}
                autosize
                minRows={2}
                value={String(values[field.name] ?? '')}
                onChange={(event) => change(field.name, event.currentTarget.value)}
              />
            );
          }
          return (
            <TextInput
              key={field.name}
              label={field.label}
              placeholder={field.placeholder}
              required={field.required}
              value={String(values[field.name] ?? '')}
              onChange={(event) => change(field.name, event.currentTarget.value)}
            />
          );
        })}
        <Group justify="flex-end" gap="sm">
          <Button variant="subtle" color="gray" onClick={onClose}>Cancelar</Button>
          <Button color={danger ? 'red' : 'yellow'} c={danger ? undefined : 'dark'} disabled={!valid} loading={busy} onClick={submit}>
            {submitLabel}
          </Button>
        </Group>
      </Stack>
    </Modal>
  );
}
