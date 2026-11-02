import React, { useContext } from 'react';
import { TransitionGroup } from 'react-transition-group';
import useNuiEvent from '../../hooks/useNuiEvent';
import useQueue from '../../hooks/useQueue';
import { Locale } from '../../store/locale';
import { getItemUrl } from '../../helpers';
import { getCurrencySymbol } from '../../helpers/currency';
import { applyItemImageFallback } from '../../helpers/itemImageFallback';
import { SlotWithItem } from '../../typings';
import { Items } from '../../store/items';
import Fade from './transitions/Fade';
import { getColor } from '../inventory/InventorySlot';
import { Config } from '../../store/config';
import { isRarityEnabled, normalizeRarity } from '../../store/rarity';

interface ItemNotificationPayload {
  item: SlotWithItem;
  action: string;
  count: number;
}

interface ItemNotificationData {
  id: number;
  payload: ItemNotificationPayload;
  ref: React.RefObject<HTMLDivElement>;
}

export const ItemNotificationsContext = React.createContext<{
  add: (item: ItemNotificationPayload) => void;
  notifications: ItemNotificationData[];
} | null>(null);

export const useItemNotifications = () => {
  const itemNotificationsContext = useContext(ItemNotificationsContext);
  if (!itemNotificationsContext) throw new Error(`ItemNotificationsContext undefined`);
  return itemNotificationsContext;
};

const ItemNotification = React.forwardRef(
  (props: { payload: ItemNotificationPayload; style?: React.CSSProperties }, ref: React.ForwardedRef<HTMLDivElement>) => {
    const slotItem = props.payload.item;
    const label = slotItem.metadata?.label || Items[slotItem.name]?.label || slotItem.name;
    const count = props.payload.count ?? 1;
    const isMoney = slotItem.name === 'money';
    const amount = count.toLocaleString('en-us');

    if (Config.layout !== 'loadout') {
      const text = isMoney
        ? `${props.payload.action ? `${props.payload.action} ` : ''}${getCurrencySymbol()}${amount}`
        : count > 1
          ? `${props.payload.action} ${amount}x`
          : props.payload.action;

      return (
        <div
          className="relative w-[7.1875rem] h-[7.1875rem] border border-transparent item-slot-border font-[Inter]"
          style={
            {
              ...props.style,
              '--borderColor': isRarityEnabled()
                ? getColor(Items[slotItem.name]?.rarity as string).text
                : 'var(--color-slot-border)',
            } as React.CSSProperties
          }
          ref={ref}
        >
          <div className="p-1.5 text-[#a8a8a8] text-xs relative w-full h-full">
            <img
              src={`${slotItem?.name ? getItemUrl(slotItem as SlotWithItem) : 'none'}`}
              onError={applyItemImageFallback}
              className="slot-content-image slot-content-image--centered absolute w-[4.375rem] h-[4.375rem] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-0"
              alt={slotItem.name}
              loading="lazy"
              decoding="async"
              draggable={false}
            />

            <div className="relative leading-3 z-10">
              <p className='uppercase text-[0.625rem] font-semibold text-white'>{text}</p>
              <p className="text-[0.6875rem]">
                {slotItem.weight > 0
                  ? slotItem.weight >= 1000
                    ? `${(slotItem.weight / 1000).toLocaleString('en-us', { minimumFractionDigits: 1 })}kg `
                    : `${slotItem.weight.toLocaleString('en-us', { minimumFractionDigits: 1 })}g `
                  : ''}
              </p>
            </div>

            <div className="slot-content-label slot-content-label--center absolute text-white text-center w-full bottom-[0.4375rem] left-1/2 -translate-x-1/2 font-semibold z-10 text-[0.6875rem] px-1 truncate">
              {label}
            </div>
          </div>
        </div>
      );
    }

    const weight = slotItem.weight > 0
      ? slotItem.weight >= 1000
        ? `${(slotItem.weight / 1000).toLocaleString('en-us', { minimumFractionDigits: 1 })}kg`
        : `${slotItem.weight.toLocaleString('en-us', { minimumFractionDigits: 1 })}g`
      : '';
    const rarity = isRarityEnabled()
      ? normalizeRarity(slotItem.metadata?.rarity || Items[slotItem.name]?.rarity) || 'common'
      : 'common';
    const color = getColor(rarity).text;
    const quantity = isMoney ? `${getCurrencySymbol()}${amount}` : `${amount}x`;
    const qualityValue =
      slotItem.metadata?.quality ??
      slotItem.durability ??
      slotItem.metadata?.durability ??
      slotItem.metadata?.armorDurability;
    const quality =
      typeof qualityValue === 'number' ? Math.max(0, Math.min(100, qualityValue)) : 100;

    return (
      <div
        className="item-notification"
        style={
          {
            ...props.style,
            '--notification-item-color': color,
          } as React.CSSProperties
        }
        ref={ref}
      >
        <div className="item-notification__media">
          <img
            src={`${slotItem?.name ? getItemUrl(slotItem as SlotWithItem) : 'none'}`}
            onError={applyItemImageFallback}
            className="item-notification__image slot-content-image"
            alt={slotItem.name}
            loading="lazy"
            decoding="async"
            draggable={false}
          />
        </div>
        <div className="item-notification__copy">
          <span className="item-notification__action">{props.payload.action}</span>
          <strong className="item-notification__name slot-content-label">{label}</strong>
          {weight && <span className="item-notification__weight">{weight}</span>}
        </div>
        <span className="item-notification__quantity slot-content-quantity slot-content-quantity--right">{quantity}</span>
        {quality !== null && (
          <div className="item-notification__quality" aria-label={`Quality ${Math.round(quality)}%`}>
            <span style={{ width: `${quality}%` }} />
          </div>
        )}
      </div>
    );
  }
);

