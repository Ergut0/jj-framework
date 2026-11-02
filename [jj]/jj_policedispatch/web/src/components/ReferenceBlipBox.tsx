import { Box, Image } from '@mantine/core';
import { useReferenceStore } from '../store/references';
import { fetchNui } from '../utils/nui';
import styles from '../styles/ReferencesTab.module.css';

export function ReferenceBlipBox({ blip }: any) {
  const { referenceBlipId, setBlipId } = useReferenceStore();
  return (
    <Box
      className={
        referenceBlipId === blip.id
          ? `${styles.referenceBoxId} ${styles.referenceBoxIdSelected}`
          : styles.referenceBoxId
      }
      onClick={() =>
        (async (e) => {
          await fetchNui('selectBlipId', {
            blipId: e,
          });
          setBlipId(blip.id);
        })(blip.id)
      }
    >
      <Image
        src={`https://docs.fivem.net/blips/${blip.code}${blip.ext ? '.' + blip.ext : '.png'}`}
        alt={blip.code}
      />
    </Box>
  );
}
