import { Box } from '@mantine/core';
import { useAtom } from 'jotai';
import { fetchNui } from '../lib/nui';
import { selectedZoneAtom, type Zone } from '../store';
import classes from './ZoneItem.module.css';

export function ZoneItem({ zone }: { zone: Zone }) {
  const [selectedZone, setSelectedZone] = useAtom(selectedZoneAtom);

  const select = async () => {
    await fetchNui('selectZonePreview', { zoneId: zone.id });
    setSelectedZone(zone);
  };

  const className =
    selectedZone?.id === zone.id ? `${classes.zoneItem} ${classes.zoneItemSelected}` : classes.zoneItem;

  return (
    <Box className={className} onClick={select}>
      <Box className={classes.zoneItemInner}>
        <Box className={classes.zoneThumb}>
          <img className={classes.zoneThumbImg} src={zone.image} alt="Zona" />
        </Box>
        <Box className={classes.zoneMeta}>
          <Box className={classes.zoneName}>{zone.name}</Box>
          <Box className={classes.zoneDescription}>{zone.description}</Box>
        </Box>
      </Box>
    </Box>
  );
}
