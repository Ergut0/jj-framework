import type { ReactNode } from 'react';
import { TbArrowLeft, TbCalendarEvent } from 'react-icons/tb';
import { fetchNui } from '../nui';
import type { Business, Navigate, Status, TabletData } from '../types';

export interface PageProps {
  data: TabletData;
  navigate: Navigate;
  back: () => void;
  close: () => void;
}

const STATUS: Record<Status, string> = {
  open: 'Abierto',
  closed: 'Cerrado',
  in_event: 'Evento',
};

export function StatusBadge({ status }: { status: Status }) {
  return (
    <span className={`status status-${status}`}>
      {status === 'in_event' ? <TbCalendarEvent size={13} /> : <i />}
      {STATUS[status] ?? 'Cerrado'}
    </span>
  );
}

export function BackButton({ onClick, children = 'Volver' }: { onClick: () => void; children?: ReactNode }) {
  return (
    <button type="button" className="action action-red" onClick={onClick}>
      <TbArrowLeft size={20} />
      {children}
    </button>
  );
}

export function BusinessLogo({ business, className }: { business: Business; className: string }) {
  if (business.logo) return <img className={className} src={business.logo} alt="" />;

  return <span className={`${className} logo-empty`}>{business.label[0]?.toUpperCase()}</span>;
}

export function callBusiness(business: Business, close: () => void) {
  fetchNui('tablet:callJob', business.name);
  close();
}

export function markBusiness(business: Business, close: () => void) {
  fetchNui('tablet:setWaypoint', business.coords);
  close();
}
