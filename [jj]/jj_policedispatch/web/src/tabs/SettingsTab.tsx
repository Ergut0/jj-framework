import { Box, Group, ScrollArea, SimpleGrid, Slider, Stack, Switch, Text } from '@mantine/core';
import { useEffect, useState } from 'react';
import { FaBell, FaGear, FaUsers, FaVolumeHigh, FaWalkieTalkie } from 'react-icons/fa6';
import { useRadioStore } from '../store/radio';
import { fetchNui, isBrowser, useNuiEvent } from '../utils/nui';
import styles from '../styles/SettingsTab.module.css';

export function SettingsTab() {
  const [radioVolume, setRadioVolume] = useState<any>(50);
  const [pursuitMode, setPursuitMode] = useState<any>(null);
  const { showMembersInHUD, setShowMembersInHUD } = useRadioStore();
  const [alertFilters, setAlertFilters] = useState<any>({
    disparos: true,
    venta_drogas: true,
  });
  const [radioProp, setRadioProp] = useState<any>(true);
  const [selectedAnim, setSelectedAnim] = useState<any>({
    dict: 'random@arrests',
    name: 'generic_radio_enter',
  });
  const [radioAnims, setRadioAnims] = useState<any>([
    {
      dict: 'cellphone@',
      name: 'cellphone_call_listen_base',
      displayName: 'Hablar en oreja',
    },
    {
      dict: 'random@arrests',
      name: 'generic_radio_enter',
      displayName: 'Hablar en hombro',
    },
    {
      dict: 'anim@cop_mic_pose_002',
      name: 'chest_mic',
      displayName: 'Hablar en pecho',
    },
  ]);
  useEffect(() => {
    if (!isBrowser()) {
      (async () => {
        try {
          const response = await fetchNui('getRadioVolume', {});
          if (response != null) {
            setRadioVolume(Number(response.toFixed(0)));
          }
        } catch {
          console.error('No se pudo obtener el volumen de la radio');
        }
      })();
      (async () => {
        try {
          const response = await fetchNui('pursuit:getCurrentMode', {});
          if (response) {
            setPursuitMode(response);
          }
        } catch {
          console.error('No se pudo obtener el modo actual');
        }
      })();
      (async () => {
        try {
          const response = await fetchNui('getRadioAnim', {});
          if (response) {
            if (response.selected && response.selected.dict && response.selected.name) {
              setSelectedAnim(response.selected);
            }
            if (response.animations && Array.isArray(response.animations)) {
              setRadioAnims(response.animations);
            }
          }
        } catch {
          console.error('No se pudo obtener la animación de la radio');
        }
      })();
      (async () => {
        try {
          const response = await fetchNui('getRadioProp', {});
          if (response && typeof response.enabled == 'boolean') {
            setRadioProp(response.enabled);
          }
        } catch {
          console.error('No se pudo obtener el prop de la radio');
        }
      })();
      (async () => {
        try {
          const response = await fetchNui('getAlertFilters', {});
          if (response) {
            setAlertFilters({
              disparos: response.disparos ?? true,
              venta_drogas: response.venta_drogas ?? true,
            });
          }
        } catch {
          console.error('No se pudo obtener el filtro de alertas');
        }
      })();
    }
  }, []);
  useNuiEvent('pursuit:modeChanged', (e) => {
    setPursuitMode(e.mode);
  });
  const handleChange = (e) => {
    setRadioVolume(Number(e.toFixed(0)));
  };
  const handleChangeEnd = (e) => {
    if (!isBrowser()) {
      fetchNui('changeRadioVolume', {
        volume: e,
      });
    }
  };
  const g = (e) => {
    setSelectedAnim(e);
    if (!isBrowser()) {
      fetchNui('changeRadioAnim', e);
    }
  };
  const v = (e) => {
    setRadioProp(e);
    if (!isBrowser()) {
      fetchNui('changeRadioProp', {
        enabled: e,
      });
    }
  };
  const y = (e, t) => {
    setAlertFilters((n) => ({
      ...n,
      [e]: t,
    }));
    if (!isBrowser()) {
      fetchNui('changeAlertFilter', {
        type: e,
        enabled: t,
      });
    }
  };
  return (
    <Box className={styles.container}>
      <Group gap="xs">
        <FaGear size={18} color="var(--mantine-color-green-1)" />
        <Text tt="uppercase" lts={0.7} c="white" fw="bold">
          Configuración
        </Text>
      </Group>
      <Box mt={10} className={styles.radioSection}>
        <ScrollArea className={styles.scrollArea} mt={10} pb={10} scrollbarSize={3} scrollbars="y">
          <Stack gap="xs" pb={8}>
            <Box className={styles.settingsBox}>
              <Stack gap={15} w="100%" mt={5} mb={10}>
                <Group justify="space-between">
                  <Group gap="sm">
                    <FaVolumeHigh color="var(--mantine-color-green-2)" />
                    <Text c="white" fw="bold" size="sm" lts={0.7}>
                      Volumen
                    </Text>
                  </Group>
                  <Text c="dark.1" size="xs" fw="bold">
                    {radioVolume.toFixed(0)}%
                  </Text>
                </Group>
                <Slider
                  value={radioVolume}
                  onChange={handleChange}
                  onChangeEnd={handleChangeEnd}
                  min={0}
                  max={100}
                  color="green.2"
                  size="sm"
                  marks={[
                    {
                      value: 0,
                      label: '0%',
                    },
                    {
                      value: 50,
                      label: '50%',
                    },
                    {
                      value: 100,
                      label: '100%',
                    },
                  ]}
                />
              </Stack>
            </Box>
            <Box className={styles.settingsBox}>
              <Group justify="space-between" w="100%">
                <Group gap="sm">
                  <FaUsers color="var(--mantine-color-green-2)" />
                  <Text c="white" fw="bold" size="sm" lts={0.7}>
                    Miembros en HUD
                  </Text>
                </Group>
                <Switch
                  checked={showMembersInHUD}
                  onChange={(event) => setShowMembersInHUD(event.currentTarget.checked)}
                  color="green.2"
                  className={styles.switchPointer}
                />
              </Group>
            </Box>
            <Box className={styles.animContainer}>
              <Group gap="sm">
                <FaWalkieTalkie color="var(--mantine-color-green-2)" />
                <Text c="white" fw="bold" size="sm" lts={0.7}>
                  Animaciones de radio
                </Text>
              </Group>
              <SimpleGrid cols={3} spacing="xs" w="100%" mt={4}>
                {radioAnims.map((radioAnim) => {
                  const t = selectedAnim.dict === radioAnim.dict && selectedAnim.name === radioAnim.name;
                  return (
                    <Box
                      key={`${radioAnim.dict}-${radioAnim.name}`}
                      className={`${styles.animCard} ${t ? styles.animCardSelected : ''}`}
                      onClick={() =>
                        g({
                          dict: radioAnim.dict,
                          name: radioAnim.name,
                        })
                      }
                    >
                      <FaWalkieTalkie
                        size={16}
                        color={t ? 'var(--mantine-color-green-3)' : 'rgba(255,255,255,0.4)'}
                      />
                      <Text
                        size="11px"
                        fw="bold"
                        ta="center"
                        mt={8}
                        c={t ? 'white' : 'gray.4'}
                        className={styles.animText}
                      >
                        {radioAnim.displayName}
                      </Text>
                    </Box>
                  );
                })}
              </SimpleGrid>
              <Group justify="space-between" w="100%" mt={4}>
                <Text c="gray.4" fw="bold" size="xs" lts={0.7}>
                  Mostrar prop de radio
                </Text>
                <Switch
                  checked={radioProp}
                  onChange={(event) => v(event.currentTarget.checked)}
                  color="green.2"
                  className={styles.switchPointer}
                />
              </Group>
            </Box>
            <Box className={styles.animContainer}>
              <Group gap="sm" mb={4}>
                <FaBell color="var(--mantine-color-green-2)" />
                <Text c="white" fw="bold" size="sm" lts={0.7}>
                  Tipos de Alertas
                </Text>
              </Group>
              <SimpleGrid cols={2} spacing="md" w="100%" mt={4}>
                <Box
                  className={`${styles.classBox} ${alertFilters.disparos ? styles.classBoxSelected : ''}`}
                  onClick={() => y('disparos', !alertFilters.disparos)}
                >
                  <Text c="white" fw="bold" size="sm" lts={0.7}>
                    TIROTEOS
                  </Text>
                </Box>
                <Box
                  className={`${styles.classBox} ${alertFilters.venta_drogas ? styles.classBoxSelected : ''}`}
                  onClick={() => y('venta_drogas', !alertFilters.venta_drogas)}
                >
                  <Text c="white" fw="bold" size="sm" lts={0.7}>
                    DROGAS
                  </Text>
                </Box>
              </SimpleGrid>
            </Box>
          </Stack>
        </ScrollArea>
      </Box>
    </Box>
  );
}
