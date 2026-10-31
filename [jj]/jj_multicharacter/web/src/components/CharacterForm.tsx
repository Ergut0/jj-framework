import { useCallback, useEffect, useState } from 'react';
import { Box, Group, Select, Stack, TextInput, Title, UnstyledButton } from '@mantine/core';
import { DateInput, DatesProvider } from '@mantine/dates';
import dayjs from 'dayjs';
import 'dayjs/locale/es';
import { useSetAtom } from 'jotai';
import { FaX } from 'react-icons/fa6';
import { countries } from '../data/countries';
import { fetchNui } from '../lib/nui';
import { activeCharacterAtom, creatingAtom } from '../store';
import classes from './CharacterForm.module.css';

dayjs.locale('es');

interface FormData {
  firstName?: string;
  lastName?: string;
  birthdate?: string;
  gender?: string;
  nationality?: string;
}

const genders = [
  { value: 'male', label: 'Masculino' },
  { value: 'female', label: 'Femenino' },
];

const nationalities = countries.map((country) => ({ value: country.display, label: country.display }));

function parseDate(value: string) {
  const parts = value.split('/');
  if (parts.length !== 3) return null;
  const [day, month, year] = parts;
  return new Date(`${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`);
}

export function CharacterForm() {
  const [form, setForm] = useState<FormData>({});
  const setCreating = useSetAtom(creatingAtom);
  const setActiveCharacter = useSetAtom(activeCharacterAtom);

  const isValid = Boolean(form.firstName && form.lastName && form.birthdate && form.gender);

  const close = useCallback(() => {
    setCreating(false);
    setActiveCharacter(null);
  }, [setActiveCharacter, setCreating]);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') close();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [close]);

  const create = async () => {
    if (!isValid) return;
    const result = await fetchNui<{ ok: boolean }>('createCharacter', form);
    if (result?.ok) setCreating(false);
  };

  return (
    <DatesProvider settings={{ locale: 'es' }}>
      <Box className={classes.container}>
        <Box className={classes.boxForm}>
          <Box mx="auto" p="md" w="100%" px={25}>
            <Group justify="space-between" className={classes.headerBox}>
              <Title ta="center" order={3} tt="uppercase" lts={0.8} c="white">
                Creador de Personaje
              </Title>
              <UnstyledButton onClick={close} mt={5}>
                <FaX color="white" size={18} />
              </UnstyledButton>
            </Group>
            <Stack mt={15} gap="lg">
              <TextInput
                label="Nombre"
                placeholder="Introduce el nombre del personaje"
                color="yellow"
                variant="filled"
                className={classes.input}
                value={form.firstName ?? ''}
                onChange={(event) => {
                  const firstName = event.currentTarget.value;
                  setForm((current) => ({ ...current, firstName }));
                }}
              />
              <TextInput
                label="Apellidos"
                placeholder="Introduce los apellidos del personaje"
                color="yellow"
                variant="filled"
                className={classes.input}
                value={form.lastName ?? ''}
                onChange={(event) => {
                  const lastName = event.currentTarget.value;
                  setForm((current) => ({ ...current, lastName }));
                }}
              />
              <DateInput
                label="Fecha de nacimiento"
                placeholder="Introduce la fecha de nacimiento del personaje"
                color="yellow"
                locale="es"
                variant="filled"
                className={classes.input}
                valueFormat="DD/MM/YYYY"
                monthLabelFormat="MMMM YYYY"
                weekdayFormat="dd"
                previousLabel="Anterior"
                nextLabel="Siguiente"
                dateParser={parseDate}
                onChange={(value) =>
                  setForm((current) => ({ ...current, birthdate: value ? dayjs(value).format('DD/MM/YYYY') : '' }))
                }
              />
              <Select
                label="Sexo"
                placeholder="Selecciona el sexo del personaje"
                color="yellow"
                variant="filled"
                className={classes.input}
                data={genders}
                value={form.gender ?? null}
                onChange={(gender) => setForm((current) => ({ ...current, gender: gender || '' }))}
              />
              <Select
                label="Nacionalidad"
                placeholder="Selecciona la nacionalidad del personaje"
                color="yellow"
                variant="filled"
                className={classes.input}
                searchable
                data={nationalities}
                value={form.nationality ?? null}
                onChange={(nationality) => setForm((current) => ({ ...current, nationality: nationality || '' }))}
              />
              <UnstyledButton className={classes.createButton} disabled={!isValid} onClick={create}>
                CREAR PERSONAJE
              </UnstyledButton>
            </Stack>
          </Box>
        </Box>
      </Box>
    </DatesProvider>
  );
}
