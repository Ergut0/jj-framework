import { create } from 'zustand';

export const useAlertsStore = create<any>((e) => ({
  alerts: [],
  hiddenIds: [],
  loaded: false,
  setAlerts: (t) =>
    e({
      alerts: t,
      loaded: true,
    }),
  addAlert: (t) =>
    e((n) => ({
      alerts: [t, ...n.alerts.filter((alert) => alert.id !== t.id)],
    })),
  hideAlert: (t) =>
    e((n) => ({
      hiddenIds: [...n.hiddenIds, t],
    })),
  hideAlerts: (t) =>
    e((n) => ({
      hiddenIds: [...n.hiddenIds, ...t],
    })),
  setAssignedUnit: (t, n) =>
    e((r) => ({
      alerts: r.alerts.map((alert) =>
        alert.id === t
          ? {
              ...alert,
              assignedUnit: n,
            }
          : alert,
      ),
    })),
}));
