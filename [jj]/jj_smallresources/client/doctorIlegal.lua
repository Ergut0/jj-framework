
local revivePlayer = function(needItem, index)
    if needItem then
        local haveItems = true
        for k, v in pairs(Config.DoctorIlegal.itemsNeeded) do 
            if exports.ox_inventory:Search('count', v.name) < v.amount then 
                Notify("No tienes suficiente " .. exports.ox_inventory:Items(v.name).label, "error")
                haveItems = false
                break 
            end
        end 
        if not haveItems then return end
    end
    TriggerServerEvent("jj_smallresources:server:doctorRevive", index)
end 

CreateThread(function()
    local success = lib.requestModel("s_m_m_doctor_01")
    if not success then return end

    for k, v in pairs(Config.DoctorIlegal.infoDoctor) do

        local ped = CreatePed(4, "s_m_m_doctor_01", v.coords.x, v.coords.y, v.coords.z, v.heading or 0.0, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetEntityAsMissionEntity(ped, true, true)
        TaskStartScenarioAtPosition(ped, "WORLD_HUMAN_CLIPBOARD", v.coords.x, v.coords.y, v.coords.z, v.heading or 0.0, 0, 0, 1)


        local pedPoints = lib.points.new({
            coords = v.coords,
            distance = 2.0,
            onEnter = function()
                lib.showTextUI('Hablar con el Doctor')
            end,
            nearby = function(self)
                if IsControlJustPressed(0, 38) then
                    revivePlayer(v.needItems, k)
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end
        })

    end 
end)

