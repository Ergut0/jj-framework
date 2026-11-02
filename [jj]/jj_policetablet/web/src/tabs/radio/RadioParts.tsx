import { ActionIcon, Badge, Box, Checkbox, Group, ScrollArea, Stack, Text, Title } from '@mantine/core';
import { useEffect, useState } from 'react';
import { FaVolumeMute, FaVolumeUp } from 'react-icons/fa';
import {
  FaAngleDown,
  FaAngleUp,
  FaDog,
  FaFlagCheckered,
  FaHelicopter,
  FaMicrophone,
  FaPowerOff as FaPowerOff2,
  FaRadio,
  FaShip,
  FaUsers,
  FaWalkieTalkie,
} from 'react-icons/fa6';
import { IconX5 } from '../../icons';
import { fetchNui, isBrowser } from '../../utils/nui';
import styles from '../../styles/Radio.module.css';

export function ZoneFilter({
  zones,
  selectedZones,
  toggleZoneVisibility,
  agent,
  handleMuteToggle,
  handleLeaveChannel,
}: any) {
  const [opened, setOpened] = useState<any>(false);
  const u = async () => {
    if (!opened) {
      setOpened(true);
      if (!isBrowser()) {
        await fetchNui('dispatch_globalTalkDown', {});
      }
    }
  };
  const f = async () => {
    if (opened) {
      setOpened(false);
      if (!isBrowser()) {
        await fetchNui('dispatch_globalTalkUp', {});
      }
    }
  };
  useEffect(() => {
    const h = () => {
      if (opened) {
        f();
      }
    };
    window.addEventListener('pointerup', h);
    window.addEventListener('mouseup', h);
    return () => {
      window.removeEventListener('pointerup', h);
      window.removeEventListener('mouseup', h);
    };
  }, [opened]);
  return (
    <Box className={styles.header}>
      <Box className={styles.titleArea}>
        <FaWalkieTalkie size={22} color="white" />
        <Title order={3} tt="uppercase" lts={1} c="white">
          Panel de Dispatch
        </Title>
      </Box>
      <Group gap="lg" align="center">
        <Box className={styles.zoneSelector}>
          <Text size="xs" fw="bold" c="dimmed" tt="uppercase" lts={1}>
            Frecuencias activas:
          </Text>
          <Group gap="md">
            {zones.map((zone) => (
              <Checkbox
                key={zone}
                size="xs"
                color="gray"
                label={zone.toUpperCase()}
                checked={!!selectedZones[zone]}
                onChange={() => toggleZoneVisibility(zone)}
                styles={{
                  label: {
                    color: '#ffffff',
                    fontWeight: 700,
                  },
                }}
              />
            ))}
          </Group>
        </Box>
        {agent?.id_group && agent.id_group !== '' && (
          <Box
            className={`${styles.broadcastButton} ${opened ? styles.broadcastButtonActive : ''}`}
            onPointerDown={(event) => {
              event.preventDefault();
              u();
            }}
            onPointerUp={(event) => {
              event.preventDefault();
              f();
            }}
          >
            <FaRadio size={14} />
            <Text size="xs" fw="bold">
              {opened ? 'Transmitiendo...' : 'Broadcast Global'}
            </Text>
          </Box>
        )}
        {agent?.id_group && agent.id_group !== '' && (
          <Group gap={6}>
            <ActionIcon
              size={28}
              variant="light"
              color={agent.isMuted ? 'red' : 'gray'}
              onClick={handleMuteToggle}
            >
              {agent.isMuted ? <FaVolumeMute size={14} /> : <FaVolumeUp size={14} />}
            </ActionIcon>
            <ActionIcon size={28} variant="light" color="red" onClick={handleLeaveChannel}>
              <FaPowerOff2 size={14} />
            </ActionIcon>
          </Group>
        )}
      </Group>
    </Box>
  );
}

export const radioIcon =
  "data:image/svg+xml,%3c?xml%20version='1.0'%20encoding='utf-8'?%3e%3csvg%20xmlns='http://www.w3.org/2000/svg'%20xmlns:xlink='http://www.w3.org/1999/xlink'%20style='margin:%20auto;%20background:%20none;%20display:%20block;%20shape-rendering:%20auto;'%20width='48px'%20height='48px'%20viewBox='0%200%20100%20100'%20preserveAspectRatio='xMidYMid'%3e%3ccircle%20cx='50'%20cy='50'%20r='0'%20fill='none'%20stroke='%23a3ee94ff'%20stroke-width='23'%3e%3canimate%20attributeName='r'%20repeatCount='indefinite'%20dur='1s'%20values='0;46'%20keyTimes='0;1'%20keySplines='0%200.2%200.8%201'%20calcMode='spline'%20begin='0s'%3e%3c/animate%3e%3canimate%20attributeName='opacity'%20repeatCount='indefinite'%20dur='1s'%20values='1;0'%20keyTimes='0;1'%20keySplines='0.2%200%200.8%201'%20calcMode='spline'%20begin='0s'%3e%3c/animate%3e%3c/circle%3e%3ccircle%20cx='50'%20cy='50'%20r='0'%20fill='none'%20stroke='%23a3ee94ff'%20stroke-width='23'%3e%3canimate%20attributeName='r'%20repeatCount='indefinite'%20dur='1s'%20values='0;46'%20keyTimes='0;1'%20keySplines='0%200.2%200.8%201'%20calcMode='spline'%20begin='-0.5s'%3e%3c/animate%3e%3canimate%20attributeName='opacity'%20repeatCount='indefinite'%20dur='1s'%20values='1;0'%20keyTimes='0;1'%20keySplines='0.2%200%200.8%201'%20calcMode='spline'%20begin='-0.5s'%3e%3c/animate%3e%3c/circle%3e%3c!--%20[ldio]%20generated%20by%20https://loading.io/%20--%3e%3c/svg%3e";

