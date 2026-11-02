import { Group } from '@mantine/core';
import { useEffect, useState } from 'react';
import { mockAgents } from '../../data/mock';
import { fetchNui, isBrowser } from '../../utils/nui';
import { DispatchTab } from '../dispatch/DispatchTab';
import { AgentList } from './AgentList';

export function AgentsTab() {
  const [agents, setAgents] = useState<any>(isBrowser() ? mockAgents : []);
  const [selectedAgent, setSelectedAgent] = useState<any>(null);
  const handleRefreshAgentsList = async () => {
    if (!isBrowser()) {
      try {
        const response = await fetchNui('fetchAgents', {});
        if (response) {
          setAgents(response);
        }
      } catch (error) {
        console.error('Error fetching agents:', error);
      }
    }
  };
  useEffect(() => {
    handleRefreshAgentsList();
  }, []);
  const handleSelectAgent = async (a) => {
    if (isBrowser()) {
      setSelectedAgent(a);
      return;
    }
    const response = await fetchNui('fetchAgentById', {
      citizenid: a.citizen.citizenid,
    });
    setSelectedAgent(response);
  };
  const fetchAgentsByFilter = async (a) => {
    const u = a.toLowerCase();
    const response = await fetchNui('fetchAgentsByFilter', u);
    setAgents(response);
  };
  return (
    <>
      <Group flex={1} justify="flex-start" align="flex-start" gap={0} wrap="nowrap">
        <AgentList
          agents={agents}
          onSelectAgent={handleSelectAgent}
          selectedAgent={selectedAgent}
          fetchAgentsByFilter={fetchAgentsByFilter}
        />
        <DispatchTab onRefreshAgentsList={handleRefreshAgentsList} />
      </Group>
    </>
  );
}
