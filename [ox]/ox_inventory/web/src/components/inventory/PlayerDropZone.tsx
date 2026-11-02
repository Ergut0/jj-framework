import React from 'react';
import { PlayerTarget } from './PlayerDropZone.types';

export type { PlayerTarget };

interface Props {
  target: PlayerTarget;
  isHovered: boolean;
}

const PlayerDropZone: React.FC<Props> = ({ target, isHovered }) => {
  return (
    <div
      style={{
        position: 'fixed',
        left: `${target.screenX * 100}vw`,
        top: `${target.screenY * 100}vh`,
        transform: 'translate(-50%, -50%)',
        zIndex: 9999,
        pointerEvents: 'none',
        userSelect: 'none',
        width: '4rem',
        height: '4rem',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {isHovered && (
        <i
          className="fas fa-hand-holding"
          style={{
            color: 'var(--color-primary)',
            fontSize: '2.1875rem',
            filter: 'drop-shadow(0 0 0.375rem rgba(var(--color-primary-rgb), 0.9))',
          }}
        />
      )}
    </div>
  );
};

export default PlayerDropZone;
