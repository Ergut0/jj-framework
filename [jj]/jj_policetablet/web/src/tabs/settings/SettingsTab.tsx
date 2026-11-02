import { Badge, Box, Button, Card, Group, ScrollArea, Stack, Text, Title } from '@mantine/core';
import { useMemo } from 'react';
import { useRecoilState, useRecoilValue } from 'recoil';
import { agentAtom, ranksAgentsAtom } from '../../state/atoms';
import { fetchNui } from '../../utils/nui';
import styles from '../../styles/Settings.module.css';

export const permissionInfo = {
  'citizens.access': {
    label: 'Acceder a ciudadanos',
    value: 'citizens.access',
  },
  'incidents.access': {
    label: 'Acceder a informes',
    value: 'incidents.access',
  },
  'reports.access': {
    label: 'Acceder a incidentes',
    value: 'reports.access',
  },
  'penalcode.access': {
    label: 'Acceder a código penal',
    value: 'penalcode.access',
  },
  'debtors.access': {
    label: 'Acceder a deudores',
    value: 'debtors.access',
  },
  'penalcode.create': {
    label: 'Crear articulos de codigo penal',
    value: 'penalcode.create',
  },
  'penalcode.edit': {
    label: 'Editar articulos de codigo penal',
    value: 'penalcode.edit',
  },
  'penalcode.delete': {
    label: 'Eliminar articulos de codigo penal',
    value: 'penalcode.delete',
  },
  'citizen.notes.delete': {
    label: 'Eliminar notas de ciudadano',
    value: 'citizen.notes.delete',
  },
  'citizen.bills.delete': {
    label: 'Eliminar multas de ciudadano',
    value: 'citizen.bills.delete',
  },
  'home.notes.create': {
    label: 'Crear anuncios',
    value: 'home.notes.create',
  },
  'home.notes.edit': {
    label: 'Editar anuncios',
    value: 'home.notes.edit',
  },
  'home.notes.delete': {
    label: 'Eliminar anuncios',
    value: 'home.notes.delete',
  },
  'incidents.delete': {
    label: 'Eliminar informes',
    value: 'incidents.delete',
  },
  'incidents.edit': {
    label: 'Editar informes',
    value: 'incidents.edit',
  },
  'reports.delete': {
    label: 'Eliminar incidentes',
    value: 'reports.delete',
  },
  'reports.edit': {
    label: 'Editar incidentes',
    value: 'reports.edit',
  },
  'reports.access.ia': {
    label: 'Acceder a incidentes de IA',
    value: 'reports.access.ia',
  },
  'reports.access.detectives': {
    label: 'Acceder a incidentes de Detectives',
    value: 'reports.access.detectives',
  },
  'reports.access.sargentos': {
    label: 'Acceder a incidentes de Sargentos',
    value: 'reports.access.sargentos',
  },
  'agents.edit': {
    label: 'Editar información de agentes',
    value: 'agents.edit',
  },
  'agents.add': {
    label: 'Añadir agentes',
    value: 'agents.add',
  },
  'federal.access': {
    label: 'Acceder a panel de federal',
    value: 'federal.access',
  },
  'camera.use': {
    label: 'Hacer fotos con la tablet',
    value: 'camera.use',
  },
};

export function SettingsTab() {
  const [e, t] = useRecoilState<any>(ranksAgentsAtom);
  const n = useRecoilValue<any>(agentAtom);
  const r = useMemo(() => {
    const i = Object.values(permissionInfo).map((item) => item.value);
    const a = e.flatMap((item) => item.permissions);
    return Array.from(new Set<any>([...i, ...a])).sort();
  }, [e]);
  const o = async (i, a) => {
    const u = e.find((item) => item.id === i);
    if (!u) {
      return;
    }
    const permissions = u.permissions.includes(a)
      ? u.permissions.filter((permission) => permission !== a)
      : [...u.permissions, a].sort();
    t((g) =>
      g.map((item) =>
        item.id === i
          ? {
              ...item,
              permissions,
            }
          : item,
      ),
    );
    if (
      !(
        await fetchNui('saveRankPermissions', {
          rankId: i,
          rankGrade: u.grade,
          permissions,
        })
      )?.success
    ) {
      t((g) =>
        g.map((item) =>
          item.id === i
            ? {
                ...item,
                permissions: u.permissions,
              }
            : item,
        ),
      );
    }
  };
  return e.some((item) => item.id === n?.rank_id && item.isBoss) ? (
    <Stack p="sm" gap="md">
      <Box className={styles.header}>
        <Title order={4} tt="uppercase" lts={0.7}>
          Configuracion de permisos por rango
        </Title>
        <Text size="sm" c="dimmed">
          Activa o desactiva permisos individuales para cada rango.
        </Text>
      </Box>
      {r.length === 0 ? (
        <Card className={styles.emptyState} withBorder radius="md" p="md">
          <Text size="sm" c="dimmed">
            No hay permisos definidos en los rangos actualmente.
          </Text>
        </Card>
      ) : (
        <ScrollArea h="78vh" offsetScrollbars scrollbarSize={4}>
          <Stack gap="md" pr="xs">
            {e
              .slice()
              .sort((i, a) => i.grade - a.grade)
              .map((item) => (
                <Card key={item.id} withBorder radius="md" p="md" className={styles.rankCard}>
                  <Group justify="space-between" align="center" mb="sm">
                    <Group gap="xs">
                      <Title order={5}>{item.label}</Title>
                      <Badge color="dark.1" variant="light" radius="sm">
                        {'Grado '}
                        {item.grade}
                      </Badge>
                      {item.isBoss && (
                        <Badge color="yellow" variant="light" radius="sm">
                          Boss
                        </Badge>
                      )}
                    </Group>
                    <Badge color="blue" variant="light" radius="sm">
                      {item.permissions.length}
                      {' permisos activos'}
                    </Badge>
                  </Group>
                  <Box className={styles.permissionsGrid}>
                    {r.map((item2) => {
                      const u = item.permissions.includes(item2);
                      const f = permissionInfo[item2] ?? {
                        label: item2,
                        value: item2,
                      };
                      return (
                        <Button
                          key={`${item.id}-${item2}`}
                          className={styles.permissionButton}
                          variant={u ? 'filled' : 'light'}
                          color={u ? 'green' : 'gray'}
                          radius="sm"
                          onClick={() => o(item.id, item2)}
                        >
                          <span className={styles.permissionTextWrap}>
                            <span className={styles.permissionLabel}>{f.label}</span>
                            <span className={styles.permissionValue}>{f.value}</span>
                          </span>
                        </Button>
                      );
                    })}
                  </Box>
                </Card>
              ))}
          </Stack>
        </ScrollArea>
      )}
    </Stack>
  ) : (
    <Group h="88.3vh" justify="center" align="center">
      <Text c="dimmed" size="lg">
        No tienes permisos para acceder a la configuración de permisos.
      </Text>
    </Group>
  );
}
