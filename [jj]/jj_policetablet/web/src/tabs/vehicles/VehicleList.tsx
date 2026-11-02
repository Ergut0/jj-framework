import { Badge, Box, Button, Group, Image, ScrollArea, Stack, Text, TextInput } from '@mantine/core';
import { useState } from 'react';
import { FaCar as FaCar2, FaCreditCard, FaIdCard, FaSearch } from 'react-icons/fa';
import { fetchNui } from '../../utils/nui';
import styles from '../../styles/Vehicles.module.css';

export function VehicleList({ onSelectVehicle, vehicles, onSelectVehicles }: any) {
  const [search, setSearch] = useState<any>('');
  const handleClick = async () => {
    const response = await fetchNui('getVehiclesByFilter', {
      filter: search.toUpperCase(),
    });
    onSelectVehicles(response);
  };
  return (
    <Box className={styles.searchContainer}>
      <Text fw={700} size="lg" mb="md" className={styles.title}>
        <FaCar2
          size={26}
          style={{
            marginRight: 8,
          }}
        />
        Búsqueda de Vehículos
      </Text>
      <Group gap="xs" mb="lg">
        <TextInput
          placeholder="Matrícula"
          className={styles.searchInput}
          size="sm"
          value={search}
          onKeyDown={(event) => {
            if (event.key === 'Enter') {
              handleClick();
            }
          }}
          onChange={(event) => setSearch(event.currentTarget.value)}
        />
        <Button size="sm" variant="default" onClick={handleClick}>
          <FaSearch />
        </Button>
      </Group>
      <ScrollArea className={styles.scrollAreaSearch} w="100%" type="never">
        <Stack gap="xs">
          {vehicles.map((vehicle) => (
            <Box key={vehicle.id} className={styles.vehicleCard} onClick={() => onSelectVehicle(vehicle)}>
              <Group wrap="nowrap" gap="md" align="flex-start">
                <Image
                  fallbackSrc="default-car.png"
                  src={vehicle.image}
                  className={styles.vehicleCardAvatar}
                  radius="sm"
                />
                <Stack gap={9}>
                  <Group justify="space-between" wrap="nowrap">
                    <Text fw={600} size="lg" c="var(--text-primary)">
                      {vehicle.model}
                    </Text>
                  </Group>
                  <Group gap="md">
                    <Badge
                      color="dark.2"
                      variant="light"
                      c="dark.1"
                      radius="sm"
                      leftSection={<FaIdCard size={12} />}
                    >
                      {vehicle.owner}
                    </Badge>
                    <Badge
                      color="dark.2"
                      variant="light"
                      c="dark.1"
                      radius="sm"
                      leftSection={<FaCreditCard size={12} />}
                    >
                      {vehicle.plate}
                    </Badge>
                  </Group>
                </Stack>
              </Group>
            </Box>
          ))}
        </Stack>
      </ScrollArea>
    </Box>
  );
}
