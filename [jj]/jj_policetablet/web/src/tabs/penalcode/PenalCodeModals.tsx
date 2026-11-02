import { Button, Modal, NumberInput, Select, Stack, TextInput, Textarea } from '@mantine/core';
import { useEffect, useState } from 'react';
import styles from '../../styles/Form.module.css';

export const AddArticleModal = ({ opened, onClose, chapters, onAddArticle }: any) => {
  const [change, setChange] = useState<any>(chapters.length > 0 ? String(chapters[0].id) : null);
  const [idArticle, setIdArticle] = useState<any>('');
  const [article, setArticle] = useState<any>('');
  const [description, setDescription] = useState<any>('');
  const [change2, setChange2] = useState<any>(0);
  const handleClick = () => {
    if (!(!idArticle.trim() || !article.trim() || !description.trim() || !change)) {
      onAddArticle(Number(change), idArticle, article, description, Number(change2));
      setIdArticle('');
      setArticle('');
      setDescription('');
      setChange2(0);
      onClose();
    }
  };
  const b = chapters.map((chapter) => ({
    value: String(chapter.id),
    label: chapter.name,
  }));
  return (
    <Modal opened={opened} onClose={onClose} title="Añadir Artículo" centered>
      <Stack gap="lg" p={2} pt={10}>
        <Select
          classNames={styles}
          label="Capítulo"
          placeholder="Selecciona un capítulo"
          required
          data={b}
          value={change}
          onChange={setChange}
          allowDeselect={false}
          searchable
        />
        <TextInput
          classNames={styles}
          label="Id artículo"
          placeholder="Id del artículo (ej: 1.01)"
          required
          value={idArticle}
          onChange={(event) => setIdArticle(event.target.value)}
        />
        <TextInput
          classNames={styles}
          label="Artículo"
          placeholder="Nombre del artículo"
          required
          value={article}
          onChange={(event) => setArticle(event.target.value)}
        />
        <Textarea
          classNames={styles}
          label="Descripción"
          placeholder="Descripción del artículo"
          autosize
          required
          value={description}
          onChange={(event) => setDescription(event.target.value)}
        />
        <NumberInput
          classNames={styles}
          label="Multa"
          placeholder="Multa del artículo"
          required
          allowNegative={false}
          min={0}
          value={change2}
          onChange={setChange2}
        />
        <Button className={styles.button} onClick={handleClick} variant="light">
          Guardar Artículo
        </Button>
      </Stack>
    </Modal>
  );
};

export const AddChapterModal = ({ opened, onClose, onAddChapter }: any) => {
  const [name, setName] = useState<any>('');
  const handleClick = () => {
    if (name.trim()) {
      onAddChapter(name.trim().toUpperCase());
      setName('');
      onClose();
    }
  };
  return (
    <Modal opened={opened} onClose={onClose} title="Añadir Capítulo" centered>
      <Stack gap="lg" p={2} pt={10}>
        <TextInput
          classNames={styles}
          label="Nombre del Capítulo"
          placeholder="Ej: CAPITULO 3 DELITOS DE TRAFICO"
          required
          value={name}
          onChange={(event) => setName(event.target.value)}
        />
        <Button className={styles.button} onClick={handleClick} variant="light">
          Guardar Capítulo
        </Button>
      </Stack>
    </Modal>
  );
};

export const EditChapterModal = ({ opened, onClose, chapter, onEditChapter }: any) => {
  const [name, setName] = useState<any>(chapter?.name || '');
  useEffect(() => {
    if (chapter) {
      setName(chapter.name);
    }
  }, [chapter]);
  const handleClick = () => {
    if (!(!name.trim() || !chapter)) {
      onEditChapter(chapter.id, name.trim().toUpperCase());
      onClose();
    }
  };
  return (
    <Modal opened={opened} onClose={onClose} title="Editar Capítulo" centered>
      <Stack gap="lg" p={2} pt={10}>
        <TextInput
          classNames={styles}
          label="Nombre del Capítulo"
          placeholder="Ej: CAPITULO 3 DELITOS DE TRAFICO"
          required
          value={name}
          onChange={(event) => setName(event.target.value)}
        />
        <Button className={styles.button} onClick={handleClick} variant="light">
          Guardar Capítulo
        </Button>
      </Stack>
    </Modal>
  );
};

export const EditArticleModal = ({ opened, onClose, infoArticle, chapters, onEditArticle }: any) => {
  const [change, setChange] = useState<any>(
    infoArticle?.chapter_id
      ? String(infoArticle.chapter_id)
      : chapters.length > 0
        ? String(chapters[0].id)
        : null,
  );
  const [idArticle, setIdArticle] = useState<any>(infoArticle ? infoArticle.id_article : '');
  const [article, setArticle] = useState<any>(infoArticle ? infoArticle.article : '');
  const [description, setDescription] = useState<any>(infoArticle ? infoArticle.description : '');
  const [change2, setChange2] = useState<any>(infoArticle ? infoArticle.fine : 0);
  const handleClick = () => {
    if (!(!idArticle.trim() || !article.trim() || !description.trim() || !change)) {
      onEditArticle(Number(change), idArticle, article, description, Number(change2));
      onClose();
    }
  };
  const S = chapters.map((chapter) => ({
    value: String(chapter.id),
    label: chapter.name,
  }));
  return (
    <Modal opened={opened} onClose={onClose} title="Editar Artículo" centered>
      <Stack gap="lg" p={2} pt={10}>
        <Select
          classNames={styles}
          label="Capítulo"
          placeholder="Selecciona un capítulo"
          required
          data={S}
          value={change}
          onChange={setChange}
          allowDeselect={false}
          searchable
        />
        <TextInput
          classNames={styles}
          label="Id artículo"
          placeholder="Id del artículo"
          required
          value={idArticle}
          onChange={(event) => setIdArticle(event.target.value)}
        />
        <TextInput
          classNames={styles}
          label="Artículo"
          placeholder="Nombre del artículo"
          required
          value={article}
          onChange={(event) => setArticle(event.target.value)}
        />
        <Textarea
          classNames={styles}
          label="Descripción"
          placeholder="Descripción del artículo"
          autosize
          required
          value={description}
          onChange={(event) => setDescription(event.target.value)}
        />
        <NumberInput
          classNames={styles}
          label="Multa"
          placeholder="Multa del artículo"
          required
          allowNegative={false}
          min={0}
          value={change2}
          onChange={setChange2}
        />
        <Button className={styles.button} onClick={handleClick} variant="light">
          Guardar Artículo
        </Button>
      </Stack>
    </Modal>
  );
};
