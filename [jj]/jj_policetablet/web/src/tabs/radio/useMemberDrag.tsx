import { Badge, Group, Text } from '@mantine/core';
import { useCallback, useEffect, useRef, useState } from 'react';
import { IconX5 } from '../../icons';
import { useRadioStore } from '../../state/radio';
import { fetchNui, isBrowser } from '../../utils/nui';

export function useMemberDrag() {
  const { radioChannels, setRadioChannelMembers } = useRadioStore();
  const [dragging, setDragging] = useState<any>(null);
  const ref = useRef<any>(null);
  const ref2 = useRef<any>(0);
  const ref3 = useRef<any>({
    x: 0,
    y: 0,
  });
  const a = useCallback(
    async (h, p, g, v) => {
      if (h === p) {
        return;
      }
      const y = radioChannels.find((radioChannel) => radioChannel.id === h);
      const b = radioChannels.find((radioChannel) => radioChannel.id === p);
      if (!y?.members || !b) {
        return;
      }
      const S = y.members[g];
      if (!S || b.members?.some((E) => E.citizenid === S.citizenid)) {
        return;
      }
      const w = [...y.members];
      w.splice(g, 1);
      const j = b.members ? [...b.members] : [];
      j.splice(v, 0, S);
      if (
        (await fetchNui('dispatch_moveMember', {
          citizenid: S.citizenid,
          lastId: h,
          newId: p,
          newFreq: b.freq,
          zone: b.zone,
        })) &&
        isBrowser()
      ) {
        setRadioChannelMembers(w, h);
        setRadioChannelMembers(j, p);
      }
    },
    [radioChannels, setRadioChannelMembers],
  );
  const handlePointerDown = useCallback((event, p, g, v) => {
    event.stopPropagation();
    ref3.current = {
      x: event.clientX,
      y: event.clientY,
    };
    setDragging({
      member: p,
      sourceRadioId: g,
      index: v,
    });
  }, []);
  const setFloatingRef = useCallback((h) => {
    ref.current = h;
    if (h) {
      h.style.position = 'fixed';
      h.style.zIndex = '9999';
      h.style.pointerEvents = 'none';
      h.style.left = `${ref3.current.x}px`;
      h.style.top = `${ref3.current.y}px`;
      h.style.transform = 'translate(-50%, -50%)';
    }
  }, []);
  useEffect(() => {
    if (!dragging) {
      return;
    }
    document.body.style.cursor = 'grabbing';
    const h = (event) => {
      event.preventDefault();
      ref3.current = {
        x: event.clientX,
        y: event.clientY,
      };
      if (ref2.current) {
        cancelAnimationFrame(ref2.current);
      }
      ref2.current = requestAnimationFrame(() => {
        if (ref.current) {
          ref.current.style.left = `${event.clientX}px`;
          ref.current.style.top = `${event.clientY}px`;
        }
      });
    };
    const p = (event) => {
      event.preventDefault();
      if (ref2.current) {
        cancelAnimationFrame(ref2.current);
      }
      if (!dragging) {
        return;
      }
      if (ref.current) {
        ref.current.style.display = 'none';
      }
      const v = document.elementFromPoint(event.clientX, event.clientY);
      if (v) {
        const y = v.closest('[data-radio-id]');
        let b = null;
        let S = 0;
        if (y) {
          b = y.getAttribute('data-radio-id');
          const w = v.closest('[data-member-index]');
          if (w) {
            S = parseInt(w.getAttribute('data-member-index'), 10);
          } else {
            S = radioChannels.find((radioChannel) => radioChannel.id === b)?.members?.length ?? 0;
          }
        }
        if (b) {
          a(dragging.sourceRadioId, b, dragging.index, S);
        }
      }
      setDragging(null);
    };
    window.addEventListener('pointermove', h, {
      passive: false,
    });
    window.addEventListener('pointerup', p);
    return () => {
      window.removeEventListener('pointermove', h);
      window.removeEventListener('pointerup', p);
      if (ref2.current) {
        cancelAnimationFrame(ref2.current);
      }
      document.body.style.cursor = '';
    };
  }, [dragging, radioChannels, a]);
  return {
    dragging,
    setFloatingRef,
    handlePointerDown,
  };
}

export function DraggedMember({ member }: any) {
  return (
    <Group
      align="center"
      justify="space-between"
      style={{
        backgroundColor: 'rgba(25, 25, 25, 0.9)',
        border: '1px solid rgba(255, 255, 255, 0.15)',
        borderRadius: '6px',
        padding: '6px 12px',
        pointerEvents: 'none',
        boxShadow: '0 4px 12px rgba(0,0,0,0.5)',
      }}
    >
      <Group gap="xs">
        <IconX5 size={8} color={member.status ? 'green' : 'red'} />
        <Text size="xs" fw="bold" c="white">
          {member.fullname}
        </Text>
      </Group>
      <Badge size="xs" variant="light" color="gray">
        {member.rank}
      </Badge>
    </Group>
  );
}
