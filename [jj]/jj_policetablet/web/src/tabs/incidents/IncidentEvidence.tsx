import {
  BackgroundImage,
  Box,
  Button,
  Flex,
  Grid,
  Group,
  Modal,
  ScrollArea,
  Stack,
  Text,
  TextInput,
} from '@mantine/core';
import { useHover } from '@mantine/hooks';
import { useState } from 'react';
import { FaArrowRight, FaBox, FaCamera, FaPlus, FaTrash, FaWarehouse } from 'react-icons/fa';
import { FaX } from 'react-icons/fa6';
import { usePermissions } from '../../state/atoms';
import { fetchNui } from '../../utils/nui';
import stylesForm from '../../styles/Form.module.css';
import stylesIncidents from '../../styles/Incidents.module.css';

export function IncidentEvidence({ selectedIncident, setSelectedIncident, canEdit = true }: any) {
  const [addOpen, setAddOpen] = useState<any>(false);
  const [imageUrl, setImageUrl] = useState<any>('');
  const [evidence2, setEvidence2] = useState<any>('');
  const { hovered, ref } = useHover();
  const { haveRankPerms } = usePermissions();
  const handleClick = () => {
    if (!(!selectedIncident || !setSelectedIncident)) {
      setSelectedIncident({
        ...selectedIncident,
        evidences: [...(selectedIncident.evidences || []), imageUrl],
      });
      setImageUrl('');
      setAddOpen(false);
    }
  };
  const handleClick2 = async () => {
    setAddOpen(false);
    const response = await fetchNui('takeEvidencePhoto', {});
    if (response && typeof response == 'string') {
      setSelectedIncident({
        ...selectedIncident,
        evidences: [...(selectedIncident.evidences || []), response],
      });
    }
  };
  const Component = () => (
    <Modal
      opened={addOpen}
      onClose={() => setAddOpen(false)}
      size="md"
      title="Añadir imagen de evidencia"
      centered
    >
      <Stack mt={15} gap="lg">
        <Group align="center" gap={9}>
          <TextInput
            flex={1}
            label="URL de la imagen"
            placeholder="Ingrese la URL de la imagen"
            description="Asegúrese de que la URL sea válida (FiveManage)"
            value={imageUrl}
            onChange={(event) => setImageUrl(event.currentTarget.value)}
          />
          <Button
            mt={48}
            className={stylesForm.button}
            tt="uppercase"
            lts={0.2}
            fw="bold"
            onClick={handleClick}
          >
            <FaArrowRight size={13} />
          </Button>
        </Group>
        {haveRankPerms(['camera.use']) && (
          <Button
            leftSection={<FaCamera size={18} />}
            className={stylesForm.button}
            tt="uppercase"
            lts={0.2}
            fw="bold"
            size="md"
            onClick={handleClick2}
          >
            Realizar Foto con cámara
          </Button>
        )}
      </Stack>
    </Modal>
  );
  const Component2 = ({ evidence }: any) => {
    const handleClick3 = () => {
      setEvidence2('');
    };
    return (
      <>
        <Box className={stylesIncidents.evidenceImageOpen}>
          <BackgroundImage w={1200} h={900} src={evidence}>
            <Flex
              justify="flex-end"
              align="flex-start"
              w="100%"
              h="100%"
              p="md"
              onClick={handleClick3}
              style={{
                cursor: 'pointer',
              }}
            >
              <FaX size={70} color="white" />
            </Flex>
          </BackgroundImage>
        </Box>
      </>
    );
  };
  const S = (j) => {
    setSelectedIncident({
      ...selectedIncident,
      evidences: selectedIncident.evidences?.filter((T) => T !== j),
    });
  };
  const handleClick4 = async () => {
    await fetchNui('openEvidenceStash', {
      incidentId: selectedIncident.id,
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
            <FaBox size={18} />
            <Text size="lg" fw="bold" c="var(--text-primary)">
              Evidencias
            </Text>
          </Group>
          <Group>
            <Button className={stylesForm.button} size="xs" onClick={handleClick4}>
              <FaWarehouse size={12} />
            </Button>
            {canEdit && (
              <Button className={stylesForm.button} size="xs" onClick={() => setAddOpen(true)}>
                <FaPlus size={12} />
              </Button>
            )}
          </Group>
        </Group>
        <ScrollArea mt="md" h="38vh" offsetScrollbars scrollbarSize={3} scrollbars="y">
          {selectedIncident.evidences && selectedIncident.evidences.length > 0 ? (
            <Grid align="flex-start" justify="flex-start">
              {selectedIncident.evidences.map((evidence, index) => (
                <Grid.Col key={index} span={3}>
                  <BackgroundImage
                    w={130}
                    h={130}
                    src={evidence}
                    radius="sm"
                    onClick={() => setEvidence2(evidence)}
                    style={{
                      cursor: hovered ? 'pointer' : 'default',
                    }}
                  >
                    {hovered && (
                      <Flex justify="flex-end" align="flex-start" w="100%" h="100%" p={6}>
                        <FaTrash
                          size={14}
                          color="white"
                          onClick={(event) => {
                            event.stopPropagation();
                            S(evidence);
                          }}
                        />
                      </Flex>
                    )}
                  </BackgroundImage>
                </Grid.Col>
              ))}
            </Grid>
          ) : (
            <Text c="dimmed" mt="lg" ta="center">
              No hay evidencias disponibles.
            </Text>
          )}
        </ScrollArea>
      </Grid.Col>
      {addOpen && <Component />}
      {evidence2.length > 0 && <Component2 evidence={evidence2} />}
    </>
  );
}
