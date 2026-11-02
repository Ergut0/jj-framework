# jj_handling

Editor de handling en tiempo real para JJ Framework. Incluye:

- Perfiles preconfigurados y perfiles guardados, con historial e importación y exportación.
- Modo taller para mecánicos.
- Panel de administración y registro de cambios.
- Permisos que se comprueban en el servidor.

## Instalación

1. Copia `jj_handling` en `[jj]`.
2. En `server.cfg`, después de `jj-framework`, `ox_lib` y `oxmysql`, añade:
   ```
   ensure jj_handling
   ```
3. Las tablas se crean solas al arrancar. Si prefieres crearlas a mano, están en `sql/install.sql`.
4. Opcional: los registros en Discord. Añade en `server.cfg`:
   ```
   set jj_handling_webhook "https://discord.com/api/webhooks/..."
   ```
5. Opcional: el superadministrador. Añade en `server.cfg`:
   ```
   add_ace group.admin jj.superadmin allow
   ```
   También puedes ponerlo en otro grupo solo para la dirección.

La interfaz ya está compilada en `web/dist`. Solo hace falta volver a compilarla si cambias algo en `web/src`:

```
cd web
bun install
bun run build
```

> La petición pedía `html/` con HTML, CSS y JS sueltos. Se ha hecho con React y Vite en `web/`, igual que el resto de interfaces del servidor, para mantener el mismo tema, logo y tipografía. El juego carga el resultado compilado (`web/dist`), así que funciona igual.

## Cómo se usa

- **`/handling`** abre el editor siendo el conductor de un vehículo. Se le puede asignar una tecla en *Ajustes → Teclas → FiveM → Editor de handling*.
- **Mecánicos:** en un taller de `Config.Workshops` y conduciendo, les aparece **[E] Editor de handling**.
- **Admins sin vehículo:** `/handling` abre solo el panel (perfiles, registros y ajustes).

### Pestaña Editor

- Seis categorías de parámetros. Cada uno tiene deslizador, campo numérico, valor de serie, porcentaje de cambio y botón para volver al valor de serie.
- Los cambios se notan **al momento** en el coche, solo para ti, como vista previa.
- **Aplicar:** deja los cambios en el vehículo como **temporales**. Los ve quien lo conduzca, aunque cambie el conductor.
- **Guardar:** crea un perfil o actualiza el que se cargó.
- **Cancelar:** deshace lo que no se ha aplicado.
- **Restablecer:** quita los cambios temporales. El coche vuelve a su perfil guardado o al original.
- **Comparar:** elige otra configuración (B) y cambia entre A y B para notarlo conduciendo. Cada parámetro muestra el valor de B.
- **Ver el original un momento:** pone el handling de serie sin perder lo que estabas editando.
- **Probar conduciendo:** oculta el editor sin perder nada. Vuelves con `/handling`.
- **Avisos:** en el lateral salen las configuraciones poco realistas y los errores que impiden aplicar.

### Pestaña Perfiles

- Lista filtrable: este vehículo, todos, míos, globales y de serie. Se puede buscar por nombre, modelo o autor.
- Cada perfil tiene ID, nombre, modelo, autor, fecha de creación, fecha de última modificación, versión y la tabla de valores comparada con los de serie.
- Acciones:
  - Cargar en el editor.
  - Instalar en este vehículo o quitarlo.
  - Poner o quitar de serie.
  - Editar valores, sin vehículo, desde el panel.
  - Duplicar.
  - Exportar a JSON.
  - Historial, con opción de restaurar versiones anteriores.
  - Borrar.
- **Nuevo:** crea un perfil indicando el nombre de spawn del modelo, por ejemplo `sultan`. Solo para el panel.
- **Importar:** pega un JSON exportado. Se valida todo antes de guardarlo.

### Pestaña Registros

Todo lo que cambia queda guardado en `jj_handling_logs`, y en Discord si hay webhook. Se puede filtrar por acción y buscar por persona, matrícula o perfil. Se registra:

- Abrir el editor.
- Aplicar, restaurar o que caduque una prueba.
- Crear, editar, duplicar, borrar, importar o exportar perfiles.
- Restaurar versiones.
- Instalar o quitar perfiles, y ponerlos o quitarlos de serie.
- Cambiar los ajustes globales.

### Pestaña Ajustes globales (solo superadmin)

