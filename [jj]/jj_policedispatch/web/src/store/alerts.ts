import { create } from 'zustand';
import { isBrowser } from '../utils/nui';

export const useAlertsStore = create<any>((e) => ({
  alerts: [
    {
      id: 1,
      idPlayer: 1,
      title: 'awwdaw',
      zone: 'awdawd',
      distance: 100,
      textAlert:
        'Alerta de prueba awd awd awd awd awdawdawdawxawdaxa wdawxawd awaw dawxwad awdaxawd axawdawdawdax awdawdawdawdawdaxawdawxawd awdawxawwdawdawdawdaxawd awdawdaxawd awdaw dawd awdawdaxawdawxaw dawdaxawdawdaxawd awawdawdawdawdadawdaxawd awxawd awdaxaw !!! awxawdadawdax awdawxawd axawd axawd axawd axawd awdadawdadawdawdawdawwdawda xawdadawdawaxa',
      timeSend: Date.now(),
    },
  ],
  isActive: !!isBrowser(),
  setAlerts: (t) =>
    e({
      alerts: t,
    }),
  addNewAlert: (t) =>
    e((e) => ({
      alerts: [...e.alerts, t],
    })),
  updateAlertUnit: (t, n) =>
    e((e) => ({
      alerts: e.alerts.map((alert) =>
        alert.id === t
          ? {
              ...alert,
              assignedUnit: n,
            }
          : alert,
      ),
    })),
  setActive: () =>
    e((e) => ({
      isActive: !e.isActive,
    })),
  deleteAlert: (t) =>
    e((e) => ({
      alerts: e.alerts.filter((alert) => alert.id !== t),
    })),
}));
