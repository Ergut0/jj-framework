# jj-framework

Framework base para servidores de FiveM, escrito en Lua 5.4. Gestiona jugadores persistentes con varios personajes por licencia de Rockstar, cuentas de dinero, trabajos con grados y salarios, callbacks cliente-servidor, aparición, muerte y comandos de administración.

## Requisitos

- Servidor FiveM con artefacto 12913 o superior, que es lo que exige oxmysql 2.14.3
- Un servidor de base de datos MySQL o MariaDB ([oxmysql](https://github.com/overextended/oxmysql) ya viene en `[ox]/oxmysql`)
- `spawnmanager` (incluido en `cfx-server-data`)
- OneSync activado: sin él, el servidor no puede leer la posición de los jugadores

## Instalación

1. Copia las carpetas `[jj]`, `[ox]` y `[standalone]` en `resources/` de tu servidor.
2. Importa [jjframework.sql](jjframework.sql), que crea la base de datos `jjframework` y todas las tablas de una vez.
3. Quita `basic-gamemode` de tu `server.cfg` si lo tienes, porque interfiere con la aparición.
4. Copia [server.cfg.example](server.cfg.example) como `server.cfg` y rellena sus valores `CAMBIAR`, o añade esto al tuyo, respetando el orden:

```cfg
set onesync on
set mysql_connection_string "mysql://usuario:contraseña@localhost/jjframework?charset=utf8mb4"
setr inventory:framework "jj"

ensure oxmysql
ensure cfxlua-require
ensure ox_lib
ensure spawnmanager
ensure jj-framework
ensure ox_target
ensure ox_inventory
ensure illenium-appearance
ensure jj_deathsystem
ensure jj_garages
ensure jj_multicharacter
ensure jj_paymethods
ensure jj_smallresources
ensure jj_things
ensure jj_personalmenu
ensure jj_keysystem
ensure jj_alquiler
ensure jj_gym
ensure jj_announce
ensure jj_admin
ensure jj_chat
ensure jj_loadingscreen

add_ace group.admin jj.admin allow
add_ace group.mod jj.mod allow
add_principal identifier.license:TU_LICENCIA group.admin
```

## Inventario: ox_inventory

jj-framework usa [ox_inventory](https://github.com/overextended/ox_inventory) como inventario. ox_inventory solo reconoce los frameworks que tienen un puente en `modules/bridge`, así que el de jj-framework está en `[ox]/ox_inventory/modules/bridge/jj`. El puente se ha escrito para la versión 2.48.1; otra versión puede necesitar ajustes.

Si actualizas ox_inventory, vuelve a copiar el contenido de `[jj]/jj-framework/compat/ox_inventory/` dentro de su carpeta, porque la actualización borra el puente. La licencia de ox_inventory es GPL-3: si distribuyes tu copia modificada, debe seguir bajo esa licencia.

Funcionamiento con jj-framework:

- **Dinero:** el efectivo es el objeto `money` y el dinero negro, `black_money`. Se mantienen sincronizados en ambos sentidos con las cuentas `cash` y `black`, así que si tiras billetes, baja tu saldo. El banco no ocupa inventario.
- **Trabajos:** tu trabajo y grado se usan como grupo en tiendas y almacenes con restricción de trabajo.
- **Licencias:** se guardan en el metadata `licenses` del jugador.
- **Vehículos:** el maletero y la guantera solo se guardan en los vehículos con propietario, es decir, los que están en `jj_vehicles`.
- **Hambre y sed:** jj-framework no las gestiona. Los objetos consumibles lanzan `jj:client:statusRequested` con los valores, para que los recoja un recurso de estados.

Para gestionar objetos, usa directamente los exports de ox_inventory:

```lua
exports.ox_inventory:AddItem(source, 'burger', 2)
```

## Interacción: ox_target

`[ox]/ox_target` es tu copia de ox_target 1.17.2 con la interfaz personalizada, adaptada a jj-framework con `client/framework/jj.lua`. Las restricciones por trabajo y grado (`groups`) usan el trabajo del personaje. Si actualizas ox_target, vuelve a copiar ese archivo, cárgalo en `client/utils.lua` y añádelo a `files` en `fxmanifest.lua`.

## Ropa y aspecto: illenium-appearance

`[standalone]/illenium-appearance` es la versión 5.7.0 con un módulo para jj-framework en `client/framework/jj` y `server/framework/jj`. Las tiendas cobran en efectivo y se configuran en `shared/config.lua`. No usa su tabla `playerskins`, y las de conjuntos guardados están en `jjframework.sql`.

Si actualizas el recurso, vuelve a copiar esas dos carpetas, añade `Framework.JJ()` a `shared/framework/framework.lua` y carga los dos módulos en `fxmanifest.lua`.

## Sistema de muerte: jj_deathsystem

`jj_deathsystem` gestiona la muerte, el hospital y el trabajo de médico (`ambulance`). Sin este recurso, activa `Config.Death.enabled` en `config.lua` o los jugadores se quedarán muertos.

- **Al caer:** el jugador queda herido durante 180 segundos y puede arrastrarse. Después queda inconsciente y puede mantener `E` para ir al hospital.
- **Hospital:** paga `Config.BillCost` del banco, pierde los objetos de `Config.BlackList` y se cura en una camilla. Policía, sheriff y médicos no pierden objetos.
- **Revisión:** con el doctor del mostrador se paga la factura y se recibe la misma cura, sin perder objetos.
- **Camillas libres:** solo se pueden usar si no hay médicos de servicio.
- **Médicos:** curan o reaniman con `/revivep`, o con `ox_target` si lo instalas.
- **Administración:** `/revive [id]`, `/heal [id]` y `/kill [id]`, con el permiso `jj.admin`.

Los puntos de servicio, vestuario, vehículos, almacén y menú de jefe están comentados en `Config.Points` de `jj_deathsystem/shared/cfg.lua`. Para usarlos, descoméntalos e instala `ox_target`. Mientras tanto, los médicos están siempre de servicio.

Desde otros recursos:

```lua
exports.jj_deathsystem:isDead(source)
exports.jj_deathsystem:revive(source)

AddEventHandler('jj_deathsystem:server:playerDown', function(source, tipo, atacante, arma) end)
```

## Garajes: jj_garages

`jj_garages` guarda los vehículos de cada jugador en `jj_vehicles`. Al arrancar añade a la tabla las columnas que le falten.

- **Guardar y sacar:** con `E` en un garaje. Cada vehículo se saca del garaje donde se guardó, salvo con `Config.SharedGarages`.
- **Depósito:** recupera los vehículos embargados y los que quedaron fuera y ya no existen, por ejemplo tras un reinicio. Cuesta `Config.DepotPrice`, que se paga con las cuentas de `Config.PayWith`.
- **Conseguir un vehículo:** `/darcoche <id> <modelo>`, con el permiso `jj.admin`. Una tienda de coches puede usar el export `addVehicle`.

Para garajes de un trabajo, usa `type = 'job'` y `job = 'police'` (o una lista de trabajos) en `Config.Garages`.

Desde otros recursos, en el servidor:

```lua
local matricula = exports.jj_garages:addVehicle(player.identifier, 'adder')
exports.jj_garages:impoundVehicle(matricula, 1000)
```

## Personajes: jj_multicharacter

`jj_multicharacter` muestra la pantalla de personajes al conectar y carga el que elija el jugador. Dinero, trabajo, inventario y vehículos son de cada personaje, no de la licencia. Sin este recurso, pon `Config.Multicharacter = false` en `[jj]/jj-framework/config.lua`: cada licencia tendrá un solo personaje, que se carga al conectar.

- **Huecos:** cada licencia empieza con `defaultOpenCharSlot` de `shared/cfg.lua`, y un administrador los cambia con `/setslots <id> <1-5>`.
- **Personaje nuevo:** elige dónde aparecer con el selector de zonas y recibe los objetos de `starterItems`. Con `useZoneSelectorOnCreate = false` aparece en `creationSpawn`.
- **Aspecto:** lo gestiona `illenium-appearance` y se guarda en `jj_players.skin`. Un personaje sin aspecto abre el creador nada más aparecer. Si ese recurso no está arrancado, se usa la ropa básica de `randomPeds`.
- **Probar escenas:** `/test_scene [número]` y `/stop_scene`, con el permiso `jj.admin`.

### Editar la interfaz

El código está en `[jj]/jj_multicharacter/web`, con Bun, Vite, React y Mantine. FiveM solo usa `web/dist`, así que hay que recompilar después de cada cambio. Con `bun run dev` se abre en el navegador con datos de ejemplo.

```bash
bun install
```

```bash
bun run build
```

La carpeta `web/node_modules` no hace falta en el servidor.

## Administración: jj_admin

Menú de administración con interfaz propia. Se abre con `/admin` o `F7`, y la tecla se puede cambiar en los ajustes de FiveM. El servidor comprueba el permiso en cada acción y guarda las acciones en la pantalla **Registros**.

- **Panel:** conectados, policías y médicos de servicio, baneos activos, heridos y actividad reciente.
- **Jugadores:** ir, traer, espectar, congelar, reanimar, curar, matar, expulsar, banear, dinero, trabajo, servicio, dar objetos y vehículos, ver y vaciar el inventario (se conserva el efectivo).
- **Mis herramientas:** noclip, modo dios, invisible, ver jugadores, ir al marcador o a unas coordenadas, y copiar coordenadas.
- **Vehículos:** crear, reparar, enderezar, borrar y limpiar los vacíos. Un vehículo de jugador que se borra se recupera en el depósito.
- **Servidor:** anuncios con `jj_announce`, clima, hora y guardar a todos los jugadores.
- **Baneos:** lista, quitar baneos y banear una licencia sin conexión. Se comprueban al conectar, por licencia y Discord.

Hay dos niveles, y `Config.Actions` de `[jj]/jj_admin/shared/config.lua` fija el mínimo de cada acción. Un moderador no puede traer, espectar, congelar, matar, expulsar ni banear a un administrador.

| Permiso | Grupo en `server.cfg` | Acceso |
| --- | --- | --- |
| `jj.admin` | `group.admin` | Todo |
| `jj.mod` | `group.mod` | Moderar jugadores, herramientas propias, arreglar vehículos y enviar anuncios |

Para dar el nivel de moderador: `add_principal identifier.license:LICENCIA group.mod`.

La interfaz está en `[jj]/jj_admin/web` y se compila igual que la de `jj_multicharacter`.

## Chat de rol: jj_chat

Sustituye al recurso `chat` de FiveM, así que no hay que arrancar los dos. Se abre con `T`. El texto normal se oye solo cerca, y los mensajes de otros recursos que usan `chat:addMessage` siguen funcionando.

| Comando | Quién lo ve |
| --- | --- |
| Texto sin comando | Jugadores a 15 m |
| `/gritar`, `/g` | Jugadores a 40 m |
| `/susurrar`, `/s` | Jugadores a 3 m |
| `/ooc`, `/b` | Jugadores a 25 m, fuera de personaje |
| `/me`, `/do` | Jugadores a 25 m (son de `jj_things`) |
| `/dep` | Compañeros de trabajo de servicio |
| `/mp <id>`, `/pm <id>`, `/r` | Mensaje privado y respuesta |
| `/reporte` | Staff conectado |
| `/staff` | Staff conectado; solo lo usa el staff |

- **Pestañas:** Todo, Rol, OOC, Privados, Trabajo y Staff. Lo que escribes va al canal de la pestaña abierta. `Tab` completa el comando o cambia de pestaña, y las flechas recorren lo que has escrito antes.
- **Staff:** quien tenga `jj.admin` o `jj.mod`. Puede usar `/silenciar <id> [minutos] [motivo]` y `/desilenciar <id>`. El silencio dura hasta que caduca o se reinicia el recurso, también si el jugador se reconecta, y no impide usar `/reporte`.
- **Ajustes:** distancias, espera entre mensajes y comandos están en `[jj]/jj_chat/shared/config.lua`. Con `Config.Distance.ooc = false`, el canal OOC llega a todo el servidor.
- **Otros comandos:** `/limpiarchat` y `/ocultarchat`.

La interfaz está en `[jj]/jj_chat/web` y se compila igual que la de `jj_multicharacter`. Los mensajes privados no se escriben en la consola del servidor; los demás, sí.

## Otros recursos de jj

- **`jj_paymethods`:** diálogo de pago con los exports de cliente `PayMethods`, `PayLater` y `CheckMoney`. La tarjeta de empresa de policía aprueba el pago sin descontar nada, porque no hay cuentas de empresa; lanza `jj_paymethods:server:companyPayment` por si otro recurso lo contabiliza.
- **`jj_personalmenu`:** menú personal (`F10`), armas visibles en el cuerpo y cámara libre. `/freecamadmin` necesita `jj.admin`. Las estadísticas requieren `jj_gym`, y la facción ilegal, `av_gangs`.
- **`jj_smallresources`:** cargar personas, chalecos, documentos, detector de huellas, tiendas y ajustes del mundo.
- **`jj_things`:** esposas, `/me`, `/do`, `/entorno`, `/cachear`, `/maletero`, carterismo, doctores ilegales, silla de ruedas y efectos varios. Los avisos a policía y médicos llegan a quien esté de servicio.

- **`jj_keysystem`:** llaves de vehículos. `U` abre y cierra el vehículo si eres su dueño o llevas una llave válida. El cerrajero hace copias y cambia la cerradura, lo que invalida las copias anteriores. Otros recursos pueden usar los exports de servidor `addTempKey` y `hasKey`.
- **`jj_alquiler`:** alquiler de barcos. El precio sale de `shared/cfg.lua`, se cobra en efectivo y da una llave temporal. Solo se puede devolver el vehículo alquilado.
- **`jj_gym`:** membresía, ejercicios y estadísticas por personaje, y alquiler de bicicletas.
- **`jj_announce`:** banners para todo el servidor con `/anuncio`, `/evento`, `/mantenimiento` y `/urgente`, con el permiso `jj.admin`. Otros recursos usan el export de servidor `Announce(tipo, mensaje, autor)`.
- **`jj_loadingscreen`:** pantalla de carga. No tiene parte de servidor. El audio no está en el repositorio por su tamaño: añade el tuyo en `web/assets/audio.mp3`.

Objetos que necesitan estos recursos en `ox_inventory/data/items.lua`:

```lua
['vehicle_key'] = { label = 'Llave de vehículo', weight = 10, stack = false, client = { event = 'jj_keysystem:useKey' } },
['gym_membership'] = { label = 'Membresía del gimnasio', weight = 0, stack = false },
```

Para que la ganzúa abra vehículos, añade a `lockpick` esta línea: `client = { export = 'jj_keysystem.lockpickVehicle' }`.

## Comandos

| Comando | Permiso | Descripción |
| --- | --- | --- |
| `/dinero` | Todos | Muestra tus saldos |
| `/trabajo` | Todos | Muestra tu trabajo |
| `/addmoney <id> <cuenta> <cantidad>` | `jj.admin` | Añade dinero |
| `/removemoney <id> <cuenta> <cantidad>` | `jj.admin` | Retira dinero |
| `/setmoney <id> <cuenta> <cantidad>` | `jj.admin` | Fija el saldo |
| `/setjob <id> <trabajo> <grado>` | `jj.admin` | Cambia el trabajo |
| `/saveall` | `jj.admin` | Guarda a todos los jugadores |

Las cuentas, los trabajos, los puntos de aparición y los intervalos se configuran en `[jj]/jj-framework/config.lua`.

## Usarlo desde otro recurso

Añade `dependency 'jj-framework'` al `fxmanifest.lua` de tu recurso y obtén el objeto principal. Los métodos se llaman con punto, no con dos puntos.

### Servidor

```lua
local JJ = exports['jj-framework']:GetCoreObject()

local PRECIO = 100

JJ.RegisterCallback('tienda:comprar', function(source, cb)
    local player = JJ.GetPlayer(source)
    cb(player ~= nil and player.removeMoney('cash', PRECIO, 'tienda'))
end)

AddEventHandler('jj:server:playerLoaded', function(source)
    local player = JJ.GetPlayer(source)
    print(player.getName(), player.getJob().label)
end)
```

El servidor decide siempre los valores importantes, como el precio: cualquier dato enviado por el cliente se puede falsificar.

### Cliente

```lua
local JJ = exports['jj-framework']:GetCoreObject()

local comprado = JJ.AwaitCallback('tienda:comprar')

RegisterNetEvent('jj:client:playerLoaded', function(data)
    print(data.job.label)
end)
```

## API

### Servidor: `JJ`

| Función | Devuelve |
| --- | --- |
| `GetPlayer(source)` | Jugador o `nil` |
| `GetPlayerByIdentifier(identificador)` | Jugador o `nil`, según el identificador de su personaje |
| `GetPlayerByLicense(licencia)` | Jugador o `nil` |
| `GetCharacters(source)` | Personajes de la licencia del jugador |
| `CreateCharacter(source, nombre, datos)` | Identificador del personaje nuevo o `nil` |
| `LoadCharacter(source, identificador)` | `true` si se ha cargado |
| `GetPlayers()` | Lista de `source` de los jugadores cargados |
| `RegisterCallback(nombre, handler)` | `handler(source, cb, ...)` |
| `Notify(source, mensaje)` | Muestra una notificación |
| `IsAdmin(source)` | `true` si tiene el permiso de administración |

### Servidor: jugador

| Método | Notas |
| --- | --- |
| `getData()` | Todos los datos del jugador |
| `getName()` | Nombre de FiveM |
| `getMoney(cuenta)`, `getAccounts()` | Saldos |
| `addMoney(cuenta, cantidad, motivo)` | `true` o `false` |
| `removeMoney(cuenta, cantidad, motivo)` | `false` si no hay saldo suficiente |
| `setMoney(cuenta, cantidad, motivo)` | `true` o `false` |
| `getJob()`, `setJob(nombre, grado)` | `setJob` devuelve `false` si no existe |
| `setDuty(enServicio)` | Se lee en `getJob().onDuty`; no se guarda y empieza en `true` |
| `getMetadata(clave)`, `setMetadata(clave, valor)` | Datos propios que se guardan en la base de datos |
| `getCharInfo()` | Nombre, apellidos, fecha de nacimiento, sexo y nacionalidad |
| `getSkin()`, `setSkin(json)` | Aspecto del personaje |
| `isSpawned()` | Si ya ha aparecido en el mundo |
| `notify(mensaje)`, `kick(motivo)` | |

### Cliente: `JJ`

`GetPlayerData()`, `IsLoaded()`, `IsSpawned()`, `Notify(mensaje)`, `TriggerCallback(nombre, cb, ...)` y `AwaitCallback(nombre, ...)`.

## Eventos

| Evento | Lado | Parámetros |
| --- | --- | --- |
| `jj:server:playerLoaded` | Servidor | `source` |
| `jj:server:playerSpawned` | Servidor | `source` |
| `jj:server:playerDropped` | Servidor | `source, motivo` |
| `jj:server:moneyChanged` | Servidor | `source, cuenta, accion, cantidad, saldo, motivo` |
| `jj:server:jobChanged` | Servidor | `source, trabajo, trabajoAnterior` |
| `jj:server:dutyChanged` | Servidor | `source, enServicio` |
| `jj:client:playerLoaded` | Cliente | `datos` (usa `RegisterNetEvent`) |
| `jj:client:playerSpawned` | Cliente | |
| `jj:client:playerRespawned` | Cliente | |
| `jj:client:playerDataChanged` | Cliente | `clave, valor` |
