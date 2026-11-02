import { Box, FloatingWindow, Group, Stack, Text } from '@mantine/core';
import { useRef } from 'react';
import { FaVolumeMute } from 'react-icons/fa';
import { FaCircle, FaWalkieTalkie } from 'react-icons/fa6';
import { useAgentStore } from '../store/agent';
import { useLockStore } from '../store/lock';
import { useRadioStore } from '../store/radio';
import { useTalkingStore } from '../store/talking';
import styles from '../styles/RadioHud.module.css';

export function now() {
  return Date.now();
}

export function RadioHud() {
  const { unlocked } = useLockStore();
  const { agent } = useAgentStore();
  const { radioChannels, showMembersInHUD } = useRadioStore();
  const { talkingPlayers } = useTalkingStore();
  const setPositionRef = useRef<any>(null);
  let s;
  let c = Symbol.for('react.early_return_sentinel');
  bb0: {
    const u = radioChannels.find((radioChannel) => radioChannel.id === agent.id_group);
    if (!u) {
      return null;
    }
    const p = u.members || [];
    const m = p.length > 0;
    const h = showMembersInHUD && m;
    s = (
      <FloatingWindow
        className={`${styles.hudWrapper} ${h ? styles.hudWrapperExpanded : ''}`}
        enabled={unlocked}
        onPositionChange={saveRadioHudPosition}
        initialPosition={loadRadioHudPosition()}
        setPositionRef={setPositionRef}
      >
        <Box className={styles.channelCard}>
          <Group gap={8} align="center" wrap="nowrap">
            {h ? (
              <FaWalkieTalkie size={12} color="var(--mantine-color-green-3)" />
            ) : (
              <FaCircle size={9} color={agent.status ? '#22c55e' : '#ef4444'} />
            )}
            <Text size="xs" fw={700} c="white" lts={0.5} truncate>
              {u.name}
            </Text>
          </Group>
        </Box>
        {h && (
          <Stack
            gap={4}
            mt={4}
            style={{
              width: '100%',
            }}
          >
            {p.map((item, index) => {
              const n = item.source ? talkingPlayers[item.source] : false;
              let r = item.fullname;
              const i = item.fullname.match(/^([^\s]+)\s+([^\s]+)\s*(.*)$/);
              if (i) {
                const e = i[1];
                const t = i[2];
                const n = i[3] || '';
                r = `${e.charAt(0)}. ${t}${n ? ' ' + n : ''}`;
              }
              return (
                <Box
                  key={`${item.citizenid}-${index}`}
                  className={`${styles.memberCard} ${n ? styles.memberCardTalking : ''}`}
                >
                  <Box className={styles.memberLeft}>
                    <FaCircle size={8} color={item.status ? '#22c55e' : '#ef4444'} />
                    <Text className={styles.memberName}>{r}</Text>
                  </Box>
                  <Box className={styles.memberRight}>
                    {item.isMuted && <FaVolumeMute size={10} color="var(--mantine-color-red-5)" />}
                    {n && (
                      <Box className={styles.talkingIndicator}>
                        <img
                          src={
                            "data:image/svg+xml,%3c?xml%20version='1.0'%20encoding='utf-8'?%3e%3csvg%20xmlns='http://www.w3.org/2000/svg'%20xmlns:xlink='http://www.w3.org/1999/xlink'%20style='margin:%20auto;%20background:%20none;%20display:%20block;%20shape-rendering:%20auto;'%20width='48px'%20height='48px'%20viewBox='0%200%20100%20100'%20preserveAspectRatio='xMidYMid'%3e%3ccircle%20cx='50'%20cy='50'%20r='0'%20fill='none'%20stroke='%23a3ee94ff'%20stroke-width='23'%3e%3canimate%20attributeName='r'%20repeatCount='indefinite'%20dur='1s'%20values='0;46'%20keyTimes='0;1'%20keySplines='0%200.2%200.8%201'%20calcMode='spline'%20begin='0s'%3e%3c/animate%3e%3canimate%20attributeName='opacity'%20repeatCount='indefinite'%20dur='1s'%20values='1;0'%20keyTimes='0;1'%20keySplines='0.2%200%200.8%201'%20calcMode='spline'%20begin='0s'%3e%3c/animate%3e%3c/circle%3e%3ccircle%20cx='50'%20cy='50'%20r='0'%20fill='none'%20stroke='%23a3ee94ff'%20stroke-width='23'%3e%3canimate%20attributeName='r'%20repeatCount='indefinite'%20dur='1s'%20values='0;46'%20keyTimes='0;1'%20keySplines='0%200.2%200.8%201'%20calcMode='spline'%20begin='-0.5s'%3e%3c/animate%3e%3canimate%20attributeName='opacity'%20repeatCount='indefinite'%20dur='1s'%20values='1;0'%20keyTimes='0;1'%20keySplines='0.2%200%200.8%201'%20calcMode='spline'%20begin='-0.5s'%3e%3c/animate%3e%3c/circle%3e%3c!--%20[ldio]%20generated%20by%20https://loading.io/%20--%3e%3c/svg%3e"
                          }
                          alt="Talking"
                          width={10}
                          height={10}
                          style={{
                            filter:
                              'invert(62%) sepia(85%) saturate(357%) hue-rotate(63deg) brightness(97%) contrast(92%)',
                          }}
                        />
                      </Box>
                    )}
                  </Box>
                </Box>
              );
            })}
          </Stack>
        )}
      </FloatingWindow>
    );
  }
  return c === Symbol.for('react.early_return_sentinel') ? s : c;
}

export function saveRadioHudPosition(e) {
  localStorage.setItem(
    'radioHudPosition',
    JSON.stringify({
      top: e.y,
      left: e.x,
    }),
  );
}

export function loadRadioHudPosition() {
  const e = localStorage.getItem('radioHudPosition');
  return e
    ? JSON.parse(e)
    : {
        top: 20,
        left: 20,
      };
}
