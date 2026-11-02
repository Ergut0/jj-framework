import { Box, Button, Grid, Group, ScrollArea, Text, TextInput } from '@mantine/core';
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
import { FaPlus, FaSave, FaSpinner, FaTrash } from 'react-icons/fa';
import { FaFloppyDisk } from 'react-icons/fa6';
import { useRecoilValue } from 'recoil';
import { RichTextBox } from '../../components/RichText';
import { agentAtom, usePermissions } from '../../state/atoms';
import { fetchNui } from '../../utils/nui';
import { IncidentAgents } from './IncidentAgents';
import { IncidentCitizens } from './IncidentCitizens';
import { IncidentEvidence } from './IncidentEvidence';
import { IncidentTags } from './IncidentTags';
import { IncidentVehicles } from './IncidentVehicles';
import { IncidentVictims } from './IncidentVictims';
import stylesIncidents from '../../styles/Incidents.module.css';
import stylesForm from '../../styles/Form.module.css';

export function IncidentDetails({
  selectedIncident,
  setSelectedIncident,
  incidents,
  setIncidents,
  isDirty,
  setIsDirty,
}: any) {
  const [status, setStatus] = useState<any>('');
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
  const h = useRecoilValue<any>(agentAtom);
  const name = h ? `${h.citizen.firstname} ${h.citizen.lastname}` : '';
  const g =
    selectedIncident.creator?.citizenid === h?.citizen.citizenid || selectedIncident.creator?.name === name;
  const canEdit = haveRankPerms(['incidents.edit']) || g;
  const y = (E) => {
    setStatus(E);
    setSelectedIncident({
      ...selectedIncident,
      title: E,
    });
    setIsDirty(true);
  };
  const b = (E) => {
    editor?.commands.setContent(E);
    setSelectedIncident({
      ...selectedIncident,
      description: E,
    });
    setIsDirty(true);
  };
  useEffect(() => {
    if (selectedIncident?.id !== undefined) {
      setStatus(selectedIncident?.title ?? '');
      editor?.commands.setContent(selectedIncident?.description ?? '');
    }
  }, [selectedIncident.id]);
  const handleClick = async () => {
    if (selectedIncident.id !== undefined) {
      await fetchNui('updateIncident', {
        selectedIncident,
      });
      setIncidents(
        incidents.map((incident) => (incident.id === selectedIncident.id ? selectedIncident : incident)),
      );
      setIsDirty(false);
    }
  };
  useEffect(() => {
    editor?.setEditable(canEdit);
  }, [editor, canEdit]);
  const handleClick2 = () => {
    const status2 = selectedIncident.status === 'open' ? 'closed' : 'open';
    setSelectedIncident({
      ...selectedIncident,
      status: status2,
    });
    setIsDirty(true);
  };
  const handleClick3 = async () => {
    const E: any = {
      id: -1,
      title: 'Nuevo Informe',
      description: '',
      creator: {
        name,
        citizenid: h?.citizen.citizenid || '',
      },
      date: new Date().toLocaleDateString(),
      status: 'open',
    };
    const response = await fetchNui('createIncident', E);
    E.id = response.id;
    E.date = response.date;
    setSelectedIncident(E);
    setIncidents([E, ...incidents]);
    setIsDirty(false);
  };
  const handleClick4 = async () => {
    await fetchNui('deleteIncident', {
      id: selectedIncident.id,
    });
    setSelectedIncident({});
    setIncidents(incidents.filter((incident) => incident.id !== selectedIncident.id));
    setIsDirty(false);
  };
  return (
    <>
      <Box className={stylesIncidents.infoSectionHeader} p="md">
        {selectedIncident.id === undefined ? (
          <Group justify="space-between">
            <Text size="lg" tt="uppercase" fw={700}>
              Informe no seleccionado
            </Text>
            <Button
              leftSection={<FaPlus />}
              size="sm"
              className={stylesForm.button}
              tt="uppercase"
              lts={0.2}
              onClick={handleClick3}
            >
              Crear informe
            </Button>
          </Group>
        ) : (
          <Box>
            <Group gap="xs">
              <TextInput
                size="xs"
                flex={1}
                classNames={{
                  input: stylesIncidents.infoSectionTitle,
                }}
                value={status}
                readOnly={!canEdit}
                onChange={(event) => y(event.currentTarget.value)}
              />
              <Button
                leftSection={<FaPlus />}
                size="sm"
                className={stylesForm.button}
                tt="uppercase"
                lts={0.2}
                onClick={handleClick3}
              >
                Crear informe
              </Button>
              {selectedIncident.id !== undefined && canEdit && (
                <Button
                  size="sm"
                  variant="filled"
                  color={isDirty ? 'blue' : 'green'}
                  tt="uppercase"
                  lts={0.2}
                  onClick={handleClick}
                  disabled={!isDirty}
                  leftSection={isDirty ? <FaFloppyDisk /> : <FaSave />}
                >
                  Guardar informe
                </Button>
              )}
              {selectedIncident.id !== undefined && haveRankPerms(['incidents.delete']) && (
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
                {selectedIncident.creator.name}
                {' el'} {selectedIncident.date}
              </Text>
              <Button
                size="xs"
                color={selectedIncident.status === 'open' ? 'green' : 'red'}
                variant="light"
                tt="uppercase"
                lts={0.5}
                fw="bold"
                onClick={handleClick2}
                leftSection={<FaSpinner />}
                disabled={!canEdit}
              >
                {selectedIncident.status === 'open' ? 'Abierto' : 'Cerrado'}
              </Button>
            </Group>
          </Box>
        )}
      </Box>
      {selectedIncident.id !== undefined ? (
        <ScrollArea className={stylesIncidents.scrollArea} type="never" mt="sm">
          <RichTextBox
            editor={editor}
            height="60vh"
            canEdit={canEdit}
            save={() => b(editor?.getHTML() || '')}
            templateScope="incidents"
          />
          <Grid mt={20} justify="space-between" mx={8}>
            <IncidentCitizens
              selectedIncident={selectedIncident}
              setSelectedIncident={(E) => {
                setSelectedIncident(E);
                setIsDirty(true);
              }}
              canEdit={canEdit}
            />
            <IncidentAgents
              selectedIncident={selectedIncident}
              setSelectedIncident={(E) => {
                setSelectedIncident(E);
                setIsDirty(true);
              }}
              canEdit={canEdit}
            />
            <IncidentEvidence
              selectedIncident={selectedIncident}
              setSelectedIncident={(E) => {
                setSelectedIncident(E);
                setIsDirty(true);
              }}
              canEdit={canEdit}
            />
            <IncidentVehicles
              selectedIncident={selectedIncident}
              setSelectedIncident={(E) => {
                setSelectedIncident(E);
                setIsDirty(true);
              }}
              canEdit={canEdit}
            />
            <IncidentVictims
              selectedIncident={selectedIncident}
              setSelectedIncident={(E) => {
                setSelectedIncident(E);
                setIsDirty(true);
              }}
              canEdit={canEdit}
            />
            <IncidentTags
              selectedIncident={selectedIncident}
              setSelectedIncident={(E) => {
                setSelectedIncident(E);
                setIsDirty(true);
              }}
              canEdit={canEdit}
            />
          </Grid>
        </ScrollArea>
      ) : (
        <Text mt={20} ta="center" c="var(--text-secondary)">
          Selecciona un informe para ver su información.
        </Text>
      )}
    </>
  );
}
