import {
  ActionIcon,
  Box,
  Button,
  Group,
  NumberFormatter,
  ScrollArea,
  Table,
  Text,
  TextInput,
  Tooltip,
} from '@mantine/core';
import { useDisclosure, useIntersection } from '@mantine/hooks';
import { useEffect, useState } from 'react';
import { FaPlus, FaSearch, FaTrash } from 'react-icons/fa';
import { FaFolderPlus, FaPencil, FaScaleBalanced } from 'react-icons/fa6';
import { useRecoilState } from 'recoil';
import { chapterListAtom, penalCodeListAtom, usePermissions } from '../../state/atoms';
import { fetchNui } from '../../utils/nui';
import { CitizenListEmpty } from '../citizens/CitizensTab';
import { AddArticleModal, AddChapterModal, EditArticleModal, EditChapterModal } from './PenalCodeModals';
import stylesPenalCode from '../../styles/PenalCode.module.css';
import stylesForm from '../../styles/Form.module.css';

export const PENAL_PAGE_SIZE = 15;

export function PenalCodeTab() {
  const { haveRankPerms } = usePermissions();
  const [t, n] = useRecoilState<any>(penalCodeListAtom);
  const [r, o] = useRecoilState<any>(chapterListAtom);
  const [opened, i] = useDisclosure(false);
  const [opened2, u] = useDisclosure(false);
  const [opened3, h] = useDisclosure(false);
  const [opened4, g] = useDisclosure(false);
  const [infoArticle, setInfoArticle] = useState<any>(null);
  const [chapter, setChapter] = useState<any>(null);
  const [search, setSearch] = useState<any>('');
  const [page, setPage] = useState<any>(1);
  const { ref: A, entry: R } = useIntersection({
    threshold: 0.5,
  });
  useEffect(() => {
    if (R?.isIntersecting) {
      setPage((L) => L + 1);
    }
  }, [R]);
  useEffect(() => {
    setPage(1);
  }, [search]);
  const handleAddChapter = async (L) => {
    u.close();
    const response = await fetchNui('createChapter', L);
    if (response && response.id) {
      o([...r, response]);
    } else {
      o([
        ...r,
        {
          id: Date.now(),
          name: L.toUpperCase(),
        },
      ]);
    }
  };
  const handleEditChapter = async (L, N) => {
    h.close();
    const name =
      (
        await fetchNui('updateChapter', {
          id: L,
          name: N,
        })
      )?.name || N.toUpperCase();
    o(
      r.map((item) =>
        item.id === L
          ? {
              ...item,
              name,
            }
          : item,
      ),
    );
  };
  const U = async (L) => {
    await fetchNui('deleteChapter', L);
    o(r.filter((item) => item.id !== L));
  };
  const handleAddArticle = async (L, N, M, V, Y) => {
    i.close();
    const newArticle: any = {
      id: t.length > 0 ? t[t.length - 1].id + 1 : 1,
      chapter_id: L,
      id_article: N,
      article: M,
      description: V,
      fine: Y,
    };
    const response = await fetchNui('createPenalCode', {
      newArticle,
    });
    newArticle.id = response?.id || newArticle.id;
    n([...t, newArticle]);
  };
  const handleEditArticle = async (L, N, M, V, Y) => {
    if (!infoArticle) {
      return;
    }
    const updatedArticle: any = {
      ...infoArticle,
      chapter_id: L,
      id_article: N,
      article: M,
      description: V,
      fine: Y,
    };
    const oe = t.map((item) => (item.id === infoArticle.id ? updatedArticle : item));
    await fetchNui('updatePenalCode', {
      id: infoArticle.id,
      updatedArticle,
    });
    n(oe);
    g.close();
  };
  const Z = async (L) => {
    await fetchNui('deletePenalCode', {
      id: L,
    });
    n(t.filter((item) => item.id !== L));
  };
  if (!t) {
    return <CitizenListEmpty />;
  }
  const J: any = {};
  r.forEach((item) => {
    J[item.id] = item.name;
  });
  const W = t
    .filter((item) => {
      const N = (item.chapter_id ? J[item.chapter_id] : item.category) || '';
      return (
        item.article.toLowerCase().includes(search.toLowerCase()) ||
        item.description.toLowerCase().includes(search.toLowerCase()) ||
        item.id_article.toLowerCase().includes(search.toLowerCase()) ||
        N.toLowerCase().includes(search.toLowerCase())
      );
    })
    .slice(0, page * PENAL_PAGE_SIZE);
  const $: any = {};
  r.forEach((item) => {
    $[item.id] = [];
  });
  W.forEach((item) => {
    const N = item.chapter_id || (r.length > 0 ? r[0].id : 1);
    if (!$[N]) {
      $[N] = [];
    }
    $[N].push(item);
  });
  let P = 0;
  const D = W.length;
  const O = [];
  r.forEach((item) => {
    const N = $[item.id] || [];
    if (!(
      search.trim() !== '' && !(N.length > 0 || item.name.toLowerCase().includes(search.toLowerCase()))
    )) {
      O.push(
        <Table.Tr key={`chapter-${item.id}`} className={stylesPenalCode.chapterRow}>
          <Table.Td colSpan={haveRankPerms(['penalcode.edit', 'penalcode.delete']) ? 5 : 4}>
            <Box
              pos="relative"
              py={4}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Group gap="xs" align="center">
                <Text className={stylesPenalCode.chapterTitle}>{item.name}</Text>
                {haveRankPerms(['penalcode.edit', 'penalcode.delete']) && (
                  <Group gap={4}>
                    {haveRankPerms(['penalcode.edit']) && (
                      <Tooltip label="Editar capítulo" color="var(--primary-color)" withArrow>
                        <ActionIcon
                          variant="transparent"
                          size="xs"
                          onClick={() => {
                            setChapter(item);
                            h.open();
                          }}
                        >
                          <FaPencil size={12} />
                        </ActionIcon>
                      </Tooltip>
                    )}
                    {haveRankPerms(['penalcode.delete']) && (
                      <Tooltip label="Eliminar capítulo" color="var(--primary-color)" withArrow>
                        <ActionIcon color="red.4" variant="transparent" size="xs" onClick={() => U(item.id)}>
                          <FaTrash size={12} />
                        </ActionIcon>
                      </Tooltip>
                    )}
                  </Group>
                )}
              </Group>
              <Text
                className={stylesPenalCode.chapterBadge}
                style={{
                  position: 'absolute',
                  right: 0,
                }}
              >
                {N.length} {N.length === 1 ? 'artículo' : 'artículos'}
              </Text>
            </Box>
          </Table.Td>
        </Table.Tr>,
      );
      if (N.length === 0) {
        O.push(
          <Table.Tr key={`empty-${item.id}`}>
            <Table.Td colSpan={haveRankPerms(['penalcode.edit', 'penalcode.delete']) ? 5 : 4}>
              <Text size="sm" c="dimmed" fs="italic" ta="center" py="xs">
                No hay artículos en este capítulo.
              </Text>
            </Table.Td>
          </Table.Tr>,
        );
      } else {
        N.forEach((item2) => {
          P++;
          O.push(
            <Table.Tr key={item2.id} ref={P === D ? A : null}>
              <Table.Td fw={600}>{item2.id_article}</Table.Td>
              <Table.Td fw={500}>{item2.article}</Table.Td>
              <Table.Td>{item2.description}</Table.Td>
              <Table.Td>
                <NumberFormatter prefix={'$'} thousandSeparator value={item2.fine} />
              </Table.Td>
              {haveRankPerms(['penalcode.edit', 'penalcode.delete']) && (
                <Table.Td>
                  <Group gap="xs">
                    {haveRankPerms(['penalcode.edit']) && (
                      <Tooltip label="Editar artículo" color="var(--primary-color)" withArrow>
                        <ActionIcon
                          color="blue.5"
                          variant="transparent"
                          size="xs"
                          onClick={() => {
                            setInfoArticle(item2);
                            g.open();
                          }}
                        >
                          <FaPencil size={13} />
                        </ActionIcon>
                      </Tooltip>
                    )}
                    {haveRankPerms(['penalcode.delete']) && (
                      <Tooltip label="Eliminar artículo" color="var(--primary-color)" withArrow>
                        <ActionIcon color="red.5" variant="transparent" size="xs" onClick={() => Z(item2.id)}>
                          <FaTrash size={13} />
                        </ActionIcon>
                      </Tooltip>
                    )}
                  </Group>
                </Table.Td>
              )}
            </Table.Tr>,
          );
        });
      }
    }
  });
  return (
    <>
      <Box px="md" mt="md">
        <Box className={stylesPenalCode.headerSection}>
          <Group justify="space-between" align="center" w="100%" wrap="wrap">
            <Group gap="xs">
              <FaScaleBalanced size={24} color="white" />
              <Text className={stylesPenalCode.title}>Código Penal</Text>
            </Group>
            <Group gap="sm" align="center">
              {haveRankPerms(['penalcode.create']) && (
                <>
                  <Button
                    className={stylesForm.button}
                    radius="sm"
                    leftSection={<FaFolderPlus size={13} />}
                    onClick={u.open}
                    size="xs"
                    variant="outline"
                  >
                    Añadir Capítulo
                  </Button>
                  <Button
                    className={stylesForm.button}
                    radius="sm"
                    leftSection={<FaPlus size={13} />}
                    onClick={i.open}
                    size="xs"
                  >
                    Añadir Artículo
                  </Button>
                </>
              )}
              <TextInput
                placeholder="Buscar artículo o capítulo..."
                leftSection={<FaSearch size={14} color="var(--text-secondary)" />}
                value={search}
                onChange={(event) => setSearch(event.currentTarget.value)}
                className={stylesPenalCode.searchInput}
                size="xs"
              />
            </Group>
          </Group>
        </Box>
        <Box mt="xl">
          <ScrollArea className={stylesPenalCode.scrollArea} offsetScrollbars scrollbarSize={4}>
            <Table
              bg="var(--secondary-color)"
              captionSide="top"
              className={stylesPenalCode.table}
              stickyHeader
              horizontalSpacing="md"
              verticalSpacing="md"
            >
              <Table.Thead>
                <Table.Tr>
                  <Table.Th>Nº Articulo</Table.Th>
                  <Table.Th>Artículo</Table.Th>
                  <Table.Th>Descripción</Table.Th>
                  <Table.Th>Multa</Table.Th>
                  {haveRankPerms(['penalcode.edit', 'penalcode.delete']) && <Table.Th>Acciones</Table.Th>}
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>{O}</Table.Tbody>
            </Table>
          </ScrollArea>
        </Box>
      </Box>
      {opened2 && <AddChapterModal opened={opened2} onClose={u.close} onAddChapter={handleAddChapter} />}
      {opened3 && (
        <EditChapterModal
          opened={opened3}
          onClose={h.close}
          chapter={chapter}
          onEditChapter={handleEditChapter}
        />
      )}
      {opened && (
        <AddArticleModal opened={opened} onClose={i.close} chapters={r} onAddArticle={handleAddArticle} />
      )}
      {opened4 && (
        <EditArticleModal
          opened={opened4}
          onClose={g.close}
          infoArticle={infoArticle}
          chapters={r}
          onEditArticle={handleEditArticle}
        />
      )}
    </>
  );
}
