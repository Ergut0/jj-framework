import { Badge, Box, Flex, Group, ScrollArea, Stack, Tabs, Text, UnstyledButton } from '@mantine/core';
import { useEffect, useRef, useState } from 'react';
import { FaVolumeMute, FaVolumeUp } from 'react-icons/fa';
import {
  FaAngleDown,
  FaAngleUp,
  FaCircle,
  FaDog,
  FaFlagCheckered,
  FaGun,
  FaHelicopter,
  FaMicrophone,
  FaPowerOff,
  FaShip,
  FaUsers,
  FaWalkieTalkie,
} from 'react-icons/fa6';
import useSound from 'use-sound';
import joinSound from '../assets/join.mp3';
import leaveSound from '../assets/leave.mp3';
import { useAgentStore } from '../store/agent';
import { useRadioStore } from '../store/radio';
import { useTalkingStore } from '../store/talking';
import { fetchNui, isBrowser, useNuiEvent } from '../utils/nui';
import styles from '../styles/RadioTab.module.css';

export function RadioMember({ index, member, onPointerDown }: any) {
  const { agent } = useAgentStore();
  useRadioStore();
  const { talkingPlayers } = useTalkingStore();
  const s = member?.citizenid && agent?.citizenid && member.citizenid === agent.citizenid;
  return (
    <Group
      align="center"
      justify="space-between"
      className={styles.radioChannelMember}
      onPointerDown={(e) => {
        if (!s && onPointerDown) {
          onPointerDown(e);
        }
      }}
      data-member-index={index}
      style={{
        touchAction: 'none',
        userSelect: 'none',
      }}
    >
      <Group gap="xs" align="center" justify="center">
        {member.status ? <FaCircle size={9} color="#22c55e" /> : <FaCircle size={9} color="#ef4444" />}
        <Text size="xs" fw="bold">
          {member.fullname}
        </Text>
        {member.divisions?.length >= 1 && (
          <Group className={styles.iconDivision} gap={9}>
            {member.divisions?.includes('ASD') && <FaHelicopter />}
            {member.divisions?.includes('TRAFFIC DIVISION') && <FaFlagCheckered />}
            {member.divisions?.includes('SAPA') && <FaShip />}
            {member.divisions?.includes('K9') && <FaDog />}
          </Group>
        )}
        {member.isMuted && (
          <Flex justify="center" align="center" w={14} h={14}>
            <FaVolumeMute />
          </Flex>
        )}
        {(member.source ? talkingPlayers[member.source] : false) && (
          <Box className={styles.talkingIndicator}>
            <img
              src={
                "data:image/svg+xml,%3c?xml%20version='1.0'%20encoding='utf-8'?%3e%3csvg%20xmlns='http://www.w3.org/2000/svg'%20xmlns:xlink='http://www.w3.org/1999/xlink'%20style='margin:%20auto;%20background:%20none;%20display:%20block;%20shape-rendering:%20auto;'%20width='48px'%20height='48px'%20viewBox='0%200%20100%20100'%20preserveAspectRatio='xMidYMid'%3e%3ccircle%20cx='50'%20cy='50'%20r='0'%20fill='none'%20stroke='%23a3ee94ff'%20stroke-width='23'%3e%3canimate%20attributeName='r'%20repeatCount='indefinite'%20dur='1s'%20values='0;46'%20keyTimes='0;1'%20keySplines='0%200.2%200.8%201'%20calcMode='spline'%20begin='0s'%3e%3c/animate%3e%3canimate%20attributeName='opacity'%20repeatCount='indefinite'%20dur='1s'%20values='1;0'%20keyTimes='0;1'%20keySplines='0.2%200%200.8%201'%20calcMode='spline'%20begin='0s'%3e%3c/animate%3e%3c/circle%3e%3ccircle%20cx='50'%20cy='50'%20r='0'%20fill='none'%20stroke='%23a3ee94ff'%20stroke-width='23'%3e%3canimate%20attributeName='r'%20repeatCount='indefinite'%20dur='1s'%20values='0;46'%20keyTimes='0;1'%20keySplines='0%200.2%200.8%201'%20calcMode='spline'%20begin='-0.5s'%3e%3c/animate%3e%3canimate%20attributeName='opacity'%20repeatCount='indefinite'%20dur='1s'%20values='1;0'%20keyTimes='0;1'%20keySplines='0.2%200%200.8%201'%20calcMode='spline'%20begin='-0.5s'%3e%3c/animate%3e%3c/circle%3e%3c!--%20[ldio]%20generated%20by%20https://loading.io/%20--%3e%3c/svg%3e"
              }
              alt="Hablando"
              width={14}
              height={14}
              style={{
                filter:
                  'invert(62%) sepia(85%) saturate(357%) hue-rotate(63deg) brightness(97%) contrast(92%)',
              }}
            />
          </Box>
        )}
      </Group>
      <Badge size="sm" variant="light" color="dark.6" radius="sm">
        {member.rank}
      </Badge>
    </Group>
  );
}

