import type React from 'react';
import noItemImage from '../assets/svg/noitem.svg';

const transparentImage = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/%3E';

export const applyItemImageFallback = (event: React.SyntheticEvent<HTMLImageElement>) => {
  const image = event.currentTarget;

  if (image.dataset.fallbackApplied) return;

  image.dataset.fallbackApplied = 'true';
  image.classList.add('item-image-fallback');
  image.style.setProperty('--item-fallback-image', `url("${noItemImage}")`);
  image.src = transparentImage;
};
