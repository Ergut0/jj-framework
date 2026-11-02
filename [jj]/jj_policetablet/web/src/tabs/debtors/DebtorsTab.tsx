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
import { useIntersection } from '@mantine/hooks';
import { useEffect, useState } from 'react';
import { FaDollarSign, FaIdCard, FaUser } from 'react-icons/fa';
import { FaMoneyBillWave } from 'react-icons/fa6';
import { fetchNui, isBrowser, openEntityTab } from '../../utils/nui';
import { CitizenListEmpty } from '../citizens/CitizensTab';
import stylesDebtors from '../../styles/Debtors.module.css';
import stylesForm from '../../styles/Form.module.css';

export const mockDebtors = [
  {
    id: 1,
    citizenid: 'CIT123456',
    imageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
    firstname: 'John',
    lastname: 'Doe',
    debt: 99999,
  },
  {
    id: 2,
    citizenid: 'CIT123457',
    imageUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
    firstname: 'Jane',
    lastname: 'Smith',
    debt: 3499,
  },
  {
    id: 3,
    citizenid: 'CIT123459',
    imageUrl: null,
    firstname: 'Carlos',
    lastname: 'Mendoza',
    debt: 12500,
  },
  {
    id: 4,
    citizenid: 'CIT123460',
    imageUrl: 'https://randomuser.me/api/portraits/men/4.jpg',
    firstname: 'Alejandro',
    lastname: 'Gómez',
    debt: 1200,
  },
];

export const DEBTORS_PAGE_SIZE = 15;

export function DebtorsTab() {
  const [debtors, setDebtors] = useState<any>([]);
  const [minDebt, setMinDebt] = useState<any>('');
  const [hasMore, setHasMore] = useState<any>(true);
  const [page, setPage] = useState<any>(1);
  const { ref, entry } = useIntersection({
    threshold: 0.5,
  });
  const h = async () => {
    setHasMore(true);
    try {
      if (isBrowser()) {
        setDebtors(mockDebtors.slice(0, 20));
        return;
      }
      const response = await fetchNui('getDebtors');
      setDebtors(Array.isArray(response) ? response : []);
    } catch (error) {
      console.error('Error fetching debtors:', error);
    } finally {
      setHasMore(false);
    }
  };
  const handleClick = async () => {
    setHasMore(true);
    let minDebt2 = minDebt === '' ? 1e4 : minDebt;
    if (minDebt2 < 1e4) {
      minDebt2 = 1e4;
      setMinDebt(1e4);
    }
    try {
      if (isBrowser()) {
        setDebtors(mockDebtors.filter((mockDebtor) => mockDebtor.debt >= minDebt2));
        return;
      }
      const response = await fetchNui('getDebtorsByFilter', {
        minDebt: minDebt2,
      });
      setDebtors(Array.isArray(response) ? response : []);
    } catch (error) {
      console.error('Error fetching filtered debtors:', error);
    } finally {
      setHasMore(false);
    }
  };
  useEffect(() => {
    if (entry?.isIntersecting) {
      setPage((y) => y + 1);
    }
  }, [entry]);
  useEffect(() => {
    setPage(1);
  }, [debtors]);
  useEffect(() => {
    h();
  }, []);
  const g = (y) =>
    new Intl.NumberFormat('es-ES', {
      style: 'currency',
      currency: 'USD',
      maximumFractionDigits: 0,
    }).format(y);
  const v = debtors.slice(0, page * DEBTORS_PAGE_SIZE);
  return (
    <Box className={stylesDebtors.container}>
      <Box className={stylesDebtors.headerSection}>
        <Group justify="space-between" align="center" w="100%" wrap="wrap">
          <Group gap="xs">
            <FaMoneyBillWave size={24} />
            <Title order={3} className={stylesDebtors.title}>
              Deudores
            </Title>
          </Group>
          <Group gap="sm" align="flex-end">
            <TextInput
              placeholder="Cantidad mínima a buscar"
              type="number"
              value={minDebt}
              leftSection={<FaDollarSign size={12} color="var(--text-secondary)" />}
              onChange={(event) =>
                setMinDebt(event.currentTarget.value === '' ? '' : Number(event.currentTarget.value))
              }
              className={stylesDebtors.minDebtInput}
              size="xs"
            />
            <Button className={stylesForm.button} onClick={handleClick}>
              Filtrar
            </Button>
          </Group>
        </Group>
      </Box>
      {hasMore ? (
        <CitizenListEmpty />
      ) : v.length > 0 ? (
        <ScrollArea h="76vh" offsetScrollbars scrollbarSize={3}>
          <Box className={stylesDebtors.grid}>
            {v.map((item, index) => (
              <Card
                key={item.citizenid}
                className={stylesDebtors.card}
                shadow="sm"
                ref={index === v.length - 1 ? ref : null}
              >
                <Box className={stylesDebtors.avatarWrapper}>
                  <Image
                    src={item.imageUrl || 'default-user.webp'}
                    fallbackSrc="default-user.webp"
                    className={stylesDebtors.avatar}
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
                  <Text className={stylesDebtors.name}>
                    {item.firstname} {item.lastname}
                  </Text>
                  <Badge
                    variant="light"
                    color="dark.1"
                    radius="sm"
                    size="sm"
                    leftSection={<FaIdCard size={12} />}
                    className={stylesDebtors.citizenid}
                  >
                    {item.citizenid}
                  </Badge>
                </Stack>
                <Box className={stylesDebtors.debtSection}>
                  <Text className={stylesDebtors.debtLabel}>Deuda Pendiente</Text>
                  <Text className={stylesDebtors.debtValue}>{g(item.debt)}</Text>
                </Box>
                <Button
                  leftSection={<FaUser size={12} />}
                  className={`${stylesForm.button} ${stylesDebtors.actionButton}`}
                  onClick={() =>
                    openEntityTab({
                      type: 'citizen',
                      citizenId: item.citizenid,
                    })
                  }
                >
                  Ver ciudadano
                </Button>
              </Card>
            ))}
          </Box>
        </ScrollArea>
      ) : (
        <Box className={stylesDebtors.noDebtors}>
          <Text size="md" c="var(--text-secondary)" ta="center">
            No se encontraron ciudadanos que coincidan con los criterios de búsqueda.
          </Text>
        </Box>
      )}
    </Box>
  );
}
