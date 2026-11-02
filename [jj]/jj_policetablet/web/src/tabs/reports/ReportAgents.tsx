import {
  ActionIcon,
  Badge,
  Box,
  Button,
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
import { FaIdCard, FaPlus, FaSearch, FaTrash } from 'react-icons/fa';
import { mockAgents } from '../../data/mock';
import { fetchNui, isBrowser, openEntityTab } from '../../utils/nui';
import stylesForm from '../../styles/Form.module.css';
import stylesReports from '../../styles/Reports.module.css';

export function SelectAgentModal({ opened, onClose, onSelect }: any) {
  const [results, setResults] = useState<any>([]);
  const [searchTerm, setSearchTerm] = useState<any>('');
  const handleClick = async () => {
    if (searchTerm.length === 0) {
      return;
    }
    if (isBrowser()) {
      setResults(
        mockAgents.filter((mockAgent2) =>
          `${mockAgent2.citizen.firstname} ${mockAgent2.citizen.lastname}`
            .toLowerCase()
            .includes(searchTerm.toLowerCase()),
        ),
      );
      return;
    }
    const response = await fetchNui('searchAgents', {
      searchTerm,
    });
    setResults(response ?? []);
  };
  return (
    <Modal opened={opened} onClose={onClose} title="Buscar agente" centered size={450}>
      <Stack mt="sm">
        <Group gap="xs" align="flex-end">
          <TextInput
            flex={1}
            placeholder="Nombre y apellidos o ID"
            label="Buscar agente"
            value={searchTerm}
            onChange={(event) => setSearchTerm(event.currentTarget.value)}
            onKeyDown={(event) => {
              if (event.key === 'Enter') {
                handleClick();
              }
            }}
          />
          <Button className={stylesForm.button} onClick={handleClick}>
            <FaSearch size={12} />
          </Button>
        </Group>
        <ScrollArea h={230} offsetScrollbars scrollbarSize={3}>
          <Stack gap="xs">
            {results.length === 0 ? (
              <Text c="dimmed" mx="auto">
                No se han encontrado agentes.
              </Text>
            ) : (
              results.map((result) => (
                <Box
                  key={result.citizen.citizenid}
                  className={stylesReports.boxItem}
                  p="sm"
                  onClick={() => {
                    onSelect(result);
                    onClose();
                  }}
                >
                  <Group align="center">
                    <Image radius="sm" w={45} src={result.citizen.imageUrl} fallbackSrc="default-user.webp" />
                    <Stack gap={4} flex={1}>
                      <Title order={5}>
                        {result.citizen.firstname} {result.citizen.lastname}
                      </Title>
                      <Badge size="sm" color="dark.1" variant="light" radius="sm">
                        {'PLACA: '}
                        {result.badge_number}
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

export function ReportAgents({ title, icon, emptyText, agents, onChange, canEdit }: any) {
  const [addOpen, setAddOpen] = useState<any>(false);
  const handleSelect = (f) => {
    if (!agents.some((agent) => agent.citizen.citizenid === f.citizen.citizenid)) {
      onChange([...agents, f]);
    }
  };
  return (
    <Box className={stylesReports.infoSectionBox} p="sm" px="lg" h="100%">
      <Group justify="space-between">
        <Group gap={9}>
          {icon}
          <Text size="lg" fw="bold" c="var(--text-primary)">
            {title}
          </Text>
        </Group>
        {canEdit && (
          <Button className={stylesForm.button} size="xs" onClick={() => setAddOpen(true)}>
            <FaPlus size={12} />
          </Button>
        )}
      </Group>
      <ScrollArea mt="sm" mah="22vh" offsetScrollbars scrollbarSize={3}>
        <Stack gap="xs">
          {agents.length > 0 ? (
            agents.map((agent, index) => (
              <Box
                key={`${agent.citizen.citizenid}-${index}`}
                className={stylesReports.boxItem}
                p={8}
                onClick={() =>
                  openEntityTab({
                    type: 'citizen',
                    citizenId: agent.citizen.citizenid,
                  })
                }
              >
                <Group justify="space-between" wrap="nowrap">
                  <Group gap="sm" wrap="nowrap">
                    <Image
                      radius="sm"
                      w={38}
                      h={38}
                      src={agent.citizen.imageUrl}
                      fallbackSrc="default-user.webp"
                    />
                    <Stack gap={2}>
                      <Text fw="bold" size="sm">
                        {agent.citizen.firstname} {agent.citizen.lastname}
                      </Text>
                      <Group gap={6}>
                        <Badge size="xs" color="dark.1" variant="light" radius="sm">
                          {'PLACA: '}
                          {agent.badge_number}
                        </Badge>
                        <Badge
                          size="xs"
                          color="dark.1"
                          variant="light"
                          radius="sm"
                          leftSection={<FaIdCard size={10} />}
                        >
                          {agent.citizen.citizenid}
                        </Badge>
                      </Group>
                    </Stack>
                  </Group>
                  {canEdit && (
                    <ActionIcon
                      variant="subtle"
                      color="red"
                      onClick={(event) => {
                        event.stopPropagation();
                        onChange(agents.filter((agent2, index2) => index2 !== index));
                      }}
                    >
                      <FaTrash size={12} />
                    </ActionIcon>
                  )}
                </Group>
              </Box>
            ))
          ) : (
            <Text c="dimmed" mt="md" mx="auto" size="sm">
              {emptyText}
            </Text>
          )}
        </Stack>
      </ScrollArea>
      {addOpen && (
        <SelectAgentModal opened={addOpen} onClose={() => setAddOpen(false)} onSelect={handleSelect} />
      )}
    </Box>
  );
}