- Aplicar perfiles automáticamente.
- Duración de las pruebas.
- Margen de los mecánicos.
- Si los mecánicos pueden guardar perfiles.
- Si los mecánicos pueden instalar perfiles.

Se guardan en el servidor y mandan sobre `config.lua`.

## Qué se aplica a cada vehículo

Lo aplica **quien conduce** al subir al asiento del conductor. Es quien simula el coche en FiveM. Si hay varias cosas, manda la primera de esta lista:

1. **Cambios temporales** (state bag `jj_handling` en el vehículo). Los pone el servidor tras validarlos y se quitan:
   - con Restablecer,
   - pasados los minutos de prueba,
   - si el vehículo se aleja del taller más de `testRadius`,
   - o al bajarse, si `Config.RestoreOnLeaveVehicle` está activo.
2. **Perfil instalado** en la matrícula del vehículo.
3. **Perfil de serie** del modelo (para todos los de ese modelo).
4. **Original**.

Para no saturar la red:

- Los clientes no reciben listas de handling. Al subir piden una vez lo suyo, que se guarda 5 minutos.
- Cuando algo cambia, el servidor solo avisa de qué modelo o matrícula hay que volver a pedir.
- Los archivos del vehículo no se tocan nunca. Los cambios usan `SetVehicleHandlingFloat`, que afecta solo a ese vehículo y se pierde al borrarlo.

**Varias personas editando a la vez.** Cada perfil tiene versión. Si alguien guarda una versión vieja, el servidor lo rechaza con *«Otra persona ha cambiado este perfil»* y no pisa nada. Cada edición guarda la anterior en el historial: se conservan las últimas `Config.HistoryPerProfile`.

## Permisos

Se comprueban siempre en el servidor. La interfaz solo oculta lo que no puedes usar.

| Nivel | Cómo se consigue | Por defecto |
|---|---|---|
| Usuario | — | Sin acceso |
| Mecánico | Trabajo de `Config.MechanicJobs` con el grado mínimo y de servicio | Solo en talleres. Tracción, frenos, suspensión y dirección, sin masa ni marchas. ±35 % del original. Prueba, guarda e instala sus perfiles |
| Admin | ACE `jj.admin` (el de JJ Framework) | Todo menos los ajustes globales |
| Superadmin | ACE `Config.SuperAdminAce` (`jj.superadmin`) | Todo |

Cada nivel se configura en `Config.Levels`:

- **Categorías y parámetros:** `categories` y `exclude`.
- **Margen respecto al original:** `maxRelative`.
- **Acciones:** `applyTemp`, `saveProfiles`, `install`, `modelDefault`, `editAny`, `deleteAny`, `import`, `export`, `panel`, `logs` y `settings`.

Los mecánicos de un taller concreto se limitan con `jobs` dentro de cada taller.

## Seguridad

- **Cada petición:**
  - Comprueba el nivel del jugador.
  - Comprueba que conduce **ese** vehículo (por netId) y que, si es mecánico, está dentro del taller.
  - Pasa por un control de repetición: `Config.Security.Cooldown` y `Burst`.
- **Modelo y matrícula:** se leen en el servidor, nunca de la interfaz.
- **Clase del vehículo:** la manda el cliente porque el servidor no la conoce. Se contrasta con el tipo de vehículo, que sí lee el servidor: una moto no puede decir que es un coche. Helicópteros, aviones, barcos, trenes y las clases o modelos bloqueados se rechazan.
- **Valores:**
  - Parámetros desconocidos, texto, NaN o infinitos.
  - Fuera del rango de la clase.
  - Agarre mínimo mayor que el máximo.
  - Recorrido inferior mayor o igual que el superior.
  - Más allá del margen del mecánico.
  - Todo eso se rechaza. El margen se calcula sobre los valores originales del **primer** momento en que se abrió el editor con ese vehículo, para que no se puedan mover.
- **Importación:** limitada a `Config.Security.MaxImportSize`, con formato `jj_handling` y todos los valores validados.
- **Base de datos:** lo que se carga se vuelve a validar al arrancar.
- **Webhook:** se quitan las menciones y el formato de Discord.

## Crear perfiles preconfigurados

Están en `Config.Presets`. Cada operación parte del handling **original de cada vehículo**, así que un mismo perfil se adapta a cada modelo:

