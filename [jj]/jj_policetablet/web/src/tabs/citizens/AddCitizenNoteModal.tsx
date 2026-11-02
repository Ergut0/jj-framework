import { Button, Modal, Stack, TextInput, Textarea } from '@mantine/core';
import { useState } from 'react';
import styles from '../../styles/Form.module.css';

export const AddCitizenNoteModal = ({ opened, onClose, citizen, onAddNote }: any) => {
  const [title, setTitle] = useState<any>('');
  const [description, setDescription] = useState<any>('');
  const handleClick = () => {
    if (!(!title.trim() || !description.trim())) {
      onAddNote(title, description);
      setTitle('');
      setDescription('');
      onClose();
    }
  };
  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title={`Añadir Nota - ${citizen?.firstname} ${citizen?.lastname}`}
      centered
    >
      <Stack gap="lg" p={2} pt={10}>
        <TextInput
          classNames={styles}
          label="Título"
          placeholder="Título de la nota"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
        />
        <Textarea
          classNames={styles}
          label="Descripción"
          placeholder="Descripción de la nota"
          minRows={4}
          value={description}
          onChange={(event) => setDescription(event.target.value)}
        />
        <Button className={styles.button} onClick={handleClick} variant="light">
          Guardar Nota
        </Button>
      </Stack>
    </Modal>
  );
};
