import {
  Badge,
  Box,
  Button,
  Card,
  Group,
  Image,
  ScrollArea,
  Stack,
  Text,
  TextInput,
  Title,
} from '@mantine/core';
import { useEffect, useState } from 'react';
import { FaClock, FaIdCard, FaLock, FaPaperPlane, FaSearch, FaUnlock, FaUser } from 'react-icons/fa';
import { fetchNui, isBrowser, openEntityTab } from '../../utils/nui';
import { CitizenListEmpty } from '../citizens/CitizensTab';
import { SendToFederalModal } from './SendToFederalModal';
import stylesFederal from '../../styles/Federal.module.css';
import stylesForm from '../../styles/Form.module.css';

export const mockJailed = [
  {
    id: 1,
    citizenid: 'CIT123456',
    imageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
    firstname: 'Carlos',
    lastname: 'Santana',
    injail: 35,
  },
  {
    id: 2,
    citizenid: 'CIT123457',
    imageUrl: null,
    firstname: 'Maria',
    lastname: 'García',
    injail: 15,
  },
];

export function FederalTab() {
  const [jailed, setJailed] = useState<any>([]);
  const [loading, setLoading] = useState<any>(true);
  const [sendModalOpen, setSendModalOpen] = useState<any>(false);
  const [search, setSearch] = useState<any>('');
  const u = async () => {
    setLoading(true);
    try {
      if (isBrowser()) {
        setJailed(mockJailed);
        return;
      }
      const response = await fetchNui('getJailedPlayers');
      setJailed(Array.isArray(response) ? response : []);
    } catch (error) {
      console.error('Error al obtener encarcelados:', error);
    } finally {
      setLoading(false);
    }
  };
  useEffect(() => {
    u();
  }, []);
  const handleSuccess = (g, v) => {
    if (isBrowser()) {
      setJailed((y) => [
        ...y,
        {
          id: Date.now(),
          citizenid: g.toUpperCase(),
          imageUrl: null,
          firstname: 'Jugador',
          lastname: g,
          injail: v,
        },
      ]);
    } else {
      u();
    }
  };
  const h = async (g) => {
    try {
      if (isBrowser()) {
        setJailed((y) => y.filter((item) => item.citizenid !== g));
        return;
      }
      if (
        (
          await fetchNui('releaseJailedPlayer', {
            citizenid: g,
          })
        )?.success
      ) {
        await u();
      }
    } catch (error) {
      console.error('Error al liberar jugador:', error);
    }
  };
  const p = jailed.filter((item) => {
    if (!search.trim()) {
      return true;
    }
    const v = search.toLowerCase().trim();
    const y = `${item.firstname} ${item.lastname}`.toLowerCase();
    const b = (item.citizenid || '').toLowerCase();
    return y.includes(v) || b.includes(v);
  });
  return (
    <Box className={stylesFederal.container}>
      <Box className={stylesFederal.headerSection}>
        <Group justify="space-between" align="center" w="100%" wrap="wrap">
          <Group gap="xs">
            <FaLock size={24} color="var(--text-color)" />
            <Title order={3} className={stylesFederal.title}>
              Cárcel Federal
            </Title>
          </Group>
          <Group gap="sm" align="center">
            <TextInput
              placeholder="Buscar por nombre o ID..."
              value={search}
              onChange={(event) => setSearch(event.currentTarget.value)}
              leftSection={<FaSearch size={12} color="var(--text-secondary)" />}
              className={stylesFederal.searchInput}
              size="xs"
            />
            <Button
              leftSection={<FaPaperPlane size={14} />}
              className={stylesForm.button}
              onClick={() => setSendModalOpen(true)}
            >
              Enviar a Federal
            </Button>
          </Group>
        </Group>
      </Box>
      <SendToFederalModal
        opened={sendModalOpen}
        onClose={() => setSendModalOpen(false)}
        onSuccess={handleSuccess}
      />
      {loading ? (
        <CitizenListEmpty />
      ) : p.length > 0 ? (
        <ScrollArea h="76vh" offsetScrollbars scrollbarSize={3}>
          <Box className={stylesFederal.grid}>
            {p.map((item) => (
              <Card key={item.citizenid} className={stylesFederal.card} shadow="sm">
                <Box className={stylesFederal.avatarWrapper}>
                  <Image
                    src={item.imageUrl || 'default-user.webp'}
                    fallbackSrc="default-user.webp"
                    className={stylesFederal.avatar}
                    alt={`${item.firstname} ${item.lastname}`}
                  />
                </Box>
                <Stack
                  gap={4}
                  align="center"
                  style={{
                    width: '100%',
                  }}
                >
                  <Text className={stylesFederal.name}>
                    {item.firstname} {item.lastname}
                  </Text>
                  <Badge
                    variant="light"
                    color="dark.1"
                    radius="sm"
                    size="sm"
                    leftSection={<FaIdCard size={12} />}
                    className={stylesFederal.citizenid}
                  >
                    {item.citizenid}
                  </Badge>
                </Stack>
                <Box className={stylesFederal.jailSection}>
                  <Text className={stylesFederal.jailLabel}>Condena Restante</Text>
                  <Group gap={6} align="center" mt={2}>
                    <FaClock size={14} color="#ff6b6b" />
                    <Text className={stylesFederal.jailValue}>
                      {item.injail} {item.injail === 1 ? 'minuto' : 'minutos'}
                    </Text>
                  </Group>
                </Box>
                <Box className={stylesFederal.buttonGroup}>
                  <Button
                    leftSection={<FaUnlock size={12} />}
                    color="green"
                    variant="light"
                    size="xs"
                    className={stylesFederal.releaseButton}
                    onClick={() => h(item.citizenid)}
                  >
                    Liberar
                  </Button>
                  <Button
                    leftSection={<FaUser size={12} />}
                    size="xs"
                    className={`${stylesForm.button} ${stylesFederal.viewButton}`}
                    onClick={() =>
                      openEntityTab({
                        type: 'citizen',
                        citizenId: item.citizenid,
                      })
                    }
                  >
                    Ver
                  </Button>
                </Box>
              </Card>
            ))}
          </Box>
        </ScrollArea>
      ) : (
        <Box className={stylesFederal.noJailed}>
          <Text size="md" c="var(--text-secondary)" ta="center">
            No hay ningún ciudadano encarcelado que coincida con la búsqueda.
          </Text>
        </Box>
      )}
    </Box>
  );
}
