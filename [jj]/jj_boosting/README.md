# jj_boosting

Contratos de robo de vehículos para JJ Framework: cola de encargos, progresión por clases, hackeos, rastreador GPS, avisos a la policía, criptomoneda interna, tienda, historial, clasificación, perfil y panel de administración.

Es una implementación propia, inspirada en las funciones públicas de los sistemas de boosting. No contiene código de ningún recurso de terceros.

## Instalación

1. Copia la carpeta `jj_boosting` a `[jj]`.
2. Añade `ensure jj_boosting` al `server.cfg`, después de `jj_policetablet`.
3. Base de datos: no hace falta hacer nada, porque las tablas se crean solas al arrancar. Si lo prefieres, ejecuta `sql/install.sql` (también está en `jjframework.sql`). Se puede ejecutar más de una vez sin perder datos.
4. Sube también `[jj]/jj_policedispatch/server/main.lua`, que incluye el export `AddAlert` para los avisos.
5. Da acceso al panel a quien corresponda:

```
add_ace group.admin jj.boosting.admin allow
```

Quien ya tenga el permiso `jj.admin` del framework también entra.

### Dependencias

| Recurso | Para qué |
|---|---|
| `oxmysql`, `ox_lib`, `ox_target`, `ox_inventory`, `jj-framework` | Obligatorios |
| `jj_policedispatch` | Avisos a la policía. Sin él no se envían, pero el recurso funciona |
| `jj_keysystem` | Llaves del vehículo robado. Sin él no se dan llaves |

Requiere OneSync, porque el servidor crea los vehículos y los protectores.

## Antes de abrirlo a los jugadores

**Revisa las coordenadas de `Config.Zones`, `Config.Dropoffs` y `Config.Access`.** Son orientativas y no se han probado en el juego. Comprueba sobre todo que los `spots` de cada zona caen en sitios de aparcamiento libres en tu mapa. También puede cambiar el resultado si usas mapas personalizados.

## Cómo funciona un contrato

1. El jugador entra en la cola desde la terminal y recibe ofertas de las clases que tiene desbloqueadas. También puede comprar contratos con criptomoneda.
2. Acepta una oferta y ve en el mapa una zona aproximada.
3. Al entrar en la zona, el servidor crea el vehículo. Se busca por modelo y matrícula.
4. Según la modalidad:
   - **Básico:** se sube y se lo lleva.
   - **Intermedio:** tiene cerradura electrónica; hay que hackearla con `ox_target` sobre el vehículo.
   - **Avanzado:** además tiene protectores armados y un rastreador que la policía sigue en el mapa.
5. Lo lleva al punto de entrega, lo para y pulsa **E**.
6. El servidor valida la entrega, borra el vehículo y paga lo pactado.

Si caduca, se destruye, se agotan los intentos de hackeo o el jugador no vuelve tras desconectarse, el contrato se pierde y resta experiencia (`failXpPenalty`).

### Rastreador

Se activa al robar el vehículo. El servidor envía la posición con un error de `Config.Tracker.accuracy` metros a los policías de servicio y a nadie más. Tras `disableAfter` segundos, el conductor puede desactivarlo con la tecla `Config.Tracker.key` (F7), que cada jugador puede cambiar en los ajustes del juego. Con `mode = 'both'` gasta el objeto si lo lleva; si no, abre el minijuego.

## Configuración (`config.lua`)

| Opción | Qué controla |
|---|---|
| `Locale` | Idioma: `es` o `en` |
| `Debug` | Muestra en consola lo que se registra |
| `Notify` | `jj` (framework) u `ox` (ox_lib) |
| `MoneyAccount` | Cuenta en la que se cobra: `cash`, `bank` o `black` |
| `CryptoName` | Nombre de la moneda |
| `Admin` | Comando del panel, permisos ACE e identificadores con acceso |
| `Access` | Comando y puntos de acceso (NPC o punto) |
| `Distances` | Distancias de interacción |
| `Contracts` | Límites de ofertas, gracia al desconectarse, penalizaciones y controles de entrega |
| `Queue` | Espera entre ofertas |
| `Levels` | Experiencia necesaria por nivel |
| `HackDifficulties` | Tamaño, longitud, tiempo e intentos de cada dificultad |
| `HackExhausted` | Al agotar intentos: `fail` pierde el contrato, `alarm` salta la alarma y avisa |
| `Tiers` | Cada modalidad: cerradura, hackeo, rastreador y protectores |
| `Classes` | Cada clase: modalidad, experiencia para desbloquearla, probabilidad en la cola, duración, policías mínimos, probabilidad de aviso, dificultad, precio, recompensas y vehículos |
| `Zones` / `Dropoffs` | Zonas de búsqueda y puntos de entrega |
| `Guards` | Modelos, arma, blindaje y distancia a la que atacan |
| `Tracker` | Frecuencia, precisión, espera, modo de desactivación y tecla |
| `Police` | Trabajos, integración y probabilidad de aviso al fallar un hackeo |
| `Store` | Punto de recogida y artículos |
| `Profile` | Límites del nombre y dominios permitidos para la imagen |
| `Leaderboard` | Criterio de orden, tamaño y caché |
| `RateLimit` | Límites de frecuencia |
| `LogRetentionDays` | Días que se guardan los registros |

Los vehículos que no sean coches llevan `type` en su entrada: `{ model = 'bati', label = 'Bati', type = 'bike' }`.

### Tienda

Cada artículo lleva `id`, `label`, `price` y uno de estos dos tipos:

