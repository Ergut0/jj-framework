import type { ReactNode } from 'react';
import { useAdmin } from '../context';

interface Props {
  action: string;
  icon: ReactNode;
  label: string;
  danger?: boolean;
  disabled?: boolean;
  active?: boolean;
  onClick: () => void;
}

// Solo se muestra si el nivel del usuario permite la acción
export function ActionButton({ action, icon, label, danger, disabled, active, onClick }: Props) {
  const { can } = useAdmin();
  if (!can(action)) return null;

  const classes = ['action-button'];
  if (danger) classes.push('danger');
  if (active) classes.push('active');

  return (
    <button type="button" className={classes.join(' ')} disabled={disabled} onClick={onClick}>
      {icon}
      <span>{label}</span>
    </button>
  );
}
