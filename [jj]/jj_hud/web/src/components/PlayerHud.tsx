import { AnimatePresence, motion } from 'motion/react';
import { Drumstick, GlassWater, HeartPulse, Mic, ShieldHalf } from 'lucide-react';
import type { ReactNode } from 'react';
import { OxygenIcon, StaminaIcon } from '../icons';
import { useHud } from '../store';
import { StatusSquare } from './StatusSquare';

const COLOR = '#6829b4';
const STROKE = '#97979783';
const ICON = 22;

type StatusName = 'micro' | 'health' | 'thirst' | 'hunger' | 'stamina' | 'oxygen' | 'armour';

const STATUSES: { name: StatusName; icon: ReactNode; canShow?: (value: number) => boolean }[] = [
  { name: 'micro', icon: <Mic size={ICON} color="#ffffff81" /> },
  { name: 'health', icon: <HeartPulse size={ICON} color="#fff" /> },
  { name: 'thirst', icon: <GlassWater size={ICON} color="#fff" /> },
  { name: 'hunger', icon: <Drumstick size={ICON} color="#fff" /> },
  { name: 'stamina', icon: <StaminaIcon size={ICON} color="#fff" />, canShow: (value) => value < 100 },
  { name: 'oxygen', icon: <OxygenIcon size={ICON} color="#fff" />, canShow: (value) => value < 100 },
  { name: 'armour', icon: <ShieldHalf size={ICON} color="#fff" />, canShow: (value) => value > 0 },
];

function Status({ name, icon, canShow }: (typeof STATUSES)[number]) {
  const value = useHud((state) => state[name]);
  const talking = useHud((state) => name === 'micro' && state.microphoneOn);

  return (
    <AnimatePresence mode="popLayout">
      {(!canShow || canShow(value)) && (
        <motion.div layout initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.8 }}>
          <StatusSquare value={value} color={COLOR} stroke={talking ? '#bebebe83' : STROKE}>
            {talking ? <Mic size={ICON} color="#57e085" /> : icon}
          </StatusSquare>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

export function PlayerHud() {
  return (
    <motion.div layout className="player-hud" initial={{ opacity: 0, y: 50 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 50 }} transition={{ duration: 0.3 }}>
      {STATUSES.map((status) => (
        <Status key={status.name} {...status} />
      ))}
    </motion.div>
  );
}
