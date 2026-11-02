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
} from '@mantine/core';
import { useState } from 'react';
import { FaIdCard, FaPhone, FaPlus, FaSearch, FaUsers as FaUsers2 } from 'react-icons/fa';
import { FaTrash as FaTrash2 } from 'react-icons/fa6';
import { HiDotsVertical } from 'react-icons/hi';
import { mockCitizens } from '../../data/mockCitizens';
import { fetchNui, isBrowser, openEntityTab } from '../../utils/nui';
import stylesForm from '../../styles/Form.module.css';
import stylesIncidents from '../../styles/Incidents.module.css';

export function AddIncidentCitizenModal({ opened, onClose, selectedIncident, setSelectedIncident }: any) {
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
      citizens: [...(selectedIncident.citizens ?? []), p],
    });
    onClose();
  };
  return (
    <Modal opened={opened} onClose={onClose} title="Ciudadanos" centered size={450}>
      <Stack mt="sm">
        <Group justify="flex-start" gap="xs">
          <TextInput
            flex={0.9}
            placeholder="Nombre, apellidos o ID"
            label="Buscar ciudadano"
            description="Ingrese el nombre o ID del ciudadano que desea buscar"
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
                No se han encontrado ciudadanos.
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
                    <Image radius="sm" w={60} h={60} src={result.imageUrl} fallbackSrc="default-user.webp" />
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

export function IncidentCitizens({ selectedIncident, setSelectedIncident, canEdit = true }: any) {
  const [addOpen, setAddOpen] = useState<any>(false);
  const [roleMenuIndex, setRoleMenuIndex] = useState<any>(null);
  const a = (h) => {
    setSelectedIncident({
      ...selectedIncident,
      citizens: (selectedIncident.citizens ?? []).filter((item, index) => index !== h),
    });
    setRoleMenuIndex(null);
  };
  const u = (h, p) => {
    if (p) {
      setSelectedIncident({
        ...selectedIncident,
        citizens: (selectedIncident.citizens ?? []).map((item, index) =>
          index === h
            ? {
                ...item,
                incidentRole: p,
              }
            : item,
        ),
      });
    }
  };
  const f = (h) => {
    openEntityTab({
      type: 'citizen',
      citizenId: h,
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
              Ciudadanos
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
            {selectedIncident.citizens && selectedIncident.citizens.length > 0 ? (
              selectedIncident.citizens.map((citizen, index) => (
                <Box
                  key={`${citizen.citizenid}-${index}`}
                  className={stylesIncidents.boxItem}
                  p={10}
                  style={{
                    cursor: 'pointer',
                  }}
                  onClick={() => {
                    if (roleMenuIndex !== index) {
                      f(citizen.citizenid);
                    }
                  }}
                >
                  <Group justify="flex-start" align="flex-start">
                    <Box w={60} h={60}>
                      <Image
                        radius="sm"
                        src={citizen.imageUrl}
                        fallbackSrc="default-user.webp"
                        w="100%"
                        h="100%"
                      />
                    </Box>
                    <Stack flex={1} gap="xs">
                      <Group justify="space-between" align="center">
                        <Title order={4}>
                          {citizen.firstname} {citizen.lastname}
                        </Title>
                        <Group gap={6}>
                          {citizen.incidentRole && (
                            <Badge
                              size="sm"
                              color={citizen.incidentRole === 'autor' ? 'orange' : 'cyan'}
                              variant="light"
                              radius="sm"
                            >
                              {citizen.incidentRole.toUpperCase()}
                            </Badge>
                          )}
                          {citizen.isWanted && (
                            <Badge size="sm" color="red" variant="light" radius="sm">
                              BUSCADO
                            </Badge>
                          )}
                          {canEdit && (
                            <Popover
                              width={230}
                              position="bottom-end"
                              withArrow
                              shadow="md"
                              opened={roleMenuIndex === index}
                              onChange={(g) => {
                                setRoleMenuIndex(g ? index : null);
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
                                      a(index);
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
                                        value: 'autor',
                                        label: 'Autor',
                                      },
                                      {
                                        value: 'complice',
                                        label: 'Complice',
                                      },
                                    ]}
                                    value={citizen.incidentRole ?? null}
                                    onChange={(g) => u(index, g)}
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
                          {citizen.citizenid}
                        </Badge>
                        <Badge
                          size="sm"
                          color="dark.1"
                          variant="light"
                          radius="sm"
                          leftSection={<FaPhone size={12} />}
                        >
                          {citizen.phoneNumber}
                        </Badge>
                      </Group>
                    </Stack>
                  </Group>
                </Box>
              ))
            ) : (
              <Text c="dimmed" mt="lg" mx="auto">
                No hay ciudadanos asignados.
              </Text>
            )}
          </Stack>
        </ScrollArea>
      </Grid.Col>
      {addOpen && (
        <AddIncidentCitizenModal
          opened={addOpen}
          onClose={() => setAddOpen(false)}
          selectedIncident={selectedIncident}
          setSelectedIncident={setSelectedIncident}
        />
      )}
    </>
  );
}
