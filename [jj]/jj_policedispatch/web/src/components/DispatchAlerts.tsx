import { Box, FloatingWindow, Group, Stack, Text } from '@mantine/core';
import { useEffect, useRef, useState } from 'react';
import {
  FaAngleLeft,
  FaAngleRight,
  FaCar,
  FaClock,
  FaComment,
  FaCreditCard,
  FaIdBadge,
  FaLocationDot,
  FaPalette,
} from 'react-icons/fa6';
import useSound from 'use-sound';
import alertSound from '../assets/alert.mp3';
import panicSound from '../assets/panic.mp3';
import { useAgentStore } from '../store/agent';
import { useAlertsStore } from '../store/alerts';
import { useLockStore } from '../store/lock';
import { useRadioStore } from '../store/radio';
import { fetchNui, useNuiEvent } from '../utils/nui';
import { now } from './RadioHud';
import styles from '../styles/DispatchAlerts.module.css';

export function DispatchAlerts() {
  const { unlocked } = useLockStore();
  const { alerts, addNewAlert, updateAlertUnit, deleteAlert } = useAlertsStore();
  const { agent } = useAgentStore();
  const { radioChannels } = useRadioStore();
  const [currentAlert, setCurrentAlert] = useState<any>(alerts[0]);
  const [pinned, setPinned] = useState<any>(false);
  const [p] = useSound(alertSound, {
    volume: 0.2,
  });
  const [h] = useSound(panicSound, {
    volume: 0.4,
  });
  const [currentTime, setCurrentTime] = useState<any>(now);
  const y = currentAlert ? alerts.findIndex((alert) => alert.id === currentAlert.id) : -1;
  const b = y;
  useEffect(() => {
    if (!alerts || alerts.length === 0) {
      setCurrentAlert(null);
    } else {
      if (!currentAlert || !alerts.some((alert) => alert.id === currentAlert.id)) {
        setCurrentAlert(alerts[alerts.length - 1]);
      }
    }
  }, [alerts]);
  useEffect(() => {
    const e = setInterval(() => {
      setCurrentTime(Date.now());
    }, 1e3);
    return () => clearInterval(e);
  }, []);
  const setPositionRef = useRef<any>(null);
  useEffect(() => {
    const e = localStorage.getItem('dispatchPosition');
    if (e && setPositionRef.current) {
      const t = JSON.parse(e);
      setPositionRef.current(t);
    }
  }, []);
  useNuiEvent('newAlert', function (e) {
    console.log('new alert', e);
    ((e) => {
      addNewAlert(e);
      if (!pinned) {
        setCurrentAlert(e);
      }
      if (e.textAlert && (e.textAlert.includes('[444]') || e.textAlert.includes('[QRR]'))) {
        h();
      } else {
        p();
      }
    })(e);
  });
  useNuiEvent('alertUnitAssigned', function (e) {
    if (e && e.alertId) {
      updateAlertUnit(e.alertId, e.assignedUnit);
      setCurrentAlert((t) =>
        t && t.id === e.alertId
          ? {
              ...t,
              assignedUnit: e.assignedUnit,
            }
          : t,
      );
    }
  });
  useNuiEvent('nextPage', function () {
    if (alerts.length) {
      setCurrentAlert(
        (e) => alerts[((e ? alerts.findIndex((alert) => alert.id === e.id) : -1) + 1) % alerts.length],
      );
    }
  });
  useNuiEvent('prevPage', function () {
    if (alerts.length) {
      setCurrentAlert(
        (e) =>
          alerts[
            ((e ? alerts.findIndex((alert) => alert.id === e.id) : 0) - 1 + alerts.length) % alerts.length
          ],
      );
    }
  });
  useNuiEvent('setWaypoint', function () {
    if (!currentAlert) {
      return;
    }
    const pinned2 = !pinned;
    setPinned(pinned2);
    fetchNui('setWaypoint', {
      id: currentAlert.id,
      pinned: pinned2,
    });
  });
  useNuiEvent('avisos:syncWayPoint', function (e) {
    const t = alerts.find((alert) => alert.id === e.index) ?? null;
    if (t) {
      setCurrentAlert(t);
    }
    setPinned(e.pinned);
    if (e.pinned) {
      fetchNui('syncWaypoint', {
        coords: e.coords,
      });
    } else {
      fetchNui('resetWaypoint', {});
    }
  });
  useNuiEvent('deleteAlert', (e) => {
    deleteAlert(e);
  });
  const H = normalizeChannelName;
  const W =
    currentAlert?.textAlert &&
    (currentAlert.textAlert.includes('[444]') || currentAlert.textAlert.includes('[QRR]'));
  const G = !!W;
  const K = ((e, t, n) => {
    if (!e || !t) {
      return false;
    }
    const r = e.toLowerCase().trim();
    const i = H(e);
    const a = t.toLowerCase().trim();
    const o = H(t);
    if (r === a || i === o) {
      return true;
    }
    const s = n?.find((e) => e.id.toLowerCase() === a);
    if (s) {
      const e = s.name.toLowerCase().trim();
      const t = H(s.name);
      if (r === e || i === t || r === s.id.toLowerCase()) {
        return true;
      }
    }
    return false;
  })(currentAlert?.assignedUnit, agent?.id_group, radioChannels);
  return (
    <FloatingWindow
      className={`${styles.container} ${G ? styles.containerPanic : K ? styles.containerAssigned : ''}`}
      enabled={unlocked}
      onPositionChange={saveDispatchPosition}
      initialPosition={loadDispatchPosition()}
      setPositionRef={setPositionRef}
    >
      <Group
        justify="space-between"
        align="flex-start"
        wrap="nowrap"
        className={`${styles.header} ${G ? styles.headerPanic : K ? styles.headerAssigned : ''}`}
      >
        <Group
          gap={6}
          align="center"
          wrap="nowrap"
          style={{
            flex: 1,
            minWidth: 0,
          }}
        >
          <Text
            c={G ? 'red.3' : K ? 'yellow.4' : pinned ? 'green.1' : 'white'}
            fw={700}
            lts={0.7}
            tt="uppercase"
            size="md"
          >
            {currentAlert?.title || 'Sin avisos'}
          </Text>
        </Group>
        <Group
          gap={6}
          c={G ? 'red.4' : K ? 'yellow.4' : 'green.2'}
          align="center"
          justify="center"
          wrap="nowrap"
          mt={4}
        >
          <FaClock size={13} />
          <Text size="xs" mt={1}>
            {((e) => {
              if (e === 0) {
                return '0s';
              }
              const t = Math.max(0, Math.round((currentTime - e) / 1e3));
              return t < 60 ? t + 's' : t < 3600 ? Math.floor(t / 60) + 'm' : Math.floor(t / 3600) + 'h';
            })(currentAlert?.timeSend || 0)}
          </Text>
        </Group>
      </Group>
      {currentAlert ? (
        <Stack className={styles.content}>
          <Group c="white" gap={8} align="center">
            <FaLocationDot size={15} />
            <Text lts={0.7} size="sm">
              {currentAlert.zone}
            </Text>
            <Text c={G ? 'red.4' : K ? 'yellow.4' : 'green.2'} size="xs">
              [
              {(() =>
                currentAlert
                  ? currentAlert.distance > 999
                    ? `${(currentAlert.distance / 1e3).toFixed(2)}km`
                    : `${currentAlert.distance}m`
                  : '')()}
              ]
            </Text>
          </Group>
          <Group c="white" grow justify="flex-start" align="flex-start" gap={2}>
            <Box maw={20}>
              <FaComment size={14} />
            </Box>
            <Text
              size="sm"
              maw="90%"
              fw="bold"
              style={{
                overflowWrap: 'anywhere',
                wordBreak: 'break-word',
              }}
            >
              {currentAlert.textAlert}
            </Text>
          </Group>
          <Box className={styles.gridDetails}>
            {currentAlert.vehModel && (
              <Group c="white" gap={8} align="center">
                <FaCar size={13} />
                <Text size="xs" lts={0.7}>
                  {currentAlert.vehModel}
                </Text>
              </Group>
            )}
            {currentAlert.plate && (
              <Group c="white" gap={8} align="center">
                <FaCreditCard size={13} />
                <Text size="xs" lts={0.7}>
                  {currentAlert.plate}
                </Text>
              </Group>
            )}
            {currentAlert.vehColor && (
              <Group c="white" gap={8} align="center">
                <FaPalette size={14} />
                <Box
                  className={styles.vehColor}
                  style={{
                    backgroundColor:
                      currentAlert?.vehColor &&
                      `rgb(${currentAlert.vehColor.r}, ${currentAlert.vehColor.g}, ${currentAlert.vehColor.b})`,
                  }}
                />
              </Group>
            )}
            <Group c="white" gap={8} align="center">
              <FaIdBadge size={14} />
              <Text size="xs" lts={0.7}>
                #{currentAlert.idPlayer}
              </Text>
            </Group>
          </Box>
        </Stack>
      ) : (
        <Box h="150">
          <Stack align="center" justify="center" mt={30} c="white">
            <FaClock size={50} />
            <Text>No hay alertas disponibles</Text>
          </Stack>
        </Box>
      )}
      <Box
        className={`${styles.footer} ${G ? styles.footerPanic : K ? styles.footerAssigned : ''}`}
        c={G ? 'red.4' : K ? 'yellow.4' : 'green.1'}
      >
        <FaAngleLeft />
        <Text size="sm" fw="bold">
          {b >= 0 ? b + 1 : 0}/{alerts.length}
        </Text>
        <FaAngleRight />
      </Box>
    </FloatingWindow>
  );
}

export function normalizeChannelName(e) {
  return e
    ? e
        .toLowerCase()
        .replace(/^\d+\s*[-:]\s*/, '')
        .trim()
    : '';
}

export function saveDispatchPosition(e) {
  const t: any = {
    top: e.y,
    left: e.x,
  };
  localStorage.setItem('dispatchPosition', JSON.stringify(t));
}

export function loadDispatchPosition() {
  const e = localStorage.getItem('dispatchPosition');
  return e
    ? JSON.parse(e)
    : {
        top: 200,
        left: 200,
      };
}