let notificationIdCounter = 0;

export const ItemNotificationsProvider = ({ children }: { children: React.ReactNode }) => {
  const queue = useQueue<ItemNotificationData>();

  const add = (payload: ItemNotificationPayload) => {
    const ref = React.createRef<HTMLDivElement>();
    queue.add({ id: ++notificationIdCounter, payload, ref });

    const timeout = setTimeout(() => {
      queue.remove();
      clearTimeout(timeout);
    }, 2500);
  };

  useNuiEvent<[item: SlotWithItem, text: string, count?: number]>('itemNotify', ([item, text, count]) => {
    if (item?.metadata?.clothingSlot !== undefined) return;
    add({
      item,
      action: Locale[text] || text,
      count: count ?? 1,
    });
  });

  return (
    <ItemNotificationsContext.Provider value={{ add, notifications: queue.values }}>
      {children}
    </ItemNotificationsContext.Provider>
  );
};

// oldest (index 0) sits centered; each newer notification alternates
// outward right/left of it (+1, -1, +2, -2, ...), so when the centered
// (oldest) one expires the rest slide inward to fill its slot.
const getSlot = (index: number) => {
  if (index === 0) return 0;
  const magnitude = Math.ceil(index / 2);
  return index % 2 === 1 ? magnitude : -magnitude;
};

const SLIDE_TRANSITION = 'transform 0.16s ease-out';

const PositionedNotification: React.FC<{
  in?: boolean;
  payload: ItemNotificationPayload;
  itemRef: React.RefObject<HTMLDivElement>;
  offset: string;
  baseStyle: React.CSSProperties;
}> = ({ in: inProp, payload, itemRef, offset, baseStyle }) => {
  // new notifications mount centered, then animate out to their slot on the
  // next frame - existing ones just get their offset updated directly, so
  // a compacting shift (after the centered one expires) slides smoothly
  // from its current spot instead of resetting through the center first.
  const [pos, setPos] = React.useState('0rem');

  React.useEffect(() => {
    const raf = requestAnimationFrame(() => setPos(offset));
    return () => cancelAnimationFrame(raf);
  }, [offset]);

  return (
    <Fade in={inProp}>
      <ItemNotification
        payload={payload}
        ref={itemRef}
        style={{
          ...baseStyle,
          transform: `translateX(calc(-50% + ${pos}))`,
          transition: SLIDE_TRANSITION,
        }}
      />
    </Fade>
  );
};

export const ItemNotificationsDisplay: React.FC = () => {
  const { notifications } = useItemNotifications();

  if (Config.layout !== 'loadout') {
    const step = 7.3125;
    return (
      <TransitionGroup
        className="absolute bottom-[20%] pointer-events-none"
        style={{ left: '50%', width: 0, height: '7.1875rem' }}
      >
        {notifications.map((notification, index) => (
          <PositionedNotification
            key={`item-notification-${notification.id}`}
            payload={notification.payload}
            itemRef={notification.ref}
            offset={`${getSlot(index) * step}rem`}
            baseStyle={{ position: 'absolute', top: 0, left: 0 }}
          />
        ))}
      </TransitionGroup>
    );
  }

  const step = 7.25;
  return (
    <TransitionGroup
      className="item-notifications"
      role="status"
      aria-live="polite"
      style={{ height: '6.75rem' }}
    >
      {notifications.map((notification, index) => (
        <PositionedNotification
          key={`item-notification-${notification.id}`}
          payload={notification.payload}
          itemRef={notification.ref}
          offset={`${getSlot(index) * step}rem`}
          baseStyle={{ position: 'absolute', top: 0, left: '50%' }}
        />
      ))}
    </TransitionGroup>
  );
};
