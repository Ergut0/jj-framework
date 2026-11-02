import { Box, Button, Group, Modal, Stack, Text } from '@mantine/core';
import { useEffect, useState } from 'react';
import { useRecoilValue } from 'recoil';
import { agentAtom, usePermissions } from '../../state/atoms';
import { fetchNui, isBrowser } from '../../utils/nui';
import { CitizenListEmpty } from '../citizens/CitizensTab';
import { ReportDetails } from './ReportDetails';
import { ReportList } from './ReportList';
import styles from '../../styles/Reports.module.css';

export function ReportsTab() {
  const { haveRankPerms } = usePermissions();
  const [reports, setReports] = useState<any>([]);
  const [selectedReport, setSelectedReport] = useState<any>({});
  const [isDirty, setIsDirty] = useState<any>(false);
  const [selectedReport2, setSelectedReport2] = useState<any>(null);
  const f = useRecoilValue<any>(agentAtom);
  const h = f?.department?.toLowerCase() === 'lssd' || f?.department?.toLowerCase() === 'sheriff';
  const p = !h && haveRankPerms(['reports.access.ia']);
  const g = !h && haveRankPerms(['reports.access.detectives']);
  const v = !h && haveRankPerms(['reports.access.sargentos']);
  const y = h && haveRankPerms(['reports.access.ia']);
  const b = h && haveRankPerms(['reports.access.detectives']);
  const S = h && haveRankPerms(['reports.access.sargentos']);
  const w = p || g || v || y || b || S;
  const j = async (R) => {
    if (isBrowser()) {
      setSelectedReport(R);
      return;
    }
    const response = await fetchNui('fetchReportById', {
      id: R.id,
    });
    setSelectedReport(response);
  };
  const handleSelectReport = async (R) => {
    const I = R.division;
    if (
      !(I === 'ia' && !p) &&
      !(I === 'detectives' && !g) &&
      !(I === 'sargentos' && !v) &&
      !(I === 'ia_lssd' && !y) &&
      !(I === 'detectives_lssd' && !b) &&
      !(I === 'sargentos_lssd' && !S)
    ) {
      if (isDirty) {
        setSelectedReport2(R);
        return;
      }
      await j(R);
    }
  };
  const handleClick = async () => {
    setIsDirty(false);
    if (selectedReport2) {
      await j(selectedReport2);
      setSelectedReport2(null);
    }
  };
  const handleClose = () => {
    setSelectedReport2(null);
  };
  useEffect(() => {
    if (isBrowser()) {
      return;
    }
    (async () => {
      const response = await fetchNui('fetchReports', {});
      setReports(response ?? []);
    })();
  }, []);
  return reports ? (
    w ? (
      <>
        <Group h="88.3vh" justify="flex-start" align="flex-start" gap={0}>
          <Stack className={styles.searchSection}>
            <ReportList reports={reports} setReports={setReports} onSelectReport={handleSelectReport} />
          </Stack>
          <Box flex={1} p="sm">
            <ReportDetails
              reports={reports}
              setReports={setReports}
              selectedReport={selectedReport}
              setSelectedReport={setSelectedReport}
              isDirty={isDirty}
              setIsDirty={setIsDirty}
            />
          </Box>
        </Group>
        <Modal
          opened={selectedReport2 !== null}
          onClose={handleClose}
          title="Cambios sin guardar"
          centered
          size="sm"
        >
          <Text size="sm" mb="md" mt="sm">
            Tienes cambios pendientes sin guardar. ¿Estás seguro de que quieres salir? Los cambios se
            perderán.
          </Text>
          <Group justify="flex-end">
            <Button variant="default" onClick={handleClose}>
              Cancelar
            </Button>
            <Button color="red" onClick={handleClick}>
              Salir sin guardar
            </Button>
          </Group>
        </Modal>
      </>
    ) : (
      <Group h="88.3vh" justify="center" align="center">
        <Text c="dimmed" size="lg">
          No tienes permisos para acceder a ninguna seccion de incidentes.
        </Text>
      </Group>
    )
  ) : (
    <CitizenListEmpty />
  );
}
