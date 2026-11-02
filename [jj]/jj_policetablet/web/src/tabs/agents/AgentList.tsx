import {
  ActionIcon,
  Badge,
  Box,
  Button,
  Group,
  Image,
  ScrollArea,
  Stack,
  Text,
  TextInput,
} from '@mantine/core';
import { useEffect, useMemo, useState } from 'react';
import { FaIdBadge, FaIdCard, FaPlus, FaSearch } from 'react-icons/fa';
import { FaPencil } from 'react-icons/fa6';
import { IconK5, Iconm, IconzO } from '../../icons';
import { usePermissions } from '../../state/atoms';
import { openEntityTab } from '../../utils/nui';
import { AddAgentModal } from './AddAgentModal';
import { AgentDetailsModal } from './AgentDetailsModal';
import styles from '../../styles/Agents.module.css';

export function AgentList({ agents, onSelectAgent, selectedAgent, fetchAgentsByFilter }: any) {
  const [search, setSearch] = useState<any>('');
  const [searching, setSearching] = useState<any>(false);
  const [addAgentOpen, setAddAgentOpen] = useState<any>(false);
  const [filteredAgents, setFilteredAgents] = useState<any>(agents);
  const { haveRankPerms } = usePermissions();
  useEffect(() => {
    setFilteredAgents(agents);
  }, [agents]);
  const v = (event, j) => {
    event.stopPropagation();
    onSelectAgent(j);
    setSearching(true);
  };
  const y = (w) => {
    openEntityTab({
      type: 'citizen',
      citizenId: w.citizen.citizenid,
    });
  };
  const handleAgentUpdate = (w) => {
    setFilteredAgents((j) => j.map((item) => (item.citizen.citizenid === w.citizen.citizenid ? w : item)));
  };
  const S = useMemo(
    () => filteredAgents.sort((w, j) => (w.onDuty && !j.onDuty ? -1 : !w.onDuty && j.onDuty ? 1 : 0)),
    [filteredAgents],
  );
  return (
    <Box className={styles.searchContainer}>
      <Group justify="space-between" align="center" mb="md">
        <Text
          fw={700}
          size="lg"
          className={styles.title}
          style={{
            display: 'flex',
            alignItems: 'center',
          }}
        >
          <Iconm
            size={26}
            style={{
              marginRight: 8,
            }}
          />
          Búsqueda de Agentes
        </Text>
        {haveRankPerms(['agents.add']) && (
          <ActionIcon
            variant="light"
            color="blue"
            onClick={() => setAddAgentOpen(true)}
            title="Asignar Agente"
          >
            <FaPlus size={16} />
          </ActionIcon>
        )}
      </Group>
      <Group gap="xs" mb="lg">
        <TextInput
          placeholder="Nombre o ID del agente"
          className={styles.searchInput}
          size="sm"
          value={search}
          onChange={(event) => setSearch(event.currentTarget.value)}
          onKeyDown={(event) => {
            if (event.key === 'Enter') {
              fetchAgentsByFilter(search);
            }
          }}
        />
        <Button size="sm" variant="default" onClick={() => fetchAgentsByFilter(search)}>
          <FaSearch />
        </Button>
      </Group>
      <ScrollArea className={styles.scrollAreaSearch} w="100%" type="never">
        <Stack gap="xs">
          {S.map((item) => (
            <Box key={item.citizen.id} className={styles.agentCard} onClick={() => y(item)}>
              <Group wrap="nowrap" gap="md" align="flex-start">
                <Image
                  fallbackSrc="default-user.webp"
                  src={item.citizen.imageUrl}
                  className={styles.agentCardAvatar}
                  radius="sm"
                />
                <Stack gap={9} w="100%">
                  <Group justify="space-between" wrap="nowrap">
                    <Box w={133}>
                      <Text truncate fw={600} size="lg" c="var(--text-primary)">
                        {item.citizen.firstname} {item.citizen.lastname}
                      </Text>
                    </Box>
                    <Group gap={9}>
                      {item.onDuty && (
                        <ActionIcon
                          variant="light"
                          color="blue"
                          size="sm"
                          onClick={(event) => {
                            event.stopPropagation();
                            window.dispatchEvent(
                              new CustomEvent('centerMapOnAgent', {
                                detail: {
                                  badge: item.badge_number,
                                },
                              }),
                            );
                          }}
                          title="Centrar en mapa"
                        >
                          <IconK5 size={13} />
                        </ActionIcon>
                      )}
                      <Box mt={3}>
                        <IconzO size={15} color={item.onDuty ? 'green' : 'red'} />
                      </Box>
                      {haveRankPerms(['agents.edit']) && (
                        <ActionIcon variant="light" color="blue" size="sm" onClick={(j) => v(j, item)}>
                          <FaPencil size={13} />
                        </ActionIcon>
                      )}
                    </Group>
                  </Group>
                  <Group gap="md">
                    <Badge
                      color="dark.2"
                      variant="light"
                      c="dark.1"
                      radius="sm"
                      leftSection={<FaIdCard size={12} />}
                    >
                      {item.citizen.citizenid}
                    </Badge>
                    <Badge
                      color="dark.2"
                      variant="light"
                      c="dark.1"
                      radius="sm"
                      leftSection={<FaIdBadge size={12} />}
                    >
                      {item.badge_number}
                    </Badge>
                  </Group>
                </Stack>
              </Group>
            </Box>
          ))}
        </Stack>
      </ScrollArea>
      {searching && (
        <AgentDetailsModal
          opened={searching}
          agent={selectedAgent}
          onClose={() => setSearching(false)}
          onAgentUpdate={handleAgentUpdate}
          onAgentFire={(w) => setFilteredAgents((j) => j.filter((item) => item.citizen.citizenid !== w))}
        />
      )}
      {addAgentOpen && (
        <AddAgentModal
          opened={addAgentOpen}
          onClose={() => setAddAgentOpen(false)}
          onAgentAdded={() => fetchAgentsByFilter(search)}
        />
      )}
    </Box>
  );
}
