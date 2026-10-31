Config = {}

Config.Debug = false

-- Recompensas del carterismo
Config.Pickpocket = {
    MinMoney = 5,
    MaxMoney = 120,
    AggressiveChance = 0.35,    -- probabilidad de que el NPC ataque incluso si el robo tiene éxito
    RewardCooldownSeconds = 60, -- tiempo mínimo entre recompensas por jugador
}

-- Clases de vehículo que permiten meterse en el maletero
Config.TrunkClasses = {
    [0]  = { allowed = true,  x = 0.0, y = -1.5, z = 0.0 },  -- Compacts
    [1]  = { allowed = true,  x = 0.0, y = -2.0, z = 0.0 },  -- Sedans
    [2]  = { allowed = true,  x = 0.0, y = -1.0, z = 0.25 }, -- SUVs
    [3]  = { allowed = true,  x = 0.0, y = -1.5, z = 0.0 },  -- Coupes
    [4]  = { allowed = true,  x = 0.0, y = -2.0, z = 0.0 },  -- Muscle
    [5]  = { allowed = true,  x = 0.0, y = -2.0, z = 0.0 },  -- Sports Classics
    [6]  = { allowed = true,  x = 0.0, y = -2.0, z = 0.0 },  -- Sports
    [7]  = { allowed = true,  x = 0.0, y = -2.0, z = 0.0 },  -- Super
    [8]  = { allowed = false, x = 0.0, y = -1.0, z = 0.25 }, -- Motorcycles
    [9]  = { allowed = true,  x = 0.0, y = -1.0, z = 0.25 }, -- Off-road
    [10] = { allowed = true,  x = 0.0, y = -1.0, z = 0.25 }, -- Industrial
    [11] = { allowed = true,  x = 0.0, y = -1.0, z = 0.25 }, -- Utility
    [12] = { allowed = true,  x = 0.0, y = -1.0, z = 0.25 }, -- Vans
    [13] = { allowed = false, x = 0.0, y = 0.0,  z = 0.0 },  -- Cycles
    [14] = { allowed = false, x = 0.0, y = -1.0, z = 0.25 }, -- Boats
    [15] = { allowed = false, x = 0.0, y = -1.0, z = 0.25 }, -- Helicopters
    [16] = { allowed = false, x = 0.0, y = -1.0, z = 0.25 }, -- Planes
    [17] = { allowed = true,  x = 0.0, y = -1.0, z = 0.25 }, -- Service
    [18] = { allowed = true,  x = 0.0, y = -1.0, z = 0.25 }, -- Emergency
    [19] = { allowed = true,  x = 0.0, y = -1.0, z = 0.25 }, -- Military
    [20] = { allowed = true,  x = 0.0, y = -1.0, z = 0.25 }, -- Commercial
    [21] = { allowed = false, x = 0.0, y = 0.0,  z = 0.0 },  -- Trains
}

-- Jefes que pueden abrir el almacén de su trabajo con jj_things:OpenBossPoliceMenu. El grado mínimo sale de isBoss
Config.BossStashes = { police = true }
-- Almacenes de trabajo abiertos a todos sus empleados
Config.JobStashes = { ambulance = true }

Config.PermsLicenseWeapon = { 19, 20, 21, 22, 23 }

Config.WidescreenWhitelist = {
    ['292689962384490497'] = true, -- jj
    ['622856807773372443'] = true, -- Chucknorris
    ['413091118935179275'] = true, -- Flekos
    ['244941079957209088'] = true, -- barbatron
    ['791412841340338197'] = true, -- rxiny
    ['456582040138153985'] = true, -- basyok
    ['620241256571994122'] = true, -- Suizo
    ['463712654629011457'] = true, -- hrkili90
    ['447424344746885120'] = true, -- minelex
    ['540329692247490571'] = true, -- turronero_52
    ['637422786624749588'] = true, -- sukykazama
    ['1257089012955353240'] = true, -- diego
    ['294858453657059328'] = true, -- neshh
    ['514842479376334886'] = true, -- jorgeborras
    ['1256495221676572733'] = true, -- juanantonio2010444
    ['699575760595320864'] = true, -- victor.l.a
    ['951296445196152882'] = true, -- lo__lamento
    ['1354220256780095579'] = true, -- killerwolf
    ['255325648975953920'] = true, -- alvarito24
    ['1329146271667327124'] = true, -- maikelbarrul29
    ['1336513110672146452'] = true, -- andres111232
    ['470047867621474305'] = true, -- zokar
    ['613901885564256277'] = true, -- bonnie9441
    ['1122967763665813547'] = true, -- groonm 
    ['676185974044098561'] = true, -- Ooscarbg 
    ['834476931326935050'] = true, -- ainh8 
    ['1155517314016477224'] = true, -- alekbakii
    ['1297008038317658134'] = true, -- risasjsa14
    ['698119510695215114'] = true, -- itry.zzz
    ['794106328951160892'] = true, -- annumimius
    ['414487667128926208'] = true, -- Daviiikim
    ['744533628511453185'] = true, -- iacobix
    ['1087375864062296074'] = true, -- proxy141001
    ['762658501109088286'] = true, -- proxy141001
    ['814987190311321630'] = true, -- proxy141001
    ['1471512013904675009'] = true, -- romero
    ['716722411067801642'] = true, -- Lagarto
    ['805773274364641341'] = true, -- Albaizinho
    ['1220872922600575077'] = true, -- Poker
    ['247040935660093440'] = true, -- Core
    ['1123934483155001394'] = true, -- BBVA
    ['451459695308439553'] = true, -- jesusnchz_
    ['1339144058903199766'] = true, -- ruso
    ['603248123774631937'] = true, -- __alex.801__
    ['1164006870860697700'] = true, --roberto.110 
    ['1192051685875515515'] = true, -- Mario 
    ['1521879743472078858'] = true, -- buraco2.0
    ['1430923770847166535'] = true, -- sniperx6
    ['554680266422222878'] = true, -- mirianito32
    ['457957737687416842'] = true, -- patatita_109
    ['1538657022726111363'] = true, -- Ivan
    ['1018283771054788698'] = true, -- joanruiz
    ['418558256840179722'] = true, -- keeviinsaanchez__
    ['553298165223391232'] = true, -- drakkopr
    ['511180721965236256'] = true, -- DonVIci
    ['1231896343547482182'] = true, -- elpeticas
    ['1255984338621829298'] = true, -- kriskobi
    ['664094779310735373'] = true, -- raymon19
    ['1167087822566604810'] = true, -- Jose24_7
    ['1166424087468445776'] = true, -- Adamcinel_
    ['690314125070303293'] = true, -- marvic2010
    ['535364228056612874'] = true, -- iscoh
}

