
CreateThread(function()
    while not LocalPlayer.state['isLoggedIn'] do
        Wait(100)
    end 

    for k, v in pairs(Config.Shops) do
        for _, i in pairs(v.coords) do
            if v.blip ~= false then 
                local blip = AddBlipForCoord(i.x, i.y, i.z) 
                SetBlipSprite(blip, v.blip.id)
                SetBlipScale(blip, v.blip.scale)
                SetBlipColour(blip, v.blip.colour)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentSubstringPlayerName(v.shop.name)
                EndTextCommandSetBlipName(blip)
            end

            lib.requestModel(v.ped)

            local shopPed = CreatePed(1, v.ped, i.x, i.y, i.z-1, i.w, false, true)
            SetEntityInvincible(shopPed, true)
            SetBlockingOfNonTemporaryEvents(shopPed, true)
            FreezeEntityPosition(shopPed, true)
            TaskStartScenarioInPlace(shopPed, "WORLD_HUMAN_STAND_MOBILE", 0, true)


            local shopPoint = lib.points.new({
                coords = vector3(i.x, i.y, i.z),
                distance = 2.0, 
                nearby = function()
                    HelpNotify("Hablar con la persona")
                    if IsControlJustReleased(0, 38) then
                        exports.ox_inventory:openInventory('shop', { type = v.shop.name })
                    end
                end
            })
        end
    end 
end)