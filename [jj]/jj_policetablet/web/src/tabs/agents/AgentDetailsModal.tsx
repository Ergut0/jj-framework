import {
  ActionIcon,
  Avatar,
  Badge,
  Button,
  Flex,
  Group,
  Menu,
  Modal,
  MultiSelect,
  NumberFormatter,
  ScrollArea,
  Select,
  Stack,
  Tabs,
  Text,
  TextInput,
  Textarea,
  Title,
} from '@mantine/core';
import { useEffect, useState } from 'react';
import { FaBox, FaCalendar, FaClock, FaPlus, FaSpinner, FaTrash, FaUser } from 'react-icons/fa';
import { useRecoilValue } from 'recoil';
import { ranksAgentsAtom, usePermissions } from '../../state/atoms';
import { fetchNui, isBrowser, openEntityTab } from '../../utils/nui';
import stylesForm from '../../styles/Form.module.css';
import stylesAgents from '../../styles/Agents.module.css';

export function AgentDetailsModal({ opened, agent, onClose, onAgentUpdate, onAgentFire }: any) {
  const [change, setChange] = useState<any>('info');
  const [historyTab, setHistoryTab] = useState<any>('Incidentes');
  const [incidents, setIncidents] = useState<any>([]);
  const [bills, setBills] = useState<any>([]);
  const [change2, setChange2] = useState<any>(null);
  const [badge_number, setBadge_number] = useState<any>('');
  const [divisions, setDivisions] = useState<any>([]);
  const [department, setDepartment] = useState<any>();
  const [hoursWorked, setHoursWorked] = useState<any>(0);
  const [infractions, setInfractions] = useState<any>([]);
  const [infractionOpen, setInfractionOpen] = useState<any>(false);
  const [infractionTitle, setInfractionTitle] = useState<any>('');
  const [infractionDescription, setInfractionDescription] = useState<any>('');
  const [loading, setLoading] = useState<any>(false);
  const [loading2, setLoading2] = useState<any>(false);
  const [loading3, setLoading3] = useState<any>(false);
  const N = useRecoilValue<any>(ranksAgentsAtom);
  const [departments, setDepartments] = useState<any>(N);
  const { haveRankPerms: Y } = usePermissions();
  useEffect(() => {
    if (isBrowser()) {
      setDepartments(N);
    } else {
      (async () => {
        const response = await fetchNui('getRanks', {});
        if (response) {
          setDepartments(response);
        }
      })();
    }
  }, [N]);
  const ne = ['METRO', 'SWAT', 'SEB', 'SAPA', 'ASD', 'K9', 'RRPP', 'RTD', 'IAD', 'TRAFFIC DIVISION'];
  const oe = (ve, Ae) => {
    const be = ve.split('\n').filter((item) => item.trim());
    const ze = Ae.split('\n').filter((item) => item.trim());
    return be.map((item, index) => ({
      id: item.trim(),
      title: ze[index]?.trim() || '',
    }));
  };
  const le = async (ve) => {
    if (!ve) {
      return [];
    }
    try {
      return (
        (await fetchNui('getAgentIncidents', {
          citizenid: ve.citizen.citizenid,
        })) || []
      );
    } catch (error) {
      console.error('Error al obtener incidentes del agente:', error);
      return [];
    }
  };
  const ue = async (ve) => {
    if (!ve) {
      return [];
    }
    try {
      return (
        (await fetchNui('getAgentBills', {
          citizenid: ve.citizen.citizenid,
          badges: [ve.badge_number],
        })) || []
      );
    } catch (error) {
      console.error('Error al obtener multas del agente:', error);
      return [];
    }
  };
  useEffect(() => {
    if (!opened || !agent) {
      return;
    }
    setChange2(String(agent.rank_id) || '0');
    setBadge_number(agent.badge_number || '');
    setDivisions(agent.divisions || []);
    setDepartment(agent.department || 'N/A');
    setHoursWorked(agent.horastrabajo || 0);
    setInfractions(agent.infractions || []);
    (async () => {
      const [Ae, be] = await Promise.all([le(agent), ue(agent)]);
      setIncidents(Ae);
      setBills(be);
    })();
  }, [opened, agent]);
  useEffect(() => {
    if (!Y(['agents.edit'])) {
      setChange('stats');
    }
  }, [opened, Y]);
  const handleClick = async () => {
    if (!(!agent || !infractionTitle.trim())) {
      setLoading(true);
      try {
        const Ae = (await fetchNui('addAgentInfraction', {
          citizenid: agent.citizen.citizenid,
          title: infractionTitle.trim(),
          description: infractionDescription.trim(),
        })) || {
          id: Date.now(),
          title: infractionTitle.trim(),
          description: infractionDescription.trim(),
          date:
            new Date().toLocaleDateString() +
            ' ' +
            new Date().toLocaleTimeString([], {
              hour: '2-digit',
              minute: '2-digit',
            }),
          author: 'Oficial Actual',
        };
        const infractions2 = [...infractions, Ae];
        setInfractions(infractions2);
        if (onAgentUpdate) {
          onAgentUpdate({
            ...agent,
            infractions: infractions2,
          });
        }
        setInfractionTitle('');
        setInfractionDescription('');
        setInfractionOpen(false);
      } catch (error) {
        console.error('Error al añadir falta/infracción al agente:', error);
      } finally {
        setLoading(false);
      }
    }
  };
  const ge = async (ve) => {
    if (agent) {
      try {
        await fetchNui('deleteAgentInfraction', {
          citizenid: agent.citizen.citizenid,
          infractionId: ve,
        });
        const infractions2 = infractions.filter((infraction) => infraction.id !== ve);
        setInfractions(infractions2);
        if (onAgentUpdate) {
          onAgentUpdate({
            ...agent,
            infractions: infractions2,
          });
        }
      } catch (error) {
        console.error('Error al eliminar falta/infracción del agente:', error);
      }
    }
  };
  const handleClick2 = async () => {
    if (agent) {
      setLoading2(true);
      try {
        if (
          (await fetchNui('updateAgent', {
            citizenid: agent.citizen.citizenid,
            badge_number,
            department: department || 'lspd',
            rank_id: parseInt(change2 || '0'),
            divisions,
          })) &&
          onAgentUpdate
        ) {
          const Ae: any = {
            ...agent,
            badge_number,
            rank_id: parseInt(change2 || '0'),
            department: department || 'lspd',
            divisions,
          };
          onAgentUpdate(Ae);
          onClose();
        }
      } catch (error) {
        console.error('Error al guardar cambios del agente:', error);
      } finally {
        setLoading2(false);
      }
    }
  };
  const handleClick3 = async () => {
    if (agent) {
      setLoading2(true);
      try {
        if (
          await fetchNui('fireAgent', {
            citizenid: agent.citizen.citizenid,
          })
        ) {
          if (onAgentFire) {
            onAgentFire(agent.citizen.citizenid);
          }
          onClose();
        }
      } catch (error) {
        console.error('Error al expulsar al agente:', error);
      } finally {
        setLoading2(false);
      }
    }
  };
  const handleClick4 = async () => {
    if (agent) {
      setLoading3(true);
      try {
        if (
          (
            await fetchNui('resetAgentWorkHours', {
              citizenid: agent.citizen.citizenid,
            })
          )?.success ||
          isBrowser()
        ) {
          setHoursWorked(0);
          if (onAgentUpdate) {
            onAgentUpdate({
              ...agent,
              horastrabajo: 0,
            });
          }
        }
      } catch (error) {
        console.error('Error al reiniciar horas de trabajo:', error);
      } finally {
        setLoading3(false);
      }
    }
  };
  const Xe = (ve) => {
    openEntityTab({
      type: 'incident',
      incidentId: ve.id,
    });
    onClose();
  };
  return (
    <Modal
      title={`Editar Agente - ${agent?.citizen.firstname} ${agent?.citizen.lastname}`}
      opened={opened}
      onClose={onClose}
      centered
      size="xl"
    >
      <Tabs value={change} onChange={setChange} mt="md">
        <Tabs.List grow>
          {Y(['agents.edit']) && <Tabs.Tab value="info">Información</Tabs.Tab>}
          <Tabs.Tab value="stats">Estadísticas</Tabs.Tab>
          <Tabs.Tab value="infractions">Faltas ({infractions.length})</Tabs.Tab>
        </Tabs.List>
        {Y(['agents.edit']) && (
          <Tabs.Panel value="info" pt="xs">
            <Stack gap="md">
              <Select
                label="Rango"
                data={departments.map((department2) => ({
                  value: String(department2.grade),
                  label: department2.label,
                }))}
                placeholder="Selecciona un rango"
                value={change2}
                onChange={setChange2}
              />
              <TextInput
                label="Número de placa"
                placeholder="Ej: 12345"
                value={badge_number}
                onChange={(event) => setBadge_number(event.currentTarget.value)}
              />
              <Select
                label="Departamento"
                data={['lspd', 'lssd']}
                value={department}
                onChange={(ve) => setDepartment(ve || 'lspd')}
              />
              <MultiSelect
                label="Divisiones"
                searchable
                data={ne}
                placeholder="Selecciona divisiones"
                value={divisions}
                onChange={setDivisions}
              />
              <Group grow>
                <Button
                  className={stylesForm.button}
                  onClick={handleClick2}
                  loading={loading2}
                  disabled={loading2}
                >
                  Guardar cambios
                </Button>
                <Button
                  color="red"
                  variant="light"
                  onClick={handleClick3}
                  loading={loading2}
                  disabled={loading2}
                >
                  Expulsar agente
                </Button>
              </Group>
            </Stack>
          </Tabs.Panel>
        )}
        <Tabs.Panel value="stats" pt="xs">
          <Stack gap="xs" p="sm" className={stylesAgents.statsCard} mt="xs" mb="xs">
            <Group justify="space-between" align="center">
              <Group gap="md">
                <Avatar size="lg" radius="sm" color="blue" variant="light">
                  <FaClock size={22} />
                </Avatar>
                <Stack gap={2}>
                  <Text size="xs" c="dimmed" fw={700} tt="uppercase" lts={0.5}>
                    Horas Trabajadas
                  </Text>
                  <Text size="xl" fw={800} c="gray.2">
                    {hoursWorked} {hoursWorked === 1 ? 'hora' : 'horas'}
                  </Text>
                </Stack>
              </Group>
              {Y(['agents.edit']) && (
                <Button
                  size="xs"
                  color="red"
                  variant="light"
                  loading={loading3}
                  disabled={loading3 || hoursWorked === 0}
                  onClick={handleClick4}
                >
                  Poner a 0
                </Button>
              )}
            </Group>
          </Stack>
          <Flex justify="space-between" mt="sm">
            <Title order={3}>
              {historyTab}
              {' del agente'}
            </Title>
            <Menu shadow="md" width={200} withArrow>
              <Menu.Target>
                <Button className={stylesForm.button}>{historyTab}</Button>
              </Menu.Target>
              <Menu.Dropdown>
                <Menu.Item onClick={() => setHistoryTab('Incidentes')}>Incidentes</Menu.Item>
                <Menu.Item onClick={() => setHistoryTab('Multas')}>Multas</Menu.Item>
              </Menu.Dropdown>
            </Menu>
          </Flex>
          {historyTab === 'Incidentes' ? (
            <ScrollArea h={340} type="never" mt="sm">
              <Stack>
                {incidents.length === 0 ? (
                  <Text c="dimmed" mt="lg" mx="auto">
                    No hay incidentes registrados para este agente.
                  </Text>
                ) : (
                  incidents.map((incident) => (
                    <Stack
                      key={incident.id}
                      p="sm"
                      className={stylesAgents.statsCard}
                      style={{
                        cursor: 'pointer',
                      }}
                      onClick={() => Xe(incident)}
                    >
                      <Group align="flex-start" gap="xs">
                        <Avatar size="lg" radius="sm">
                          <FaBox size={24} />
                        </Avatar>
                        <Stack gap="xs">
                          <Text fw="bold" c="gray.2" truncate>
                            {incident.title}
                          </Text>
                          <Group>
                            <Badge
                              color="dark.2"
                              variant="light"
                              c="dark.1"
                              radius="sm"
                              size="sm"
                              leftSection={<FaUser size={12} />}
                            >
                              {incident.creator?.name}
                            </Badge>
                            <Badge
                              color="dark.2"
                              variant="light"
                              c="dark.1"
                              radius="sm"
                              size="sm"
                              leftSection={<FaCalendar size={12} />}
                            >
                              {incident.date}
                            </Badge>
                            <Badge
                              color={incident.status === 'open' ? 'green' : 'red'}
                              variant="light"
                              radius="sm"
                              size="sm"
                              leftSection={<FaSpinner size={12} />}
                            >
                              {incident.status === 'open' ? 'Abierto' : 'Cerrado'}
                            </Badge>
                          </Group>
                        </Stack>
                      </Group>
                    </Stack>
                  ))
                )}
              </Stack>
            </ScrollArea>
          ) : (
            <ScrollArea h={340} type="never" mt="sm">
              <Stack>
                {bills.length === 0 ? (
                  <Text c="dimmed" mt="lg" mx="auto">
                    No hay multas registradas para este agente.
                  </Text>
                ) : (
                  bills.map((bill) => {
                    const Ae = oe(bill.id_article, bill.title);
                    return (
                      <Stack
                        key={bill.id}
                        p="sm"
                        className={`${stylesAgents.statsCard} ${bill.payed ? stylesAgents.payedBill : stylesAgents.unpaidBill}`}
                      >
                        <Group
                          justify="space-between"
                          align="flex-start"
                          pb="xs"
                          style={{
                            borderBottom: '1px solid var(--border-color)',
                          }}
                        >
                          <Stack
                            gap="sm"
                            style={{
                              flex: 1,
                            }}
                          >
                            {Ae.map((item, index) => (
                              <Text key={index} fw="bold" c="gray.2" size="md">
                                {'Art '}
                                {item.id}
                                {' - '}
                                {item.title}
                              </Text>
                            ))}
                          </Stack>
                          <Text
                            fw="bold"
                            c="gray.2"
                            style={{
                              minWidth: 'fit-content',
                              marginLeft: '12px',
                            }}
                          >
                            <NumberFormatter
                              value={bill.amount}
                              thousandSeparator="."
                              decimalSeparator=","
                              prefix={'$'}
                            />
                          </Text>
                        </Group>
                        <Group justify="flex-start">
                          <Badge
                            color="dark.2"
                            variant="light"
                            c="dark.1"
                            radius="sm"
                            leftSection={<FaUser size={12} />}
                          >
                            {bill.agentName}
                            {' - '}
                            {bill.agentBadge}
                          </Badge>
                          <Badge
                            color="dark.2"
                            variant="light"
                            c="dark.1"
                            radius="sm"
                            leftSection={<FaCalendar size={12} />}
                          >
                            {bill.date}
                          </Badge>
                        </Group>
                      </Stack>
                    );
                  })
                )}
              </Stack>
            </ScrollArea>
          )}
        </Tabs.Panel>
        <Tabs.Panel value="infractions" pt="xs">
          <Stack gap="md">
            <Group justify="space-between" align="center" mt="xs">
              <Group gap="xs">
                <Text fw={700} size="md" c="var(--text-primary)">
                  Faltas / Infracciones Registradas
                </Text>
                <Badge color="red" variant="light" radius="sm">
                  {infractions.length} {infractions.length === 1 ? 'falta' : 'faltas'}
                </Badge>
              </Group>
              {Y(['agents.edit']) && (
                <Button
                  className={stylesForm.button}
                  size="xs"
                  leftSection={<FaPlus size={12} />}
                  onClick={() => setInfractionOpen(true)}
                >
                  Registrar Falta
                </Button>
              )}
            </Group>
            <ScrollArea h="38vh" type="never" offsetScrollbars scrollbarSize={3}>
              <Stack gap="xs" mt={4}>
                {infractions.length === 0 ? (
                  <Text c="dimmed" ta="center" mt="xl">
                    No hay faltas registradas para este agente.
                  </Text>
                ) : (
                  infractions.map((infraction) => (
                    <Stack
                      key={infraction.id}
                      p="sm"
                      style={{
                        backgroundColor: 'var(--primary-color)',
                        border: '1px solid var(--border-color)',
                        borderRadius: '5px',
                      }}
                      gap="xs"
                    >
                      <Group justify="space-between" align="flex-start">
                        <Text fw={700} c="gray.2" size="sm">
                          {infraction.title}
                        </Text>
                        <Group gap="xs" align="center">
                          <Badge
                            color="dark.2"
                            variant="light"
                            c="dark.1"
                            radius="sm"
                            leftSection={<FaCalendar size={11} />}
                          >
                            {infraction.date}
                          </Badge>
                          {Y(['agents.edit']) && (
                            <ActionIcon
                              variant="transparent"
                              color="red.5"
                              size="xs"
                              onClick={() => ge(infraction.id)}
                              title="Eliminar falta"
                            >
                              <FaTrash size={12} />
                            </ActionIcon>
                          )}
                        </Group>
                      </Group>
                      {infraction.description && (
                        <Text
                          size="xs"
                          c="gray.4"
                          style={{
                            whiteSpace: 'pre-wrap',
                          }}
                        >
                          {infraction.description}
                        </Text>
                      )}
                      <Group justify="flex-start" mt={2}>
                        <Badge
                          color="dark.2"
                          variant="light"
                          c="dark.1"
                          radius="sm"
                          leftSection={<FaUser size={11} />}
                        >
                          {infraction.author}
                        </Badge>
                      </Group>
                    </Stack>
                  ))
                )}
              </Stack>
            </ScrollArea>
          </Stack>
        </Tabs.Panel>
      </Tabs>
      <Modal
        title="Registrar Falta a Agente"
        opened={infractionOpen}
        onClose={() => setInfractionOpen(false)}
        centered
        size="md"
      >
        <Stack gap="md" mt="xs">
          <TextInput
            label="Título de la falta"
            placeholder="Ej: Inasistencia / Incumplimiento de protocolo"
            value={infractionTitle}
            onChange={(event) => setInfractionTitle(event.currentTarget.value)}
            required
          />
          <Textarea
            label="Descripción de la falta"
            placeholder="Ingrese los detalles y observaciones sobre la falta cometida..."
            value={infractionDescription}
            onChange={(event) => setInfractionDescription(event.currentTarget.value)}
            minRows={3}
            autosize
          />
          <Group justify="flex-end" mt="sm">
            <Button variant="default" onClick={() => setInfractionOpen(false)}>
              Cancelar
            </Button>
            <Button
              className={stylesForm.button}
              onClick={handleClick}
              loading={loading}
              disabled={!infractionTitle.trim()}
            >
              Guardar Falta
            </Button>
          </Group>
        </Stack>
      </Modal>
    </Modal>
  );
}
