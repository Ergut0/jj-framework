import { Box, Button, CloseButton, Group, Image, Stack, Text } from '@mantine/core';
import { Component, useEffect, useState } from 'react';
import { FaLock, FaPlus, FaPowerOff, FaUsers as FaUsers2 } from 'react-icons/fa';
import { FaCar, FaMoneyBillWave, FaScaleBalanced, FaWalkieTalkie } from 'react-icons/fa6';
import { TiHome, TiWarning } from 'react-icons/ti';
import { useRecoilState, useSetRecoilState } from 'recoil';
import { IconG5, IconOse, Iconm } from './icons';
import { useAlertsStore } from './state/alerts';
import {
  agentAtom,
  chapterListAtom,
  penalCodeListAtom,
  ranksAgentsAtom,
  usePermissions,
} from './state/atoms';
import { AgentsTab } from './tabs/agents/AgentsTab';
import { CitizensTab } from './tabs/citizens/CitizensTab';
import { DebtorsTab } from './tabs/debtors/DebtorsTab';
import { FederalTab } from './tabs/federal/FederalTab';
import { HomeTab } from './tabs/home/HomeTab';
import { IncidentsTab } from './tabs/incidents/IncidentsTab';
import { PenalCodeTab } from './tabs/penalcode/PenalCodeTab';
import { RadioTab } from './tabs/radio/RadioTab';
import { ReportsTab } from './tabs/reports/ReportsTab';
import { SettingsTab } from './tabs/settings/SettingsTab';
import { VehiclesTab } from './tabs/vehicles/VehiclesTab';
import { OPEN_ENTITY_TAB_EVENT, fetchNui, isBrowser, useNuiEvent } from './utils/nui';
import styles from './styles/Layout.module.css';

export function useDispatchAlerts() {
  const { setAlerts, addAlert, setAssignedUnit, loaded } = useAlertsStore();
  useEffect(() => {
    if (!(isBrowser() || loaded)) {
      fetchNui('fetchDispatchAlerts').then((o) => {
        if (o && Array.isArray(o)) {
          setAlerts(o);
        }
      });
    }
  }, [loaded]);
  useNuiEvent('newDispatchAlert', (o) => {
    if (o) {
      addAlert(o);
    }
  });
  useNuiEvent('alertUnitAssigned', (o) => {
    if (o && o.alertId) {
      setAssignedUnit(o.alertId, o.assignedUnit);
    }
  });
}

export class ErrorBoundary extends Component<any, any> {
  constructor(t) {
    super(t);
    this.state = {
      hasError: false,
    };
  }
  static getDerivedStateFromError() {
    return {
      hasError: true,
    };
  }
  componentDidCatch(t, n) {
    console.error(`Error en la pestaña "${this.props.label ?? 'desconocida'}":`, t, n);
  }
  componentDidUpdate(t) {
    if (this.state.hasError && t.children !== this.props.children) {
      this.setState({
        hasError: false,
      });
    }
  }
  handleReset = () => {
    this.setState({
      hasError: false,
    });
  };
  render() {
    return this.state.hasError ? (
      <Group h="88.3vh" justify="center" align="center">
        <Stack align="center" gap="xs">
          <TiWarning size={40} color="var(--mantine-color-yellow-5, #9775fa)" />
          <Text c="dimmed" size="lg" ta="center">
            Ocurrió un error al mostrar esta sección.
          </Text>
          {this.props.label && (
            <Text c="dimmed" size="sm" ta="center">
              ({this.props.label})
            </Text>
          )}
          <Box mt="xs">
            <Button size="sm" variant="light" onClick={this.handleReset}>
              Reintentar
            </Button>
          </Box>
        </Stack>
      </Group>
    ) : (
      this.props.children
    );
  }
}

