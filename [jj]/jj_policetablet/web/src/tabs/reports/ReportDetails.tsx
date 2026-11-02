import {
  Box,
  Button,
  Grid,
  Group,
  ScrollArea,
  SegmentedControl,
  Select,
  Text,
  TextInput,
  Textarea,
} from '@mantine/core';
import { Link, getTaskListExtension } from '@mantine/tiptap';
import { Color } from '@tiptap/extension-color';
import { Highlight } from '@tiptap/extension-highlight';
import { Subscript } from '@tiptap/extension-subscript';
import { Superscript } from '@tiptap/extension-superscript';
import { TaskItem } from '@tiptap/extension-task-item';
import { TaskList } from '@tiptap/extension-task-list';
import { TextAlign } from '@tiptap/extension-text-align';
import { TextStyle } from '@tiptap/extension-text-style';
import { useEditor } from '@tiptap/react';
import { StarterKit } from '@tiptap/starter-kit';
import { useEffect, useState } from 'react';
import {
  FaBalanceScale,
  FaClipboardList,
  FaFileAlt,
  FaPlus,
  FaSave,
  FaSpinner,
  FaTrash,
  FaUserShield,
} from 'react-icons/fa';
import { FaFloppyDisk } from 'react-icons/fa6';
import { useRecoilValue } from 'recoil';
import { RichTextBox } from '../../components/RichText';
import { Iconm } from '../../icons';
import { agentAtom, usePermissions } from '../../state/atoms';
import { fetchNui } from '../../utils/nui';
import { ReportAgents } from './ReportAgents';
import { ReportVideos } from './ReportVideos';
import stylesReports from '../../styles/Reports.module.css';
import stylesForm from '../../styles/Form.module.css';

export const emptyReportData = () => ({
  implicatedAgents: [],
  reportingAgents: [],
  motive: '',
  complainant: '',
  videos: [],
  verdict: 'pending',
  sanction: '',
});

export const parseReportData = (e) => {
  const t = emptyReportData();
  return !e || Array.isArray(e)
    ? t
    : {
        implicatedAgents: Array.isArray(e.implicatedAgents) ? e.implicatedAgents : [],
        reportingAgents: Array.isArray(e.reportingAgents) ? e.reportingAgents : [],
        motive: e.motive ?? t.motive,
        complainant: e.complainant ?? t.complainant,
        videos: Array.isArray(e.videos) ? e.videos : [],
        verdict: e.verdict ?? t.verdict,
        sanction: e.sanction ?? t.sanction,
      };
};

