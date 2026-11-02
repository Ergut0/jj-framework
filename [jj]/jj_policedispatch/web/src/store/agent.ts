import { create } from 'zustand';

export const useAgentStore = create<any>((e) => ({
  agent: {
    id_group: '',
    citizenid: 'CAWD1234',
    fullname: 'Maximiliano Pantoja (452)',
    status: true,
    isMuted: false,
    rank: 'Teniente I',
    divisions: ['ASD'],
  },
  setAgent: (t) =>
    e((e) =>
      !t || !t.citizenid
        ? e
        : {
            agent: t,
          },
    ),
  setAgentRadioGroup: (t) =>
    e((e) => ({
      agent: e.agent
        ? {
            ...e.agent,
            id_group: t,
          }
        : e.agent,
    })),
  changeAgentStatus: () =>
    e((e) => ({
      agent: e.agent
        ? {
            ...e.agent,
            status: !e.agent.status,
          }
        : e.agent,
    })),
  setAgentStatus: (t) =>
    e((e) => ({
      agent: e.agent
        ? {
            ...e.agent,
            status: t,
          }
        : e.agent,
    })),
  setAgentMuted: (t) =>
    e((e) => ({
      agent: e.agent
        ? {
            ...e.agent,
            isMuted: t,
          }
        : e.agent,
    })),
}));
