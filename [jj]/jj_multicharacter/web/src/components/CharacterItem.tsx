import { Box } from '@mantine/core';
import { useAtom, useSetAtom } from 'jotai';
import { FaCirclePlus, FaLock, FaUser } from 'react-icons/fa6';
import { fetchNui } from '../lib/nui';
import { activeCharacterAtom, creatingAtom, type Character } from '../store';
import classes from './CharacterItem.module.css';

interface Props {
  character?: Character;
  isLocked: boolean;
  indexSlot: number;
  setPlayButtonVisible: (visible: boolean) => void;
}

export function CharacterItem({ character, isLocked, indexSlot, setPlayButtonVisible }: Props) {
  const [activeCharacter, setActiveCharacter] = useAtom(activeCharacterAtom);
  const setCreating = useSetAtom(creatingAtom);

  const nameLabel = isLocked ? 'Bloqueado' : character ? 'Nombre del personaje' : 'Crear nuevo personaje';
  const name = isLocked ? 'Slot bloqueado' : character ? character.fullName : 'Slot disponible';
  const valueLabel = isLocked ? 'No disponible' : character ? 'Fecha de nacimiento' : 'Disponible';
  const value = character && !isLocked ? character.birthdate : `Slot ${indexSlot + 1}`;

  const className = isLocked
    ? `${classes.charItem} ${classes.locked}`
    : activeCharacter?.id === character?.id
      ? `${classes.charItem} ${classes.selected}`
      : classes.charItem;

  const select = async () => {
    if (isLocked) return;
    setPlayButtonVisible(false);
    if (!character) {
      setCreating(true);
    } else if (await fetchNui('setActiveCharacter', { citizenid: character.citizenid })) {
      setActiveCharacter(character);
      setCreating(false);
    }
  };

  return (
    <Box className={className} onClick={select}>
      <Box className={classes.charItemInner}>
        <Box className={classes.charThumb}>
          {isLocked && <FaLock className={`${classes.charThumbImg} ${classes.locked}`} />}
          {!character && !isLocked && <FaCirclePlus className={`${classes.charThumbImg} ${classes.nochar}`} />}
          {character && !isLocked && <FaUser className={`${classes.charThumbImg} ${classes.char}`} />}
        </Box>
        <Box className={classes.charMeta}>
          <Box className={classes.charItemInfoLabel}>{nameLabel}</Box>
          <Box className={classes.charName}>{name}</Box>
          <Box className={classes.charItemInfoLabel}>{valueLabel}</Box>
          <Box className={classes.charValue}>{value}</Box>
        </Box>
      </Box>
    </Box>
  );
}
