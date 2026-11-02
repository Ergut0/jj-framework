import { ActionIcon, Box, Group, ScrollArea, SimpleGrid, Text, Tooltip } from '@mantine/core';
import { FaLayerGroup, FaPowerOff } from 'react-icons/fa6';
import { ReferenceBlipBox } from '../components/ReferenceBlipBox';
import { referenceBlips, referenceColors } from '../data/references';
import { useAgentStore } from '../store/agent';
import { useRadioStore } from '../store/radio';
import { useReferenceStore } from '../store/references';
import { fetchNui } from '../utils/nui';
import styles from '../styles/ReferencesTab.module.css';

export function ReferenceColorBox({ blip, indexBlip }: any) {
  const { referenceColorId, setBlipColor } = useReferenceStore();
  const { radioChannels } = useRadioStore();
  const { agent } = useAgentStore();
  const c = referenceColorId === blip.id;
  const l = radioChannels.some((radioChannel) =>
    radioChannel.members?.some((e) => e.color === blip.id && e.citizenid !== agent?.citizenid),
  );
  let f = styles.referenceBoxColor;
  if (c) {
    f += ` ${styles.referenceBoxColorSelected}`;
  } else {
    if (l) {
      f += ` ${styles.referenceBoxColorInUseByOther}`;
    }
  }
  return (
    <Box
      className={f}
      style={{
        backgroundColor: blip.hex,
      }}
      onClick={() =>
        (async (e) => {
          await fetchNui('selectBlipColor', {
            colorId: e,
          });
          setBlipColor(e);
        })(blip.id)
      }
    >
      <Text c="black" fw="bold" size="sm">
        {indexBlip}
      </Text>
    </Box>
  );
}

export function ReferencesTab() {
  const { refTurned, changeRefStatus } = useReferenceStore();
  return (
    <Box
      style={{
        flex: 1,
        minHeight: 0,
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      <Group gap="xs" justify="space-between" w="100%">
        <Group gap="xs">
          <FaLayerGroup size={21} color="var(--mantine-color-green-1)" />
          <Text tt="uppercase" lts={0.7} c="white" fw="bold">
            Referencias
          </Text>
        </Group>
        <Tooltip
          label={refTurned ? 'Apagar Referencia' : 'Encender Referencia'}
          color="dark.6"
          withinPortal={false}
        >
          <ActionIcon
            c={refTurned ? 'red' : 'yellow.4'}
            variant="transparent"
            size="md"
            onClick={() => {
              changeRefStatus();
              fetchNui('changeRefStatus', {
                refTurned,
              });
            }}
          >
            <FaPowerOff size={21} />
          </ActionIcon>
        </Tooltip>
      </Group>
      <Box
        mt={10}
        style={{
          flex: '0 0 45%',
          minHeight: 0,
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        <Box className={styles.header}>
          <Text size="xs" tt="uppercase" c="green.2" fw={900} lts={1.9}>
            Iconos
          </Text>
        </Box>
        <ScrollArea
          style={{
            flex: 1,
            minHeight: 0,
          }}
          mt={13}
          type="always"
          scrollbarSize={3}
          scrollbars="y"
        >
          <SimpleGrid cols={6} spacing="sm" pb={8}>
            {referenceBlips.map(renderReferenceBlip)}
          </SimpleGrid>
        </ScrollArea>
      </Box>
      <Box
        mt={17}
        style={{
          flex: 1,
          minHeight: 0,
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        <Box className={styles.header}>
          <Text size="xs" tt="uppercase" c="green.2" fw={900} lts={1.9}>
            Colores
          </Text>
        </Box>
        <ScrollArea
          style={{
            flex: 1,
            minHeight: 0,
          }}
          mt={13}
          scrollbarSize={3}
          scrollbars="y"
        >
          <SimpleGrid cols={6} spacing="sm" pb={8}>
            {referenceColors.map(renderReferenceColor)}
          </SimpleGrid>
        </ScrollArea>
      </Box>
    </Box>
  );
}

export function renderReferenceColor(e, t) {
  return (
    <Box key={e.id}>
      <ReferenceColorBox blip={e} indexBlip={t} />
    </Box>
  );
}

export function renderReferenceBlip(e) {
  return (
    <Box key={e.id}>
      <ReferenceBlipBox blip={e} />
    </Box>
  );
}
