local _isVip = false
local _afkactivedesactive = false
local Helmet = false

function RegisterPersonalMenu()
    RegisterCommand("personalmenu", function(source, args)
        OpenPersonalMenu()
    end)
    RegisterKeyMapping("personalmenu", "Menú Personal", "keyboard", "F10")
end

function OpenPersonalMenu()
    lib.registerMenu({
        id = 'personal_menu',
        title = 'MENÚ PERSONAL',
        position = 'bottom-right',
        options = {
            { icon = "fas fa-id-card", label = "Información Personal",     args = { action = 'infopersonal' } },
            { label = "Interacciones", icon = "fas fa-users",              args = { action = 'interactions' } },
            { icon = "fas fa-tasks",   label = "Menu de Acciones",         args = { action = 'menuaction' } },
            { icon = "fas fa-film",    label = "Rockstar Editor",          args = { action = 'editor' } },
            { icon = "fas fa-gun",     label = "Personalización de Armas", args = { action = 'holster' } },
        }
    }, function(_, _, args)
        local action = args and args.action
        if action == 'infopersonal' then
            OpenInfoPersonalMenu()
        elseif action == 'interactions' then
            OpenInteractionsMenu()
        elseif action == 'menuaction' then
            OpenDeactivateMenu()
        elseif action == 'editor' then
            OpenRockstarEditorMenu()
        elseif action == 'holster' then
            ExecuteCommand("holster")
        end
    end)
    lib.showMenu('personal_menu')
end

--[[function OpenGangMenu()
    local gang = GetGang()
    if not gang then
        Notify("No estás en ninguna banda", "error")
        return
    end

    lib.registerMenu({
        id = 'gang_menu',
        title = 'MI BANDA',
        position = 'bottom-right',
        options = {
            { icon = "fas fa-skull-crossbones", label = "Banda: " .. gang.label },
            { icon = "fas fa-id-badge",         label = "Rango: " .. (gang.rankName or "Sin rango") },
            { icon = "fas fa-users",            label = "Ver mi banda",     description = "Rango y salir de la banda", args = { action = 'mine' } },
            { icon = "fas fa-spray-can",        label = "Pintar grafiti",   description = "Donde apuntas", args = { action = 'graffiti' } },
        },
        onClose = function()
            OpenPersonalMenu()
        end
    }, function(_, _, args)
        local action = args and args.action
        if action == 'mine' then
            ExecuteCommand("banda")
        elseif action == 'graffiti' then
            ExecuteCommand("graffiti")
        end
    end)
    lib.showMenu('gang_menu')
end]]--

function OpenInteractionsMenu()
    lib.registerMenu({
        id = 'interactions_menu',
        title = 'INTERACCIONES',
        position = 'bottom-right',
        options = {
            { icon = "fa-solid fa-car", label = "Meter en vehículo",  args = { action = 'put_in_vehicle' } },
            { icon = "fa-solid fa-car", label = "Sacar del vehículo", args = { action = 'out_of_vehicle' } },
        },
        onClose = function()
            OpenPersonalMenu()
        end
    }, function(selected, _, args)
        if selected == 1 then
            exports['jj_things']:PutInVehicle()
        elseif selected == 2 then
            exports['jj_things']:OutOfVehicle()
        elseif selected == 3 then
            ExecuteCommand("headbag")
        end
    end)
    lib.showMenu('interactions_menu')
end

function OpenInfoPersonalMenu()
    lib.registerMenu({
        id = 'info_personal_menu',
        title = 'INF. PERSONAL',
        position = 'bottom-right',
        options = {
            { icon = "fas fa-hashtag", label = 'ID ' ..  (GetPlayerData().identifier or '') },
            { icon = "fas fa-briefcase", label = "Información Laboral",                    args = { action = 'laboralinfo' } },
            { icon = "fas fa-chart-bar", label = "Estadísticas",                           args = { action = 'stats' } },
            { icon = "fas fa-crown",     label = ("CPS: %s"):format(LocalPlayer.state.cp or 0), args = { action = 'vip' } }
        },
        onClose = function()
            OpenPersonalMenu()
        end
    }, function(selected, _, args)
        if selected == 2 then
            OpenJobInfoMenu()
        elseif selected == 3 then
            OpenStatsMenu()
        end
    end)
    lib.showMenu('info_personal_menu')
end

