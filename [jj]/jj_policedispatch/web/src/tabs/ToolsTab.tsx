import { Box, Group, ScrollArea, Stack, Text } from '@mantine/core';
import { FaArchive } from 'react-icons/fa';
import { FaRoad } from 'react-icons/fa6';
import { useAgentStore } from '../store/agent';
import { fetchNui } from '../utils/nui';
import styles from '../styles/ToolsTab.module.css';

export function ToolButton({ icon, title, desc, onClick }: any) {
  return (
    <Box
      className={styles.toolsBox}
      onClick={onClick}
      style={{
        cursor: onClick ? 'pointer' : 'default',
      }}
    >
      <Group grow>
        <Box className={styles.icon}>{icon}</Box>
        <Stack gap={3} maw="80%">
          <Text c="white" fw="bold" lts={0.7}>
            {title}
          </Text>
          <Text c="dark.1" size="xs">
            {desc}
          </Text>
        </Stack>
      </Group>
    </Box>
  );
}

export const statusCodes = [
  {
    id: '10.8',
    label: '10.8',
    desc: 'A la espera de asignación',
    variant: 'default',
  },
  {
    id: '10.10',
    label: '10.10',
    desc: 'Realiza su 10.10. Buen servicio!',
    variant: 'default',
  },
  {
    id: 'COD 7',
    label: 'COD 7',
    desc: 'Parada técnica',
    variant: 'default',
  },
  {
    id: '254-V',
    label: '254-V',
    desc: 'Persecución: Modelo y matrícula',
    variant: 'default',
  },
  {
    id: 'COD 2',
    label: 'COD 2',
    desc: 'Patrullaje ordinario',
    variant: 'default',
  },
  {
    id: 'VEH 488',
    label: 'VEH 488',
    desc: 'Vehículo implicado en el 488',
    variant: 'default',
  },
  {
    id: 'VEH 487',
    label: 'VEH 487',
    desc: 'Vehículo implicado en el 487',
    variant: 'default',
  },
  {
    id: '10.6',
    label: '10.6',
    desc: 'Parada de tráfico: Modelo y matrícula',
    variant: 'default',
  },
  {
    id: '10.20',
    label: '10.20',
    desc: 'Envía tu ubicación actual',
    variant: 'default',
  },
  {
    id: '444',
    label: '444',
    desc: 'Agente implicado en tiroteo en peligro',
    variant: 'default',
  },
  {
    id: 'QAB',
    label: 'QAB',
    desc: 'Todos los agentes del Táctico abatidos',
    variant: 'blue',
  },
  {
    id: 'QRR',
    label: 'QRR',
    desc: 'Agente en peligro (entorno rojo)',
    variant: 'red',
  },
];

export function ToolsTab() {
  const { agent } = useAgentStore();
  const r = (e) => {
    fetchNui('triggerTool', {
      action: e,
      agentName: agent?.fullname,
      agentRank: agent?.rank,
    });
  };
  let c;
  c = (
    <Box className={styles.header}>
      <Text size="xs" tt="uppercase" c="green.2" fw={900} lts={1.9}>
        Interacción general
      </Text>
    </Box>
  );
  return (
    <Box className={styles.container}>
      <Group gap="xs">
        <FaArchive size={18} color="var(--mantine-color-green-1)" />
        <Text tt="uppercase" lts={0.7} c="white" fw="bold">
          Procedimientos
        </Text>
      </Group>
      <Box className={styles.radioSection}>
        <Box className={styles.header}>
          <Text size="xs" tt="uppercase" c="green.2" fw={900} lts={1.9}>
            Comunicación radial
          </Text>
        </Box>
        <ScrollArea className={styles.scrollArea} mt={13} scrollbarSize={3} scrollbars="y">
          <Box className={styles.codeGrid} pb={8} pr={4}>
            {statusCodes.map((statusCode) => {
              let t = styles.codeButton;
              if (statusCode.variant === 'blue') {
                t += ` ${styles.codeButtonBlue}`;
              }
              if (statusCode.variant === 'red') {
                t += ` ${styles.codeButtonRed}`;
              }
              return (
                <Box
                  key={statusCode.id}
                  className={t}
                  title={statusCode.desc}
                  onClick={() => r(statusCode.id)}
                >
                  <Text className={styles.codeText}>{statusCode.label}</Text>
                </Box>
              );
            })}
          </Box>
        </ScrollArea>
      </Box>
      <Box className={styles.generalSection}>
        {c}
        <ScrollArea className={styles.scrollArea} mt={13} scrollbarSize={3} scrollbars="y">
          <Stack gap="xs" pb={8} pr={4}>
            <ToolButton
              icon={<FaRoad size={16} />}
              title="Parar tráfico"
              desc="Para el tráfico para que los civiles no molesten en el operativo."
              onClick={() => r('stop_traffic')}
            />
            <ToolButton
              icon={<FaRoad size={16} />}
              title="Reanudar tráfico"
              desc="Reanuda el tráfico para que vuelva todo a la normalidad."
              onClick={() => r('resume_traffic')}
            />
          </Stack>
        </ScrollArea>
      </Box>
    </Box>
  );
}
