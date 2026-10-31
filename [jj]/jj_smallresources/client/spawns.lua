CreateThread(function()
    local RandomVehicles = {
        --Garaje 1
        {pos = vector3(-191.32, 205.12, 85.65), heading = 0.72, Cars = {'italirsx','comet6','tenf','cypher','pariah','xa21'}, spawnName = "Garaje1"},
        {pos = vector3(-171.76, 214.4, 88.29), heading = 180.32, Cars = {'italirsx','comet6','tenf','cypher','pariah','xa21'}, spawnName = "Garaje1"},
        {pos = vector3(-143.52, 210.52, 92.09), heading = 179.16, Cars = {'italirsx','comet6','tenf','cypher','pariah','xa21'}, spawnName = "Garaje1"},
        {pos = vector3(-86.96, 205.28, 94.41), heading = 5.64, Cars = {'italirsx','comet6','tenf','cypher','pariah','xa21'}, spawnName = "Garaje1"},

        --Garaje 3
        {pos = vector3(-1358.88, -19.8, 52.41), heading = 235.28, Cars = {'cognoscenti','schafter4','tailgater2','superd','oracle2','rebla','baller7'}, spawnName = "Garaje3"},
        {pos = vector3(-1387.56, -17.44, 52.49), heading = 142.4, Cars = {'cognoscenti','schafter4','tailgater2','superd','oracle2','rebla','baller7'}, spawnName = "Garaje3"},
        {pos = vector3(-1387.4, 33.96, 52.65), heading = 308.28, Cars = {'cognoscenti','schafter4','tailgater2','superd','oracle2','rebla','baller7'}, spawnName = "Garaje3"},
        {pos = vector3(-1402.04, 46.16, 52.17), heading = 60.12, Cars = {'cognoscenti','schafter4','tailgater2','superd','oracle2','rebla','baller7'}, spawnName = "Garaje3"},
        {pos = vector3(-1391.96, 80.48, 52.93), heading = 307.44, Cars = {'cognoscenti','schafter4','tailgater2','superd','oracle2','rebla','baller7'}, spawnName = "Garaje3"},

        --Garaje 4
        {pos = vector3(-1531.36, -555.56, 24.77), heading = 216.08, Cars = {'toros','jugular','komoda','raiden','drafter','ninef','bestiagts'}, spawnName = "Garaje4"},
        {pos = vector3(-1508.72, -559.16, 24.77), heading = 36.8, Cars = {'toros','jugular','komoda','raiden','drafter','ninef','bestiagts'}, spawnName = "Garaje4"},
        {pos = vector3(-1495.36, -573.68, 22.33), heading = 214.48, Cars = {'toros','jugular','komoda','raiden','drafter','ninef','bestiagts'}, spawnName = "Garaje4"},
        {pos = vector3(-1511.6, -602.68, 22.33), heading = 180.72, Cars = {'toros','jugular','komoda','raiden','drafter','ninef','bestiagts'}, spawnName = "Garaje4"},
        {pos = vector3(-1550.64, -625.08, 22.33), heading = 353.16, Cars = {'toros','jugular','komoda','raiden','drafter','ninef','bestiagts'}, spawnName = "Garaje4"},

        --Garaje 5
        {pos = vector3(-1554.56, -589.8, 24.77), heading = 36.04, Cars = {'elegy','calico','futo2','euros','zr350','remus','rt3000','sultan2'}, spawnName = "Garaje5"},
        {pos = vector3(-1291.16, -241.32, 41.49), heading = 122.92, Cars = {'elegy','calico','futo2','euros','zr350','remus','rt3000','sultan2'}, spawnName = "Garaje5"},
        {pos = vector3(-1279.44, -199.72, 46.09), heading = 302.04, Cars = {'elegy','calico','futo2','euros','zr350','remus','rt3000','sultan2'}, spawnName = "Garaje5"},
        {pos = vector3(-1308.84, -196.4, 46.09), heading = 33.12, Cars = {'elegy','calico','futo2','euros','zr350','remus','rt3000','sultan2'}, spawnName = "Garaje5"},
        {pos = vector3(-1292.92, -237.8, 46.09), heading = 120.6, Cars = {'elegy','calico','futo2','euros','zr350','remus','rt3000','sultan2'}, spawnName = "Garaje5"},
        {pos = vector3(-1302.8, -225.76, 50.61), heading = 305.16, Cars = {'elegy','calico','futo2','euros','zr350','remus','rt3000','sultan2'}, spawnName = "Garaje5"},
        {pos = vector3(-1277.0, -203.0, 50.61), heading = 307.44, Cars = {'elegy','calico','futo2','euros','zr350','remus','rt3000','sultan2'}, spawnName = "Garaje5"},
        {pos = vector3(-1270.0, -251.52, 59.69), heading = 34.64 , Cars = {'elegy','calico','futo2','euros','zr350','remus','rt3000','sultan2'}, spawnName = "Garaje5"},
        {pos = vector3(-1309.12, -196.32, 59.69), heading = 216.6, Cars = {'elegy','calico','futo2','euros','zr350','remus','rt3000','sultan2'}, spawnName = "Garaje5"},

        --Garaje 6
        {pos = vector3(-730.8, -1063.36, 11.37), heading = 32.24, Cars = {'dominator8','gauntlet','ellie','tampa','vigero2','ruiner'}, spawnName = "Garaje6"},
        {pos = vector3(-737.44, -1032.8, 11.77), heading = 299.12, Cars = {'dominator8','gauntlet','ellie','tampa','vigero2','ruiner'}, spawnName = "Garaje6"},
        {pos = vector3(-758.32, -1063.28, 11.01), heading = 210.4, Cars = {'dominator8','gauntlet','ellie','tampa','vigero2','ruiner'}, spawnName = "Garaje6"},
        {pos = vector3(-758.52, -1080.72, 10.85), heading = 29.48, Cars = {'dominator8','gauntlet','ellie','tampa','vigero2','ruiner'}, spawnName = "Garaje6"},
        {pos = vector3(-760.64, -1026.24, 12.17), heading = 301.52, Cars = {'dominator8','gauntlet','ellie','tampa','vigero2','ruiner'}, spawnName = "Garaje6"},

        --Garaje 7
        {pos = vector3(33.12, -1760.32, 28.37), heading = 231.6, Cars = {'blista','asea','primo2','stratum','stanier','intruder','washington'}, spawnName = "Garaje7"},
        {pos = vector3(24.44, -1739.68, 28.37), heading = 230.56, Cars = {'blista','asea','primo2','stratum','stanier','intruder','washington'}, spawnName = "Garaje7"},
        {pos = vector3(-3.6, -1747.68, 28.37), heading = 233.36, Cars = {'blista','asea','primo2','stratum','stanier','intruder','washington'}, spawnName = "Garaje7"},
        {pos = vector3(31.44, -1705.72, 28.33), heading = 25.76, Cars = {'blista','asea','primo2','stratum','stanier','intruder','washington'}, spawnName = "Garaje7"},

        --Garaje 8
        {pos = vector3(-809.84, -768.04, 20.37), heading = 94.12, Cars = {'growler','sm722','corsita','omnisegt','champion','sentinel4','vectre'}, spawnName = "Garaje8"},
        {pos = vector3(-840.76, -764.32, 20.69), heading = 88.88, Cars = {'growler','sm722','corsita','omnisegt','champion','sentinel4','vectre'}, spawnName = "Garaje8"},
        {pos = vector3(-822.52, -757.08, 21.41), heading = 275.64, Cars = {'growler','sm722','corsita','omnisegt','champion','sentinel4','vectre'}, spawnName = "Garaje8"},
    }

    local vehSpawns = {}

    for k, v in pairs(RandomVehicles) do 
        local randomveh = v.Cars[math.random(1, #v.Cars)]
        local success = lib.requestModel(randomveh, 1000)
        if not success then
        end
        vehSpawns[k] = CreateScriptVehicleGenerator(v.pos.x, v.pos.y, v.pos.z, v.heading, 5.0, 3.0, joaat(randomveh), -1, -1, -1, -1, true, false, false, false, true, -1)
        SetScriptVehicleGenerator(vehSpawns[k], true)
        Wait(50)
    end 
    SetAllVehicleGeneratorsActive(true)

    
    AddEventHandler('onResourceStop', function(resource)
        if resource == GetCurrentResourceName() then
             for k, v in pairs(vehSpawns) do
                 if DoesScriptVehicleGeneratorExist(v) then
                     DeleteScriptVehicleGenerator(v)
                 end
             end
        end
     end)

end)
