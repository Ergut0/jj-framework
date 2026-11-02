import {
  ActionIcon,
  Avatar,
  Badge,
  Box,
  Button,
  Flex,
  Grid,
  Group,
  Image,
  NumberFormatter,
  ScrollArea,
  SegmentedControl,
  Stack,
  Text,
  Tooltip,
} from '@mantine/core';
import { useState } from 'react';
import {
  FaBox,
  FaCalendar,
  FaCheck,
  FaCreditCard,
  FaPlus,
  FaSpinner,
  FaThumbtack,
  FaTimes,
  FaTrash,
  FaUser,
} from 'react-icons/fa';
import { openEntityTab } from '../../utils/nui';
import stylesCitizens from '../../styles/Citizens.module.css';
import stylesForm from '../../styles/Form.module.css';

export function InfoSection({ title, icon: Icon, iconSize, onAdd, rightSection, children }: any) {
  return (
    <Grid.Col
      span={5.92}
      className={stylesCitizens.infoSectionBox}
      mt={15}
      mih="45vh"
      mah="45vh"
      p="sm"
      px="lg"
    >
      <Group justify="space-between">
        <Group gap={9}>
          {Icon && <Icon size={iconSize || 18} />}
          <Text size="lg" fw="bold" c="var(--text-primary)">
            {title}
          </Text>
        </Group>
        <Group gap={8} align="center">
          {rightSection}
          {onAdd && (
            <Button className={stylesForm.button} size="xs" onClick={onAdd}>
              <FaPlus size={12} />
            </Button>
          )}
        </Group>
      </Group>
      {children}
    </Grid.Col>
  );
}

export function CitizenNotes({ notes, canDelete, onTogglePinged, onDeleteNote }: any) {
  const o = async (s) => {
    onDeleteNote(s);
  };
  return (
    <ScrollArea h="38vh" type="never" mt="sm">
      <Box>
        {notes.length === 0 ? (
          <Box w="100%" mt="lg">
            <Text c="dimmed" ta="center">
              No hay notas registradas.
            </Text>
          </Box>
        ) : (
          notes.map((note) => (
            <Box
              key={note.id}
              className={
                note.pinged
                  ? `${stylesCitizens.noteItem} ${stylesCitizens.pingedNoteItem}`
                  : stylesCitizens.noteItem
              }
            >
              <Flex justify="space-between" align="center">
                <Text fw={700} size="md" c="var(--text-primary)">
                  {note.title}
                </Text>
                <Flex gap="xs" align="center" justify="flex-end">
                  <Tooltip
                    label={note.pinged ? 'Desanclar nota' : 'Anclar nota'}
                    color="var(--primary-color)"
                    withArrow
                  >
                    <ActionIcon
                      size="xs"
                      variant="transparent"
                      color={note.pinged ? 'yellow' : 'dark.1'}
                      onClick={() => onTogglePinged(note.id)}
                    >
                      <FaThumbtack size={14} />
                    </ActionIcon>
                  </Tooltip>
                  {canDelete && (
                    <Tooltip label="Eliminar nota" color="var(--primary-color)" withArrow>
                      <ActionIcon
                        mb={3.3}
                        color="red.5"
                        variant="transparent"
                        size="xs"
                        onClick={() => o(note.id)}
                      >
                        <FaTrash size={13} />
                      </ActionIcon>
                    </Tooltip>
                  )}
                </Flex>
              </Flex>
              <Text size="sm" c="var(--text-secondary)" mt={4}>
                {note.description}
              </Text>
              <Flex justify="flex-end" align="center" mt={5}>
                <Text size="xs" c="var(--text-secondary)" mt={4} mr={10}>
                  {note.date}
                  {' - '}
                  {note.author}
                </Text>
              </Flex>
            </Box>
          ))
        )}
      </Box>
    </ScrollArea>
  );
}

