const dateFormat = new Intl.DateTimeFormat('es-ES', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
const moneyFormat = new Intl.NumberFormat('es-ES');

export const formatDate = (seconds: number) => dateFormat.format(new Date(seconds * 1000));
export const formatMoney = (value: number) => `$${moneyFormat.format(value)}`;

export const ACTION_LABELS: Record<string, string> = {
  goto: 'Ir al jugador',
  bring: 'Traer jugador',
  spectate: 'Espectar',
  freeze: 'Congelar',
  revive: 'Reanimar',
  heal: 'Curar',
  kill: 'Matar',
  kick: 'Expulsar',
  ban: 'Banear',
  viewInventory: 'Ver inventario',
  money: 'Dinero',
  setJob: 'Cambiar trabajo',
  setDuty: 'Cambiar servicio',
  giveItem: 'Dar objeto',
  clearInventory: 'Vaciar inventario',
  giveVehicle: 'Dar vehículo',
  noclip: 'Noclip',
  god: 'Modo dios',
  invisible: 'Invisible',
  players: 'Ver jugadores',
  tpWaypoint: 'Ir al marcador',
  tpCoords: 'Ir a coordenadas',
  vehicleRepair: 'Reparar vehículo',
  vehicleFlip: 'Enderezar vehículo',
  vehicleDelete: 'Borrar vehículo',
  spawnVehicle: 'Crear vehículo',
  clearVehicles: 'Limpiar vehículos',
  announce: 'Anuncio',
  weather: 'Clima',
  time: 'Hora',
  saveAll: 'Guardar jugadores',
  unban: 'Quitar baneo',
  banOffline: 'Banear licencia',
};
