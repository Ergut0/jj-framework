import {
  ActionIcon,
  Box,
  Button,
  Group,
  Modal,
  ScrollArea,
  Stack,
  Tabs,
  Text,
  TextInput,
  Tooltip,
} from '@mantine/core';
import { Link, RichTextEditor, getTaskListExtension } from '@mantine/tiptap';
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
import { useEffect, useMemo, useState } from 'react';
import { FaArrowRight, FaTrash } from 'react-icons/fa';
import { FaNoteSticky } from 'react-icons/fa6';
import { fetchNui, isBrowser } from '../utils/nui';
import styles from '../styles/Form.module.css';

export function RichTextContent(e) {
  return (
    <>
      <RichTextEditor editor={e.editor} w="100%">
        <RichTextEditor.Toolbar>
          <Group w="100%">
            <RichTextEditor.ControlsGroup>
              <RichTextEditor.ColorPicker colors={[]} />
              <RichTextEditor.Bold />
              <RichTextEditor.Italic />
              <RichTextEditor.Underline />
              <RichTextEditor.Strikethrough />
              <RichTextEditor.ClearFormatting />
              <RichTextEditor.Highlight />
              <RichTextEditor.Code />
            </RichTextEditor.ControlsGroup>
            <RichTextEditor.ControlsGroup>
              <RichTextEditor.H1 />
              <RichTextEditor.H2 />
              <RichTextEditor.H3 />
              <RichTextEditor.H4 />
            </RichTextEditor.ControlsGroup>
            <RichTextEditor.ControlsGroup>
              <RichTextEditor.Blockquote />
              <RichTextEditor.Hr />
              <RichTextEditor.TaskList />
              <RichTextEditor.BulletList />
              <RichTextEditor.OrderedList />
              <RichTextEditor.Subscript />
              <RichTextEditor.Superscript />
            </RichTextEditor.ControlsGroup>
            <RichTextEditor.ControlsGroup>
              <RichTextEditor.AlignLeft />
              <RichTextEditor.AlignCenter />
              <RichTextEditor.AlignJustify />
              <RichTextEditor.AlignRight />
            </RichTextEditor.ControlsGroup>
            <RichTextEditor.ControlsGroup>
              <RichTextEditor.Undo />
              <RichTextEditor.Redo />
            </RichTextEditor.ControlsGroup>
          </Group>
        </RichTextEditor.Toolbar>
        <ScrollArea h={e.height} type="never" onClick={() => e.editor?.commands.focus()}>
          <RichTextEditor.Content mih={e.height} />
        </ScrollArea>
      </RichTextEditor>
    </>
  );
}