export function ReportDetails({
  selectedReport,
  setSelectedReport,
  reports,
  setReports,
  isDirty,
  setIsDirty,
}: any) {
  const [status, setStatus] = useState<any>('');
  const u = useRecoilValue<any>(agentAtom);
  const f = u?.department?.toLowerCase() === 'lssd' || u?.department?.toLowerCase() === 'sheriff';
  const [division, setDivision] = useState<any>(f ? 'ia_lssd' : 'ia');
  useEffect(() => {
    setDivision(f ? 'ia_lssd' : 'ia');
  }, [f]);
  const editor = useEditor({
    shouldRerenderOnTransaction: true,
    editorProps: {
      attributes: {
        spellcheck: 'false',
      },
    },
    extensions: [
      StarterKit.configure({
        link: false,
      }),
      Link,
      Color,
      Superscript,
      Subscript,
      Highlight,
      TextStyle,
      getTaskListExtension(TaskList),
      TaskItem.configure({
        nested: true,
      }),
      TextAlign.configure({
        types: ['heading', 'paragraph'],
      }),
    ],
  });
  const { haveRankPerms } = usePermissions();
  const name = u ? `${u.citizen.firstname} ${u.citizen.lastname}` : '';
  const b =
    selectedReport.creator?.citizenid === u?.citizen.citizenid || selectedReport.creator?.name === name;
  const canEdit = haveRankPerms(['reports.edit']) || b;
  const w = !f && haveRankPerms(['reports.access.ia']);
  const j = !f && haveRankPerms(['reports.access.detectives']);
  const T = !f && haveRankPerms(['reports.access.sargentos']);
  const E = f && haveRankPerms(['reports.access.ia']);
  const A = f && haveRankPerms(['reports.access.detectives']);
  const R = f && haveRankPerms(['reports.access.sargentos']);
  const I =
    selectedReport.division === 'ia'
      ? w
      : selectedReport.division === 'detectives'
        ? j
        : selectedReport.division === 'sargentos'
          ? T
          : selectedReport.division === 'ia_lssd'
            ? E
            : selectedReport.division === 'detectives_lssd'
              ? A
              : selectedReport.division === 'sargentos_lssd'
                ? R
                : false;
  const B = (P) => {
    setStatus(P);
    setSelectedReport({
      ...selectedReport,
      title: P,
    });
    setIsDirty(true);
  };
  const U = parseReportData(selectedReport.caseInfo);
  const F = (P) => {
    setSelectedReport({
      ...selectedReport,
      caseInfo: {
        ...U,
        ...P,
      },
    });
    setIsDirty(true);
  };
  const q = (P) => {
    editor?.commands.setContent(P);
    setSelectedReport({
      ...selectedReport,
      description: P,
    });
    setIsDirty(true);
  };
  useEffect(() => {
    if (selectedReport?.id !== undefined) {
      setStatus(selectedReport?.title ?? '');
      editor?.commands.setContent(selectedReport?.description ?? '');
    }
  }, [selectedReport.id]);
  const handleClick = async () => {
    if (selectedReport.id !== undefined) {
      await fetchNui('updateReport', {
        selectedReport,
      });
      setReports(reports.map((report) => (report.id === selectedReport.id ? selectedReport : report)));
      setIsDirty(false);
    }
  };
  useEffect(() => {
    editor?.setEditable(canEdit);
  }, [editor, canEdit]);
  const handleClick2 = () => {
    const status2 = selectedReport.status === 'open' ? 'closed' : 'open';
    setSelectedReport({
      ...selectedReport,
      status: status2,
    });
    setIsDirty(true);
  };
  const handleClick3 = async () => {
    const P: any = {
      id: -1,
      title: 'Nuevo Incidente',
      description: '',
      creator: {
        name,
        citizenid: u?.citizen.citizenid || '',
      },
      date: new Date().toLocaleDateString(),
      division,
      caseInfo: emptyReportData(),
      status: 'open',
    };
    const response = await fetchNui('createReport', P);
    if (!(!response || response.error)) {
      P.id = response.id;
      P.date = response.date;
      P.division = response.division ?? division;
      setSelectedReport(P);
      setReports([P, ...reports]);
      setIsDirty(false);
    }
  };
  const W = (P) => {
    setSelectedReport({
      ...selectedReport,
      division: P,
    });
    setIsDirty(true);
  };
  const handleClick4 = async () => {
    await fetchNui('deleteReport', {
      id: selectedReport.id,
    });
    setSelectedReport({});
    setReports(reports.filter((report) => report.id !== selectedReport.id));
    setIsDirty(false);
  };
  return (
    <>
      <Box className={stylesReports.infoSectionHeader} p="md">
        {selectedReport.id === undefined ? (
          <Group justify="space-between">
            <Text size="lg" tt="uppercase" fw={700}>
              Incidente no seleccionado
            </Text>
            <Group gap="xs">
              <Select
                w={210}
                placeholder="Tipo"
                value={division}
                data={
                  f
                    ? [
                        {
                          value: 'ia_lssd',
                          label: 'IAD LSSD',
                        },
                        {
                          value: 'detectives_lssd',
                          label: 'DETECTIVES LSSD',
                        },
                        {
                          value: 'sargentos_lssd',
                          label: 'SARGENTOS LSSD',
                        },
                      ]
                    : [
                        {
                          value: 'ia',
                          label: 'IAD LSPD',
                        },
                        {
                          value: 'detectives',
                          label: 'DETECTIVES LSPD',
                        },
                        {
                          value: 'sargentos',
                          label: 'SARGENTOS LSPD',
                        },
                      ]
                }
                onChange={(P) => {
                  if (P) {
                    setDivision(P);
                  }
                }}
                allowDeselect={false}
              />
              <Button
                leftSection={<FaPlus />}
                size="sm"
                className={stylesForm.button}
                tt="uppercase"
                lts={0.2}
                onClick={handleClick3}
              >
                Crear incidente
              </Button>
            </Group>
          </Group>
        ) : (
          <Box>
            <Group gap="xs">
              <TextInput
                size="xs"
                flex={1}
                classNames={{
                  input: stylesReports.infoSectionTitle,
                }}
                value={status}
                readOnly={!canEdit}
                onChange={(event) => B(event.currentTarget.value)}
              />
              <Select
                w={190}
                placeholder="Tipo"
                data={
                  f
                    ? [
                        {
                          value: 'ia_lssd',
                          label: 'IAD LSSD',
                        },
                        {
                          value: 'detectives_lssd',
                          label: 'DETECTIVES LSSD',
                        },
                        {
                          value: 'sargentos_lssd',
                          label: 'SARGENTOS LSSD',
                        },
                      ]
                    : [
                        {
                          value: 'ia',
                          label: 'IAD LSPD',
                        },
                        {
                          value: 'detectives',
                          label: 'DETECTIVES LSPD',
                        },
                        {
                          value: 'sargentos',
                          label: 'SARGENTOS LSPD',
                        },
                      ]
                }
                value={selectedReport.division ?? (f ? 'ia_lssd' : 'ia')}
                readOnly={!canEdit}
                onChange={(P) => {
                  if (P) {
                    W(P);
                  }
                }}
                allowDeselect={false}
              />
              <Button
                leftSection={<FaPlus />}
                size="sm"
                className={stylesForm.button}
                tt="uppercase"
                lts={0.2}
                onClick={handleClick3}
              >
                Crear incidente
              </Button>
              {selectedReport.id !== undefined && canEdit && (
                <Button
                  size="sm"
                  variant="filled"
                  color={isDirty ? 'blue' : 'green'}
                  tt="uppercase"
                  lts={0.2}
                  leftSection={isDirty ? <FaFloppyDisk /> : <FaSave />}
                  onClick={handleClick}
                  disabled={!isDirty}
                >
                  Guardar incidente
                </Button>
              )}
              {selectedReport.id !== undefined && haveRankPerms(['reports.delete']) && (
                <Button size="sm" variant="light" color="red" tt="uppercase" lts={0.2} onClick={handleClick4}>
                  <FaTrash />
                </Button>
              )}
            </Group>
            <Group
              justify="space-between"
              mt={13}
              pt={13}
              style={{
                borderTop: '1px solid var(--border-color)',
              }}
            >
              <Text size="xs" c="var(--text-secondary)" fw="bold" mt={10}>
                {'Realizado por '}
                {selectedReport.creator.name}
                {' el'} {selectedReport.date}
              </Text>
              <Button
                size="xs"
                color={selectedReport.status === 'open' ? 'green' : 'red'}
                variant="light"
                tt="uppercase"
                lts={0.5}
                fw="bold"
                onClick={handleClick2}
                leftSection={<FaSpinner />}
                disabled={!canEdit}
              >
                {selectedReport.status === 'open' ? 'Abierto' : 'Cerrado'}
              </Button>
            </Group>
          </Box>
        )}
      </Box>
      {selectedReport.id !== undefined ? (
        I ? (
          <ScrollArea className={stylesReports.scrollArea} type="never" mt="sm">
            <Grid mx={8} gutter="md">
              <Grid.Col span={12}>
                <Box className={stylesReports.infoSectionBox} p="sm" px="lg">
                  <Group gap={9}>
                    <FaClipboardList size={18} />
                    <Text size="lg" fw="bold" c="var(--text-primary)">
                      Datos del caso
                    </Text>
                  </Group>
                  <Group mt="sm" grow align="flex-start">
                    <TextInput
                      label="Motivo de la investigación"
                      placeholder="Ej: Negligencia"
                      value={U.motive}
                      readOnly={!canEdit}
                      onChange={(event) =>
                        F({
                          motive: event.currentTarget.value,
                        })
                      }
                    />
                    <TextInput
                      label="Denunciante / Involucrado"
                      placeholder="Nombre de la persona"
                      value={U.complainant}
                      readOnly={!canEdit}
                      onChange={(event) =>
                        F({
                          complainant: event.currentTarget.value,
                        })
                      }
                    />
                  </Group>
                </Box>
              </Grid.Col>
              <Grid.Col span={6}>
                <ReportAgents
                  title="Agente implicado"
                  icon={<FaUserShield size={18} />}
                  emptyText="No hay agente implicado."
                  agents={U.implicatedAgents}
                  onChange={(P) =>
                    F({
                      implicatedAgents: P,
                    })
                  }
                  canEdit={canEdit}
                />
              </Grid.Col>
              <Grid.Col span={6}>
                <ReportAgents
                  title="Agentes que ponen la falta"
                  icon={<Iconm size={20} />}
                  emptyText="No hay agentes añadidos."
                  agents={U.reportingAgents}
                  onChange={(P) =>
                    F({
                      reportingAgents: P,
                    })
                  }
                  canEdit={canEdit}
                />
              </Grid.Col>
              <Grid.Col span={12}>
                <Group gap={9} mb="xs">
                  <FaFileAlt size={16} />
                  <Text size="lg" fw="bold" c="var(--text-primary)">
                    Resumen de los hechos
                  </Text>
                </Group>
                <RichTextBox
                  editor={editor}
                  height="30vh"
                  canEdit={canEdit}
                  save={() => q(editor?.getHTML() || '')}
                  templateScope="reports"
                />
              </Grid.Col>
              <Grid.Col span={6}>
                <ReportVideos
                  videos={U.videos}
                  onChange={(P) =>
                    F({
                      videos: P,
                    })
                  }
                  canEdit={canEdit}
                />
              </Grid.Col>
              <Grid.Col span={6}>
                <Box className={stylesReports.infoSectionBox} p="sm" px="lg" h="100%">
                  <Group gap={9}>
                    <FaBalanceScale size={18} />
                    <Text size="lg" fw="bold" c="var(--text-primary)">
                      Resolución de Jefatura
                    </Text>
                  </Group>
                  <SegmentedControl
                    mt="sm"
                    fullWidth
                    readOnly={!canEdit}
                    value={U.verdict}
                    onChange={(P) =>
                      F({
                        verdict: P,
                      })
                    }
                    color={U.verdict === 'guilty' ? 'red' : U.verdict === 'not_guilty' ? 'green' : 'gray'}
                    data={[
                      {
                        value: 'pending',
                        label: 'Pendiente',
                      },
                      {
                        value: 'not_guilty',
                        label: 'No culpable',
                      },
                      {
                        value: 'guilty',
                        label: 'Culpable',
                      },
                    ]}
                  />
                  <Textarea
                    mt="sm"
                    label="Sanción aplicada"
                    placeholder={
                      U.verdict === 'guilty'
                        ? 'Ej: Suspensión de empleo por 1 día + Falta Media'
                        : 'Solo si el agente es culpable'
                    }
                    autosize
                    minRows={3}
                    value={U.sanction}
                    readOnly={!canEdit}
                    disabled={U.verdict !== 'guilty'}
                    onChange={(event) =>
                      F({
                        sanction: event.currentTarget.value,
                      })
                    }
                  />
                </Box>
              </Grid.Col>
            </Grid>
          </ScrollArea>
        ) : (
          <Text mt={20} ta="center" c="var(--text-secondary)">
            No tienes permisos para acceder a este tipo de incidente.
          </Text>
        )
      ) : (
        <Text mt={20} ta="center" c="var(--text-secondary)">
          Selecciona un incidente para ver su informacion.
        </Text>
      )}
    </>
  );
}