```lua
{ id = 'mi_perfil', label = 'Mi perfil', desc = 'Para qué sirve', classes = { 0, 1, 6, 7 }, ops = {
    fInitialDriveForce = { mult = 1.15 },   -- 15 % más que el original
    fSuspensionRaise = { add = -0.02 },     -- 2 cm más bajo que el original
    fDriveBiasFront = { set = 0.0 },        -- Valor fijo: propulsión trasera
} }
```

- `classes` limita en qué clases de vehículo sale el perfil (por `GetVehicleClass`). Sin `classes`, en todas.
- El resultado siempre se recorta a los rangos de la clase (`Config.ClassLimits`) y, para mecánicos, a su margen y sus parámetros.
- Los valores de ejemplo son un punto de partida. **Pruébalos con los coches del servidor antes de usarlos en serio.**

Los perfiles guardados (pestaña Perfiles) guardan **valores absolutos** solo de lo que cambia, para un modelo concreto. Por eso un perfil de `sultan` no se puede instalar en otro modelo.

## Parámetros, unidades y limitaciones

Todo se muestra y se guarda en unidades del `handling.meta`. El juego guarda algunos de otra forma y el recurso los convierte (`shared/parameters.lua`):

| Parámetro | En el juego | Conversión |
|---|---|---|
| `fInitialDriveMaxFlatVel` | m/s | meta = interno × 3.6 |
| `fSteeringLock`, `fTractionCurveLateral` | radianes | meta = grados |
| `fBrakeBiasFront`, `fSuspensionBiasFront`, `fAntiRollBarBiasFront` | delante × 2 y detrás (1 − meta) × 2 | también se escribe el valor trasero |
| `fDriveBiasFront` | igual que los repartos, con 0 y 1 puros | **`fDriveBiasRear` es derivado**: se muestra pero no se edita |
| `fSuspensionCompDamp`, `fSuspensionReboundDamp` | ÷ 10 | meta = interno × 10 |
| `fInitialDragCoeff` | ÷ 10000 | meta = interno × 10000 |

Estas conversiones son las que documenta la comunidad de FiveM. **Compruébalas en el juego:** abre un coche cuyo `handling.meta` conozcas y compara los valores de serie del editor. Si alguno no cuadra, ajusta su `scale` en `shared/parameters.lua`.

Limitaciones del juego:

- **`nInitialDriveGears` y `fMass`** están marcados como especiales. Las marchas se aplican junto con `SetVehicleHighGear`. Algunos modelos no notan la masa hasta volver a crear el vehículo.
- **Cambios de motor:** tras tocar `fInitialDriveForce`, `fInitialDriveMaxFlatVel` o `fInitialDragCoeff` se llama a `ModifyVehicleTopSpeed(vehículo, 1.0)` para que se noten sin volver a entrar.
- **`fDownforceModifier`** solo afecta a los modelos que lo usan.
- **Dirección:** los textos sobre subviraje y sobreviraje son **tendencias**, no una simulación. El resultado real depende del resto del handling; pruébalo conduciendo.
- **Otros recursos que tocan el handling:**
  - `jj_things` baja `fBrakeForce` cuando el coche está dañado.
  - `jj_policedispatch` cambia el handling en el modo persecución.
  - Si un coche lleva un perfil de jj_handling, el último en escribir manda. Al restaurar, jj_handling solo deshace lo que cambió él.

## Archivos

```
config.lua             Toda la configuración
shared/parameters.lua  Lista de parámetros, rangos y conversiones
shared/validation.lua  Validación y avisos (la usan servidor y cliente)
shared/utils.lua       Utilidades
server/main.lua        Callbacks, cambios temporales y su caducidad
server/permissions.lua Niveles, talleres y ajustes globales
server/profiles.lua    Perfiles, historial, importar/exportar, instalaciones
server/database.lua    Consultas (perfiles y asignaciones en memoria)
server/logs.lua        Registros en base de datos, consola y Discord
server/security.lua    Control de peticiones y comprobación de vehículos
client/handling.lua    Lectura y escritura con los natives
client/editor.lua      Editor y conexión con la interfaz
client/main.lua        Aplicación automática al conducir
client/workshop.lua    Puntos de taller
web/                   Interfaz (React + Vite)
sql/install.sql        Tablas
```
