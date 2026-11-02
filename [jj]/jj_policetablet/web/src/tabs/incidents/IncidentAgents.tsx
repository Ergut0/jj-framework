import {
  ActionIcon,
  Badge,
  Box,
  Button,
  Divider,
  Grid,
  Group,
  Image,
  Modal,
  Popover,
  ScrollArea,
  Select,
  Stack,
  Text,
  TextInput,
  Title,
  Tooltip,
} from '@mantine/core';
import { useState } from 'react';
import { FaIdCard, FaPhone, FaPlus, FaSearch } from 'react-icons/fa';
import { FaTrash as FaTrash2, FaWalkieTalkie } from 'react-icons/fa6';
import { HiDotsVertical } from 'react-icons/hi';
import { mockAgents } from '../../data/mock';
import { Iconm } from '../../icons';
import { fetchNui, isBrowser, openEntityTab } from '../../utils/nui';
import stylesForm from '../../styles/Form.module.css';
import stylesIncidents from '../../styles/Incidents.module.css';

export function AddIncidentAgentModal({ opened, onClose, selectedIncident, setSelectedIncident }: any) {
  const [results, setResults] = useState<any>([]);
  const [searchTerm, setSearchTerm] = useState<any>('');
  const u = (p) => {
    let g = [];
    if (!(searchTerm.length === 0)) {
      g = p.filter((item) =>
        `${item.citizen.firstname} ${item.citizen.lastname}`.toLowerCase().includes(searchTerm.toLowerCase()),
      );
    }
    return g;
  };
  const f = async () => {
    if (searchTerm.length !== 0) {
      if (isBrowser()) {
        const p = u(mockAgents);
        setResults(p);
      } else {
        const response = await fetchNui('searchAgents', {
          searchTerm,
        });
        setResults(response);
      }
    }
  };
  const h = (p) => {
    const g: any = {
      ...selectedIncident,
      agents: [...(selectedIncident.agents ?? []), p],
    };
    setSelectedIncident(g);
    onClose();
  };
  return (
    <Modal opened={opened} onClose={onClose} title="Agentes" centered size={450}>
      <Stack mt="sm">
        <Group justify="flex-start" gap="xs">
          <TextInput
            flex={0.9}
            placeholder="Nombre y apellidos o ID"
            label="Buscar agente"
            description="Ingrese el nombre o ID del agente que desea buscar"
            value={searchTerm}
            onChange={(event) => setSearchTerm(event.currentTarget.value)}
          />
          <Button flex={0.1} mt={47} className={stylesForm.button} onClick={() => f()}>
            <FaSearch size={12} />
          </Button>
        </Group>
        <ScrollArea h={230} offsetScrollbars scrollbarSize={3}>
          <Stack flex={1} gap="xs">
            {results.length === 0 ? (
              <Text c="dimmed" mx="auto">
                No se han encontrado agentes.
              </Text>
            ) : (
              results.map((result) => (
                <Box
                  key={result.citizen.citizenid}
                  className={stylesIncidents.boxItem}
                  onClick={() => h(result)}
                  p="sm"
                >
                  <Group justify="flex-start" align="flex-start">
                    <Image radius="sm" w={60} src={result.citizen.imageUrl} fallbackSrc="default-user.webp" />
                    <Stack flex={1} gap="xs">
                      <Group justify="space-between" align="center">
                        <Title order={4}>
                          {result.citizen.firstname} {result.citizen.lastname}
                        </Title>
                        <Badge size="sm" color="dark.1" variant="light" radius="sm">
                          {'PLACA: '}
                          {result.badge_number}
                        </Badge>
                      </Group>
                      <Group>
                        <Badge
                          size="sm"
                          color="dark.1"
                          variant="light"
                          radius="sm"
                          leftSection={<FaIdCard size={12} />}
                        >
                          {result.citizen.citizenid}
                        </Badge>
                        <Badge
                          size="sm"
                          color="dark.1"
                          variant="light"
                          radius="sm"
                          leftSection={<FaPhone size={12} />}
                        >
                          {result.citizen.phoneNumber}
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

export function IncidentAgents({ selectedIncident, setSelectedIncident, canEdit = true }: any) {
  const [addOpen, setAddOpen] = useState<any>(false);
  const [roleMenuIndex, setRoleMenuIndex] = useState<any>(null);
  const [loading, setLoading] = useState<any>(false);
  const f = (v) => {
    setSelectedIncident({
      ...selectedIncident,
      agents: (selectedIncident.agents ?? []).filter((item, index) => index !== v),
    });
    setRoleMenuIndex(null);
  };
  const h = (v, y) => {
    if (y) {
      setSelectedIncident({
        ...selectedIncident,
        agents: (selectedIncident.agents ?? []).map((item, index) =>
          index === v
            ? {
                ...item,
                incidentRole: y,
              }
            : item,
        ),
      });
    }
  };
  const p = (v) => {
    openEntityTab({
      type: 'citizen',
      citizenId: v,
    });
  };
  const handleClick = async () => {
    if (!isBrowser()) {
      setLoading(true);
      try {
        const response = await fetchNui('getFrequencyAgents');
        if (!response || response.length === 0) {
          return;
        }
        const y = new Set<any>((selectedIncident.agents ?? []).map((item) => item.citizen.citizenid));
        const b = response.filter((item) => !y.has(item.citizen.citizenid));
        if (b.length === 0) {
          return;
        }
        setSelectedIncident({
          ...selectedIncident,
          agents: [...(selectedIncident.agents ?? []), ...b],
        });
      } finally {
        setLoading(false);
      }
    }
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
            <Iconm size={20} />
            <Text size="lg" fw="bold" c="var(--text-primary)">
              Agentes
            </Text>
          </Group>
          {canEdit && (
            <Group gap={6}>
              <Tooltip label="Añadir agentes de tu frecuencia" color="var(--primary-color)" withArrow>
                <Button className={stylesForm.button} size="xs" onClick={handleClick} loading={loading}>
                  <FaWalkieTalkie size={12} />
                </Button>
              </Tooltip>
              <Button className={stylesForm.button} size="xs" onClick={() => setAddOpen(true)}>
                <FaPlus size={12} />
              </Button>
            </Group>
          )}
        </Group>
        <ScrollArea mt="sm" h="38vh" offsetScrollbars scrollbarSize={3}>
          <Stack gap="sm">
            {selectedIncident.agents && selectedIncident.agents.length > 0 ? (
              selectedIncident.agents.map((agent, index) => (
                <Box
                  key={`${agent.citizen.citizenid}-${index}`}
                  className={stylesIncidents.boxItem}
                  p={10}
                  style={{
                    cursor: 'pointer',
                  }}
                  onClick={() => {
                    if (roleMenuIndex !== index) {
                      p(agent.citizen.citizenid);
                    }
                  }}
                >
                  <Group justify="flex-start" align="flex-start">
                    <Box w={60} h={60}>
                      <Image
                        radius="sm"
                        w="100%"
                        h="100%"
                        src={agent.citizen.imageUrl}
                        fallbackSrc="default-user.webp"
                      />
                    </Box>
                    <Stack flex={1} gap="xs">
                      <Group justify="space-between" align="center">
                        <Title order={4}>
                          {agent.citizen.firstname} {agent.citizen.lastname}
                        </Title>
                        <Group gap={6}>
                          {agent.incidentRole && (
                            <Badge
                              size="sm"
                              color={agent.incidentRole === 'mando' ? 'blue' : 'teal'}
                              variant="light"
                              radius="sm"
                            >
                              {agent.incidentRole.toUpperCase()}
                            </Badge>
                          )}
                          <Badge size="sm" color="dark.1" variant="light" radius="sm">
                            {'PLACA: '}
                            {agent.badge_number}
                          </Badge>
                          {canEdit && (
                            <Popover
                              width={230}
                              position="bottom-end"
                              withArrow
                              shadow="md"
                              opened={roleMenuIndex === index}
                              onChange={(b) => {
                                setRoleMenuIndex(b ? index : null);
                              }}
                              withinPortal={false}
                            >
                              <Popover.Target>
                                <ActionIcon
                                  size="sm"
                                  variant="subtle"
                                  color="gray"
                                  onClick={(event) => {
                                    event.stopPropagation();
                                    setRoleMenuIndex(roleMenuIndex === index ? null : index);
                                  }}
                                >
                                  <HiDotsVertical size={14} />
                                </ActionIcon>
                              </Popover.Target>
                              <Popover.Dropdown>
                                <Stack gap="xs">
                                  <Button
                                    variant="subtle"
                                    color="red"
                                    leftSection={<FaTrash2 size={12} />}
                                    justify="flex-start"
                                    onClick={(event) => {
                                      event.stopPropagation();
                                      f(index);
                                    }}
                                    px={6}
                                    h={30}
                                  >
                                    Eliminar
                                  </Button>
                                  <Divider />
                                  <Select
                                    placeholder="Selecciona un rol"
                                    label="Asignar rol"
                                    data={[
                                      {
                                        value: 'mando',
                                        label: 'Mando',
                                      },
                                      {
                                        value: 'supervisor',
                                        label: 'Supervisor',
                                      },
                                    ]}
                                    value={agent.incidentRole ?? null}
                                    onChange={(b) => h(index, b)}
                                    onMouseDown={(event) => event.stopPropagation()}
                                    onClick={(event) => event.stopPropagation()}
                                    comboboxProps={{
                                      withinPortal: false,
                                    }}
                                    allowDeselect={false}
                                  />
                                </Stack>
                              </Popover.Dropdown>
                            </Popover>
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
                          {agent.citizen.citizenid}
                        </Badge>
                        <Badge
                          size="sm"
                          color="dark.1"
                          variant="light"
                          radius="sm"
                          leftSection={<FaPhone size={12} />}
                        >
                          {agent.citizen.phoneNumber}
                        </Badge>
                      </Group>
                    </Stack>
                  </Group>
                </Box>
              ))
            ) : (
              <Text c="dimmed" mt="lg" mx="auto">
                No hay agentes asignados.
              </Text>
            )}
          </Stack>
        </ScrollArea>
      </Grid.Col>
      {addOpen && (
        <AddIncidentAgentModal
          opened={addOpen}
          onClose={() => setAddOpen(false)}
          selectedIncident={selectedIncident}
          setSelectedIncident={setSelectedIncident}
        />
      )}
    </>
  );
}