export function TemplatesModal({
  opened,
  onClose,
  templates,
  canEdit,
  onSaveTemplate,
  onApplyTemplate,
  onDeleteTemplate,
}: any) {
  const [change, setChange] = useState<any>('use');
  const [templateName, setTemplateName] = useState<any>('');
  const [templateContent, setTemplateContent] = useState<any>('');
  const v = templates.filter((template) => {
    const j = templateName.toLowerCase().trim();
    if (!j) {
      return true;
    }
    const T = template.content
      .replace(/<[^>]*>/g, ' ')
      .replace(/&nbsp;/g, ' ')
      .toLowerCase();
    return template.name.toLowerCase().includes(j) || T.includes(j);
  });
  const y = (w) =>
    w
      .replace(/<[^>]*>/g, ' ')
      .replace(/&nbsp;/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
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
      editor?.commands.clearContent();
      setTemplateName('');
      setChange(templates.length > 0 ? 'use' : 'create');
    }
  }, [opened, editor]);
  useEffect(() => {
    editor?.setEditable(canEdit);
  }, [editor, canEdit]);
  const handleClick = async () => {
    if (await onSaveTemplate(templateContent, editor?.getHTML() ?? '')) {
      setTemplateContent('');
      editor?.commands.clearContent();
    }
  };
  return (
    <Modal opened={opened} onClose={onClose} title="Plantillas" centered size="80%">
      <Tabs value={change} onChange={setChange} mt="sm">
        <Tabs.List grow>
          <Tabs.Tab value="use">Usar plantilla</Tabs.Tab>
          <Tabs.Tab value="create" disabled={!canEdit}>
            Crear plantilla
          </Tabs.Tab>
        </Tabs.List>
        <Tabs.Panel value="use" pt="sm">
          <Stack>
            <TextInput
              flex={1}
              label="Nombre de la plantilla"
              placeholder="Ej: Informe de persecucion"
              value={templateName}
              onChange={(event) => setTemplateName(event.currentTarget.value)}
            />
            {v.length === 0 ? (
              <Text c="dimmed" ta="center" mt="sm" h="60vh">
                No hay plantillas que coincidan.
              </Text>
            ) : (
              <ScrollArea h="60vh" type="never" mt="xs">
                <Stack gap="xs">
                  {v.map((item) => (
                    <Box
                      key={item.id}
                      p="sm"
                      style={{
                        border: '1px solid var(--border-color)',
                        borderRadius: '5px',
                        background: 'var(--primary-color)',
                      }}
                    >
                      <Group justify="space-between" wrap="nowrap" align="flex-start">
                        <Box flex={1}>
                          <Text fw={700}>{item.name}</Text>
                          <Text size="xs" c="dimmed">
                            {new Date(item.createdAt).toLocaleString()}
                          </Text>
                          <Text size="sm" c="gray.4" mt={6} lineClamp={2}>
                            {y(item.content) || 'Sin contenido'}
                          </Text>
                        </Box>
                        <Group gap={6} wrap="nowrap">
                          <Button
                            className={styles.button}
                            size="xs"
                            onClick={() => onApplyTemplate(item.content)}
                            disabled={!canEdit}
                          >
                            Usar
                          </Button>
                          <Tooltip label="Eliminar plantilla" color="var(--primary-color)" withArrow>
                            <ActionIcon
                              color="red"
                              variant="light"
                              onClick={async () => {
                                await onDeleteTemplate(item.id);
                              }}
                              disabled={!canEdit}
                            >
                              <FaTrash size={13} />
                            </ActionIcon>
                          </Tooltip>
                        </Group>
                      </Group>
                    </Box>
                  ))}
                </Stack>
              </ScrollArea>
            )}
          </Stack>
        </Tabs.Panel>
        <Tabs.Panel value="create" pt="sm">
          <Stack>
            <Group align="flex-end" gap="xs">
              <TextInput
                flex={1}
                label="Nombre de la plantilla"
                placeholder="Ej: Informe de persecucion"
                value={templateContent}
                onChange={(event) => setTemplateContent(event.currentTarget.value)}
                disabled={!canEdit}
              />
              <Button
                className={styles.button}
                onClick={handleClick}
                disabled={!canEdit}
                mb={1}
                leftSection={<FaArrowRight size={12} />}
              >
                Guardar
              </Button>
            </Group>
            <RichTextContent editor={editor} height="57vh" />
          </Stack>
        </Tabs.Panel>
      </Tabs>
    </Modal>
  );
}

export const TEMPLATES_KEY = 'rich-text-templates:shared';

export const parseTemplates = (e) => {
  if (!e) {
    return [];
  }
  try {
    const t = JSON.parse(e);
    return Array.isArray(t) ? t : [];
  } catch {
    return [];
  }
};

export const sortTemplates = (e) =>
  e
    .replace(/<[^>]*>/g, '')
    .replace(/&nbsp;/g, ' ')
    .trim().length === 0;

