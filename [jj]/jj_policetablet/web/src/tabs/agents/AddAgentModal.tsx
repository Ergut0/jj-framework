import { Button, Modal, Stack, TextInput } from '@mantine/core';
import { useState } from 'react';
import { fetchNui } from '../../utils/nui';
import styles from '../../styles/Form.module.css';

export function AddAgentModal({ opened, onClose, onAgentAdded }: any) {
  const [sourceId, setSourceId] = useState<any>('');
  const [loading, setLoading] = useState<any>(false);
  const handleClick = async () => {
    if (sourceId.trim()) {
      setLoading(true);
      try {
        if (
          await fetchNui('addAgentBySourceId', {
            sourceId: parseInt(sourceId),
          })
        ) {
          if (onAgentAdded) {
            onAgentAdded();
          }
          setSourceId('');
          onClose();
        }
      } catch (error) {
        console.error('Error adding agent:', error);
      } finally {
        setLoading(false);
      }
    }
  };
  return (
    <Modal title="Asignar Agente" opened={opened} onClose={onClose} centered size="sm">
      <Stack gap="md">
        <TextInput
          label="ID de (Jugador)"
          placeholder="Ej: 1"
          value={sourceId}
          onChange={(event) => setSourceId(event.currentTarget.value)}
          type="number"
        />
        <Button
          className={styles.button}
          onClick={handleClick}
          loading={loading}
          disabled={loading || !sourceId.trim()}
        >
          Asignar
        </Button>
      </Stack>
    </Modal>
  );
}