export function RadioChannel({ radio, onPointerDown }: any) {
  const [expanded, setExpanded] = useState<any>(false);
  const { agent, setAgentRadioGroup } = useAgentStore();
  const [c] = useSound(joinSound);
  useRadioStore();
  const u = (event) => {
    event.stopPropagation();
    setExpanded(!expanded);
  };
  const ref = useRef<any>(null);
  const ref2 = useRef<any>(false);
  const ref3 = useRef<any>(null);
  return (
    <Box data-radio-id={radio.id}>
      <Group
        className={expanded ? styles.radioChannel : styles.radioChannelCollapsed}
        justify="space-between"
        onClick={async () => {
          if (
            radio.members?.some((e) => e?.citizenid && agent?.citizenid && e.citizenid == agent.citizenid)
          ) {
            return;
          }
          const response = await fetchNui('joinChannel', {
            id: radio.id,
            freq: radio.freq,
            zone: radio.zone,
          });
          c();
          if (response) {
            setAgentRadioGroup(radio.id);
          }
        }}
      >
        <Text size="xs" fw="bold" lts={0.7}>
          {radio.name}
        </Text>
        <Group gap={8} align="center" justify="center">
          {agent?.id_group !== radio.id && (
            <Box
              className={styles.directTalkBtn}
              onClick={stopPropagation}
              onPointerDown={(event) =>
                ((event2) => {
                  const t = useAgentStore.getState().agent;
                  if (t?.id_group == radio.id) {
                    return;
                  }
                  event2.stopPropagation();
                  ref.current &&= (clearTimeout(ref.current), null);
                  if (ref3.current) {
                    ref3.current();
                  }
                  const r = () => {
                    (() => {
                      ref.current &&= (clearTimeout(ref.current), null);
                      ref3.current &&= (ref3.current(), null);
                      if (ref2.current) {
                        ref2.current = false;
                        const e = useAgentStore.getState().agent;
                        const t = useRadioStore.getState().radioChannels;
                        fetchNui('directTalkUp', {
                          currentFreq:
                            (e?.id_group ? t.find((item) => item.id === e.id_group)?.freq : null) || null,
                        });
                      }
                    })();
                  };
                  window.addEventListener('pointerup', r, {
                    once: true,
                  });
                  window.addEventListener('mouseup', r, {
                    once: true,
                  });
                  ref3.current = () => {
                    window.removeEventListener('pointerup', r);
                    window.removeEventListener('mouseup', r);
                  };
                  ref.current = setTimeout(() => {
                    ref2.current = true;
                    const e = useRadioStore.getState().radioChannels;
                    const r = t?.id_group ? e.find((item) => item.id === t.id_group)?.freq : null;
                    fetchNui('directTalkDown', {
                      freq: radio.freq,
                      zone: radio.zone,
                      channelId: radio.id,
                      currentFreq: r || null,
                    });
                  }, 100);
                })(event)
              }
            >
              <FaMicrophone size={11} />
              <span>HABLAR</span>
            </Box>
          )}
          <Group gap={4} align="center" justify="center" onClick={(e) => u(e)}>
            <FaUsers size={17} color="var(--mantine-color-green-2)" />
            <Text size="xs" c="green.2">
              {radio.members ? radio.members.length : 0}
            </Text>
          </Group>
          {expanded ? (
            <FaAngleUp size={13} color="var(--mantine-color-green-2)" onClick={(e) => u(e)} />
          ) : (
            <FaAngleDown size={13} color="var(--mantine-color-green-2)" onClick={(e) => u(e)} />
          )}
        </Group>
      </Group>
      {!expanded && (
        <Stack gap={0}>
          {!expanded && (
            <Stack gap={0}>
              {radio.members?.map((e, t) => (
                <RadioMember
                  key={t}
                  index={t}
                  member={e}
                  radioId={radio.id}
                  onPointerDown={(i) => onPointerDown(i, e, radio.id, t)}
                  data-member-index={t}
                />
              ))}
            </Stack>
          )}
        </Stack>
      )}
    </Box>
  );
}

