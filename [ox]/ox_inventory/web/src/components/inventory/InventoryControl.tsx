import React, { useEffect, useRef, useState } from 'react';
import { useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectItemAmount, setItemAmount } from '../../store/inventory';
import { DragSource } from '../../typings';
import { onUse } from '../../dnd/onUse';
import { onGive } from '../../dnd/onGive';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import UsefulControls from './UsefulControls';

const MAX_AMOUNT = 999999999;

const InventoryControl: React.FC = () => {
  const itemAmount = useAppSelector(selectItemAmount);
  const dispatch = useAppDispatch();
  const t = (key: string, fallback: string) => {
    const value = Locale[key];
    return value && value !== key ? value : fallback;
  };

  const [infoVisible, setInfoVisible] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const cursorRef = useRef<number | null>(null);
  const formattedAmount = itemAmount > 0 ? itemAmount.toLocaleString('en-US') : '';

  const [, use] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      source.inventory === 'player' && onUse(source.item);
    },
  }));

  const [, give] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      (source.inventory === 'player' || source.inventory === 'backpack') && onGive(source);
    },
  }));

  const inputHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    const rawValue = event.target.value;
    const cursor = event.target.selectionStart ?? rawValue.length;
    const digitsBeforeCursor = rawValue.slice(0, cursor).replace(/\D/g, '').length;
    const value = Number(rawValue.replace(/\D/g, ''));

    dispatch(setItemAmount(Number.isFinite(value) ? Math.min(Math.floor(value), MAX_AMOUNT) : 0));
    cursorRef.current = digitsBeforeCursor;
  };

  const decreaseAmount = () => {
    dispatch(setItemAmount(itemAmount > 0 ? itemAmount - 1 : 0));
  };

  const increaseAmount = () => {
    dispatch(setItemAmount(itemAmount < MAX_AMOUNT ? itemAmount + 1 : MAX_AMOUNT));
  };

  const clearAmount = () => {
    dispatch(setItemAmount(0));
  };

  useEffect(() => {
    if (cursorRef.current === null || !inputRef.current) return;

    let digits = 0;
    let cursor = formattedAmount.length;

    for (let i = 0; i < formattedAmount.length; i++) {
      if (/\d/.test(formattedAmount[i])) digits++;
      if (digits >= cursorRef.current) {
        cursor = i + 1;
        break;
      }
    }

    inputRef.current.setSelectionRange(cursor, cursor);
    cursorRef.current = null;
  }, [formattedAmount]);

  return (
    <>
      <UsefulControls infoVisible={infoVisible} setInfoVisible={setInfoVisible} />
      <div className="gqty">
        <div className={`gqty__wrap ${itemAmount > 0 ? 'gqty--active' : ''}`} title="Default quantity for drag & drop">
          <span className="gqty__label">{t('quantity_short', t('quantity', 'Qty'))}</span>
          <button className="gqty__btn" onClick={decreaseAmount}>
            <i className="fas fa-minus" />
          </button>
          <input
            ref={inputRef}
            className="gqty__input"
            type="text"
            inputMode="numeric"
            value={formattedAmount}
            onChange={inputHandler}
            min={0}
            max={MAX_AMOUNT}
            placeholder={itemAmount === 0 ? t('amount', 'Amount') : undefined}
          />
          <button className="gqty__btn" onClick={increaseAmount}>
            <i className="fas fa-plus" />
          </button>
          <button className="gqty__clear" onClick={clearAmount} disabled={itemAmount === 0}>
            <i className="fas fa-xmark" />
          </button>
        </div>
      </div>


      <button className="useful-controls-button" onClick={() => setInfoVisible(true)}>
        <svg xmlns="http://www.w3.org/2000/svg" height="2em" viewBox="0 0 524 524">
          <path d="M256 512A256 256 0 1 0 256 0a256 256 0 1 0 0 512zM216 336h24V272H216c-13.3 0-24-10.7-24-24s10.7-24 24-24h48c13.3 0 24 10.7 24 24v88h8c13.3 0 24 10.7 24 24s-10.7 24-24 24H216c-13.3 0-24-10.7-24-24s10.7-24 24-24zm40-208a32 32 0 1 1 0 64 32 32 0 1 1 0-64z" />
        </svg>
      </button>
    </>
  );
};

export default InventoryControl;
