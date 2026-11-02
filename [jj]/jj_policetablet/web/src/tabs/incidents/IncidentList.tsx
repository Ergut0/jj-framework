import { Avatar, Badge, Box, Button, Group, ScrollArea, Stack, Text, TextInput } from '@mantine/core';
import { DatePickerInput } from '@mantine/dates';
import { useState } from 'react';
import { FaBox, FaClock, FaSearch, FaSpinner } from 'react-icons/fa';
import { TiWarning } from 'react-icons/ti';
import { fetchNui, isBrowser } from '../../utils/nui';
import styles from '../../styles/Incidents.module.css';

export function IncidentList({ incidents, onSelectIncident, setIncidents }: any) {
  const [query, setQuery] = useState<any>('');
  const [dateFilter, setDateFilter] = useState<any>(null);
  const a = async (f = dateFilter) => {
    if (isBrowser()) {
      return;
    }
    const [h, p, g] = f ? f.split('-') : [];
    const response = await fetchNui('searchIncidents', {
      query,
      date: f ? `${g}/${p}/${h}` : null,
    });
    setIncidents(response);
  };
  const u = incidents.sort((f, h) => (h.id ?? 0) - (f.id ?? 0));
  return (
    <>
      <Group gap="xs" px="md" pt="md">
        <TiWarning size={26} color="white" />
        <Text size="lg" fw={700} c="white" flex={1}>
          Búsqueda de Informes
        </Text>
      </Group>
      <Group px="md" gap={11}>
        <TextInput
          flex={1}
          placeholder="Titulo del informe"
          value={query}
          onKeyDown={(event) => {
            if (event.key === 'Enter') {
              a();
            }
          }}
          onChange={(event) => setQuery(event.target.value)}
        />
        <Button size="sm" variant="default" onClick={() => a()}>
          <FaSearch />
        </Button>
      </Group>
      <Group px="md" mt={8}>
        <DatePickerInput
          flex={1}
          label="Filtrar por día"
          placeholder="Cualquier día"
          locale="es"
          valueFormat="DD/MM/YYYY"
          clearable
          value={dateFilter}
          onChange={(f) => {
            setDateFilter(f);
            a(f);
          }}
        />
      </Group>
      <ScrollArea className={styles.scrollAreaSearch} w="100%" type="never">
        <Stack gap="xs" px="sm">
          {u.map((item) => (
            <Box key={item.id} className={styles.incidentCard} onClick={() => onSelectIncident(item)}>
              <Group gap="xs">
                <Avatar radius="sm" size={60}>
                  <FaBox />
                </Avatar>
                <Stack gap={10}>
                  <Box w="210">
                    <Text fw={600} size="md" c="var(--text-primary)" truncate tt="uppercase">
                      #{item.id}
                      {' - '}
                      {item.title}
                    </Text>
                  </Box>
                  <Group gap={10}>
                    <Badge
                      color="dark.2"
                      variant="light"
                      size="xs"
                      c="dark.1"
                      radius="sm"
                      leftSection={<FaClock />}
                    >
                      {item.date}
                    </Badge>
                    <Badge
                      color={item.status === 'open' ? 'green' : 'red'}
                      variant="light"
                      size="xs"
                      radius="sm"
                      leftSection={<FaSpinner />}
                    >
                      {item.status === 'open' ? 'Abierto' : 'Cerrado'}
                    </Badge>
                  </Group>
                </Stack>
              </Group>
            </Box>
          ))}
        </Stack>
      </ScrollArea>
    </>
  );
}
