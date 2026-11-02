import {
  ActionIcon,
  Badge,
  Box,
  Button,
  Group,
  Menu,
  Modal,
  NumberFormatter,
  NumberInput,
  ScrollArea,
  Stack,
  Table,
  Text,
  TextInput,
  Title,
  Tooltip,
} from '@mantine/core';
import { useIntersection } from '@mantine/hooks';
import { useEffect, useState } from 'react';
import { FaExclamationTriangle, FaGavel, FaMinus, FaPlus, FaSearch, FaTrash } from 'react-icons/fa';
import { FaEllipsisVertical, FaX } from 'react-icons/fa6';
import { useRecoilValue } from 'recoil';
import { agentAtom, chapterListAtom, penalCodeListAtom } from '../../state/atoms';
import stylesForm from '../../styles/Form.module.css';
import stylesCitizens from '../../styles/Citizens.module.css';

export const ARTICLES_PAGE_SIZE = 15;

export function AddBillsModal({ opened, onClose, onAddBills }: any) {
  const r = useRecoilValue<any>(penalCodeListAtom);
  const o = useRecoilValue<any>(chapterListAtom);
  const [search, setSearch] = useState<any>('');
  const [selectedBills, setSelectedBills] = useState<any>([]);
  const [id_article, setId_article] = useState<any>('');
  const [customTitle, setCustomTitle] = useState<any>('');
  const [customAmount, setCustomAmount] = useState<any>('');
  const b = useRecoilValue<any>(agentAtom);
  const agentName = b ? `${b.citizen.firstname} ${b.citizen.lastname}` : 'Sistema';
  const agentBadge = b?.badge_number ?? '';
  const j: any = {};
  o.forEach((item) => {
    j[item.id] = item.name;
  });
  const T = r.filter((item) => {
    const L = (item.chapter_id ? j[item.chapter_id] : item.category) || '';
    return (
      item.id_article.includes(search) ||
      item.article.toLowerCase().includes(search.toLowerCase()) ||
      item.description.toLowerCase().includes(search.toLowerCase()) ||
      L.toLowerCase().includes(search.toLowerCase())
    );
  });
  const [page, setPage] = useState<any>(1);
  const { ref: R, entry: I } = useIntersection({
    threshold: 0.5,
  });
  useEffect(() => {
    if (I?.isIntersecting) {
      setPage((O) => O + 1);
    }
  }, [I]);
  useEffect(() => {
    setPage(1);
  }, [search]);
  const B = T.slice(0, page * ARTICLES_PAGE_SIZE);
  const U = (O) => {
    const L: any = {
      id: Date.now(),
      id_article: O.id_article,
      title: O.article,
      amount: O.fine,
      date: new Date().toLocaleDateString('es-ES', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
      }),
      payed: false,
      agentName,
      agentBadge,
    };
    if (!selectedBills.some((selectedBill) => selectedBill.id_article === L.id_article)) {
      setSelectedBills((N) => [...N, L]);
    }
  };
  const F = () => {
    if (!id_article || !customTitle || !customAmount) {
      return;
    }
    const O: any = {
      id: Date.now(),
      id_article,
      title: customTitle,
      amount: Number(customAmount),
      date: new Date().toLocaleDateString('es-ES', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
      }),
      payed: false,
      agentName,
      agentBadge,
    };
    setSelectedBills((L) => [...L, O]);
    setId_article('');
    setCustomTitle('');
    setCustomAmount('');
  };
  const handleMultiply = (O, L) => {
    setSelectedBills((N) =>
      N.map((item) => {
        if (item.id_article === O) {
          const V = item.title.replace(/\s*\(x\d+\)/gi, '');
          return {
            ...item,
            title: `${V} (x${L})`,
            amount: item.amount * L,
            multAmount: L,
          };
        }
        return item;
      }),
    );
  };
  const handleAgravar = (O, L) => {
    setSelectedBills((N) =>
      N.map((item) => {
        if (item.id_article === O) {
          const V = item.title.replace(/\s*\((Atenuado|Agravado)\s+[^)]+\)/g, '');
          return {
            ...item,
            title: `${V} (Agravado ${L}%)`,
            amount: Math.round(item.amount * (1 + L / 100)),
            agvrAmount: L,
          };
        }
        return item;
      }),
    );
  };
  const handleAtenuar = (O, L) => {
    setSelectedBills((N) =>
      N.map((item) => {
        if (item.id_article === O) {
          const V = item.title.replace(/\s*\((Atenuado|Agravado)\s+[^)]+\)/g, '');
          return {
            ...item,
            title: `${V} (Atenuado ${L}%)`,
            amount: Math.max(0, Math.round(item.amount * (1 - L / 100))),
            atnrAmount: L,
          };
        }
        return item;
      }),
    );
  };
  const handleDelete = (O) => {
    setSelectedBills((L) => L.filter((item) => item.id_article !== O));
  };
  const handleToggleCod9 = (O) => {
    setSelectedBills((L) =>
      L.map((item) => {
        if (item.id_article === O) {
          const isCod9 = !item.isCod9;
          let V = item.title.replace(/\s*\(COD-9\)/gi, '');
          if (isCod9) {
            V = `${V} (COD-9)`;
          }
          return {
            ...item,
            title: V.trim(),
            isCod9,
          };
        }
        return item;
      }),
    );
  };
  const handleToggleSC = (O) => {
    setSelectedBills((L) =>
      L.map((item) => {
        if (item.id_article === O) {
          const isSC = !item.isSC;
          let V = item.title.replace(/\s*\(SC\)/gi, '');
          if (isSC) {
            V = `${V} (SC)`;
          }
          return {
            ...item,
            title: V.trim(),
            isSC,
          };
        }
        return item;
      }),
    );
  };
  const handleClick = () => {
    if (selectedBills.length === 0) {
      return;
    }
    const O: any = {
      id: Date.now(),
      id_article: selectedBills.map((selectedBill) => selectedBill.id_article).join('\n'),
      title: selectedBills.map((selectedBill) => selectedBill.title).join('\n'),
      amount: selectedBills.reduce((total, selectedBill) => total + selectedBill.amount, 0),
      date: new Date().toLocaleDateString('es-ES', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
      }),
      payed: false,
      agentName,
      agentBadge,
    };
    onAddBills([O]);
    setSelectedBills([]);
    onClose();
  };
  const D = ({
    item: O,
    onMultiply: L,
    onAgravar: N,
    onAtenuar: M,
    onToggleCod9: V,
    onToggleSC: Y,
    onDelete,
  }: any) => {
    const [modifierMode, setModifierMode] = useState<any>(null);
    const [change, setChange] = useState<any>(2);
    const [change2, setChange2] = useState<any>(10);
    const [change3, setChange3] = useState<any>(10);
    const Xe = (Ae) => setModifierMode((be) => (be === Ae ? null : Ae));
    const handleClose = () => setModifierMode(null);
    return (
      <Menu arrowPosition="center" withArrow closeOnItemClick={false} onClose={handleClose}>
        <Menu.Target>
          <ActionIcon color="white" variant="transparent">
            <FaEllipsisVertical size={14} />
          </ActionIcon>
        </Menu.Target>
        <Menu.Dropdown>
          <Menu.Item leftSection={<FaPlus size={12} />} onClick={() => Xe('agravar')}>
            Agravar
          </Menu.Item>
          {modifierMode === 'agravar' && (
            <Box px={8} pb={8} pt={4}>
              <NumberInput
                size="xs"
                placeholder="Porcentaje a agravar (%)"
                min={1}
                max={999}
                suffix="%"
                value={change2}
                onChange={setChange2}
                classNames={stylesForm}
              />
              <Button
                size="xs"
                fullWidth
                mt={6}
                className={stylesForm.button}
                onClick={() => {
                  N(O.id_article, Number(change2));
                  setModifierMode(null);
                }}
              >
                Confirmar
              </Button>
            </Box>
          )}
          <Menu.Item leftSection={<FaMinus size={12} />} onClick={() => Xe('atenuar')}>
            Atenuar
          </Menu.Item>
          {modifierMode === 'atenuar' && (
            <Box px={8} pb={8} pt={4}>
              <NumberInput
                size="xs"
                placeholder="Porcentaje a atenuar (%)"
                min={1}
                max={100}
                suffix="%"
                value={change3}
                onChange={setChange3}
                classNames={stylesForm}
              />
              <Button
                size="xs"
                fullWidth
                mt={6}
                className={stylesForm.button}
                onClick={() => {
                  M(O.id_article, Number(change3));
                  setModifierMode(null);
                }}
              >
                Confirmar
              </Button>
            </Box>
          )}
          <Menu.Item leftSection={<FaX size={12} />} onClick={() => Xe('multiplicar')}>
            Multiplicar
          </Menu.Item>
          {modifierMode === 'multiplicar' && (
            <Box px={8} pb={8} pt={4}>
              <NumberInput
                size="xs"
                placeholder="Cantidad a multiplicar"
                prefix="x"
                min={1}
                max={99}
                value={change}
                onChange={setChange}
                classNames={stylesForm}
              />
              <Button
                size="xs"
                fullWidth
                mt={6}
                className={stylesForm.button}
                onClick={() => {
                  L(O.id_article, Number(change));
                  setModifierMode(null);
                }}
              >
                Confirmar
              </Button>
            </Box>
          )}
          <Menu.Item leftSection={<FaExclamationTriangle size={12} />} onClick={() => V(O.id_article)}>
            {O.isCod9 ? 'Quitar COD-9' : 'Marcar COD-9'}
          </Menu.Item>
          <Menu.Item leftSection={<FaGavel size={12} />} onClick={() => Y(O.id_article)}>
            {O.isSC ? 'Quitar SC' : 'Marcar SC'}
          </Menu.Item>
          <Menu.Item leftSection={<FaTrash size={12} />} color="red" onClick={() => onDelete(O.id_article)}>
            Eliminar
          </Menu.Item>
        </Menu.Dropdown>
      </Menu>
    );
  };
  return (
    <>
      <Modal opened={opened} onClose={onClose} title="Añadir multa" size="90%" centered>
        <Group align="flex-start" mt="lg">
          <Stack flex="1">
            <Box>
              <Group
                justify="space-between"
                bg="dark.7"
                p="sm"
                style={{
                  borderRadius: '5px',
                }}
              >
                <Title order={3}>Listado de Articulos</Title>
                <TextInput
                  leftSection={<FaSearch />}
                  placeholder="Buscar articulo..."
                  w="30%"
                  classNames={stylesForm}
                  value={search}
                  onChange={(event) => setSearch(event.target.value)}
                />
              </Group>
              <ScrollArea offsetScrollbars scrollbarSize={4} mt="sm" h="55vh">
                <Table
                  captionSide="top"
                  className={stylesCitizens.table}
                  stickyHeader
                  horizontalSpacing="md"
                  verticalSpacing="md"
                >
                  <Table.Thead>
                    <Table.Tr>
                      <Table.Th>Nº</Table.Th>
                      <Table.Th>Artículo</Table.Th>
                      <Table.Th>Descripción</Table.Th>
                      <Table.Th>Multa</Table.Th>
                      <Table.Th>Accion</Table.Th>
                    </Table.Tr>
                  </Table.Thead>
                  <Table.Tbody>
                    {B.map((item, index) => (
                      <Table.Tr key={item.id} ref={index === B.length - 1 ? R : null}>
                        <Table.Td>{item.id_article}</Table.Td>
                        <Table.Td>{item.article}</Table.Td>
                        <Table.Td>{item.description}</Table.Td>
                        <Table.Td>
                          <NumberFormatter prefix={'$'} thousandSeparator value={item.fine} />
                        </Table.Td>
                        <Table.Td>
                          <Button
                            size="xs"
                            className={stylesForm.button}
                            tt="uppercase"
                            lts={0.2}
                            onClick={() => U(item)}
                          >
                            Agregar
                          </Button>
                        </Table.Td>
                      </Table.Tr>
                    ))}
                  </Table.Tbody>
                </Table>
              </ScrollArea>
            </Box>
            <Stack mt="md" gap="md">
              <Box
                bg="dark.7"
                p="sm"
                style={{
                  borderRadius: '5px',
                }}
              >
                <Title order={3}>Multa Personalizada</Title>
              </Box>
              <Group
                align="center"
                justify="space-between"
                bg="dark.8"
                p="md"
                style={{
                  borderRadius: '5px',
                }}
              >
                <TextInput
                  label="Nº de artículo"
                  placeholder="Número del artículo"
                  classNames={stylesForm}
                  value={id_article}
                  onChange={(event) => setId_article(event.target.value)}
                />
                <TextInput
                  flex="1"
                  label="Articulo"
                  placeholder="Nombre del artículo"
                  classNames={stylesForm}
                  value={customTitle}
                  onChange={(event) => setCustomTitle(event.target.value)}
                />
                <TextInput
                  label="Multa"
                  placeholder="Cantidad de la multa"
                  classNames={stylesForm}
                  value={customAmount}
                  onChange={(event) => setCustomAmount(event.target.value)}
                />
                <Button
                  size="md"
                  mt={20}
                  className={stylesForm.button}
                  tt="uppercase"
                  lts={0.2}
                  onClick={() => F()}
                >
                  Agregar
                </Button>
              </Group>
            </Stack>
          </Stack>
          <Stack flex="0.35" gap={13} className={stylesCitizens.stackBillsAdded}>
            <Title
              order={3}
              bg="dark.7"
              p="sm"
              style={{
                borderRadius: '5px',
              }}
            >
              Multas Agregadas
            </Title>
            <ScrollArea h="56.63vh" offsetScrollbars scrollbarSize={4} p={0} bg="dark.8">
              {selectedBills.length === 0 ? (
                <Stack
                  gap="sm"
                  p="md"
                  style={{
                    borderRadius: '5px',
                  }}
                >
                  <Text size="sm" c="dark.2" mx="auto">
                    No hay multas agregadas
                  </Text>
                </Stack>
              ) : (
                <Box
                  bg="dark.7"
                  style={{
                    borderRadius: '5px',
                    overflow: 'hidden',
                  }}
                >
                  <div className={stylesCitizens.billsArticleContainer}>
                    {selectedBills.map((selectedBill, index) => (
                      <div key={selectedBill.id_article} className={stylesCitizens.billArticleItem}>
                        <div className={stylesCitizens.billArticleContent}>
                          <div className={stylesCitizens.billArticleNumber}>{index + 1}</div>
                          <div className={stylesCitizens.billArticleInfo}>
                            <div className={stylesCitizens.billArticleNumber_}>
                              {'Art. '}
                              {selectedBill.id_article}
                            </div>
                            <div className={stylesCitizens.billArticleTitle}>{selectedBill.title}</div>
                          </div>
                        </div>
                        <Group gap="xs" className={stylesCitizens.billArticleAmount}>
                          <Badge variant="light" color="green" radius="sm" size="md">
                            <NumberFormatter value={selectedBill.amount} prefix={'$'} />
                          </Badge>
                          {selectedBill.multAmount && (
                            <Badge variant="light" color="blue" radius="sm" size="xs">
                              x{selectedBill.multAmount}
                            </Badge>
                          )}
                          {selectedBill.agvrAmount && (
                            <Badge variant="light" color="orange" radius="sm" size="xs">
                              +{selectedBill.agvrAmount}%
                            </Badge>
                          )}
                          {selectedBill.atnrAmount && (
                            <Badge variant="light" color="cyan" radius="sm" size="xs">
                              -{selectedBill.atnrAmount}%
                            </Badge>
                          )}
                          {selectedBill.isCod9 && (
                            <Badge variant="light" color="red" radius="sm" size="xs">
                              COD-9
                            </Badge>
                          )}
                          {selectedBill.isSC && (
                            <Badge variant="light" color="yellow" radius="sm" size="xs">
                              SC
                            </Badge>
                          )}
                          <Tooltip label="Opciones" withArrow color="dark.8">
                            <D
                              item={selectedBill}
                              onMultiply={handleMultiply}
                              onAgravar={handleAgravar}
                              onAtenuar={handleAtenuar}
                              onToggleCod9={handleToggleCod9}
                              onToggleSC={handleToggleSC}
                              onDelete={handleDelete}
                            />
                          </Tooltip>
                        </Group>
                      </div>
                    ))}
                  </div>
                </Box>
              )}
            </ScrollArea>
            <Stack>
              <Title
                order={3}
                bg="dark.7"
                p="sm"
                style={{
                  borderRadius: '5px',
                }}
              >
                Total
              </Title>
              <Stack
                justify="space-between"
                bg="dark.8"
                p="sm"
                style={{
                  borderRadius: '5px',
                }}
              >
                <Group justify="space-between">
                  <Text size="md" fw="bold">
                    Cantidad:{' '}
                    <NumberFormatter
                      color="green"
                      value={selectedBills.reduce((total, selectedBill) => total + selectedBill.amount, 0)}
                      prefix={'$'}
                    />
                  </Text>
                  <Text size="sm" fw="bold">
                    ({selectedBills.length} {selectedBills.length === 1 ? 'artículo' : 'artículos'})
                  </Text>
                </Group>
                <Button
                  size="sm"
                  className={stylesForm.button}
                  tt="uppercase"
                  lts={0.2}
                  onClick={handleClick}
                  disabled={selectedBills.length === 0}
                >
                  Añadir
                </Button>
              </Stack>
            </Stack>
          </Stack>
        </Group>
      </Modal>
    </>
  );
}
