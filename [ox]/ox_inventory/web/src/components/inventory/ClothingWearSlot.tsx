import React, { useEffect, useMemo, useRef } from 'react';
import { useDrag, useDrop } from 'react-dnd';
import { useMergeRefs } from '@floating-ui/react';
import { closeTooltip, openTooltip } from '../../store/tooltip';
import { useAppDispatch, useAppSelector } from '../../store';
import { DragSource, InventoryType, Slot, SlotWithItem } from '../../typings';
import { ClothingSlotDefinition } from '../../typings/clothing';
import { getItemUrl, isSlotWithItem } from '../../helpers';
import { Items } from '../../store/items';
import { getColor, getItemQuality } from './InventorySlot';
import { fetchNui } from '../../utils/fetchNui';
import torsoSvg from '../../assets/svg/torso.svg';
import glovesSvg from '../../assets/svg/gloves.svg';
import vestSvg from '../../assets/svg/vest.svg';
import { formatItemAmount } from '../../helpers/formatItemAmount';
import { applyItemImageFallback } from '../../helpers/itemImageFallback';
import { Config } from '../../store/config';
import { isRarityEnabled, normalizeRarity } from '../../store/rarity';

type ClothingWearSlotProps = {
  slotIndex: number;
  definition: ClothingSlotDefinition;
  slot?: Slot;
  isOtherPlayer?: boolean;
  otherInventoryId?: string;
};

const transparentDragImage =
  typeof window !== 'undefined'
    ? (() => {
        const img = new Image();
        img.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';
        return img;
      })()
    : undefined;

const getMetadataNumber = (metadata: SlotWithItem['metadata'] | undefined, key: 'component' | 'prop') => {
  const rawValue = metadata?.[key];
  const numericValue = Number(rawValue);
  return Number.isFinite(numericValue) ? numericValue : undefined;
};

export const clothingItemMatchesDefinition = (item: SlotWithItem | undefined, definition: ClothingSlotDefinition) => {
  if (!item || !item.name) return false;

  const componentId = typeof definition.component === 'number' ? definition.component : undefined;
  const propId = typeof definition.prop === 'number' ? definition.prop : undefined;
  const itemComponent = getMetadataNumber(item.metadata, 'component');
  const itemProp = getMetadataNumber(item.metadata, 'prop');

  if (componentId !== undefined) {
    return itemComponent === componentId;
  }

  if (propId !== undefined) {
    return itemProp === propId;
  }

  return false;
};

