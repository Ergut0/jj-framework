import {
  BackgroundImage,
  Box,
  Button,
  Center,
  Grid,
  Group,
  Modal,
  Stack,
  Text,
  TextInput,
  Title,
} from '@mantine/core';
import { useHover } from '@mantine/hooks';
import { useState } from 'react';
import {
  FaArrowRight,
  FaBox,
  FaCamera,
  FaCarBattery,
  FaCarSide,
  FaCreditCard,
  FaExclamationTriangle,
  FaPlus,
  FaUser,
} from 'react-icons/fa';
import { FaNoteSticky } from 'react-icons/fa6';
import { mockIncidents } from '../../data/mockIncidents';
import { usePermissions } from '../../state/atoms';
import { fetchNui, isBrowser } from '../../utils/nui';
import { AddVehicleNoteModal, VehicleIncidents, VehicleNotes } from './VehicleSections';
import stylesVehicles from '../../styles/Vehicles.module.css';
import stylesForm from '../../styles/Form.module.css';

export function VehicleDetails({ selectedVehicle, setSelectedVehicle }: any) {
  const { haveRankPerms } = usePermissions();
  const incidents = isBrowser()
    ? mockIncidents.filter((mockIncident) =>
        mockIncident.vehicles?.some((p) => p.plate === selectedVehicle?.plate),
      )
    : selectedVehicle?.incidents || [];
  const [addNoteOpen, setAddNoteOpen] = useState<any>(false);
  const i = () => {
    if (!selectedVehicle?.notes) {
      return [];
    }
    const h = selectedVehicle.notes.filter((note) => note.pinged);
    const p = selectedVehicle.notes.filter((note) => !note.pinged);
    return [...h, ...p];
  };
  const handleTogglePinged = async (h) => {
    if (!selectedVehicle) {
      return;
    }
    await fetchNui('toggleVehicleNotePingedStatus', {
      vehiclePlate: selectedVehicle.plate,
      noteId: h,
    });
    const notes = selectedVehicle.notes?.map((g) =>
      g.id === h
        ? {
            ...g,
            pinged: !g.pinged,
          }
        : g,
    );
    setSelectedVehicle({
      ...selectedVehicle,
      id: selectedVehicle.id,
      notes,
    });
  };
  const handleAddNote = async (h, p) => {
    if (!selectedVehicle) {
      return;
    }
    const note: any = {
      id: selectedVehicle.notes ? selectedVehicle.notes.length + 1 : 1,
      title: h,
      description: p,
      pinged: false,
      date: new Date().toISOString().slice(0, 10),
      author: 'Sistema',
    };
    const response = await fetchNui('addVehicleNote', {
      vehiclePlate: selectedVehicle.plate,
      note,
    });
    const notes = selectedVehicle.notes ? [...selectedVehicle.notes, response] : [response];
    setSelectedVehicle({
      ...selectedVehicle,
      id: selectedVehicle.id,
      notes,
    });
  };
  const handleDeleteNote = async (h) => {
    if (!selectedVehicle) {
      return;
    }
    await fetchNui('deleteVehicleNote', {
      vehiclePlate: selectedVehicle.plate,
      noteId: h,
    });
    const notes = selectedVehicle.notes?.filter((g) => g.id !== h);
    setSelectedVehicle({
      ...selectedVehicle,
      id: selectedVehicle.id,
      notes,
    });
  };
  return (
    <>
      <Grid mt={20} justify="space-between" mx={8}>
        <Grid.Col
          span={5.92}
          className={stylesVehicles.infoSectionBox}
          mt={15}
          mih="48vh"
          mah="48vh"
          p="sm"
          px="lg"
        >
          <Group justify="space-between" gap={0}>
            <Group gap={9}>
              <FaNoteSticky size={18} />
              <Text size="lg" fw="bold" c="var(--text-primary)">
                Notas
              </Text>
            </Group>
            <Button className={stylesForm.button} size="xs" onClick={() => setAddNoteOpen(true)}>
              <FaPlus size={12} />
            </Button>
          </Group>
          <VehicleNotes
            notes={i()}
            canDelete={haveRankPerms(['citizen.notes.delete'])}
            onDeleteNote={handleDeleteNote}
            onTogglePinged={handleTogglePinged}
          />
        </Grid.Col>
        <Grid.Col
          span={5.92}
          className={stylesVehicles.infoSectionBox}
          mt={15}
          mih="48vh"
          mah="48vh"
          p="sm"
          px="lg"
        >
          <Group justify="space-between" gap={0}>
            <Group gap={9}>
              <FaBox size={17} />
              <Text size="lg" fw="bold" c="var(--text-primary)">
                Incidentes
              </Text>
            </Group>
          </Group>
          <VehicleIncidents incidents={incidents} />
        </Grid.Col>
      </Grid>
      {addNoteOpen && (
        <AddVehicleNoteModal
          opened={addNoteOpen}
          onClose={() => setAddNoteOpen(false)}
          vehicle={selectedVehicle}
          onAddNote={handleAddNote}
        />
      )}
    </>
  );
}

