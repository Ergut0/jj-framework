import { Box, FloatingWindow, Switch } from '@mantine/core';
import { useEffect, useRef, useState } from 'react';
import { FaLock, FaUnlock } from 'react-icons/fa6';
import { useAgentStore } from '../store/agent';
import { useLockStore } from '../store/lock';
import { useRadioStore } from '../store/radio';
import { useReferenceStore } from '../store/references';
import { RadioZoneTabs } from '../tabs/RadioZoneTabs';
import { fetchNui, useNuiEvent } from '../utils/nui';
import { HeaderTabs } from './HeaderTabs';
import styles from '../styles/ActionMenu.module.css';

export const MENU_BASE_WIDTH = 443;

export const MENU_BASE_HEIGHT = 510;

export const MENU_MAX_WIDTH = 800;

export const MENU_MAX_HEIGHT = 1e3;

export function ActionMenu({ active }: any) {
  const { unlocked, changeLock } = useLockStore();
  const [tab, setTab] = useState<any>(0);
  const { agent, changeAgentStatus, setAgentStatus, setAgentRadioGroup } = useAgentStore();
  const { updateMemberStatus, setRadioChannelMembers, removeMember } = useRadioStore();
  const [refreshData, setRefreshData] = useState<any>(0);
  const setPositionRef = useRef<any>(null);
  const [size, setSize] = useState<any>(loadActionMenuSize);
  const ref = useRef<any>(null);
  let onMouseDown;
  onMouseDown = (event) => {
    event.preventDefault();
    event.stopPropagation();
    ref.current = {
      x: event.clientX,
      y: event.clientY,
      w: size.width,
      h: size.height,
    };
    const t = (event2) => {
      if (ref.current) {
        setSize({
          width: Math.min(
            MENU_BASE_HEIGHT,
            Math.max(MENU_BASE_WIDTH, ref.current.w + event2.clientX - ref.current.x),
          ),
          height: Math.min(
            MENU_MAX_HEIGHT,
            Math.max(MENU_MAX_WIDTH, ref.current.h + event2.clientY - ref.current.y),
          ),
        });
      }
    };
    const n = () => {
      document.removeEventListener('mousemove', t);
      document.removeEventListener('mouseup', n);
      ref.current = null;
    };
    document.addEventListener('mousemove', t);
    document.addEventListener('mouseup', n);
  };
  useEffect(() => {
    localStorage.setItem('actionMenuSize', JSON.stringify(size));
  }, [size]);
  useEffect(() => {
    const e = localStorage.getItem('actionMenuPosition');
    if (e && setPositionRef.current) {
      const t = JSON.parse(e);
      setPositionRef.current(t);
    }
  }, []);
  const { setBlipColor: M, setBlipId: N } = useReferenceStore();
  useNuiEvent('refreshBlipGroup', function (e) {
    M(e.colorId);
    N(e.blipId);
  });
  useNuiEvent('memberStatusChanged', function (e) {
    if (agent?.citizenid && e.citizenid === agent.citizenid) {
      setAgentStatus(e.status);
    }
    updateMemberStatus(e.citizenid, e.status);
  });
  useNuiEvent('refreshMembersChannels', function (e) {
    if (e?.movedCitizenId) {
      removeMember(e.movedCitizenId);
    }
    if (e?.lastChannel) {
      setRadioChannelMembers(e.lastChannel.members, e.lastChannel.id);
    }
    if (e?.newChannel) {
      setRadioChannelMembers(e.newChannel.members, e.newChannel.id);
    }
    if (agent?.citizenid && e?.movedCitizenId === agent.citizenid && typeof e.newRadioGroup == 'string') {
      setAgentRadioGroup(e.newRadioGroup);
    }
  });
  useNuiEvent('toggleStatus', async function () {
    if (!agent) {
      return;
    }
    const status = !agent.status;
    changeAgentStatus();
    if (agent.citizenid) {
      updateMemberStatus(agent.citizenid, status);
    }
    await fetchNui('setStatus', {
      status,
    });
  });
  useNuiEvent('refreshData', function () {
    setRefreshData(increment);
    console.log('refreshData');
  });
  return (
    <FloatingWindow
      className={styles.container}
      style={{
        width: size.width,
        height: size.height,
        display: active ? undefined : 'none',
      }}
      enabled={unlocked}
      onPositionChange={saveActionMenuPosition}
      initialPosition={loadActionMenuPosition()}
      setPositionRef={setPositionRef}
    >
      <Box className={styles.header}>
        <HeaderTabs tab={tab} onTabChange={setTab} />
        <Switch
          className={styles.headerItemSwitch}
          withThumbIndicator={false}
          checked={agent?.status || false}
          color="green.2"
          onChange={async () => {
            if (!agent) {
              return;
            }
            const status = !agent.status;
            changeAgentStatus();
            if (agent.citizenid) {
              updateMemberStatus(agent.citizenid, status);
            }
            await fetchNui('setStatus', {
              status,
            });
          }}
        />
        <Box className={styles.headerItemLocked} onClick={changeLock}>
          {unlocked ? <FaUnlock size={18} /> : <FaLock size={18} />}
        </Box>
      </Box>
      <Box
        className={styles.body}
        style={{
          flex: 1,
          minHeight: 0,
        }}
      >
        <RadioZoneTabs tab={tab} refreshData={refreshData} />
      </Box>
      <Box className={styles.resizeHandle} onMouseDown={onMouseDown} />
    </FloatingWindow>
  );
}

export function increment(e) {
  return e + 1;
}

export function saveActionMenuPosition(e) {
  const t: any = {
    top: e.y,
    left: e.x,
  };
  localStorage.setItem('actionMenuPosition', JSON.stringify(t));
}

export function loadActionMenuPosition() {
  const e = localStorage.getItem('actionMenuPosition');
  return e
    ? JSON.parse(e)
    : {
        top: 200,
        left: 200,
      };
}

export function loadActionMenuSize() {
  const e = localStorage.getItem('actionMenuSize');
  return e
    ? JSON.parse(e)
    : {
        width: 450,
        height: 800,
      };
}
