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
import { FaIdCard, FaPhone, FaPlus, FaSearch, FaUsers as FaUsers2 } from 'react-icons/fa';
import { FaTrash as FaTrash2 } from 'react-icons/fa6';
import { mockCitizens } from '../../data/mockCitizens';
import { fetchNui, isBrowser, openEntityTab } from '../../utils/nui';
import stylesForm from '../../styles/Form.module.css';
import stylesIncidents from '../../styles/Incidents.module.css';

export function AddIncidentVictimModal({ opened, onClose, selectedIncident, setSelectedIncident }: any) {
  const [results, setResults] = useState<any>([]);
  const [search, setSearch] = useState<any>('');
  const u = (p) =>
    search.length === 0
      ? []
      : p.filter(
          (item) =>
            `${item.firstname} ${item.lastname}`.toLowerCase().includes(search.toLowerCase()) ||
            item.citizenid.toLowerCase().includes(search.toLowerCase()),
        );
  const handleClick = async () => {
    if (search.length === 0) {
      return;
    }
    if (isBrowser()) {
      setResults(u(mockCitizens));
      return;
    }
    const response = await fetchNui('getCitizensIncidents', search.toLowerCase());
    setResults(response);
  };
  const h = (p) => {
    setSelectedIncident({
      ...selectedIncident,
      victims: [...(selectedIncident.victims ?? []), p],
    });
    onClose();
  };
  return (
    <Modal opened={opened} onClose={onClose} title="Victimas" centered size={450}>
      <Stack mt="sm">
        <Group justify="flex-start" gap="xs">
          <TextInput
            flex={0.9}
            placeholder="Nombre, apellidos o ID"
            label="Buscar victima"
            description="Ingrese el nombre o ID de la victima que desea buscar"
            value={search}
            onChange={(event) => setSearch(event.currentTarget.value)}
          />
          <Button flex={0.1} mt={47} className={stylesForm.button} onClick={handleClick}>
            <FaSearch size={12} />
          </Button>
        </Group>
        <ScrollArea mt="sm" h="38vh" offsetScrollbars scrollbarSize={3}>
          <Stack flex={1} gap="xs">
            {results.length === 0 ? (
              <Text c="dimmed" mx="auto">
                No se han encontrado victimas.
              </Text>
            ) : (
              results.map((result) => (
                <Box
                  key={result.citizenid}
                  className={stylesIncidents.boxItem}
                  onClick={() => h(result)}
                  p="sm"
                >
                  <Group justify="flex-start" align="flex-start">
                    <Image radius="sm" w={60} src={result.imageUrl} fallbackSrc="default-user.webp" />
                    <Stack flex={1} gap="xs">
                      <Group justify="space-between" align="center">
                        <Title order={4}>
                          {result.firstname} {result.lastname}
                        </Title>
                        {result.isWanted && (
                          <Badge size="sm" color="red" variant="light" radius="sm">
                            BUSCADO
                          </Badge>
                        )}
                      </Group>
                      <Group>
                        <Badge
                          size="sm"
                          color="dark.1"
                          variant="light"
                          radius="sm"
                          leftSection={<FaIdCard size={12} />}
                        >
                          {result.citizenid}
                        </Badge>
                        <Badge
                          size="sm"
                          color="dark.1"
                          variant="light"
                          radius="sm"
                          leftSection={<FaPhone size={12} />}
                        >
                          {result.phoneNumber}
                        </Badge>
                      </Group>
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

export function IncidentVictims({ selectedIncident, setSelectedIncident, canEdit = true }: any) {
  const [addOpen, setAddOpen] = useState<any>(false);
  const s = (i) => {
    setSelectedIncident({
      ...selectedIncident,
      victims: (selectedIncident.victims ?? []).filter((item, index) => index !== i),
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
            <FaUsers2 size={21} />
            <Text size="lg" fw="bold" c="var(--text-primary)">
              Victimas
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
            {selectedIncident.victims && selectedIncident.victims.length > 0 ? (
              selectedIncident.victims.map((victim, index) => (
                <Box
                  key={`${victim.citizenid}-${index}`}
                  className={stylesIncidents.boxItem}
                  p="sm"
                  style={{
                    cursor: 'pointer',
                  }}
                  onClick={() =>
                    openEntityTab({
                      type: 'citizen',
                      citizenId: victim.citizenid,
                    })
                  }
                >
                  <Group justify="flex-start" align="flex-start">
                    <Image radius="sm" w={60} h={60} src={victim.imageUrl} fallbackSrc="default-user.webp" />
                    <Stack flex={1} gap="xs">
                      <Group justify="space-between" align="center">
                        <Title order={4}>
                          {victim.firstname} {victim.lastname}
                        </Title>
                        <Group gap={6}>
                          {victim.isWanted && (
                            <Badge size="sm" color="red" variant="light" radius="sm">
                              BUSCADO
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
                      <Group>
                        <Badge
                          size="sm"
                          color="dark.1"
                          variant="light"
                          radius="sm"
                          leftSection={<FaIdCard size={12} />}
                        >
                          {victim.citizenid}
                        </Badge>
                        <Badge
                          size="sm"
                          color="dark.1"
                          variant="light"
                          radius="sm"
                          leftSection={<FaPhone size={12} />}
                        >
                          {victim.phoneNumber}
                        </Badge>
                      </Group>
                    </Stack>
                  </Group>
                </Box>
              ))
            ) : (
              <Text c="dimmed" mt="lg" mx="auto">
                No hay victimas asignadas.
              </Text>
            )}
          </Stack>
        </ScrollArea>
      </Grid.Col>
      {addOpen && (
        <AddIncidentVictimModal
          opened={addOpen}
          onClose={() => setAddOpen(false)}
          selectedIncident={selectedIncident}
          setSelectedIncident={setSelectedIncident}
        />
      )}
    </>
  );
}
