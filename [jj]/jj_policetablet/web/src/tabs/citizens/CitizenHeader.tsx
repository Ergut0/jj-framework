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
  Tooltip,
} from '@mantine/core';
import { useHover } from '@mantine/hooks';
import { useState } from 'react';
import {
  FaArrowRight,
  FaBirthdayCake,
  FaCamera,
  FaExclamationTriangle,
  FaGlobe,
  FaIdCard,
  FaPhoneAlt,
  FaSearch,
  FaUser,
  FaVenusMars,
  FaWarehouse,
} from 'react-icons/fa';
import { usePermissions } from '../../state/atoms';
import { fetchNui } from '../../utils/nui';
import stylesForm from '../../styles/Form.module.css';
import stylesCitizens from '../../styles/Citizens.module.css';

export const CitizenHeader = ({ selectedCitizen, setSelectedCitizen }: any) => {
  const [imageModalOpen, setImageModalOpen] = useState<any>(false);
  const [imageUrl, setImageUrl] = useState<any>('');
  const { hovered, ref } = useHover();
  const { haveRankPerms } = usePermissions();
  const handleClick = async () => {
    if (selectedCitizen) {
      setSelectedCitizen({
        ...selectedCitizen,
        isWanted: !selectedCitizen.isWanted,
      });
      await fetchNui('toggleWantedStatus', {
        citizenid: selectedCitizen.citizenid,
      });
    }
  };
  const handleClick2 = async () => {
    if (selectedCitizen) {
      setSelectedCitizen({
        ...selectedCitizen,
        isDangerous: !selectedCitizen.isDangerous,
      });
      await fetchNui('toggleDangerousStatus', {
        citizenid: selectedCitizen.citizenid,
      });
    }
  };
  const handleClick3 = async () => {
    if (selectedCitizen?.citizenid) {
      await fetchNui('openCitizenInventory', {
        citizenid: selectedCitizen.citizenid,
      });
    }
  };
  const handleClick4 = async () => {
    if (selectedCitizen) {
      setSelectedCitizen({
        ...selectedCitizen,
        imageUrl,
      });
      setImageModalOpen(false);
      await fetchNui('updateCitizenImage', {
        citizenid: selectedCitizen.citizenid,
        imageUrl,
      });
    }
  };
  const handleClick5 = async () => {
    setImageModalOpen(false);
    const imageUrl2 = await fetchNui('takeCitizenPhoto', {
      citizenid: selectedCitizen.citizenid,
    });
    if (imageUrl2) {
      setSelectedCitizen({
        ...selectedCitizen,
        imageUrl: imageUrl2,
      });
    }
  };
  const Component2 = () => (
    <Modal
      opened={imageModalOpen}
      onClose={() => setImageModalOpen(false)}
      size="md"
      title="Actualizar Imagen del Ciudadano"
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
            onClick={handleClick4}
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
            onClick={handleClick5}
          >
            Realizar Foto con cámara
          </Button>
        )}
      </Stack>
    </Modal>
  );
  const Component = ({ icon: S, iconSize, title, value: T, onClick: E, tooltip: A }: any) => {
    const R = (
      <Stack
        className={E ? stylesCitizens.headerSectionInfoClickable : stylesCitizens.headerSectionInfo}
        p="sm"
        gap={8}
        flex={1}
        onClick={E}
      >
        <Group gap={8}>
          {S && <S size={iconSize || 18} color="var(--text-secondary)" />}
          <Text fw={700} size="xs" c="var(--text-secondary)" tt="uppercase">
            {title}
          </Text>
        </Group>
        <Text fw={700} size="md" c="var(--text-primary)">
          {T}
        </Text>
      </Stack>
    );
    return (
      <Grid.Col span={4}>
        {A ? (
          <Tooltip label={A} position="top" withArrow bg="dark.6" c="white">
            {R}
          </Tooltip>
        ) : (
          R
        )}
      </Grid.Col>
    );
  };
  return (
    <>
      <Group w="100%" align="center" gap="sm" mt={20}>
        <Box className={stylesCitizens.avatar} flex={0.35}>
          <BackgroundImage
            src={selectedCitizen?.imageUrl || 'default-user.webp'}
            radius="sm"
            onClick={() => setImageModalOpen(true)}
            ref={ref}
          >
            {hovered && (
              <Center className={stylesCitizens.avatarOverlay}>
                <FaCamera size={64} color="var(--text-primary)" />
              </Center>
            )}
          </BackgroundImage>
        </Box>
        <Grid flex={1} grow gutter="xs">
          <Component icon={FaIdCard} iconSize={18} title="Id Ciudadano" value={selectedCitizen?.citizenid} />
          <Component
            icon={FaUser}
            iconSize={18}
            title="Nombre"
            value={selectedCitizen?.firstname + ' ' + selectedCitizen?.lastname}
          />
          <Component
            icon={FaPhoneAlt}
            iconSize={18}
            title="Telefono"
            value={selectedCitizen?.phoneNumber || 'Sin línea registrada'}
            tooltip={selectedCitizen?.phoneNumber ? 'Llamar al ciudadano' : undefined}
            onClick={
              selectedCitizen?.phoneNumber
                ? () => {
                    fetchNui('callPhoneNumber', {
                      phoneNumber: selectedCitizen.phoneNumber,
                    });
                  }
                : undefined
            }
          />
          <Component icon={FaGlobe} iconSize={18} title="Nacionalidad" value={selectedCitizen?.nationality} />
          <Component
            icon={FaBirthdayCake}
            iconSize={18}
            title="Nacimiento"
            value={selectedCitizen?.dateofbirth}
          />
          <Component icon={FaVenusMars} iconSize={18} title="Genero" value={selectedCitizen?.gender} />
          <Grid.Col span={4}>
            <Box
              p="sm"
              className={
                selectedCitizen?.isDangerous
                  ? `${stylesCitizens.dangerButton} ${stylesCitizens.dangerButtonActive}`
                  : stylesCitizens.dangerButton
              }
              onClick={handleClick2}
            >
              <Group align="center" justify="center" gap={8} p="xs">
                <FaExclamationTriangle size={17} />
                <Text
                  c={selectedCitizen?.isDangerous ? 'red' : 'var(--text-primary)'}
                  fw="bold"
                  tt="uppercase"
                  size="sm"
                >
                  Sujeto Peligroso
                </Text>
              </Group>
            </Box>
          </Grid.Col>
          <Grid.Col span={4}>
            <Box
              p="sm"
              ta="center"
              className={
                selectedCitizen?.isWanted
                  ? `${stylesCitizens.searchButton} ${stylesCitizens.searchButtonActive}`
                  : stylesCitizens.searchButton
              }
              onClick={handleClick}
            >
              <Group align="center" justify="center" gap={9} p="xs">
                <FaSearch size={17} />
                <Text
                  c={selectedCitizen?.isWanted ? 'yellow.2' : 'var(--text-primary)'}
                  fw="bold"
                  tt="uppercase"
                  size="sm"
                >
                  Sujeto en Búsqueda y Captura
                </Text>
              </Group>
            </Box>
          </Grid.Col>
          <Grid.Col span={12}>
            <Box p="sm" ta="center" className={stylesCitizens.inventoryButton} onClick={handleClick3}>
              <Group align="center" justify="center" gap={9} p="xs">
                <FaWarehouse size={17} />
                <Text c="var(--text-primary)" fw="bold" tt="uppercase" size="sm">
                  Cajón de Evidencias
                </Text>
              </Group>
            </Box>
          </Grid.Col>
        </Grid>
      </Group>
      {imageModalOpen && <Component2 />}
    </>
  );
};
