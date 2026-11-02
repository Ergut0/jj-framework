import { Badge, Box, Button, Group, Image, ScrollArea, Stack, Text, TextInput } from '@mantine/core';
import { FaIdCard, FaPhone, FaSearch, FaUsers as FaUsers2 } from 'react-icons/fa';
import styles from '../../styles/Citizens.module.css';

export function CitizenList({ filterCitizen, setFilterCitizen, citizens, onSearch, onSelectCitizen }: any) {
  return (
    <Box className={styles.searchContainer}>
      <Text fw={700} size="lg" mb="md" className={styles.title}>
        <FaUsers2
          size={28}
          style={{
            marginRight: 8,
          }}
        />
        Búsqueda de Ciudadanos
      </Text>
      <Group gap="xs" mb="lg">
        <TextInput
          placeholder="ID o Nombre y Apellidos"
          className={styles.searchInput}
          size="sm"
          value={filterCitizen}
          onKeyDown={(event) => {
            if (event.key === 'Enter') {
              onSearch();
            }
          }}
          onChange={(event) => setFilterCitizen(event.target.value)}
        />
        <Button size="sm" variant="default" onClick={onSearch}>
          <FaSearch />
        </Button>
      </Group>
      <ScrollArea className={styles.scrollAreaSearch} w="100%" type="never">
        <Stack gap="xs">
          {citizens.map((citizen) => (
            <Box
              key={citizen.id}
              className={styles.citizenCard}
              onClick={() => onSelectCitizen(citizen.citizenid)}
            >
              <Group wrap="nowrap" gap="md" align="flex-start">
                <Image
                  fallbackSrc="default-user.webp"
                  src={citizen.imageUrl}
                  className={styles.citizenCardAvatar}
                  radius="sm"
                />
                <Stack gap={9}>
                  <Group justify="space-between" wrap="nowrap">
                    <Text fw={600} size="lg" c="var(--text-primary)">
                      {citizen.firstname} {citizen.lastname}
                    </Text>
                  </Group>
                  <Group gap="sm" wrap="nowrap">
                    <Badge
                      color="dark.2"
                      variant="light"
                      c="dark.1"
                      radius="sm"
                      leftSection={<FaPhone size={12} />}
                    >
                      {citizen.phoneNumber || 'Sin línea'}
                    </Badge>
                    <Badge
                      color="dark.2"
                      variant="light"
                      c="dark.1"
                      radius="sm"
                      leftSection={<FaIdCard size={12} />}
                    >
                      {citizen.citizenid}
                    </Badge>
                  </Group>
                </Stack>
              </Group>
            </Box>
          ))}
        </Stack>
      </ScrollArea>
    </Box>
  );
}
