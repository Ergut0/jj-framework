import React, { useState } from 'react';
import { useNuiEvent } from '../../hooks/useNuiEvent';

interface Control {
  key: string;
  action: string;
}

interface PlacementHudData {
  visible: boolean;
  label?: string;
  controls?: Control[];
}

const PlacementHud: React.FC = () => {
  const [data, setData] = useState<PlacementHudData>({ visible: false });

  useNuiEvent<PlacementHudData>('setPlacementHud', (payload) => {
    setData(payload ?? { visible: false });
  });

  if (!data.visible) return null;

  const controls = data.controls ?? [];

  return (
    <div className="placement-hud" role="status" aria-live="polite">
      {data.label && (
        <>
          <div className="placement-hud__status">
            <span className="placement-hud__status-dot" />
            <span className="placement-hud__label">{data.label}</span>
          </div>
          {controls.length > 0 && <div className="placement-hud__divider" />}
        </>
      )}

      <div className="placement-hud__controls">
        {controls.map((control, index) => (
          <div className="placement-hud__control" key={`${control.key}-${control.action}-${index}`}>
            <kbd className="placement-hud__key">{control.key}</kbd>
            <span className="placement-hud__action">{control.action}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PlacementHud;
