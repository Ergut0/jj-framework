import { Box, Center, Group, Loader, ScrollArea, Text, Title } from '@mantine/core';
import { useEffect, useState } from 'react';
import { mockCitizens } from '../../data/mockCitizens';
import { fetchNui, isBrowser } from '../../utils/nui';
import { CitizenDetails } from './CitizenDetails';
import { CitizenHeader } from './CitizenHeader';
import { CitizenList } from './CitizenList';
import styles from '../../styles/Citizens.module.css';

export function CitizenListEmpty() {
  return (
    <Center p="md" h="79vh" w="100%" mx="auto">
      <Loader size="lg" variant="dots" />
    </Center>
  );
}

export function CitizensTab({ initialCitizenId }: any) {
  const [filterCitizen, setFilterCitizen] = useState<any>('');
  const [citizens, setCitizens] = useState<any>(isBrowser() ? mockCitizens : null);
  const [selectedCitizen, setSelectedCitizen] = useState<any>(null);
  useEffect(() => {
    if (isBrowser()) {
      return;
    }
    (async () => {
      const response = await fetchNui('getCitizens');
      setCitizens(response);
    })();
  }, []);
  const handleSearch = async () => {
    const f = filterCitizen.toLowerCase();
    const response = await fetchNui('getCitizensByFilter', f);
    setCitizens(response);
  };
  const handleSelectCitizen = async (f) => {
    if (isBrowser()) {
      const p = mockCitizens.find((mockCitizen) => mockCitizen.citizenid === f);
      setSelectedCitizen(p ?? null);
      return;
    }
    const response = await fetchNui('getCitizenById', f);
    setSelectedCitizen(response);
  };
  useEffect(() => {
    if (initialCitizenId) {
      handleSelectCitizen(initialCitizenId);
    }
  }, [initialCitizenId]);
  return citizens ? (
    <>
      <Group justify="space-between" align="flex-start" gap={0}>
        <CitizenList
          filterCitizen={filterCitizen}
          setFilterCitizen={setFilterCitizen}
          citizens={citizens}
          onSearch={handleSearch}
          onSelectCitizen={handleSelectCitizen}
        />
        <Group justify="space-between" align="flex-start" flex={1} p="md">
          <Group align="center" justify="center" w="100%">
            <Box className={styles.headerSection}>
              <Title order={4} tt="uppercase" lts={0.7} ta="center">
                Perfil del Ciudadano
              </Title>
            </Box>
          </Group>
          <ScrollArea className={styles.scrollArea} w="100%" type="never">
            {selectedCitizen ? (
              <>
                <CitizenHeader selectedCitizen={selectedCitizen} setSelectedCitizen={setSelectedCitizen} />
                <CitizenDetails selectedCitizen={selectedCitizen} setSelectedCitizen={setSelectedCitizen} />
              </>
            ) : (
              <Text mt={20} ta="center" c="var(--text-secondary)">
                Selecciona un ciudadano para ver su información.
              </Text>
            )}
          </ScrollArea>
        </Group>
      </Group>
    </>
  ) : (
    <CitizenListEmpty />
  );
}
