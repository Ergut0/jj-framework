import { create } from 'zustand';

export const useAgentStore = create<any>((e) => ({
  agent: null,
  setAgent: (t) =>
    e((n) =>
      !t || !t.citizenid
        ? n
        : {
            agent: t,
          },
    ),
  setAgentRadioGroup: (t) =>
    e((n) => ({
      agent: n.agent
        ? {
            ...n.agent,
            id_group: t,
          }
        : n.agent,
    })),
  changeAgentStatus: () =>
    e((t) => ({
      agent: t.agent
        ? {
            ...t.agent,
            status: !t.agent.status,
          }
        : t.agent,
    })),
  setAgentStatus: (t) =>
    e((n) => ({
      agent: n.agent
        ? {
            ...n.agent,
            status: t,
          }
        : n.agent,
    })),
  setAgentMuted: (t) =>
    e((n) => ({
      agent: n.agent
        ? {
            ...n.agent,
            isMuted: t,
          }
        : n.agent,
    })),
}));

export const useRadioStore = create<any>((e) => ({
  radioChannels: [],
  setRadioChannels: (t) =>
    e({
      radioChannels: t,
    }),
  setRadioChannelMembers: (t, n) =>
    e((r) => ({
      radioChannels: r.radioChannels.map((radioChannel) =>
        radioChannel.id === n
          ? {
              ...radioChannel,
              members: t,
            }
          : radioChannel,
      ),
    })),
  addRadioChannelMember: (t, n) =>
    e((r) => ({
      radioChannels: r.radioChannels.map((radioChannel) =>
        radioChannel.id === n
          ? {
              ...radioChannel,
              members: radioChannel.members ? [...radioChannel.members, t] : [t],
            }
          : radioChannel,
      ),
    })),
  updateMemberStatus: (t, n) =>
    e((r) => ({
      radioChannels: r.radioChannels.map((radioChannel) => ({
        ...radioChannel,
        members:
          radioChannel.members?.map((s) =>
            s.citizenid === t
              ? {
                  ...s,
                  status: n,
                }
              : s,
          ) || [],
      })),
    })),
  updateMemberMuted: (t, n) =>
    e((r) => ({
      radioChannels: r.radioChannels.map((radioChannel) => ({
        ...radioChannel,
        members:
          radioChannel.members?.map((s) =>
            s.citizenid === t
              ? {
                  ...s,
                  isMuted: n,
                }
              : s,
          ) || [],
      })),
    })),
  removeMember: (t) =>
    e((n) => ({
      radioChannels: n.radioChannels.map((radioChannel) => ({
        ...radioChannel,
        members: radioChannel.members?.filter((o) => o.citizenid !== t) || [],
      })),
    })),
}));

export const useTalkingStore = create<any>((e) => ({
  talkingPlayers: {},
  setTalking: (t, n) =>
    e((r) => ({
      talkingPlayers: {
        ...r.talkingPlayers,
        [t]: n,
      },
    })),
}));
