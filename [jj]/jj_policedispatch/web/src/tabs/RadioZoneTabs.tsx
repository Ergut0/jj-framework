import { Box } from '@mantine/core';
import { useEffect, useState } from 'react';
import { useAgentStore } from '../store/agent';
import { useRadioStore } from '../store/radio';
import { fetchNui, isBrowser } from '../utils/nui';
import { RadioTab } from './RadioTab';
import { ReferencesTab } from './ReferencesTab';
import { SettingsTab } from './SettingsTab';
import { ToolsTab } from './ToolsTab';

export function RadioZoneTabs({ tab, refreshData }: any) {
  const [radioInfo, setRadioInfo] = useState<any>(isBrowser() ? ['lspd', 'lssd'] : null);
  const { setAgent } = useAgentStore();
  const { radioChannels, setRadioChannels, setRadioChannelMembers } = useRadioStore();
  useEffect(() => {
    if (!isBrowser()) {
      (async () => {
        const response = await fetchNui('fetchRadioData', {});
        setRadioInfo(response.zones);
        setRadioChannels(response.channels);
      })();
    }
  }, [refreshData]);
  useEffect(() => {
    if (!isBrowser()) {
      (async () => {
        setAgent(await fetchNui('fetchAgentData', {}));
      })();
    }
  }, [refreshData]);
  useEffect(() => {
    if (!isBrowser()) {
      (async () => {
        const response = await fetchNui('fetchMembers', {});
        radioChannels.forEach((radioChannel) => {
          setRadioChannelMembers([], radioChannel.id);
        });
        const t: any = {};
        response.forEach((item) => {
          if (!t[item.id_group]) {
            t[item.id_group] = [];
          }
          t[item.id_group].push(item);
        });
        Object.entries(t).forEach(([e, t]) => {
          setRadioChannelMembers(t, e);
        });
      })();
    }
  }, [refreshData]);
  return (
    <Box
      style={{
        flex: 1,
        minHeight: 0,
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      {((e) => {
        switch (e) {
          case 0:
            return <ReferencesTab />;
          case 1:
            return <RadioTab radioInfo={radioInfo} />;
          case 2:
            return <ToolsTab />;
          case 3:
            return <SettingsTab />;
          default:
            return <Box>Default Content</Box>;
        }
      })(tab)}
    </Box>
  );
}
