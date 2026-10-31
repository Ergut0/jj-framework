import { useState } from 'react';
import { Box, UnstyledButton } from '@mantine/core';
import { useAtomValue } from 'jotai';
import { CharacterForm } from '../components/CharacterForm';
import { CharacterItem } from '../components/CharacterItem';
import { fetchNui, isBrowser, useNuiEvent } from '../lib/nui';
import { activeCharacterAtom, charactersAtom, creatingAtom, slotsUnlockedAtom } from '../store';
import classes from './Characters.module.css';

const TOTAL_SLOTS = 5;

export function Characters() {
  const characters = useAtomValue(charactersAtom);
  const creating = useAtomValue(creatingAtom);
  const activeCharacter = useAtomValue(activeCharacterAtom);
  const slotsUnlocked = useAtomValue(slotsUnlockedAtom);
  const [playVisible, setPlayVisible] = useState(isBrowser());

  useNuiEvent('showPlayButton', () => setPlayVisible(true));

  const play = async () => {
    if (activeCharacter && (await fetchNui('selectCharacter', { citizenid: activeCharacter.citizenid }))) {
      setPlayVisible(false);
    }
  };

  return (
    <Box>
      <Box className={classes.container}>
        {playVisible && (
          <UnstyledButton className={classes.button} onClick={play}>
            JUGAR
          </UnstyledButton>
        )}
        <Box className={classes.gridCharacters}>
          {Array.from({ length: TOTAL_SLOTS }, (_, index) => characters[index]).map((character, index) => (
            <CharacterItem
              key={character?.id ? `character-${character.id}` : `empty-${index}`}
              character={character}
              isLocked={index >= slotsUnlocked}
              indexSlot={index}
              setPlayButtonVisible={setPlayVisible}
            />
          ))}
        </Box>
      </Box>
      {creating && <CharacterForm />}
    </Box>
  );
}
