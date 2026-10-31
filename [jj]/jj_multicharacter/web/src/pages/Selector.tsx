import { Box, UnstyledButton } from '@mantine/core';
import { useAtomValue } from 'jotai';
import { ZoneItem } from '../components/ZoneItem';
import { fetchNui } from '../lib/nui';
import { selectedZoneAtom, zonesAtom } from '../store';
import classes from './Selector.module.css';

export function Selector() {
  const zones = useAtomValue(zonesAtom);
  const selectedZone = useAtomValue(selectedZoneAtom);

  const spawn = async () => {
    if (selectedZone) await fetchNui('spawnZone', { zoneId: selectedZone.id });
  };

  return (
    <Box className={classes.container}>
      {selectedZone && (
        <UnstyledButton className={classes.button} onClick={spawn}>
          APARECER
        </UnstyledButton>
      )}
      <Box className={classes.gridZones}>
        {zones.map((zone) => (
          <ZoneItem key={zone.id} zone={zone} />
        ))}
      </Box>
    </Box>
  );
}
