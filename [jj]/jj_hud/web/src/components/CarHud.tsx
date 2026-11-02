import { motion } from 'motion/react';
import { CarFront, Compass, Fuel, Lightbulb, LockKeyhole, LockKeyholeOpen, Mountain, Wrench } from 'lucide-react';
import type { ReactNode } from 'react';
import type { VehicleData } from '../store';

// Arco de las revoluciones: abierto por abajo
const SIZE = 210;
const CENTER = SIZE / 2;
const RADIUS = 92;
const STROKE = 11;
const START_ANGLE = 135;
const SWEEP = 270;
const CIRCUMFERENCE = 2 * Math.PI * RADIUS;
const ARC_LENGTH = (SWEEP / 360) * CIRCUMFERENCE;
const REDLINE = 85;

const SeatbeltIcon = ({ size = 18, color = 'currentColor' }: { size?: number; color?: string }) => (
  <svg viewBox="0 0 24 24" width={size} height={size} fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="5" r="3" />
    <path d="M6 22v-7a6 6 0 0 1 12 0v7" />
    <path d="M7 11l11 9" />
  </svg>
);

function Gauge({ vehicle }: { vehicle: VehicleData }) {
  const level = Math.max(0, Math.min(100, vehicle.rpm));
  const redline = level >= REDLINE;

  return (
    <div className="gauge">
      <svg viewBox={`0 0 ${SIZE} ${SIZE}`} width={SIZE} height={SIZE} style={{ transform: `rotate(${START_ANGLE}deg)` }}>
        <circle cx={CENTER} cy={CENTER} r={RADIUS} fill="none" stroke="#ffffff1f" strokeWidth={STROKE} strokeLinecap="round" strokeDasharray={`${ARC_LENGTH} ${CIRCUMFERENCE}`} />
        <circle
          className="gauge-level"
          cx={CENTER}
          cy={CENTER}
          r={RADIUS}
          fill="none"
          stroke={redline ? '#f43f5e' : 'var(--accent)'}
          strokeWidth={STROKE}
          strokeLinecap="round"
          strokeDasharray={`${(level / 100) * ARC_LENGTH} ${CIRCUMFERENCE}`}
        />
      </svg>
      <div className="gauge-center">
        <strong className="speed">{vehicle.speed}</strong>
        <span className="unit">{vehicle.unit}</span>
        {vehicle.gear !== undefined && <span className={redline ? 'gear red' : 'gear'}>{vehicle.gear}</span>}
        {vehicle.altitude !== undefined && (
          <span className="altitude"><Mountain size={13} /> {vehicle.altitude} m</span>
        )}
      </div>
    </div>
  );
}

function Bar({ icon, value, warn, label }: { icon: ReactNode; value: number; warn: boolean; label: string }) {
  return (
    <div className={warn ? 'bar warn' : 'bar'} title={label}>
      <span className="bar-icon">{icon}</span>
      <div className="bar-track">
        <div className="bar-level" style={{ width: `${Math.max(0, Math.min(100, value))}%` }} />
      </div>
    </div>
  );
}

function Indicator({ active, danger, label, children }: { active: boolean; danger?: boolean; label: string; children: ReactNode }) {
  const classes = ['indicator'];
  if (active) classes.push('on');
  if (danger) classes.push('danger');
  return <span className={classes.join(' ')} title={label} aria-label={label}>{children}</span>;
}

export function CarHud({ vehicle }: { vehicle: VehicleData }) {
  return (
    <motion.div className="car-hud" initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 40 }} transition={{ duration: 0.25 }}>
      {vehicle.street && (
        <div className="location">
          <Compass size={15} />
          <strong>{vehicle.direction}</strong>
          <span>{vehicle.street}</span>
        </div>
      )}

      <div className="car-panel">
        <Gauge vehicle={vehicle} />

        <div className="car-side">
          <Bar icon={<Fuel size={15} />} value={vehicle.fuel} warn={vehicle.fuel <= 15} label={`Gasolina: ${vehicle.fuel} %`} />
          <Bar icon={<Wrench size={15} />} value={vehicle.engine} warn={vehicle.engine <= 30} label={`Motor: ${vehicle.engine} %`} />

          <div className="indicators">
            {vehicle.hasSeatbelt && (
              <Indicator active={vehicle.belted} danger={!vehicle.belted} label={vehicle.belted ? 'Cinturón puesto' : 'Sin cinturón'}>
                <SeatbeltIcon />
              </Indicator>
            )}
            <Indicator active={vehicle.running} danger={!vehicle.running} label={vehicle.running ? 'Motor encendido' : 'Motor apagado'}>
              <CarFront size={18} />
            </Indicator>
            <Indicator active={vehicle.lights > 0} label={['Luces apagadas', 'Luces encendidas', 'Largas'][vehicle.lights]}>
              <Lightbulb size={18} className={vehicle.lights === 2 ? 'high-beam' : undefined} />
            </Indicator>
            <Indicator active={vehicle.locked} label={vehicle.locked ? 'Cerrado' : 'Abierto'}>
              {vehicle.locked ? <LockKeyhole size={18} /> : <LockKeyholeOpen size={18} />}
            </Indicator>
          </div>
        </div>
      </div>
    </motion.div>
  );
}