export function stopPropagation(e) {
  return e.stopPropagation();
}

export function useMemberDrag(e, t) {
  const { radioChannels, setRadioChannelMembers } = useRadioStore();
  const [dragging, setDragging] = useState<any>(null);
  const [pos, setPos] = useState<any>({
    x: 0,
    y: 0,
  });
  const ref = useRef<any>(e);
  useEffect(() => {
    ref.current = e;
  }, [e]);
  const m = async (e, t, n, a) => {
    if (e === t) {
      return;
    }
    const o = radioChannels.find((radioChannel) => radioChannel.id === e);
    const s = radioChannels.find((radioChannel) => radioChannel.id === t);
    if (!o?.members || !s) {
      return;
    }
    const c = o.members[n];
    if (!c || s.members?.some((e) => e.citizenid === c.citizenid)) {
      return;
    }
    const l = [...o.members];
    l.splice(n, 1);
    const u = s.members ? [...s.members] : [];
    u.splice(a, 0, c);
    if (
      (await fetchNui('moveMember', {
        citizenid: c.citizenid,
        lastId: e,
        newId: t,
        newFreq: s.freq,
        zone: s.zone,
      })) &&
      isBrowser()
    ) {
      setRadioChannelMembers(l, e);
      setRadioChannelMembers(u, t);
    }
  };
  let y;
  y = [dragging, t, radioChannels, m];
  useEffect(() => {
    if (!dragging) {
      return;
    }
    const e = (event) => {
      event.preventDefault();
      setPos({
        x: event.clientX,
        y: event.clientY,
      });
      const n = document.elementFromPoint(event.clientX, event.clientY);
      if (n) {
        const e = n.closest('[data-zone]')?.getAttribute('data-zone');
        if (e && e !== ref.current) {
          t(e);
        }
      }
    };
    const n = (event) => {
      event.preventDefault();
      if (!dragging) {
        return;
      }
      const t = document.elementFromPoint(event.clientX, event.clientY);
      if (t) {
        const e = t.closest('[data-radio-id]');
        let n = null;
        let i = 0;
        if (e) {
          n = e.getAttribute('data-radio-id');
          const a = t.closest('[data-member-index]');
          i = a
            ? parseInt(a.getAttribute('data-member-index'), 10)
            : (radioChannels.find((radioChannel) => radioChannel.id === n)?.members?.length ?? 0);
        }
        if (n) {
          m(dragging.sourceRadioId, n, dragging.index, i);
        }
      }
      setDragging(null);
    };
    window.addEventListener('pointermove', e);
    window.addEventListener('pointerup', n);
    return () => {
      window.removeEventListener('pointermove', e);
      window.removeEventListener('pointerup', n);
    };
  }, y);
  return {
    dragging,
    pos,
    handlePointerDown: (event, t, n, r) => {
      event.stopPropagation();
      setDragging({
        member: t,
        sourceRadioId: n,
        index: r,
      });
      setPos({
        x: event.clientX,
        y: event.clientY,
      });
    },
  };
}

export function DraggedMember({ member, style, className }: any) {
  return (
    <Box
      className={`${styles.radioChannelMember} ${className || ''}`}
      style={{
        opacity: 0.7,
        backgroundColor: 'var(--mantine-color-dark-8)',
        border: '1px solid var(--mantine-color-dark-6)',
        borderRadius: '5px',
        padding: '10px',
        pointerEvents: 'none',
        ...style,
      }}
    >
      <Group align="center" justify="space-between">
        <Group gap="xs" align="center" justify="center">
          {member.status ? <FaCircle size={9} color="#22c55e" /> : <FaCircle size={9} color="#ef4444" />}
          <Text size="xs" fw="bold">
            {member.fullname}
          </Text>
          <Group className={styles.iconDivision} gap={9}>
            <FaGun />
            <FaHelicopter />
          </Group>
        </Group>
        <Badge size="sm" variant="light" color="dark.6" radius="sm">
          {member.rank}
        </Badge>
      </Group>
    </Box>
  );
}