Config.Entornos = {
    ["aviso"] =
    "¡Somos la policía de la LSPD, están ustedes rodeados, si en 2 minutos no se rinden con las manos en alto, abriremos fuego!",
    ["entrar"] =
    "¡De nuevo nos comunicamos con ustedes desde la LSPD, vamos a proceder a entrar en la zona, toda persona que no tenga las manos levantadas será abatido!"
}

Config.PoleDance = {
    ['Enabled'] = false,
    ['Locations'] = {
        { ['Position'] = vector3(104.4169, -1288.2931, 22.0794), ['Number'] = '1' },
    }
}

Config.DoctorIlegal = {
    
    price = 350,

    itemsNeeded = {
    },

    infoDoctor = {
        {
            coords = vector3(-2245.67, 330.23, 156.52), --Destru Crews
            heading = 188.42,
            isLegal = true,
        },
        {
            coords = vector3(1755.75, -1650.35, 112.66), -- Petrolera Burrito
            heading = 259.09,
            isLegal = false,
        },
        {
            coords = vector3(-466.43, 6288.20, 13.61), -- Paleto
            heading = 97.45,
            isLegal = false,
        },
        {
            coords = vector3(2483.95, 3445.86, 51.07), -- Sandy
            heading = 322.14,
            isLegal = false,
        },
        {
            coords = vector3(663.98, 1284.98, 360.30), -- Vinewood Tower
            heading = 94.49,
            isLegal = false,
        },
        {
            coords = vector3(155.76, -2203.39, 4.69), -- 
            heading = 90.49,
            isLegal = false,
        },
        {
            coords = vector3(-2044.84, -1028.20, 2.58), -- Yate Sur
            heading =  167.80,
            isLegal = true,
        },
        {
            coords = vector3(-1389.96, 6745.92, 2.58), -- Yate Norte 
            heading =  167.80,
            isLegal = true,
        },
        {
            coords = vector3(-301.35, -1289.16, 31.25), -- Medico Almacen Mafia
            heading =  326.72,
            isLegal = false,
        },
        -- Evento -- Contenedores
        -- {
        --     coords = vector3(1091.21, -2224.42, 31.30),
        --     heading = 214.57,
        --     needItems = true,
        -- },
        -- {
        --     coords = vector3(1035.22, -2966.28, 5.90),
        --     heading = 7.50,
        --     needItems = true,
        -- },
        -- {
        --     coords = vector3(840.60, 2175.94, 52.29),
        --     heading = 116.63,
        --     needItems = true,
        -- },
        -- {
        --     coords = vector3(-454.55, -2755.90, 6.00),
        --     heading = 339.82,
        --     needItems = true,
        -- },
        -- {
        --     coords = vector3(161.99, -1689.54, 3.07),
        --     heading = 314.12,
        --     needItems = true,
        -- },
        -- {
        --     coords = vector3(442.02, -1671.75, 3.07),
        --     heading = 124.26,
        --     needItems = true,
        -- },
        -- {
        --     coords = vector3(79.82, -1479.11, 3.07),
        --     heading = 356.66,
        --     needItems = true,
        -- },
    }
}

Config.GaragesPersonal = {
    ["license:8bbe2465f8094cc5914685e78ec6ee5cb2c886ab"] = { --  destru  
        spawnPoint = vector4(-2302.53, 4239.43, 42.47, 234.83),
        vehicles = {"volatus","supervolito2","seasparrow","buzzard2" }
    },
    -- ["license:ac951b1e22070042e3ffd85c20dc6c81d18863e0"] = { --  Legend  
    --     spawnPoint = vector4(-1763.95, -1245.36, 2.2, 145.16),
    --     vehicles = {"luxury1"}
    -- },
    ["license:9e205aede9a5a12cf0ded67f476445cfed7ae6e8"] = { -- Carlos
        spawnPoint = vector4(-1574.06, 93.16, 58.6, 313.11),
        vehicles = {"seasparrow","volatus","havok","AW139","ec130" }
    },
    ["license:1aa819c833832071c6041a2dab10019fc49a7229"] = { -- 692853434331824209 - Davidsmate
        spawnPoint = vector4(-773.21, 160.12, 67.47, 230.96),
        vehicles = {"seasparrow","volatus","supervolito2" }
    },
    ["license:37f856680c09c9653457463c10879c2d79858c8c"] = { -- 884035742278500402 - Jotaa
        spawnPoint = vector4(-724.65, -1443.95, 5.00, 139.24),
        vehicles = {"swift2","volatus","havok" }
    },

}
