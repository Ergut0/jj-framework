import { useCallback, useEffect, useState, type ComponentType, type MouseEvent } from 'react';
import { createPortal } from 'react-dom';
import { AnimatePresence, motion } from 'framer-motion';
import background from './assets/background.webp';
import logo from './assets/logo.webp';
import map from './assets/map.webp';
import * as Icons from './icons';
import { fetchNui, isBrowser, useNuiEvent } from './nui';

interface Player {
  job: string;
  cash: number;
  bank: number;
  cps: number;
  fullname: string;
  sex: string;
}

interface Job {
  name: string;
  label: string;
  icon: string;
  open: boolean;
}

interface Announcement {
  id: number;
  message: string;
}

const JOB_ICONS: Record<string, ComponentType> = {
  ocio: Icons.Ocio,
  prostibulo: Icons.Prostibulo,
  avion: Icons.Avion,
  iglesia: Icons.Iglesia,
  badulaque: Icons.Badulaque,
  mechanic: Icons.Mechanic,
  arcade: Icons.Arcade,
  security: Icons.Security,
  compraventa: Icons.Compraventa,
  casino: Icons.Casino,
  weed: Icons.Weed,
  taxi: Icons.Taxi,
  bolera: Icons.Bolera,
  weazel: Icons.Weazel,
};

const grid = { hidden: {}, visible: { transition: { staggerChildren: 0.08, delayChildren: 0.15 } } };
const cardMotion = {
  hidden: { opacity: 0, y: 24, scale: 0.98 },
  visible: { opacity: 1, y: 0, scale: 1, transition: { type: 'spring' as const, stiffness: 260, damping: 26 } },
};
const list = { hidden: {}, visible: { transition: { staggerChildren: 0.05 } } };
const listItem = {
  hidden: { opacity: 0, x: -12 },
  visible: { opacity: 1, x: 0, transition: { duration: 0.25, ease: 'easeOut' as const } },
};
const actionHover = { whileHover: { scale: 1.01 }, transition: { type: 'tween' as const, duration: 0.2, ease: 'easeOut' as const } };

