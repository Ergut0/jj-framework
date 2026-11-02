import React, { useState, useEffect } from 'react';
import useNuiEvent from '../../hooks/useNuiEvent';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import { getCurrencySymbol } from '../../helpers/currency';

interface PlayerInfo {
  cash: number;
  bank: number;
  playerId: number;
  citizenId: string;
  citizenLabel?: string;
  name: string;
}

const fmt = (n: number) =>
  getCurrencySymbol() + Math.floor(n).toLocaleString('en-US');

const PlayerInfoPanel: React.FC = () => {
  const [info, setInfo] = useState<PlayerInfo>({
    cash: 0,
    bank: 0,
    playerId: 0,
    citizenId: '',
    name: '',
  });

  useEffect(() => {
    fetchNui<PlayerInfo>('getPlayerInfo')
      .then((data) => { if (data) setInfo(data); })
      .catch(() => {});
  }, []);

  useNuiEvent<PlayerInfo>('setPlayerInfo', (data) => {
    if (data) setInfo(data);
  });

  return (
    <div className="player-info-panel">
      {info.name && (
        <div className="player-info-name">
          <i className="fas fa-user" />
          <span>{info.name}</span>
        </div>
      )}
      <div className="player-info-grid">
        <div className="player-info-card">
          <i className="fas fa-money-bill-wave" />
          <div className="player-info-card-body">
            <span className="player-info-label">{Locale.ui_cash}</span>
            <span className="player-info-value player-info-value--cash">{fmt(info.cash)}</span>
          </div>
        </div>
        <div className="player-info-card">
          <i className="fas fa-university" />
          <div className="player-info-card-body">
            <span className="player-info-label">{Locale.ui_bank}</span>
            <span className="player-info-value player-info-value--bank">{fmt(info.bank)}</span>
          </div>
        </div>
        <div className="player-info-card">
          <i className="fas fa-id-badge" />
          <div className="player-info-card-body">
            <span className="player-info-label">{Locale.ui_player_id}</span>
            <span className="player-info-value">#{info.playerId}</span>
          </div>
        </div>
        <div className="player-info-card">
          <i className={info.citizenLabel === 'Job' ? 'fas fa-briefcase' : 'fas fa-fingerprint'} />
          <div className="player-info-card-body">
            <span className="player-info-label">{info.citizenLabel || Locale.ui_citizen_id}</span>
            <span className="player-info-value player-info-value--citizen">{info.citizenId || '-'}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PlayerInfoPanel;