const renderClothingIcon = (icon?: string) => {
  switch ((icon || '').toLowerCase()) {
    case 'hat':
      return (
        <svg width="60" height="60" viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M11.25 35L5.8675 39.305C5.59721 39.5225 5.37902 39.7977 5.22891 40.1104C5.0788 40.4232 5.00059 40.7656 5 41.1125C4.9947 41.5303 5.1085 41.941 5.3281 42.2966C5.5477 42.6521 5.864 42.9377 6.24 43.12C11.975 45.8 20.49 47.5 30 47.5C39.51 47.5 48.0275 45.8 53.7575 43.12C54.134 42.938 54.4508 42.6526 54.6708 42.297C54.8909 41.9415 55.0051 41.5306 55 41.1125C54.9994 40.7656 54.9212 40.4232 54.7711 40.1104C54.621 39.7977 54.4028 39.5225 54.1325 39.305L48.75 35" stroke="currentColor" strokeOpacity="0.8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
          <path d="M27.5 25H32.5M30 37.5C37.6675 37.5 44.475 36.5175 48.75 35L47.7325 25.8425C47.0275 19.4975 46.675 16.3225 44.54 14.4125C42.4 12.5 39.21 12.5 32.825 12.5H27.175C20.79 12.5 17.5975 12.5 15.46 14.4125C13.325 16.3225 12.9725 19.4975 12.2675 25.8425L11.25 35C15.525 36.5175 22.3325 37.5 30 37.5Z" stroke="currentColor" strokeOpacity="0.8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      );
    case 'mask':
      return (
        <svg width="60" height="60" viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M37.1859 44.1639C36.9105 44.5778 36.482 44.8654 35.9946 44.9634C35.5071 45.0615 35.0007 44.9619 34.5867 44.6866C33.0633 43.6741 31.875 43.1256 30 43.1256C28.125 43.1256 26.9367 43.6741 25.4133 44.6866C24.9993 44.9517 24.4977 45.0435 24.0166 44.9424C23.5355 44.8413 23.1133 44.5553 22.8411 44.1459C22.5688 43.7366 22.4682 43.2367 22.5609 42.7539C22.6536 42.2711 22.9322 41.8441 23.3367 41.5647C25.3125 40.2499 27.2016 39.3756 30 39.3756C32.7984 39.3756 34.6875 40.2499 36.6633 41.5647C37.0772 41.8401 37.3648 42.2687 37.4628 42.7561C37.5608 43.2435 37.4612 43.7499 37.1859 44.1639ZM52.5 11.2506V24.3217C52.5 32.7217 50.2383 40.6459 46.1297 46.6295C41.8734 52.8311 36.1453 56.2389 30 56.2389C23.8547 56.2389 18.1266 52.8241 13.8703 46.6295C9.76172 40.6506 7.5 32.7264 7.5 24.3264V11.2506C7.50021 10.6412 7.64897 10.0409 7.9334 9.50191C8.21783 8.96288 8.62935 8.50129 9.13233 8.15712C9.63532 7.81295 10.2146 7.59656 10.8201 7.52668C11.4255 7.45681 12.0389 7.53555 12.607 7.7561C15.9 9.03579 22.5422 11.1827 30 11.1827C37.4578 11.1827 44.0977 9.03579 47.393 7.7561C47.9611 7.53555 48.5745 7.45681 49.1799 7.52668C49.7854 7.59656 50.3647 7.81295 50.8677 8.15712C51.3707 8.50129 51.7822 8.96288 52.0666 9.50191C52.351 10.0409 52.4998 10.6412 52.5 11.2506ZM48.75 11.2506C45.2109 12.6311 38.0695 14.9374 30 14.9374C21.9305 14.9374 14.7891 12.6264 11.25 11.2506V24.3264C11.25 31.9764 13.2797 39.1459 16.9617 44.5131C20.4984 49.6647 25.1273 52.5006 30 52.5006C34.8727 52.5006 39.5016 49.6647 43.0383 44.5131C46.7203 39.1413 48.75 31.9764 48.75 24.3264V11.2506ZM44.3766 26.7194C44.1932 26.555 43.9791 26.4283 43.7468 26.3466C43.5144 26.2649 43.2682 26.2298 43.0222 26.2433C42.7763 26.2568 42.5354 26.3186 42.3134 26.4252C42.0913 26.5319 41.8924 26.6812 41.7281 26.8647C41.1 27.5678 39.6539 28.1163 38.4469 28.1163C37.2398 28.1163 35.7844 27.5655 35.1656 26.8647C35.0008 26.6794 34.8011 26.5284 34.5779 26.4203C34.3547 26.3122 34.1125 26.2491 33.8649 26.2346C33.6173 26.2201 33.3693 26.2546 33.1351 26.3359C32.9008 26.4173 32.6849 26.544 32.4996 26.7088C32.3143 26.8737 32.1633 27.0734 32.0552 27.2965C31.9471 27.5197 31.884 27.762 31.8695 28.0096C31.8551 28.2571 31.8895 28.5051 31.9709 28.7394C32.0522 28.9736 32.1789 29.1896 32.3438 29.3749C33.682 30.8702 36.1266 31.8756 38.4375 31.8756C40.7484 31.8756 43.1836 30.8702 44.5312 29.3749C44.6962 29.1907 44.8231 28.9757 44.9046 28.7423C44.9861 28.509 45.0207 28.2617 45.0063 28.0149C44.9919 27.7681 44.9289 27.5266 44.8208 27.3043C44.7127 27.0819 44.5618 26.8832 44.3766 26.7194ZM27.6562 29.3749C27.8205 29.1902 27.9467 28.975 28.0277 28.7415C28.1087 28.5081 28.143 28.2609 28.1285 28.0143C28.1141 27.7676 28.0511 27.5261 27.9434 27.3038C27.8356 27.0814 27.6851 26.8824 27.5004 26.7182C27.3157 26.554 27.1005 26.4278 26.8671 26.3468C26.6336 26.2657 26.3865 26.2315 26.1398 26.2459C25.8931 26.2604 25.6517 26.3233 25.4293 26.4311C25.2069 26.5389 25.008 26.6894 24.8438 26.8741C24.2156 27.5772 22.7695 28.1256 21.5625 28.1256C20.3555 28.1256 18.9 27.5749 18.2812 26.8741C18.117 26.6894 17.9181 26.5389 17.6957 26.4311C17.4733 26.3233 17.2319 26.2604 16.9852 26.2459C16.7385 26.2315 16.4914 26.2657 16.2579 26.3468C16.0245 26.4278 15.8093 26.554 15.6246 26.7182C15.4399 26.8824 15.2894 27.0814 15.1816 27.3038C15.0739 27.5261 15.0109 27.7676 14.9965 28.0143C14.982 28.2609 15.0163 28.5081 15.0973 28.7415C15.1783 28.975 15.3045 29.1902 15.4688 29.3749C16.8164 30.8702 19.2609 31.8756 21.5625 31.8756C23.8641 31.8756 26.3086 30.8702 27.6562 29.3749Z" fill="currentColor" fillOpacity="0.7"/>
        </svg>
      );
    case 'glasses':
      return (
        <svg width="60" height="60" viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M46.875 9.375C46.3777 9.375 45.9008 9.57254 45.5492 9.92418C45.1975 10.2758 45 10.7527 45 11.25C45 11.7473 45.1975 12.2242 45.5492 12.5758C45.9008 12.9275 46.3777 13.125 46.875 13.125C47.8696 13.125 48.8234 13.5201 49.5266 14.2233C50.2299 14.9266 50.625 15.8804 50.625 16.875V30.4875C49.3031 29.3973 47.7304 28.6537 46.049 28.3238C44.3676 27.9939 42.6305 28.0882 40.9947 28.5981C39.3589 29.108 37.8759 30.0175 36.6798 31.2444C35.4836 32.4712 34.612 33.9768 34.1437 35.625H25.8562C25.388 33.9768 24.5164 32.4712 23.3202 31.2444C22.1241 30.0175 20.6411 29.108 19.0053 28.5981C17.3695 28.0882 15.6324 27.9939 13.951 28.3238C12.2696 28.6537 10.6969 29.3973 9.375 30.4875V16.875C9.375 15.8804 9.77009 14.9266 10.4733 14.2233C11.1766 13.5201 12.1304 13.125 13.125 13.125C13.6223 13.125 14.0992 12.9275 14.4508 12.5758C14.8025 12.2242 15 11.7473 15 11.25C15 10.7527 14.8025 10.2758 14.4508 9.92418C14.0992 9.57254 13.6223 9.375 13.125 9.375C11.1359 9.375 9.22822 10.1652 7.8217 11.5717C6.41518 12.9782 5.625 14.8859 5.625 16.875V38.4375C5.63004 41.0879 6.65535 43.6346 8.48816 45.5492C10.321 47.4637 12.8205 48.5991 15.4682 48.7197C18.1159 48.8403 20.7083 47.9369 22.7076 46.1969C24.7069 44.4569 25.9595 42.014 26.2055 39.375H33.7945C34.0405 42.014 35.2931 44.4569 37.2924 46.1969C39.2917 47.9369 41.8841 48.8403 44.5318 48.7197C47.1795 48.5991 49.679 47.4637 51.5118 45.5492C53.3446 43.6346 54.37 41.0879 54.375 38.4375V16.875C54.375 14.8859 53.5848 12.9782 52.1783 11.5717C50.7718 10.1652 48.8641 9.375 46.875 9.375ZM15.9375 45C14.6396 45 13.3708 44.6151 12.2916 43.894C11.2124 43.1729 10.3712 42.148 9.87454 40.9489C9.37784 39.7497 9.24788 38.4302 9.5011 37.1572C9.75431 35.8842 10.3793 34.7149 11.2971 33.7971C12.2149 32.8793 13.3842 32.2543 14.6572 32.0011C15.9302 31.7479 17.2497 31.8778 18.4489 32.3745C19.648 32.8712 20.6729 33.7124 21.394 34.7916C22.1151 35.8708 22.5 37.1396 22.5 38.4375C22.5 40.178 21.8086 41.8472 20.5779 43.0779C19.3472 44.3086 17.678 45 15.9375 45ZM44.0625 45C42.7646 45 41.4958 44.6151 40.4166 43.894C39.3374 43.1729 38.4962 42.148 37.9995 40.9489C37.5028 39.7497 37.3729 38.4302 37.6261 37.1572C37.8793 35.8842 38.5043 34.7149 39.4221 33.7971C40.3399 32.8793 41.5092 32.2543 42.7822 32.0011C44.0552 31.7479 45.3747 31.8778 46.5739 32.3745C47.773 32.8712 48.7979 33.7124 49.519 34.7916C50.2401 35.8708 50.625 37.1396 50.625 38.4375C50.625 40.178 49.9336 41.8472 48.7029 43.0779C47.4722 44.3086 45.803 45 44.0625 45Z" fill="currentColor" fillOpacity="0.7"/>
        </svg>
      );
    case 'shirt':
      return (
        <svg width="60" height="60" viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M22.5 7.5V6.25L5 11.25L7.5 25H15V55H45V25H52.5L55 11.25L37.5 6.25V7.5C37.5 9.48912 36.7098 11.3968 35.3033 12.8033C33.8968 14.2098 31.9891 15 30 15C28.0109 15 26.1032 14.2098 24.6967 12.8033C23.2902 11.3968 22.5 9.48912 22.5 7.5Z" stroke="currentColor" strokeOpacity="0.8" strokeWidth="1.5"/>
        </svg>
      );
    case 'pants':
      return (
        <svg width="60" height="60" viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M52.4719 50.1562L47.3156 8.90625C47.2014 7.99982 46.7602 7.16625 46.0749 6.56207C45.3896 5.9579 44.5073 5.62469 43.5937 5.625H16.4062C15.4926 5.62469 14.6104 5.9579 13.9251 6.56207C13.2397 7.16625 12.7986 7.99982 12.6844 8.90625L7.52812 50.1562C7.46161 50.6842 7.50822 51.2203 7.66486 51.7289C7.8215 52.2374 8.08459 52.7068 8.43664 53.1059C8.78868 53.5049 9.22163 53.8245 9.7067 54.0433C10.1918 54.2621 10.7179 54.3752 11.25 54.375H20.7867C21.6207 54.3751 22.4309 54.0973 23.0892 53.5854C23.7476 53.0735 24.2165 52.3567 24.4219 51.5484L30 29.9859L35.5758 51.5344C35.7786 52.3456 36.2467 53.0659 36.9058 53.5806C37.5648 54.0952 38.377 54.3749 39.2133 54.375H48.75C49.2821 54.3752 49.8082 54.2621 50.2933 54.0433C50.7784 53.8245 51.2113 53.5049 51.5634 53.1059C51.9154 52.7068 52.1785 52.2374 52.3351 51.7289C52.4918 51.2203 52.5384 50.6842 52.4719 50.1562ZM45.2109 22.3125C43.8695 22.0046 42.6381 21.3349 41.6505 20.3763C40.663 19.4177 39.957 18.2067 39.6094 16.875H44.5312L45.2109 22.3125ZM43.5937 9.375L44.0625 13.125H15.9375L16.4062 9.375H43.5937ZM15.4687 16.875H20.3906C20.043 18.2067 19.337 19.4177 18.3495 20.3763C17.3619 21.3349 16.1305 22.0046 14.7891 22.3125L15.4687 16.875ZM20.7867 50.625H11.25L14.2969 26.1867C16.739 25.9274 19.0296 24.8775 20.82 23.1966C22.6105 21.5157 23.8028 19.2959 24.2156 16.875H28.125V22.2656L20.7867 50.625ZM39.2086 50.6109L31.875 22.2656V16.875H35.7844C36.1972 19.2959 37.3895 21.5157 39.18 23.1966C40.9704 24.8775 43.261 25.9274 45.7031 26.1867L48.75 50.625L39.2086 50.6109Z" fill="currentColor" fillOpacity="0.7"/>
        </svg>
      );
    case 'shoes':
      return (
        <svg width="60" height="60" viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M47.7524 45H19.9074C12.5724 45 8.90742 45 6.66992 42.2075C2.42742 36.9075 7.26242 22.8075 10.1899 17.5C11.1824 23.5 21.4049 23.3325 25.1274 22.5C22.6474 17.5025 25.9574 15.835 27.6124 15H27.6174C34.9999 23.75 50.7874 28.51 54.6549 38.0475C56.3274 42.1675 51.5624 45 47.7524 45Z" stroke="currentColor" strokeOpacity="0.8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
          <path d="M5 35C15.4125 38.575 21.8275 39.61 30.055 37.01C32.5475 36.2225 33.7925 35.8275 34.57 35.88C35.345 35.935 36.9325 36.6725 40.1025 38.1525C44.06 39.9975 49.4925 41.06 55 38.395" stroke="currentColor" strokeOpacity="0.8" strokeWidth="1.5" strokeLinejoin="round"/>
          <path d="M33.75 23.75L37.5 20M38.75 27.5L42.5 23.75" stroke="currentColor" strokeOpacity="0.8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      );
    case 'jacket':
      return (
        <svg width="60" height="60" viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M22.5 7.5V6.25L5 11.25L7.5 25H15V55H45V25H52.5L55 11.25L37.5 6.25V7.5C37.5 9.48912 36.7098 11.3968 35.3033 12.8033C33.8968 14.2098 31.9891 15 30 15C28.0109 15 26.1032 14.2098 24.6967 12.8033C23.2902 11.3968 22.5 9.48912 22.5 7.5Z" stroke="currentColor" strokeOpacity="0.8" strokeWidth="1.5"/>
          <path d="M30 15V55" stroke="currentColor" strokeOpacity="0.5" strokeWidth="1.5" strokeDasharray="4 3"/>
        </svg>
      );
    case 'torso':
      return <img src={torsoSvg} width="60" height="60" alt="torso" />;
    case 'gloves':
      return <img src={glovesSvg} width="60" height="60" alt="gloves" />;
    case 'vest':
      return <img src={vestSvg} width="60" height="60" alt="vest" />;
    case 'necklace':
      return (
        <svg width="60" height="60" viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M10 16C10 16 16 32 30 32C44 32 50 16 50 16" stroke="currentColor" strokeOpacity="0.8" strokeWidth="1.5" strokeLinecap="round"/>
          <path d="M27 32L30 42L33 32" stroke="currentColor" strokeOpacity="0.8" strokeWidth="1.5" strokeLinejoin="round"/>
          <circle cx="30" cy="42" r="4" stroke="currentColor" strokeOpacity="0.8" strokeWidth="1.5"/>
        </svg>
      );
    case 'bag':
      return (
        <svg width="65" height="65" viewBox="0 0 65 65" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M55.86 49.4599V39.605C55.86 39.0925 55.4125 38.645 54.9 38.645H51.38V32.565C51.38 27.8925 49.6525 23.5399 46.7725 20.2775L47.86 10.7405C47.86 10.4855 47.795 10.1655 47.605 9.97295C47.4125 9.78045 47.1575 9.65295 46.9 9.65295H41.0749C40.5624 9.65295 40.1799 10.038 40.1149 10.4854L39.6024 15.1579C37.4274 14.2629 35.1224 13.8129 32.6275 13.8129H32.435C30.0025 13.8129 27.635 14.3254 25.4601 15.1579L24.9475 10.4854C24.8825 9.97293 24.5 9.65295 23.9875 9.65295H18.1625C17.9075 9.65295 17.65 9.78045 17.4575 9.97295C17.2675 10.1655 17.075 10.4205 17.14 10.7405L18.2275 20.3405C15.3475 23.6055 13.62 27.9554 13.62 32.6279V38.7079H10.1C9.58747 38.7079 9.13997 39.1554 9.13997 39.6679V49.5229C9.13997 51.3154 10.6124 52.7879 12.405 52.7879H13.685C14.005 54.2604 15.285 55.4129 16.885 55.4129H48.0525C49.6525 55.4129 50.9325 54.2604 51.2525 52.7879H52.5325C54.3874 52.7254 55.86 51.2529 55.86 49.4604L55.86 49.4599Z" fill="currentColor" fillOpacity="0.5"/>
          <path d="M43.7651 37.5549H21.2349C20.7224 37.5549 20.2749 38.0024 20.2749 38.5149V49.2675C20.2749 49.78 20.7224 50.2275 21.2349 50.2275H43.7624C44.2749 50.2275 44.7224 49.78 44.7224 49.2675L44.7249 38.5149C44.7249 38.0049 44.2749 37.5549 43.7649 37.5549H43.7651Z" fill="currentColor" fillOpacity="0.5"/>
          <path d="M32.5651 20.4674H32.5001C25.7801 20.4674 20.3401 25.9074 20.3401 32.6274C20.3401 33.1399 20.7876 33.5874 21.3001 33.5874H43.8275C44.34 33.5874 44.7875 33.1399 44.7875 32.6274C44.725 25.9725 39.2851 20.4674 32.5646 20.4674H32.5651Z" fill="currentColor" fillOpacity="0.5"/>
        </svg>
      );
    default:
      return null;
  }
};

const ClothingWearSlot: React.FC<ClothingWearSlotProps> = ({ slotIndex, definition, slot, isOtherPlayer, otherInventoryId }) => {
  const dispatch = useAppDispatch();
  const { leftInventory, rightInventory } = useAppSelector((state) => state.inventory);
  const timerRef = useRef<number | null>(null);
  const hoveredRef = useRef(false);
  const activeInventory = isOtherPlayer ? rightInventory : leftInventory;
  const slotData = slot || { slot: (activeInventory.clothing?.offset || 1200) + slotIndex + 1 };
  const hasItem = isSlotWithItem(slotData);
  const slotItem = hasItem ? (slotData as SlotWithItem) : null;
  const rarityEnabled = isRarityEnabled();
  const rarity = slotItem
    ? rarityEnabled ? normalizeRarity(slotItem.metadata?.rarity || Items[slotItem.name]?.rarity) || 'common' : 'common'
    : undefined;
  const rarityColors = getColor(rarity);
  const borderColor = rarity && rarity !== 'common' ? rarityColors.text : 'var(--color-slot-border)';
  const isLoadout = Config.layout === 'loadout';
  const slotBackground = isLoadout || !rarityEnabled ? undefined : rarityColors.background;

  const [{ isOver }, drop] = useDrop<DragSource, void, { isOver: boolean }>(
    () => ({
      accept: 'SLOT',
      collect: (monitor) => ({
        isOver: monitor.isOver() && monitor.canDrop(),
      }),
      canDrop: (source) =>
        !hasItem &&
        (source.inventory === InventoryType.PLAYER || source.inventory === InventoryType.BACKPACK) &&
        clothingItemMatchesDefinition(source.item as SlotWithItem, definition),
      drop: (source) => {
        const fromInventory =
          source.inventoryId || (source.inventory === InventoryType.BACKPACK ? leftInventory.backpack?.id : leftInventory.id);

        if (isOtherPlayer) {
          fetchNui<boolean>('moveToOtherClothingSlot', {
            toSlot: slotIndex,
            fromSlot: source.item.slot,
            fromInventory,
            toInventory: otherInventoryId ?? activeInventory.id,
          });
        } else {
          fetchNui<boolean>('moveToClothingSlot', {
            toSlot: slotIndex,
            fromSlot: source.item.slot,
            fromInventory,
          });
        }
      },
    }),
    [activeInventory.id, definition, hasItem, isOtherPlayer, leftInventory.backpack?.id, leftInventory.id, otherInventoryId, slotIndex]
  );

  const [{ isDragging }, drag, preview] = useDrag<DragSource, void, { isDragging: boolean }>(
    () => ({
      type: 'SLOT',
      collect: (monitor) => ({ isDragging: monitor.isDragging() }),
      canDrag: () => hasItem,
      item: () =>
        hasItem && slotItem
          ? {
              inventory: isOtherPlayer ? InventoryType.OTHER_CLOTHING : InventoryType.CLOTHING,
              inventoryId: isOtherPlayer ? (otherInventoryId ?? activeInventory.id) : leftInventory.id,
              item: { name: slotItem.name, slot: slotItem.slot },
              metadata: { ...(slotItem.metadata || {}), clothingSlot: slotIndex },
              image: `url(${getItemUrl(slotItem) || 'none'})`,
            }
          : null,
    }),
    [activeInventory.id, hasItem, isOtherPlayer, leftInventory.id, otherInventoryId, slotIndex, slotItem]
  );

  useEffect(() => {
    if (transparentDragImage) {
      preview(transparentDragImage, { captureDraggingState: true });
    }
  }, [preview]);

  useEffect(() => {
    return () => {
      hoveredRef.current = false;

      if (timerRef.current) {
        clearTimeout(timerRef.current);
        timerRef.current = null;
      }
    };
  }, []);

  const refs = useMergeRefs([drop, drag]);

  const amountText = formatItemAmount(slotItem?.name, slotItem?.count);

  const weightText = useMemo(() => {
    if (!slotItem?.weight) return '';

    if (slotItem.weight >= 1000) {
      return `${(slotItem.weight / 1000).toLocaleString('en-us', {
        minimumFractionDigits: 1,
      })}kg `;
    }

    return `${slotItem.weight.toLocaleString('en-us', {
      minimumFractionDigits: 1,
    })}g `;
  }, [slotItem]);

  const durability = getItemQuality(slotItem);

  const itemLabel = slotItem?.metadata?.label ?? (slotItem?.name ? Items[slotItem.name]?.label ?? slotItem.name : '');

  return (
    <div className="clothing-slot-wrap">
      <div className="clothing-slot-title">{definition.label}</div>
      <div
        ref={refs}
        className={`clothing-slot-shell relative w-[6.75rem] h-[6.75rem] border border-transparent item-slot-border${hasItem && isLoadout && rarityEnabled ? ' has-item rarity-framed' : ''}${rarityEnabled && rarity ? ` rarity-${rarity}` : ''}`}
        style={
          {
            opacity: isDragging ? 0.4 : 1,
            background: slotBackground,
            '--borderColor': isOver ? 'var(--accent-lime)' : borderColor,
            '--rarityColor': rarityColors.text,
          } as React.CSSProperties
        }
      >
        {isLoadout && durability !== null && (
          <span className="slot-quality-bar" aria-label={`Quality ${Math.round(durability)}%`}>
            <span style={{ width: `${durability}%` }} />
          </span>
        )}
        {!hasItem && <div className="clothing-slot-icon">{renderClothingIcon(definition.icon)}</div>}

        {hasItem && slotItem && (
          <div
            className="p-1.5 text-secondary text-xs relative w-full h-full cursor-pointer"
            onMouseEnter={() => {
              hoveredRef.current = true;
              timerRef.current = window.setTimeout(() => {
                if (hoveredRef.current) {
                  dispatch(openTooltip({ item: slotItem, inventoryType: InventoryType.PLAYER }));
                }
              }, 500);
            }}
            onMouseLeave={() => {
              hoveredRef.current = false;
              if (timerRef.current) {
                clearTimeout(timerRef.current);
                timerRef.current = null;
              }
              dispatch(closeTooltip());
            }}
          >
            <img
              src={`${slotItem.name ? getItemUrl(slotItem) : 'none'}`}
              className="slot-content-image slot-content-image--centered absolute w-[4.125rem] h-[4.125rem] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-0"
              alt={slotItem.name}
              loading="lazy"
              decoding="async"
              draggable={false}
              onError={applyItemImageFallback}
            />

            <div className="leading-3 font-[350] relative z-10">
              {rarityEnabled && rarity && (
                <p
                  className="absolute top-0 right-0 text-[0.625rem] font-medium"
                  style={{
                    color: rarity === 'common' ? 'var(--tx)' : getColor(rarity).text,
                  }}
                >
                  {rarity.toUpperCase()}
                </p>
              )}
              <div>
                <p className="slot-content-quantity text-[0.6875rem]">{amountText}</p>
              </div>
            </div>

            <p className="text-[0.6875rem] absolute bottom-1.5 right-1.5">{weightText}</p>

            <p className="slot-content-label absolute text-white w-1/2 bottom-[0.4375rem] left-[0.4375rem] font-semibold z-10">{itemLabel}</p>

            {!isLoadout && durability !== null && (
              <div className="absolute h-1 w-full bottom-0 left-0">
                <div
                  className="h-full"
                  style={{
                    backgroundColor: getColor(rarity || 'common').text,
                    width: `${durability}%`,
                  }}
                />
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default ClothingWearSlot;
