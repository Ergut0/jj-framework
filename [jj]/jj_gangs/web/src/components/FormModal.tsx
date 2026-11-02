import { useEffect, useState } from 'react';
import { Button, Group, Modal, NumberInput, Select, Stack, Text, TextInput } from '@mantine/core';

export type FieldValue = string | number | null;

export interface Field {
  name: string;
  label: string;
  type?: 'text' | 'number' | 'select';
  options?: { value: string; label: string }[];
  placeholder?: string;
  required?: boolean;
  searchable?: boolean;
  min?: number;
  max?: number;
  maxLength?: number;
  initial?: FieldValue;
  // Campo que solo aparece según lo elegido en otros, como la droga de un laboratorio
  visible?: (values: Record<string, FieldValue>) => boolean;
}

interface Props {
  opened: boolean;
  title: string;
  description?: string;
  submitLabel: string;
  danger?: boolean;
  fields?: Field[];
  onClose: () => void;
  onSubmit: (values: Record<string, FieldValue>) => Promise<boolean> | boolean | void;
}

export function FormModal({ opened, title, description, submitLabel, danger, fields = [], onClose, onSubmit }: Props) {
  const [values, setValues] = useState<Record<string, FieldValue>>({});
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (opened) setValues(Object.fromEntries(fields.map((field) => [field.name, field.initial ?? null])));
    // Solo se reinicia al abrir: los campos se reconstruyen en cada refresco de datos
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [opened]);

  const shown = fields.filter((field) => !field.visible || field.visible(values));
  const valid = shown.every((field) => !field.required || (values[field.name] !== null && values[field.name] !== undefined && values[field.name] !== ''));

  const submit = async () => {
    if (!valid || busy) return;
    setBusy(true);
    const result = await onSubmit(values);
    setBusy(false);
    if (result !== false) onClose();
  };

  const change = (name: string, value: FieldValue) => setValues((current) => ({ ...current, [name]: value }));

  return (
    <Modal opened={opened} onClose={onClose} title={title} centered zIndex={3000} overlayProps={{ backgroundOpacity: 0.55 }}>
      <Stack gap="md">
        {description && <Text size="sm" c="dimmed">{description}</Text>}
        {shown.map((field) => {
          if (field.type === 'select') {
            return (
              <Select
                key={field.name}
                label={field.label}
                placeholder={field.placeholder}
                data={field.options ?? []}
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
                max={field.max}
                value={values[field.name] ?? ''}
                onChange={(value) => change(field.name, value === '' ? null : value)}
              />
            );
          }
          return (
            <TextInput
              key={field.name}
              label={field.label}
              placeholder={field.placeholder}
              required={field.required}
              maxLength={field.maxLength}
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