export function VehicleHeader({ vehicle, setSelectedVehicle }: any) {
  const [imageModalOpen, setImageModalOpen] = useState<any>(false);
  const [imageUrl, setImageUrl] = useState<any>('');
  const { hovered, ref } = useHover();
  const { haveRankPerms } = usePermissions();
  const handleClick = async () => {
    if (vehicle) {
      await fetchNui('toggleVehicleIncautedStatus', {
        vehiclePlate: vehicle.plate,
      });
      setSelectedVehicle({
        ...vehicle,
        incauted: !vehicle.incauted,
      });
    }
  };
  const handleClick2 = async () => {
    if (vehicle) {
      await fetchNui('toggleVehicleWantedStatus', {
        vehiclePlate: vehicle.plate,
      });
      setSelectedVehicle({
        ...vehicle,
        wanted: !vehicle.wanted,
      });
    }
  };
  const handleClick3 = async () => {
    if (vehicle) {
      await fetchNui('updateVehicleImageUrl', {
        vehiclePlate: vehicle.plate,
        imageUrl,
      });
      setSelectedVehicle({
        ...vehicle,
        image: imageUrl,
      });
      setImageModalOpen(false);
    }
  };
  const handleClick4 = async () => {
    setImageModalOpen(false);
    if (!vehicle) {
      return;
    }
    const image = await fetchNui('takeVehiclePicture', {
      vehiclePlate: vehicle.plate,
    });
    if (image) {
      setSelectedVehicle({
        ...vehicle,
        image,
      });
    }
  };
  const Component2 = () => (
    <Modal
      opened={imageModalOpen}
      onClose={() => setImageModalOpen(false)}
      size="md"
      title="Actualizar Imagen del Vehículo"
      centered
    >
      <Stack mt={15} gap="lg">
        <Group align="center" gap={9}>
          <TextInput
            flex={1}
            label="URL de la imagen"
            placeholder="Ingrese la URL de la imagen"
            description="Asegúrese de que la URL sea válida"
            value={imageUrl}
            onChange={(event) => setImageUrl(event.currentTarget.value)}
          />
          <Button
            mt={48}
            className={stylesForm.button}
            tt="uppercase"
            lts={0.2}
            fw="bold"
            onClick={handleClick3}
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
            onClick={handleClick4}
          >
            Realizar Foto con cámara
          </Button>
        )}
      </Stack>
    </Modal>
  );
  const Component = ({ icon: Icon, iconSize: S, title, value }: any) => (
    <Grid.Col span={6}>
      <Stack className={stylesVehicles.headerSectionInfo} p="sm" gap={8} flex={1}>
        <Group gap={8}>
          {Icon && <Icon size={S || 18} color="var(--text-secondary)" />}
          <Text fw={700} size="xs" c="var(--text-secondary)" tt="uppercase">
            {title}
          </Text>
        </Group>
        <Text fw={700} size="md" c="var(--text-primary)">
          {value || 'N/A'}
        </Text>
      </Stack>
    </Grid.Col>
  );
  return (
    <Stack flex={1} p="md">
      <Box className={stylesVehicles.headerSection}>
        <Title order={4} tt="uppercase" lts={0.7} ta="center">
          Perfil del Vehículo
        </Title>
      </Box>
      {vehicle ? (
        <>
          <Group w="100%" align="center" gap="sm" mt={20}>
            <Box className={stylesVehicles.avatar} flex={0.35}>
              <BackgroundImage
                src={vehicle.image || 'default-car.png'}
                radius="sm"
                onClick={() => setImageModalOpen(true)}
                ref={ref}
              >
                {hovered && (
                  <Center p="md" pt={76}>
                    <FaCamera size={140} color="var(--text-primary)" />
                  </Center>
                )}
              </BackgroundImage>
            </Box>
            <Grid flex={1} grow gutter="xs">
              <Component icon={FaCarBattery} iconSize={18} title="Bastidor" value={String(vehicle.chassis)} />
              <Component icon={FaCarSide} iconSize={21} title="Modelo" value={vehicle.model} />
              <Component icon={FaCreditCard} iconSize={17} title="Matrícula" value={vehicle.plate} />
              <Component icon={FaUser} iconSize={18} title="Propietario" value={vehicle.owner} />
              <Grid.Col span="auto" mt="sm">
                <Box
                  p="md"
                  className={
                    vehicle.incauted
                      ? `${stylesVehicles.incautedButton} ${stylesVehicles.incautedButtonActive}`
                      : stylesVehicles.incautedButton
                  }
                  onClick={handleClick}
                >
                  <Group align="center" justify="center" gap={8} p="xs">
                    <FaExclamationTriangle size={17} />
                    <Text
                      c={vehicle.incauted ? 'yellow.2' : 'var(--text-primary)'}
                      fw="bold"
                      tt="uppercase"
                      size="sm"
                    >
                      Vehículo Incautado
                    </Text>
                  </Group>
                </Box>
              </Grid.Col>
              <Grid.Col span="auto" mt="sm">
                <Box
                  p="md"
                  className={
                    vehicle.wanted
                      ? `${stylesVehicles.wantedButton} ${stylesVehicles.wantedButtonActive}`
                      : stylesVehicles.wantedButton
                  }
                  onClick={handleClick2}
                >
                  <Group align="center" justify="center" gap={8} p="xs">
                    <FaExclamationTriangle size={17} />
                    <Text
                      c={vehicle.wanted ? 'red' : 'var(--text-primary)'}
                      fw="bold"
                      tt="uppercase"
                      size="sm"
                    >
                      Vehículo Buscado
                    </Text>
                  </Group>
                </Box>
              </Grid.Col>
            </Grid>
          </Group>
          <VehicleDetails selectedVehicle={vehicle} setSelectedVehicle={setSelectedVehicle} />
          {imageModalOpen && <Component2 />}
        </>
      ) : (
        <Text mt={20} ta="center" c="var(--text-secondary)">
          Selecciona un vehículo para ver su información.
        </Text>
      )}
    </Stack>
  );
}
