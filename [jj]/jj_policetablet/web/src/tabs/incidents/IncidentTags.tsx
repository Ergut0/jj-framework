import { Badge, Box, Button, Grid, Group, Modal, MultiSelect, Stack, Text, TextInput } from '@mantine/core';
import { useHover } from '@mantine/hooks';
import { useState } from 'react';
import { FaArrowRight, FaPlus, FaTags } from 'react-icons/fa';
import { FaX } from 'react-icons/fa6';
import stylesForm from '../../styles/Form.module.css';
import stylesIncidents from '../../styles/Incidents.module.css';

export function AddIncidentTagModal({ opened, onClose, selectedIncident, setSelectedIncident }: any) {
  const s = [
    'LSPD',
    'LSSD',
    'Caso abierto',
    'Caso cerrado',
    'DB',
    'SCUB',
    'USMS',
    'Armas de fuego',
    'Robo mediano',
    'Robo grande',
    'Operativo policial',
    'Intento de homicidio',
    'Intento de homicidio (funcionario)',
    'Altercado',
    'Tráfico',
    'Drogas',
    'Secuestro',
    'Secuestro (funcionario)',
    'Tiroteo entre grupos',
  ];
  const [customTag, setCustomTag] = useState<any>('');
  const [change, setChange] = useState<any>([]);
  const handleClick = () => {
    if (!change.includes(customTag)) {
      if (customTag.length !== 0) {
        setChange([...change, customTag]);
        setCustomTag('');
      }
    }
  };
  const handleClick2 = () => {
    setSelectedIncident({
      ...selectedIncident,
      tags: [...(selectedIncident.tags ?? []), ...change],
    });
    onClose();
  };
  return (
    <>
      <Modal title="Agregar Tag" opened={opened} onClose={onClose} centered>
        <Stack mt={10}>
          <MultiSelect
            label="Selecciona un tag para el informe"
            placeholder="Tags"
            data={s}
            searchable
            value={change}
            onChange={setChange}
            nothingFoundMessage="No se encontraron tags"
          />
          <Group gap="xs">
            <TextInput
              label="Agregar nuevo tag (Solo para este informe)"
              placeholder="Tag personalizado"
              flex={1}
              value={customTag}
              onChange={(event) => setCustomTag(event.currentTarget.value)}
            />
            <Button className={stylesForm.button} mt={27} onClick={handleClick}>
              <FaArrowRight />
            </Button>
          </Group>
          <Button className={stylesForm.button} onClick={handleClick2}>
            Confirmar
          </Button>
        </Stack>
      </Modal>
    </>
  );
}

export function IncidentTags({ selectedIncident, setSelectedIncident, canEdit = true }: any) {
  const [addOpen, setAddOpen] = useState<any>(false);
  const { hovered, ref } = useHover();
  const a = (u) => {
    setSelectedIncident({
      ...selectedIncident,
      tags: selectedIncident.tags?.filter((f) => f !== u),
    });
  };
  return (
    <>
      <Grid.Col
        span={5.92}
        className={stylesIncidents.infoSectionBox}
        mt={15}
        mih="45vh"
        mah="45vh"
        p="sm"
        px="lg"
        ref={ref}
      >
        <Group justify="space-between">
          <Group gap={9}>
            <FaTags size={19} />
            <Text size="lg" fw="bold" c="var(--text-primary)">
              Tags
            </Text>
          </Group>
          {canEdit && (
            <Button className={stylesForm.button} size="xs" onClick={() => setAddOpen(true)}>
              <FaPlus size={12} />
            </Button>
          )}
        </Group>
        <Box>
          {selectedIncident.tags && selectedIncident.tags.length > 0 ? (
            <Group mt="md" gap="lg">
              {selectedIncident.tags.map((tag, index) => (
                <Badge
                  key={index}
                  size="md"
                  color="dark.1"
                  variant="light"
                  radius="sm"
                  leftSection={hovered ? <FaX /> : undefined}
                  onClick={() => {
                    if (hovered) {
                      a(tag);
                    }
                  }}
                  style={{
                    cursor: hovered ? 'pointer' : 'default',
                  }}
                >
                  {tag}
                </Badge>
              ))}
            </Group>
          ) : (
            <Text c="dimmed" mt="xl" ta="center">
              No hay tags asignados.
            </Text>
          )}
        </Box>
      </Grid.Col>
      {addOpen && (
        <AddIncidentTagModal
          opened={addOpen}
          onClose={() => setAddOpen(false)}
          selectedIncident={selectedIncident}
          setSelectedIncident={setSelectedIncident}
        />
      )}
    </>
  );
}