export function App() {
  const { haveRankPerms } = usePermissions();
  useDispatchAlerts();
  const t = [
    {
      label: 'Inicio',
      component: HomeTab,
      icon: <TiHome size={21} />,
    },
    {
      label: 'Ciudadanos',
      component: CitizensTab,
      icon: <FaUsers2 size={21} />,
      permissionKey: 'citizens.access',
    },
    {
      label: 'Vehículos',
      component: VehiclesTab,
      icon: <FaCar size={21} />,
    },
    {
      label: 'Informes',
      component: IncidentsTab,
      icon: <TiWarning size={21} />,
      permissionKey: 'incidents.access',
    },
    {
      label: 'Código penal',
      component: PenalCodeTab,
      icon: <FaScaleBalanced size={21} />,
      permissionKey: 'penalcode.access',
    },
    {
      label: 'Deudores',
      component: DebtorsTab,
      icon: <FaMoneyBillWave size={21} />,
      permissionKey: 'debtors.access',
    },
    {
      label: 'Federal',
      component: FederalTab,
      icon: <FaLock size={21} />,
      permissionKey: 'federal.access',
    },
    {
      label: 'Incidentes',
      component: ReportsTab,
      icon: <IconG5 size={21} />,
      permissionKey: 'reports.access',
    },
    {
      label: 'Agentes',
      component: AgentsTab,
      icon: <Iconm size={21} />,
    },
    {
      label: 'Dispatch',
      component: RadioTab,
      icon: <FaWalkieTalkie size={21} />,
    },
    {
      label: 'Ajustes',
      component: SettingsTab,
      icon: <IconOse size={21} />,
    },
  ];
  const [tabs, setTabs] = useState<any>([
    {
      id: 'home-1',
      label: 'Inicio',
      component: <HomeTab />,
    },
  ]);
  const [activeTabId, setActiveTabId] = useState<any>('home-1');
  const handleClick = () => {
    const R = `home-${Date.now()}`;
    const I: any = {
      id: R,
      label: 'Inicio',
      component: <HomeTab />,
    };
    setTabs([...tabs, I]);
    setActiveTabId(R);
  };
  const a = (R) => {
    const I = t[R];
    if (!I) {
      return;
    }
    const B = I.component;
    const U = tabs.map((tab) =>
      tab.id === activeTabId
        ? {
            ...tab,
            label: I.label,
            component: <B />,
            permissionKey: I.permissionKey,
          }
        : tab,
    );
    setTabs(U);
  };
  const u = (R) => {
    const I = tabs.filter((tab) => tab.id !== R);
    if (I.length === 0) {
      setTabs([
        {
          id: 'home-1',
          label: 'Inicio',
          component: <HomeTab />,
        },
      ]);
      setActiveTabId('home-1');
    } else {
      setTabs(I);
      if (activeTabId === R) {
        setActiveTabId(I[I.length - 1].id);
      }
    }
  };
  const f = (R) =>
    R.type === 'citizen'
      ? {
          id: `citizen-${R.citizenId}`,
          label: 'Ciudadanos',
          component: <CitizensTab initialCitizenId={R.citizenId} />,
          permissionKey: 'citizens.access',
        }
      : R.type === 'incident'
        ? {
            id: `incident-${R.incidentId}`,
            label: 'Incidentes',
            component: <IncidentsTab initialIncidentId={R.incidentId} />,
          }
        : R.type === 'vehicle'
          ? {
              id: `vehicle-${R.plate}`,
              label: 'Vehículos',
              component: <VehiclesTab initialVehiclePlate={R.plate} />,
            }
          : {
              id: `home-${Date.now()}`,
              label: 'Inicio',
              component: <HomeTab />,
            };
  const h = (R) => {
    const I = f(R);
    setTabs((B) => (B.some((item) => item.id === I.id) ? B : [...B, I]));
    setActiveTabId(I.id);
  };
  const [dataLoaded, setDataLoaded] = useState<any>(!!isBrowser());
  const [onDuty, setOnDuty] = useState<any>(!!isBrowser());
  const b = useSetRecoilState<any>(penalCodeListAtom);
  const S = useSetRecoilState<any>(chapterListAtom);
  useNuiEvent('openTablet', () => {
    // Cada consulta va por separado: si una no responde, la tablet no se queda vacía
    fetchNui('getPlayerData').then((I) => {
      setOnDuty(I?.onDuty === true);
      j(I ?? false);
    });
    fetchNui('getRanksSettings').then((B) => {
      T(Array.isArray(B) ? B : []);
    });
    fetchNui('getPenalCodes').then((U) => {
      let F = [];
      let q = [];
      if (U && typeof U == 'object' && 'penalCodes' in U) {
        F = U.penalCodes || [];
        q = U.chapters || [];
      } else {
        if (Array.isArray(U)) {
          F = U;
        }
      }
      const Z = F.sort((J, H) => {
        const W = parseFloat(J.id_article);
        const $ = parseFloat(H.id_article);
        return W - $;
      });
      b(Array.isArray(Z) ? Z : []);
      if (q.length > 0) {
        S(q);
      }
    });
    setDataLoaded(true);
  });
  useNuiEvent('closeTablet', () => {
    setDataLoaded(false);
  });
  useEffect(() => {
    const R = (event) => {
      if (event.key === 'Escape') {
        setDataLoaded(false);
        fetchNui('closeTablet', {});
      }
    };
    const I = (B) => {
      const F = B.detail;
      if (F) {
        h(F);
      }
    };
    window.addEventListener('keydown', R);
    window.addEventListener(OPEN_ENTITY_TAB_EVENT, I);
    return () => {
      window.removeEventListener('keydown', R);
      window.removeEventListener(OPEN_ENTITY_TAB_EVENT, I);
    };
  }, []);
  const [w, j] = useRecoilState<any>(agentAtom);
  const T = useSetRecoilState<any>(ranksAgentsAtom);
  const handleClick2 = async () => {
    const response = await fetchNui('toggleDutyStatus', {});
    if (response?.success) {
      setOnDuty(response.onDuty === true);
    }
  };
  const A = tabs.find((tab) => tab.id === activeTabId)?.label ?? 'esta sección';
  return (
    <>
      <Box className={`${styles.container} ${dataLoaded ? styles.tabletOpen : styles.tabletClosed}`}>
        <Box className={styles.leftPanel}>
          <Box className={styles.imageContainer}>
            <Image src="LSPD.png" alt="Logo" className={styles.image} />
          </Box>
          <Box className={styles.navContainer}>
            {t.map((item, index) => (
              <Button
                key={index}
                className={styles.navButton}
                leftSection={item.icon ? item.icon : null}
                onClick={() => a(index)}
              >
                {item.label}
              </Button>
            ))}
          </Box>
        </Box>
        <Box className={styles.topPanel}>
          <Group gap="xs" className={styles.topButtonGroup}>
            {tabs.map((tab) => (
              <Button
                key={tab.id}
                size="md"
                variant="default"
                className={
                  tab.id === activeTabId
                    ? `${styles.topTabButton} ${styles.topTapButtonActive}`
                    : styles.topTabButton
                }
                rightSection={
                  tabs.length > 1 ? (
                    <CloseButton
                      size="sm"
                      variant="transparent"
                      className={styles.closeButton}
                      onClick={(event) => {
                        event.stopPropagation();
                        u(tab.id);
                      }}
                    />
                  ) : null
                }
                onClick={() => setActiveTabId(tab.id)}
              >
                {tab.label}
              </Button>
            ))}
            {tabs.length < 8 && (
              <Button onClick={handleClick} size="compact-sm" variant="default" className={styles.addButton}>
                <FaPlus size={10} />
              </Button>
            )}
            <Button
              className={styles.dutyButton}
              color={onDuty ? 'red' : 'green'}
              radius="sm"
              mx="auto"
              tt="uppercase"
              lts={0.2}
              fw="bold"
              size="sm"
              variant="light"
              leftSection={<FaPowerOff size={20} />}
              onClick={handleClick2}
            >
              {onDuty ? 'Salir de servicio' : 'Entrar de servicio'}
            </Button>
          </Group>
        </Box>
        {w && (
          <Box className={styles.rightPanel}>
            {onDuty ? (
              tabs.map((tab) => {
                const I = !tab.permissionKey || haveRankPerms([tab.permissionKey]);
                return (
                  <Box
                    key={tab.id}
                    style={{
                      display: tab.id === activeTabId ? 'block' : 'none',
                    }}
                  >
                    {I ? (
                      <ErrorBoundary label={tab.label}>{tab.component}</ErrorBoundary>
                    ) : (
                      <Group h="88.3vh" justify="center" align="center">
                        <Text c="dimmed" size="lg">
                          No tienes permisos para acceder a esta sección.
                        </Text>
                      </Group>
                    )}
                  </Box>
                );
              })
            ) : (
              <Box className={styles.offDutyState}>
                {'DEBES ENTRAR DE SERVICIO PARA PODER VER '}
                {A}
              </Box>
            )}
          </Box>
        )}
        {w === false && (
          <Box className={styles.rightPanel}>
            <Box className={styles.offDutyState}>NO SE HAN PODIDO CARGAR TUS DATOS DE AGENTE</Box>
          </Box>
        )}
      </Box>
    </>
  );
}
