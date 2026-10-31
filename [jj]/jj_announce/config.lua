Config = {}

-- Pueden enviar anuncios quienes tengan el permiso de administración de jj-framework (jj.admin)
Config.Duration = 9000                  -- ms que se muestra cada anuncio
Config.Sound    = true                  -- sonido al recibir un anuncio
Config.MaxLength = 220                  -- longitud maxima del mensaje

-- tipo = { comando, titulo, color }
Config.Types = {
    anuncio       = { command = 'anuncio',       title = 'ANUNCIO',       color = '#a855f7' },
    evento        = { command = 'evento',        title = 'EVENTO',        color = '#4ade80' },
    mantenimiento = { command = 'mantenimiento', title = 'MANTENIMIENTO', color = '#fbbf24' },
    urgente       = { command = 'urgente',       title = 'URGENTE',       color = '#fb7185' },
}
