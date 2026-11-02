import { useMemo, useState } from 'react';
import { TbPlus, TbSearch, TbWorld } from 'react-icons/tb';
import type { JobSummary } from '../types';
import { JobLogo } from './JobLogo';

interface Props {
  jobs: JobSummary[];
  selected: string | null;
  onSelect: (name: string) => void;
  onCreate: () => void;
  onGlobal: () => void;
}

export function Sidebar({ jobs, selected, onSelect, onCreate, onGlobal }: Props) {
  const [search, setSearch] = useState('');

  const visible = useMemo(() => {
    const term = search.trim().toLowerCase();
    return term ? jobs.filter((job) => job.label.toLowerCase().includes(term) || job.name.includes(term)) : jobs;
  }, [jobs, search]);

  return (
    <aside className="sidebar">
      <header className="sidebar-title">
        <h1>Trabajos</h1>
        <span>{jobs.length}</span>
      </header>

      <label className="search">
        <TbSearch size={15} />
        <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Buscar trabajo" />
      </label>

      <nav className="job-list">
        {visible.map((job) => (
          <button key={job.id} type="button" className={`job-row${selected === job.name ? ' active' : ''}`} onClick={() => onSelect(job.name)}>
            <JobLogo src={job.img} label={job.label} size={34} />
            <span className="job-row-text">
              <strong>{job.label}</strong>
              <small>{job.name}</small>
            </span>
            <i className={`dot${job.open ? ' on' : ''}`} title={job.open ? 'Abierto' : 'Cerrado'} />
          </button>
        ))}
        {!visible.length && <p className="list-empty">{search ? 'Ningún trabajo coincide' : 'Sin trabajos'}</p>}
      </nav>

      <footer className="sidebar-actions">
        <button type="button" className={`side-link${selected === 'global' ? ' active' : ''}`} onClick={onGlobal}>
          <TbWorld size={16} /> Teleports globales
        </button>
        <button type="button" className="side-primary" onClick={onCreate}>
          <TbPlus size={16} /> Crear trabajo
        </button>
      </footer>
    </aside>
  );
}
