import { create } from 'zustand';

export const mockRadioChannels = [
  {
    id: 'mando-lspd',
    freq: 100,
    zone: 'lspd',
    name: '07-MANDO-00',
    members: [
      {
        id_group: 'mando-lssd',
        citizenid: '12345',
        fullname: 'Jhon Doe (123)',
        rank: 'Oficial III',
        divisions: ['SOB', 'ASD'],
        status: true,
      },
      {
        id_group: 'mando-lssd',
        citizenid: '13456',
        fullname: 'Pepe Villuela (433)',
        rank: 'Oficial II',
        divisions: ['SOB', 'ASD'],
        status: false,
      },
    ],
  },
  {
    id: 'adam1-lspd',
    freq: 100,
    zone: 'lspd',
    name: '01-ADAM-00',
  },
  {
    id: 'adam2-lspd',
    freq: 100,
    zone: 'lspd',
    name: '02-ADAM-02',
  },
  {
    id: 'adam3-lspd',
    freq: 100,
    zone: 'lspd',
    name: '02-ADAM-02',
  },
  {
    id: 'mando-lssd',
    freq: 100,
    zone: 'lssd',
    name: '07-MANDO-00',
  },
  {
    id: 'adam1-lssd',
    freq: 100,
    zone: 'lssd',
    name: '01-ADAM-01',
  },
  {
    id: 'adam2-lssd',
    freq: 100,
    zone: 'lssd',
    name: '02-ADAM-02',
  },
  {
    id: 'adam3-lssd',
    freq: 100,
    zone: 'lssd',
    name: '03-ADAM-03',
  },
  {
    id: 'adam4-lssd',
    freq: 100,
    zone: 'lssd',
    name: '04-ADAM-04',
  },
];

export const useRadioStore = create<any>((e) => ({
  radioChannels: mockRadioChannels,
  showMembersInHUD: localStorage.getItem('radioShowMembersHUD') !== 'false',
  setShowMembersInHUD: (t) => {
    localStorage.setItem('radioShowMembersHUD', String(t));
    e({
      showMembersInHUD: t,
    });
  },
  setRadioChannels: (t) =>
    e({
      radioChannels: t,
    }),
  setRadioChannelMembers: (t, n) =>
    e((e) => ({
      radioChannels: e.radioChannels.map((radioChannel) =>
        radioChannel.id === n
          ? {
              ...radioChannel,
              members: t,
            }
          : radioChannel,
      ),
    })),
  addRadioChannelMember: (t, n) =>
    e((e) => ({
      radioChannels: e.radioChannels.map((radioChannel) =>
        radioChannel.id === n
          ? {
              ...radioChannel,
              members: [...radioChannel.members, t],
            }
          : radioChannel,
      ),
    })),
  updateMemberStatus: (t, n) =>
    e((e) => ({
      radioChannels: e.radioChannels.map((radioChannel) => ({
        ...radioChannel,
        members: radioChannel.members?.map((e) =>
          e.citizenid === t
            ? {
                ...e,
                status: n,
              }
            : e,
        ),
      })),
    })),
  updateMemberMuted: (t, n) =>
    e((e) => ({
      radioChannels: e.radioChannels.map((radioChannel) => ({
        ...radioChannel,
        members: radioChannel.members?.map((e) =>
          e.citizenid === t
            ? {
                ...e,
                isMuted: n,
              }
            : e,
        ),
      })),
    })),
  removeMember: (t) =>
    e((e) => ({
      radioChannels: e.radioChannels.map((radioChannel) => ({
        ...radioChannel,
        members: radioChannel.members?.filter((e) => e.citizenid !== t),
      })),
    })),
}));
