import {
  ActionIcon,
  Badge,
  Box,
  Button,
  Card,
  Group,
  Image,
  Modal,
  ScrollArea,
  Stack,
  Switch,
  Text,
  Title,
  Tooltip,
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
import { FaIdCard, FaPlus, FaTrash } from 'react-icons/fa';
import { FaPencil } from 'react-icons/fa6';
import { RichTextContent } from '../../components/RichText';
import { mockCitizens } from '../../data/mockCitizens';
import { usePermissions } from '../../state/atoms';
import { fetchNui, isBrowser, openEntityTab } from '../../utils/nui';
import stylesForm from '../../styles/Form.module.css';
import stylesHome from '../../styles/Home.module.css';

export const mockAnnounces = [
  {
    id: 1,
    text: 'Bienvenidos al sistema de gestión policial. Por favor, asegúrese de seguir los protocolos establecidos.',
    pinned: false,
  },
  {
    id: 2,
    text: '<h2 style="text-align: center;">Welcome to Mantine rich text editor</h2><p><code>RichTextEditor</code> component focuses on usability and is designed to be as simple as possible to bring a familiar editing experience to regular users. <code>RichTextEditor</code> is based on <a href="https://tiptap.dev/" rel="noopener noreferrer" target="_blank">Tiptap.dev</a> and supports all of its features:</p><ul><li>General text formatting: <strong>bold</strong>, <em>italic</em>, <u>underline</u>, <s>strike-through</s> </li><li>Headings (h1-h6)</li><li>Sub and super scripts (<sup>&lt;sup /&gt;</sup> and <sub>&lt;sub /&gt;</sub> tags)</li><li>Ordered and bullet lists</li><li>Text align&nbsp;</li><li>And all <a href="https://tiptap.dev/extensions" target="_blank" rel="noopener noreferrer">other extensions</a></li></ul>',
    pinned: false,
  },
  {
    id: 23,
    text: '<h2 style="text-align: center;">Welcome to Mantine rich text editor</h2><p><code>RichTextEditor</code> component focuses on usability and is designed to be as simple as possible to bring a familiar editing experience to regular users. <code>RichTextEditor</code> is based on <a href="https://tiptap.dev/" rel="noopener noreferrer" target="_blank">Tiptap.dev</a> and supports all of its features:</p><ul><li>General text formatting: <strong>bold</strong>, <em>italic</em>, <u>underline</u>, <s>strike-through</s> </li><li>Headings (h1-h6)</li><li>Sub and super scripts (<sup>&lt;sup /&gt;</sup> and <sub>&lt;sub /&gt;</sub> tags)</li><li>Ordered and bullet lists</li><li>Text align&nbsp;</li><li>And all <a href="https://tiptap.dev/extensions" target="_blank" rel="noopener noreferrer">other extensions</a></li></ul>',
    pinned: true,
  },
  {
    id: 24,
    text: '<h2 style="text-align: center;">Welcome to Mantine rich text editor</h2><p><code>RichTextEditor</code> component focuses on usability and is designed to be as simple as possible to bring a familiar editing experience to regular users. <code>RichTextEditor</code> is based on <a href="https://tiptap.dev/" rel="noopener noreferrer" target="_blank">Tiptap.dev</a> and supports all of its features:</p><ul><li>General text formatting: <strong>bold</strong>, <em>italic</em>, <u>underline</u>, <s>strike-through</s> </li><li>Headings (h1-h6)</li><li>Sub and super scripts (<sup>&lt;sup /&gt;</sup> and <sub>&lt;sub /&gt;</sub> tags)</li><li>Ordered and bullet lists</li><li>Text align&nbsp;</li><li>And all <a href="https://tiptap.dev/extensions" target="_blank" rel="noopener noreferrer">other extensions</a></li></ul>',
    pinned: false,
  },
  {
    id: 25,
    text: '<h2 style="text-align: center;">Welcome to Mantine rich text editor</h2><p><code>RichTextEditor</code> component focuses on usability and is designed to be as simple as possible to bring a familiar editing experience to regular users. <code>RichTextEditor</code> is based on <a href="https://tiptap.dev/" rel="noopener noreferrer" target="_blank">Tiptap.dev</a> and supports all of its features:</p><ul><li>General text formatting: <strong>bold</strong>, <em>italic</em>, <u>underline</u>, <s>strike-through</s> </li><li>Headings (h1-h6)</li><li>Sub and super scripts (<sup>&lt;sup /&gt;</sup> and <sub>&lt;sub /&gt;</sub> tags)</li><li>Ordered and bullet lists</li><li>Text align&nbsp;</li><li>And all <a href="https://tiptap.dev/extensions" target="_blank" rel="noopener noreferrer">other extensions</a></li></ul>',
    pinned: false,
  },
  {
    id: 3,
    text: 'Recordatorio: La reunión de coordinación policial se llevará a cabo el próximo lunes a las 10:00 AM en la sala de conferencias principal.',
    pinned: false,
  },
  {
    id: 4,
    text: 'Actualización de protocolo: A partir del 1 de septiembre, todos los oficiales deberán completar el curso de capacitación en línea sobre manejo de crisis.',
    pinned: true,
  },
];

export function CreateAnnounceModal({ opened, onClose, onCreate }: any) {
  const [pinned, setPinned] = useState<any>(false);
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
  useEffect(() => {
    if (opened) {
      setPinned(false);
      editor?.commands.setContent('');
    }
  }, [opened, editor]);
  const handleClick = () => {
    const a = editor?.getHTML().trim() ?? '';
    if (!(!a || a === '<p></p>')) {
      onCreate(a, pinned);
      setPinned(false);
      editor?.commands.setContent('');
      onClose();
    }
  };
  return (
    <Modal opened={opened} onClose={onClose} title="Crear anuncio" centered size="90%">
      <Stack gap="md" mt="md" h={800}>
        <RichTextContent editor={editor} height={680} />
        <Group justify="flex-end" align="center">
          <Switch
            label="Fijar anuncio"
            checked={pinned}
            labelPosition="left"
            onChange={(event) => setPinned(event.currentTarget.checked)}
          />
          <Button className={stylesForm.button} onClick={handleClick}>
            Crear anuncio
          </Button>
        </Group>
      </Stack>
    </Modal>
  );
}

export function EditAnnounceModal({ opened, onClose, onUpdate, initialText, initialPinned }: any) {
  const [pinned, setPinned] = useState<any>(initialPinned);
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
  useEffect(() => {
    if (opened) {
      setPinned(initialPinned);
      editor?.commands.setContent(initialText || '');
    }
  }, [opened, initialPinned, initialText, editor]);
  const handleClick = () => {
    const f = editor?.getHTML().trim() ?? '';
    if (!(!f || f === '<p></p>')) {
      onUpdate(f, pinned);
      onClose();
    }
  };
  return (
    <Modal opened={opened} onClose={onClose} title="Editar anuncio" centered size="90%">
      <Stack gap="md" mt="md" h={800}>
        <RichTextContent editor={editor} height={680} />
        <Group justify="flex-end" align="center">
          <Switch
            label="Fijar anuncio"
            checked={pinned}
            labelPosition="left"
            onChange={(event) => setPinned(event.currentTarget.checked)}
          />
          <Button className={stylesForm.button} onClick={handleClick}>
            Guardar cambios
          </Button>
        </Group>
      </Stack>
    </Modal>
  );
}

export function HomeTab() {
  const [announces, setAnnounces] = useState<any>([]);
  const [createOpen, setCreateOpen] = useState<any>(false);
  const [editOpen, setEditOpen] = useState<any>(false);
  const [editingAnnounce, setEditingAnnounce] = useState<any>(null);
  const { haveRankPerms } = usePermissions();
  const f = [...announces].sort((w, j) => (w.pinned && !j.pinned ? -1 : !w.pinned && j.pinned ? 1 : 0));
  const [wantedSubjects, setWantedSubjects] = useState<any>([]);
  useEffect(() => {
    if (isBrowser()) {
      setAnnounces(mockAnnounces);
      setWantedSubjects(mockCitizens.filter((mockCitizen) => mockCitizen.isWanted));
      return;
    }
    (async () => {
      const [j, T] = await Promise.all([fetchNui('fetchHomeAnnounces'), fetchNui('fetchHomeWantedSubjects')]);
      setAnnounces(Array.isArray(j) ? j : []);
      setWantedSubjects(Array.isArray(T) ? T : []);
    })();
  }, []);
  const handleClick = () => {
    setCreateOpen(true);
  };
  const handleCreate = async (w, j) => {
    if (isBrowser()) {
      const E: any = {
        id: Date.now(),
        text: w,
        pinned: j,
      };
      setAnnounces((A) => [E, ...A]);
      return;
    }
    const response = await fetchNui('createHomeAnnounce', {
      text: w,
      pinned: j,
    });
    if (response && typeof response.id == 'number') {
      setAnnounces((E) => [response, ...E]);
    }
  };
  const y = (w) => {
    setEditingAnnounce(w);
    setEditOpen(true);
  };
  const handleUpdate = async (w, j) => {
    if (editingAnnounce) {
      if (!(
        !isBrowser() &&
        !(
          await fetchNui('updateHomeAnnounce', {
            id: editingAnnounce.id,
            text: w,
            pinned: j,
          })
        )?.success
      )) {
        setAnnounces((T) =>
          T.map((item) =>
            item.id === editingAnnounce.id
              ? {
                  ...item,
                  text: w,
                  pinned: j,
                }
              : item,
          ),
        );
        setEditingAnnounce(null);
      }
    }
  };
  const S = async (w) => {
    if (isBrowser()) {
      setAnnounces((T) => T.filter((item) => item.id !== w));
      return;
    }
    if (
      (
        await fetchNui('deleteHomeAnnounce', {
          id: w,
        })
      )?.success
    ) {
      setAnnounces((T) => T.filter((item) => item.id !== w));
    }
  };
  return (
    <Group p="sm" gap="md">
      <Stack gap="md" className={stylesHome.announcesSection}>
        <Box className={stylesHome.announcesTitle}>
          <Title order={4} tt="uppercase" lts={0.7} ta="center">
            Tablón de Anuncios
          </Title>
          <Box className={stylesHome.actionIcons}>
            {haveRankPerms(['home.notes.create']) && (
              <Tooltip label="Crear anuncio" color="var(--primary-color)" withArrow>
                <ActionIcon variant="light" color="dark.1" radius="sm" size="md" onClick={handleClick}>
                  <FaPlus size={12} />
                </ActionIcon>
              </Tooltip>
            )}
          </Box>
        </Box>
        <ScrollArea h="80vh" offsetScrollbars scrollbarSize={3}>
          <Stack gap="md">
            {f.map((item) => (
              <Card
                key={item.id}
                shadow="sm"
                padding="lg"
                radius="md"
                withBorder
                className={item.pinned ? stylesHome.pinnedCard : stylesHome.announceCard}
              >
                <Card.Section inheritPadding py="md">
                  {haveRankPerms(['home.notes.delete']) && (
                    <Box className={stylesHome.deleteIcon}>
                      {haveRankPerms(['home.notes.edit']) && (
                        <Tooltip label="Editar anuncio" color="var(--primary-color)" withArrow>
                          <ActionIcon
                            variant="light"
                            color="blue"
                            radius="sm"
                            size="md"
                            mr={7}
                            onClick={() => y(item)}
                          >
                            <FaPencil size={12} />
                          </ActionIcon>
                        </Tooltip>
                      )}
                      {haveRankPerms(['home.notes.delete']) && (
                        <Tooltip label="Eliminar anuncio" color="var(--primary-color)" withArrow>
                          <ActionIcon
                            variant="light"
                            color="red"
                            radius="sm"
                            size="md"
                            onClick={() => S(item.id)}
                          >
                            <FaTrash size={12} />
                          </ActionIcon>
                        </Tooltip>
                      )}
                    </Box>
                  )}
                  {item.text.startsWith('<') ? (
                    <div
                      dangerouslySetInnerHTML={{
                        __html: item.text,
                      }}
                    />
                  ) : (
                    <Text size="sm">{item.text}</Text>
                  )}
                </Card.Section>
              </Card>
            ))}
          </Stack>
        </ScrollArea>
      </Stack>
      <CreateAnnounceModal opened={createOpen} onClose={() => setCreateOpen(false)} onCreate={handleCreate} />
      <EditAnnounceModal
        opened={editOpen}
        onClose={() => {
          setEditOpen(false);
          setEditingAnnounce(null);
        }}
        onUpdate={handleUpdate}
        initialText={editingAnnounce?.text ?? ''}
        initialPinned={editingAnnounce?.pinned ?? false}
      />
      <Stack className={stylesHome.wantedSection}>
        <Box className={stylesHome.announcesTitle}>
          <Title order={4} tt="uppercase" lts={0.7} ta="center">
            Sujetos en búsqueda y captura
          </Title>
        </Box>
        <ScrollArea h="80vh" offsetScrollbars scrollbarSize={3}>
          <Stack gap="md">
            {wantedSubjects.map((wantedSubject) => (
              <Box key={wantedSubject.citizenid} className={stylesHome.wantedSubject}>
                <Image
                  src={wantedSubject.imageUrl}
                  fallbackSrc="default-user.webp"
                  h={90}
                  w={90}
                  radius="sm"
                />
                <Stack flex={1}>
                  <Group justify="space-between">
                    <Text size="xl" fw={600}>
                      {wantedSubject.firstname} {wantedSubject.lastname}
                    </Text>
                    <Group gap="xs">
                      <Badge
                        variant="light"
                        color="dark.1"
                        radius="sm"
                        size="sm"
                        leftSection={<FaIdCard size={12} />}
                      >
                        {wantedSubject.citizenid}
                      </Badge>
                    </Group>
                  </Group>
                  <Button
                    className={stylesForm.button}
                    onClick={() =>
                      openEntityTab({
                        type: 'citizen',
                        citizenId: wantedSubject.citizenid,
                      })
                    }
                  >
                    Ver detalles
                  </Button>
                </Stack>
              </Box>
            ))}
          </Stack>
        </ScrollArea>
      </Stack>
    </Group>
  );
}
