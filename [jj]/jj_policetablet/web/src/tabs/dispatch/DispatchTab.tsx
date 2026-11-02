import { ActionIcon, Box, Button, Flex, Group, Menu, ScrollArea, Text, Title } from '@mantine/core';
import { useEffect, useRef, useState } from 'react';
import { FaCheck, FaSync, FaTimes, FaTrash, FaUserPlus } from 'react-icons/fa';
import { FaCar, FaLocationDot, FaWalkieTalkie } from 'react-icons/fa6';
import { RiAlarmWarningFill } from 'react-icons/ri';
import { useAlertsStore } from '../../state/alerts';
import { fetchNui, isBrowser, useNuiEvent } from '../../utils/nui';
import { AgentMarker, DepartmentFilter, MapTiles, MapZoomControls } from './MapParts';
import styles from '../../styles/Agents.module.css';

export const GAME_TO_MAP = {
  a: 805879e-10,
  b: -5393e-10,
  c: 0.45841209,
  d: 2812e-10,
  e: -802451e-10,
  f: 0.6745357553,
};

export const TILE_SIZE = 256;

export const mockRadioMessages = [
  {
    id: 1,
    tag: 'RPOL',
    header: '👮 [101 - Patrulla] Sargento John Doe (101)',
    msg: 'Unidad 101 disponible para avisos en zona sur.',
    color: [130, 185, 250],
    time: '14:20',
  },
  {
    id: 2,
    tag: 'RSUR',
    header: '[101 - Patrulla] Sargento John Doe (101)',
    msg: 'Patrullando zona de Legion Square sin novedades.',
    color: [102, 128, 217],
    time: '14:22',
  },
  {
    id: 3,
    tag: 'RNORTE',
    header: '[205 - K9] Oficial II James Smith (205)',
    msg: 'Controles establecidos en Paleto Bay.',
    color: [219, 183, 29],
    time: '14:25',
  },
];

export const mockDispatchAlerts = [
  {
    id: 1,
    title: 'Disparos reportados',
    zone: 'Vinewood Hills',
    textAlert: 'Se han escuchado disparos en la zona de las mansiones.',
    type: 'disparos',
    timeSend: Date.now() - 12e4,
    coords: {
      x: -425.1,
      y: 1200.2,
      z: 30.7,
    },
  },
  {
    id: 2,
    title: 'Robo de Vehículo',
    zone: 'Pillbox Hill',
    textAlert: 'Vehículo sustraído por sujeto sospechoso.',
    type: 'general',
    plate: '88ABC12',
    vehModel: 'Sultan RS',
    timeSend: Date.now() - 3e5,
    coords: {
      x: 215.1,
      y: -800.2,
      z: 30.7,
    },
  },
];

export const mockOnDutyAgents = [
  {
    source: 1,
    badge_number: '101',
    asig: '101 - Patrulla',
    coords: {
      x: 425.1,
      y: -979.2,
      z: 30.7,
    },
    heading: 90,
    is_self: true,
    department: 'lspd',
  },
  {
    source: 2,
    badge_number: '205',
    asig: '205 - K9',
    coords: {
      x: -1082.5,
      y: -2824.1,
      z: 27.7,
    },
    heading: 180,
    department: 'lssd',
  },
  {
    source: 3,
    badge_number: '303',
    asig: '303 - Tránsito',
    coords: {
      x: 1850.5,
      y: 3680.2,
      z: 34,
    },
    heading: 45,
    department: 'lspd',
  },
];

export const mockAgentDetails = {
  1: {
    source: 1,
    citizen: {
      firstname: 'John',
      lastname: 'Doe',
      citizenid: '12345678',
    },
    badge_number: '101',
    rank_id: 4,
    rank_label: 'Sargento',
    department: 'LSPD',
    divisions: ['Patrulla'],
    is_self: true,
  },
  2: {
    source: 2,
    citizen: {
      firstname: 'James',
      lastname: 'Smith',
      citizenid: '87654321',
    },
    badge_number: '205',
    rank_id: 2,
    rank_label: 'Oficial II',
    department: 'LSPD',
    divisions: ['K9'],
  },
  3: {
    source: 3,
    citizen: {
      firstname: 'Alice',
      lastname: 'Vance',
      citizenid: '55443322',
    },
    badge_number: '303',
    rank_id: 1,
    rank_label: 'Oficial I',
    department: 'LSPD',
    divisions: ['Tránsito'],
  },
};