export const useRichTextTemplates = (e = 'global') => {
  const t = useMemo(() => TEMPLATES_KEY, []);
  const [templates, setTemplates] = useState<any>([]);
  useEffect(() => {
    if (typeof window > 'u') {
      setTemplates([]);
      return;
    }
    (async () => {
      if (isBrowser()) {
        setTemplates(parseTemplates(window.localStorage.getItem(t)));
        return;
      }
      const response = await fetchNui('fetchRichTextTemplates', {
        scope: e,
      });
      setTemplates(Array.isArray(response) ? response : []);
    })();
  }, [e, t]);
  const o = (a) => {
    if (!(typeof window > 'u')) {
      window.localStorage.setItem(t, JSON.stringify(a));
    }
  };
  return {
    templates,
    saveTemplate: async (a, u) => {
      const name = a.trim();
      if (!name || sortTemplates(u)) {
        return false;
      }
      if (isBrowser()) {
        const p: any = {
          id: Date.now(),
          name,
          content: u,
          createdAt: Date.now(),
        };
        setTemplates((g) => {
          const v = [p, ...g];
          o(v);
          return v;
        });
        return true;
      }
      const response = await fetchNui('createRichTextTemplate', {
        scope: e,
        name,
        content: u,
      });
      return !response?.success || !response.template
        ? false
        : (setTemplates((p) => [response.template, ...p]), true);
    },
    deleteTemplate: async (a) => {
      if (isBrowser()) {
        setTemplates((f) => {
          const h = f.filter((item) => item.id !== a);
          o(h);
          return h;
        });
        return;
      }
      if (
        (
          await fetchNui('deleteRichTextTemplate', {
            id: a,
          })
        )?.success
      ) {
        setTemplates((f) => f.filter((item) => item.id !== a));
      }
    },
  };
};

export function RichTextBox({ editor, save, canEdit = true, height, templateScope = 'global' }: any) {
  const [templatesOpen, setTemplatesOpen] = useState<any>(false);
  const { templates, saveTemplate, deleteTemplate } = useRichTextTemplates(templateScope);
  const handleSaveTemplate = async (g, v) => await saveTemplate(g, v);
  const handleApplyTemplate = (g) => {
    if (!(!editor || canEdit === false)) {
      editor.commands.setContent(g);
      editor.commands.focus('end');
      save?.();
      setTemplatesOpen(false);
    }
  };
  return (
    <>
      <RichTextEditor editor={editor} w="100%" onBlur={save}>
        <RichTextEditor.Toolbar>
          <Group justify="space-between" w="100%">
            <Group>
              <RichTextEditor.ControlsGroup>
                <RichTextEditor.ColorPicker colors={[]} />
                <RichTextEditor.Bold />
                <RichTextEditor.Italic />
                <RichTextEditor.Underline />
                <RichTextEditor.Strikethrough />
                <RichTextEditor.ClearFormatting />
                <RichTextEditor.Highlight />
                <RichTextEditor.Code />
              </RichTextEditor.ControlsGroup>
              <RichTextEditor.ControlsGroup>
                <RichTextEditor.H1 />
                <RichTextEditor.H2 />
                <RichTextEditor.H3 />
                <RichTextEditor.H4 />
              </RichTextEditor.ControlsGroup>
              <RichTextEditor.ControlsGroup>
                <RichTextEditor.Blockquote />
                <RichTextEditor.Hr />
                <RichTextEditor.TaskList />
                <RichTextEditor.BulletList />
                <RichTextEditor.OrderedList />
                <RichTextEditor.Subscript />
                <RichTextEditor.Superscript />
              </RichTextEditor.ControlsGroup>
              <RichTextEditor.ControlsGroup>
                <RichTextEditor.AlignLeft />
                <RichTextEditor.AlignCenter />
                <RichTextEditor.AlignJustify />
                <RichTextEditor.AlignRight />
              </RichTextEditor.ControlsGroup>
              <RichTextEditor.ControlsGroup>
                <RichTextEditor.Undo />
                <RichTextEditor.Redo />
              </RichTextEditor.ControlsGroup>
            </Group>
            <Button
              tt="uppercase"
              lts={0.2}
              className={styles.button}
              leftSection={<FaNoteSticky />}
              onClick={() => setTemplatesOpen(true)}
              disabled={!editor || canEdit === false}
            >
              Plantillas
            </Button>
          </Group>
        </RichTextEditor.Toolbar>
        <ScrollArea
          h={height}
          type="never"
          onClick={() => {
            if (canEdit !== false) {
              editor?.commands.focus();
            }
          }}
        >
          <RichTextEditor.Content mih={height} />
        </ScrollArea>
      </RichTextEditor>
      {templatesOpen && (
        <TemplatesModal
          opened={templatesOpen}
          onClose={() => setTemplatesOpen(false)}
          templates={templates}
          canEdit={canEdit}
          onSaveTemplate={handleSaveTemplate}
          onApplyTemplate={handleApplyTemplate}
          onDeleteTemplate={deleteTemplate}
        />
      )}
    </>
  );
}
