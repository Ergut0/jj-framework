import React, { useEffect, useRef, useCallback } from 'react';
import { fetchNui } from '../../utils/fetchNui';

const ClothingBodyPatch: React.FC<{ isActive: boolean }> = ({ isActive }) => {
  const windowRef = useRef<HTMLDivElement>(null);

  const sendTarget = useCallback(() => {
    const element = windowRef.current;
    if (!element) return;

    const rect = element.getBoundingClientRect();
    const viewportWidth = window.innerWidth || document.documentElement.clientWidth;
    const viewportHeight = window.innerHeight || document.documentElement.clientHeight;

    if (!viewportWidth || !viewportHeight) return;

    fetchNui('setClothingPreviewTarget', {
      x: (rect.left + rect.width / 2) / viewportWidth,
      y: (rect.top + rect.height / 2) / viewportHeight,
    }).catch(() => undefined);
  }, []);

  useEffect(() => {
    const resizeObserver = typeof ResizeObserver !== 'undefined' ? new ResizeObserver(sendTarget) : undefined;
    if (windowRef.current && resizeObserver) {
      resizeObserver.observe(windowRef.current);
    }
    window.addEventListener('resize', sendTarget);
    return () => {
      resizeObserver?.disconnect();
      window.removeEventListener('resize', sendTarget);
    };
  }, [sendTarget]);

  useEffect(() => {
    if (!isActive) return;
    const t = setTimeout(sendTarget, 400);
    return () => clearTimeout(t);
  }, [isActive, sendTarget]);

  return (
    <div className="clothing-body-panel">
      <div ref={windowRef} className="clothing-body-window" />
    </div>
  );
};

export default ClothingBodyPatch;
