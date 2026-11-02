# jj-framework

Framework base para servidores de FiveM, escrito en Lua 5.4. Gestiona jugadores persistentes con varios personajes por licencia de Rockstar, cuentas de dinero, trabajos con grados y salarios, callbacks cliente-servidor, aparición, muerte y comandos de administración.

## Requisitos

- Servidor FiveM con artefacto 12913 o superior, que es lo que exige oxmysql 2.14.3
- Un servidor de base de datos MySQL o MariaDB ([oxmysql](https://github.com/overextended/oxmysql) ya viene en `[ox]/oxmysql`)
- `spawnmanager` (incluido en `cfx-server-data`)
- OneSync activado: sin él, el servidor no puede leer la posición de los jugadores

## Instalación

1. Copia las carpetas `[jj]`, `[ox]`, `[standalone]`, `[voice]` y `[phone]` en `resources/` de tu servidor.
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
ensure jj_vehicleshop
ensure jj_gangs
ensure jj_hud
ensure jj_personajes
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

## Voz: pma-voice

`[voice]/pma-voice` es [pma-voice](https://github.com/AvarianKnight/pma-voice) sin modificar (commit `6c9d96e`, versión 7.0.1 del manifiesto). Se configura en `server.cfg` y necesita `onesync`.

- **Hablar:** la tecla de pulsar para hablar de los ajustes de voz de FiveM.
- **Distancia de voz:** `F11`. `jj_hud` la muestra en el cuadrado del micrófono.
- **Radio:** `Bloq Mayús`, solo si estás en un canal. Sin un recurso de radio, se entra con el export de cliente `setRadioChannel`. No se usa `Alt` izquierdo, su tecla por defecto, porque es la de `ox_target`.
- **Reiniciar la voz:** `F4` o `/rvoz`, de `jj_things`.

## Móvil: lb-phone

`[phone]/lb-phone` es LB Phone 2.9.0. Está cifrado con el escrow de Cfx, así que solo funciona en un servidor cuya clave tenga la licencia. El puente con jj-framework está en los archivos abiertos `custom/frameworks/standalone`, con `Config.Framework = "standalone"` y `Config.CustomFramework = true`. Si actualizas el recurso, conserva esas dos carpetas, `config/config.lua` y `GiveVehicleKey` en `server/custom/functions/functions.lua`.

- **Teléfono:** uno por personaje. Se abre con `F1` y no se puede abrir muerto, en el suelo ni esposado.
- **Dinero:** la cartera usa la cuenta `bank`, también para enviar a personajes desconectados.
- **Empresas:** `police`, `ambulance` y `mechanic`. Un jefe puede contratar, despedir, cambiar de grado, e ingresar y retirar de la cuenta de empresa de `fd_banking`.
- **Garaje:** muestra los vehículos de `jj_vehicles` y el aparcacoches saca los que están en un garaje.
- **Objeto:** con `Config.Item.Require = false` no hace falta llevar el objeto `phone`.
- **Fotos, vídeos y audios:** necesitan claves en `server/apiKeys.lua`.

## Banco: fd_banking

`[standalone]/fd_banking` es Advanced Banking 1.5.22. Está cifrado con el escrow de Cfx, así que solo funciona en un servidor cuya clave tenga la licencia. El puente con jj-framework está en `modules/bridge/server/jj.lua` y `modules/bridge/client/jj.lua`, y la traducción en `locales/es.json`. `[standalone]/fd_banking_app` añade la aplicación Banco a `lb-phone`.

- **Cuenta personal:** usa la cuenta `bank` del personaje. Cualquier movimiento de otro recurso queda en el historial.
- **Empresas:** cada trabajo con un grado `isBoss` tiene su cuenta, y sus jefes son los dueños. Las cuentas se crean al arrancar el recurso.
- **Bandas:** `Config.UseGangAccounts` está desactivado, porque las bandas de `jj_gangs` se crean en marcha.
- **Bancos y cajeros:** se usan con `ox_target`.
- **Miembros de cuentas compartidas:** se añaden por ID del jugador conectado.
- **Facturas:** `/factura`, para `Config.SocietiesInvoicesEnabled`.
- **Requisitos:** necesita el recurso `yarn` de cfx-server-data e internet al arrancar por primera vez, para instalar sus dependencias.

Si actualizas el recurso, conserva esos tres archivos y `config.lua`. El `fd_banking.sql` original borra las tablas al importarlo: usa `jjframework.sql`, que las crea sin borrar nada.

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

## Concesionarios: jj_vehicleshop

Cada vendedor abre su concesionario con `E`, o con `ox_target` si pones `UseTarget = true`. Las flechas rotan el vehículo, y `Esc` vuelve a las categorías y luego cierra. El servidor comprueba la distancia al vendedor, el trabajo y el precio, que sale siempre de su configuración.

- **Compra:** el pago se elige en el diálogo de `jj_paymethods`, con banco o efectivo. El vehículo queda registrado en `jj_garages` y aparece en `purchased_vehicle_spawn`, con llaves del dueño. Si no llega a aparecer, se queda en el garaje.
- **Tarjeta de empresa:** no cobra nada, así que solo se ofrece en los concesionarios con `company_card = true`, que de serie es solo el de policía.
- **Garaje:** el campo `garage` de cada concesionario indica dónde se guarda. Sin él, va al garaje por defecto de `jj_garages`.
- **CP:** los vehículos con `coins` en `categories/` también se pueden pagar con CP, las monedas de donación. La opción aparece en el diálogo de pago con el precio y el saldo del jugador, y el servidor cobra siempre el precio de su configuración.
- **Prueba de conducción:** se hace en un mundo aparte durante `DriveTestTime` minutos, y al terminar vuelves junto al vendedor. El servidor la cierra si el cliente deja de responder.
- **Concesionario VIP:** con `isVip = true` en el vendedor, hace falta el permiso `jj.vip`.
- **Ajustes:** `config/config.lua` para vendedores y concesionarios, y `categories/` para vehículos y precios.
- **Imágenes:** pon `modelo.png` en `web/public/vehicles` y recompila. Sin imagen propia, usa la de la documentación de FiveM.
- **Administración:** `/registrarcoche`, con `jj.admin`, pone a tu nombre el vehículo en el que vas. El modelo se deduce del nombre que da el juego, que en algunos coches no coincide con el de aparición.

La interfaz está en `[jj]/jj_vehicleshop/web` y se compila igual que la de `jj_personajes`.

## Bandas: jj_gangs

Bandas con su barrio, puntos propios, droga y grafitis. Las tablas se crean solas al arrancar, y también están en `jjframework.sql`. Los ajustes están en `shared/config.lua`.

**Panel de administración:** `/bandas`, con el permiso `jj.admin`. Permite:

- Crear bandas, cambiar su nombre y color, y eliminarlas.
- Mover el barrio y cambiar su radio.
- Añadir, mover y quitar puntos, e ir a ellos o marcarlos en el mapa.
- Añadir miembros, cambiar rangos, nombrar jefe y sacar a jugadores, también si están desconectados.
- Ver y borrar grafitis.

Al crear una banda, mover el barrio o colocar un punto, el panel se oculta: ve hasta el sitio y pulsa `E`, o `Retroceso` para cancelar. Al colocar un barrio verás su círculo mientras caminas.

La interfaz está en `[jj]/jj_gangs/web` y se compila igual que la de `jj_personajes`.

**Puntos de la banda.** Se usan con `E` y solo los ven sus miembros:

| Punto | Para qué sirve |
| --- | --- |
| Gestión de la banda | Invitar a jugadores cercanos, cambiar rangos y expulsar |
| Armario | Almacén compartido de `ox_inventory` |
| Ropero | Conjuntos guardados de `illenium-appearance` |
| Garaje | Garaje de `jj_garages`, solo para la banda. Colócate donde deba aparecer el coche y mirando hacia donde quieras que salga |
| Laboratorio | Fabrica la droga elegida al crearlo. Las recetas están en `Config.Labs` y de serie no gastan materiales |

**Rangos:** Oficial, Sub Jefe (invita, asciende y expulsa a rangos inferiores) y Jefe (todo). Si el jefe nombra a otro jefe, le traspasa la banda. `/banda` muestra tu rango y permite salir.

**Barrio:** cada banda tiene un círculo de su color en el mapa, visible para todos.

**Venta de droga:** cualquiera con droga puede ofrecérsela a un NPC con `ox_target`, salvo policías, sheriffs y médicos. El pago es en dinero negro:

| Dónde se vende | Pago | Aviso |
| --- | --- | --- |
| Fuera de los barrios | Normal | Ninguno |
| Tu propio barrio | Normal | Ninguno |
| El barrio de otra banda | 1,5 veces más | La banda dueña recibe un aviso con la calle y una marca en el mapa, como mucho uno por minuto |

El NPC rechaza la venta un 20 % de las veces, y entonces puede avisar a la policía. Todo se ajusta en `Config.Sale`.

**Grafitis:** `/graffiti` pide una URL de imagen, o píntalo vacío para usar el nombre de tu banda. Apunta a una pared lisa y cercana, viendo la vista previa, y pulsa `Enter` para pintar o `X` para cancelar. Hay un máximo de 15 por banda.

- **Mapa:** cada grafiti muestra un círculo de 70 m con el color de la banda.
- **Borrar:** cualquier miembro de una banda puede borrarlos con `E`. Si es de otra banda, su dueña recibe un aviso al empezar y otro al terminar.
- **Imágenes:** se aceptan enlaces directos `https` a png, jpg, webp o gif de las webs de `Config.Graffiti.AllowedHosts`. Cada jugador descarga la imagen y esa web ve su IP. Con `AllowedHosts = false` se acepta cualquiera, con ese riesgo.
- **Moderación:** en `/bandas` > **Grafitis** se ve cada imagen, su URL y quién la puso, y se puede borrar. La consola del servidor también registra cada una.

Otros recursos pueden usar los exports de servidor `isMember(source, idBanda)` y `getGang(source)`, y el estado `Player(source).state.jjGang`.

Sus objetos ya están en `ox_inventory/data/items.lua`, con imagen: `weed_bag`, `coke_bag` y `meth_bag`.

## HUD: jj_hud

Muestra el estado del jugador abajo a la izquierda, el logo y la hora arriba a la derecha, y el HUD del vehículo abajo a la derecha. `/hud` lo oculta o lo muestra. Se oculta en el menú de pausa y hasta entrar con un personaje.

- **Estado del jugador:** voz, vida, sed y hambre siempre; resistencia y oxígeno cuando bajan, y chaleco si llevas.
- **HUD del vehículo:** velocidad, revoluciones, marcha, gasolina, estado del motor, cinturón, luces, seguro, calle y orientación. En aeronaves muestra la altura, y en barcos y aeronaves no hay marcha ni cinturón.
- **Cinturón:** `Y`. Con él puesto no se puede salir del vehículo. Con `Config.Seatbelt.Eject = true`, además, sin él se sale despedido en un choque fuerte.
- **Hambre y sed:** se guardan con cada personaje y bajan con el tiempo. Los objetos con `status` de `ox_inventory` las llenan, como `croissant_mixto` y `refresco`. Con `Config.Needs.Damage = true`, a 0 se pierde vida. Otros recursos pueden usar el export de servidor `addNeed(source, 'hunger', cantidad)`.
- **Gasolina:** el HUD muestra el nivel del vehículo, pero no hay ningún sistema que la gaste. Hace falta un recurso aparte, como `ox_fuel`.
- **Ajustes:** `shared/config.lua`. Para cambiar el logo, sustituye `web/public/logo.png` y recompila.

La interfaz está en `[jj]/jj_hud/web` y se compila igual que la de `jj_personajes`.

## Personajes: jj_personajes

`jj_personajes` muestra la pantalla de personajes al conectar y carga el que elija el jugador. Dinero, trabajo, inventario y vehículos son de cada personaje, no de la licencia. Sin este recurso, pon `Config.Multicharacter = false` en `[jj]/jj-framework/config.lua`: cada licencia tendrá un solo personaje, que se carga al conectar.

- **Escenario:** los personajes del jugador esperan en fila con su aspecto real, y la cámara viaja hasta el elegido. Los huecos libres son siluetas translúcidas. El sitio, la hora y las animaciones están en `Config.Stage` de `shared/config.lua`.
- **Expediente:** cada personaje muestra su trabajo, su dinero y dónde se le dejó.
- **Huecos:** cada licencia empieza con `Config.DefaultSlots`. Los administradores los gestionan con estos comandos, que también funcionan desde la consola del servidor:
  - `/darslot <id|licencia> [cantidad]`: suma huecos, uno si no se indica la cantidad. Nunca pasa de `Config.MaxSlots`.
  - `/quitarslot <id|licencia> [cantidad]`: resta huecos, uno si no se indica la cantidad. Nunca baja de 1, y quien ya tenga más personajes los sigue viendo todos, pero no puede crear otro.
  - `/setslots <id|licencia> <1-5>`: pone un número exacto.
  - Con el jugador conectado basta su id, y se le avisa del cambio. Si no lo está, se usa su licencia: `license:xxxx`.
- **Personaje nuevo:** rellena su DNI, que se ve en directo, empieza en `Config.NewCharacterSpawn` (el aeropuerto) y recibe los objetos de `Config.StarterItems`.
- **Personaje existente:** vuelve siempre donde estaba, para que salir del servidor no sirva para escapar.
- **Aspecto:** lo gestiona `illenium-appearance` y se guarda en `jj_players.skin`. Un personaje sin aspecto abre el creador nada más aparecer. Si ese recurso no está arrancado, se usa la ropa básica de `Config.BaseOutfits`.

### Editar la interfaz

El código está en `[jj]/jj_personajes/web`, con Bun, Vite y React. FiveM solo usa `web/dist`, así que hay que recompilar después de cada cambio. Con `bun run dev` se abre en el navegador con datos de ejemplo.

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

Las mismas acciones se pueden usar por comando, con los mismos permisos y el mismo registro. Cada uno solo ve en el chat los comandos que puede usar.

| Comando | Nivel | Descripción |
| --- | --- | --- |
| `/tp <id>` o `/tp <x> <y> <z>` | `mod` | Ir a un jugador o a unas coordenadas |
| `/tpm` | `mod` | Ir al marcador del mapa |
| `/bring <id>` o `/traer <id>` | `mod` | Traer a un jugador |
| `/espectar <id>` | `mod` | Espectar a un jugador |
| `/congelar <id>` | `mod` | Congelar o descongelar a un jugador |
| `/kick <id> [motivo]` | `mod` | Expulsar a un jugador |
| `/ban <id> <horas> [motivo]` | `mod` | Banear a un jugador. `0` horas es permanente |
| `/unban <id del baneo>` | `admin` | Quitar un baneo |
| `/noclip` | `mod` | Noclip |
| `/god` | `admin` | Modo dios |
| `/invisible` | `mod` | Invisibilidad |
| `/jugadores` | `mod` | Ver nombres y blips de los jugadores |
| `/coords` | `mod` | Copiar tus coordenadas |
| `/car <modelo>` o `/coche <modelo>` | `admin` | Crear un vehículo |
| `/dv` | `mod` | Borrar el vehículo cercano |
| `/fix` | `mod` | Reparar el vehículo cercano |
| `/flip` | `mod` | Enderezar el vehículo cercano |
| `/darcoche <id> <modelo>` | `admin` | Dar un vehículo en propiedad |
| `/clima <tipo o auto>` | `admin` | Cambiar el clima |
| `/hora <hora> [minutos]` o `/hora auto` | `admin` | Cambiar la hora |

La interfaz está en `[jj]/jj_admin/web` y se compila igual que la de `jj_personajes`.

## Creador de trabajos: jj_creatorjobs

Crea trabajos sin reiniciar el servidor. Se abre con `/createjob` o `F9`: un administrador (`jj.admin`) gestiona todos los trabajos creados, y un jefe solo los empleados del suyo. Los de `[jj]/jj-framework/config.lua` no aparecen aquí.

- **Empleados:** contratar por ID de jugador conectado, despedir y cambiar de rango, también a desconectados. Un jefe no puede nombrar a otro jefe ni actuar sobre otro jefe.
- **Rangos:** nombre, sueldo y permisos de jefe. Quien tenga un rango que se borra pasa al de nivel 0.
- **Puntos:** servicio, inventario, mercado, ropero, sociedad, garaje de empresa, guardar vehículo, garaje personal, garaje de compraventa y zona de trabajo. Al salir de la zona se queda fuera de servicio. El garaje personal es un garaje de `jj_garages`.
- **Menú F6:** facturar, cachear, compraventa, reparar, abrir cerradura, incautar, limpiar, desvolcar, esposar, abrir o cerrar el negocio y enviar anuncios.
- **Blips, mercado, vehículos y teleports:** por trabajo. Hay además teleports globales, con contraseña y mundo propio opcionales.
- **Dinero:** al crear un trabajo se crea su cuenta de empresa en `fd_banking`, con sus jefes como dueños. Con `Config.UseBanking = false`, o sin ese recurso, usa la columna `money` de `jobscreator_jobs`.
- **Facturas:** las de F6 llegan a las facturas del banco del cliente, que puede pagarlas o rechazarlas, y el dinero entra en la cuenta de la empresa al pagarlas. La experiencia se da al pagar, comprobándolo cada minuto. Un administrador puede facturarse a sí mismo para probar. Sin `fd_banking`, el cliente la paga en el momento.
- **Sueldos:** con `Config.SocietyPaycheck = true` salen de la sociedad a las :00 y las :30, solo de servicio. Con `false` los paga jj-framework con sus nóminas, sin sacarlos de la sociedad.

- **Registro:** cada empresa guarda 30 días de quién ha entrado o salido de servicio, contratado, despedido, cambiado rangos, movido dinero, enviado o pagado facturas, sacado o vendido vehículos y cambiado la configuración. Lo ven los administradores y sus jefes, en la pestaña Registro. A Discord llegan cuatro canales, con los webhooks al principio de `server/logs.lua`: `jefe` (contratar, despedir y cambiar rangos), `caja` (ingresos, retiradas y pedidos pagados con la sociedad), `fichaje` (entrar y salir de servicio) y `compraventa` (compraventa de vehículos). El resto solo queda en la pestaña Registro. `/testlogs` envía una prueba a cada canal, y si Discord rechaza un webhook, la consola lo avisa.

Los comandos `/abrirnegocio` y `/cerrarnegocio` son para el jefe, o para quien tenga esa opción en F6. Crafteo necesita `josete_crafteos`, que no está en este servidor. Los puntos de Tuneo abren `jj_tuneos`.

`jj_creatorjobs` debe arrancar después de `jj_garages` y antes de `fd_banking`, que espera a sus trabajos para no borrar sus cuentas.

La interfaz está en `[jj]/jj_creatorjobs/web`. En el navegador funciona con datos de prueba, y con `?jefe` en la URL se ve como un jefe.

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

La interfaz está en `[jj]/jj_chat/web` y se compila igual que la de `jj_personajes`. Los mensajes privados no se escriben en la consola del servidor; los demás, sí.

## Otros recursos de jj

- **`jj_tuneos`:** menú de tuneo. Sus puntos están en `Config.Positions` de `config/config.lua`, y allí solo se tunea un vehículo propio. `/tuneo` lo abre con cualquier vehículo para `jj.admin` y `jj.mod`, igual que un punto de Tuneo de `jj_creatorjobs` para sus empleados de servicio. El tuneo se guarda en `jj_vehicles`. Con `Config.FreeTuning = true` es gratis.
- **`jj_discord`:** presencia en Discord con el ID, los jugadores conectados y, si quieres, el personaje y el trabajo. Pon el ID de la aplicación de Discord, las imágenes y los botones en `config.lua`.
- **`jj_bizztablet`:** tablet de negocios y eventos, que se abre con el objeto `tablet_locales` o con los exports de cliente `openTablet`, `openEvents` y `openJobPage(trabajo)`. Lista los trabajos de jj-framework y `jj_creatorjobs`; los artículos salen del Mercado de cada trabajo. El jefe edita la ficha y crea eventos, y solo un administrador o una licencia de `Config.Licenses` cambia el logo, la categoría y la ubicación.
- **`jj_pausemenu`:** menú de pausa con Escape, que da acceso al mapa, los ajustes, los datos del personaje, los anuncios y los comercios de `jj_creatorjobs`. Los administradores añaden anuncios con `/addanuncio <mensaje>` y los quitan con `/quitaranuncio <id>`; desde otro recurso, con el export `AddAnnouncement(mensaje, autor)`. Los iconos y los comercios ocultos están en `config/config.lua`.
- **`jj_policejob`:** comisarías, armerías, vehículos de servicio, esposas, escolta, cacheo, cárcel de comisaría y objetos de carretera. Se configura en `shared/config.lua`. Los objetos o armas de la armería que no existan en `ox_inventory` no salen y la consola lo avisa.
- **`jj_policedispatch`:** avisos, radio por canales, referencias en el mapa, radar y códigos, con F5. Comandos: `/911`, `/112`, `/rpol`, `/rems`. Desde otro recurso: exports de cliente `sendAlert`, `sendAmbulanceAlert`, `sendDrugAlert` y `sendVehicleAlert`. Su interfaz está en `web/src` (Bun, Vite, React y Mantine): después de cambiarla hay que ejecutar `bun install` y `bun run build` en `web`.
- **`jj_policetablet`:** expedientes de ciudadanos y vehículos, multas (llegan como factura a `fd_banking`), informes, código penal, cárcel federal, agentes y ajustes de rangos. Se abre con `Inicio` o con el objeto `police_cad`. Las fotos necesitan `screenshot-basic` y `set jj_policetablet:fivemanage "clave"` en `server.cfg`. Su interfaz está en `web/src` (Bun, Vite, React y Mantine): después de cambiarla hay que ejecutar `bun install` y `bun run build` en `web`.
- **`jj_boosting`:** contratos de robo de vehículos con progresión por clases, hackeos, rastreador GPS, avisos a la policía, criptomoneda interna, tienda, historial, clasificación y panel de administración. Se abre en sus puntos de acceso o con `/boosting`; el panel, con `/boostingadmin`. Todo está explicado en su `README.md`.
- **`pug-robberycreator`:** creador de robos de un tercero, con parte de su código cifrado. Funciona con JJ Framework gracias a `config/jj-bridge.lua`, que hace de qb-core solo dentro de ese recurso. Se configura con `/robbery` (administradores) y necesita `ox_doorlock` para las puertas de los robos.
- **`jj_paymethods`:** diálogo de pago con los exports de cliente `PayMethods`, `PayLater`, `CheckMoney` y `SelectMethod(importe, permitirTarjeta)`, que solo devuelve el método elegido. Para cosas caras, usa `SelectMethod` y cobra desde el servidor con el export `Pay(source, importe, método)`: así el precio no depende del cliente. La tarjeta de empresa de policía aprueba el pago sin descontar nada, porque no hay cuentas de empresa; lanza `jj_paymethods:server:companyPayment` por si otro recurso lo contabiliza.
- **`jj_personalmenu`:** menú personal (`F10`), armas visibles en el cuerpo y cámara libre. `/freecamadmin` necesita `jj.admin`. Las estadísticas requieren `jj_gym`, y la facción ilegal, `av_gangs`.
- **`jj_smallresources`:** cargar personas, chalecos, documentos, detector de huellas, tiendas y ajustes del mundo.
- **`jj_things`:** esposas, `/me`, `/do`, `/entorno`, `/cachear`, `/maletero`, carterismo, doctores ilegales, silla de ruedas y efectos varios. Los avisos a policía y médicos llegan a quien esté de servicio.

- **`jj_keysystem`:** llaves de vehículos. `U` abre y cierra el vehículo si eres su dueño o llevas una llave válida. El cerrajero hace copias y cambia la cerradura, lo que invalida las copias anteriores. Otros recursos pueden usar los exports de servidor `addTempKey` y `hasKey`.
- **`jj_alquiler`:** alquiler de barcos. El precio sale de `shared/cfg.lua`, se cobra en efectivo y da una llave temporal. Solo se puede devolver el vehículo alquilado.
- **`jj_gym`:** membresía, ejercicios y estadísticas por personaje, y alquiler de bicicletas.
- **`jj_recoil`:** retroceso propio para cada arma, en `shared/main.lua`. El objeto `energetica_recoil` lo reduce durante un tiempo, que se conserva aunque el personaje salga del servidor.
- **`jj_tienda`:** tienda de vales y coches que se abre con `/tienda` y se paga con Ethereum, la cuenta `ethereum` del framework. Se gana por tiempo de juego. Los coches se entregan en el garaje del comprador con `jj_garages`. Artículos, precios y pagos están en `config.lua`.
- **`jj_radio`:** radio para civiles que se abre con el objeto `radio`. Se sintoniza cualquier frecuencia del 1.0 al 999.9, con frecuencias guardadas por personaje, invitaciones por id, volumen y animación al hablar. La tabla `jj_radio_frequencies` se crea sola. Usa `pma-voice` y se configura en `shared/config.lua`.
- **`jj_entornozones`:** zonas del mapa que muestran un texto de rol al entrar en ellas. Se gestionan desde el panel `/entornos`, solo para administradores: nombre, texto, duración y color del aviso, activar o desactivar cada zona, probar el aviso, ir a la zona y `Mostrar zonas` para verlas dibujadas en el mundo. La forma se dibuja con la cámara libre de `fivem-freecam`: C añade o quita un punto, K edita uno, la rueda cambia la altura, G termina y Retroceso cancela. Se guardan en la tabla `jj_entorno_zones`, que se crea y se actualiza sola.
- **`jj_queue`:** cola de entrada enlazada con vuestro Discord. Un bot comprueba al conectar que la persona está en el servidor de Discord, si tiene el rol de whitelist y qué prioridad le dan sus roles; todo se configura con ids de roles en `config.lua`, y el token del bot va en `server.cfg` con `set jj_queue_bot_token`. También hay prioridad por permisos (ACE), y quien se cae y vuelve en 3 minutos entra el primero. `/addwhitelist <id>` y `/removewhitelist <id>` dan o quitan la whitelist a mano, `/rolesdiscord <id>` muestra lo que ve el bot de alguien y `/cola` cuánta gente espera.
- **`jj_flags`:** captura de banderas entre las bandas de jj_gangs, cada una con el color de su banda. Un admin abre el evento con `/comenzarbanderas`; los miembros plantan con `/ponerbandera` (máximo 5 por banda) y capturan las de otras con H. La captura dura 5 minutos: se para si hay defensores vivos en la zona y se cancela si no queda ningún atacante. `/comprobarbanderas` muestra cuántas tiene cada banda y `/terminarbanderas` cierra el evento con la clasificación. Las banderas se guardan en la base de datos. Con `/panelbanderas` se abre un panel para empezar y terminar el evento, ver las capturas en directo, poner, borrar o cambiar de dueño las banderas, sacar bandas del evento y cambiar tiempos, radio y máximo sin reiniciar.
- **`jj_crafting`:** crafteo de dos tipos. **Civiles:** mesas que se colocan con un objeto, como `bench_basic` y `bench_advanced`, con roles para compartirlas. **Bandas:** una mesa en un punto fijo del mapa que solo ven y usan los miembros de esa banda, que comparten su almacén. Todo se configura desde el panel `/crafteoadmin`, solo para administradores: recetas, tipos de mesa, puntos de banda, planos, ajustes y mesas colocadas. Se guarda en la base de datos (tablas `jj_crafting_*`) y se aplica al momento, sin reiniciar. `data/crafting.lua` solo se usa para rellenar esas tablas la primera vez. Hay cola de fabricación, experiencia y planos, y usa las mismas tablas que el crafteo que tenía `ox_inventory`, así que se conservan las mesas, la experiencia y los almacenes.
- **`jj_radioilegal`:** panel de banda que se abre con F6. Tiene 10 frecuencias de radio privadas por banda, para las que hace falta el objeto `radio`, y las acciones de arrastrar, esposar, meter o sacar del vehículo y poner una bolsa en la cabeza. Usa `jj_gangs`, `pma-voice`, y las esposas y la escolta de `jj_things` y `jj_policejob`. Se configura en `shared/config.lua`.
- **`jj_sustos`:** comandos de broma solo para administradores: `/susto`, `/sustofoto`, `/sustostop`, `/sustocoche` y `/sustoexplosion`. Sin id se aplican a quien los usa. La duración máxima está en `shared/config.lua`.
- **`jj_crews`:** crews de pilotos con miembros, rangos, banco y ranking. Se abre con el objeto `tablet_crew` y se administra con `/crewadmin`. Hay que importar `sql/crews.sql`.
- **`jj_racing`:** carreras con creador de circuitos, salas, premios, récords y retos entre crews. Se abre con el objeto `tablet_reacing` y se administra con `/raceadmin`. Hay que importar `sql/races.sql` y, para tener 102 circuitos de inicio, `sql/tracks.sql`.
- **`jj_announce`:** banners para todo el servidor con `/anuncio`, `/evento`, `/mantenimiento` y `/urgente`, con el permiso `jj.admin`. Otros recursos usan el export de servidor `Announce(tipo, mensaje, autor)`.
- **`jj_loadingscreen`:** pantalla de carga. No tiene parte de servidor. El audio no está en el repositorio por su tamaño: añade el tuyo en `web/assets/audio.mp3`.

Los objetos de estos recursos ya están en `[ox]/ox_inventory/data/items.lua`, con sus imágenes en `web/images`: `id_card`, `driver_license`, `vehicle_key`, `gym_membership`, `croissant_mixto`, `refresco`, `armor`, `heavyarmor`, `medikit`, `detector`, `handcuffs`, `llave_negra`, `wheelchair`, y `lockpick`, que abre vehículos con `jj_keysystem`.

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
| `/darcp <id\|licencia> <cantidad>` | `jj.admin` o consola | Da CP |
| `/quitarcp <id\|licencia> <cantidad>` | `jj.admin` o consola | Quita CP, solo si tiene suficientes |
| `/ponercp <id\|licencia> <cantidad>` | `jj.admin` o consola | Fija el saldo de CP |
| `/vercp <id\|licencia>` | `jj.admin` o consola | Muestra el saldo de CP |

Las cuentas, los trabajos, los puntos de aparición y los intervalos se configuran en `[jj]/jj-framework/config.lua`.

### CP: monedas de donación

Las CP son de la licencia, no del personaje: todos los personajes de un jugador comparten el mismo saldo, que se guarda en la tabla `jj_cp` y aparece en el menú de pausa y en el menú personal. Las que tuviera un personaje de antes pasan a su licencia la primera vez que entra.

Los comandos funcionan desde la consola, así que sirven para entregar las compras de Tebex: con el jugador conectado basta su id (`darcp {id} 500`), y si no lo está, su licencia (`darcp license:xxxx 500`). Cada cambio queda en la consola del servidor.

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
| `Notify(source, mensaje, tipo, duración)` | Muestra una notificación de ox_lib. `tipo`: `inform`, `success`, `warning` o `error`. Los dos últimos son opcionales |
| `IsAdmin(source)` | `true` si tiene el permiso de administración |
| `GetCP(source o licencia)` | Saldo de CP |
| `AddCP(source o licencia, cantidad, motivo)` | Saldo nuevo o `nil` |
| `RemoveCP(source o licencia, cantidad, motivo)` | Saldo nuevo, o `nil` si no tiene suficientes |
| `SetCP(source o licencia, cantidad, motivo)` | Saldo nuevo o `nil` |

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
| `notify(mensaje, tipo, duración)`, `kick(motivo)` | |

### Cliente: `JJ`

`GetPlayerData()`, `IsLoaded()`, `IsSpawned()`, `Notify(mensaje, tipo, duración)`, `ShowTextUI(texto, opciones)`, `HideTextUI()`, `IsTextUIOpen()`, `ProgressBar(datos)`, `ProgressCircle(datos)`, `AlertDialog(datos)`, `InputDialog(título, filas, opciones)`, `ShowContext(datos)`, `TriggerCallback(nombre, cb, ...)` y `AwaitCallback(nombre, ...)`.

## Eventos

| Evento | Lado | Parámetros |
| --- | --- | --- |
| `jj:server:playerLoaded` | Servidor | `source` |
| `jj:server:playerSpawned` | Servidor | `source` |
| `jj:server:playerDropped` | Servidor | `source, motivo` |
| `jj:server:moneyChanged` | Servidor | `source, cuenta, accion, cantidad, saldo, motivo` |
| `jj:server:cpChanged` | Servidor | `licencia, accion, cantidad, saldo, motivo` |
| `jj:server:jobChanged` | Servidor | `source, trabajo, trabajoAnterior` |
| `jj:server:dutyChanged` | Servidor | `source, enServicio` |
| `jj:client:playerLoaded` | Cliente | `datos` (usa `RegisterNetEvent`) |
| `jj:client:playerSpawned` | Cliente | |
| `jj:client:playerRespawned` | Cliente | |
| `jj:client:playerDataChanged` | Cliente | `clave, valor` |