const number = (value: number) => Number(value || 0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');

const EXAMPLE = {
  player: { job: 'Desempleado', cash: 41135, bank: 699924165, cps: 0, fullname: 'das das', sex: 'Hombre' },
  jobs: [
    { name: 'tallerbennys', label: "Benny's Motorworks", icon: 'mechanic', open: true },
    { name: 'burger', label: 'Burger Shot', icon: 'shop', open: true },
    { name: 'casino', label: 'Diamond Casino', icon: 'casino', open: true },
    { name: 'weazel', label: 'Weazel News', icon: 'weazel', open: true },
    { name: 'weedland', label: 'Weed-Land Coffee Shop', icon: 'weed', open: true },
    { name: 'eightarcade', label: 'Eight Arcade', icon: 'arcade', open: true },
    { name: 'yacht', label: 'Yate', icon: 'ocio', open: true },
    { name: 'vanilla', label: 'Vanilla Unicorn', icon: 'prostibulo', open: false },
    { name: 'downtown', label: 'Downtown Cab Co.', icon: 'taxi', open: false },
    { name: 'bowling', label: 'Bolera', icon: 'bolera', open: false },
    { name: 'airlanda', label: 'Aerolínea', icon: 'avion', open: false },
    { name: 'compraventanorte', label: 'Compraventa Norte', icon: 'compraventa', open: false },
  ],
  announcements: [
    { id: 1, message: 'Reinicio del servidor a las 18:00.' },
    { id: 2, message: 'Esta noche hay evento en el Vanilla Unicorn. ¡No faltes!' },
  ],
};

function AnnouncementIcon() {
  const [first, second, third, fourth] = Icons.ANNOUNCEMENT_PATHS;

  return (
    <svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 163.8 138.7">
      <g transform="matrix(.866 .5 -.5 .866 63.85 -37.17)">
        <path transform="translate(-50.17 -17.42)" d={first} fill="transparent" />
        <path d={second} fill="transparent" />
        <g transform="translate(-31.67 -17.67)">
          <g transform="matrix(.9996 .02904 -.02904 .9996 3.046 -2.931)">
            <g transform="matrix(.9979 -.06459 .06459 .9979 -6.504 6.748)">
              <g transform="matrix(.465 -.2127 .2127 .465 132.7 174.9)">
                <g transform="translate(-272 -922.1)">
                  <path fill="currentColor" d={third} />
                </g>
              </g>
              <g transform="matrix(.2821 -.05262 .2293 .5085 154.5 164.8)">
                <g transform="translate(-272 -922.1)">
                  <path fill="currentColor" d={fourth} />
                </g>
              </g>
            </g>
          </g>
        </g>
      </g>
    </svg>
  );
}

function Announcements({ items }: { items: Announcement[] }) {
  const [tooltip, setTooltip] = useState<{ id: number; bottom: number; left: number } | null>(null);

  const showTooltip = (event: MouseEvent<HTMLDivElement>, id: number) => {
    const rect = event.currentTarget.getBoundingClientRect();
    setTooltip({ id, bottom: window.innerHeight - rect.top + 8, left: rect.left + 14 });
  };

  return (
    <div className="ann-announcements">
      <div className="ann-backgroundIcon">
        <AnnouncementIcon />
      </div>
      <div className="ann-backgroundGlow" />
      <AnimatePresence mode="wait">
        {items.length === 0 ? (
          <motion.div key="empty" className="ann-noAnnouncements" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.2 }}>
            <p>No hay anuncios disponibles.</p>
          </motion.div>
        ) : (
          <motion.div key="list" className="ann-announcementList" variants={list} initial="hidden" animate="visible" onScroll={() => setTooltip(null)}>
            {items.map((item) => (
              <motion.div
                key={item.id}
                className="ann-announcement"
                variants={listItem}
                onMouseEnter={(event) => showTooltip(event, item.id)}
                onMouseLeave={() => setTooltip(null)}
              >
                <div className="ann-dot" />
                <p>{item.message}</p>
              </motion.div>
            ))}
          </motion.div>
        )}
      </AnimatePresence>
      {createPortal(
        <AnimatePresence>
          {tooltip && (
            <motion.div
              className="ann-tooltip"
              style={{ bottom: tooltip.bottom, left: tooltip.left }}
              initial={{ opacity: 0, y: 4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 4 }}
              transition={{ duration: 0.15, ease: 'easeOut' }}
            >
              ID #{tooltip.id}
              <span className="ann-arrow" />
            </motion.div>
          )}
        </AnimatePresence>,
        document.body,
      )}
    </div>
  );
}

function PlayerInfo({ player }: { player: Player }) {
  const stats: [ComponentType, string, string][] = [
    [Icons.Job, 'MI TRABAJO', player.job],
    [Icons.Cash, 'EFECTIVO', `$ ${number(player.cash)}`],
    [Icons.Bank, 'BANCO', `$ ${number(player.bank)}`],
    [Icons.Cp, 'CP', number(player.cps)],
  ];

  return (
    <div className="player-playerInfo">
      <div className="player-header">
        <div className="player-info">
          <h2>{player.fullname}</h2>
          <p>{player.sex}</p>
        </div>
        <div className="player-icon">
          <Icons.User />
        </div>
      </div>
      <motion.div className="player-stats" variants={list} initial="hidden" animate="visible">
        {stats.map(([Icon, label, value]) => (
          <motion.div key={label} className="player-stat" variants={listItem}>
            <div className="player-icon">
              <Icon />
            </div>
            <h2>{label}</h2>
            <h1 title={value}>{value}</h1>
          </motion.div>
        ))}
      </motion.div>
    </div>
  );
}

function BusinessList({ jobs }: { jobs: Job[] }) {
  const sorted = [...jobs].sort((a, b) => Number(b.open) - Number(a.open));

  return (
    <motion.div className="biz-businessList" variants={list} initial="hidden" animate="visible">
      {sorted.map((job) => {
        const Icon = JOB_ICONS[job.icon] ?? Icons.Shop;
        return (
          <motion.div
            key={job.name}
            className={`biz-business${job.open ? '' : ' biz-disabled'}`}
            variants={listItem}
            whileHover={{ y: -1 }}
            whileTap={{ y: 0, scale: 0.98 }}
            onClick={() => fetchNui('openBusiness', { name: job.name })}
          >
            <div className="biz-icon">
              <Icon />
            </div>
            <p>{job.label}</p>
          </motion.div>
        );
      })}
    </motion.div>
  );
}

