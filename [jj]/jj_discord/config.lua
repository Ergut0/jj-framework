Config = {}

-- ID de la aplicación en https://discord.com/developers/applications
-- El nombre de la aplicación es el título que se ve en Discord. Sin ID, se ve como FiveM y sin imágenes
Config.AppId = '1544727769210949713'

-- Nombres de las imágenes subidas en Rich Presence > Art Assets de la aplicación. Vacío para no mostrarlas
Config.LargeImage = ''
Config.LargeImageText = ''
Config.SmallImage = ''
Config.SmallImageText = ''

-- Textos. Valores disponibles: {id}, {players}, {max}, {name} (nombre del personaje) y {job} (nombre del trabajo)
-- {name} y {job} los verá cualquiera que mire el perfil de Discord del jugador
Config.Text = 'ID {id} | {players}/{max} jugadores'
Config.TextBeforeSpawn = 'Eligiendo personaje | {players}/{max} jugadores'

-- Segundos entre actualizaciones
Config.Interval = 30

-- Hasta dos botones. La URL tiene que empezar por https:// o fivem://
Config.Buttons = {
    { label = 'Discord', url = 'https://discord.gg/RbrWHTKvPt' },
    { label = 'Jugar', url = 'cfx.re/join/xllm8le' },
}
