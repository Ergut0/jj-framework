import { Box } from '@mantine/core';
import { useCallback, useEffect, useRef, useState } from 'react';
import useSound from 'use-sound';
import joinSound from '../../assets/join.mp3';
import leaveSound from '../../assets/leave.mp3';
import { useAgentStore, useRadioStore, useTalkingStore } from '../../state/radio';
import { fetchNui, isBrowser, useNuiEvent } from '../../utils/nui';
import { RadioZone, ZoneFilter } from './RadioParts';
import { DraggedMember, useMemberDrag } from './useMemberDrag';
import styles from '../../styles/Radio.module.css';

export const val_mse = ['lspd', 'lssd'];

export const mockRadioChannels = [
  {
    id: 'mando-lspd',
    freq: 100,
    zone: 'lspd',
    name: '07-MANDO-00',
    members: [
      {
        id_group: 'mando-lspd',
        citizenid: '12345',
        fullname: 'Jhon Doe (123)',
        rank: 'Oficial III',
        divisions: ['METRO', 'ASD'],
        status: true,
      },
      {
        id_group: 'mando-lspd',
        citizenid: '13456',
        fullname: 'Pepe Villuela (433)',
        rank: 'Oficial II',
        divisions: ['ASD'],
        status: false,
      },
    ],
  },
  {
    id: 'adam1-lspd',
    freq: 101,
    zone: 'lspd',
    name: '01-ADAM-00',
    members: [],
  },
  {
    id: 'adam2-lspd',
    freq: 102,
    zone: 'lspd',
    name: '02-ADAM-02',
    members: [],
  },
  {
    id: 'mando-lssd',
    freq: 105,
    zone: 'lssd',
    name: '07-MANDO-00',
    members: [
      {
        id_group: 'mando-lssd',
        citizenid: '55555',
        fullname: 'Jack Ryan (007)',
        rank: 'Sheriff',
        divisions: ['SAHP'],
        status: true,
      },
    ],
  },
  {
    id: 'adam1-lssd',
    freq: 106,
    zone: 'lssd',
    name: '01-ADAM-01',
    members: [],
  },
];