function Card({ className, children, ...props }: Omit<React.ComponentProps<typeof motion.div>, 'children'> & { children: React.ReactNode }) {
  return (
    <motion.div className={`card-card ${className ?? ''}`} variants={cardMotion} {...props}>
      <div className="card-glow" />
      <div className="card-outsideGlow" />
      {children}
    </motion.div>
  );
}

export function App() {
  const [isOpen, setIsOpen] = useState(false);
  const [player, setPlayer] = useState<Player>({ job: '', cash: 0, bank: 0, cps: 0, fullname: '', sex: '' });
  const [jobs, setJobs] = useState<Job[]>([]);
  const [announcements, setAnnouncements] = useState<Announcement[]>([]);

  useNuiEvent('openPauseMenu', useCallback(() => setIsOpen(true), []));
  useNuiEvent('closePauseMenu', useCallback(() => setIsOpen(false), []));
  useNuiEvent<Player>('updatePlayerData', setPlayer);
  useNuiEvent<Job[]>('loadJobs', useCallback((items) => setJobs(items ?? []), []));
  useNuiEvent<Announcement[]>('loadAnnouncements', useCallback((items) => setAnnouncements(items ?? []), []));
  useNuiEvent<{ name: string; open: boolean }>(
    'updateJob',
    useCallback(({ name, open }) => setJobs((items) => items.map((job) => (job.name === name ? { ...job, open } : job))), []),
  );

  useEffect(() => {
    if (!isBrowser()) return;
    setPlayer(EXAMPLE.player);
    setJobs(EXAMPLE.jobs);
    setAnnouncements(EXAMPLE.announcements);
    setIsOpen(true);
  }, []);

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setIsOpen(false);
        fetchNui('closePauseMenu');
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  if (!isOpen) return null;

  const leaveTo = (callback: string) => {
    fetchNui(callback);
    setIsOpen(false);
  };

  return (
    <motion.div className="menu-container" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.2, ease: 'easeOut' }}>
      <motion.div className="bg-background" initial={{ opacity: 0, scale: 1.05 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: 0.4, ease: 'easeOut' }}>
        <img src={background} alt="" />
      </motion.div>

      <motion.div className="head-header" initial={{ opacity: 0, y: -24 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5, ease: 'easeOut' }}>
        <div className="head-logo">
          <img src={logo} alt="Logo" />
        </div>
        <div className="head-texts">
          <h1>Atlantis Roleplay</h1>
          <p>Menú de pausa</p>
        </div>
      </motion.div>

      <motion.div className="menu-content" variants={grid} initial="hidden" animate="visible">
        <Card className="menu-map" {...actionHover} onClick={() => leaveTo('openMap')}>
          <h1><Icons.MapTitle /> Mapa del juego</h1>
          <div className="menu-mapImage">
            <img src={map} alt="Mapa del juego" className="menu-mapImage" />
          </div>
          <div className="menu-button">
            <div className="menu-icon"><Icons.MapButton /></div>
            <div className="menu-texts">
              <h2>Explora la ciudad</h2>
              <p>Descubre ubicaciones, servicios y más.</p>
            </div>
          </div>
        </Card>

        <Card className="menu-playerInfo">
          <h1><Icons.InfoTitle /> Mi información</h1>
          <PlayerInfo player={player} />
        </Card>

        <Card className="menu-announcements">
          <h1><Icons.AnnouncementsTitle /> Anuncios</h1>
          <Announcements items={announcements} />
        </Card>

        <Card className="menu-settings" {...actionHover} onClick={() => leaveTo('openSettings')}>
          <h1><Icons.SettingsTitle /> Ajustes</h1>
          <div className="menu-button">
            <div className="menu-icon"><Icons.SettingsButton /></div>
            <div className="menu-texts">
              <h2>Ajustes del juego</h2>
              <p>Personaliza tu experiencia.</p>
            </div>
          </div>
        </Card>

        <Card className="menu-jobs">
          <h1><Icons.JobsTitle /> Comercios</h1>
          <BusinessList jobs={jobs} />
        </Card>
      </motion.div>
    </motion.div>
  );
}
