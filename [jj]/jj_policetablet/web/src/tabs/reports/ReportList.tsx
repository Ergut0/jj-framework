import { Avatar, Badge, Box, Button, Group, ScrollArea, Select, Stack, Text, TextInput } from '@mantine/core';
import { DatePickerInput } from '@mantine/dates';
import { useState } from 'react';
import { FaBox, FaClock, FaSearch, FaSpinner } from 'react-icons/fa';
import { useRecoilValue } from 'recoil';
import { IconG5 } from '../../icons';
import { agentAtom, usePermissions } from '../../state/atoms';
import { fetchNui, isBrowser } from '../../utils/nui';
import styles from '../../styles/Reports.module.css';

export const reportCategories = [
  {
    key: 'ia',
    label: 'IAD LSPD',
    permission: 'reports.access.ia',
    dept: 'lspd',
  },
  {
    key: 'detectives',
    label: 'DETECTIVES LSPD',
    permission: 'reports.access.detectives',
    dept: 'lspd',
  },
  {
    key: 'sargentos',
    label: 'SARGENTOS LSPD',
    permission: 'reports.access.sargentos',
    dept: 'lspd',
  },
  {
    key: 'ia_lssd',
    label: 'IAD LSSD',
    permission: 'reports.access.ia',
    dept: 'lssd',
  },
  {
    key: 'detectives_lssd',
    label: 'DETECTIVES LSSD',
    permission: 'reports.access.detectives',
    dept: 'lssd',
  },
  {
    key: 'sargentos_lssd',
    label: 'SARGENTOS LSSD',
    permission: 'reports.access.sargentos',
    dept: 'lssd',
  },
];

export function ReportList({ reports, onSelectReport, setReports }: any) {
  const [query, setQuery] = useState<any>('');
  const [categoryFilter, setCategoryFilter] = useState<any>('all');
  const [dateFilter, setDateFilter] = useState<any>(null);
  const { haveRankPerms } = usePermissions();
  const h = useRecoilValue<any>(agentAtom);
  const g =
    h?.department?.toLowerCase() === 'lssd' || h?.department?.toLowerCase() === 'sheriff' ? 'lssd' : 'lspd';
  const v = reportCategories.filter(
    (reportCategory) => reportCategory.dept === g && haveRankPerms([reportCategory.permission]),
  );
  const y = (j) =>
    j === 'detective'
      ? 'detectives'
      : j === 'ia'
        ? 'ia'
        : j === 'sargentos'
          ? 'sargentos'
          : j === 'detectives_lssd'
            ? 'detectives_lssd'
            : j === 'ia_lssd'
              ? 'ia_lssd'
              : j === 'sargentos_lssd'
                ? 'sargentos_lssd'
                : j;
  const S = reports
    .filter((report) => {
      const T = y(report.division ?? 'ia');
      return v.some((item) => item.key === T);
    })
    .filter((report) => (categoryFilter === 'all' ? true : y(report.division ?? 'ia') === categoryFilter));
  const w = async (j = dateFilter) => {
    if (isBrowser()) {
      return;
    }
    const [T, E, A] = j ? j.split('-') : [];
    const I = [
      ...((await fetchNui('searchReports', {
        query,
        date: j ? `${A}/${E}/${T}` : null,
      })) ?? []),
    ].sort((B, U) => (U.id ?? 0) - (B.id ?? 0));
    setReports(I);
  };
  return (
    <>
      <Group gap="xs" px="md" pt="md">
        <IconG5 size={26} color="white" />
        <Text size="lg" fw={700} c="white" flex={1}>
          Busqueda de Incidentes
        </Text>
      </Group>
      <Group px="md" gap={11}>
        <TextInput
          flex={1}
          placeholder="Titulo del incidente"
          value={query}
          onKeyDown={(event) => {
            if (event.key === 'Enter') {
              w();
            }
          }}
          onChange={(event) => setQuery(event.target.value)}
        />
        <Button size="sm" variant="default" onClick={() => w()}>
          <FaSearch />
        </Button>
      </Group>
      <Group px="md" mt={8} wrap="nowrap">
        <DatePickerInput
          flex={1}
          label="Filtrar por día"
          placeholder="Cualquier día"
          locale="es"
          valueFormat="DD/MM/YYYY"
          clearable
          value={dateFilter}
          onChange={(j) => {
            setDateFilter(j);
            w(j);
          }}
        />
        <Select
          flex={1}
          label="Filtrar por tipo"
          placeholder="Tipo de incidente"
          value={categoryFilter}
          onChange={(j) => setCategoryFilter(j ?? 'all')}
          data={[
            {
              value: 'all',
              label: 'Todos',
            },
            ...v.map((item) => ({
              value: item.key,
              label: item.label,
            })),
          ]}
          allowDeselect={false}
          disabled={v.length === 0}
        />
      </Group>
      <ScrollArea className={styles.scrollAreaSearch} w="100%" type="never">
        <Stack gap="xs" px="sm">
          {v.length === 0 ? (
            <Text c="dimmed" ta="center" mt="lg">
              No tienes permisos para acceder a secciones de incidentes.
            </Text>
          ) : S.length === 0 ? (
            <Text c="dimmed" ta="center" mt="lg">
              No hay incidentes para el filtro seleccionado.
            </Text>
          ) : (
            S.map((item) => (
              <Box key={item.id} className={styles.incidentCard} onClick={() => onSelectReport(item)}>
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
            ))
          )}
        </Stack>
      </ScrollArea>
    </>
  );
}