export function RadioTab() {
  const {
    radioChannels,
    setRadioChannels,
    setRadioChannelMembers,
    updateMemberStatus,
    updateMemberMuted,
    removeMember,
  } = useRadioStore();
  const { agent, setAgent, setAgentRadioGroup, setAgentMuted } = useAgentStore();
  const { talkingPlayers, setTalking } = useTalkingStore();
  const { dragging, setFloatingRef, handlePointerDown } = useMemberDrag();
  const [b] = useSound(joinSound);
  const [S] = useSound(leaveSound);
  const [zones, setZones] = useState<any>([]);
  const [selectedZones, setSelectedZones] = useState<any>({});
  const [collapsedChannels, setCollapsedChannels] = useState<any>({});
  useEffect(() => {
    if (isBrowser()) {
      setZones(val_mse);
      setSelectedZones({
        lspd: true,
        lssd: true,
      });
      setRadioChannels(mockRadioChannels);
      setAgent({
        id_group: 'mando-lspd',
        citizenid: '12345',
        fullname: 'Jhon Doe (123)',
        rank: 'Oficial III',
        divisions: ['METRO'],
        status: true,
        isMuted: false,
      });
      return;
    }
    (async () => {
      const response = await fetchNui('dispatch_fetchRadioData', {});
      if (response) {
        setZones(response.zones || []);
        const N = localStorage.getItem('dispatch_selectedZones');
        if (N) {
          try {
            const M = JSON.parse(N);
            const V: any = {};
            response.zones?.forEach((Y) => {
              V[Y] = M[Y] ?? (Y !== 'divisiones' && Y !== 'saed');
            });
            setSelectedZones(V);
          } catch {
            const M: any = {};
            response.zones?.forEach((V) => {
              M[V] = V !== 'divisiones' && V !== 'saed';
            });
            setSelectedZones(M);
          }
        } else {
          const M: any = {};
          response.zones?.forEach((V) => {
            M[V] = V !== 'divisiones' && V !== 'saed';
          });
          setSelectedZones(M);
        }
        setRadioChannels(response.channels || []);
      }
      const response2 = await fetchNui('dispatch_fetchAgentData', {});
      if (response2) {
        setAgent(response2);
      }
      const response3 = await fetchNui('dispatch_fetchMembers', {});
      if (response3 && response) {
        response.channels.forEach((channel) => {
          setRadioChannelMembers([], channel.id);
        });
        const N: any = {};
        response3.forEach((item) => {
          if (!N[item.id_group]) {
            N[item.id_group] = [];
          }
          N[item.id_group].push(item);
        });
        Object.entries(N).forEach(([M, V]) => {
          setRadioChannelMembers(V, M);
        });
      }
    })();
  }, []);
  useNuiEvent('refreshMembersChannels', (P) => {
    if (P?.movedCitizenId) {
      removeMember(P.movedCitizenId);
    }
    if (P?.lastChannel) {
      setRadioChannelMembers(P.lastChannel.members, P.lastChannel.id);
    }
    if (P?.newChannel) {
      setRadioChannelMembers(P.newChannel.members, P.newChannel.id);
    }
    if (agent?.citizenid && P?.movedCitizenId === agent.citizenid && typeof P.newRadioGroup == 'string') {
      setAgentRadioGroup(P.newRadioGroup);
    }
  });
  useNuiEvent('memberStatusChanged', (P) => {
    updateMemberStatus(P.citizenid, P.status);
  });
  useNuiEvent('memberMutedChanged', (P) => {
    updateMemberMuted(P.citizenid, P.isMuted);
  });
  useNuiEvent('setRadioTalking', (P) => {
    setTalking(P.source, P.talking);
  });
  useNuiEvent('refreshData', async () => {
    if (isBrowser()) {
      return;
    }
    const response = await fetchNui('dispatch_fetchRadioData', {});
    if (response) {
      setRadioChannels(response.channels || []);
    }
    const response2 = await fetchNui('dispatch_fetchAgentData', {});
    if (response2) {
      setAgent(response2);
    }
  });
  const handleLeaveChannel = async () => {
    if (!agent) {
      return;
    }
    const P = radioChannels.find((radioChannel) => radioChannel.id === agent.id_group);
    if (!P) {
      return;
    }
    if (
      (await fetchNui('dispatch_leaveChannel', {
        id: P.id,
        zone: P.zone,
      })) ||
      isBrowser()
    ) {
      S();
      setAgentRadioGroup('');
    }
  };
  const handleMuteToggle = async () => {
    if (!agent) {
      return;
    }
    const isMuted = !(agent.isMuted || false);
    const O = radioChannels.find((radioChannel) => radioChannel.id === agent.id_group);
    if (!O) {
      return;
    }
    if (
      (await fetchNui('dispatch_setMuted', {
        isMuted,
        zone: O.zone,
        freq: O.freq,
      })) ||
      isBrowser()
    ) {
      setAgentMuted(isMuted);
    }
  };
  const joinChannel = async (P) => {
    if (!agent || P.members?.some((L) => L.citizenid === agent.citizenid)) {
      return;
    }
    if (
      (await fetchNui('dispatch_joinChannel', {
        id: P.id,
        freq: P.freq,
        zone: P.zone,
      })) ||
      isBrowser()
    ) {
      b();
      setAgentRadioGroup(P.id);
    }
  };
  const ref = useRef<any>(null);
  const ref2 = useRef<any>(false);
  const ref3 = useRef<any>(null);
  const directTalkUp = useCallback(() => {
    if (ref.current) {
      clearTimeout(ref.current);
      ref.current = null;
    }
    if (ref3.current) {
      ref3.current();
      ref3.current = null;
    }
    if (ref2.current) {
      ref2.current = false;
      const P = useAgentStore.getState().agent;
      const D = useRadioStore.getState().radioChannels;
      const O = P?.id_group ? D.find((item) => item.id === P.id_group)?.freq : null;
      fetchNui('dispatch_directTalkUp', {
        currentFreq: O || null,
      });
    }
  }, []);
  const directTalkDown = useCallback(
    (event, D) => {
      const O = useAgentStore.getState().agent;
      if (O?.id_group === D.id) {
        return;
      }
      event.stopPropagation();
      if (ref.current) {
        clearTimeout(ref.current);
        ref.current = null;
      }
      if (ref3.current) {
        ref3.current();
      }
      const L = () => {
        directTalkUp();
      };
      window.addEventListener('pointerup', L, {
        once: true,
      });
      window.addEventListener('mouseup', L, {
        once: true,
      });
      ref3.current = () => {
        window.removeEventListener('pointerup', L);
        window.removeEventListener('mouseup', L);
      };
      ref.current = setTimeout(() => {
        ref2.current = true;
        const N = useRadioStore.getState().radioChannels;
        const M = O?.id_group ? N.find((item) => item.id === O.id_group)?.freq : null;
        fetchNui('dispatch_directTalkDown', {
          freq: D.freq,
          zone: D.zone,
          currentFreq: M || null,
        });
      }, 100);
    },
    [directTalkUp],
  );
  const toggleZoneVisibility = (P) => {
    setSelectedZones((D) => {
      const O: any = {
        ...D,
        [P]: !D[P],
      };
      localStorage.setItem('dispatch_selectedZones', JSON.stringify(O));
      return O;
    });
  };
  const toggleChannelCollapse = (P) => {
    setCollapsedChannels((D) => ({
      ...D,
      [P]: !D[P],
    }));
  };
  return (
    <Box className={styles.dispatchContainer}>
      <ZoneFilter
        zones={zones}
        selectedZones={selectedZones}
        toggleZoneVisibility={toggleZoneVisibility}
        agent={agent}
        handleMuteToggle={handleMuteToggle}
        handleLeaveChannel={handleLeaveChannel}
      />
      <Box className={styles.columnsWrapper}>
        {zones
          .filter((zone) => selectedZones[zone])
          .map((zone) => {
            const channels = radioChannels.filter((radioChannel) => radioChannel.zone === zone);
            return (
              <RadioZone
                key={zone}
                zone={zone}
                channels={channels}
                agent={agent}
                talkingPlayers={talkingPlayers}
                collapsedChannels={collapsedChannels}
                toggleChannelCollapse={toggleChannelCollapse}
                joinChannel={joinChannel}
                directTalkDown={directTalkDown}
                directTalkUp={directTalkUp}
                handlePointerDown={handlePointerDown}
              />
            );
          })}
      </Box>
      {dragging && (
        <Box ref={setFloatingRef}>
          <DraggedMember member={dragging.member} />
        </Box>
      )}
    </Box>
  );
}
