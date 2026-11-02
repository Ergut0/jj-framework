import {
  ActionIcon,
  Avatar,
  Badge,
  Box,
  Button,
  Flex,
  Group,
  Modal,
  ScrollArea,
  Stack,
  Text,
  TextInput,
  Textarea,
  Tooltip,
} from '@mantine/core';
import { useState } from 'react';
import { FaBox, FaCalendar, FaSpinner, FaThumbtack, FaTrash, FaUser } from 'react-icons/fa';
import { openEntityTab } from '../../utils/nui';
import stylesForm from '../../styles/Form.module.css';
import stylesVehicles from '../../styles/Vehicles.module.css';

export const AddVehicleNoteModal = ({ opened, onClose, vehicle, onAddNote }: any) => {
  const [title, setTitle] = useState<any>('');
  const [description, setDescription] = useState<any>('');
  const handleClick = () => {
    if (!(!title.trim() || !description.trim())) {
      onAddNote(title, description);
      setTitle('');
      setDescription('');
      onClose();
    }
  };
  return (
    <Modal opened={opened} onClose={onClose} title={`Añadir Nota - ${vehicle?.plate}`} centered>
      <Stack gap="lg" p={2} pt={10}>
        <TextInput
          classNames={stylesForm}
          label="Título"
          placeholder="Título de la nota"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
        />
        <Textarea
          classNames={stylesForm}
          label="Descripción"
          placeholder="Descripción de la nota"
          minRows={4}
          value={description}
          onChange={(event) => setDescription(event.target.value)}
        />
        <Button className={stylesForm.button} onClick={handleClick} variant="light">
          Guardar Nota
        </Button>
      </Stack>
    </Modal>
  );
};

export function VehicleNotes({ notes, canDelete, onTogglePinged, onDeleteNote }: any) {
  return notes.length === 0 ? (
    <Text c="dimmed" mt="md" ta="center">
      No hay notas asignadas.
    </Text>
  ) : (
    <ScrollArea h="38vh" type="never" mt="md">
      <Box>
        {notes.map((note, index) => (
          <Box
            key={index}
            className={
              note.pinged
                ? `${stylesVehicles.noteItem} ${stylesVehicles.pingedNoteItem}`
                : stylesVehicles.noteItem
            }
          >
            <Group justify="space-between">
              <Text fw={700} size="md" c="var(--text-primary)">
                {note.title}
              </Text>
              <Group gap="xs" align="center" justify="flex-end">
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
                      onClick={() => onDeleteNote(note.id)}
                    >
                      <FaTrash size={13} />
                    </ActionIcon>
                  </Tooltip>
                )}
              </Group>
            </Group>
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
        ))}
      </Box>
    </ScrollArea>
  );
}

export function VehicleIncidents({ incidents }: any) {
  return incidents.length === 0 ? (
    <Text c="dimmed" ta="center" mt="md">
      No hay incidentes asignados.
    </Text>
  ) : (
    <ScrollArea h="37vh" type="never" mt="md" w="100%">
      <Stack>
        {incidents.map((incident) => (
          <Stack
            key={incident.id}
            p="sm"
            className={stylesVehicles.incidentItem}
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
        ))}
      </Stack>
    </ScrollArea>
  );
}