export function RadioMember({ member, channelId, mIdx, isSelf, isTalking, handlePointerDown }: any) {
  return (
    <Box
      className={`${styles.memberRow} ${isTalking ? styles.memberRowTalking : ''}`}
      onPointerDown={(i) => {
        if (!isSelf) {
          handlePointerDown(i, member, channelId, mIdx);
        }
      }}
      data-member-index={mIdx}
      style={{
        touchAction: 'none',
      }}
    >
      <Box className={styles.memberLeft}>
        <IconX5 size={7} color={member.status ? 'green' : 'red'} />
        <Text className={styles.memberName}>{member.fullname}</Text>
        {member.divisions?.length >= 1 && (
          <Box
            style={{
              display: 'flex',
              gap: '6px',
              opacity: 1,
            }}
          >
            {member.divisions.includes('ASD') && <FaHelicopter size={12} color="#ffffff" />}
            {member.divisions.includes('TRAFFIC DIVISION') && <FaFlagCheckered size={12} color="#ffffff" />}
            {member.divisions.includes('SAPA') && <FaShip size={12} color="#ffffff" />}
            {member.divisions.includes('K9') && <FaDog size={12} color="#ffffff" />}
          </Box>
        )}
        {member.isMuted && <FaVolumeMute size={13} />}
        {isTalking && (
          <Box className={styles.talkingIndicator}>
            <img src={radioIcon} alt="Talking" width={15} height={15} />
          </Box>
        )}
      </Box>
      <Badge size="sm" variant="light" color="gray" radius="sm">
        {member.rank}
      </Badge>
    </Box>
  );
}

export function RadioChannel({
  channel,
  agent,
  talkingPlayers,
  collapsedChannels,
  toggleChannelCollapse,
  joinChannel,
  directTalkDown,
  handlePointerDown,
}: any) {
  const u = !!collapsedChannels[channel.id];
  const f = agent?.id_group === channel.id;
  const h = channel.members || [];
  return (
    <Box
      data-radio-id={channel.id}
      className={f ? styles.radioChannelActive : styles.radioChannel}
      onClick={() => joinChannel(channel)}
    >
      <Box className={styles.channelHeader}>
        <Text size="xs" fw="bold" c="white" lts={0.5}>
          {channel.name}
        </Text>
        <Group gap={8}>
          {agent?.id_group !== channel.id && (
            <Box
              className={styles.directTalkBtn}
              onClick={(event) => event.stopPropagation()}
              onPointerDown={(p) => directTalkDown(p, channel)}
            >
              <FaMicrophone size={11} />
              <span>HABLAR</span>
            </Box>
          )}
          <Group
            gap={3}
            onClick={(event) => {
              event.stopPropagation();
              toggleChannelCollapse(channel.id);
            }}
          >
            <FaUsers size={14} color="#e0e0e0" />
            <Text size="xs" c="white" fw="bold">
              {h.length}
            </Text>
          </Group>
          <Box
            onClick={(event) => {
              event.stopPropagation();
              toggleChannelCollapse(channel.id);
            }}
            style={{
              display: 'flex',
              alignItems: 'center',
            }}
          >
            {u ? <FaAngleDown size={12} color="#e0e0e0" /> : <FaAngleUp size={12} color="#e0e0e0" />}
          </Box>
        </Group>
      </Box>
      {!u && h.length > 0 && (
        <Box className={styles.membersList}>
          {h.map((item, index) => {
            const isSelf = item.citizenid === agent?.citizenid;
            const isTalking = item.source ? !!talkingPlayers[item.source] : false;
            return (
              <RadioMember
                key={`${item.citizenid}-${index}`}
                member={item}
                channelId={channel.id}
                mIdx={index}
                isSelf={isSelf}
                isTalking={isTalking}
                handlePointerDown={handlePointerDown}
              />
            );
          })}
        </Box>
      )}
    </Box>
  );
}

export function RadioZone({
  zone,
  channels,
  agent,
  talkingPlayers,
  collapsedChannels,
  toggleChannelCollapse,
  joinChannel,
  directTalkDown,
  directTalkUp,
  handlePointerDown,
}: any) {
  return (
    <Box className={styles.zoneColumn}>
      <Box className={styles.columnHeader}>
        <Text className={styles.columnTitle}>{zone.toUpperCase()}</Text>
      </Box>
      <ScrollArea h="88vh" p={12} scrollbarSize={4} scrollbars="y">
        <Stack gap="sm">
          {channels.map((channel) => (
            <RadioChannel
              key={channel.id}
              channel={channel}
              agent={agent}
              talkingPlayers={talkingPlayers}
              collapsedChannels={collapsedChannels}
              toggleChannelCollapse={toggleChannelCollapse}
              joinChannel={joinChannel}
              directTalkDown={directTalkDown}
              directTalkUp={directTalkUp}
              handlePointerDown={handlePointerDown}
            />
          ))}
        </Stack>
      </ScrollArea>
    </Box>
  );
}