export function DispatchTab({ onRefreshAgentsList }: any) {
  const ref = useRef<any>(null);
  const ref2 = useRef<any>(null);
  const [agents, setAgents] = useState<any>([]);
  const [zoom, setZoom] = useState<any>(3);
  const [offsetX, setOffsetX] = useState<any>(-100);
  const [offsetY, setOffsetY] = useState<any>(-300);
  const [dragging, setDragging] = useState<any>(false);
  const [dimensions, setDimensions] = useState<any>({
    width: 0,
    height: 0,
  });
  const [followedSource, setFollowedSource] = useState<any>(null);
  const [loading, setLoading] = useState<any>(false);
  const [visibleDepartments, setVisibleDepartments] = useState<any>({
    lspd: true,
    lssd: true,
    saed: true,
  });
  const [radioMessages, setRadioMessages] = useState<any>([]);
  const {
    alerts: I,
    hiddenIds: B,
    loaded: U,
    setAlerts: F,
    hideAlert,
    hideAlerts: Z,
    setAssignedUnit: J,
  } = useAlertsStore();
  useEffect(() => {
    if (isBrowser()) {
      setRadioMessages(mockRadioMessages);
      if (!U) {
        F(mockDispatchAlerts);
      }
      return;
    }
    fetchNui('fetchRadioHistory').then((ie) => {
      if (ie && Array.isArray(ie)) {
        setRadioMessages(ie);
      }
    });
  }, []);
  useNuiEvent('newRadioMessage', (ie) => {
    if (ie) {
      const ye: any = {
        ...ie,
        time:
          ie.time ||
          new Date().toLocaleTimeString([], {
            hour: '2-digit',
            minute: '2-digit',
          }),
      };
      setRadioMessages((Ke) => [...Ke, ye]);
    }
  });
  const H = (ie) => {
    hideAlert(ie);
    if (!isBrowser()) {
      fetchNui('deleteAlert', {
        id: ie,
      });
    }
  };
  const W = I.filter((item) => !B.includes(item.id));
  const handleClick = () => {
    const ids = W.map((item) => item.id);
    if (ids.length !== 0) {
      Z(ids);
      if (!isBrowser()) {
        fetchNui('deleteAllAlerts', {
          ids,
        });
      }
    }
  };
  const P = (ie) =>
    ie
      ? ie
          .replace(/^\d+\s*[-:]\s*/, '')
          .trim()
          .split(/\s+-\s+/)[0]
          .trim()
      : '';
  const D = (ie, ye) => {
    const unitName = ye ? P(ye) : undefined;
    const ae = I.find((item) => item.id === ie);
    if (unitName && ae) {
      const De = ae.coords || (typeof ae.distance == 'object' ? ae.distance : undefined);
      if (De) {
        ct(De.x, De.y);
      }
    }
    if (isBrowser()) {
      J(ie, unitName);
      return;
    }
    fetchNui('assignAlertToUnit', {
      alertId: ie,
      unitName,
    });
  };
  const O = () => {
    const ie = agents
      .map((agent) => P(agent.asig))
      .filter((agent) => !!agent && agent.trim() !== '' && !agent.startsWith('Agente #'));
    const ye = Array.from(new Set<any>(ie)).sort();
    return ye.length === 0 && isBrowser() ? ['ADAM-01', 'MANDO-00', 'AIR-01', 'UNION-21'] : ye;
  };
  useEffect(() => {
    if (ref2.current) {
      ref2.current.scrollTop = ref2.current.scrollHeight;
    }
  }, [radioMessages]);
  const L = (ie, ye) => {
    if (ye && Array.isArray(ye)) {
      return `rgb(${ye.join(',')})`;
    }
    switch (ie) {
      case 'RPOL':
        return '#3b82f6';
      case 'RSUR':
        return '#6366f1';
      case 'RNORTE':
        return '#9333ea';
      case 'REMS':
        return '#ef4444';
      default:
        return '#6b7280';
    }
  };
  const N = (ie) => {
    if (!ie) {
      return 'Reciente';
    }
    const ye = Math.max(0, Math.floor((Date.now() - ie) / 6e4));
    return ye < 1 ? 'Ahora' : ye < 60 ? `Hace ${ye}m` : `Hace ${Math.floor(ye / 60)}h`;
  };
  const handleChange = (ie, ye) => {
    setVisibleDepartments((Ke) => {
      const ae: any = {
        ...Ke,
        [ie]: ye,
      };
      if (!ye && followedSource !== null) {
        const De = agents.find((agent) => agent.source === followedSource);
        if (De) {
          const ht = De.department?.toLowerCase() || 'lspd';
          if ((ht === 'lspd' || ht === 'lssd' ? ht : 'saed') === ie) {
            setFollowedSource(null);
          }
        }
      }
      return ae;
    });
  };
  const handleClick2 = async () => {
    setLoading(true);
    if (isBrowser()) {
      setTimeout(() => {
        setAgents(mockOnDutyAgents);
        setLoading(false);
      }, 500);
      return;
    }
    try {
      const ie = [
        fetchNui('fetchOnDutyAgents', {}).then((ye) => {
          if (ye && Array.isArray(ye)) {
            setAgents(ye);
          }
        }),
      ];
      if (onRefreshAgentsList) {
        ie.push(onRefreshAgentsList());
      }
      await Promise.all(ie);
    } catch (error) {
      console.error('Error manual refreshing on duty agents:', error);
    } finally {
      setLoading(false);
    }
  };
  const [visibleTiles, setVisibleTiles] = useState<any>({});
  const [loadedTiles, setLoadedTiles] = useState<any>({});
  const ue = async (ie) => {
    if (!(visibleTiles[ie] || loadedTiles[ie])) {
      if (isBrowser()) {
        const ye = mockAgentDetails[ie];
        if (ye) {
          setVisibleTiles((Ke) => ({
            ...Ke,
            [ie]: ye,
          }));
        }
        return;
      }
      setLoadedTiles((ye) => ({
        ...ye,
        [ie]: true,
      }));
      try {
        const response = await fetchNui('fetchOnDutyAgentDetails', {
          source: ie,
        });
        if (response) {
          setVisibleTiles((Ke) => ({
            ...Ke,
            [ie]: response,
          }));
        }
      } catch (error) {
        console.error('Error fetching agent details:', error);
      } finally {
        setLoadedTiles((ye) => ({
          ...ye,
          [ie]: false,
        }));
      }
    }
  };
  useEffect(() => {
    if (followedSource !== null) {
      ue(followedSource);
    }
  }, [followedSource]);
  const ref3 = useRef<any>(3);
  const ref4 = useRef<any>(-100);
  const ref5 = useRef<any>(-300);
  const ref6 = useRef<any>({
    x: 0,
    y: 0,
  });
  const ref7 = useRef<any>({
    x: 0,
    y: 0,
  });
  const Xe = (ie, ye, Ke) => {
    ref3.current = ie;
    ref4.current = ye;
    ref5.current = Ke;
    setZoom(ie);
    setOffsetX(ye);
    setOffsetY(Ke);
  };
  const ve = (ie, ye, Ke, ae?, De?) => {
    const ht = ae ?? dimensions.width;
    const xt = De ?? dimensions.height;
    if (ht === 0 || xt === 0) {
      return {
        x: ie,
        y: ye,
      };
    }
    const pt = TILE_SIZE * Math.pow(2, Ke);
    let x = ie;
    let y = ye;
    if (pt <= ht) {
      x = Math.round((ht - pt) / 2);
    } else {
      const gn = ht - pt;
      x = Math.max(gn, Math.min(0, ie));
    }
    if (pt <= xt) {
      y = Math.round((xt - pt) / 2);
    } else {
      const gn = xt - pt;
      y = Math.max(gn, Math.min(0, ye));
    }
    return {
      x,
      y,
    };
  };
  useEffect(() => {
    if (!ref.current) {
      return;
    }
    const ie = () => {
      if (ref.current) {
        const Ke = ref.current.getBoundingClientRect();
        setDimensions({
          width: Ke.width,
          height: Ke.height,
        });
        const ae = ref3.current;
        const De = ve(ref4.current, ref5.current, ae, Ke.width, Ke.height);
        Xe(ae, De.x, De.y);
      }
    };
    ie();
    const ye = new ResizeObserver(ie);
    ye.observe(ref.current);
    setTimeout(() => {
      if (ref.current) {
        const Ke = ref.current.getBoundingClientRect();
        const ae = TILE_SIZE * Math.pow(2, 3);
        const De = GAME_TO_MAP.c * ae;
        const ht = GAME_TO_MAP.f * ae;
        const xt = Ke.width / 2 - De;
        const pt = Ke.height / 2 - ht;
        const ft = ve(xt, pt, 3, Ke.width, Ke.height);
        Xe(3, ft.x, ft.y);
      }
    }, 100);
    return () => ye.disconnect();
  }, []);
  useEffect(() => {
    if (isBrowser()) {
      setAgents(mockOnDutyAgents);
      return;
    }
    (async () => {
      try {
        const response = await fetchNui('fetchOnDutyAgents', {});
        if (response && Array.isArray(response)) {
          setAgents(response);
        }
      } catch (error) {
        console.error('Error fetching initial on duty agents:', error);
      }
    })();
  }, []);
  useNuiEvent('updateOnDutyAgents', (ie) => {
    if (ie && Array.isArray(ie)) {
      setAgents(ie);
    }
  });
  useEffect(() => {
    const ie = (ye) => {
      const Ke = ye;
      const ae = agents.find((agent) => agent.badge_number === Ke.detail.badge);
      if (ae && ae.coords) {
        setFollowedSource(ae.source);
        ct(ae.coords.x, ae.coords.y);
      }
    };
    window.addEventListener('centerMapOnAgent', ie);
    return () => window.removeEventListener('centerMapOnAgent', ie);
  }, [agents]);
  const Ae = (ie, ye) => {
    const Ke = TILE_SIZE * Math.pow(2, zoom);
    return {
      x: (GAME_TO_MAP.a * ie + GAME_TO_MAP.b * ye + GAME_TO_MAP.c) * Ke,
      y: (GAME_TO_MAP.d * ie + GAME_TO_MAP.e * ye + GAME_TO_MAP.f) * Ke,
    };
  };
  const handleMouseDown = (event) => {
    if (event.button === 0) {
      setDragging(true);
      ref6.current = {
        x: event.clientX,
        y: event.clientY,
      };
      ref7.current = {
        x: ref4.current,
        y: ref5.current,
      };
    }
  };
  const handleMouseMove = (event) => {
    if (!dragging) {
      return;
    }
    const ye = event.clientX - ref6.current.x;
    const Ke = event.clientY - ref6.current.y;
    const ae = ve(ref7.current.x + ye, ref7.current.y + Ke, ref3.current);
    Xe(ref3.current, ae.x, ae.y);
  };
  const handleMouseUp = () => {
    setDragging(false);
  };
  const handleWheel = (ie) => {
    if (!ref.current) {
      return;
    }
    const ye = dimensions.width;
    const Ke = dimensions.height;
    const ae = ref3.current;
    let De = ae;
    if (ie.deltaY < 0) {
      De = Math.min(6, ae + 1);
    } else {
      De = Math.max(3, ae - 1);
    }
    if (De !== ae) {
      const ht = Math.pow(2, ae);
      const xt = Math.pow(2, De);
      const pt = ye / 2;
      const ft = Ke / 2;
      const Wt = (pt - ref4.current) / ht;
      const gn = (ft - ref5.current) / ht;
      const re = pt - Wt * xt;
      const Q = ft - gn * xt;
      const xe = ve(re, Q, De);
      Xe(De, xe.x, xe.y);
    }
  };
  const Tt = (ie) => {
    if (!ref.current) {
      return;
    }
    const ye = dimensions.width;
    const Ke = dimensions.height;
    const ae = ref3.current;
    const De = ie ? Math.min(6, ae + 1) : Math.max(3, ae - 1);
    if (De !== ae) {
      const ht = Math.pow(2, ae);
      const xt = Math.pow(2, De);
      const pt = ye / 2;
      const ft = Ke / 2;
      const Wt = (pt - ref4.current) / ht;
      const gn = (ft - ref5.current) / ht;
      const re = pt - Wt * xt;
      const Q = ft - gn * xt;
      const xe = ve(re, Q, De);
      Xe(De, xe.x, xe.y);
    }
  };
  const ct = (ie, ye) => {
    if (!ref.current) {
      return;
    }
    const Ke = TILE_SIZE * Math.pow(2, ref3.current);
    const ae = (GAME_TO_MAP.a * ie + GAME_TO_MAP.b * ye + GAME_TO_MAP.c) * Ke;
    const De = (GAME_TO_MAP.d * ie + GAME_TO_MAP.e * ye + GAME_TO_MAP.f) * Ke;
    const ht = ve(dimensions.width / 2 - ae, dimensions.height / 2 - De, ref3.current);
    Xe(ref3.current, ht.x, ht.y);
  };
  const handleWaypoint = async (ie) => {
    if (isBrowser()) {
      console.log('Setting browser waypoint to:', ie.coords);
      return;
    }
    await fetchNui('setMapWaypoint', {
      coords: ie.coords,
    });
  };
  return (
    <Box flex={1} className={styles.mapWrapper}>
      <Box className={styles.headerSection}>
        <Group align="center" justify="space-between" w="100%">
          <Box
            style={{
              width: 34,
            }}
          />
          <Title order={4} tt="uppercase" lts={0.7} ta="center">
            Mapa de Agentes
          </Title>
          <ActionIcon
            size="lg"
            variant="subtle"
            color="blue"
            loading={loading}
            onClick={handleClick2}
            title="Refrescar agentes"
          >
            <FaSync />
          </ActionIcon>
        </Group>
      </Box>
      <Flex
        pos="relative"
        className={styles.mapCanvasContainer}
        ref={ref}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
        onWheel={handleWheel}
      >
        <MapTiles
          offsetX={offsetX}
          offsetY={offsetY}
          zoom={zoom}
          dimensions={dimensions}
          tileSize={TILE_SIZE}
        />
        <div
          style={{
            position: 'absolute',
            width: '100%',
            height: '100%',
            pointerEvents: 'none',
          }}
        >
          {agents
            .filter((agent) => {
              if (!agent.coords) {
                return false;
              }
              const ye = agent.department?.toLowerCase() || 'lspd';
              return ye === 'lspd'
                ? visibleDepartments.lspd
                : ye === 'lssd'
                  ? visibleDepartments.lssd
                  : visibleDepartments.saed;
            })
            .map((agent) => (
              <AgentMarker
                key={agent.source}
                agent={agent}
                pixel={Ae(agent.coords.x, agent.coords.y)}
                offsetX={offsetX}
                offsetY={offsetY}
                isSelected={followedSource === agent.source}
                onSelect={() => setFollowedSource(agent.source)}
                onDeselect={() => setFollowedSource(null)}
                loadingDetails={!!loadedTiles[agent.source]}
                details={visibleTiles[agent.source]}
                onWaypoint={handleWaypoint}
              />
            ))}
        </div>
        <DepartmentFilter visibleDepartments={visibleDepartments} onChange={handleChange} />
        <MapZoomControls onZoomIn={() => Tt(true)} onZoomOut={() => Tt(false)} onCenter={() => ct(0, 0)} />
        <style>
          {
            '\n          @keyframes pulse-blue {\n            0% {\n              transform: scale(0.95);\n              box-shadow: 0 0 0 0 rgba(34, 139, 230, 0.5);\n            }\n            70% {\n              transform: scale(1);\n              box-shadow: 0 0 0 10px rgba(34, 139, 230, 0);\n            }\n            100% {\n              transform: scale(0.95);\n              box-shadow: 0 0 0 0 rgba(34, 139, 230, 0);\n            }\n          }\n          @keyframes pulse-gold {\n            0% {\n              transform: scale(0.95);\n              box-shadow: 0 0 0 0 rgba(168,85,247, 0.5);\n            }\n            70% {\n              transform: scale(1);\n              box-shadow: 0 0 0 10px rgba(168,85,247, 0);\n            }\n            100% {\n              transform: scale(0.95);\n              box-shadow: 0 0 0 0 rgba(168,85,247, 0);\n            }\n          }\n          @keyframes pulse-red {\n            0% {\n              transform: scale(0.95);\n              box-shadow: 0 0 0 0 rgba(224, 49, 49, 0.5);\n            }\n            70% {\n              transform: scale(1);\n              box-shadow: 0 0 0 10px rgba(224, 49, 49, 0);\n            }\n            100% {\n              transform: scale(0.95);\n              box-shadow: 0 0 0 0 rgba(224, 49, 49, 0);\n            }\n          }\n          @keyframes pulse-orange {\n            0% {\n              transform: scale(0.95);\n              box-shadow: 0 0 0 0 rgba(253, 126, 20, 0.5);\n            }\n            70% {\n              transform: scale(1);\n              box-shadow: 0 0 0 10px rgba(253, 126, 20, 0);\n            }\n            100% {\n              transform: scale(0.95);\n              box-shadow: 0 0 0 0 rgba(253, 126, 20, 0);\n            }\n          }\n        '
          }
        </style>
      </Flex>
      <Box className={styles.bottomSection}>
        <Box className={styles.bottomBox}>
          <Box className={styles.boxHeader}>
            <Box className={styles.boxHeaderTitle}>
              <FaWalkieTalkie size={14} color="var(--text-primary)" />
              RADIO INTERNA
            </Box>
            <Text size="xs" c="dimmed" fw={600}>
              {radioMessages.length}
              {' MENSAJES'}
            </Text>
          </Box>
          <Box className={styles.boxContent} ref={ref2}>
            {radioMessages.length === 0 ? (
              <Box className={styles.emptyBoxText}>
                <FaWalkieTalkie
                  size={32}
                  color="var(--text-secondary)"
                  style={{
                    opacity: 0.4,
                  }}
                />
                <Text size="sm" c="dimmed" fw={500}>
                  Sin transmisiones por radio
                </Text>
              </Box>
            ) : (
              radioMessages.map((radioMessage, index) => (
                <Box key={radioMessage.id || index} className={styles.radioItem}>
                  <Box className={styles.radioHeader}>
                    <Box
                      className={styles.radioTagBadge}
                      style={{
                        backgroundColor: L(radioMessage.tag, radioMessage.color),
                      }}
                    >
                      {radioMessage.tag}
                    </Box>
                    <Text className={styles.radioTitle} title={radioMessage.header}>
                      {radioMessage.header}
                    </Text>
                    <Text className={styles.radioTime}>{radioMessage.time}</Text>
                  </Box>
                  <Text className={styles.radioMsg}>{radioMessage.msg}</Text>
                </Box>
              ))
            )}
          </Box>
        </Box>
        <Box className={styles.bottomBox}>
          <Box className={styles.boxHeader}>
            <Box className={styles.boxHeaderTitle}>
              <RiAlarmWarningFill size={16} color="var(--text-primary)" />
              AVISOS DE DISPATCH
            </Box>
            <Group gap={8} wrap="nowrap">
              <Text size="xs" c="dimmed" fw={600}>
                {W.length}
                {' AVISOS'}
              </Text>
              <Button
                size="compact-xs"
                variant="light"
                color="red"
                leftSection={<FaTrash size={10} />}
                disabled={W.length === 0}
                onClick={handleClick}
                title="Borrar todos los avisos"
              >
                Borrar todo
              </Button>
            </Group>
          </Box>
          <Box className={styles.boxContent}>
            {W.length === 0 ? (
              <Box className={styles.emptyBoxText}>
                <RiAlarmWarningFill
                  size={36}
                  color="var(--text-secondary)"
                  style={{
                    opacity: 0.4,
                  }}
                />
                <Text size="sm" c="dimmed" fw={500}>
                  No hay avisos de dispatch
                </Text>
              </Box>
            ) : (
              W.map((item, index) => {
                const Ke =
                  item.textAlert && (item.textAlert.includes('[444]') || item.textAlert.includes('[QRR]'));
                const coords = item.coords || (typeof item.distance == 'object' ? item.distance : undefined);
                const De = !!item.assignedUnit;
                return (
                  <Box
                    key={item.id || index}
                    className={`${styles.dispatchItem} ${Ke ? styles.dispatchItemPanic : ''} ${De ? styles.dispatchItemAssigned : ''}`}
                  >
                    <Box className={styles.dispatchHeader}>
                      <Group gap={6} align="center">
                        <Text className={styles.dispatchTitle}>{item.title || 'Aviso de Dispatch'}</Text>
                        {De && (
                          <Box className={styles.unitBadge}>
                            {'UNIDAD: '}
                            {P(item.assignedUnit)}
                          </Box>
                        )}
                      </Group>
                      <Text className={styles.radioTime}>{N(item.timeSend)}</Text>
                    </Box>
                    <Text className={styles.dispatchText}>{item.textAlert}</Text>
                    <Box className={styles.dispatchMeta}>
                      {item.zone && (
                        <Box className={styles.dispatchZone}>
                          <FaLocationDot size={11} />
                          {item.zone}
                        </Box>
                      )}
                      {item.vehModel && (
                        <Box
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 4,
                          }}
                        >
                          <FaCar size={11} />
                          {item.vehModel} {item.plate ? `[${item.plate}]` : ''}
                        </Box>
                      )}
                      <Group
                        gap={4}
                        style={{
                          marginLeft: 'auto',
                          flexShrink: 0,
                        }}
                      >
                        <Menu shadow="md" width={200} position="bottom-end">
                          <Menu.Target>
                            <Button
                              size="compact-xs"
                              variant={De ? 'filled' : 'light'}
                              color={De ? 'orange' : 'blue'}
                              leftSection={<FaUserPlus size={10} />}
                              title="Asignar aviso a unidad"
                            >
                              {De ? 'Cambiar Unidad' : 'Asignar'}
                            </Button>
                          </Menu.Target>
                          <Menu.Dropdown
                            style={{
                              backgroundColor: 'var(--primary-color)',
                              borderColor: 'var(--border-color)',
                            }}
                          >
                            <Menu.Label c="dimmed">Seleccionar Unidad</Menu.Label>
                            {De && (
                              <Menu.Item
                                color="red"
                                leftSection={<FaTimes size={11} />}
                                onClick={() => D(item.id, undefined)}
                              >
                                Desasignar Unidad
                              </Menu.Item>
                            )}
                            <Menu.Divider />
                            {O().length === 0 ? (
                              <Menu.Label c="dimmed">No hay unidades activas</Menu.Label>
                            ) : (
                              <ScrollArea.Autosize mah={180}>
                                {O().map((item2) => (
                                  <Menu.Item
                                    key={item2}
                                    onClick={() => D(item.id, item2)}
                                    rightSection={
                                      item.assignedUnit === item2 ? (
                                        <FaCheck size={10} color="#a855f7" />
                                      ) : null
                                    }
                                    style={{
                                      color: item.assignedUnit === item2 ? '#c084fc' : 'var(--text-primary)',
                                    }}
                                  >
                                    {item2}
                                  </Menu.Item>
                                ))}
                              </ScrollArea.Autosize>
                            )}
                          </Menu.Dropdown>
                        </Menu>
                        {coords && (
                          <ActionIcon
                            size="xs"
                            variant="light"
                            color="blue"
                            onClick={() => {
                              if (coords) {
                                ct(coords.x, coords.y);
                                if (!isBrowser()) {
                                  fetchNui('setMapWaypoint', {
                                    coords,
                                  });
                                }
                              }
                            }}
                            title="Marcar GPS y centrar mapa"
                          >
                            <FaLocationDot size={10} />
                          </ActionIcon>
                        )}
                        <ActionIcon
                          size="xs"
                          variant="light"
                          color="red"
                          onClick={() => H(item.id)}
                          title="Borrar alerta"
                        >
                          <FaTrash size={10} />
                        </ActionIcon>
                      </Group>
                    </Box>
                  </Box>
                );
              })
            )}
          </Box>
        </Box>
      </Box>
    </Box>
  );
}
