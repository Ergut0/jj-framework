import { useEffect } from 'react';
import { Box, Center, Stack, Text } from '@mantine/core';
import { useSetAtom } from 'jotai';
import { useNavigate } from 'react-router';
import { fetchNui, isBrowser } from '../lib/nui';
import { charactersAtom, slotsUnlockedAtom, zonesAtom, type Character, type Zone } from '../store';
import classes from './Loading.module.css';

const LOADING_TIME = 6000;

interface AllData {
  characters?: Character[];
  zones?: Zone[];
  slotsUnlocked?: number;
}

export function Loading() {
  const navigate = useNavigate();
  const setCharacters = useSetAtom(charactersAtom);
  const setZones = useSetAtom(zonesAtom);
  const setSlots = useSetAtom(slotsUnlockedAtom);

  useEffect(() => {
    const timer = setTimeout(() => navigate('/characters'), LOADING_TIME);

    if (!isBrowser()) {
      fetchNui<AllData>('getAllData').then((data) => {
        if (!data) return;
        setCharacters(data.characters || []);
        setZones(data.zones || []);
        setSlots(data.slotsUnlocked || 1);
      });
    }

    return () => clearTimeout(timer);
  }, [navigate, setCharacters, setSlots, setZones]);

  return (
    <Box className={classes.container}>
      <Box className={classes.background}>
        <video src="video.mp4" autoPlay muted loop playsInline className={classes.player} />
      </Box>
      <Box className={classes.overlay} />
      <Center className={classes.content}>
        <Stack align="center" gap="lg">
          <Box className={classes.loader} />
          <Text c="white" size="lg" tt="uppercase" fw="bold" lts={0.8}>
            Cargando tus personajes...
          </Text>
        </Stack>
      </Center>
    </Box>
  );
}