export function CitizenBills({ bills, canDelete, onDeleteBill }: any) {
  const [billFilter, setBillFilter] = useState<any>('all');
  const s = bills.filter((bill) => bill.payed).length;
  const i = bills.length - s;
  const a = bills.filter((bill) => !bill.payed).reduce((total, bill) => total + Number(bill.amount || 0), 0);
  const u = bills.filter((bill) => bill.payed).reduce((total, bill) => total + Number(bill.amount || 0), 0);
  const f = [...bills]
    .filter((item) => (billFilter === 'all' ? true : billFilter === 'payed' ? item.payed : !item.payed))
    .sort((g, v) => v.id - g.id);
  const h =
    billFilter === 'payed'
      ? 'No hay multas pagadas.'
      : billFilter === 'unpaid'
        ? 'No hay multas impagadas.'
        : 'No hay multas registradas.';
  const p = (g, v) => {
    const y = g.split('\n').filter((item) => item.trim());
    const b = v.split('\n').filter((item) => item.trim());
    return y.map((item, index) => ({
      id: item.trim(),
      title: b[index]?.trim() || '',
    }));
  };
  return (
    <>
      <Group justify="space-between" mt="sm" wrap="nowrap">
        <SegmentedControl
          size="xs"
          value={billFilter}
          onChange={(g) => setBillFilter(g)}
          data={[
            {
              label: `Todas (${bills.length})`,
              value: 'all',
            },
            {
              label: `Impagadas (${i})`,
              value: 'unpaid',
            },
            {
              label: `Pagadas (${s})`,
              value: 'payed',
            },
          ]}
        />
        <Group gap="md" wrap="nowrap">
          {billFilter !== 'payed' && (
            <Text
              size="sm"
              fw={700}
              c="red.5"
              style={{
                whiteSpace: 'nowrap',
              }}
            >
              Pendiente: <NumberFormatter value={a} thousandSeparator="." decimalSeparator="," prefix={'$'} />
            </Text>
          )}
          {billFilter !== 'unpaid' && (
            <Text
              size="sm"
              fw={700}
              c="green.5"
              style={{
                whiteSpace: 'nowrap',
              }}
            >
              Total pagado:{' '}
              <NumberFormatter value={u} thousandSeparator="." decimalSeparator="," prefix={'$'} />
            </Text>
          )}
        </Group>
      </Group>
      <ScrollArea h="calc(37vh - 40px)" type="never" mt="xs">
        <Stack>
          {f.length === 0 ? (
            <Text c="dimmed" mt="lg" mx="auto">
              {h}
            </Text>
          ) : (
            f.map((item) => {
              const v = p(item.id_article, item.title);
              return (
                <Stack
                  key={item.id}
                  p="sm"
                  className={`${stylesCitizens.billItem} ${item.payed ? stylesCitizens.payedBill : stylesCitizens.unpaidBill}`}
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
                      {v.map((item2, index) => (
                        <Text key={index} fw="bold" c="gray.2" size="md">
                          {'Art '}
                          {item2.id}
                          {' - '}
                          {item2.title}
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
                        value={item.amount}
                        thousandSeparator="."
                        decimalSeparator=","
                        prefix={'$'}
                      />
                    </Text>
                    {canDelete && (
                      <Tooltip label="Eliminar multa" color="var(--primary-color)" withArrow>
                        <ActionIcon
                          mb={3.3}
                          color="red.5"
                          variant="transparent"
                          size="xs"
                          onClick={() => onDeleteBill(item.id)}
                        >
                          <FaTrash size={13} />
                        </ActionIcon>
                      </Tooltip>
                    )}
                  </Group>
                  <Group justify="flex-start">
                    <Badge
                      color={item.payed ? 'green.6' : 'red.6'}
                      variant="light"
                      radius="sm"
                      leftSection={item.payed ? <FaCheck size={11} /> : <FaTimes size={11} />}
                    >
                      {item.payed ? 'Pagada' : 'Impagada'}
                    </Badge>
                    <Badge
                      color="dark.2"
                      variant="light"
                      c="dark.1"
                      radius="sm"
                      leftSection={<FaUser size={12} />}
                    >
                      {item.agentName}
                      {' - '}
                      {item.agentBadge}
                    </Badge>
                    <Badge
                      color="dark.2"
                      variant="light"
                      c="dark.1"
                      radius="sm"
                      leftSection={<FaCalendar size={12} />}
                    >
                      {item.date}
                    </Badge>
                  </Group>
                </Stack>
              );
            })
          )}
        </Stack>
      </ScrollArea>
    </>
  );
}

export function CitizenVehicles({ vehicles }: any) {
  return (
    <ScrollArea h="37vh" type="never" mt="sm">
      <Stack>
        {vehicles.length === 0 ? (
          <Text c="dimmed" mt="lg" mx="auto">
            No hay vehículos registrados.
          </Text>
        ) : (
          vehicles.map((vehicle) => (
            <Stack
              key={vehicle.id}
              p="sm"
              className={stylesCitizens.vehicleItem}
              w="100%"
              style={{
                cursor: 'pointer',
              }}
              onClick={() =>
                openEntityTab({
                  type: 'vehicle',
                  plate: vehicle.plate,
                })
              }
            >
              <Group align="flex-start" gap="xs">
                <Image src={vehicle.image} fallbackSrc="default-car.png" w={60} h={60} radius="sm" />
                <Stack gap="xs">
                  <Text fw="bold" c="gray.2">
                    {vehicle.model}
                  </Text>
                  <Badge
                    color="dark.2"
                    variant="light"
                    c="dark.1"
                    radius="sm"
                    size="sm"
                    leftSection={<FaCreditCard size={12} />}
                  >
                    {vehicle.plate}
                  </Badge>
                </Stack>
                <Flex justify="flex-end" align="center" ml="auto" gap="xs">
                  {vehicle.wanted && (
                    <Badge size="sm" color="red" variant="light" radius="sm">
                      COD-9
                    </Badge>
                  )}
                  {vehicle.incauted && (
                    <Badge size="sm" color="orange" variant="light" radius="sm">
                      INCAUTADO
                    </Badge>
                  )}
                </Flex>
              </Group>
            </Stack>
          ))
        )}
      </Stack>
    </ScrollArea>
  );
}

export function CitizenIncidents({ incidents }: any) {
  return (
    <ScrollArea h="37vh" type="never" mt="sm">
      <Stack>
        {incidents.length === 0 ? (
          <Text c="dimmed" mt="lg" mx="auto">
            No hay incidentes registrados.
          </Text>
        ) : (
          incidents.map((incident) => (
            <Stack
              key={incident.id}
              p="sm"
              className={stylesCitizens.incidentItem}
              style={{
                cursor: 'pointer',
              }}
              onClick={() =>
                openEntityTab({
                  type: 'incident',
                  incidentId: incident.id,
                })
              }
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
                      {incident.creator.name}
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
  );
}
