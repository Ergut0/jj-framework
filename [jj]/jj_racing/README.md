# jj_racing — Creador y sistema de carreras para jj-framework

Recurso de carreras para FiveM sobre **jj-framework** con un **creador de circuitos in-game** para
administradores y un sistema completo para jugadores (salas, cuenta atrás, checkpoints, HUD,
resultados, récords, eventos oficiales y retos **crew vs crew**). Se integra con el recurso
[`jj_crews`](../jj_crews) mediante sus exports: los resultados suman puntos, victorias y premios
a los crews. Toda la lógica crítica (estado de las salas, inscripciones, tiempos, posiciones,
premios y puntos) vive en el servidor; el cliente solo reporta progreso.

- Dependencias obligatorias: `jj-framework`, `ox_lib`, `oxmysql` (y **OneSync** para el anti‑trampas completo).
- Dependencia opcional (detectada en tiempo de ejecución): `jj_crews`.
- Los campos `citizenid` guardan el `identifier` del personaje de jj-framework.
- Interfaz NUI con Bun + React + Tailwind (panel de jugador, panel de administración y HUD).

---

## Índice

1. [Instalación](#1-instalación)
2. [Configuración](#2-configuración)
3. [Uso rápido](#3-uso-rápido)
4. [Creador de circuitos](#4-creador-de-circuitos)
5. [Integración con crews](#5-integración-con-crews)
6. [Reparto de premios y dinero](#6-reparto-de-premios-y-dinero)
7. [Anti‑trampas](#7-anti-trampas)
8. [Exports y eventos públicos](#8-exports-y-eventos-públicos)
9. [Base de datos](#9-base-de-datos)
10. [Interfaz web (Bun)](#10-interfaz-web-bun)
11. [Rendimiento](#11-rendimiento)
12. [Estructura](#12-estructura)
13. [Limitaciones conocidas](#13-limitaciones-conocidas)

---

## 1. Instalación

1. El recurso es `[jj]/jj_racing`. Ese nombre es el que se usa en `ensure` y en los exports (`exports.jj_racing:GetTrack(...)`).
2. Importa `sql/races.sql` en tu base de datos (MySQL/MariaDB). Es idempotente (`CREATE TABLE IF NOT EXISTS`).
3. (Opcional) Importa `sql/tracks.sql`: **102 circuitos** convertidos desde otro sistema de carreras (`ra_racing_tracks`,
   original en `sql/source/`). Es idempotente y no usa variables de sesión. Se importan activos, como checkpoints normales (radio 10 m), con una parrilla
   de 12 huecos generada detrás del primer punto (revísala en el creador) y sin props/blips (races no los usa).
   Impórtalo **después** de `races.sql` y reinicia el recurso: en la consola verás `N circuitos cargados (M activos)`.
   Si dice 0, el SQL no se importó en la base de datos que usa oxmysql; si hay circuitos «desactivados por estar incompletos»,
   la importación de checkpoints falló y conviene repetirla.
4. Compila la interfaz (ver [sección 10](#10-interfaz-web-bun)). El repositorio puede incluir ya `web/dist`.
5. En `server.cfg` (el orden importa: `jj_crews` antes que `jj_racing`):

   ```cfg
   ensure jj_crews      # opcional: integración de crews
   ensure jj_racing

   # OneSync es necesario para las comprobaciones de posición/vehículo en servidor
   set onesync on

   # Permiso de administración por ACE (además de los administradores de jj-framework)
   add_ace group.mod races.admin allow

   # Webhook de Discord opcional (resultados, récords, anulaciones)
   set races_webhook "https://discord.com/api/webhooks/..."
   ```
6. Reinicia el servidor. Al arrancar el recurso:
   - carga ajustes, circuitos y récords en memoria;
   - **reembolsa** cualquier dinero que quedara retenido por una caída (`race_escrow`);
   - cancela los eventos que estaban abiertos y programa el siguiente.

## 2. Configuración

Todo está en [`config.lua`](config.lua) (comentado). Resumen:

| Bloque | Qué controla |
| --- | --- |
| `Config.Locale` / `Config.Currency` | Idioma (`es`/`en`, carpeta `locales/`) y símbolo de moneda |
| `Config.AdminCommand` / `LeaveCommand` | `/raceadmin` y `/raceleave`. El panel de jugador se abre con el objeto `tablet_reacing` |
| `Config.AdminAce` | Quién es administrador además de los de jj-framework, **siempre validado en el servidor** |
| `Config.Categories` / `Difficulties` / `PointToPointCategories` | Categorías (calle, circuito, offroad, sprint, circular), dificultades y categorías de una sola vuelta |
| `Config.VehicleClasses` / `BlacklistedModels` / `BlacklistedClasses` | Clases de vehículo (por clase GTA y lista blanca opcional de modelos) y prohibidos |
| `Config.Settings` | **Ajustes editables en vivo** desde el panel admin (se guardan en BD): límites de pilotos, vueltas, cuenta atrás, premios, comisión, reparto, puntos y fórmula de crews… |
| `Config.Events` / `Config.CrewVs` / `Config.Lobby` | Eventos oficiales, retos de crews y salas |
| `Config.AntiCheat` | Velocidades máximas, tolerancias, avisos para marcar/descalificar |
| `Config.Ghost` / `Config.Pit` / `Config.Markers` | Modo fantasma, pit stops y marcadores del mundo |
| `Config.Creator` | Límites y controles del editor |
| `Config.RateLimit` | Límite de peticiones por jugador |
| `Config.Webhook*` | Webhook (se define por convar `races_webhook`, nunca en el fichero compartido) |

> `Config.Settings` solo contiene los **valores iniciales**: una vez guardados desde el panel
> (`/raceadmin` → Ajustes) los valores de la base de datos prevalecen.

## 3. Uso rápido

- Jugadores: el objeto `tablet_reacing` de ox_inventory abre el panel: catálogo, salas abiertas, lobby, retos de crews, resultados,
  estadísticas y clasificaciones. `/raceleave` abandona la sala o la carrera actual.
- Administradores: `/raceadmin` abre el panel de administración (solo si el **servidor** confirma el permiso).
- Para correr hay que **ir al volante** de un vehículo de la clase de la carrera cuando el anfitrión
  pulsa *Iniciar*; el servidor comprueba el vehículo de cada piloto, los coloca en la parrilla y da la salida.

Flujo de una carrera: `abierta → (comprobación de vehículos) → cuenta atrás → en curso → finalizada | cancelada`.
Si el anfitrión sale, la sala se cancela y **todas las inscripciones se devuelven**. Una desconexión o un
abandono durante la carrera cuenta como DNF.

## 4. Creador de circuitos

Panel de administración → **Creador**:

1. Rellena los datos del circuito: nombre, categoría, dificultad, descripción, vueltas por defecto,
   clase de vehículo permitida, premio base, tiempo límite, colisiones y si permite crews.
2. Pulsa **Editar en el mundo**. El panel se cierra y puedes colocar puntos en el mapa:

   | Tecla | Acción |
   | --- | --- |
   | `E` | Colocar punto (en la mira o en tu posición) |
   | `Q` | Eliminar el seleccionado (o el último) |
   | `←` / `→` | Seleccionar checkpoint anterior / siguiente |
   | `F` | Mover el seleccionado a la posición actual |
   | `TAB` | Alternar «cursor (mira)» / «posición del jugador» |
   | `Z` | Cambiar el tipo: checkpoint → atajo → pit → parrilla |
   | Rueda / `↑↓` | Radio (con `SHIFT`: altura) |
   | `Retroceso` | Terminar y volver al panel |

   Los puntos se dibujan en el mundo (marcadores, líneas y números) y como blips numerados en el minimapa.
3. Vuelve al panel para afinar radio, altura, orden y enlaces de atajos; la vista de ruta SVG se actualiza en vivo.
4. **Guardar**. El circuito nace **desactivado**. Con `Config.Creator.requireTest = true` debes **probarlo**
   (*Probar* te coloca en la parrilla y mide el tiempo, que queda como **tiempo de referencia**) antes de publicarlo.

Tipos de checkpoint:

- **Normal**: obligatorio y en orden. El último es la meta (en circuitos, ponlo junto a la salida).
- **Atajo** (`linkFrom → linkTo`): alternativa opcional que une el checkpoint normal `linkFrom` con el
  `linkTo` saltándose al menos uno (por ejemplo `4 → 6` se salta el 5).
- **Pit**: zona opcional que repara el vehículo (cooldown configurable) sin alterar el progreso.

**Versiones**: si cambias el trazado (posición, orden, tipos, enlaces o parrilla) la versión sube,
el circuito se despublica y se invalida la prueba; los récords de versiones anteriores se conservan pero
no cuentan en la clasificación actual. Cambiar radio/altura/metadatos no sube la versión y la opción
*cambio menor* permite conservar la versión aunque muevas puntos.

**Importar / exportar**: formato JSON `{"format":"races.track","schema":1,...}` (botones *Exportar* e *Importar*).
Lo importado se valida igual que un circuito creado a mano y queda desactivado y sin probar.

## 5. Integración con crews

El recurso de crews es **opcional**: en cada llamada se comprueba que esté iniciado **y** que exponga sus exports. Se prueban
los nombres de `Config.CrewsResources` (por defecto `jj_crews`).
Si está iniciado pero no expone los exports, la consola avisa **una sola vez** y las carreras siguen funcionando sin crews
(sin etiquetas, retos ni puntos) hasta que `crews` esté operativo; al arrancar bien se imprime `integración con crews activa`.

Exports de `crews` que se usan (siempre desde el servidor, con `pcall`):
`GetPlayerCrew`, `IsInCrew`, `GetCrew`, `AddCrewPoints`, `AddCrewWin`, `AddCrewMoney`
(y `GetCrewMembers` / `GetAllCrews` para avisos y rankings).
**Cada llamada de escritura queda registrada** en `race_logs` (`crew_export`, visible en el panel admin → Logs).

### Carreras abiertas

- En el lobby, el HUD y los resultados cada piloto muestra el **tag y color** de su crew.
- Al cerrar la carrera, el **servidor** acredita al crew de cada piloto que termina los puntos de
  `crewPointsByPosition[posición]` (o `crewFinishPoints` fuera de tabla). Reglas anti‑abuso (ajustables en vivo):
  - mínimo de pilotos para premiar (`minPlayersForRewards`);
  - `crewRequireOutsider`: solo cuentan si corre al menos un piloto ajeno a ese crew;
  - `crewMaxPointsPerRace`: tope por crew y carrera;
  - `crewPrizeSharePct`: % opcional del premio de cada piloto que se ingresa en el banco del crew.

### Crew vs crew

1. Un miembro con rango suficiente (`crewVsMinRank`, el líder siempre) **reta** a otro crew eligiendo circuito
   (que permita crews), vueltas, clase, tamaño de equipo y apuesta.
2. Un miembro con rango del crew rival lo **acepta o rechaza** (caduca en `challengeExpirySeconds`).
3. Al aceptar, el servidor retira la apuesta del banco de **ambos** crews (`AddCrewMoney` negativo, queda retenida)
   y abre una sala restringida a los miembros de esos dos crews (equipos del mismo tamaño).
4. Al cerrar, el resultado por equipo se calcula con la fórmula `crewVsFormula`:
   - `points`: suma de `crewPointsByPosition` de los miembros que terminan;
   - `positions`: menor suma de posiciones (no terminar penaliza);
   - `best`: mejor posición individual (desempata por puntos).
5. El crew ganador recibe **victoria** (`AddCrewWin`), **puntos** (`crewVsWinPoints`) y el **bote**
   (apuestas − comisión + premio base del circuito) en su banco (`AddCrewMoney`). En empate, o si nadie
   termina, se devuelven las apuestas. Si la sala se cancela, también.

## 6. Reparto de premios y dinero

- **Inscripción** (la fija el anfitrión) y **bolsa extra** (opcional, la aporta el anfitrión): se cobran al unirse y
  quedan **retenidas** en `race_escrow`. Se devuelven íntegras si la sala se cancela, caduca, el jugador sale
  antes de empezar o el servidor se cae (recuperación al arrancar). Cada fila se borra **antes** de pagar: ante
  un fallo se prefiere perder un pago a duplicar dinero.
- **Bote** = inscripciones − comisión (`commissionPct`, sumidero de dinero) + bolsa extra + **premio base del circuito**
  (dinero nuevo, tope `baseMaxPrize`). Se reparte entre quienes terminan según `prizeSplit` (normalizado al
  número de finalistas; el redondeo va al ganador).
- Si hay menos de `minPlayersForRewards` pilotos o nadie termina: **no hay premios** ni puntos de crew y se
  devuelven las inscripciones.
- **Eventos oficiales**: gratuitos, premio fijado por el administrador y pagado por el servidor.
- Los puntos del **ranking de pilotos** salen de `pilotPoints[posición]`.

## 7. Anti‑trampas

Todo se valida en el servidor con la posición autoritativa del jugador (OneSync):

- **Orden** estricto de checkpoints (incluyendo atajos válidos y vueltas); lo que llega fuera de orden se ignora.
- **Posición**: al pasar un checkpoint, el jugador debe estar físicamente cerca (radio + `posTolerance`).
- **Tiempo mínimo plausible** entre checkpoints (`distancia / maxSpeed × minTimeFactor`) y contra el tiempo de
  referencia del circuito (`minRefFactor`).
- **Teletransportes**: muestreo de posición solo mientras hay carreras en curso (`teleportSpeed`).
- **Vehículo**: modelo contrastado con el servidor al salir y durante la carrera; clase validada por lista blanca
  de modelos o por la clase GTA reportada (aprendida por modelo; un modelo no puede cambiar de clase).
  Cambiar de vehículo descalifica; salir del vehículo más de `leftVehicleGrace` segundos también.
- Cada incidencia suma **avisos**: al llegar a `strikesToFlag` el resultado queda **marcado como sospechoso**
  (no cuenta para récords hasta que un administrador lo apruebe en *Revisión*); a `strikesToDq` se descalifica.
- Rate limit en callbacks y en los eventos de progreso; límites y validación de tipos en todos los parámetros.

## 8. Exports y eventos públicos

```lua
exports.jj_racing:GetActiveRaces()   -- lista de carreras en curso/abiertas (resumen)
exports.jj_racing:GetTrack(id)       -- detalle de un circuito (ruta, parrilla, récord...) o nil
exports.jj_racing:GetTracks()        -- circuitos activos (resumen)
exports.jj_racing:GetTrackRecord(id) -- mejor vuelta actual { name, time, vehicle, crewTag, crewColor } o nil
exports.jj_racing:GetPlayerRace(src) -- { id, state, mode, trackId, trackName, status } o nil
exports.jj_racing:IsInRace(src)      -- boolean
```

Evento de servidor al cerrar cada carrera (no es de red):

```lua
AddEventHandler('races:onRaceFinished', function(race)
    -- race = {
    --   raceKey, lobbyId, trackId, trackName, mode ('open'|'crew'|'official'), laps,
    --   crewVs = { winner, winnerCrew, payout, points, formula } | nil,
    --   results = { { source, citizenid, name, position, status ('finished'|'dnf'|'dq'),
    --                 totalTime, bestLap, prize, points, crewPoints, crewId, flagged }, ... }
    -- }
end)
```

Los tiempos van en milisegundos. Los resultados de pruebas de circuito (modo `test`) no emiten este evento.

## 9. Base de datos

Tablas (`sql/races.sql`): `race_tracks`, `race_checkpoints` (con historial por versión), `race_events`,
`race_results`, `race_records`, `race_escrow` (dinero retenido), `race_logs` (auditoría) y `race_settings`
(ajustes en vivo). Todas las consultas están parametrizadas (sin concatenar SQL). Los logs se purgan
pasados `Config.LogRetentionDays` días.

## 10. Interfaz web (Bun)

La carpeta `web/` contiene la NUI (React 19 + Tailwind 4). `fxmanifest.lua` apunta a `web/dist/index.html`
y expone `web/dist/**`.

```bash
cd web
bun install
bun run dev        # servidor de desarrollo con datos simulados (mock) en http://localhost:3000
bun run build      # genera web/dist (la carga la NUI)
bun run typecheck  # tsc --noEmit
```

- Modo navegador: `?view=admin` (panel admin), `?hud=1` (simula una carrera para ver el HUD),
  `?creator=1` (overlay del editor), `?lang=en` (inglés).
- Comunicación: `fetchNui(action, data)` (`web/src/lib/nui.ts`) ↔ `RegisterNUICallback`; Lua → web con
  `SendNUIMessage` (`open`, `lobby`, `results`, `hud:*`, `creator:*`). Fuera del juego `fetchNui` usa el mock
  (`web/src/lib/mock`).
- La vista de administración **solo se monta si el servidor confirma el permiso** (`getState.isAdmin`); además,
  cada callback `admin*` vuelve a comprobarlo en el servidor.
- ESC cierra el panel y se libera el foco (`SetNuiFocus(false, false)`).
- El gestor de paquetes de Bun guarda el lockfile como `bun.lock` (formato de texto en las versiones recientes).

## 11. Rendimiento

- **0.00 ms en reposo**: no hay bucles permanentes en cliente ni servidor. El hilo de la carrera (servidor) solo
  existe mientras haya una carrera en curso; el cliente solo itera durante su carrera (`Wait(200)` lejos de
  los checkpoints, `Wait(0)` cerca) y durante el modo fantasma o el editor.
- Circuitos, ajustes y récords se mantienen en memoria; las clasificaciones se cachean unos segundos.
- Los eventos programados usan un único `SetTimeout` hacia el siguiente evento (sin sondeo).

## 12. Estructura

```
races/
├── fxmanifest.lua · config.lua
├── locales/            es.lua, en.lua
├── shared/utils.lua
├── client/             nui.lua, main.lua, race.lua, ghost.lua, creator.lua
├── server/
│   ├── logs.lua · database.lua · permissions.lua
│   ├── validation.lua  (circuitos, vehículos, checkpoints y tiempos)
│   ├── crews.lua       (puente con el recurso crews + retos crew vs crew)
│   ├── leaderboard.lua (récords y rankings)
│   ├── lobbies.lua     (salas, dinero retenido, cuenta atrás, progreso, eventos)
│   ├── results.lua     (posiciones, premios, puntos de crew, anulaciones)
│   └── main.lua        (ajustes, circuitos, arranque, exports) · callbacks.lua
├── sql/races.sql
└── web/                (Bun) src/, dist/, build.ts, package.json
```

## 13. Limitaciones conocidas

- **Sin OneSync** no hay posición ni vehículo autoritativos: se desactivan esas comprobaciones (se avisa en consola).
- GTA no expone `GetVehicleClass` en servidor: la clase la reporta el cliente y el servidor solo contrasta el
  **modelo**. Para clases estrictas define `models` (lista blanca) en `Config.VehicleClasses`.
- Los atajos no pueden cruzar el cambio de vuelta (`linkTo` ≤ número de checkpoints normales).
- Si el servidor se cae justo entre cobrar y registrar una retención, ese cobro puntual no se recupera
  (se prioriza no duplicar dinero).
- El editor en el mundo depende de los controles por defecto de GTA; si entran en conflicto con otro recurso,
  cámbialos en `Config.Creator.Keys`.
