import { Box } from '@mantine/core';
import { FaArchive } from 'react-icons/fa';
import { FaGear, FaLayerGroup, FaWalkieTalkie } from 'react-icons/fa6';
import styles from '../styles/ActionMenu.module.css';

export function HeaderTabs({ tab, onTabChange }: any) {
  const a = (e) => (tab === e ? `${styles.headerItem} ${styles.headerItemSelected}` : styles.headerItem);
  return (
    <>
      <Box className={a(0)} onClick={() => onTabChange(0)}>
        <FaLayerGroup size={19} />
      </Box>
      <Box className={a(1)} onClick={() => onTabChange(1)}>
        <FaWalkieTalkie size={19} />
      </Box>
      <Box className={a(2)} onClick={() => onTabChange(2)}>
        <FaArchive size={19} />
      </Box>
      <Box className={a(3)} onClick={() => onTabChange(3)}>
        <FaGear size={19} />
      </Box>
    </>
  );
}