export function RadioTab({ radioInfo }: any) {
  const [zone, setZone] = useState<any>('lspd');
  const viewportRef = useRef<any>(null);
  const ref = useRef<any>({});
  useEffect(() => {
    if (viewportRef.current) {
      const top = ref.current[zone] || 0;
      viewportRef.current.scrollTo({
        top,
        behavior: 'instant',
      });
    }
  }, [zone]);
  const { radioChannels, updateMemberStatus, updateMemberMuted } = useRadioStore();
  const { agent, setAgentMuted } = useAgentStore();
  const { dragging, pos, handlePointerDown } = useMemberDrag(zone, setZone);
  const [y] = useSound(leaveSound);
  useNuiEvent('memberStatusChanged', function (e) {
    updateMemberStatus(e.citizenid, e.status);
  });
  useNuiEvent('memberMutedChanged', function (e) {
    updateMemberMuted(e.citizenid, e.isMuted);
  });
  if (!radioInfo) {
    return null;
  }
  const Component = Box;
  const O = Tabs;
  const D = ScrollArea;
  const E = Stack;
  return (
    <Component
      style={{
        flex: 1,
        minHeight: 0,
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      <Group gap="xs">
        <FaWalkieTalkie size={20} color="var(--mantine-color-green-1)" />
        <Text tt="uppercase" lts={0.7} c="white" fw="bold">
          Radio
        </Text>
      </Group>
      <O
        mt={10}
        color="green.2"
        defaultValue="lspd"
        value={zone}
        style={{
          flex: 1,
          minHeight: 0,
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        <Tabs.List justify="center">
          {radioInfo.map((item, index) => (
            <Tabs.Tab key={index} value={item} fw="bold" onClick={() => setZone(item)} data-zone={item}>
              {item.toUpperCase()}
            </Tabs.Tab>
          ))}
        </Tabs.List>
        <Group mt={19} w="100%" gap="xs" wrap="nowrap">
          <Box className={styles.headerFreq}>
            <Text tt="uppercase" fw={900} c="green.1" size="xs" lts={1.9}>
              {'Frecuencias '}
              {`${zone.toUpperCase()}`}
            </Text>
          </Box>
          <Group gap={6} wrap="nowrap">
            <UnstyledButton
              className={styles.buttonFreq}
              onClick={async () => {
                const e = radioChannels.find((radioChannel) => radioChannel.id == agent.id_group);
                if (e) {
                  await fetchNui('leaveChannel', {
                    id: e.id,
                    zone: e.zone,
                  });
                  y();
                }
              }}
            >
              <FaPowerOff />
            </UnstyledButton>
            <UnstyledButton
              className={styles.buttonFreq}
              onClick={async () => {
                const isMuted = !agent.isMuted;
                const t = radioChannels.find((radioChannel) => radioChannel.id == agent.id_group);
                if (
                  t &&
                  (await fetchNui('setMuted', {
                    isMuted,
                    zone,
                    freq: t.freq,
                  }))
                ) {
                  setAgentMuted(isMuted);
                }
              }}
              data-active={agent.isMuted ? 'true' : 'false'}
              style={{
                borderColor: agent.isMuted ? 'rgba(255, 74, 74, 0.7)' : undefined,
                backgroundColor: agent.isMuted ? 'rgba(255, 74, 74, 0.5)' : undefined,
                color: agent.isMuted ? 'rgb(255, 74, 74)' : 'white',
              }}
            >
              {agent.isMuted ? <FaVolumeMute /> : <FaVolumeUp />}
            </UnstyledButton>
          </Group>
        </Group>
        <D
          viewportRef={viewportRef}
          style={{
            flex: 1,
            minHeight: 0,
          }}
          mt={13}
          type="never"
          scrollbars="y"
          onScrollPositionChange={(e) => {
            ref.current[zone] = e.y;
          }}
        >
          <E gap="xs" pb={8}>
            {radioChannels
              .filter((radioChannel) => radioChannel.zone === zone)
              .map((radioChannel, index) => (
                <RadioChannel key={index} radio={radioChannel} onPointerDown={handlePointerDown} />
              ))}
          </E>
        </D>
      </O>
      {dragging && (
        <Box
          style={{
            position: 'fixed',
            left: pos.x + 10,
            top: pos.y + 10,
            zIndex: 9999,
          }}
        >
          <DraggedMember member={dragging.member} />
        </Box>
      )}
    </Component>
  );
}
