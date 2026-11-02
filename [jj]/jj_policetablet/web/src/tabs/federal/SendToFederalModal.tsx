import { Button, Group, Modal, NumberInput, Stack, Text, TextInput } from '@mantine/core';
import { useState } from 'react';
import { FaClock, FaIdCard } from 'react-icons/fa';
import { fetchNui, isBrowser } from '../../utils/nui';
import styles from '../../styles/Form.module.css';

export function SendToFederalModal({ opened, onClose, onSuccess }: any) {
  const [search, setSearch] = useState<any>('');
  const [minutes, setMinutes] = useState<any>(10);
  const [loading, setLoading] = useState<any>(false);
  const [selectedCitizen, setSelectedCitizen] = useState<any>(null);
  const handleClose = () => {
    setSelectedCitizen(null);
    setSearch('');
    setMinutes(10);
    onClose();
  };
  const handleClick = async () => {
    setSelectedCitizen(null);
    if (!search.trim()) {
      setSelectedCitizen({
        type: 'error',
        text: 'Introduce la ID o CitizenID del jugador.',
      });
      return;
    }
    const time = Number(minutes);
    if (isNaN(time) || time < 1) {
      setSelectedCitizen({
        type: 'error',
        text: 'El tiempo mínimo debe ser 1 minuto.',
      });
      return;
    }
    setLoading(true);
    try {
      if (isBrowser()) {
        onSuccess(search.trim(), time);
        handleClose();
        return;
      }
      const response = await fetchNui('sendToFederal', {
        targetId: search.trim(),
        time,
      });
      if (response?.success) {
        onSuccess(search.trim(), time);
        handleClose();
      } else {
        setSelectedCitizen({
          type: 'error',
          text: response?.message || 'Error al enviar a federal.',
        });
      }
    } catch (error) {
      console.error('Error al enviar a federal:', error);
      setSelectedCitizen({
        type: 'error',
        text: 'Error de conexión.',
      });
    } finally {
      setLoading(false);
    }
  };
  return (
    <Modal
      opened={opened}
      onClose={handleClose}
      title="Enviar Ciudadano a Cárcel Federal"
      centered
      overlayProps={{
        backgroundOpacity: 0.55,
        blur: 3,
      }}
      styles={{
        header: {
          backgroundColor: 'var(--secondary-color)',
          color: 'var(--text-primary)',
        },
        content: {
          backgroundColor: 'var(--secondary-color)',
          color: 'var(--text-primary)',
          border: '1px solid var(--border-color)',
        },
        title: {
          fontWeight: 700,
          textTransform: 'uppercase',
          fontSize: '0.95rem',
        },
      }}
    >
      <Stack gap="md" mt="sm">
        {selectedCitizen && (
          <Text color={selectedCitizen.type === 'error' ? 'red' : 'green'} size="sm" fw={600}>
            {selectedCitizen.text}
          </Text>
        )}
        <TextInput
          label="ID o CitizenID del Ciudadano"
          placeholder="Ej: 1 (ID servidor) o CIT123456"
          value={search}
          onChange={(event) => setSearch(event.currentTarget.value)}
          required
          leftSection={<FaIdCard size={14} color="var(--text-secondary)" />}
          styles={{
            input: {
              backgroundColor: 'var(--primary-color)',
              color: 'var(--text-primary)',
              borderColor: 'var(--border-color)',
            },
            label: {
              color: 'var(--text-primary)',
              fontWeight: 600,
              fontSize: '0.85rem',
              marginBottom: 4,
            },
          }}
        />
        <NumberInput
          label="Tiempo de Condena (en minutos)"
          placeholder="Tiempo mínimo 1 minuto"
          min={1}
          value={minutes}
          onChange={(v) => setMinutes(v)}
          required
          leftSection={<FaClock size={14} color="var(--text-secondary)" />}
          styles={{
            input: {
              backgroundColor: 'var(--primary-color)',
              color: 'var(--text-primary)',
              borderColor: 'var(--border-color)',
            },
            label: {
              color: 'var(--text-primary)',
              fontWeight: 600,
              fontSize: '0.85rem',
              marginBottom: 4,
            },
          }}
        />
        <Group justify="flex-end" mt="md">
          <Button
            className={styles.button}
            tt="uppercase"
            lts={0.2}
            fw="bold"
            onClick={handleClick}
            loading={loading}
            size="sm"
          >
            Enviar a Federal
          </Button>
        </Group>
      </Stack>
    </Modal>
  );
}
