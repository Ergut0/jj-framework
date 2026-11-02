import { Box, Button, Flex, Group, Progress, Text, Title } from '@mantine/core';
import { IconGauge, IconUsers } from '@tabler/icons-react';
import type { UILang, VehicleData } from '../types';

const MAX_STAT = 10;

function Stat({ name, value }: { name: string; value: number }) {
  const score = Math.min(Math.max(value, 0), MAX_STAT);
  return (
    <Box mt={10}>
      <Group grow w="100%">
        <Text fw={500} fz="md" fs="italic" className="info-field">{name}</Text>
        <Text fw={500} fz="md" ta="right" fs="italic" className="info-field">{`${Math.round(score)} / ${MAX_STAT}`}</Text>
      </Group>
      <Progress color="var(--accent)" size="xs" value={(score / MAX_STAT) * 100} />
    </Box>
  );
}

interface Props {
  vehicle: VehicleData;
  lang: UILang;
  tall: boolean;
  onBuy: () => void;
  onTest: () => void;
}

export function VehicleInfo({ vehicle, lang, tall, onBuy, onTest }: Props) {
  return (
    <div className="info-layer">
      <Flex
        justify="flex-end"
        align="flex-start"
        direction="column"
        wrap="nowrap"
        className="info-container"
        style={{ scale: tall ? '1' : '0.85', marginTop: tall ? '1%' : undefined, marginLeft: tall ? '1%' : undefined }}
      >
        <Box className="info-header">
          <Group grow w="100%" p={5} className="info-top">
            <Flex justify="flex-end" align="flex-start" direction="column" wrap="nowrap">
              <Text tt="uppercase" fs="italic" className="info-brand">{vehicle.brand}</Text>
              <Text c="dimmed" fz={20} mt={-10} tt="uppercase" className="info-name" truncate>{vehicle.label}</Text>
            </Flex>
            <Title mt={9} order={1} ta="right" className="info-class">{vehicle.class}</Title>
          </Group>
        </Box>

        <Box className="info-stats" mb={10} p={5} mt={-10}>
          {Object.keys(vehicle.info).sort().map((key) => (
            <Stat key={key} name={vehicle.info[key].name} value={vehicle.info[key].value} />
          ))}
        </Box>

        <Group grow w="100%" p={5} mb={10}>
          <Group gap={0}>
            <IconGauge size="0.95rem" />
            <Text ml={5} tt="uppercase" className="info-field">{`${vehicle.speed} ${vehicle.unit}`}</Text>
          </Group>
          <Group gap={0}>
            <IconUsers size="0.95rem" />
            <Text ml={5} className="info-field">{`${vehicle.seats} ${lang.seats}`}</Text>
          </Group>
        </Group>

        {vehicle.buy && (
          <Button w="95%" color="var(--accent)" c="gray.3" className="info-button" onClick={onBuy}>{lang.buy_button}</Button>
        )}
        {vehicle.test && (
          <Button w="95%" mt={10} color="var(--accent)" c="gray.3" className="info-button" onClick={onTest}>{lang.test_button}</Button>
        )}
        <Box h={10} />
      </Flex>
    </div>
  );
}
