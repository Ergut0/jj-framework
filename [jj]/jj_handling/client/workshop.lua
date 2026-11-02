-- Modo taller: dentro de un taller, el mecánico que conduce ve el aviso para abrir el editor.
-- El aviso es solo una ayuda; el servidor vuelve a comprobar trabajo, taller y vehículo
local L = Config.Locales
local shown = false

local function isMechanic()
    local data = JJ.GetPlayerData and JJ.GetPlayerData()
    local job = data and data.job
    if not job then return false end
    local minGrade = Config.MechanicJobs[job.name]
    return minGrade ~= nil and (job.grade or 0) >= minGrade and (not Config.MechanicRequiresDuty or job.onDuty ~= false)
end

local function hide()
    if shown then
        lib.hideTextUI()
        shown = false
    end
end

for _, workshop in ipairs(Config.Workshops) do
    lib.points.new({
        coords = workshop.coords,
        distance = Config.InteractDistance,
        nearby = function()
            local canOpen = cache.vehicle and cache.seat == -1 and not Editor.IsOpen() and isMechanic()
            if not canOpen then return hide() end

            if not shown then
                lib.showTextUI(('%s · %s'):format(L.open_hint, workshop.label))
                shown = true
            end
            if IsControlJustPressed(0, Config.InteractKey) then
                hide()
                CreateThread(Editor.Open)
            end
        end,
        onExit = hide,
    })
end
