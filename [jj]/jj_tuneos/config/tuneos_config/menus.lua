Config = Config or {}

Config.Menus = {
        ['empty'] = {
            title = '',
            options = {},
        },
        ['main'] = {
            title = '',
            options = {
                -- {label = 'Reparar', img = 'img/icons/repair.png', price = 0, onSelect = function() repairtVehicle(customVehicle) end},
                {label = 'Visual', img = 'img/icons/visual.png', openSubMenu = 'visual'},
                {label = 'Rendimiento', img = 'img/icons/upgrade.png', openSubMenu = 'upgrade'}
            },
            onBack = function() closeUI(1) end,
            defaultOption = 1
        },
        ['upgrade'] = {
            title = 'RENDIMIENTO',
            options = {
                {label = 'Motor', img = 'img/icons/engine.png', modType = 11, priceMult = 0},
                {label = 'Frenos', img = 'img/icons/brakes.png', modType = 12, priceMult = 0},
                {label = 'Transmisión', img = 'img/icons/transmission.png', modType = 13, priceMult = 0},
                {label = 'Suspensión', img = 'img/icons/suspension.png', modType = 15, priceMult = 0},
                {label = 'Armadura', img = 'img/icons/armor.png', modType = 16, priceMult = 0},
                {label = 'Turbo', img = 'img/icons/engine.png', modType = 18, priceMult = 0},
            },
            onBack = function() updateMenu('main') end
        },
        ['visual'] = {
            title = 'VISUAL',
            options = {
                {label = 'Carrocería', img = 'img/icons/body.png', openSubMenu = 'body_parts'},
                {label = 'Interior', img = 'img/icons/body.png', openSubMenu = 'inside_parts'},
                {label = 'Pintura', img = 'img/icons/respray.png', openSubMenu = 'respray'},
                {label = 'Llantas', img = 'img/icons/wheel.png', openSubMenu = 'wheels', onSelect = function()
                    moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'wheel_lf', {x = -1.8, y = 0.0, z = 0.0}, {x = 0.0, y = 0.0, z = -20.0})
                end},
                {label = 'Matrícula', img = 'img/icons/plate.png', openSubMenu = 'plate'},
                {label = 'Luces', img = 'img/icons/headlights.png', openSubMenu = 'lights'},
                {label = 'Pegatinas', img = 'img/icons/respray.png', openSubMenu = 'stickers'},
                {label = 'Extras', img = 'img/icons/plus.png', modType = 'extras', priceMult = 0},
                {label = 'Tintado de lunas', img = 'img/icons/door.png', modType = 'windowTint', priceMult = 0, onSelect = function()
                    moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'window_lf', {x = -2.0, y = 0.0, z = 0.0}, {x = 0.0, y = 0.0, z = -10.0})
                end, onSubBack = function()
                    SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true)
                end},
                {label = 'Claxon', img = 'img/icons/horn.png', modType = 14, priceMult = 0},
                {label = 'Interior', img = 'img/icons/body.png', modType = 27, priceMult = 0},
                {label = 'Placas', img = 'img/icons/plate.png', modType = 35, priceMult = 0},
                {label = 'Altavoces', img = 'img/icons/speaker.png', modType = 36, priceMult = 0},
                {label = 'Maletero', img = 'img/icons/trunk.png', modType = 37, priceMult = 0, onSelect = function() openDoors(customVehicle, {0,0,0,0,0,1,1}) end},
                {label = 'Hidráulica', img = 'img/icons/hydrulics.png', modType = 38, priceMult = 0},
                {label = 'Bloque motor', img = 'img/icons/engine_block.png', modType = 39, priceMult = 0, onSelect = function() openDoors(customVehicle, {0,0,0,0,1,0,0}) end},
                {label = 'Filtro de aire', img = 'img/icons/air_filter.png', modType = 40, priceMult = 0},
                {label = 'Barras', img = 'img/icons/suspension.png', modType = 41, priceMult = 0},
                {label = 'Depósito', img = 'img/icons/gas_tank.png', modType = 45, priceMult = 0},
            },
            onBack = function() updateMenu('main') end
        },
            ['body_parts'] = {
                title = 'PARTES',
                options = {
                    {label = 'Alerones', img = 'img/icons/spoiler.png', modType = 0, priceMult = 0},
                    {label = 'Paragolpes delantero', img = 'img/icons/bumper.png', modType = 1, priceMult = 0},
                    {label = 'Paragolpes trasero', img = 'img/icons/bumper.png', modType = 2, priceMult = 0, onSelect = function()
                        moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'bumper_r', {x = 0.0, y = -4.0, z = 1.5}, {x = -30.0, y = 0.0, z = 0.0})
                    end, onSubBack = function()
                        SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true)
                    end},
                    {label = 'Faldones', img = 'img/icons/bumper.png', modType = 3, priceMult = 0, onSelect = function()
                        moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'wheel_lf', {x = -2.5, y = 0.0, z = 0.0}, {x = 0.0, y = 0.0, z = -20.0})
                    end, onSubBack = function()
                        SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true)
                    end},
                    {label = 'Tubos de escape', img = 'img/icons/exhaust.png', modType = 4, priceMult = 0, onSelect = function()
                        moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'bumper_r', {x = 0.0, y = -4.0, z = 1.5}, {x = -30.0, y = 0.0, z = 0.0})
                    end, onSubBack = function()
                        SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true)
                    end},
                    {label = 'Caja', img = 'img/icons/body.png', modType = 5, priceMult = 0, onSelect = function()
                        moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'interiorlight', {x = 0.0, y = 1.0, z = -0.1}, {x = 0.0, y = 0.0, z = 0.0})
                    end, onSubBack = function()
                        SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true)
                    end},
                    {label = 'Parrilla', img = 'img/icons/bumper.png', modType = 6, priceMult = 0},
                    {label = 'Capó', img = 'img/icons/hood.png', modType = 7, priceMult = 0},
                    {label = 'Fender izquierdo', img = 'img/icons/bumper.png', modType = 8, priceMult = 0},
                    {label = 'Fender derecho', img = 'img/icons/bumper.png', modType = 9, priceMult = 0},
                    {label = 'Techo', img = 'img/icons/body.png', modType = 10, priceMult = 0},
                    {label = 'Cubierta', img = 'img/icons/bumper.png', modType = 42, priceMult = 0},
                    {label = 'Aerials', img = 'img/icons/bumper.png', modType = 43, priceMult = 0},
                    {label = 'Alerones', img = 'img/icons/bumper.png', modType = 44, priceMult = 0},
                    {label = 'Tintado de lunas', img = 'img/icons/door.png', modType = 46, priceMult = 0},
                },
                onBack = function() updateMenu('visual') end
            },
            ['inside_parts'] = {
                title = 'INTERIOR',
                options = {
                    {label = 'Dash', img = 'img/icons/dashboard.png', modType = 29, priceMult = 0},
                    {label = 'Dial', img = 'img/icons/dashboard.png', modType = 30, priceMult = 0},
                    {label = 'Puerta altavoz', img = 'img/icons/speaker.png', modType = 31, priceMult = 0, onSelect = function() openDoors(customVehicle, {1,1,1,1,0,0,0}) end},
                    {label = 'Asiento', img = 'img/icons/seat.png', modType = 32, priceMult = 0},
                    {label = 'Volante', img = 'img/icons/steering_wheel.png', modType = 33, priceMult = 0},
                    {label = 'Palanca de cambios', img = 'img/icons/shifter_leaver.png', modType = 34, priceMult = 0},
                    {label = 'Ornamentos', img = 'img/icons/visual.png', modType = 28, priceMult = 0},
                },
                onBack = function() updateMenu('visual') end
            },
            ['respray'] = {
                title = 'PINTURA',
                options = {
                    {label = 'Primario', img = 'img/icons/respray.png', modType = 'color1', customType = 'customColor', priceMult = 0, onSelect = function() openColorPicker('Color Primario', 'color1', true, 0.1) end},
                    {label = 'Secundario', img = 'img/icons/respray.png', modType = 'color2', customType = 'customColor', priceMult = 0, onSelect = function() openColorPicker('Color Secundario', 'color2', true, 0.5) end},
                    {label = 'Interior', img = 'img/icons/respray.png', modType = 'interiorColor', customType = 'color', priceMult = 0, onSelect = function() openColorPicker('Color del Interior', 'interiorColor', false, 0.5) end},
                    {label = 'Panel', img = 'img/icons/respray.png', modType = 'dashboardColor', customType = 'color', priceMult = 0, onSelect = function() openColorPicker('Color del Panel', 'dashboardColor', false, 0.5) end},
                    {label = 'Tipo primario', img = 'img/icons/respray.png', modType = 'paintType1', priceMult = 0},
                    {label = 'Tipo secundario', img = 'img/icons/respray.png', modType = 'paintType2', priceMult = 0},
                    {label = 'Aclarado', img = 'img/icons/respray.png', modType = 'pearlescentColor', customType = 'color', priceMult = 0, onSelect = function() openColorPicker('Corlor Perlado', 'pearlescentColor', false, 0.5) end},
                },
                onBack = function() updateMenu('visual') end
            },
            ['wheels'] = {
                title = 'LLANTAS',
                options = {
                    {label = 'Tipo', img = 'img/icons/wheel.png', onSelect = function() updateMenu('wheels_type') end},
                    {label = 'Color', img = 'img/icons/respray.png', modType = 'wheelColor', customType = 'color', priceMult = 0, onSelect = function() openColorPicker('Color de las ruedas', 'wheelColor', false, 0.5) end},
                    {label = 'Humo', img = 'img/icons/respray.png', modType = 'tyreSmokeColor', customType = 'customColor', priceMult = 0, onSelect = function() openColorPicker('Color del humo', 'tyreSmokeColor', true, 0.5) end},
                    {label = 'Neumático personalizado', img = 'img/icons/wheel.png', modType = 55, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'tyress', 0)  end}
        
                },
                onBack = function() updateMenu('visual') SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true) end
            },
                ['wheels_type'] = {
                    title = 'CATEGORIA',
                    options = {
                        {label = 'Sport', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 0) end},
                        {label = 'Muscle ', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 1) end},
                        {label = 'Lowrider', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 2) end},
                        {label = 'SUV', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 3) end},
                        {label = 'Offroad', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 4) end},
                        {label = 'Tuner', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 5) end},
                        {label = 'Bike Wheels', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 6) end},
                        {label = 'High End', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 7) end},
                        {label = 'Bennys', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 8) end},
                        {label = 'A medida', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 9) end},
                        {label = 'Track', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 10) end},
                        {label = 'Street', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 11) end},
                    },
                    onBack = function() updateMenu('wheels') end
                },
            ['plate'] = {
                title = 'MATRICULA',
                options = {
                    {label = 'Tipo', img = 'img/icons/plate.png', modType = 25, priceMult = 0},
                    {label = 'Color', img = 'img/icons/respray.png', modType = 'plateIndex', priceMult = 0, onSelect = function()
                        moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'bumper_r', {x = -2.0, y = -2.0, z = 1.5}, {x = -30.0, y = 0.0, z = 0.0})
                    end, onSubBack = function()
                        SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true)
                    end},
                    {label = 'Portamatrículas', img = 'img/icons/bumper.png', modType = 26, priceMult = 0},
                },
                onBack = function() updateMenu('visual') end
            },
            ['lights'] = {
                title = 'LUCES',
                options = {
                    {label = 'Xenon', img = 'img/icons/headlights.png', modType = 'modXenon', priceMult = 0, onSelect = function() SetVehicleEngineOn(customVehicle, true, false, false) end},
                    {label = 'Neon', img = 'img/icons/headlights.png', modType = 'neonColor', customType = 'customColor', priceMult = 0, onSelect = function() SetVehicleEngineOn(customVehicle, true, false, false) openColorPicker('Color de Neon', 'neonColor', true, 0.5) end},
                },
                onBack = function() updateMenu('visual') end
            },
            ['stickers'] = {
                title = 'PEGATINAS',
                options = {
                    {label = 'Pegatinas', img = 'img/icons/respray.png', modType = 48, priceMult = 0},
                    {label = 'Diseños', img = 'img/icons/respray.png', modType = 'livery', priceMult = 0},
                },
                onBack = function() updateMenu('visual') end
            },
}
Config.Menus2 = {
    ['empty'] = {
        title = '',
        options = {},
    },
    ['main'] = {
        title = '',
        options = {
            --{label = 'Reparar', img = 'img/icons/repair.png', price = 0, onSelect = function() repairtVehicle(customVehicle) end},
            {label = 'Visual', img = 'img/icons/visual.png', openSubMenu = 'visual'},
            {label = 'Rendimiento', img = 'img/icons/upgrade.png', openSubMenu = 'upgrade'}
        },
        onBack = function() closeUI(1) end,
        defaultOption = 1
    },
    ['upgrade'] = {
        title = 'RENDIMIENTO',
        options = {
            {label = 'Motor', img = 'img/icons/engine.png', modType = 11, priceMult = 0},
            {label = 'Frenos', img = 'img/icons/brakes.png', modType = 12, priceMult = 0},
            {label = 'Transmisión', img = 'img/icons/transmission.png', modType = 13, priceMult = 0},
            {label = 'Suspensión', img = 'img/icons/suspension.png', modType = 15, priceMult = 0},
            {label = 'Armadura', img = 'img/icons/armor.png', modType = 16, priceMult = 0},
            {label = 'Turbo', img = 'img/icons/engine.png', modType = 18, priceMult = 0},
        },
        onBack = function() updateMenu('main') end
    },
    ['visual'] = {
        title = 'VISUAL',
        options = {
            {label = 'Carrocería', img = 'img/icons/body.png', openSubMenu = 'body_parts'},
            {label = 'Interior', img = 'img/icons/body.png', openSubMenu = 'inside_parts'},
            {label = 'Pintura', img = 'img/icons/respray.png', openSubMenu = 'respray'},
            {label = 'Llantas', img = 'img/icons/wheel.png', openSubMenu = 'wheels', onSelect = function()
                moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'wheel_lf', {x = -1.8, y = 0.0, z = 0.0}, {x = 0.0, y = 0.0, z = -20.0})
            end},
            {label = 'Matrícula', img = 'img/icons/plate.png', openSubMenu = 'plate'},
            {label = 'Luces', img = 'img/icons/headlights.png', openSubMenu = 'lights'},
            {label = 'Pegatinas', img = 'img/icons/respray.png', openSubMenu = 'stickers'},
            {label = 'Extras', img = 'img/icons/plus.png', modType = 'extras', priceMult = 0},
            {label = 'Tintado de lunas', img = 'img/icons/door.png', modType = 'windowTint', priceMult = 0, onSelect = function()
                moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'window_lf', {x = -2.0, y = 0.0, z = 0.0}, {x = 0.0, y = 0.0, z = -10.0})
            end, onSubBack = function()
                SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true)
            end},
            {label = 'Claxon', img = 'img/icons/horn.png', modType = 14, priceMult = 0},
            {label = 'Interior', img = 'img/icons/body.png', modType = 27, priceMult = 0},
            {label = 'Placas', img = 'img/icons/plate.png', modType = 35, priceMult = 0},
            {label = 'Altavoces', img = 'img/icons/speaker.png', modType = 36, priceMult = 0},
            {label = 'Maletero', img = 'img/icons/trunk.png', modType = 37, priceMult = 0, onSelect = function() openDoors(customVehicle, {0,0,0,0,0,1,1}) end},
            {label = 'Hidráulica', img = 'img/icons/hydrulics.png', modType = 38, priceMult = 0},
            {label = 'Bloque motor', img = 'img/icons/engine_block.png', modType = 39, priceMult = 0, onSelect = function() openDoors(customVehicle, {0,0,0,0,1,0,0}) end},
            {label = 'Filtro de aire', img = 'img/icons/air_filter.png', modType = 40, priceMult = 0},
            {label = 'Barras', img = 'img/icons/suspension.png', modType = 41, priceMult = 0},
            {label = 'Depósito', img = 'img/icons/gas_tank.png', modType = 45, priceMult = 0},
        },
        onBack = function() updateMenu('main') end
    },
        ['body_parts'] = {
            title = 'PARTES',
            options = {
                {label = 'Alerones', img = 'img/icons/spoiler.png', modType = 0, priceMult = 0},
                {label = 'Paragolpes delantero', img = 'img/icons/bumper.png', modType = 1, priceMult = 0},
                {label = 'Paragolpes trasero', img = 'img/icons/bumper.png', modType = 2, priceMult = 0, onSelect = function()
                    moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'bumper_r', {x = 0.0, y = -4.0, z = 1.5}, {x = -30.0, y = 0.0, z = 0.0})
                end, onSubBack = function()
                    SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true)
                end},
                {label = 'Faldones', img = 'img/icons/bumper.png', modType = 3, priceMult = 0, onSelect = function()
                    moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'wheel_lf', {x = -2.5, y = 0.0, z = 0.0}, {x = 0.0, y = 0.0, z = -20.0})
                end, onSubBack = function()
                    SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true)
                end},
                {label = 'Tubos de escape', img = 'img/icons/exhaust.png', modType = 4, priceMult = 0, onSelect = function()
                    moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'bumper_r', {x = 0.0, y = -4.0, z = 1.5}, {x = -30.0, y = 0.0, z = 0.0})
                end, onSubBack = function()
                    SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true)
                end},
                {label = 'Caja', img = 'img/icons/body.png', modType = 5, priceMult = 0, onSelect = function()
                    moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'interiorlight', {x = 0.0, y = 1.0, z = -0.1}, {x = 0.0, y = 0.0, z = 0.0})
                end, onSubBack = function()
                    SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true)
                end},
                {label = 'Parrilla', img = 'img/icons/bumper.png', modType = 6, priceMult = 0},
                {label = 'Capó', img = 'img/icons/hood.png', modType = 7, priceMult = 0},
                {label = 'Fender izquierdo', img = 'img/icons/bumper.png', modType = 8, priceMult = 0},
                {label = 'Fender derecho', img = 'img/icons/bumper.png', modType = 9, priceMult = 0},
                {label = 'Techo', img = 'img/icons/body.png', modType = 10, priceMult = 0},
                {label = 'Cubierta', img = 'img/icons/bumper.png', modType = 42, priceMult = 0},
                {label = 'Aerials', img = 'img/icons/bumper.png', modType = 43, priceMult = 0},
                {label = 'Alerones', img = 'img/icons/bumper.png', modType = 44, priceMult = 0},
                {label = 'Tintado de lunas', img = 'img/icons/door.png', modType = 46, priceMult = 0},
            },
            onBack = function() updateMenu('visual') end
        },
        ['inside_parts'] = {
            title = 'INTERIOR',
            options = {
                {label = 'Dash', img = 'img/icons/dashboard.png', modType = 29, priceMult = 0},
                {label = 'Dial', img = 'img/icons/dashboard.png', modType = 30, priceMult = 0},
                {label = 'Puerta altavoz', img = 'img/icons/speaker.png', modType = 31, priceMult = 0, onSelect = function() openDoors(customVehicle, {1,1,1,1,0,0,0}) end},
                {label = 'Asiento', img = 'img/icons/seat.png', modType = 32, priceMult = 0},
                {label = 'Volante', img = 'img/icons/steering_wheel.png', modType = 33, priceMult = 0},
                {label = 'Palanca de cambios', img = 'img/icons/shifter_leaver.png', modType = 34, priceMult = 0},
                {label = 'Ornamentos', img = 'img/icons/visual.png', modType = 28, priceMult = 0},
            },
            onBack = function() updateMenu('visual') end
        },
        ['respray'] = {
            title = 'PINTURA',
            options = {
                {label = 'Primario', img = 'img/icons/respray.png', modType = 'color1', customType = 'customColor', priceMult = 0, onSelect = function() openColorPicker('Color Primario', 'color1', true, 0.1) end},
                {label = 'Secundario', img = 'img/icons/respray.png', modType = 'color2', customType = 'customColor', priceMult = 0, onSelect = function() openColorPicker('Color Secundario', 'color2', true, 0.5) end},
                {label = 'Interior', img = 'img/icons/respray.png', modType = 'interiorColor', customType = 'color', priceMult = 0, onSelect = function() openColorPicker('Color del Interior', 'interiorColor', false, 0.5) end},
                {label = 'Panel', img = 'img/icons/respray.png', modType = 'dashboardColor', customType = 'color', priceMult = 0, onSelect = function() openColorPicker('Color del Panel', 'dashboardColor', false, 0.5) end},
                {label = 'Tipo primario', img = 'img/icons/respray.png', modType = 'paintType1', priceMult = 0},
                {label = 'Tipo secundario', img = 'img/icons/respray.png', modType = 'paintType2', priceMult = 0},
                {label = 'Aclarado', img = 'img/icons/respray.png', modType = 'pearlescentColor', customType = 'color', priceMult = 0, onSelect = function() openColorPicker('Corlor Perlado', 'pearlescentColor', false, 0.5) end},
            },
            onBack = function() updateMenu('visual') end
        },
        ['wheels'] = {
            title = 'LLANTAS',
            options = {
                {label = 'Tipo', img = 'img/icons/wheel.png', onSelect = function() updateMenu('wheels_type') end},
                {label = 'Color', img = 'img/icons/respray.png', modType = 'wheelColor', customType = 'color', priceMult = 0, onSelect = function() openColorPicker('Color de las ruedas', 'wheelColor', false, 0.5) end},
                {label = 'Humo', img = 'img/icons/respray.png', modType = 'tyreSmokeColor', customType = 'customColor', priceMult = 0, onSelect = function() openColorPicker('Color del humo', 'tyreSmokeColor', true, 0.5) end},
                {label = 'Neumático personalizado', img = 'img/icons/wheel.png', modType = 55, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'tyress', 0)  end}
    
            },
            onBack = function() updateMenu('visual') SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true) end
        },
            ['wheels_type'] = {
                title = 'CATEGORIA',
                options = {
                    {label = 'Sport', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 0) end},
                    {label = 'Muscle ', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 1) end},
                    {label = 'Lowrider', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 2) end},
                    {label = 'SUV', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 3) end},
                    {label = 'Offroad', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 4) end},
                    {label = 'Tuner', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 5) end},
                    {label = 'Bike Wheels', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 6) end},
                    {label = 'High End', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 7) end},
                    {label = 'Bennys', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 8) end},
                    {label = 'A medida', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 9) end},
                    {label = 'Track', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 10) end},
                    {label = 'Street', img = 'img/icons/wheel.png', modType = 23, priceMult = 0, onSelect = function() SetVehicleModData(customVehicle, 'wheels', 11) end},
                },
                onBack = function() updateMenu('wheels') end
            },
        ['plate'] = {
            title = 'MATRICULA',
            options = {
                {label = 'Tipo', img = 'img/icons/plate.png', modType = 25, priceMult = 0},
                {label = 'Color', img = 'img/icons/respray.png', modType = 'plateIndex', priceMult = 0, onSelect = function()
                    moveToCameraToBoneSmoth(customCamMain, customCamSec, customVehicle, 'bumper_r', {x = -2.0, y = -2.0, z = 1.5}, {x = -30.0, y = 0.0, z = 0.0})
                end, onSubBack = function()
                    SetCamActiveWithInterp(customCamMain, customCamSec, 500, true, true)
                end},
                {label = 'Portamatrículas', img = 'img/icons/bumper.png', modType = 26, priceMult = 0},
            },
            onBack = function() updateMenu('visual') end
        },
        ['lights'] = {
            title = 'LUCES',
            options = {
                {label = 'Xenon', img = 'img/icons/headlights.png', modType = 'modXenon', priceMult = 0, onSelect = function() SetVehicleEngineOn(customVehicle, true, false, false) end},
                {label = 'Neon', img = 'img/icons/headlights.png', modType = 'neonColor', customType = 'customColor', priceMult = 0, onSelect = function() SetVehicleEngineOn(customVehicle, true, false, false) openColorPicker('Color de Neon', 'neonColor', true, 0.5) end},
            },
            onBack = function() updateMenu('visual') end
        },
        ['stickers'] = {
            title = 'PEGATINAS',
            options = {
                {label = 'Pegatinas', img = 'img/icons/respray.png', modType = 48, priceMult = 0},
                {label = 'Diseños', img = 'img/icons/respray.png', modType = 'livery', priceMult = 0},
            },
            onBack = function() updateMenu('visual') end
        },
}