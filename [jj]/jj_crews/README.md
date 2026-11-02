# jj_crews

Gestión de crews de pilotos para jj-framework: creación, miembros, rangos, banco, ranking y administración.
**No incluye sistema de carreras**: otros recursos, como `jj_racing`, suman puntos y victorias mediante exports.

Dependencias: `jj-framework`, `ox_lib`, `oxmysql`.

## Instalación
1. Importa `sql/crews.sql` en tu base de datos.
2. `server.cfg`:
   ```
   ensure jj_crews
   # opcional: webhook de Discord para logs (solo servidor)
   set crews_webhook "https://discord.com/api/webhooks/..."
   # opcional: acceso admin por ACE, además de los administradores de jj-framework
   add_ace group.mod crews.admin allow
   ```
3. La carpeta `web/dist` ya está compilada. Reconstrúyela solo si cambias la UI.

## Uso
- Objeto `tablet_crew` de ox_inventory: panel de jugador.
- `/crewadmin`: panel de administración. El servidor valida `JJ.IsAdmin` o el ACE `crews.admin`; la UI admin solo se monta si el servidor lo confirma.

## Configuración
Todo en `config.lua`: idioma (`es`/`en`), comando de administración, límites, costes, rangos por defecto, permisos, nombres prohibidos, rate limit y debug.
Los ajustes de `Config.Settings` se pueden editar en vivo desde el panel admin (se guardan en `crew_settings`).

Las columnas y campos `citizenid` guardan el `identifier` del personaje de jj-framework.

## Exports (servidor)
```lua
exports.jj_crews:GetPlayerCrew(source)          -- crew del jugador o nil
exports.jj_crews:GetCrewByCitizenId(identifier)
exports.jj_crews:IsInCrew(source)               -- boolean
exports.jj_crews:GetCrew(crewId)
exports.jj_crews:GetCrewMembers(crewId)
exports.jj_crews:GetAllCrews()
exports.jj_crews:AddCrewPoints(crewId, points, reason)
exports.jj_crews:AddCrewWin(crewId, amount, reason)
exports.jj_crews:AddCrewMoney(crewId, amount, reason)
```
Statebag del jugador: `Player(src).state.crew`.

## Eventos (servidor)
`crews:crewCreated`, `crews:crewDeleted`, `crews:memberJoined`, `crews:memberLeft`, `crews:pointsChanged`.

## Seguridad
Toda validación (permisos, rangos, importes, pertenencia) ocurre en el servidor; hay rate limiting por jugador y acción, SQL parametrizado y operaciones de banco atómicas.

## Build de la web
```
cd web
bun install
bun run dev      # desarrollo en navegador con datos mock (?view=admin&lang=en)
bun run build    # genera web/dist
```
