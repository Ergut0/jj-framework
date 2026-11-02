import { Box, FloatingWindow, Group, Stack, Text } from '@mantine/core';
import { useEffect, useRef, useState } from 'react';
import { useLockStore } from '../store/lock';
import { isBrowser, useNuiEvent } from '../utils/nui';
import styles from '../styles/Radar.module.css';

export function Radar() {
  const { unlocked } = useLockStore();
  const [locked, setLocked] = useState<any>(false);
  const [isLargeScreen, setIsLargeScreen] = useState<any>(window.innerWidth >= 1921);
  const o = isBrowser()
    ? {
        speed: 0,
        plate: 'MKQ694',
        model: 'MASSACRO',
        classLabel: 'A',
      }
    : null;
  const [frontVehicle, setFrontVehicle] = useState<any>(o);
  const l = isBrowser()
    ? {
        speed: 0,
        plate: 'LSC452',
        model: 'ZENTORNO',
        classLabel: 'S',
      }
    : null;
  const [rearVehicle, setRearVehicle] = useState<any>(l);
  const setPositionRef = useRef<any>(null);
  useEffect(() => {
    const e = localStorage.getItem('radarPosition');
    if (e && setPositionRef.current) {
      const t = JSON.parse(e);
      setPositionRef.current(t);
    }
  }, []);
  useEffect(() => {
    const e = () => {
      setIsLargeScreen(window.innerWidth >= 1921);
    };
    e();
    window.addEventListener('resize', e);
    return () => window.removeEventListener('resize', e);
  }, []);
  useNuiEvent('updateRadarData', (e) => {
    if (!locked) {
      if (e.front) {
        setFrontVehicle(e.front);
      }
      if (e.rear) {
        setRearVehicle(e.rear);
      }
    }
  });
  useNuiEvent('setRadarLock', (e) => {
    setLocked(e.locked);
  });
  const S = splitSpeed;
  return (
    <FloatingWindow
      className={`${styles.container} ${isLargeScreen ? styles.container2K : ''} ${locked ? styles.lockedGlow : ''}`}
      enabled={unlocked}
      onPositionChange={saveRadarPosition}
      initialPosition={loadRadarPosition()}
      setPositionRef={setPositionRef}
    >
      <Group className={styles.panelsGroup} gap={0} wrap="nowrap">
        <Stack className={styles.panel} gap={10}>
          <Stack gap={2} align="center">
            <Text className={`${styles.panelHeader} ${locked ? styles.panelHeaderLocked : ''}`}>FRONTAL</Text>
            <Box className={`${styles.headerDivider} ${locked ? styles.headerDividerLocked : ''}`} />
          </Stack>
          <Group justify="center" align="flex-end" gap={6} className={styles.speedWrapper}>
            <Text className={styles.speedDigits}>
              <span className={styles.leadingDigits}>{S(frontVehicle?.speed).leading}</span>
              <span>{S(frontVehicle?.speed).active}</span>
            </Text>
            <Text className={`${styles.speedUnit} ${locked ? styles.speedUnitLocked : ''}`}>KM/H</Text>
          </Group>
          <Group justify="space-between" align="center" px={10} wrap="nowrap">
            <Stack gap={2} align="center">
              <Text className={styles.gridLabel}>MATRÍCULA</Text>
              <Text className={`${styles.gridValue} ${frontVehicle?.isCod9 ? styles.cod9Plate : ''}`}>
                {frontVehicle?.isCod9 ? '[COD-9] ' + frontVehicle?.plate : frontVehicle?.plate || '---'}
              </Text>
            </Stack>
            <Stack gap={2} align="center">
              <Text className={styles.gridLabel}>MODELO</Text>
              <Text className={styles.gridValue}>{frontVehicle?.model || '---'}</Text>
            </Stack>
          </Group>
        </Stack>
        <Box className={styles.verticalDivider} />
        <Stack className={styles.panel} gap={10}>
          <Stack gap={2} align="center">
            <Text className={`${styles.panelHeader} ${locked ? styles.panelHeaderLocked : ''}`}>TRASERO</Text>
            <Box className={`${styles.headerDivider} ${locked ? styles.headerDividerLocked : ''}`} />
          </Stack>
          <Group justify="center" align="flex-end" gap={6} className={styles.speedWrapper}>
            <Text className={styles.speedDigits}>
              <span className={styles.leadingDigits}>{S(rearVehicle?.speed).leading}</span>
              <span>{S(rearVehicle?.speed).active}</span>
            </Text>
            <Text className={`${styles.speedUnit} ${locked ? styles.speedUnitLocked : ''}`}>KM/H</Text>
          </Group>
          <Group justify="space-between" align="center" px={10} wrap="nowrap">
            <Stack gap={2} align="center">
              <Text className={styles.gridLabel}>MATRÍCULA</Text>
              <Text className={`${styles.gridValue} ${rearVehicle?.isCod9 ? styles.cod9Plate : ''}`}>
                {rearVehicle?.isCod9 ? '[COD-9] ' + rearVehicle?.plate : rearVehicle?.plate || '---'}
              </Text>
            </Stack>
            <Stack gap={2} align="center">
              <Text className={styles.gridLabel}>MODELO</Text>
              <Text className={styles.gridValue}>{rearVehicle?.model || '---'}</Text>
            </Stack>
          </Group>
        </Stack>
      </Group>
    </FloatingWindow>
  );
}

export function splitSpeed(e) {
  if (e == null) {
    return {
      leading: '00',
      active: '0',
    };
  }
  const t = Math.floor(e);
  const n = t.toString().padStart(3, '0');
  let r = 3;
  for (let e = 0; e < n.length; e++) {
    if (n[e] !== '0') {
      r = e;
      break;
    }
  }
  if (t === 0) {
    r = 2;
  }
  return {
    leading: n.slice(0, r),
    active: n.slice(r),
  };
}

export function saveRadarPosition(e) {
  const t: any = {
    top: e.y,
    left: e.x,
  };
  localStorage.setItem('radarPosition', JSON.stringify(t));
}

export function loadRadarPosition() {
  const e = localStorage.getItem('radarPosition');
  return e
    ? JSON.parse(e)
    : {
        top: 350,
        left: 200,
      };
}
