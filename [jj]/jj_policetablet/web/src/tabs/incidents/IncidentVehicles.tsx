import {
  ActionIcon,
  Badge,
  Box,
  Button,
  Grid,
  Group,
  Image,
  Modal,
  ScrollArea,
  Stack,
  Text,
  TextInput,
  Title,
} from '@mantine/core';
import { useState } from 'react';
import { FaCarAlt, FaCreditCard, FaPlus, FaSearch } from 'react-icons/fa';
import { FaTrash as FaTrash2 } from 'react-icons/fa6';
import { mockCitizens } from '../../data/mockCitizens';
import { fetchNui, isBrowser, openEntityTab } from '../../utils/nui';
import stylesForm from '../../styles/Form.module.css';
import stylesIncidents from '../../styles/Incidents.module.css';

export function AddIncidentVehicleModal({ opened, onClose, selectedIncident, setSelectedIncident }: any) {
  const [results, setResults] = useState<any>([]);
  const [search, setSearch] = useState<any>('');
  const handleClick = async () => {
    if (search.length === 0) {
      return;
    }
    if (isBrowser()) {
      const g = mockCitizens
        .flatMap((mockCitizen) => mockCitizen.vehicles ?? [])
        .filter(
          (item) =>
            item.plate.toLowerCase().includes(search.toLowerCase()) ||
            item.model.toLowerCase().includes(search.toLowerCase()),
        );
      setResults(g);
      return;
    }
    const response = await fetchNui('getVehiclesIncidents', search.toLowerCase());
    setResults(response);
  };
  const f = (h) => {
    setSelectedIncident({
      ...selectedIncident,
      vehicles: [...(selectedIncident.vehicles ?? []), h],
    });
    onClose();
  };
  return (
    <Modal opened={opened} onClose={onClose} title="Vehículos" centered size={450}>
      <Stack mt="sm">
        <Group justify="flex-start" gap="xs">
          <TextInput
            flex={0.9}
            placeholder="Matrícula o modelo"
            label="Buscar vehículo"
            description="Ingrese la matrícula o modelo del vehículo"
            value={search}
            onChange={(event) => setSearch(event.currentTarget.value)}
          />
          <Button flex={0.1} mt={47} className={stylesForm.button} onClick={handleClick}>
            <FaSearch size={12} />
          </Button>
        </Group>
        <ScrollArea h={230} offsetScrollbars scrollbarSize={3}>
          <Stack flex={1} gap="xs">
            {results.length === 0 ? (
              <Text c="dimmed" mx="auto">
                No se han encontrado vehículos.
              </Text>
            ) : (
              results.map((result) => (
                <Box key={result.id} className={stylesIncidents.boxItem} onClick={() => f(result)} p="sm">
                  <Group justify="flex-start" align="center">
                    <Image radius="sm" w={60} src={result.image} fallbackSrc="default-car.png" />
                    <Stack flex={1} gap="xs">
                      <Group justify="space-between" align="center">
                        <Title order={4}>{result.model}</Title>
                        {result.incauted && (
                          <Badge size="sm" color="orange" variant="light" radius="sm">
                            INCAUTADO
                          </Badge>
                        )}
                      </Group>
                      <Badge size="sm" color="dark.1" variant="light" radius="sm">
                        {'Matrícula: '}
                        {result.plate}
                      </Badge>
                    </Stack>
                  </Group>
                </Box>
              ))
            )}
          </Stack>
        </ScrollArea>
      </Stack>
    </Modal>
  );
}

export function IncidentVehicles({ selectedIncident, setSelectedIncident, canEdit = true }: any) {
  const [addOpen, setAddOpen] = useState<any>(false);
  const s = (a) => {
    setSelectedIncident({
      ...selectedIncident,
      vehicles: (selectedIncident.vehicles ?? []).filter((item, index) => index !== a),
    });
  };
  const i = (a) => {
    openEntityTab({
      type: 'vehicle',
      plate: a,
    });
  };
  return (
    <>
      <Grid.Col
        span={5.92}
        className={stylesIncidents.infoSectionBox}
        mt={15}
        mih="45vh"
        mah="45vh"
        p="sm"
        px="lg"
      >
        <Group justify="space-between">
          <Group gap={9}>
            <FaCarAlt size={20} />
            <Text size="lg" fw="bold" c="var(--text-primary)">
              Vehículos
            </Text>
          </Group>
          {canEdit && (
            <Button className={stylesForm.button} size="xs" onClick={() => setAddOpen(true)}>
              <FaPlus size={12} />
            </Button>
          )}
        </Group>
        <ScrollArea mt="sm" h="38vh" offsetScrollbars scrollbarSize={3}>
          <Stack gap="sm">
            {selectedIncident.vehicles && selectedIncident.vehicles.length > 0 ? (
              selectedIncident.vehicles.map((vehicle, index) => (
                <Box
                  key={`${vehicle.id}-${index}`}
                  className={stylesIncidents.boxItem}
                  p="sm"
                  style={{
                    cursor: 'pointer',
                  }}
                  onClick={() => i(vehicle.plate)}
                >
                  <Group justify="flex-start" align="center">
                    <Image radius="sm" w={60} src={vehicle.image} fallbackSrc="default-car.png" />
                    <Stack flex={1} gap="xs">
                      <Group justify="space-between" align="center">
                        <Title order={4}>{vehicle.model}</Title>
                        <Group gap={6}>
                          {vehicle.incauted && (
                            <Badge size="sm" color="orange" variant="light" radius="sm">
                              INCAUTADO
                            </Badge>
                          )}
                          {canEdit && (
                            <ActionIcon
                              size="sm"
                              color="red"
                              variant="subtle"
                              onClick={(event) => {
                                event.stopPropagation();
                                s(index);
                              }}
                            >
                              <FaTrash2 size={12} />
                            </ActionIcon>
                          )}
                        </Group>
                      </Group>
                      <Badge
                        size="sm"
                        color="dark.1"
                        variant="light"
                        radius="sm"
                        leftSection={<FaCreditCard size={10} />}
                      >
                        {vehicle.plate}
                      </Badge>
                    </Stack>
                  </Group>
                </Box>
              ))
            ) : (
              <Text c="dimmed" mt="lg" mx="auto">
                No hay vehículos asignados.
              </Text>
            )}
          </Stack>
        </ScrollArea>
      </Grid.Col>
      {addOpen && (
        <AddIncidentVehicleModal
          opened={addOpen}
          onClose={() => setAddOpen(false)}
          selectedIncident={selectedIncident}
          setSelectedIncident={setSelectedIncident}
        />
      )}
    </>
  );
}