function OpenDeactivateMenu()
    lib.registerMenu({
        id = 'deactivate_menu',
        title = 'Menu de Acciones',
        position = 'bottom-right',
        options = {
            -- { icon = "fas fa-camera",        label = "Alternar cámara AFK", checked = _afkactivedesactive },
            { icon = "fas fa-helmet-safety", label = "Alternar cascos",     checked = Helmet },
            { icon = "fas fa-user-tie",      label = "Cambiar Peinado",     checked = exports["jj_things"]:SecondHairActive() },
        },
        onCheck = function(selected, checked, args)
            -- if selected == 1 then
            --     ToggleAFKCamera()
            if selected == 1 then
                ToggleHelmet()
            elseif selected == 2 then
                exports["jj_things"]:ChangeHair()
            end
        end,
        onClose = function()
            OpenPersonalMenu()
        end
    }, function(selected, _, args)
    end)
    lib.showMenu('deactivate_menu')
end

function OpenRockstarEditorMenu()
    lib.registerMenu({
        id = 'rockstar_editor_menu',
        title = 'Rockstar Editor',
        position = 'bottom-right',
        options = {
            { icon = "fas fa-video",         label = "Iniciar Grabación",   args = { action = 'start_recording' } },
            { icon = "fas fa-save",          label = "Guardar Grabación",   args = { action = 'save_recording' } },
            { icon = "fas fa-trash",         label = "Descartar Grabación", args = { action = 'discard_recording' } },
            { icon = "fas fa-theater-masks", label = "jj Editor",      args = { action = 'jj_editor' } }
        },
        onClose = function()
            OpenPersonalMenu()
        end
    }, function(selected, _, args)
        if selected == 1 then
            StartRecording(1)
        elseif selected == 2 then
            if IsRecording() then
                StopRecordingAndSaveClip()
            end
        elseif selected == 3 then
            StopRecordingAndDiscardClip()
        elseif selected == 4 then
            ExecuteCommand("jjeditor")
        end
    end)
    lib.showMenu('rockstar_editor_menu')
end

local drugTypes = {
    ['cogollo'] = 'Marihuana',
    ['bolsacoca'] = 'Cocaína',
    ['bolsameta'] = 'Meta',
    ['bolsaextasis'] = 'Éxtasis'
}

function OpenJobInfoMenu()
    local PlayerData = GetPlayerData()
    local gang = GetGang()
    local gangLabel = gang and gang.label or "Ninguna"
    lib.registerMenu({
        id = 'job_info_menu',
        title = 'INFORMACIÓN LABORAL',
        position = 'bottom-right',
        options = {
            { icon = "fas fa-briefcase",        label = "Facción Principal: " .. PlayerData.job.label .. " - " .. PlayerData.job.gradeLabel },
            { icon = "fas fa-skull-crossbones", label = "Facción Ilegal: " .. gangLabel },
        },
        onClose = function()
            OpenInfoPersonalMenu()
        end
    }, function(selected)
    end)
    lib.showMenu('job_info_menu')
end

function OpenStatsMenu()
    if GetResourceState('jj_gym') ~= 'started' then
        Notify("Las estadísticas no están disponibles", "error")
        return
    end

    lib.callback("jj_gym:getStats", false, function(stats)
        local elements = {}
        for _, stat in pairs(stats or {}) do
            elements[#elements + 1] = {
                label = "Resistencia",
                progress = stat.stamina,
            }
            elements[#elements + 1] = {
                label = "Fuerza",
                progress = stat.strength
            }
            elements[#elements + 1] = {
                label = "Yoga",
                progress = stat.yoga
            }
            elements[#elements + 1] = {
                label = "Oxígeno",
                progress = stat.lung
            }
        end
        lib.registerMenu({
            id = 'stats_menu',
            title = 'Estadísticas',
            position = 'bottom-right',
            options = elements,
            onClose = function()
                OpenInfoPersonalMenu()
            end
        }, function(_, _, _)
        end)
        lib.showMenu('stats_menu')
    end)
end

CreateThread(function()
    while true do
        InvalidateIdleCam()
        Wait(10000)
    end
end)

function ToggleHelmet()
    Helmet = not Helmet
    local ped = PlayerPedId()
    if Helmet then
        Notify("Te has quitado la opción para ponerte el casco", "success", 5000)
        SetPedHelmet(ped, false)
        RemovePedHelmet(ped, true)
    else
        Notify("Te has puesto la opción para ponerte el casco", "success", 5000)
        SetPedHelmet(ped, true)
        RemovePedHelmet(ped, false)
    end
end

RegisterPersonalMenu()
