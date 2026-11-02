import { Box, Button, Group, Modal, Stack, Text } from '@mantine/core';
import { useEffect, useState } from 'react';
import { mockIncidents } from '../../data/mockIncidents';
import { fetchNui, isBrowser } from '../../utils/nui';
import { CitizenListEmpty } from '../citizens/CitizensTab';
import { IncidentDetails } from './IncidentDetails';
import { IncidentList } from './IncidentList';
import styles from '../../styles/Incidents.module.css';

export function IncidentsTab({ initialIncidentId }: any) {
  const [incidents, setIncidents] = useState<any>(isBrowser() ? mockIncidents : []);
  const [selectedIncident, setSelectedIncident] = useState<any>({});
  const [isDirty, setIsDirty] = useState<any>(false);
  const [selectedIncident2, setSelectedIncident2] = useState<any>(null);
  const f = async (v) => {
    if (isBrowser()) {
      setSelectedIncident(v);
      return;
    }
    const response = await fetchNui('fetchIncidentById', {
      id: v.id,
    });
    setSelectedIncident(response);
  };
  const handleSelectIncident = async (v) => {
    if (isDirty) {
      setSelectedIncident2(v);
      return;
    }
    await f(v);
  };
  const handleClick = async () => {
    setIsDirty(false);
    if (selectedIncident2) {
      await f(selectedIncident2);
      setSelectedIncident2(null);
    }
  };
  const handleClose = () => {
    setSelectedIncident2(null);
  };
  useEffect(() => {
    if (isBrowser()) {
      return;
    }
    (async () => {
      const response = await fetchNui('fetchIncidents', {});
      setIncidents(response ?? []);
    })();
  }, []);
  useEffect(() => {
    if (!initialIncidentId) {
      return;
    }
    (async () => {
      const response = await fetchNui('fetchIncidentById', {
        id: initialIncidentId,
      });
      setSelectedIncident(response);
      setIsDirty(false);
    })();
  }, [initialIncidentId]);
  return incidents ? (
    <>
      <Group h="88.3vh" justify="flex-start" align="flex-start" gap={0}>
        <Stack className={styles.searchSection}>
          <IncidentList
            incidents={incidents}
            setIncidents={setIncidents}
            onSelectIncident={handleSelectIncident}
          />
        </Stack>
        <Box flex={1} p="sm">
          <IncidentDetails
            incidents={incidents}
            setIncidents={setIncidents}
            selectedIncident={selectedIncident}
            setSelectedIncident={setSelectedIncident}
            isDirty={isDirty}
            setIsDirty={setIsDirty}
          />
        </Box>
      </Group>
      <Modal
        opened={selectedIncident2 !== null}
        onClose={handleClose}
        title="Cambios sin guardar"
        centered
        size="sm"
      >
        <Text size="sm" mb="md" mt="sm">
          Tienes cambios pendientes sin guardar. ¿Estás seguro de que quieres salir? Los cambios se perderán.
        </Text>
        <Group justify="flex-end">
          <Button variant="default" onClick={handleClose}>
            Cancelar
          </Button>
          <Button color="red" onClick={handleClick}>
            Salir
          </Button>
        </Group>
      </Modal>
    </>
  ) : (
    <CitizenListEmpty />
  );
}