- `type = 'item'` con `item`: da ese objeto de `ox_inventory`. Si no existe, avisa en la consola y no sale a la venta.
- `type = 'service'` con `service` y `uses`: de momento existe `priority`, que reduce a la mitad la espera de las siguientes ofertas.

Opcionales: `stock`, `maxPerPlayer`, `requiredClass` y `pickup = true` para entregarlo en `Store.pickupPoint`. El stock se repone en cada arranque del recurso.

### Abrir la terminal con un objeto

En `data/items.lua` de `ox_inventory`:

```lua
['laptop'] = {
    label = 'Portátil',
    client = { export = 'jj_boosting.openTerminal' },
},
```

## Integración

Todo el contacto con otros recursos está en `server/bridge.lua`. Para usar otro sistema, solo hay que cambiar ese archivo.

| Función | Con qué |
|---|---|
| Jugador e identificador | `JJ.GetPlayer`, `JJ.GetPlayerByIdentifier`, `player.identifier` |
| Dinero | `player.addMoney` |
| Permisos | `JJ.IsAdmin` y ACE |
| Notificaciones | `JJ.Notify` |
| Trabajo y servicio | `player.getJob()` |
| Avisos policiales | `exports.jj_policedispatch:AddAlert(datos, coords)` |
| Inventario | `exports.ox_inventory` |
| Llaves | `exports.jj_keysystem:addTempKey` |

Para enviar los avisos a otro sistema, pon `Config.Police.dispatch = 'event'` y escucha `jj_boosting:policeAlert` en el servidor. Recibe `(datos, coords)`.

## Administración

Abre el panel con `/boostingadmin`. Las pestañas son:

- **Resumen:** estadísticas, contratos en marcha (se pueden cancelar) y reposición del stock.
- **Jugadores:** búsqueda y ficha; asignar un contrato de cualquier clase y ajustar experiencia o criptomoneda.
- **Historial:** todos los contratos, con filtros.
- **Contratos:** activar o desactivar clases y vehículos, y multiplicador de recompensas. Se guarda en la base de datos.
- **Registros:** auditoría por categoría.

Categorías de los registros:

| Categoría | Qué recoge |
|---|---|
| `admin` | Cada acción del panel, con autor y objetivo |
| `security` | Accesos denegados y acciones sospechosas |
| `police` | Avisos generados |
| `tracker` | Cambios del rastreador |
| `contract` | Aceptados, completados y hackeos |
| `store` | Compras y recogidas |
| `economy` | Pagos fallidos |

Si en `security` aparece `deliver_too_fast`, `hack_too_fast`, `seat_without_hack` o `hack_invalid_token` de forma repetida, conviene revisar a ese jugador.

## Seguridad

El cliente solo pide acciones y muestra el resultado:

- **Recompensas:** se guardan en la fila del contrato al crearlo. El cliente nunca las envía.
- **Contrato completado una sola vez:** el cambio de estado es `UPDATE … WHERE status = ?`; solo gana una llamada.
- **Dinero sin duplicar:** cada movimiento tiene una referencia única (`contract:<uid>`) y el saldo no puede quedar en negativo.
- **Stock:** `UPDATE … WHERE remaining >= ?`, así dos compras a la vez no superan lo disponible.
- **Hackeo:** el servidor crea la partida y corrige la respuesta. Comprueba token, estado, distancia y tiempo.
- **Entrega:** se comprueban entidad, modelo, marca del contrato, distancia, velocidad y tiempo desde el robo.
- **Panel:** el permiso se comprueba en cada llamada. Tocar la interfaz no da acceso a nada.
- **Límites:** frecuencia por jugador y operación, y bloqueo de operaciones simultáneas.

## Limitaciones

- El minijuego se muestra en el cliente, así que la secuencia se envía al jugador. Un cliente modificado podría resolverlo solo, aunque sigue limitado por token, tiempo, distancia y estado.
- Si el recurso se reinicia, los contratos en marcha se cierran sin penalización, porque sus vehículos dejan de existir.
- Las compras pendientes de recoger no caducan.
- La imagen de perfil es una URL validada por dominio: el recurso no sube ni guarda imágenes.

## Procedimiento de pruebas

Con dos personajes, uno de ellos admin, y un policía de servicio:

1. **Acceso:** abre la terminal con `/boosting` y ciérrala con ESC. El ratón debe quedar libre.
2. **Permisos:** con un jugador normal, `/boostingadmin` debe negar el acceso y dejar un registro en `security`.
3. **Contrato básico:** en el panel, asígnate uno de clase D, acéptalo, ve a la zona, róbalo y entrégalo. Comprueba dinero, criptomoneda, experiencia e historial, y que el vehículo desaparece.
4. **Hackeo:** asígnate uno de clase B. Prueba a fallar: debe restar un intento. Después resuélvelo y comprueba que se abre.
5. **Avanzado:** con uno de clase A, comprueba que los protectores atacan, que el policía recibe el aviso y ve el rastreador, y que no recibe nada si está fuera de servicio. Desactiva el rastreador con F7: el marcador debe desaparecer.
6. **Desconexión:** desconéctate con un contrato en marcha y vuelve antes de `abandonGrace`: debe seguir activo. Repite sin volver: debe perderse.
7. **Tienda:** compra hasta agotar el stock y el límite por jugador, y recoge un artículo en el punto.
8. **Registros:** revisa que cada acción anterior ha quedado anotada en el panel.
