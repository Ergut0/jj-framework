import {
  ActionIcon,
  Box,
  Button,
  Group,
  Modal,
  ScrollArea,
  Stack,
  Text,
  TextInput,
  Tooltip,
} from '@mantine/core';
import { useState } from 'react';
import { FaCopy, FaPlus, FaTrash, FaVideo } from 'react-icons/fa';
import stylesReports from '../../styles/Reports.module.css';
import stylesForm from '../../styles/Form.module.css';

export const copyToClipboard = (e) => {
  const t = document.createElement('textarea');
  t.value = e;
  document.body.appendChild(t);
  t.select();
  document.execCommand('copy');
  document.body.removeChild(t);
};

export function ReportVideos({ videos, onChange, canEdit }: any) {
  const [addOpen, setAddOpen] = useState<any>(false);
  const [videoTitle, setVideoTitle] = useState<any>('');
  const [videoUrl, setVideoUrl] = useState<any>('');
  const [copiedIndex, setCopiedIndex] = useState<any>(null);
  const handleClick = () => {
    if (videoUrl.trim()) {
      onChange([
        ...videos,
        {
          label: videoTitle.trim() || 'Vídeo',
          url: videoUrl.trim(),
        },
      ]);
      setVideoTitle('');
      setVideoUrl('');
      setAddOpen(false);
    }
  };
  const g = (v, y) => {
    copyToClipboard(y);
    setCopiedIndex(v);
    setTimeout(() => setCopiedIndex(null), 1500);
  };
  return (
    <Box className={stylesReports.infoSectionBox} p="sm" px="lg" h="100%">
      <Group justify="space-between">
        <Group gap={9}>
          <FaVideo size={18} />
          <Text size="lg" fw="bold" c="var(--text-primary)">
            Vídeos (Bodycam)
          </Text>
        </Group>
        {canEdit && (
          <Button className={stylesForm.button} size="xs" onClick={() => setAddOpen(true)}>
            <FaPlus size={12} />
          </Button>
        )}
      </Group>
      <ScrollArea mt="sm" mah="22vh" offsetScrollbars scrollbarSize={3}>
        <Stack gap="xs">
          {videos.length > 0 ? (
            videos.map((video, index) => (
              <Box key={`${video.url}-${index}`} className={stylesReports.boxItem} p={8}>
                <Group justify="space-between" wrap="nowrap">
                  <Stack
                    gap={2}
                    style={{
                      minWidth: 0,
                    }}
                  >
                    <Text fw="bold" size="sm">
                      {video.label}
                    </Text>
                    <Text size="xs" c="var(--text-secondary)" truncate="end">
                      {video.url}
                    </Text>
                  </Stack>
                  <Group gap={4} wrap="nowrap">
                    <Tooltip label={copiedIndex === index ? '¡Copiado!' : 'Copiar enlace'} withArrow>
                      <ActionIcon variant="subtle" color="gray" onClick={() => g(index, video.url)}>
                        <FaCopy size={12} />
                      </ActionIcon>
                    </Tooltip>
                    {canEdit && (
                      <ActionIcon
                        variant="subtle"
                        color="red"
                        onClick={() => onChange(videos.filter((video2, index2) => index2 !== index))}
                      >
                        <FaTrash size={12} />
                      </ActionIcon>
                    )}
                  </Group>
                </Group>
              </Box>
            ))
          ) : (
            <Text c="dimmed" mt="md" mx="auto" size="sm">
              No hay vídeos añadidos.
            </Text>
          )}
        </Stack>
      </ScrollArea>
      <Modal opened={addOpen} onClose={() => setAddOpen(false)} title="Añadir vídeo" centered size="md">
        <Stack mt="sm">
          <TextInput
            label="Descripción"
            placeholder="Ej: Bodycam agente 197"
            value={videoTitle}
            onChange={(event) => setVideoTitle(event.currentTarget.value)}
          />
          <TextInput
            label="Enlace del vídeo"
            placeholder="https://medal.tv/..."
            value={videoUrl}
            onChange={(event) => setVideoUrl(event.currentTarget.value)}
          />
          <Button
            className={stylesForm.button}
            tt="uppercase"
            onClick={handleClick}
            disabled={!videoUrl.trim()}
          >
            Añadir
          </Button>
        </Stack>
      </Modal>
    </Box>
  );
}
