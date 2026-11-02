return {
    ['antiinflamatorio'] = {
        label = 'Anti Inflamatorio',
        weight = 115,
        client = {
            anim = { dict = 'mp_suicide', clip = 'pill' },
            prop = { model = 'prop_cs_pills', pos = vec3(0.03, 0.02, 0.0), rot = vec3(20.0, 0.0, -0.0), bone = 64112 },
            disable = { move = false, car = false, combat = true },
            usetime = 2500,
        }
    },

    ['bandage'] = {
        label = 'Vendaje',
        weight = 115,
        client = {
            anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
            prop = { model = 'prop_rolled_sock_02', pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
            disable = { move = true, car = true, combat = true },
            usetime = 2500,
        }
    },

    ['parachute'] = {
        label = 'Paracaidas',
        weight = 8000,
        stack = false,
        client = {
            anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
            usetime = 1500
        }
    },

    ['skateboard'] = {
        label = 'Skateboard',
        weight = 3000,
        stack = false,
        close = true,
        description = 'Monopatin',
    },

    ['panties'] = {
        label = 'Ropa interior',
        weight = 10,
        consume = 0,
        client = {
            status = { thirst = -100000, stress = -25000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_cs_panties_02', pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
            usetime = 2500,
        }
    },


    ['identification'] = {
        label = 'Identificacion',
        client = {
            image = 'card_id.png'
        }
    },


    ["shisha"] = {
        label = "Cachimba",
        weight = 10,
        stack = true,
        close = true,
        description = "Usa la para relajarte y disfrutar de un buen rato con amigos",
        client = {
            image = "shisha.png",
        }
    },


    ["cigarro"] = {
        label = "Cigarro",
        weight = 10,
        stack = true,
        close = true,
        consume = 0.1,
        client = {
            status = { thirst = 0 },
            anim = { dict = 'amb@world_human_aa_smoke@male@idle_a', clip = 'idle_a' },
            prop = { model = 'ng_proc_cigarette01a', pos = vec3(0.0, 0.0, -0.0), rot = vec3(0.0, 0.0, 0.0), bone = 28422 },
            usetime = 7500,
            image = 'cigarro.png',
        },
    },

    ["purohabano"] = {
        label = "Puro habano",
        weight = 10,
        stack = false,
        close = true,
        consume = 0.1,
        client = {
            status = { thirst = 0 },
            anim = { dict = 'amb@world_human_aa_smoke@male@idle_a', clip = 'idle_a' },
            prop = { model = 'ng_proc_cigar01a', pos = vec3(0.0, 0.0, -0.0), rot = vec3(0.0, 0.0, -180.0), bone = 28422 },
            usetime = 7500,
            image = 'purohabano.png',
        },
    },
    -- LB PHONE



    ['phone'] = {
        label = 'Teléfono',
        weight = 190,
        stack = false,
        consume = 0,
        client = {
            add = function(total)
                if total > 0 then
                    pcall(function() return exports.npwd:setPhoneDisabled(false) end)
                end
            end,

            remove = function(total)
                if total < 1 then
                    pcall(function() return exports.npwd:setPhoneDisabled(true) end)
                end
            end
        },
        modelp = 'sf_prop_sf_npc_phone_01a',
    },

    -- Dineros


    ['money'] = {
        label = 'Dinero',
        weight = 0.01,
        modelp = 'sf_prop_sf_cash_pile_01',
    },

    ['fakemoney'] = {
        label = 'Dinero Falso',
        weight = 0.01,
        modelp = 'sf_prop_sf_cash_roll_01a',
    },

    ['black_money'] = {
        label = 'Dinero sin declarar',
        weight = 0.01,
        modelp = 'sf_prop_sf_cash_roll_01a',
    },


    -- COMIDA BASE


    ["hotdogbarato"] = {
        label = "Hotdog",
        weight = 3,
        stack = true,
        close = true,
        degrade = 30,
        decay = true,
        description = "Un hotdog de un puesto ambulante, no tiene buena pinta pero está bueno.",
        client = {
            status = {
                hunger = 90000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_hotdog_02', pos = vec3(0.03, 0.05, -0.01), bone = 58867, rot = vec3(-90.0, 0.0, 45.0) },
            usetime = 3500,
            image = "hotdogbarato.png",
            notification = 'Bofff... me he acabado todo en muy poco tiempo, que bueno estaba.',
        }
    },

    ['mustard'] = {
        label = 'Mostaza',
        weight = 3,
        client = {
            status = { hunger = 25000, thirst = 25000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_food_mustard', pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
            usetime = 2500,
            notification = 'Te... bebiste mostaza'
        },
        modelp = 'prop_food_mustard',
    },
    ['water'] = {
        label = 'Agua',
        weight = 3,
        degrade = 30,
        client = {
            status = { thirst = 90000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'vw_prop_casino_water_bottle_01a', pos = vec3(0.01, 0.01, -0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            cancel = true,
            notification = 'Bebiste agua bien fresquita',
        },
        modelp = 'bbs_water_bottle',
    },
    ['vasodecafe'] = {
        label = 'Vaso de Cafe',
        weight = 3,
        degrade = 30,
        client = {
            status = { thirst = 90000 },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 2500,
            cancel = true,
            notification = 'Un buen cafe fresquito',
        },
        modelp = 'bbs_water_bottle',
    },
    ['burger'] = {
        label = 'Hamburguesa',
        weight = 220,
        degrade = 30,
        client = {
            status = { hunger = 90000 },
            anim = 'eating',
            prop = 'burger',
            usetime = 2500,
            notification = 'You ate a delicious burger'
        },
    },

    ['sprunk'] = {
        label = 'Sprunk',
        weight = 15,
        degrade = 30,
        client = {
            status = { thirst = 90000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            image = 'sprunk.png',
            notification = 'Te quitaste la sed con un Sprunk'
        }
    },

    ['tigrebull'] = {
        label = 'Tigrebull',
        weight = 15,
        degrade = 30,
        client = {
            status = { thirst = 90000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            image = 'tigrebull.png',
            notification = 'Te quitaste la sed con un Sprunk'
        }
    },
    ['cola'] = {
        label = 'Ecola',
        weight = 15,
        degrade = 30,
        client = {
            status = { thirst = 90000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            image = 'cola.png',
        }
    },
    ["snikkel_candy"] = {
        label = "Caramelos Snikkel",
        weight = 15,
        degrade = 30,
        stack = true,
        close = true,
        client = {
            status = { hunger = 90000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_choc_meto', pos = vec3(0.0, -0.0, -0.0), rot = vec3(0, 0.0, -0.0) },
            usetime = 2500,
            image = 'snikkel_candy.png',
        }
    },
    ["beer_ipa"] = {
        label = "Cerveza IPA",
        weight = 15,
        degrade = 30,
        stack = true,
        close = true,
        client = {
            status = { thirst = 90000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'h4_prop_h4_can_beer_01a', pos = vec3(0.01, 0.01, 0.0), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            image = 'beer_IPA.png',
        }
    },
    ["manman_mango"] = {
        label = "Manman Mango",
        weight = 15,
        degrade = 30,
        stack = true,
        close = true,
        client = {
            status = { thirst = 90000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            image = 'manman_mango.png',
        }
    },
    ["manman_coconut"] = {
        label = "Manman Coco",
        weight = 1,
        degrade = 30,
        stack = true,
        close = true,
        client = {
            status = { thirst = 90000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            image = 'manman_coconut.png',
        }
    },
    ["soda_ecola_new"] = {
        label = "Refresco Ecola New",
        weight = 15,
        degrade = 30,
        stack = true,
        close = true,
        client = {
            status = { thirst = 90000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            image = 'Soda_ecola_new.png',
        }
    },
    ["soda_FIZZAZZ"] = {
        label = "Refresco FIZZAZZ",
        weight = 15,
        degrade = 30,
        stack = true,
        close = true,
        client = {
            status = { thirst = 90000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'sf_prop_sf_can_01a', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            image = 'Soda_FIZZAZZ.png',
        }
    },
    ["jesters_original"] = {
        label = "Jesters Original",
        weight = 15,
        stack = true,
        degrade = 30,
        close = true,
        client = {
            status = { hunger = 90000 },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, -0.0, -0.0), rot = vec3(90, 0.0, 40.0) },
            usetime = 2500,
            image = 'Jesters_original.png',
        }
    },
    ["flamingo_classic"] = {
        label = "Flamingo Clasico",
        weight = 15,
        stack = true,
        degrade = 30,
        close = true,
        client = {
            status = { hunger = 90000 },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, -0.0, -0.0), rot = vec3(90, 0.0, 40.0) },
            usetime = 2500,
            image = 'FLAMINGO_Classic.png',
        }
    },
    ["cedda_catfish"] = {
        label = "Cedda Bagre",
        weight = 15,
        stack = true,
        close = true,
        degrade = 30,
        client = {
            status = { hunger = 90000 },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, -0.0, -0.0), rot = vec3(90, 0.0, 40.0) },
            usetime = 2500,
            image = 'cedda_catfish.png',
        }
    },
    ["ricadillos_tortilla"] = {
        label = "Ricadillos Tortilla",
        weight = 1,
        stack = true,
        close = true,
        degrade = 30,
        client = {
            status = { hunger = 90000 },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, -0.0, -0.0), rot = vec3(90, 0.0, 40.0) },
            usetime = 2500,
            image = 'Ricadillos_Tortilla.png',
        }
    },
    ["flamingo_hot"] = {
        label = "Flamingo Picante",
        weight = 15,
        stack = true,
        close = true,
        degrade = 30,
        client = {
            status = { hunger = 90000 },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, -0.0, -0.0), rot = vec3(90, 0.0, 40.0) },
            usetime = 2500,
            image = 'FLAMINGO_hot.png',
        }
    },
    ["twerks_candy"] = {
        label = "Caramelos Twerks",
        weight = 15,
        stack = true,
        close = true,
        degrade = 30,
        client = {
            status = { hunger = 90000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_choc_meto', pos = vec3(0.0, -0.0, -0.0), rot = vec3(0, 0.0, -0.0) },
            usetime = 2500,
            image = 'twerks_candy.png',
        }
    },
    ["tosti"] = {
        label = "Tosti",
        weight = 15,
        stack = true,
        close = true,
        degrade = 30,
        client = {
            status = { hunger = 90000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 2500,
            image = 'tosti.png',
        }
    },



    -- BASICO


    ['carlockpick'] = {
        label = 'Ganzua',
        weight = 150,
        client = { export = "jj_keysystem.lockpickVehicle" }
    },

    ['lockpick'] = {
        label = 'Ganzua',
        weight = 150,
        client = { export = "jj_keysystem.lockpickVehicle" }
    },

    -- JJ-FRAMEWORK: objetos que usan los recursos de jj

    ['weed_bag'] = {
        label = 'Bolsa de marihuana',
        weight = 50,
    },

    ['coke_bag'] = {
        label = 'Bolsa de cocaína',
        weight = 50,
    },

    ['meth_bag'] = {
        label = 'Bolsa de metanfetamina',
        weight = 50,
    },

    ['id_card'] = {
        label = 'DNI',
        weight = 10,
        stack = false,
    },

    ['driver_license'] = {
        label = 'Permiso de conducir',
        weight = 10,
        stack = false,
    },

    ['vehicle_key'] = {
        label = 'Llave de vehículo',
        weight = 10,
        stack = false,
        client = {
            event = 'jj_keysystem:useKey',
        },
    },

    ['croissant_mixto'] = {
        label = 'Croissant mixto',
        weight = 150,
        client = {
            status = { hunger = 200000 },
            anim = 'eating',
            prop = 'burger',
            usetime = 2500,
            notification = 'Te has comido un croissant mixto',
        },
    },

    ['refresco'] = {
        label = 'Refresco',
        weight = 350,
        client = {
            status = { thirst = 200000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            notification = 'Te has bebido un refresco',
        },
    },

    ['armor'] = {
        label = 'Chaleco',
        weight = 3000,
        stack = false,
        client = {
            event = 'consumables:client:UseArmor',
        },
    },

    ['heavyarmor'] = {
        label = 'Chaleco pesado',
        weight = 5000,
        stack = false,
        client = {
            event = 'consumables:client:UseHeavyArmor',
        },
    },

    ['medikit'] = {
        label = 'Botiquín',
        weight = 500,
    },

    ['detector'] = {
        label = 'Detector de huellas',
        weight = 300,
        stack = false,
        client = {
            event = 'detector:use',
        },
    },

    ['handcuffs'] = {
        label = 'Esposas',
        weight = 200,
        client = {
            export = 'jj_things.useHandcuffs',
        },
    },

    ['police_cad'] = {
        label = 'Tablet policial',
        weight = 500,
        stack = false,
        client = {
            export = 'jj_policetablet.useCad',
        },
    },

    ['lspd_badge'] = {
        label = 'Placa de policía',
        weight = 50,
        stack = false,
        client = {
            event = 'jj_policejob:client:showBadge',
        },
    },

    ['prop_mp_cone_02'] = {
        label = 'Cono',
        weight = 1000,
        client = {
            export = 'jj_policejob.spawnProp',
        },
    },

    ['prop_barrier_work05'] = {
        label = 'Barrera de obras',
        weight = 1000,
        client = {
            export = 'jj_policejob.spawnProp',
        },
    },

    ['prop_parking_sign_1'] = {
        label = 'Señal de aparcamiento',
        weight = 1000,
        client = {
            export = 'jj_policejob.spawnProp',
        },
    },

    ['prop_mp_barrier_02b'] = {
        label = 'Barrera policial',
        weight = 1000,
        client = {
            export = 'jj_policejob.spawnProp',
        },
    },

    ['prop_air_conelight'] = {
        label = 'Cono luminoso',
        weight = 1000,
        client = {
            export = 'jj_policejob.spawnProp',
        },
    },

    ['llave_negra'] = {
        label = 'Llave de esposas',
        weight = 20,
        client = {
            export = 'jj_things.useUncuff',
        },
    },

    ['advancedlockpick'] = {
        label = 'Ganzua Avanzada',
        weight = 150,
    },

    ['radio'] = {
        label = 'Radio',
        weight = 1000,
        stack = false,
        close = true,
        allowArmed = true,
        description = 'Una radio para hablar por cualquier frecuencia.',
        client = {
            export = 'jj_radio.openRadio'
        }
    },
    ['armour'] = {
        label = 'Chaleco antibalas',
        weight = 3000,
        stack = false,
        client = {
            anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
            usetime = 3500,
        },
        modelp = "prop_armour_pickup",
    },

    ['heavyarmour'] = {
        label = 'Armadura pesada',
        weight = 4500,
        stack = false,
        client = {
            anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
            usetime = 3500,
        },
        modelp = "prop_bodyarmour_03",
    },


    ['armor_plates'] = {
        label = 'Placas de armadura',
        weight = 800,
        stack = true,
        close = true,
        consume = 1,
        client = {
            event = 'ox_inventory:utility:applyArmorPlate',
        },
        modelp = "p_cs_laptop_02_w",
    },

    ['armor_repair_kit'] = {
        label = 'Kit de reparación de armadura',
        weight = 1200,
        stack = true,
        close = true,
        client = {
            event = 'ox_inventory:utility:applyArmorPlate',
        },
        modelp = "p_cs_laptop_02_w",
    },

    ['clothing'] = {
        label = 'Ropa',
        consume = 0,
    },

    ['mastercard'] = {
        label = 'Tarjeta Fleeca',
        stack = false,
        weight = 10,
        client = {
            image = 'card_bank.png'
        }
    },

    -- ================== PUG FISHING ===============================

    ["largemouthbass"] = {
        label = "Perca americana",
        weight = 300,
        stack = true,
        close = true,
        description = "Fish for Fishing.",
        client = {
            image = "largemouthbass.png",
        },
        name = "largemouthbass",
        type = "item",
        image = "largemouthbass.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["item_bench"] = {
        label = "Banco de trabajo",
        weight = 1500,
        stack = false,
        close = true,
        description = "A workbench to craft items.",
        client = {
            image = "item_bench.png",
        },
        name = "item_bench",
        type = "item",
        image = "item_bench.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishingnet"] = {
        label = "Red de pesca",
        weight = 500,
        stack = false,
        close = true,
        description = "A net used for catching fish!",
        client = {
            image = "fishingnet.png",
        },
        name = "fishingnet",
        type = "item",
        image = "fishingnet.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["emerald"] = {
        label = "Esmeralda",
        weight = 300,
        stack = true,
        close = true,
        description = "Emerald",
        client = {
            image = "emerald.png",
        },
        name = "emerald",
        type = "item",
        image = "emerald.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["chestkey"] = {
        label = "Llave",
        weight = 100,
        stack = true,
        close = true,
        description = "A gold key.",
        client = {
            image = "chestkey.png",
        },
        name = "chestkey",
        type = "item",
        image = "chestkey.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["rainbowtrout"] = {
        label = "Trucha arcoiris",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for rainbowtrout",
        client = {
            image = "rainbowtrout.png",
        },
        name = "rainbowtrout",
        type = "item",
        image = "rainbowtrout.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["stripedbass"] = {
        label = "Lubina rayada",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for stripedbass",
        client = {
            image = "stripedbass.png",
        },
        name = "stripedbass",
        type = "item",
        image = "stripedbass.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["catfish"] = {
        label = "Bagre",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for catfish",
        client = {
            image = "catfish.png",
        },
        name = "catfish",
        type = "item",
        image = "catfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["swordfish"] = {
        label = "Pez espada",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for swordfish",
        client = {
            image = "swordfish.png",
        },
        name = "swordfish",
        type = "item",
        image = "swordfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["cookedfish"] = {
        label = "Pescado cocinado",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for cookedfish",
        client = {
            image = "cookedfish.png",
        },
        name = "cookedfish",
        type = "item",
        image = "cookedfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishingrod3"] = {
        label = "Caña de pescar 3",
        weight = 100,
        stack = false,
        close = true,
        description = "Description for fishingrod3",
        client = {
            image = "fishingrod3.png",
        },
        name = "fishingrod3",
        type = "item",
        image = "fishingrod3.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fish"] = {
        label = "Pescado",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for fish",
        client = {
            image = "fish.png",
        },
        name = "fish",
        type = "item",
        image = "fish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["treasuremap"] = {
        label = "Mapa del tesoro",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for treasuremap",
        client = {
            image = "treasuremap.png",
        },
        name = "treasuremap",
        type = "item",
        image = "treasuremap.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["ruby"] = {
        label = "Rubi",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for ruby",
        client = {
            image = "ruby.png",
        },
        name = "ruby",
        type = "item",
        image = "ruby.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishingbait"] = {
        label = "Cebo de pesca",
        weight = 1,
        stack = true,
        close = true,
        description = "Description for fishingbait",
        client = {
            image = "fishingbait.png",
        },
        name = "fishingbait",
        type = "item",
        image = "fishingbait.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["treasurechest"] = {
        label = "Cofre del tesoro",
        weight = 10,
        stack = true,
        close = true,
        description = "Description for treasurechest",
        client = {
            image = "treasurechest.png",
        },
        name = "treasurechest",
        type = "item",
        image = "treasurechest.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["attachment_bench"] = {
        label = "Banco de accesorios",
        weight = 100,
        stack = false,
        close = true,
        description = "Description for attachment_bench",
        client = {
            image = "attachment_bench.png",
        },
        name = "attachment_bench",
        type = "item",
        image = "attachment_bench.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishinglure"] = {
        label = "Señuelo de pesca",
        weight = 10,
        stack = false,
        close = true,
        description = "Description for fishinglure",
        client = {
            image = "fishinglure.png",
        },
        name = "fishinglure",
        type = "item",
        image = "fishinglure.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["perfectlycookedfish"] = {
        label = "Pescado perfectamente cocinado",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for perfectlycookedfish",
        client = {
            image = "perfectlycookedfish.png",
        },
        name = "perfectlycookedfish",
        type = "item",
        image = "perfectlycookedfish.png",
        unique = false,
        useable = false,
        shouldClose = true,
        combinable = nil,
    },
    ["salmon"] = {
        label = "Salmon",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for salmon",
        client = {
            image = "salmon.png",
        },
        name = "salmon",
        type = "item",
        image = "salmon.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["tunafish"] = {
        label = "Atun",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for tunafish",
        client = {
            image = "tunafish.png",
        },
        name = "tunafish",
        type = "item",
        image = "tunafish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["tigershark"] = {
        label = "Tiburon tigre",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for tigershark",
        client = {
            image = "tigershark.png",
        },
        name = "tigershark",
        type = "item",
        image = "tigershark.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishinglure2"] = {
        label = "Señuelo de pesca 2",
        weight = 10,
        stack = false,
        close = true,
        description = "Description for fishinglure2",
        client = {
            image = "fishinglure2.png",
        },
        name = "fishinglure2",
        type = "item",
        image = "fishinglure2.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["codfish"] = {
        label = "Bacalao",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for codfish",
        client = {
            image = "codfish.png",
        },
        name = "codfish",
        type = "item",
        image = "codfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["eelfish"] = {
        label = "Anguila",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for eelfish",
        client = {
            image = "eelfish.png",
        },
        name = "eelfish",
        type = "item",
        image = "eelfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["skillreel"] = {
        label = "Carrete experto",
        weight = 100,
        stack = false,
        close = true,
        description = "Description for skillreel",
        client = {
            image = "skillreel.png",
        },
        name = "skillreel",
        type = "item",
        image = "skillreel.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishingfireplace"] = {
        label = "Fogon de pesca",
        weight = 100,
        stack = false,
        close = true,
        description = "Description for fishingfireplace",
        client = {
            image = "fishingfireplace.png",
        },
        name = "fishingfireplace",
        type = "item",
        image = "fishingfireplace.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["yellowdiamond"] = {
        label = "Diamante amarillo",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for yellowdiamond",
        client = {
            image = "yellowdiamond.png",
        },
        name = "yellowdiamond",
        type = "item",
        image = "yellowdiamond.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishingshovel"] = {
        label = "Pala de pesca",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for fishingshovel",
        client = {
            image = "fishingshovel.png",
        },
        name = "fishingshovel",
        type = "item",
        image = "fishingshovel.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["proreel"] = {
        label = "Carrete profesional",
        weight = 100,
        stack = false,
        close = true,
        description = "Description for proreel",
        client = {
            image = "proreel.png",
        },
        name = "proreel",
        type = "item",
        image = "proreel.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["goldfish"] = {
        label = "Pez dorado",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for goldfish",
        client = {
            image = "goldfish.png",
        },
        name = "goldfish",
        type = "item",
        image = "goldfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["redfish"] = {
        label = "Pez rojo",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for redfish",
        client = {
            image = "redfish.png",
        },
        name = "redfish",
        type = "item",
        image = "redfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["captainskull"] = {
        label = "Calavera del capitan",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for captainskull",
        client = {
            image = "captainskull.png",
        },
        name = "captainskull",
        type = "item",
        image = "captainskull.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishingrod2"] = {
        label = "Caña de pescar 2",
        weight = 100,
        stack = false,
        close = true,
        description = "Description for fishingrod2",
        client = {
            image = "fishingrod2.png",
        },
        name = "fishingrod2",
        type = "item",
        image = "fishingrod2.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["killerwhale"] = {
        label = "Orca",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for killerwhale",
        client = {
            image = "killerwhale.png",
        },
        name = "killerwhale",
        type = "item",
        image = "killerwhale.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["sapphire"] = {
        label = "Zafiro",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for sapphire",
        client = {
            image = "sapphire.png",
        },
        name = "sapphire",
        type = "item",
        image = "sapphire.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["bottlemap"] = {
        label = "Mapa en botella",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for bottlemap",
        client = {
            image = "bottlemap.png",
        },
        name = "bottlemap",
        type = "item",
        image = "bottlemap.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishingtrowl"] = {
        label = "Rastra de pesca",
        weight = 100,
        stack = false,
        close = true,
        --       consume = 0.034,
        description = "Description for fishingtrowl",
        client = {
            image = "fishingtrowl.png",
        },
        name = "fishingtrowl",
        type = "item",
        image = "fishingtrowl.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["gholfish"] = {
        label = "Pez fantasma",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for gholfish",
        client = {
            image = "gholfish.png",
        },
        name = "gholfish",
        type = "item",
        image = "gholfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishingrod"] = {
        label = "Caña de pescar",
        weight = 100,
        stack = false,
        close = true,
        description = "Description for fishingrod",
        client = {
            image = "fishingrod.png",
        },
        name = "fishingrod",
        type = "item",
        image = "fishingrod.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["stingraymeat"] = {
        label = "Carne de raya",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for stingraymeat",
        client = {
            image = "stingraymeat.png",
        },
        name = "stingraymeat",
        type = "item",
        image = "stingraymeat.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["bluefish"] = {
        label = "Pez azul",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for bluefish",
        client = {
            image = "bluefish.png",
        },
        name = "bluefish",
        type = "item",
        image = "bluefish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishinganchor"] = {
        label = "Ancla de pesca",
        weight = 100,
        stack = false,
        close = true,
        description = "Description for fishinganchor",
        client = {
            image = "fishinganchor.png",
        },
        name = "fishinganchor",
        type = "item",
        image = "fishinganchor.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["sockeyesalmon"] = {
        label = "Salmon rojo",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for sockeyesalmon",
        client = {
            image = "sockeyesalmon.png",
        },
        name = "sockeyesalmon",
        type = "item",
        image = "sockeyesalmon.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["rockfish"] = {
        label = "Pez roca",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for rockfish",
        client = {
            image = "rockfish.png",
        },
        name = "rockfish",
        type = "item",
        image = "rockfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["flyfish"] = {
        label = "Pez volador",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for flyfish",
        client = {
            image = "flyfish.png",
        },
        name = "flyfish",
        type = "item",
        image = "flyfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["tarponfish"] = {
        label = "Tarpon",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for tarponfish",
        client = {
            image = "tarponfish.png",
        },
        name = "tarponfish",
        type = "item",
        image = "tarponfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishinghalibut"] = {
        label = "Fletan de pesca",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for fishinghalibut",
        client = {
            image = "fishinghalibut.png",
        },
        name = "fishinghalibut",
        type = "item",
        image = "fishinghalibut.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["anglerfish"] = {
        label = "Rape",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for anglerfish",
        client = {
            image = "anglerfish.png",
        },
        name = "anglerfish",
        type = "item",
        image = "anglerfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["kingsalmon"] = {
        label = "Salmon real",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for kingsalmon",
        client = {
            image = "kingsalmon.png",
        },
        name = "kingsalmon",
        type = "item",
        image = "kingsalmon.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["mahimahi"] = {
        label = "Dorado",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for mahimahi",
        client = {
            image = "mahimahi.png",
        },
        name = "mahimahi",
        type = "item",
        image = "mahimahi.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["crawfish"] = {
        label = "Cangrejo de rio",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for crawfish",
        client = {
            image = "crawfish.png",
        },
        name = "crawfish",
        type = "item",
        image = "crawfish.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["oceansturgeon"] = {
        label = "Esturion oceanico",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for oceansturgeon",
        client = {
            image = "oceansturgeon.png",
        },
        name = "oceansturgeon",
        type = "item",
        image = "oceansturgeon.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishinglog"] = {
        label = "Registro de pesca",
        weight = 100,
        stack = false,
        close = true,
        description = "Description for fishinglog",
        client = {
            image = "fishinglog.png",
        },
        name = "fishinglog",
        type = "item",
        image = "fishinglog.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["fishingcrabtrap"] = {
        label = "Trampa para cangrejos",
        weight = 100,
        stack = false,
        close = true,
        description = "Description for fishingcrabtrap",
        client = {
            image = "fishingcrabtrap.png",
        },
        name = "fishingcrabtrap",
        type = "item",
        image = "fishingcrabtrap.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["bluecrab"] = {
        label = "Cangrejo azul",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for bluecrab",
        client = {
            image = "bluecrab.png",
        },
        name = "bluecrab",
        type = "item",
        image = "bluecrab.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["dungenesscrab"] = {
        label = "Cangrejo Dungeness",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for dungenesscrab",
        client = {
            image = "dungenesscrab.png",
        },
        name = "dungenesscrab",
        type = "item",
        image = "dungenesscrab.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["rockcrab"] = {
        label = "Cangrejo roca",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for rockcrab",
        client = {
            image = "rockcrab.png",
        },
        name = "rockcrab",
        type = "item",
        image = "rockcrab.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["redcrab"] = {
        label = "Cangrejo rojo",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for redcrab",
        client = {
            image = "redcrab.png",
        },
        name = "redcrab",
        type = "item",
        image = "redcrab.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["snowcrab"] = {
        label = "Cangrejo de nieve",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for snowcrab",
        client = {
            image = "snowcrab.png",
        },
        name = "snowcrab",
        type = "item",
        image = "snowcrab.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },
    ["cookedcrab"] = {
        label = "Cangrejo cocinado",
        weight = 100,
        stack = true,
        close = true,
        description = "Description for cookedcrab",
        client = {
            image = "cookedcrab.png",
        },
        name = "cookedcrab",
        type = "item",
        image = "cookedcrab.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
    },


    -- ================== RX HUNTING ================================


    ["hunting_trophie"] = {
        label = "Trofeo de caza",
        weight = 15,
        description = "Un trofeo por la caza de mas de 10 coyotes en menos de una hora.",
        stack = true,
        close = true
    },


    ["hunting_medal"] = {
        label = "Medalla de caza",
        weight = 15,
        description = "Un trofeo por la caza de mas de 10 pumas en menos de una hora.",
        stack = true,
        close = true
    },


    ["book_hunting"] = {
        label = "Manual de caza",
        weight = 1,
        stack = true,
        close = true
    },


    ["book_hunting2"] = {
        label = "Manual de caza Vol2",
        weight = 1,
        stack = true,
        close = true
    },


    ['bone_fragments'] = {
        label = 'Fragmentos de hueso',
        weight = 2,
        stack = true,
        close = true,
        description = nil
    },
    ['cloth'] = {
        label = 'Tela',
        weight = 3,
        stack = true,
        close = true,
        description = nil
    },
    ['leather'] = {
        label = 'Cuero',
        weight = 3,
        stack = true,
        close = true,
        description = nil
    },
    ['raw_pork'] = {
        label = 'Cerdo crudo',
        weight = 2,
        stack = true,
        close = true,
        description = nil
    },
    ['animal_fat'] = {
        label = 'Grasa animal',
        weight = 2,
        stack = true,
        close = true,
        description = nil
    },
    ['meat_stand'] = {
        label = 'Cebo de carne',
        weight = 10,
        stack = false,
        close = true,
        description = nil
    },
    ['deer'] = {
        label = 'Señuelo ciervo',
        weight = 10,
        stack = false,
        close = true,
        description = nil
    },
    ['boar_meat'] = {
        label = 'Señuelo jabali',
        weight = 10,
        stack = false,
        close = true,
        description = nil
    },
    ['deer_horn'] = {
        label = 'Silbato de ciervo',
        weight = 5,
        stack = false,
        close = true,
        description = nil
    },


    -- ===========================HOOKAH=============================
    -- INGREDIENTES GENÉRICOS
    -- CARNES Y PRODUCTOS CRUDOS
    -- PESCADO / MARISCO / PRODUCTOS DEL MAR
    -- ===========================HOOKAH=============================

    ['beef'] = {
        label = 'Carne de vacuno',
        weight = 1,
        stack = true,
        close = false,
        description = 'Una porcion de carne de vacuno lista para cocinar en distintas recetas.'
    },

    ['egg'] = {
        label = 'Huevo',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un ingrediente fresco y versatil usado en muchas preparaciones.'
    },

    ['spiceskit'] = {
        label = 'Kit de especias',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un surtido de especias para dar mas sabor a cualquier plato.'
    },
    ['cocktail_pack'] = {
        label = 'Kit de cócteles',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un surtido de ingredientes para preparar cócteles deliciosos.'
    },

    ['sauceskit'] = {
        label = 'Kit de salsas',
        weight = 1,
        stack = true,
        close = false,
        description = 'Una seleccion de salsas para acompanar y mejorar tus recetas.'
    },

    ['icecubes'] = {
        label = 'Cubitos de hielo',
        weight = 1,
        stack = true,
        close = false,
        description = 'Cubitos de hielo ideales para enfriar bebidas y preparaciones.'
    },

    ['strawberries'] = {
        label = 'Fresas',
        weight = 1,
        stack = true,
        close = false,
        description = 'Fresas frescas y dulces perfectas para postres o bebidas.'
    },

    ['tomatoslices'] = {
        label = 'Rodajas de tomate',
        weight = 1,
        stack = true,
        close = false,
        description = 'Rodajas de tomate listas para usar en hamburguesas, ensaladas o bocadillos.'
    },

    ['apples'] = {
        label = 'Manzanas',
        weight = 1,
        stack = true,
        close = false,
        description = 'Manzanas frescas listas para comer o usar en recetas.'
    },

    ['mincedmeat'] = {
        label = 'Carne picada',
        weight = 1,
        stack = true,
        close = false,
        description = 'Carne condimentada preparada para elaborar salchichas, hamburgesas... o recetas similares.'
    },

    ['fish_raw'] = {
        label = 'Pescado crudo',
        weight = 300,
        stack = true,
        close = true,
        description = 'Pescado fresco sin cocinar.'
    },

    ['fish_cooked'] = {
        label = 'Pescado cocinado',
        weight = 300,
        stack = true,
        close = true,
        description = 'Pescado cocinado listo para consumir o preparar platos.'
    },

    ['fish_fillet'] = {
        label = 'Filete de pescado',
        weight = 200,
        stack = true,
        close = true,
        description = 'Filete de pescado preparado para cocinar.'
    },

    ['salmon_raw'] = {
        label = 'Salmón crudo',
        weight = 300,
        stack = true,
        close = true,
        description = 'Salmón fresco sin cocinar.'
    },

    ['salmon_cooked'] = {
        label = 'Salmón cocinado',
        weight = 300,
        stack = true,
        close = true,
        description = 'Salmón cocinado listo para preparar platos.'
    },

    ['tuna_raw'] = {
        label = 'Atún crudo',
        weight = 300,
        stack = true,
        close = true,
        description = 'Atún fresco sin cocinar.'
    },

    ['tuna_cooked'] = {
        label = 'Atún cocinado',
        weight = 300,
        stack = true,
        close = true,
        description = 'Atún cocinado listo para preparar platos.'
    },

    ['shrimp_raw'] = {
        label = 'Gambas crudas',
        weight = 200,
        stack = true,
        close = true,
        description = 'Gambas frescas sin cocinar.'
    },

    ['shrimp_cooked'] = {
        label = 'Gambas cocinadas',
        weight = 200,
        stack = true,
        close = true,
        description = 'Gambas cocinadas listas para consumir.'
    },

    ['crab_raw'] = {
        label = 'Cangrejo crudo',
        weight = 350,
        stack = true,
        close = true,
        description = 'Cangrejo fresco sin cocinar.'
    },

    ['crab_cooked'] = {
        label = 'Cangrejo cocinado',
        weight = 350,
        stack = true,
        close = true,
        description = 'Cangrejo cocinado listo para preparar platos.'
    },

    ['lobster_raw'] = {
        label = 'Langosta cruda',
        weight = 500,
        stack = true,
        close = true,
        description = 'Langosta fresca sin cocinar.'
    },

    ['lobster_cooked'] = {
        label = 'Langosta cocinada',
        weight = 500,
        stack = true,
        close = true,
        description = 'Langosta cocinada de alta calidad.'
    },

    ['squid_raw'] = {
        label = 'Calamar crudo',
        weight = 250,
        stack = true,
        close = true,
        description = 'Calamar fresco sin cocinar.'
    },

    ['squid_cooked'] = {
        label = 'Calamar cocinado',
        weight = 250,
        stack = true,
        close = true,
        description = 'Calamar cocinado listo para preparar platos.'
    },

    ['octopus_raw'] = {
        label = 'Pulpo crudo',
        weight = 350,
        stack = true,
        close = true,
        description = 'Pulpo fresco sin cocinar.'
    },

    ['octopus_cooked'] = {
        label = 'Pulpo cocinado',
        weight = 350,
        stack = true,
        close = true,
        description = 'Pulpo cocinado listo para consumir.'
    },

    ['seafood_mix_raw'] = {
        label = 'Marisco crudo',
        weight = 300,
        stack = true,
        close = true,
        description = 'Mezcla de marisco crudo.'
    },

    ['seafood_mix_cooked'] = {
        label = 'Marisco cocinado',
        weight = 300,
        stack = true,
        close = true,
        description = 'Mezcla de marisco cocinado.'
    },

    ['seaweed'] = {
        label = 'Alga marina',
        weight = 50,
        stack = true,
        close = true,
        description = 'Alga marina utilizada para preparar platos.'
    },

    ['rice'] = {
        label = 'Arroz',
        weight = 150,
        stack = true,
        close = true,
        description = 'Arroz utilizado como base para varios platos.'
    },

    ['soy_sauce'] = {
        label = 'Salsa de soja',
        weight = 100,
        stack = true,
        close = true,
        description = 'Salsa utilizada para acompañar platos asiáticos.'
    },

    ['lemon'] = {
        label = 'Limón',
        weight = 80,
        stack = true,
        close = true,
        description = 'Limón utilizado para cocinar o acompañar platos.'
    },



    ['bread'] = {
        label = 'Pan',
        weight = 100,
        stack = true,
        close = true,
        description = 'Pan utilizado para preparar hamburguesas y bocadillos.'
    },

    ['toasted_bread'] = {
        label = 'Pan tostado',
        weight = 100,
        stack = true,
        close = true,
        description = 'Pan tostado listo para preparar comida.'
    },

    ['lettuce_raw'] = {
        label = 'Lechuga sin cortar',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lechuga fresca sin preparar.'
    },

    ['lettuce'] = {
        label = 'Lechuga',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lechuga limpia y cortada.'
    },

    ['cheese_block'] = {
        label = 'Bloque de queso',
        weight = 300,
        stack = true,
        close = true,
        description = 'Bloque de queso para cortar en porciones.'
    },

    ['cheese'] = {
        label = 'Queso',
        weight = 100,
        stack = true,
        close = true,
        description = 'Porción de queso lista para usar.'
    },

    ['oil'] = {
        label = 'Aceite',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un ingrediente basico ideal para cocinar y preparar todo tipo de recetas.'
    },

    ['corn'] = {
        label = 'Maiz',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un ingrediente versatil que puede usarse en distintas elaboraciones.'
    },

    ['butter'] = {
        label = 'Mantequilla',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un ingrediente cremoso perfecto para cocinar, untar o dar sabor.'
    },

    ['ham'] = {
        label = 'Jamon',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un ingrediente sabroso ideal para bocadillos, tapas y distintas recetas.'
    },

    ['garlic'] = {
        label = 'Ajo',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un ingrediente aromatico muy usado para dar sabor a todo tipo de platos.'
    },


    ['lamb_raw'] = {
        label = 'Cordero crudo',
        weight = 1,
        stack = true,
        close = false,
        description = 'Una porcion de cordero crudo lista para cocinar en distintas recetas.'
    },

    ['lamb_cooked'] = {
        label = 'Cordero cocinado',
        weight = 1,
        stack = true,
        close = false,
        description = 'Una porcion de cordero ya cocinada, lista para servir o acompanar otros platos.'
    },

    ['orange'] = {
        label = 'Naranja',
        weight = 1,
        stack = true,
        close = false,
        description = 'Una fruta fresca y jugosa ideal para comer sola o usar en bebidas y recetas.'
    },

    ['pork_raw'] = {
        label = 'Carne de cerdo cruda',
        weight = 1,
        stack = true,
        close = false,
        description = 'Una pieza de carne de cerdo lista para cocinar en distintas preparaciones.'
    },

    ['pork_cooked'] = {
        label = 'Carne de cerdo cocinada',
        weight = 1,
        stack = true,
        close = false,
        description = 'Carne de cerdo ya cocinada, lista para servir o usar en otras recetas.'
    },

    ['salt'] = {
        label = 'Sal',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un condimento esencial para potenciar el sabor de cualquier plato.'
    },

    ['sugar'] = {
        label = 'Azucar',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un ingrediente dulce usado en postres, bebidas y otras preparaciones.'
    },

    ['driedfruits'] = {
        label = 'Frutos secos',
        weight = 1,
        stack = true,
        close = false,
        description = 'Una mezcla de frutos secos ideal para snacks o recetas variadas.'
    },

    ['chocolate'] = {
        label = 'Chocolate',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un ingrediente dulce perfecto para postres, bebidas y decoraciones.'
    },

    ['jelly'] = {
        label = 'Gelatina',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un ingrediente suave y dulce ideal para postres y preparaciones frias.'
    },

    ['milk'] = {
        label = 'Leche',
        weight = 250,
        stack = true,
        close = true,
        description = 'Leche utilizada para preparar bebidas y batidos.'
    },
    ['granosdecafe'] = {
        label = 'Granos de café',
        weight = 100,
        stack = true,
        close = true,
        description = 'Granos de café utilizados para preparar café.'
    },

    ['empty_cup'] = {
        label = 'Vaso vacío',
        weight = 50,
        stack = true,
        close = true,
        description = 'Vaso vacío para servir bebidas.'
    },

    ['flour'] = {
        label = 'Harina',
        weight = 150,
        stack = true,
        close = true,
        description = 'Harina utilizada para preparar rebozados y masas.'
    },

    ['onion'] = {
        label = 'Cebolla',
        weight = 100,
        stack = true,
        close = true,
        description = 'Cebolla utilizada para preparar acompañamientos.'
    },

    ['potato_raw'] = {
        label = 'Patata cruda',
        weight = 150,
        stack = true,
        close = true,
        description = 'Patata sin cocinar.'
    },

    ['meat_raw'] = {
        label = 'Carne cruda',
        weight = 250,
        stack = true,
        close = true,
        description = 'Carne cruda que debe cocinarse antes de utilizarse.'
    },

    ['meat_cooked'] = {
        label = 'Carne cocinada',
        weight = 250,
        stack = true,
        close = true,
        description = 'Carne cocinada lista para preparar comida.'
    },

    ['chicken_raw'] = {
        label = 'Pollo crudo',
        weight = 250,
        stack = true,
        close = true,
        description = 'Pollo crudo que debe cocinarse antes de utilizarse.'
    },

    ['chicken_cooked'] = {
        label = 'Pollo cocinado',
        weight = 250,
        stack = true,
        close = true,
        description = 'Pollo cocinado listo para preparar comida.'
    },

    ['crispy_chicken'] = {
        label = 'Pollo crujiente',
        weight = 250,
        stack = true,
        close = true,
        description = 'Pollo crujiente preparado para hamburguesas o menús.'
    },

    ['bacon_raw'] = {
        label = 'Bacon crudo',
        weight = 150,
        stack = true,
        close = true,
        description = 'Bacon crudo que debe cocinarse.'
    },

    ['bacon_cooked'] = {
        label = 'Bacon cocinado',
        weight = 150,
        stack = true,
        close = true,
        description = 'Bacon cocinado listo para usar.'
    },


    -- =========================================================
    -- COMIDA INTERMEDIA / ACOMPAÑAMIENTOS
    -- =========================================================

    ['fries'] = {
        label = 'Patatas fritas',
        weight = 200,
        stack = true,
        close = true,
        description = 'Ración de patatas fritas.'
    },

    ['onion_rings'] = {
        label = 'Aros de cebolla',
        weight = 200,
        stack = true,
        close = true,
        description = 'Ración de aros de cebolla fritos.'
    },

    ['nuggets'] = {
        label = 'Nuggets',
        weight = 200,
        stack = true,
        close = true,
        description = 'Ración de nuggets de pollo.'
    },


    -- ===========================DROGAS INGREDIENTES=============================


    ["heroin_barrel"] = {
        label = "Barril",
        weight = 100,
        stack = true,
        close = true
    },

    ["heroin_alchol"] = {
        label = "Alcohol de heroína",
        weight = 10,
        stack = true,
        close = true
    },


    ["heroin_anhydride"] = {
        label = "Anhídrido",
        weight = 15,
        stack = true,
        close = true
    },

    ["platanocanario"] = {
        label = "Platano Canario",
        weight = 3,
        stack = true,
        close = true,
        description =
        "El plátano canario es el serio del grupo: pequeño, dulce y con acento tropical marcado, como si siempre supiera algo que tú no.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = "mp_player_inteat@burger", clip = "mp_player_int_eat_burger" },
            prop = { model = "v_res_tre_banana", pos = vec3(0.03, -0.02, -0.02), rot = vec3(0, -90.0, -0.0) },
            usetime = 3000,
            image = "platanocanario.png",
            notification = 'Bofff... me he acabado todo en muy poco tiempo, que bueno estaba.',
        }
    },



    ["heroin_hcacid"] = {
        label = "Acido Oxácidos ",
        weight = 10,
        stack = true,
        close = true
    },

    ["aluminumoxide"] = {
        label = "Óxido de aluminio",
        weight = 10,
        stack = true,
        close = true
    },

    -- ======================= PET ITEMS ======================


    --- Brutal Pets
    ["pet_water"] = {
        label = "Agua Mascotas ",
        weight = 150,
        stack = true,
        close = false,
    },

    ["pet_food"] = {
        label = "Comida Mascotas",
        weight = 150,
        stack = true,
        close = false,
    },

    ["pet_medikit"] = {
        label = "Kit Medicinal Mascotas",
        weight = 500,
        stack = true,
        close = false,
    },

    -- ======================== RCORE CASINO

    ['casino_beer'] = {
        label = 'Cerveza',
        weight = 15,
        close = true,
        consume = 0,
    },

    ['casino_burger'] = {
        label = 'Casino burger',
        weight = 15,
        close = true,
        degrade = 10080,
        client = {

            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
        }
    },

    ['casino_coffee'] = {
        label = 'Casino Cafe',
        weight = 15,
        close = true,
        degrade = 10080,
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
        }
    },

    ['casino_coke'] = {
        label = 'Casino Cola',
        weight = 15,
        close = true,
        degrade = 10080,
        client = {
            status = { thirst = 90000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
        }
    },

    ['casino_donut'] = {
        label = 'Casino Donut',
        weight = 15,
        close = true,
        degrade = 10080,
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_donut_02', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 90.0, -180.0), bone = 4186 },
            usetime = 3500,
        }
    },

    ['casino_ego_chaser'] = {
        label = 'Casino ego chaser',
        weight = 15,
        close = true,
        degrade = 10080,
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_choc_ego', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
        }

    },

    ['casino_luckypotion'] = {
        label = 'Casino luckypotion',
        weight = 15,
        close = true,
        consume = 0,
    },

    ['casino_psqs'] = {
        label = 'Casino Ps & Qs',
        weight = 15,
        close = true,
        degrade = 10080,
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
        }
    },

    ['casino_sandwitch'] = {
        label = 'Casino Sandwitch',
        weight = 15,
        close = true,
        degrade = 10080,
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
        }
    },

    ['casino_sprite'] = {
        label = 'Casino Sprunk',
        weight = 15,
        close = true,
        degrade = 10080,
        client = {
            status = { thirst = 90000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            notification = 'Te quitaste la sed con un Sprunk'
        }
    },


    -- ========================== VMS HOUSING =====================
    ['house_key'] = {
        label = 'Lleve de casa',
        weight = 10,
        stack = false,
        close = true,
    },
    ['police_barrier'] = {
        label = 'Barrera policial',
        weight = 300,
        stack = true,
        close = true,
    },
    ['police_stormram'] = {
        label = 'Ariete Policial',
        weight = 5000,
        stack = true,
        close = true,
    },
    ['pliers'] = {
        label = 'Alicates',
        weight = 50,
        stack = true,
        close = true,
    },
    ['insulating_tape'] = {
        label = 'Cinta aislante',
        weight = 20,
        stack = true,
        close = true,
    },

    -- TALLERES ILICITOS

    ["nos_blue"] = {
        label = "Nitro Azul",
        weight = 150,
        stack = true,
        close = true,
        description = "Nitrous bottle",
        client = {
            image = "nos_blue.png",
        }
    },
    ["nos_yellow"] = {
        label = "Nitro Amarillo",
        weight = 150,
        stack = true,
        close = true,
        description = "Nitrous bottle",
        client = {
            image = "nos_yellow.png",
        }
    },
    ["nos_red"] = {
        label = "Nitro Rojo",
        weight = 150,
        stack = true,
        close = true,
        description = "Nitrous bottle",
        client = {
            image = "nos_red.png",
        }
    },
    ["nos_remover"] = {
        label = "Remover Nitro",
        weight = 150,
        stack = true,
        close = true,
        description = "Nitrous removal kit",
        client = {
            image = "nos_remover.png",
        }
    },
    ["nos_purple"] = {
        label = "Nitro Lila",
        weight = 150,
        stack = true,
        close = true,
        description = "Nitrous bottle",
        client = {
            image = "nos_purple.png",
        }
    },
    ["nos_green"] = {
        label = "Nitro Verde",
        weight = 150,
        stack = true,
        close = true,
        description = "Nitrous bottle",
        client = {
            image = "nos_green.png",
        }
    },
    ["nos_turquoise"] = {
        label = "Nitro Turquesa",
        weight = 150,
        stack = true,
        close = true,
        description = "Nitrous bottle",
        client = {
            image = "nos_turquoise.png",
        }
    },
    ["veh_plates"] = {
        label = "Matrícula falsa",
        weight = 150,
        stack = true,
        close = true,
        description = "Matrícula falsa para vehículos",
        client = { image = "veh_plates.png" }
    },



    -- ===========================CINTURONES MAFIA=============================

    ['bigtbelt_world'] = {
        label = 'Cinturon Campeon del mundo',
        weight = 100,
        stack = false,
        close = true,
        client = {
            image = "bigtbelt_world.png",
        },
        modelp = 'bigtbelt_world',
    },

    ['bigtbelt_world2'] = {
        label = 'Cinturon Campeon del mundo',
        weight = 100,
        stack = false,
        close = true,
        client = {
            image = "bigtbelt_world.png",
        },
        modelp = 'bigtbelt_world2',
    },

    ['bigtbelt_north'] = {
        label = 'Cinturon Campeon del norte',
        weight = 50,
        stack = false,
        close = true,
        client = {
            image = "bigtbelt_north.png",
        },
        modelp = 'bigtbelt_north',
    },

    ['bigtbelt_south'] = {
        label = 'Cinturon Campeon del sur',
        weight = 75,
        stack = false,
        close = true,
        client = {
            image = "bigtbelt_south.png",
        },
        modelp = 'bigtbelt_south',
    },
    ['keyvehicle'] = {
        label = 'LLave de vehiculo',
        weight = 75,
        stack = false,
        close = true,
        client = {
            image = "keyvehicle.png",
        },
        modelp = 'bigtbelt_south',
    },

    -- ===========================MAFIA=============================

    ["documentoclasificado"] = {
        label = "Documento Clasificado",
        weight = 3,
        stack = true,
        close = true,
        description = "Clasificado",
        client = {
            image = "documentoclasificado.png",
        },
        modelp = 'tr_prop_tr_clipboard_sh_01a',
    },
    ["carpetaclasificada"] = {
        label = "Carpeta Clasificada",
        weight = 3,
        stack = true,
        close = true,
        description = "Clasificado",
        client = {
            image = "carpetaclasificada.png",
        },
        modelp = 'm23_2_prop_m32_folder_01b',
    },

    ['notaadhesiva'] = {
        label = 'Post It',
        weight = 10,
        stack = true,
        close = true,
        description = "Una nota adhesiva, con algo escrito en ella."
    },

    ['invitaciondon'] = {
        label = 'Invitacion Don',
        weight = 10,
        stack = true,
        close = true,
        description =
        'Tarjeta de invitacion a la fiesta mas exclusiva de Los Santos. INVITACION EXCLUSIVA para el 22 de marzo. Si tienes esta invitacion, sientente afortunado',
    },

    ['canonak47'] = {
        label = 'Cañón de AK-47',
        weight = 120,
        stack = true,
        close = true,
        description =
        'Cañón reforzado compatible con rifles AK-47, diseñado para soportar altas presiones y disparos continuados. Esto es solo la pieza de un puzle más grande, ¿dónde estarán las demás?',
    },

    ['culataak47'] = {
        label = 'Culata de AK-47',
        weight = 300,
        stack = true,
        close = true,
        description =
        'Culata robusta diseñada para rifles AK-47 que proporciona estabilidad y control al disparar. Esto es solo la pieza de un puzle más grande, ¿dónde estarán las demás?',
    },

    ['mecanismoak47'] = {
        label = 'Mecanismo de AK-47',
        weight = 500,
        stack = true,
        close = true,
        description =
        'Sistema interno encargado del funcionamiento del arma y de su ciclo de disparo automático. Esto es solo la pieza de un puzle más grande, ¿dónde estarán las demás?',
    },

    ['pistonak47'] = {
        label = 'Pistón de gas AK-47',
        weight = 500,
        stack = true,
        close = true,
        description =
        'Pistón de gas que permite el retroceso del sistema y el ciclo automático del rifle AK-47. Esto es solo la pieza de un puzle más grande, ¿dónde estarán las demás?',
    },

    ['cargadorak47'] = {
        label = 'Cargador de AK-47',
        weight = 300,
        stack = true,
        close = true,
        description =
        'Cargador curvo estándar diseñado para almacenar munición de calibre 7.62 para rifles AK-47. Esto es solo la pieza de un puzle más grande, ¿dónde estarán las demás?',
    },

    ['muelleak47'] = {
        label = 'Muelle recuperador AK-47',
        weight = 300,
        stack = true,
        close = true,
        description =
        'Muelle recuperador encargado de devolver el sistema del rifle a su posición tras cada disparo. Esto es solo la pieza de un puzle más grande, ¿dónde estarán las demás?',
    },

    ['gatilloak47'] = {
        label = 'Gatillo de AK-47',
        weight = 150,
        stack = true,
        close = true,
        description =
        'Mecanismo de gatillo que inicia el ciclo de disparo del rifle AK-47. Esto es solo la pieza de un puzle más grande, ¿dónde estarán las demás?',
    },



    ['bolsatussi'] = {
        label = 'Bolsa de Tussi',
        weight = 1,
        stack = true,
        close = true,
        description =
        'Una pequeña bolsa con 1 gramo de polvo rosado conocido en la calle como tussi. La cocaina sabor fresa.',
    },

    ['cucharacrack'] = {
        label = 'Cuchara con Restos de Crack',
        weight = 15,
        stack = true,
        close = true,
        description = 'Una cuchara metálica con restos quemados de crack. Todavia quedan restos por fumar.',
    },

    ['hongospsilocibios'] = {
        label = 'Hongos Psilocibios',
        weight = 80,
        stack = true,
        close = true,
        description = 'Un pequeño grupo de hongos psilocibios secos, conocidos por sus fuertes efectos psicodélicos.',
    },

    ['canonconfeti'] = {
        label = 'Cañón de Confeti',
        weight = 300,
        stack = true,
        close = true,
        consume = 0,
        5,
        description =
        'Un cañón de confeti listo para ser disparado. Para grandes celebraciones, fiestas o momentos especiales donde quieras llenar el aire de color.',
        modelp = "prop_poster_tube_02",
        client = {
            event = 'confetti:canon',
        },
    },

    ["rayadecoca"] = {
        label = "Raya de coca",
        weight = 5,
        stack = true,
        close = true,
        description = "Un tirito de un gramo. Para pasar bien la noche",
        modelp = "prop_cs_coke_line",
    },

    ["jeringadefenta"] = {
        label = "Jeriguilla de Fentanilo",
        weight = 15,
        stack = true,
        close = true,
        description = "Una jeringuilla cargada de fentanilo, en dosis altas puede ser altamente mortal.",
        modelp = "prop_syringe_01",
    },

    ["ldemarihuana"] = {
        label = "Porro grande",
        weight = 5,
        stack = true,
        close = true,
        description = "Una L liada con cariño, para calmar el estres y relajarse lentamente",
        modelp = "p_cs_joint_02",
    },

    ["pastillaslsd"] = {
        label = "Pastillas de colores",
        weight = 5,
        stack = true,
        close = true,
        description = "Recien llegadas, las pastillas rojas, verdes y amarillas.",
        modelp = "bkr_prop_coke_painkiller_01a",
    },

    ["porrodemaria"] = {
        label = "Porro de maria",
        weight = 5,
        stack = true,
        close = true,
        description =
        "Un porro liado a la perfecion con su papel de alta gama, su filtro de cartón y la mejor marihuana de la ciudad.",
        modelp = "p_cs_joint_02",

    },

    ["cajadealmacenamiento"] = {
        label = "Caja cerrada",
        weight = 2000,
        stack = false,
        close = true,
        description = "Minimo esto tiene que pesar un kilo. ¿Que tendrá esto dentro?",
        modelp = 'prop_cs_cardbox_01',
    },

    ["cajadearmas"] = {
        label = "Caja de armas",
        weight = 2000,
        stack = false,
        close = true,
        description = "Así a peso son aproximadamente unos 2KG de ¿armas?.",
        modelp = 'p_gcase_s',
    },

    ["microchipavanzado"] = {
        label = "Microchips avanzados",
        weight = 200,
        stack = true,
        close = true,
        description =
        "Microchips de alta tecnologia recubiertos de oro, cobre y nikel. Con una nanotecnologia inigualable",
    },


    ["lingotestitanio"] = {
        label = "Lingotes de titanio",
        weight = 500,
        stack = true,
        close = true,
        description = "Metal industrial extremadamente resistente usado en armamento..",
        modelp = 'prop_security_case_01',
    },


    ["fardodecoca"] = {
        label = "1KG de cocaina",
        weight = 1000,
        stack = false,
        close = true,
        description = "Así a peso son aproximadamente un 1KG de cocaina pura.",
        modelp = "prop_drug_package_02",
    },

    ["fardodemaria"] = {
        label = "1KG de marihuana",
        weight = 1000,
        stack = false,
        close = true,
        description = "Así a peso son aproximadamente un 1KG de marihuana pura.",
        modelp = "hei_prop_heist_weed_block_01b",
    },

    ["fardodemeta"] = {
        label = "1KG de metanfetamina",
        weight = 1000,
        stack = false,
        close = true,
        description = "Así a peso son aproximadamente un 1KG de meta pura.",
        modelp = "xm3_prop_xm3_drug_pkg_01a",
    },

    ["fardodefenta"] = {
        label = "1KG de fentanilo",
        weight = 1000,
        stack = false,
        close = true,
        description = "Así a peso son aproximadamente un 1KG de fentanilo en pipetas.",
        modelp = "prop_mp_drug_pack_red",
    },

    ["botequimico"] = {
        label = "Bote quimico",
        weight = 1000,
        stack = false,
        close = true,
        modelp = 'prop_barrel_exp_01b',
        description = "Bote de residuos quimicos. Es peligroso tenerlo cerca.",
        client = {
            image = "botequimico.png",
        }
    },


    ["llavevieja"] = {
        label = "Llave misteriosa",
        weight = 5,
        stack = true,
        close = true,
        description = "Una llave bastante antigua ¿que abrirá esto?",
        modelp = "h4_prop_h4_keys_jail_01a",
    },

    ["botiquin"] = {
        label = "Botiquin",
        weight = 15,
        stack = true,
        close = true,
        description =
        "Un botiquin de primeros auxilios, tiene todo lo necesario para cortar una hemorragia de forma rapida, pero deberias ir al hospital mejor.",
        modelp = "v_ret_ta_firstaid",
    },

    ["maletinjudio"] = {
        label = "Maletin del Judio",
        weight = 500,
        stack = true,
        close = true,
        description = "Un maletin muy valioso, por el contenido de su interior.",
        modelp = 'ch_prop_ch_case_01a',
    },

    ["calavera"] = {
        label = "Calavera Humana",
        weight = 150,
        stack = true,
        close = true,
        description = "Tiene una apariencia bastante realista, parece una calavera de una persona",
        modelp = "ch_prop_collectibles_limb_01a",
    },

    ["dedocortado"] = {
        label = "Dedo Humano",
        weight = 150,
        stack = true,
        close = true,
        description = "Tiene una apariencia bastante realista, parece el dedo de una persona",
    },


    ["brazocortado"] = {
        label = "Brazo Humano",
        weight = 150,
        stack = false,
        close = true,
        description = "Tiene una apariencia bastante realista, parece el brazo de una persona",
        modelp = "ch_prop_collectibles_limb_01a",
    },

    ["cabezahumana"] = {
        label = "Cabeza Humana",
        weight = 150,
        stack = false,
        close = true,
        description = "Una cabeza humana envuelta en unos trozos de papel de peridoco. Que asco da esto.",
        modelp = "p_cs_duffel_01_s",
    },

    ["orejacortada"] = {
        label = "Oreja Humana",
        weight = 150,
        stack = true,
        close = true,
        description = "Tiene una apariencia bastante realista, parece la oreja de una persona",
    },

    ["diamanterosado"] = {
        label = "Diamante rosa",
        weight = 150,
        stack = true,
        close = true,
        description = "Es una piedra de bastante valor, si lo miras de cerca es como hipnotica",
        modelp = 'h4_prop_h4_diamond_01a',
    },

    ['maletin_bomba'] = {
        label = 'Maletín Bomba',
        weight = 5000,
        stack = false,
        close = true,
        client = {
            event = 'bombs:place',
            image = 'maletabomba.png'
        }
    },

    ['detonador_bomba'] = {
        label = 'Detonador',
        weight = 100,
        stack = false,
        close = true,
        client = {
            event = 'bombs:useDetonator',
            image = 'detonador_bomba.png'
        }
    },

    ["inhibidormovil"] = {
        label = "Inhibidor movil.",
        weight = 150,
        stack = true,
        close = true,
        description = "Un inhibidor de frecuencias ¿servirá para desconectar una cerradura electronica?",
        modelp = 'prop_prologue_phone',
    },


    ["trojan_usb"] = {
        label = "USB Troyano",
        weight = 100,
        stack = true,
        close = true,
        description = "Software útil para desactivar algunos sistemas.",
        client = {
            image = "trojan_usb.png",
        }
    },

    ["electronickit"] = {
        label = "Kit Electronico",
        weight = 30,
        stack = true,
        close = true,
        description = "Un buen kit electrico de apoyo",
        client = {
            image = "electronickit.png",
        }
    },


    ['hackingdevice'] = {
        label = 'Dispositivo de hackeo',
        weight = 50,
        description = 'Te permitirá saltarte los sistemas de seguridad de vehículos.',
        client = {
            image = "hackpc.png",
        }

    },
    ["screwdriverset"] = {
        label = "Juego de Destornilladores",
        weight = 30,
        stack = true,
        modelp = 'v_ind_cs_screwdrivr1',
        close = true,
        description = "Herramienta sofisticada",
        client = {
            image = "screwdriverset.png",
        }
    },
    ["cortadordecristal"] = {
        label = "Cortador de Cristal",
        weight = 120,
        stack = true,
        close = true,
        description = "Todo se corta",
        client = {
            image = "cortadordecristal.png",
        },
        modelp = "h4_prop_h4_cutter_01a"
    },
    ["drill"] = {
        label = "Taladro",
        weight = 120,
        stack = true,
        close = true,
        description = "Herramienta sofisticada",
        client = {
            image = "drill.png",
        },
        modelp = 'gr_prop_gr_drill_01a',
    },

    ["taladropercutor"] = {
        label = "Taladro Percutor",
        weight = 300,
        stack = true,
        close = true,
        description = "Herramienta sofisticada",
        client = {
            image = "taladropercutor.png",
        },
        modelp = 'hei_prop_heist_drill',
    },


    ["lanzatermica"] = {
        label = "Lanza Termica",
        weight = 200,
        stack = true,
        close = true,
        description = "Herramienta sofisticada",
        client = {
            image = "lanzatermica.png",
        },
        modelp = 'ch_prop_ch_heist_drill',
    },

    ["radial"] = {
        label = "Radial",
        weight = 120,
        stack = true,
        close = true,
        description = "Herramienta sofisticada",
        client = {
            image = "radial.png",
        },
        modelp = 'xm3_prop_xm3_grinder_02a',
    },

    ["sierragrande"] = {
        label = "Sierra Grande",
        weight = 300,
        stack = true,
        close = true,
        description = "Herramienta sofisticada",
        client = {
            image = "sierragrande.png",
        },
        modelp = 'v_ind_cm_grinder',
    },

    ["sopleteportatil"] = {
        label = "Soplete portatil",
        weight = 120,
        stack = true,
        close = true,
        description = "Herramienta sofisticada",
        client = {
            image = "sopleteportatil.png",
        },
        modelp = 'prop_weld_torch',
    },


    ["thermite"] = {
        label = "Termita",
        weight = 300,
        stack = true,
        close = true,
        description = "Herramienta sofisticada",
        client = {
            image = "thermite.png",
        },
        modelp = 'hei_prop_heist_thermite_case',
    },

    ["keycard"] = {
        label = "Tarjeta de Almacen.",
        weight = 15,
        stack = true,
        close = true,
        consume = 0.5,
        description = "Una tarjeta de seguridad con un PIN atrás.",
        client = { image = 'keycard.png' }
    },

    ["tarjetadeseguridad"] = {
        label = "Tarjeta de seguridad.",
        weight = 15,
        stack = true,
        close = true,
        description = "Una tarjeta de seguridad con un PIN atrás.",
    },

    ["tarjetadeseguridad2"] = {
        label = "Tarjeta de seguridad.",
        weight = 15,
        stack = true,
        close = true,
        description = "Una tarjeta de seguridad con un PIN atrás.",
    },

    ["tarjetadeseguridad3"] = {
        label = "Tarjeta de seguridad.",
        weight = 15,
        stack = true,
        close = true,
        description = "Una tarjeta de seguridad con un PIN atrás.",
    },


    ["tarjetamotel"] = {
        label = "Tarjeta de motel.",
        weight = 15,
        stack = false,
        close = true,
        description = "Una tarjeta de seguridad con un PIN atrás.",
    },

    ["placafib"] = {
        label = "Placa de FIB.",
        weight = 15,
        stack = true,
        close = true,
        description = "Una placa del FIB con un PIN atrás.",
        modelp = 'prop_fib_badge',

    },


    ["idfalso"] = {
        label = "ID",
        weight = 15,
        stack = true,
        close = true,
        description = "Una tarjeta de identificacion. Asociada a un nombre un una ID",

    },

    ["pasaportefalso"] = {
        label = "Pasaporte",
        weight = 15,
        stack = true,
        close = true,
        description = "Un pasaporte de identificacion. Asociada a un nombre un una ID",

    },

    ["periodico1"] = {
        label = "Periodico antiguo.",
        weight = 15,
        stack = false,
        close = true,
        description = "Este dia ocurrio algo muy impactante para la ciudad de los santos",
        modelp = 'ng_proc_paper_news_rag',
    },


    ["periodico2"] = {
        label = "Periodico antiguo.",
        weight = 15,
        stack = false,
        close = true,
        description = "Este dia ocurrio algo muy impactante para la ciudad de los santos",
        modelp = 'ng_proc_paper_news_rag',

    },

    ["documentosantiguos"] = {
        label = "Documentos arrugados.",
        weight = 15,
        stack = false,
        close = true,
        description = "A ver que pone en la letra pequeña... Este nombre me suena de algo",
        modelp = 'hei_prop_hei_timetable',

    },

    ["facturas"] = {
        label = "Facutas arrugadas.",
        weight = 15,
        stack = false,
        close = true,
        description = "A ver que pone en la letra pequeña... Este nombre me suena de algo",
        modelp = 'hei_prop_hei_timetable',
    },

    ["evidenciaspoliciales"] = {
        label = "Evidencias arrugadas.",
        weight = 15,
        stack = false,
        close = true,
        description = "A ver que pone en la letra pequeña... Este nombre me suena de algo",
        modelp = 'hei_prop_heist_docs_01',
    },

    ["evidenciaspoliciales1"] = {
        label = "Evidencias arrugadas.",
        weight = 15,
        stack = false,
        close = true,
        description = "A ver que pone en la letra pequeña... Este nombre me suena de algo",
        modelp = 'hei_prop_heist_docs_01',

    },

    ["evidenciaspoliciales2"] = {
        label = "Evidencias arrugadas.",
        weight = 15,
        stack = false,
        close = true,
        description = "A ver que pone en la letra pequeña... Este nombre me suena de algo",
        modelp = 'hei_prop_heist_docs_01',

    },

    ["estatuadeoro"] = {
        label = "Estatua dorada",
        weight = 250,
        stack = true,
        close = true,
        description = "Una estatua dorada, con el sello de ORO de primera. Tiene muy buena pinta",
        modelp = 'vw_prop_vw_pogo_gold_01a',

    },

    ["estatuadeoro2"] = {
        label = "Estatua dorada",
        weight = 250,
        stack = true,
        close = true,
        description = "Una estatua dorada, con el sello de ORO de primera. Tiene muy buena pinta",
    },


    ["huevoazteka"] = {
        label = "Huevo Azteka",
        weight = 250,
        stack = true,
        close = true,
        description = "Una reliquia antigua de los antepasados americanos. ¿Que precio tendrá esto?",
    },

    ["panteradeoro"] = {
        label = "Pantera dorada",
        weight = 250,
        stack = true,
        close = true,
        description = "Una pantera de oro con una gema de lapislazuli en su interior. Que bien se ve",
        modelp = "h4_prop_h4_art_pant_01a",
    },

    ["caballodeoro"] = {
        label = "Caballo dorado",
        weight = 250,
        stack = true,
        close = true,
        description = "Una estatua dorada, con el sello de ORO de primera. Tiene muy buena pinta",
    },

    ["grandiamante"] = {
        label = "Gran diamante",
        weight = 550,
        stack = true,
        close = true,
        description = "Es un diamante gigante, esto minimo pesa unos 500g.",
    },

    ["paletdebilletes"] = {
        label = "Un palet de billetes",
        weight = 2000,
        stack = false,
        close = true,
        description = "Un palet lleno de billetes, seria preciso contarlo mas tranquilamente para saber cuanto hay",
        modelp = 'bkr_prop_bkr_cashpile_01',
    },

    ["muestrasangre"] = {
        label = "Muestra de sangre.",
        weight = 15,
        stack = true,
        close = true,
        description = "Una muestra de sangre ¿podrá ser analizada para saber de quien será?",

    },

    ["muestraorina"] = {
        label = "Muestra de orina.",
        weight = 15,
        stack = true,
        close = true,
        description = "Una muestra de orina ¿podrá ser analizada para saber de quien será?",

    },

    ["kitquirurgicohospi"] = {
        label = "Kit Quirúrgico",
        weight = 10,
        stack = true,
        close = true,
        description = "Maletín con bisturís y herramientas quirúrgicas de alta precisión.",
        client = {
            image = "kitquirurgicohospi.png",
        },
        modelp = "xm3_prop_xm3_med_osc_01a",
    },

    ["desfibriladorportatilhospi"] = {
        label = "Desfibrilador Portátil",
        weight = 10,
        stack = true,
        close = true,
        description = "Dispositivo médico util para reanimación cardíaca en emergencias.",
        client = {
            image = "desfibriladorportatilhospi.png",
        },
        modelp = "prop_medstation_03",
    },

    ["jeringuillasadrenalinahospi"] = {
        label = "Jeringuillas de Adrenalina",
        weight = 10,
        stack = true,
        close = true,
        description =
        "Unas cuantas jeringuillas de adrenalina, costosas de encontrar y con un alto valor. Esto es mejor que una raya de cocaina",
        client = {
            image = "jeringuillasadrenalinahospi.png",
        }
    },

    ["historialmedicohospi"] = {
        label = "Historial Médico",
        weight = 10,
        stack = true,
        close = true,
        description = "Documentación sensible de pacientes con alto valor.",
        client = {
            image = "historialmedicohospi.png",
        },
        modelp = 'hei_prop_hei_timetable',

    },

    ["recetariomedicohospi"] = {
        label = "Recetario Médico",
        weight = 10,
        stack = true,
        close = true,
        description = "Talonario oficial del estado del SAED, puede ser utilizado para emitir recetas falsas.",
        client = {
            image = "recetariomedicohospi.png",
        },
        modelp = 'hei_prop_hei_timetable',

    },

    ["transporteorganoshospi"] = {
        label = "Transporte de Órganos Lleno",
        weight = 10,
        stack = true,
        close = true,
        description =
        "Contenedor refrigerado usado para transportar órganos humanos. Al parecer tiene varios órganos en su interior.",
        client = {
            image = "transporteorganoshospi.png",
        },
        modelp = "xm_prop_smug_crate_s_medical",
    },

    ["cartera"] = {
        label = "Cartera vieja.",
        weight = 15,
        stack = true,
        close = true,
        description = "Una cartera bastante gordita, cuanta informacion tendrá esto...",
        modelp = 'ba_prop_battle_wallet_pickup',
    },


    ["corazonhumano"] = {
        label = "Corazon Humano",
        weight = 10,
        stack = true,
        close = true,
        description =
        "Un corazón humano extraído recientemente. Aún conserva restos de sangre fresca y tiene cortes alrededor de los vasos sanguíneos.",
        client = {
            image = "corazonhumano.png",
        }
    },


    -- ===========================PL PRINTER IMPRESORA=============================

    ["gym_membership"] = {
        label = "Membresía del gimnasio",
        weight = 10,
        stack = true,
        close = false,
        description = "Membresía GYM",
        client = {
            image = "gym_membership.png",
        }
    },


    ["casino_chips"] = {
        label = "Fichas para casino",
        weight = 1,
        stack = true,
        close = false,
        description = "Fichas para gastar en el casino.",
        client = {
            image = "fichascasino.png",
        }
    },

    -- =========================== ORIGEN POLICE ===================================

    -- ── EVIDENCE ──────────────────────────────────────────────────────────────────

    ['evidence_a'] = {
        label       = 'Bullet Evidence',
        weight      = 0,
        stack       = false,
        close       = false,
        description = 'Evidence obtained from a crime scene.',
        image       = 'evidence_a.png',
    },

    ['evidence_az'] = {
        label       = 'Evidence',
        weight      = 0,
        stack       = false,
        close       = false,
        description = 'Evidence obtained from a crime scene.',
        image       = 'evidence_az.png',
    },

    ['evidence_b'] = {
        label       = 'Vehicle Evidence',
        weight      = 0,
        stack       = false,
        close       = false,
        description = 'Evidence obtained from a crime scene.',
        image       = 'evidence_b.png',
    },

    ['evidence_n'] = {
        label       = 'Impact Evidence',
        weight      = 0,
        stack       = false,
        close       = false,
        description = 'Evidence obtained from a crime scene.',
        image       = 'evidence_n.png',
    },

    ['evidence_ne'] = {
        label       = 'Footprint Evidence',
        weight      = 0,
        stack       = false,
        close       = false,
        description = 'Evidence obtained from a crime scene.',
        image       = 'evidence_ne.png',
    },

    ['evidence_r'] = {
        label       = 'Blood Evidence',
        weight      = 0,
        stack       = false,
        close       = false,
        description = 'Evidence obtained from a crime scene.',
        image       = 'evidence_r.png',
    },

    ['evidence_ro'] = {
        label       = 'Evidence',
        weight      = 0,
        stack       = false,
        close       = false,
        description = 'Evidence obtained from a crime scene.',
        image       = 'evidence_ro.png',
    },

    ['evidence_v'] = {
        label       = 'Drug Evidence',
        weight      = 0,
        stack       = false,
        close       = false,
        description = 'Evidence obtained from a crime scene.',
        image       = 'evidence_v.png',
    },

    -- ── EQUIPMENT ─────────────────────────────────────────────────────────────────


    ["grapadora"] = {
        label = "Grapadora",
        weight = 10,
        stack = true,
        close = true,
        description =
        "La herramienta favorita de cualquier detective. Dicen que sirve para unir papeles, pero en realidad solo existe para recordarles que el 90% de su trabajo consiste en rellenar informes.",
        client = {
            image = "grapadora.png",
        },
        modelp = 'v_ret_gc_staple',
    },


    ["binoculars"] = {
        label = "Prismaticos",
        weight = 600,
        stack = true,
        close = true,
        description = "Para ver los picos de las montanas u otras cosas...",
        client = {
            image = "binoculars.png",
        },
        modelp = 'v_serv_ct_binoculars',
    },

    -- ['megaphone'] = {
    --     label       = 'Megafono',
    --     weight      = 0,
    --     stack       = false,
    --     close       = false,
    --     description = 'A megaphone to make your voice heard.',
    --     image       = 'megaphone.png',
    -- },

    ["megaphone"] = {
        name = "megaphone",
        label = "Megáfono",
        weight = 1,
        stack = true,
        close = true,
        client = { image = "megaphone.png", export = 'jj_megaphone.useMegaphone' },
        modelp = 'prop_megaphone_01',
    },

    -- ========================== 0R CRAFTEO ILEGALES =================

    ['canon_generico'] = {
        label = 'Canon generico',
        weight = 120,
        stack = true,
        close = false,
        description = 'Un canon estandar compatible con distintos modelos de armas.'
    },

    ['culata_generica'] = {
        label = 'Culata generica',
        weight = 180,
        stack = true,
        close = false,
        description = 'Una culata basica pensada para el montaje de diferentes armas.'
    },

    ['cargador_generico'] = {
        label = 'Cargador generico',
        weight = 90,
        stack = true,
        close = false,
        description = 'Un cargador comun preparado para alojar municion en varias armas.'
    },

    ['gatillo_generico'] = {
        label = 'Gatillo generico',
        weight = 40,
        stack = true,
        close = false,
        description = 'Una pieza de disparo basica para mecanismos de armas compatibles.'
    },

    ['muelle_recuperador'] = {
        label = 'Muelle recuperador',
        weight = 35,
        stack = true,
        close = false,
        description = 'Un muelle encargado de ayudar al retorno del mecanismo tras el disparo.'
    },

    ['mecanismo_disparo'] = {
        label = 'Mecanismo de disparo',
        weight = 110,
        stack = true,
        close = false,
        description = 'Un conjunto de piezas internas necesario para accionar el disparo del arma.'
    },

    ['cerrojo_generico'] = {
        label = 'Cerrojo generico',
        weight = 140,
        stack = true,
        close = false,
        description = 'Una pieza de cierre estandar usada en el funcionamiento interno del arma.'
    },

    ['cuerpo_arma_corta'] = {
        label = 'Cuerpo de arma corta',
        weight = 200,
        stack = true,
        close = false,
        description = 'La estructura principal para el ensamblaje de un arma corta.'
    },

    ['cuerpo_arma_media'] = {
        label = 'Cuerpo de arma media',
        weight = 200,
        stack = true,
        close = false,
        description = 'La base estructural pensada para montar un arma de tamano medio.'
    },

    ['cuerpo_escopeta_generico'] = {
        label = 'Cuerpo de escopeta',
        weight = 200,
        stack = true,
        close = false,
        description = 'La estructura principal destinada al montaje de una escopeta.'
    },

    ['cuerpo_arma_larga'] = {
        label = 'Cuerpo de arma larga',
        weight = 200,
        stack = true,
        close = false,
        description = 'La estructura principal destinada al montaje de un arma larga.'
    },
    -- ================= SCRITP PELUCAS HOOKAH MEDINA =================


    ["stg_chess"] = {
        label = "Ajedrez",
        weight = 2000,
        stack = false,
        close = true,
        description = "Mesa de ajedrez plegable. Colócala donde quieras y reta a alguien.",
        client = {
            event = 'stg-chessv2:client:useItem'
        }
    },

    ["stg_checkers"] = {
        label = "Damas",
        weight = 2000,
        stack = false,
        close = true,
        description = "Tablero de damas plegable. Colócalo donde quieras y reta a alguien.",
        client = {
            event = 'stg-checkers:client:useItem'
        }
    },

    ["scratch_ticket"] = {
        label = "Rasca",
        weight = 3,
        stack = true,
        close = false,
        description = "Rasca y gana",
        client = {
            image = "scratch_ticket.png",
        }
    },


    ['cinturontigrebull'] = {
        label = 'Cinturón Tigre Bull',
        weight = 500,
        stack = false,
        close = true,
        client = {
            image = "cinturontigrebull.png",
        },
        modelp = 'wwe_championship_belt_current',
    },

    ['metaldetector'] = {
        label = 'Detector de metales',
        weight = 1200,
        buttons = {
            {
                label = 'Usar detector de metales',
                action = function(slot)
                    exports.ox_inventory:closeInventory()
                    exports['bbs_metalDetecting']:startDetecting()
                end
            },
            {
                label = 'Guardar detector',
                action = function(slot)
                    exports.ox_inventory:closeInventory()
                    exports['bbs_metalDetecting']:stopDetecting()
                end
            },
        },
    },

    ["kuz_divinggeargood"] = {
        label = "Equipo de buceo Profesional",
        weight = 600,
        stack = true,
        close = true,
        description = "Equipo avanzado de buceo",
        client = {
            image = "diving_gear.png",
        }
    },
    ["kuz_divinggear"] = {
        label = "Equipo de buceo",
        weight = 600,
        stack = true,
        close = true,
        description = "Equipo avanzado de buceo",
        client = {
            image = "diving_gear.png",
        }
    },

    ["kuz_silvercoin"] = {
        label = "Moneda de plata",
        weight = 3,
        stack = true,
        close = true,
        description = "Una moneda de plata, que tiene un valor bastante alto. Podrás venderla a un buen precio.",
        client = {
            image = "kuz_silvercoin.png",
        }
    },

    ["kuz_rarecoin"] = {
        label = "Moneda rara",
        weight = 3,
        stack = true,
        close = true,
        description = "Una moneda rara, que es bastante valiosa. Puedes venderla por un buen precio.",
        client = {
            image = "kuz_rarecoin.png",
        }
    },

    ["kuz_plasmacutter"] = {
        label = "Cortador de plasma",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Un cortador laser, podras usarlo para cortar metales y abrir cajas fuertes. Es un objeto muy valioso.",
        client = {
            image = "kuz_plasmacutter.png",
        }
    },

    ["kuz_pearl"] = {
        label = "Perla",
        weight = 3,
        stack = true,
        close = true,
        description = "Una perla, que es bastante valiosa. Puedes venderla por un buen precio.",
        client = {
            image = "kuz_pearl.png",
        }
    },

    ["kuz_jewelry"] = {
        label = "Joyería bisutería",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Bisuteria del lago con un poco de corrosion, pero que tiene un valor bastante alto. Podrás venderla a un buen precio.",
        client = {
            image = "kuz_jewelry.png",
        }
    },

    ["kuz_goldcoin"] = {
        label = "Moneda de oro",
        weight = 3,
        stack = true,
        close = true,
        description = "Una moneda de oro, que tiene un valor bastante alto. Podrás venderla a un buen precio.",
        client = {
            image = "kuz_goldcoin.png",
        }
    },

    ["wheelchair"] = {
        label       = "Silla de ruedas",
        weight      = 500,
        stack       = false,
        close       = true,
        consume     = 1,
        description = "Silla de ruedas.",
        client      = {
            export = 'jj_things.wheelchair',
        },
        modelp      = 'prop_wheelchair_01',
    },


    ["tablet_locales"] = {
        label = "Tablet de Locales",
        weight = 10,
        stack = true,
        close = true,
        description =
        "Una tablet con la información de los locales de la ciudad. Útil para encontrar el lugar perfecto para cada ocasión.",
        client = {
            export = "jj_bizztablet.openTablet", image = "tablet_locales.png"
        },
        modelp = 'reh_prop_reh_tablet_01a',

    },

    ["repairkit"] = {
        label = "Kit de reparación",
        weight = 250,
        stack = true,
        close = true,
        description = "Kit de reparación para reparar el motor de vehículos",
        client = {
            image = "repairkit.png",
            export = "jj_creatorjobs.repairkit",
        }
    },

    ["llavedecoche"] = {
        label = "LLaves",
        weight = 10,
        stack = true,
        close = true,
        description = "Las llaves vinculadas, a la cerradorura electronica de un coche",
        client = {
            image = "llavedecoche.png",
        }
    },


    ["cleaningkit"] = {
        label = "Kit de limpieza",
        weight = 250,
        stack = true,
        close = true,
        description = "Un paño de microfibra con un poco de jabón dejará tu coche reluciente otra vez.",
        client = {
            image = "cleaningkit.png",
        }
    },

    ['bench_basic'] = {
        label = 'Banco de crafteo básico',
        description = 'Un banco portátil para crafteo básico. Colócalo para empezar a craftear.',
        weight = 8000,
        stack = false,
        close = true,
        consume = 0
    },

    ['bench_advanced'] = {
        label = 'Banco de crafteo avanzado',
        description = 'Banco avanzado capaz de recetas más complejas.',
        weight = 9500,
        stack = false,
        close = true,
        consume = 0
    },

    ['blueprint'] = {
        label = 'Plano',
        description = 'Un plano detallado con dibujos técnicos e instrucciones.',
        weight = 25,
        stack = true,
        close = true,
        consume = 0,
        degrade = 60,
    },
    ['storage_small'] = {
        label = 'Almacenamiento pequeño',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un contenedor pequeño pensado para guardar una cantidad limitada de objetos.'
    },

    ['storage_medium'] = {
        label = 'Almacenamiento mediano',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un contenedor de tamaño medio ideal para almacenar varios objetos de forma organizada.'
    },

    ['storage_large'] = {
        label = 'Almacenamiento grande',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un contenedor amplio diseñado para guardar una gran cantidad de objetos.'
    },

    -- ========================= PISTOLAD DE AGUA =========================

    ["watergun"] = {
        label = "Pistola de Agua",
        weight = 15,
        stack = true,
        close = true,
        description = "",
        client = { image = "watergun.png" }
    },


    -- ========================= Pinturas coche Exclusivas =========================

    ["magen_oran_flip"] = {
        label = "Pintura 69",
        weight = 5,
        stack = true,
        close = true,
        description = "Magenta Orange Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["anod_purple"] = {
        label = "Pintura 48",
        weight = 5,
        stack = true,
        close = true,
        description = "Anod Purple",
        client = {
            image = "exoticspray.png",
        }
    },
    ["orang_purp_flip"] = {
        label = "Pintura 36",
        weight = 5,
        stack = true,
        close = true,
        description = "Orange Purple Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["magen_gree_flip"] = {
        label = "Pintura 13",
        weight = 200,
        stack = true,
        close = true,
        description = "Magenta Green Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["black_holo"] = {
        label = "Pintura 17",
        weight = 200,
        stack = true,
        close = true,
        description = "Black Holographic",
        client = {
            image = "exoticspray.png",
        }
    },
    ["pink_pearl"] = {
        label = "Pintura 74",
        weight = 5,
        stack = true,
        close = true,
        description = "Pink Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["anod_copper"] = {
        label = "Pintura 55",
        weight = 5,
        stack = true,
        close = true,
        description = "Anod Copper",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_the_seven"] = {
        label = "Pintura 64",
        weight = 5,
        stack = true,
        close = true,
        description = "Ykta The Seven",
        client = {
            image = "exoticspray.png",
        }
    },
    ["anod_champagne"] = {
        label = "Pintura 50",
        weight = 5,
        stack = true,
        close = true,
        description = "Anod Champagne",
        client = {
            image = "exoticspray.png",
        }
    },
    ["green_prisma"] = {
        label = "Pintura 75",
        weight = 5,
        stack = true,
        close = true,
        description = "Green Prismatic",
        client = {
            image = "exoticspray.png",
        }
    },
    ["yellow_pearl"] = {
        label = "Pintura 1",
        weight = 5,
        stack = true,
        close = true,
        description = "Yellow Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_bubblegum"] = {
        label = "Pintura 56",
        weight = 200,
        stack = true,
        close = true,
        description = "Ykta Bubblegum",
        client = {
            image = "exoticspray.png",
        }
    },
    ["orang_blue_flip"] = {
        label = "Pintura 52",
        weight = 200,
        stack = true,
        close = true,
        description = "Orange Blue Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["turq_red_flip"] = {
        label = "Pintura 9",
        weight = 200,
        stack = true,
        close = true,
        description = "Turquoise Red Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["darkblueprisma"] = {
        label = "Pintura 26",
        weight = 5,
        stack = true,
        close = true,
        description = "Dark Blue Prismatic",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_fubuki"] = {
        label = "Pintura 68",
        weight = 5,
        stack = true,
        close = true,
        description = "Ykta Fubuki",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_full_rbow"] = {
        label = "Pintura 58",
        weight = 200,
        stack = true,
        close = true,
        description = "Ykta Full Rainbow",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_vice_city"] = {
        label = "Pintura 70",
        weight = 200,
        stack = true,
        close = true,
        description = "Ykta Vice City",
        client = {
            image = "exoticspray.png",
        }
    },
    ["hot_pink_prisma"] = {
        label = "Pintura 4",
        weight = 200,
        stack = true,
        close = true,
        description = "Hot Pink Prismatic",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_synthwave"] = {
        label = "Pintura 38",
        weight = 200,
        stack = true,
        close = true,
        description = "Ykta Synthwave",
        client = {
            image = "exoticspray.png",
        }
    },
    ["lit_purp_pearl"] = {
        label = "Pintura 24",
        weight = 5,
        stack = true,
        close = true,
        description = "Luminous Purple Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_electro"] = {
        label = "Pintura 62",
        weight = 5,
        stack = true,
        close = true,
        description = "Ykta Electro",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_chromabera"] = {
        label = "Pintura 18",
        weight = 200,
        stack = true,
        close = true,
        description = "Ykta ChromaBera",
        client = {
            image = "exoticspray.png",
        }
    },
    ["blue_green_flip"] = {
        label = "Pintura 31",
        weight = 5,
        stack = true,
        close = true,
        description = "Blue Green Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_four_seaso"] = {
        label = "Pintura 78",
        weight = 5,
        stack = true,
        close = true,
        description = "Ykta Four Seasons",
        client = {
            image = "exoticspray.png",
        }
    },
    ["green_blue_flip"] = {
        label = "Pintura 65",
        weight = 5,
        stack = true,
        close = true,
        description = "Green Blue Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["darktealpearl"] = {
        label = "Pintura 15",
        weight = 200,
        stack = true,
        close = true,
        description = "Dark Teal Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["blu_rainbo_flip"] = {
        label = "Pintura 71",
        weight = 200,
        stack = true,
        close = true,
        description = "Blue Rainbow Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["rainbow_prisma"] = {
        label = "Pintura 19",
        weight = 200,
        stack = true,
        close = true,
        description = "Rainbow Prismatic",
        client = {
            image = "exoticspray.png",
        }
    },
    ["darkpurpprisma"] = {
        label = "Pintura 67",
        weight = 5,
        stack = true,
        close = true,
        description = "Dark Purple Prismatic",
        client = {
            image = "exoticspray.png",
        }
    },
    ["coppe_purp_flip"] = {
        label = "Pintura 28",
        weight = 5,
        stack = true,
        close = true,
        description = "Copper Purple Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_nite_day"] = {
        label = "Pintura 77",
        weight = 200,
        stack = true,
        close = true,
        description = "Ykta Nite & Day",
        client = {
            image = "exoticspray.png",
        }
    },
    ["lit_pink_pearl"] = {
        label = "Pintura 80",
        weight = 200,
        stack = true,
        close = true,
        description = "Luminous Pink Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["red_rainbo_flip"] = {
        label = "Pintura 60",
        weight = 200,
        stack = true,
        close = true,
        description = "Red Rainbow Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["purp_red_flip"] = {
        label = "Pintura 11",
        weight = 5,
        stack = true,
        close = true,
        description = "Purple Red Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["lit_blue_pearl"] = {
        label = "Pintura 51",
        weight = 5,
        stack = true,
        close = true,
        description = "Luminous Blue Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_verlierer2"] = {
        label = "Pintura 44",
        weight = 5,
        stack = true,
        close = true,
        description = "Ykta Verlierer II",
        client = {
            image = "exoticspray.png",
        }
    },
    ["anod_lime"] = {
        label = "Pintura 46",
        weight = 5,
        stack = true,
        close = true,
        description = "Anod Lime",
        client = {
            image = "exoticspray.png",
        }
    },
    ["white_purp_flip"] = {
        label = "Pintura 66",
        weight = 5,
        stack = true,
        close = true,
        description = "White Purple Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["anod_wine"] = {
        label = "Pintura 20",
        weight = 5,
        stack = true,
        close = true,
        description = "Anod Wine",
        client = {
            image = "exoticspray.png",
        }
    },
    ["purp_green_flip"] = {
        label = "Pintura 41",
        weight = 200,
        stack = true,
        close = true,
        description = "Purple Green Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_monika"] = {
        label = "Pintura 42",
        weight = 200,
        stack = true,
        close = true,
        description = "Ykta Monika",
        client = {
            image = "exoticspray.png",
        }
    },
    ["anod_green"] = {
        label = "Pintura 32",
        weight = 5,
        stack = true,
        close = true,
        description = "Anod Green",
        client = {
            image = "exoticspray.png",
        }
    },
    ["green_turq_flip"] = {
        label = "Pintura 72",
        weight = 200,
        stack = true,
        close = true,
        description = "Green Turquoise Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["cream_pearl"] = {
        label = "Pintura 16",
        weight = 200,
        stack = true,
        close = true,
        description = "Cream Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_kamenrider"] = {
        label = "Pintura 35",
        weight = 200,
        stack = true,
        close = true,
        description = "Ykta Kamen Rider",
        client = {
            image = "exoticspray.png",
        }
    },
    ["magen_yell_flip"] = {
        label = "Pintura 43",
        weight = 200,
        stack = true,
        close = true,
        description = "Magenta Yellow Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_m9_throwba"] = {
        label = "Pintura 45",
        weight = 5,
        stack = true,
        close = true,
        description = "Ykta M9 Throwback",
        client = {
            image = "exoticspray.png",
        }
    },
    ["anod_gold"] = {
        label = "Pintura 47",
        weight = 5,
        stack = true,
        close = true,
        description = "Anod Gold",
        client = {
            image = "exoticspray.png",
        }
    },
    ["anod_bronze"] = {
        label = "Pintura 59",
        weight = 5,
        stack = true,
        close = true,
        description = "Anod Bronze",
        client = {
            image = "exoticspray.png",
        }
    },
    ["blue_pink_flip"] = {
        label = "Pintura 10",
        weight = 200,
        stack = true,
        close = true,
        description = "Blue Pink Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["lit_green_pearl"] = {
        label = "Pintura 25",
        weight = 200,
        stack = true,
        close = true,
        description = "Luminous Green Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_sunsets"] = {
        label = "Pintura 61",
        weight = 5,
        stack = true,
        close = true,
        description = "Ykta Sunsets",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_temperatur"] = {
        label = "Pintura 22",
        weight = 5,
        stack = true,
        close = true,
        description = "Ykta Temperature",
        client = {
            image = "exoticspray.png",
        }
    },
    ["white_prisma"] = {
        label = "Pintura 2",
        weight = 5,
        stack = true,
        close = true,
        description = "White Prismatic",
        client = {
            image = "exoticspray.png",
        }
    },
    ["turq_purp_flip"] = {
        label = "Pintura 73",
        weight = 200,
        stack = true,
        close = true,
        description = "Turquoise Purple Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["green_brow_flip"] = {
        label = "Pintura 7",
        weight = 200,
        stack = true,
        close = true,
        description = "Green Brown Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["red_prisma"] = {
        label = "Pintura 33",
        weight = 5,
        stack = true,
        close = true,
        description = "Red Prismatic",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_christmas"] = {
        label = "Pintura 79",
        weight = 200,
        stack = true,
        close = true,
        description = "Ykta Christmas",
        client = {
            image = "exoticspray.png",
        }
    },
    ["cyan_purp_flip"] = {
        label = "Pintura 40",
        weight = 200,
        stack = true,
        close = true,
        description = "Cyan Purple Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["teal_purp_flip"] = {
        label = "Pintura 21",
        weight = 200,
        stack = true,
        close = true,
        description = "Teal Purple Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["darkgreenpearl"] = {
        label = "Pintura 39",
        weight = 5,
        stack = true,
        close = true,
        description = "Dark Green Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["blue_pearl"] = {
        label = "Pintura 5",
        weight = 200,
        stack = true,
        close = true,
        description = "Blue Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["anod_red"] = {
        label = "Pintura 82",
        weight = 200,
        stack = true,
        close = true,
        description = "Anod Red",
        client = {
            image = "exoticspray.png",
        }
    },
    ["anod_blue"] = {
        label = "Pintura 30",
        weight = 5,
        stack = true,
        close = true,
        description = "Anod Blue",
        client = {
            image = "exoticspray.png",
        }
    },
    ["green_purp_flip"] = {
        label = "Pintura 27",
        weight = 200,
        stack = true,
        close = true,
        description = "Green Purple Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["oil_slic_prisma"] = {
        label = "Pintura 76",
        weight = 5,
        stack = true,
        close = true,
        description = "Oil Slick Prismatic",
        client = {
            image = "exoticspray.png",
        }
    },
    ["darkbluepearl"] = {
        label = "Pintura 54",
        weight = 5,
        stack = true,
        close = true,
        description = "Dark Blue Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["darkpurplepearl"] = {
        label = "Pintura 29",
        weight = 200,
        stack = true,
        close = true,
        description = "Dark Purple Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["magen_cyan_flip"] = {
        label = "Pintura 53",
        weight = 200,
        stack = true,
        close = true,
        description = "Magenta Cyan Flip",
        client = {
            image = "exoticspray.png",
        }
    },


    ["red_orangeflip"] = {
        label = "Pintura 12",
        weight = 200,
        stack = true,
        close = true,
        description = "Red Orange Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["green_red_flip"] = {
        label = "Pintura 8",
        weight = 200,
        stack = true,
        close = true,
        description = "Green Red Flip",
        client = {
            image = "exoticspray.png",
        }
    },
    ["green_pearl"] = {
        label = "Pintura 81",
        weight = 200,
        stack = true,
        close = true,
        description = "Green Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["black_prisma"] = {
        label = "Pintura 49",
        weight = 5,
        stack = true,
        close = true,
        description = "Black Prismatic",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_monochrome"] = {
        label = "Pintura 63",
        weight = 5,
        stack = true,
        close = true,
        description = "Ykta Monochrome",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_hsw"] = {
        label = "Pintura 6",
        weight = 5,
        stack = true,
        close = true,
        description = "Ykta HSW",
        client = {
            image = "exoticspray.png",
        }
    },
    ["oil_slick_pearl"] = {
        label = "Pintura 37",
        weight = 5,
        stack = true,
        close = true,
        description = "Oil Slick Pearl",
        client = {
            image = "exoticspray.png",
        }
    },
    ["white_holo"] = {
        label = "Pintura 23",
        weight = 200,
        stack = true,
        close = true,
        description = "White Holographic",
        client = {
            image = "exoticspray.png",
        }
    },
    ["graphite_prisma"] = {
        label = "Pintura 14",
        weight = 200,
        stack = true,
        close = true,
        description = "Graphite Prismatic",
        client = {
            image = "exoticspray.png",
        }
    },
    ["ykta_sprunk_ex"] = {
        label = "Pintura 57",
        weight = 5,
        stack = true,
        close = true,
        description = "Ykta Sprunk Ex",
        client = {
            image = "exoticspray.png",
        }
    },
    ["burg_green_flip"] = {
        label = "Pintura 3",
        weight = 200,
        stack = true,
        close = true,
        description = "Burgundy Green Flip",
        client = {
            image = "exoticspray.png",
        }
    },



    -- ========================= MATERIALES RECICLADORA ==========================


    ['scrapmetal'] = {
        label = 'Chatarra metálica',
        weight = 80,
    },


    ["plastic"] = {
        label = "Plastico",
        weight = 15,
        stack = true,
        close = true
    },


    ["aluminum"] = {
        label = "Aluminio",
        weight = 100,
        stack = true,
        close = true
    },


    ["glass"] = {
        label = "Cristal",
        weight = 100,
        stack = true,
        close = true
    },


    ["copper"] = {
        label = "Cobre",
        weight = 100,
        stack = true,
        close = false,
        description = "Una buena pieza de metal que probablemente puedas usar para algo.",
        client = {
            image = "copper.png",
        }
    },
    ["steel"] = {
        label = "Acero",
        weight = 100,
        stack = true,
        close = false,
        description = "Una buena pieza de metal que probablemente puedas usar para algo.",
        client = {
            image = "steel.png",
        }
    },

    ["coffee"] = {
        label = "Cafe vacio",
        weight = 200,
        stack = true,
        close = true,
        description = "Café vacio",
        client = {
            image = "coffee.png",
        }
    },

    ["rubber"] = {
        label = "Goma",
        weight = 100,
        stack = true,
        close = false,
        description = "Goma. Creo que hasta podrías hacer tu propio patito de goma con ella :D",
        client = {
            image = "rubber.png",
        }
    },
    ["iron"] = {
        label = "Hierro",
        weight = 100,
        stack = true,
        close = false,
        description = "Una útil pieza de metal que probablemente puedas usar para algo.",
        client = {
            image = "iron.png",
        }
    },

    ["rolling_paper"] = {
        label = "Papel de liar",
        weight = 10,
        stack = true,
        close = true,
        description = "Papel hecho exclusivamente para enrollarse un porro.",
        client = {
            image = "rolling_paper.png",
        }
    },

    ["lighter"] = {
        label = "Mechero",
        weight = 10,
        stack = true,
        close = true,
        description = "Perfecto para encender algo cuando lo necesites.",
        client = {
            image = "lighter1.png",
        }
    },

    ['packaging_station'] = {
        label = 'Estacion de empaquetado',
        weight = 1,
        stack = false,
        close = false,
        description = 'Una mesa de trabajo preparada para empaquetar y organizar distintos productos.'
    },

    ['drying_rack'] = {
        label = 'Estante de secado',
        weight = 1,
        stack = false,
        close = false,
        description = 'Una estructura pensada para secar materiales o sustancias de forma ordenada.'
    },

    ['drug_mixer'] = {
        label = 'Mezcladora quimica',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un aparato de laboratorio usado para mezclar compuestos y sustancias.'
    },

    ['drug_cauldron'] = {
        label = 'Caldero quimico',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un recipiente grande utilizado para calentar y preparar mezclas quimicas.'
    },

    ['drug_oven'] = {
        label = 'Horno quimico',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un horno especializado para procesar sustancias mediante calor controlado.'
    },

    ['chemistry_station'] = {
        label = 'Estacion de quimica',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un puesto de trabajo equipado para realizar procesos y preparaciones quimicas.'
    },

    ['pills'] = {
        label = 'Pastillas',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un conjunto de pastillas preparadas para su almacenamiento o distribucion.'
    },



    -- ================= RECOMPENSAS ROBOS =======================

    ["10kgoldchain"] = {
        label = "Cadena de oro de 10 quilates",
        weight = 200,
        stack = true,
        close = true,
        description = "Cadena de oro de 10 quilates.",
        client = {
            image = "10kgoldchain.png",
        }
    },

    ["kuz_watch"] = {
        label = "Reloj Caro",
        weight = 3,
        stack = true,
        close = false,
        modelp = 'prop_jewel_02a',
        description = "Caro y unico",
        client = {
            image = "kuz_watch.png",
        }
    },

    ["diamond_ring"] = {
        label = "Anillo de Diamante",
        weight = 3,
        stack = true,
        modelp = 'prop_jewel_04b',
        close = true,
        description = "Un anillo de diamantes me parece el premio mayor!",
        client = {
            image = "diamond_ring.png",
        }
    },

    ["virus"] = {
        label = "Virus de Humane",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Un desarollo biologico, aun en proceso un virus muy potente desarollado por indrustrias Humane, aun no se ha encontrado su contraparte por lo que abrirlo podria llegar a ser muy peligroso.",
        client = {
            image = "virus.png",
        },
        modelp = "p_cs_duffel_01_s",
    },

    ["diamondring"] = {
        label = "Anillo de Diamantes",
        weight = 300,
        stack = true,
        close = true,
        description = "Preciosa Joya",
        client = {
            image = "diamondring.png",
        }
    },
    ["tvantiguacasa"] = {
        label = "Tv Antigua",
        weight = 300,
        stack = false,
        close = true,
        description = "Tv de la epoca de mi abuela",
        client = {
            image = "tvantigua.png",
        },
        modelp = 'v_res_cctv',
    },
    ["portatilcasa"] = {
        label = "Portátil",
        weight = 200,
        stack = true,
        close = true,
        description = "Portátil",
        modelp = 'prop_laptop_01a',
    },
    ["cajadezapatos"] = {
        label = "Caja de Zapatos",
        weight = 300,
        stack = true,
        close = true,
        description = "Caja de zapatos de segunda mano",
        client = {
            image = "cajadezapatos.png",
        },
        modelp = 'prop_cs_box_clothes',
    },
    ["altavocezchinoscasa"] = {
        label = "Altavoces Chinos",
        weight = 300,
        stack = false,
        close = true,
        description = "Altavocez replica exacta",
        client = {
            image = "altavocezchinos.png",
        },
        modelp = 'prop_mp3_dock',
    },
    ["joyasbaratas"] = {
        label = "Joyas Baratas",
        weight = 300,
        stack = true,
        close = true,
        description = "Joya Barata",
        client = {
            image = "joyasbaratas.png",
        }
    },
    ["champagne_dorado"] = {
        label = "Champagne Dorado",
        weight = 300,
        stack = true,
        close = true,
        description = "Champagne Dorado",
        client = {
            image = "champagnedorado.png",
        }
    },
    ["camaraderollo"] = {
        label = "Camara Antigua",
        weight = 300,
        stack = false,
        close = true,
        description = "Camara de 1980",
        client = {
            image = "camaraderollo.png",
        },
        modelp = 'v_ret_ta_camera',
    },
    ["maletinbaratocasa"] = {
        label = "Maletin Barato",
        weight = 300,
        stack = false,
        close = true,
        description = "Guarda y organiza todo aqui",
        client = {
            image = "maletin_barato.png",
        },
        modelp = 'ch_prop_ch_case_01a',
    },
    ["tvplasmacasa"] = {
        label = "Tv de Plasma",
        weight = 300,
        stack = false,
        close = true,
        description = "Tv gigante de 38 pulgadas",
        client = {
            image = "tvplasma.png",
        },
        modelp = 'prop_trev_tv_01',
    },
    ["tvfina"] = {
        label = "Tv de Plasma",
        weight = 300,
        stack = false,
        close = true,
        description = "Tv gigante de 38 pulgadas",
        client = {
            image = "tvfina.png",
        },
        modelp = 'prop_trev_tv_01',
    },
    ["podadora"] = {
        label = "Podadora",
        weight = 300,
        stack = false,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "podadora.png",
        }
    },
    ["lavadoracasa"] = {
        label = "Lavadora",
        weight = 300,
        stack = false,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "lavadora.png",
        }
    },
    ["focouv"] = {
        label = "Focos UV",
        weight = 300,
        stack = false,
        close = true,
        description = "Un buen foco para casa",
        client = {
            image = "focouv.png",
        }
    },
    ["cafeteracasa"] = {
        label = "Cafetera",
        weight = 300,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "cafetera.png",
        },
        modelp = 'apa_mp_h_acc_coffeemachine_01',
    },

    ["planchacasa"] = {
        label = "Placha",
        weight = 300,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "plancha.png",
        },
        modelp = 'apa_mp_h_acc_coffeemachine_01',
    },

    ["bateriacochecasa"] = {
        label = "Bateria de coche",
        weight = 300,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "bateriacoche.png",
        },
    },

    ["calentadoraguacasa"] = {
        label = "Calentador Agua",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "calentadoragua.png",
        },
        modelp = 'prop_cs_kettle_01',
    },
    ["tostadoracasa"] = {
        label = "Tostadora de pan",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "tostadora.png",
        },
        modelp = 'prop_toaster_02',
    },
    ["secadorpelocasa"] = {
        label = "Secador de pelo",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "secadorpelo.png",
        },
        modelp = 'v_club_vuhairdryer',
    },
    ["ventiladorcasa"] = {
        label = "Ventilador",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "ventilador.png",
        },
    },
    ["cadenadeoro"] = {
        label = "Cadena de Oro",
        weight = 3,
        stack = true,
        close = true,
        description = "Lo mejor en el mercado",
        client = {
            image = "cadenadeoro.png",
        },
        modelp = 'p_csbporndudes_necklace_s',

    },
    ["cadenadeplata"] = {
        label = "Cadena de Plata",
        weight = 3,
        stack = true,
        close = true,
        description = "Lo mejor en el mercado",
        client = {
            image = "cadenadeplata.png",
        },
        modelp = 'p_stretch_necklace_s',
    },
    ["cadenadediamantes"] = {
        label = "Cadena de Diamantes",
        weight = 3,
        stack = true,
        close = true,
        description = "Lo mejor en el mercado",
        client = {
            image = "cadenadediamantes.png",
        },
        modelp = 'p_jewel_necklace02_s',
    },
    ["relojdediamantes"] = {
        label = "Reloj de Diamantes",
        weight = 3,
        stack = true,
        close = true,
        modelp = 'prop_jewel_02b',
        description = "Lo mejor en el mercado",
        client = {
            image = "relojdediamantes.png",
        }
    },
    ["aspirina"] = {
        label = "Aspirina",
        weight = 3,
        stack = true,
        close = true,
        description = "Solo por receta medica",
        client = {
            image = "aspirina.png",
        },
        modelp = 'ex_office_swag_pills2',
    },
    ["usb"] = {
        label = "USB",
        weight = 3,
        stack = true,
        close = true,
        description = "Lo mejor en el mercado",
        client = {
            image = "usb.png",
        }
    },
    ["usbhackeo"] = {
        label = "USB Hackeo",
        weight = 3,
        stack = true,
        close = true,
        description = "Clasificado",
        client = {
            image = "usbhackeo.png",
        }
    },
    ["usbtroya"] = {
        label = "USB Troya",
        weight = 3,
        stack = true,
        close = true,
        description = "Clasificado",
        client = {
            image = "usbtroya.png",
        }
    },
    ["bolsabasura"] = {
        label = "Bolsa de Basura",
        weight = 3,
        stack = true,
        close = true,
        description = "Todo cabe aqui",
        client = {
            image = "bolsabasura.png",
        },
        modelp = 'prop_ld_binbag_01',
    },
    ["arosplata"] = {
        label = "Aros de Plata",
        weight = 3,
        stack = true,
        close = true,
        description = "Lo mejor en el mercado",
        client = {
            image = "arosplata.png",
        }
    },
    ["anilloro"] = {
        label = "Anillo de Oro",
        weight = 3,
        stack = true,
        close = true,
        description = "Lo mejor en el mercado",
        client = {
            image = "anilloro.png",
        }
    },

    ["tvremote"] = {
        label = "Mando de TV",
        weight = 3,
        stack = true,
        close = true,
        description = "Mando a distancia para televisión.",
        client = {
            image = "tvremote.png",
        },
        modep = "v_res_tre_remote"
    },
    ["vehicletv"] = {
        label = "Mando de TV",
        weight = 3,
        stack = true,
        close = true,
        description = "Mando a distancia para televisión.",
        client = {
            image = "vehicletv.png",
        },
        modep = "v_res_tre_remote"
    },
    ["lamparacasa"] = {
        label = "Lampara",
        weight = 3,
        stack = true,
        close = true,
        client = {
            image = "lampara.png",
        }
    },
    ["retratodefoto"] = {
        label = "Retrato Fotogratico",
        weight = 3,
        stack = true,
        close = true,
        client = {
            image = "retratodefoto.png",
        }
    },
    ["cajavacia"] = {
        label = "Caja Vacia",
        weight = 3,
        stack = true,
        close = true,
        description = "No encontraras nada",
        client = {
            image = "cajavacia.png",
        }
    },
    ["retratofotogratico"] = {
        label = "Retrato Fotogratico",
        weight = 3,
        stack = true,
        close = true,
        client = {
            image = "encendedorvacio.png",
        }
    },
    ["tazarota"] = {
        label = "Taza Rota",
        weight = 3,
        stack = true,
        close = true,
        description = "Objeto Inutil",
        client = {
            image = "tazarota.png",
        }
    },
    ["cenicero"] = {
        label = "Cenicero",
        weight = 3,
        stack = true,
        close = true,
        client = {
            image = "cenicero.png",
        }
    },
    ["perfumecaro"] = {
        label = "Perfume Caro",
        weight = 3,
        stack = true,
        close = true,
        client = {
            image = "perfumecaro.png",
        }
    },
    ["perfumebarato"] = {
        label = "Perfume Barato",
        weight = 3,
        stack = true,
        close = true,
        description = "Objeto Inutil",
        client = {
            image = "perfumebarato.png",
        }
    },
    ["camaradevideoprogramatv"] = {
        label = "Televisor muy antiguo",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu programa",
        client = {
            image = "camaradevideoprogramatv.png",
        }
    },
    ["liquadoradealimentoscasa"] = {
        label = "Procesador de alimentos",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "liquadoradealimentos.png",
        }
    },
    ["microondascasa"] = {
        label = "Microondas",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "microondascasa.png",
        }
    },
    ["tvmuyantiguacasa"] = {
        label = "Televisor muy antiguo",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "tvmuyantigua.png",
        }
    },
    ["microscopiolabotario"] = {
        label = "Microscopio grande",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu laboratorio",
        client = {
            image = "microscopiolabotario.png",
        }
    },
    ["boomboxretro"] = {
        label = "Boombox de los antiguos",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "boomboxretro.png",
        }
    },
    ["radiocassete"] = {
        label = "Radio de las antiguas",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "radiocassete.png",
        }
    },
    ["maquinadegranizados"] = {
        label = "Maquina Granizados",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "maquinadegranizados.png",
        }
    },
    ["exprimidordezumo"] = {
        label = "Exprimidor de fruta",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "exprimidordezumo.png",
        }
    },
    ["maquinadedvd"] = {
        label = "Maquina de video",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "maquinadedvd.png",
        }
    },
    ["telefonofijodecasa"] = {
        label = "Telefono fijo",
        weight = 3,
        stack = true,
        close = true,
        description = "Una buena maquina para tu casa",
        client = {
            image = "telefonofijodecasa.png",
        }
    },

    --- PINTURAS

    ["cuadrofirmado"] = {
        label = "Cuadro Firmado de autor",
        weight = 350,
        stack = true,
        close = true,
        description = "Un cuadro normalito con firma pero algo de dinero vale",
        client = {
            image = "cuadrofirmado.png",
        },
        modelp = 'h4_prop_h4_painting_01e',
    },
    ["paintingh"] = {
        label = "Pintura",
        weight = 350,
        stack = true,
        close = true,
        description = "Un cuadro normalito pero algo de dinero vale",
        client = {
            image = "paintingh.png",
        },
        modelp = 'h4_prop_h4_painting_01e',
    },
    ["paintingg"] = {
        label = "Pintura",
        weight = 350,
        stack = true,
        close = true,
        description = "Un cuadro normalito pero algo de dinero vale",
        client = {
            image = "paintingg.png",
        },
        modelp = 'h4_prop_h4_painting_01d',
    },
    ["paintingj"] = {
        label = "Pintura",
        weight = 350,
        stack = true,
        close = true,
        description = "Un cuadro normalito pero algo de dinero vale",
        client = {
            image = "paintingj.png",
        },
        modelp = 'h4_prop_h4_painting_01b',
    },
    ["paintingf"] = {
        label = "Pintura",
        weight = 350,
        stack = true,
        close = true,
        description = "Un cuadro normalito pero algo de dinero vale",
        client = {
            image = "paintingf.png",
        },
        modelp = 'ch_prop_vault_painting_01j',
    },

    -- ========================================= PUG ROBBERY =========================================

    ["gasmask"] = {
        label = "Máscara de gas",
        weight = 100,
        stack = true,
        close = true,
        description = "Útil para evitar morir entre gases.",
    },
    ["ropehook"] = {
        label = "Cuerda con gancho",
        weight = 100,
        stack = true,
        close = true,
        description = "Una cuerda larga con un gancho.",

    },
    ["paintingart"] = {
        label = "Pintura artística",
        weight = 500,
        stack = true,
        close = true,
        description = "Una impresionante pieza de arte moderno.",

    },
    ["paintingcity"] = {
        label = "Pintura de ciudad",
        weight = 500,
        stack = true,
        close = true,
        description = "Una representación de una concurrida plaza de la ciudad.",

    },
    ["paintingclown"] = {
        label = "Pintura de payaso",
        weight = 500,
        stack = true,
        close = true,
        description = "Un retrato de payaso colorido e inquietante.",

    },
    ["paintingfamily"] = {
        label = "Pintura familiar",
        weight = 500,
        stack = true,
        close = true,
        description = "Una pintura nostálgica de una reunión familiar.",

    },
    ["paintingguys"] = {
        label = "Pintura de caballeros",
        weight = 500,
        stack = true,
        close = true,
        description = "Una pintura de dos caballeros conversando.",

    },
    ["paintinglady"] = {
        label = "Pintura de dama",
        weight = 500,
        stack = true,
        close = true,
        description = "Un elegante retrato de una dama.",

    },
    ["paintingnative"] = {
        label = "Pintura indígena",
        weight = 500,
        stack = true,
        close = true,
        description = "Una pintura de una figura indígena sosteniendo una máscara.",

    },
    ["paintingpaddle"] = {
        label = "Pintura con paletas",
        weight = 500,
        stack = true,
        close = true,
        description = "Una pintura alegre con globos y paletas.",
        client = {
            image = "paintingpaddle.png",
        }
    },
    ["paintingpig"] = {
        label = "Pintura de cerdo",
        weight = 500,
        stack = true,
        close = true,
        description = "¿Parece un cerdo caro, no?",

    },
    ----------------------------------------------
    ["paintingrocket"] = {
        label = "Pintura de cohete",
        weight = 500,
        stack = true,
        close = true,
        description = "Una pintura abstracta de un cohete.",

    },


    ["diamondnecklace"] = {
        label = "Cadena de Diamantes",
        weight = 3,
        stack = true,
        close = true,
        description = "Lo mejor en el mercado",
        client = {
            image = "cadenadediamantes.png",
        },
        modelp = 'p_jewel_necklace02_s',
    },

    ["goldbarstack"] = {
        label = "Montón de lingotes de oro",
        weight = 200,
        stack = true,
        close = true,
        description = "Un montón de lingotes de oro.",
        client = {
            image = "goldbarstack.png",
        }
    },

    ["goldwatch"] = {
        label = "Reloj de alta gama",
        weight = 15,
        stack = true,
        close = true,
        description = "Uno de los relojes mas caros en el planeta.",
        modelp = 'prop_jewel_02c',
    },

    ["purpleusb"] = {
        label = "USB morado",
        weight = 10,
        stack = true,
        close = true,
        description = "Una misteriosa memoria USB morada.",
        client = {
            image = "purpleusb.png",
        }
    },

    ["salvagedlockpick"] = {
        label = "Ganzúa recuperada",
        weight = 5,
        stack = true,
        close = true,
        description = "Una ganzúa recuperada y bastante desgastada.",
        client = {
            image = "salvagedlockpick.png",
        }
    },
    ["silverring"] = {
        label = "Anillo de Plata",
        weight = 3,
        stack = true,
        close = true,
        description = "Lo mejor en el mercado",
        client = {
            image = "silverring.png",
        }
    },

    ["unmarkedsimcard"] = {
        label = "Tarjeta SIM sin marcar",
        weight = 5,
        stack = true,
        close = true,
        description = "Una tarjeta SIM sin marcar; podría servir para algo.",
        client = {
            image = "unmarkedsimcard.png",
        }
    },

    ["bandsofnotes"] = {
        label = "Fajos de billetes",
        weight = 10,
        stack = true,
        close = true,
        description = "Un fajo de billetes de alto valor; podría valer bastante.",
        client = { image = "bandsofnotes.png" }
    },
    ["bankcard"] = {
        label = "Tarjeta bancaria",
        weight = 5,
        stack = true,
        close = true,
        description = "Una tarjeta bancaria estándar para transacciones.",
        client = { image = "bankcard.png" }
    },
    ["group6card"] = {
        label = "Tarjeta de seguridad Group 6",
        weight = 5,
        stack = true,
        close = true,
        description = "Una tarjeta de seguridad de Group 6 que da acceso a zonas restringidas.",
        client = { image = "group6card.png" }
    },
    ["humaneco2"] = {
        label = "Compuesto X2",
        weight = 5,
        stack = true,
        close = true,
        description = "Un Compuesto X2, potencialmente útil para tareas específicas.",
        client = { image = "humaneco2.png" }
    },
    ["paletobankcard"] = {
        label = "Tarjeta del Banco de Paleto",
        weight = 5,
        stack = true,
        close = true,
        description = "Una tarjeta identificativa para empleados del Banco de Paleto.",
        client = { image = "paletobankcard.png" }
    },
    ["stacksofcash"] = {
        label = "Montones de efectivo",
        weight = 15,
        stack = true,
        close = true,
        description = "Un gran montón de efectivo.",
        client = { image = "stacksofcash.png" }
    },
    ["handsaw"] = {
        label = "Serrucho",
        weight = 3,
        stack = true,
        close = true,
        description = "Una sierra manual básica, útil para cortar madera y otros materiales.",
        client = { image = "handsaw.png" }
    },
    ["harddrive"] = {
        label = "Disco duro",
        weight = 1,
        stack = true,
        close = false,
        description = "Un disco duro interno, útil para almacenar datos.",
        client = { image = "harddrive.png" }
    },
    ["silverbar"] = {
        label = "Lingote de plata",
        weight = 5,
        stack = true,
        close = false,
        description = "Un lingote de plata pura, valioso para comerciar y fabricar.",
        client = { image = "silverbar.png" }
    },
    ["wirecutters"] = {
        label = "Corta Alambres",
        weight = 2,
        stack = true,
        close = true,
        description = "Una herramienta para cortar cables, esencial para varias tareas.",
        client = { image = "wirecutters.png" }
    },
    ["pincracker"] = {
        label = "Descifrador de PIN",
        weight = 1,
        stack = true,
        close = true,
        description = "Una herramienta para vulnerar cerraduras con PIN, esencial para ganzueros expertos.",
        client = { image = "pincracker.png" }
    },
    ["bigbankcard"] = {
        label = "Tarjeta Pacific Bank",
        weight = 5,
        stack = true,
        close = true,
        description = "Una tarjeta bancaria que da acceso a servicios bancarios.",
        client = { image = "bigbankcard.png" }
    },

    ["c4"] = {
        label = "Explosivo C4",
        weight = 10,
        stack = true,
        close = true,
        description = "Un potente explosivo, útil para abrir barreras resistentes.",
        client = { image = "c4.png" }
    },
    ["humaneusb"] = {
        label = "USB de Humane Labs",
        weight = 1,
        stack = true,
        close = true,
        description = "Una memoria USB con datos sensibles, propiedad de Humane Labs.",
        client = { image = "humaneusb.png" }
    },
    ["bankidcard"] = {
        label = "Tarjeta ID bancaria",
        weight = 1,
        stack = true,
        close = true,
        description = "Una tarjeta identificativa para empleados del banco, con acceso a ciertas zonas.",
        client = { image = "bankidcard.png" }
    },

    -- PLT PLUTO LABORATORIOS DROGAS

    ['drogacocodrilo'] = {
        label = 'Bolsa de Krokodil',
        weight = 1,
        stack = true,
        description = 'Una bolsa con Krokodil, un potente opiacio. Con graves efectos secundarios'
    },

    ['bolsafentanilo'] = {
        label = 'Bolsa de Fentanilo',
        weight = 1,
        stack = true,
        description = 'Una bolsa con fentanilo, un potente analgésico.'
    },

    ['weed_seed'] = {
        label = 'Semilla de marihuana',
        weight = 40,
        stack = true,
        description = 'Una semilla lista para cultivar una planta de marihuana.'
    },

    ['gingeritis_weed'] = {
        label = 'Marihuana Gingeritis húmeda',
        weight = 110,
        stack = true,
        description = 'Una variedad Gingeritis recién recolectada, todavía húmeda.'
    },

    ['energizing_dried_weed'] = {
        label = 'Marihuana energizante seca',
        weight = 30,
        stack = true,
        description = 'Marihuana seca con efectos estimulantes y energizantes.'
    },

    ['weed'] = {
        label = 'Marihuana húmeda',
        weight = 100,
        stack = true,
        description = 'Marihuana recién cosechada que aún conserva humedad.'
    },

    ['high_quality_weed'] = {
        label = 'Marihuana húmeda de alta calidad',
        weight = 100,
        stack = true,
        description = 'Marihuana húmeda seleccionada por su calidad superior.'
    },

    ['dried_weed'] = {
        label = 'Marihuana seca',
        weight = 20,
        stack = true,
        description = 'Marihuana ya secada y lista para su siguiente proceso.'
    },

    ['dried_high_quality_weed'] = {
        label = 'Marihuana seca de alta calidad',
        weight = 20,
        stack = true,
        description = 'Marihuana seca tratada y clasificada como de alta calidad.'
    },

    ['packaged_gingeritis_weed'] = {
        label = 'Marihuana Gingeritis húmeda empaquetada',
        weight = 110,
        stack = true,
        description = 'Marihuana Gingeritis húmeda preparada y empaquetada.'
    },

    ['packaged_energizing_dried_weed'] = {
        label = 'Marihuana energizante seca empaquetada',
        weight = 40,
        stack = true,
        description = 'Marihuana seca energizante lista para su distribución.'
    },

    ['packaged_weed'] = {
        label = 'Marihuana húmeda empaquetada',
        weight = 110,
        stack = true,
        description = 'Marihuana húmeda empaquetada para almacenamiento o venta.'
    },

    ['packaged_high_quality_weed'] = {
        label = 'Marihuana húmeda de alta calidad empaquetada',
        weight = 110,
        stack = true,
        description = 'Marihuana húmeda premium empaquetada y lista para mover.'
    },

    ['packaged_dried_weed'] = {
        label = 'Marihuana seca empaquetada',
        weight = 30,
        stack = true,
        description = 'Marihuana seca empaquetada y lista para distribución.'
    },

    ['packaged_dried_high_quality_weed'] = {
        label = 'Marihuana seca de alta calidad empaquetada',
        weight = 20,
        stack = true,
        description = 'Marihuana seca premium empaquetada con cuidado.'
    },

    ['coke_seed'] = {
        label = 'Semilla de coca',
        weight = 40,
        stack = true,
        description = 'Una semilla preparada para cultivar una planta de coca.'
    },

    ['coke_leaf'] = {
        label = 'Hoja de coca húmeda',
        weight = 50,
        stack = true,
        description = 'Hoja de coca recién recolectada que aún conserva humedad.'
    },

    ['high_quality_coke_leaf'] = {
        label = 'Hoja de coca húmeda de alta calidad',
        weight = 50,
        stack = true,
        description = 'Hoja de coca húmeda seleccionada por su calidad superior.'
    },

    ['dried_coke_leaf'] = {
        label = 'Hoja de coca seca',
        weight = 10,
        stack = true,
        description = 'Hoja de coca secada y lista para su procesamiento.'
    },

    ['dried_high_quality_coke_leaf'] = {
        label = 'Hoja de coca seca de alta calidad',
        weight = 10,
        stack = true,
        description = 'Hoja de coca seca premium lista para refinar.'
    },

    ['coke'] = {
        label = 'Base de coca húmeda',
        weight = 100,
        stack = true,
        description = 'Una base de coca recién procesada que aún está húmeda.'
    },

    ['high_quality_coke'] = {
        label = 'Base de coca húmeda de alta calidad',
        weight = 100,
        stack = true,
        description = 'Base de coca húmeda refinada con una pureza superior.'
    },

    ['dried_coke'] = {
        label = 'Base de coca seca',
        weight = 20,
        stack = true,
        description = 'Base de coca secada para continuar su preparación.'
    },

    ['dried_high_quality_coke'] = {
        label = 'Base de coca seca de alta calidad',
        weight = 20,
        stack = true,
        description = 'Base de coca seca premium con mejor calidad.'
    },

    ['cooked_coke'] = {
        label = 'Coca húmeda',
        weight = 100,
        stack = true,
        description = 'Coca procesada que aún conserva humedad.'
    },

    ['cooked_high_quality_coke'] = {
        label = 'Coca húmeda de alta calidad',
        weight = 100,
        stack = true,
        description = 'Coca húmeda de calidad superior, recién procesada.'
    },

    ['cooked_dried_coke'] = {
        label = 'Coca seca',
        weight = 20,
        stack = true,
        description = 'Coca seca preparada para empaquetar o distribuir.'
    },

    ['cooked_dried_high_quality_coke'] = {
        label = 'Coca seca de alta calidad',
        weight = 20,
        stack = true,
        description = 'Coca seca premium con un acabado de mayor calidad.'
    },

    ['packaged_coke'] = {
        label = 'Base de coca húmeda empaquetada',
        weight = 100,
        stack = true,
        description = 'Base de coca húmeda guardada y empaquetada.'
    },

    ['packaged_high_quality_coke'] = {
        label = 'Base de coca húmeda de alta calidad empaquetada',
        weight = 100,
        stack = true,
        description = 'Base de coca húmeda premium empaquetada para distribución.'
    },

    ['packaged_dried_coke'] = {
        label = 'Base de coca seca empaquetada',
        weight = 20,
        stack = true,
        description = 'Base de coca seca empaquetada y lista para mover.'
    },

    ['packaged_dried_high_quality_coke'] = {
        label = 'Base de coca seca de alta calidad empaquetada',
        weight = 20,
        stack = true,
        description = 'Base de coca seca premium empaquetada con cuidado.'
    },

    ['packaged_cooked_coke'] = {
        label = 'Coca húmeda empaquetada',
        weight = 100,
        stack = true,
        description = 'Coca húmeda empaquetada para almacenamiento o transporte.'
    },

    ['packaged_cooked_high_quality_coke'] = {
        label = 'Coca húmeda de alta calidad empaquetada',
        weight = 100,
        stack = true,
        description = 'Coca húmeda premium empaquetada y preparada.'
    },

    ['packaged_cooked_dried_coke'] = {
        label = 'Coca seca empaquetada',
        weight = 20,
        stack = true,
        description = 'Coca seca empaquetada lista para distribución.'
    },

    ['packaged_cooked_dried_high_quality_coke'] = {
        label = 'Coca seca de alta calidad empaquetada',
        weight = 20,
        stack = true,
        description = 'Coca seca premium empaquetada y lista para mover.'
    },

    ['liquid_meth'] = {
        label = 'Meta líquida',
        weight = 200,
        stack = true,
        description = 'Una sustancia de metanfetamina en estado líquido.'
    },

    ['default_meth'] = {
        label = 'Cogollo de meta',
        weight = 10,
        stack = true,
        description = 'Una pequeña porción de metanfetamina preparada.'
    },

    ['packaged_default_meth'] = {
        label = 'Meta empaquetada',
        weight = 60,
        stack = true,
        description = 'Metanfetamina empaquetada y lista para distribución.'
    },

    ['weed_brick'] = {
        label = 'Ladrillo de marihuana',
        weight = 400,
        stack = false,
        description = 'Un bloque compacto de marihuana prensada.'
    },

    ['high_quality_weed_brick'] = {
        label = 'Ladrillo de marihuana de alta calidad',
        weight = 400,
        stack = false,
        description = 'Un ladrillo prensado de marihuana premium.'
    },

    ['coke_brick'] = {
        label = 'Ladrillo de base de coca',
        weight = 500,
        stack = false,
        description = 'Un bloque compacto hecho con base de coca.'
    },

    ['high_quality_coke_brick'] = {
        label = 'Ladrillo de base de coca de alta calidad',
        weight = 500,
        stack = false,
        description = 'Un ladrillo premium elaborado con base de coca refinada.'
    },

    ['cooked_coke_brick'] = {
        label = 'Ladrillo de coca',
        weight = 500,
        stack = false,
        description = 'Un bloque compacto de coca ya procesada.'
    },

    ['cooked_high_quality_coke_brick'] = {
        label = 'Ladrillo de coca de alta calidad',
        weight = 500,
        stack = false,
        description = 'Un ladrillo de coca premium con mejor calidad.'
    },

    ['baggy'] = {
        label = 'Bolsita',
        weight = 10,
        stack = true,
        description = 'Una pequeña bolsa útil para empaquetar producto.'
    },

    ['plant_pot'] = {
        label = 'Maceta',
        weight = 100,
        stack = true,
        description = 'Una maceta preparada para cultivar plantas.'
    },

    ['fertilizer'] = {
        label = 'Fertilizante',
        weight = 1000,
        stack = true,
        description = 'Producto usado para mejorar el crecimiento de las plantas.'
    },

    ['default_lamp'] = {
        label = 'Lámpara',
        weight = 500,
        stack = true,
        description = 'Una lámpara pensada para favorecer el cultivo interior.'
    },

    ['default_fan'] = {
        label = 'Ventilador',
        weight = 500,
        stack = true,
        description = 'Un ventilador útil para mantener el flujo de aire en el cultivo.'
    },

    ['default_soil'] = {
        label = 'Tierra',
        weight = 500,
        stack = true,
        description = 'Sustrato básico para plantar y cultivar.'
    },

    ['drying_rack'] = {
        label = 'Estante de secado',
        weight = 500,
        stack = false,
        description = 'Una estructura diseñada para secar plantas y sustancias.'
    },

    ['watering_can'] = {
        label = 'Regadera',
        weight = 500,
        stack = true,
        description = 'Una regadera para hidratar y cuidar las plantas.'
    },

    ['default_brick_press'] = {
        label = 'Prensa de ladrillos',
        weight = 3500,
        stack = false,
        description = 'Una máquina usada para prensar producto en forma de ladrillo.'
    },

    ['packaging_station'] = {
        label = 'Estación de empaquetado',
        weight = 5000,
        stack = false,
        description = 'Un puesto de trabajo preparado para empaquetar productos.'
    },

    ['drug_mixer'] = {
        label = 'Mezcladora química',
        weight = 2000,
        stack = false,
        description = 'Una máquina usada para mezclar compuestos y sustancias.'
    },

    ['plant_trimmers'] = {
        label = 'Tijeras de poda',
        weight = 200,
        stack = true,
        description = 'Herramientas diseñadas para recortar y cuidar plantas.'
    },

    ['drug_cauldron'] = {
        label = 'Caldero químico',
        weight = 5000,
        stack = false,
        description = 'Un gran recipiente utilizado para preparar mezclas químicas.'
    },

    ['drug_oven'] = {
        label = 'Horno de laboratorio',
        weight = 5000,
        stack = false,
        description = 'Un horno especializado para procesar sustancias con calor.'
    },

    ['chemistry_station'] = {
        label = 'Estación de química',
        weight = 5000,
        stack = false,
        description = 'Una mesa de trabajo equipada para procesos químicos.'
    },

    ['acetone'] = {
        label = 'Acetona',
        weight = 500,
        stack = true,
        description = 'Un químico inflamable usado en distintas preparaciones.'
    },

    ['ecola'] = {
        label = 'E-Cola',
        weight = 200,
        stack = true,
        description = 'Un refresco muy conocido que puede usarse en ciertas mezclas.'
    },

    ['pills'] = {
        label = 'Pseudoefedrina',
        weight = 100,
        stack = true,
        description = 'Pastillas con pseudoefedrina usadas como compuesto químico.'
    },

    ['phosphorus'] = {
        label = 'Fósforo',
        weight = 10,
        stack = true,
        description = 'Elemento químico utilizado en diversas preparaciones.'
    },

    ['gunpowder'] = {
        label = 'Pólvora',
        weight = 10,
        stack = true,
        description = 'Elemento químico utilizado en diversas preparaciones.'
    },

    ['gasoline'] = {
        label = 'Gasolina',
        weight = 200,
        stack = true,
        description = 'Combustible inflamable útil para procesos específicos.'
    },

    ['banana'] = {
        label = 'Plátano',
        weight = 100,
        stack = true,
        description = 'Una fruta común que puede servir para mezclas o consumo.'
    },

    ['hammer'] = {
        label = 'Martillo',
        weight = 100,
        stack = true,
        description = 'Una herramienta resistente para golpear o trabajar materiales.'
    },

    -- FARMACIA/HOSPITAL

    ["oxy"] = {
        label = "Oxy",
        weight = 3,
        stack = true,
        close = true,
        description = "Solo con receta medica",
        client = {
            image = "oxy.png",
        },
        modelp = 'prop_cs_pills',
    },
    ["provetas"] = {
        label = "Provetas",
        weight = 3,
        stack = true,
        close = true,
        description = "Solo con receta medica",
        client = {
            image = "provetas.png",
        },
        modelp = 'v_med_flask',
    },
    ["magnesio"] = {
        label = "Magnesio",
        weight = 3,
        stack = true,
        close = true,
        description = "Solo con receta medica",
        client = {
            image = "magnesio.png",
        },
        modelp = 'v_club_vu_pills',
    },
    ["botesdesuero"] = {
        label = "Botes de Suero",
        weight = 3,
        stack = true,
        close = true,
        description = "Solo con receta medica",
        client = {
            image = "botesdesuero.png",
        },
        modelp = 'xm3_prop_xm3_bottle_pills_01a',
    },
    ["sunblock"] = {
        label = "Protector solar",
        weight = 3,
        stack = true,
        close = true,
        description = "Un anillo de diamantes me parece el premio mayor!",
        client = {
            image = "sunblock.png",
        },
        modelp = 'xm3_prop_xm3_bottle_pills_01a',
    },


    ["rubynecklace"] = {
        label = "Cadena de oro blanco y diamantes",
        weight = 150,
        stack = true,
        close = true,
        description = "Cadena de oro y diamantes de 10 quilates. Con cierre artesanal italiano y un Rubi en su corazon.",
        modelp = 'h4_prop_h4_necklace_01a',
    },



    ["goldbracelet"] = {
        label = "Brazalete de oro",
        weight = 50,
        stack = true,
        close = true,
        description =
        "Brazalete de oro con el sello de 18 quilates con diamantes incrustados. Se puede notar que es bastante robusto y tiene buena sujecion.",
        modelp = 'sf_prop_sf_bracelet_01a',
    },

    ["ruedascoche"] = {
        label = "Rueda",
        weight = 100,
        stack = true,
        close = true,
        description = "Una rueda de ¿repuesto?",
    },

    ["richalmilie"] = {
        label = "Reloj de alta gama",
        weight = 15,
        stack = true,
        close = true,
        description = "Uno de los relojes mas caros en el planeta.",
        modelp = 'prop_jewel_02c',
    },

    ["patriciofelipe"] = {
        label = "Reloj de alta gama",
        weight = 15,
        stack = true,
        close = true,
        description = "Uno de los relojes mas caros en el planeta de oro de 18 quilates.",
        modelp = 'prop_jewel_02a',
    },

    ["cadenazarubi"] = {
        label = "Cadena de oro blanco y diamantes",
        weight = 150,
        stack = true,
        close = true,
        description = "Cadena de oro y diamantes de 10 quilates. Con cierre artesanal italiano y un Rubi en su corazon.",
        modelp = 'h4_prop_h4_necklace_01a',
    },

    ["cadenaesmeralda"] = {
        label = "Cadena de oro blanco y diamantes",
        weight = 150,
        stack = true,
        close = true,
        description =
        "Cadena de oro y diamantes de 10 quilates. Con cierre artesanal italiano y una Esmeralda en su corazon.",
        modelp = 'sf_prop_sf_necklace_01a',
    },

    ["brazalete"] = {
        label = "Brazalete",
        weight = 50,
        stack = true,
        close = true,
        description =
        "Brazalete de oro con el sello de 18 quilates. Se puede notar que es bastante robusto y tiene buena sujecion.",
        modelp = 'h4_prop_h4_bracelet_01a',
    },
    ["brazaleteoro"] = {
        label = "Brazalete de oro",
        weight = 50,
        stack = true,
        close = true,
        description =
        "Brazalete de oro con el sello de 18 quilates. Se puede notar que es bastante robusto y tiene buena sujecion.",
        modelp = 'h4_prop_h4_bracelet_01a',
    },
    ["brazaleteoro2"] = {
        label = "Brazalete de oro",
        weight = 50,
        stack = true,
        close = true,
        description =
        "Brazalete de oro con el sello de 18 quilates. Se puede notar que es bastante robusto y tiene buena sujecion.",
        modelp = 'h4_prop_h4_bracelet_01a',
    },

    ["surtidojoyas"] = {
        label = "Surtido Variado joyas",
        weight = 50,
        stack = true,
        close = true,
        description =
        "Un surtido de muchas joyas, relojes, brazaletes, anillos y cadenas. De calidad cuestinable, pero parecen bonitas.",
        modelp = 'ex_office_swag_jewelwatch2',
    },

    ["brazaleteoro2"] = {
        label = "Brazalete de oro",
        weight = 50,
        stack = true,
        close = true,
        description =
        "Brazalete de oro con el sello de 18 quilates con diamantes incrustados. Se puede notar que es bastante robusto y tiene buena sujecion.",
        modelp = 'sf_prop_sf_bracelet_01a',
    },


    ["gemarubi"] = {
        label = "Gema de Rubi",
        weight = 150,
        stack = true,
        close = true,
        description =
        "La piedra preciosa roja más valorada, conocida por su color rojo intenso, que significa rojo en latín.",
        modelp = 'sf_prop_sf_jewel_01a',
    },

    ["transmisioncoche"] = {
        label = "Caja de cambios",
        weight = 500,
        stack = true,
        close = true,
        description = "Una caja de cambios para el coche.",
    },

    ["ruedascoche"] = {
        label = "Rueda",
        weight = 100,
        stack = true,
        close = true,
        description = "Una rueda de ¿repuesto?",
    },

    ["faroscoche"] = {
        label = "Faros de coche",
        weight = 250,
        stack = true,
        close = true,
        description = "Un par de faros para el coche",
    },

    ["turbocoche"] = {
        label = "Turbo de coche",
        weight = 100,
        stack = true,
        close = true,
        description = "Un par de turbos para el coche",
    },

    ["bloquecoche"] = {
        label = "Motor de coche",
        weight = 5000,
        stack = false,
        close = true,
        description = "Puro hierro fundido, el corazon de la bestia",
    },

    ["suspensioncoche"] = {
        label = "Suspension de coche",
        weight = 250,
        stack = true,
        close = true,
        description = "Un par de amortiguadores y suspensiones para el coche",
    },



    -- ========= SAED =================



    ["predictor"] = {
        label = "Predictor ",
        weight = 10,
        stack = true,
        close = true,
        description = "Estamos contigo desde el primer instante.",
        client = {
            image = "predictor.png", },
    },

    ["pastillasanticonceptivas"] = {
        label = "Pastillas anticonceptivas",
        weight = 10,
        stack = true,
        close = true,
        description = "Método anticonceptivo hormonal de administración diaria.",
        client = {
            image = "pastillasanticonceptivas.png", },
    },

    ["preservativossaed"] = {
        label = "Preservativos",
        weight = 10,
        stack = true,
        close = true,
        description = "Responsabilidad que se disfruta.",
        client = {
            image = "preservativossaed.png", },
    },

    ["preservativossaed2"] = {
        label = "Caja de Preservativos",
        weight = 10,
        stack = true,
        close = true,
        description = "Responsabilidad que se disfruta.",
        client = {
            image = "preservativossaed2.png", },
    },

    ['condones'] = {
        label = 'Condones',
        weight = 10,
        stack = true,
        close = true,
        description = 'Más vale prevenir que... criar.',
        client = {
            usetime = 5000,
        }
    },

    ['test_embarazo'] = {
        label = 'Test de Embarazo',
        weight = 50,
        stack = true,
        close = true,
        description = 'Dos rayitas y tu vida cambia para siempre.',
        client = {
            usetime = 5000,
        }
    },

    ['analgesicos'] = {
        label = 'Analgésicos',
        weight = 1,
        stack = true,
        close = true,
        description = 'Para cuando la vida (o la resaca) pega duro.',
    },

    ['ansioliticos'] = {
        label = 'Ansiolíticos',
        weight = 1,
        stack = true,
        close = true,
        description = 'Calmita, calmita, que ya se pasa.',
    },

    ['pastilla_dia_despues'] = {
        label = 'Pastilla del Día Después',
        weight = 20,
        stack = true,
        close = true,
        description = 'El botón de "deshacer" de anoche.',
        client = {
            anim = { dict = 'mp_suicide', clip = 'pill' },
            usetime = 2000,
        }
    },

    -- ========================= AV CAMERAS =================================

    ['gopro'] = {
        label = 'Camara Go',
        weight = 1,
        stack = true,
        close = true,
        description = 'Una camara de expertos'
    },
    ['cam_kit'] = {
        label = 'Kit de camara',
        weight = 1,
        stack = false,
        close = true,
        description = 'Kit de camaras'
    },
    ['cam_battery'] = {
        label = 'Bateria de camaras',
        weight = 1,
        stack = false,
        close = true,
        description = 'Bateria para camaras'
    },
    ['basic_cam'] = {
        label = 'Camara basica',
        weight = 1,
        stack = false,
        close = true,
        description = 'Una camara basica para principiantes'
    },
    ['security_cam'] = {
        label = 'Camara de seguridad',
        weight = 1,
        stack = false,
        close = true,
        description = 'Una camara de seguridad'
    },
    ['server_cam'] = {
        label = 'Camara de server',
        weight = 1,
        stack = false,
        close = true,
        description = 'Una camara con capacidad de replay'
    },


    -- ========================= AV BOOSTING GANGS RACING=====================

    ["tablet"] = {
        label = "Tablet",
        weight = 200,
        stack = true,
        close = true,
        description = "Tablet",
        client = { image = 'tablet.png' },
        modelp = 'prop_cs_tablet_02',
    },

    ["laptop"] = {
        label = "Portátil",
        weight = 200,
        stack = true,
        close = true,
        description = "Portátil",
        modelp = 'prop_laptop_01a',
    },

    ['dongle'] = {
        label = 'USB Dongle',
        weight = 1,
        stack = false,
        close = true,
        client = { image = 'dongle.png' }
    },
    ['vpn'] = {
        label = 'VPN',
        weight = 1,
        stack = true,
        close = false,
        client = { image = 'vpn.png' }
    },
    ['transponder'] = {
        label = 'Transponder',
        weight = 1,
        consume = 0.3,
        stack = true,
        close = true,
        client = { image = 'transponder.png' }

    },

    ["hacking_device"] = {
        label = "Dispositivo Hackeo PC",
        weight = 3,
        stack = true,
        close = true,
        consume = 0.1,
        description = "Herramienta sofisticada",
        client = {
            image = "hackingdevice.png",
        }
    },

    ['boosting_spray'] = {
        label = 'Respray Kit',
        weight = 1,
        consume = 0.3,
        stack = true,
        close = true,
        client = { image = 'boosting_spray.png' }

    },
    ['spraypaint'] = {
        label = 'Bote de Spray',
        weight = 500,
        stack = true,
        close = true,
        description = 'Un spray con un boceto en mano, del grafiti de la organizacion.',
        client = {
            image = "spray.png",
        }
    },

    ['spraycloth'] = {
        label = 'Limpiador de spray',
        weight = 500,
        stack = true,
        close = true,
        description = 'Un spray con un boceto en mano, del grafiti de la organizacion.',
        client = {
            image = "spraycloth.png",
        }
    },

    ['spray'] = {
        label = 'Spray de Territorio',
        weight = 3,
        stack = false,
        close = true,
        description = 'Plasma tu arte',
        client = {
            image = "spraypaint.png",
        },

    },
    ['spray_remover'] = {
        label = 'Limpiador de spray',
        weight = 3,
        stack = false,
        close = true,
        description = 'Dale un buen uso',
        client = {
            image = "spray_remover.png",
        },

    },

    -- Uso por export de servidor (av_runs/server/editable/_framework.lua).
    -- consume = 0 para que no se gaste: sin él, el export fuerza consume = 1.
    ['drug_package'] = {
        label = 'Illegal Package',
        weight = 1,
        stack = false,
        close = false,
        description = 'Marked for police seizure'
    },


    -- ========================= AV MUSIC =======================

    ['cd'] = {
        label = 'CD',
        weight = 1,
        stack = false,
        close = true,
        description = 'Apoya a tu artista local.'
    },
    ['discman'] = {
        label = 'Discman',
        weight = 1,
        stack = false,
        close = true,
        description = 'Reproduce CDs.'
    },
    ['headphones'] = {
        label = 'Auriculares BT',
        weight = 1,
        stack = false,
        close = false,
        description = 'Escucha tu música favorita.'
    },

    -- ================ 0Resmond AMBULANCE ===================


    ['facility_panel'] = {
        label = 'Panel de instalaciones',
        weight = 500,
        stack = false,
        close = false,
        description = 'Un panel portátil para gestionar y diagnosticar sistemas de las instalaciones.'
    },

    ['medbag'] = {
        label = 'Bolsa médica',
        weight = 1000,
        stack = true,
        close = false,
        description = 'Una bolsa con material médico básico para actuar en emergencias.'
    },

    ['bandage_pro'] = {
        label = 'Vendaje',
        weight = 50,
        stack = true,
        close = false,
        description = 'Un vendaje estéril para cubrir heridas y controlar hemorragias leves.'
    },

    ['firstaid'] = {
        label = 'Botiquín de primeros auxilios',
        weight = 300,
        stack = true,
        close = false,
        description = 'Un kit con suministros esenciales para tratar lesiones y estabilizar pacientes.'
    },

    ['syringe'] = {
        label = 'Jeringuilla',
        weight = 20,
        stack = true,
        close = false,
        description = 'Una jeringuilla desechable para administrar medicamentos o extraer muestras.'
    },

    ['blood_sample'] = {
        label = 'Muestra de sangre',
        weight = 30,
        stack = true,
        close = false,
        description = 'Una muestra de sangre extraída para su posterior análisis.',
        unique = true
    },

    ['blood_test_result'] = {
        label = 'Resultado de análisis de sangre',
        weight = 15,
        stack = false,
        close = false,
        description = 'Un informe médico con los resultados de una analítica sanguínea.',
        unique = true
    },

    ['mr_scan_result'] = {
        label = 'Resultado de resonancia magnética',
        weight = 15,
        stack = false,
        close = false,
        description = 'Un informe con los hallazgos obtenidos en una resonancia magnética.',
        unique = true
    },

    ['prescription'] = {
        label = 'Receta médica',
        weight = 15,
        stack = false,
        close = false,
        description = 'Una receta emitida por personal sanitario para un tratamiento o medicación.',
        unique = true
    },

    ['pill_a'] = {
        label = 'Pastilla A',
        weight = 5,
        stack = true,
        close = false,
        description = 'Medicamento de tipo A para tratamientos médicos específicos.'
    },

    ['pill_b'] = {
        label = 'Pastilla B',
        weight = 5,
        stack = true,
        close = false,
        description = 'Medicamento de tipo B para tratamientos médicos específicos.'
    },

    ['pill_c'] = {
        label = 'Pastilla C',
        weight = 5,
        stack = true,
        close = false,
        description = 'Medicamento de tipo C para tratamientos médicos específicos.'
    },

    ['ice_pack'] = {
        label = 'Bolsa de hielo',
        weight = 100,
        stack = true,
        close = false,
        description = 'Una compresa fría para reducir dolor, inflamación y hematomas.'
    },

    ['neck_brace'] = {
        label = 'Collarín cervical',
        weight = 180,
        stack = true,
        close = false,
        description = 'Un soporte ortopédico para inmovilizar y proteger el cuello.'
    },

    ['gauze_pad'] = {
        label = 'Gasa estéril',
        weight = 40,
        stack = true,
        close = false,
        description = 'Una gasa limpia para cubrir heridas y absorber sangre.'
    },

    ['tourniquet'] = {
        label = 'Torniquete',
        weight = 100,
        stack = true,
        close = false,
        description = 'Herramienta de emergencia para cortar temporalmente el flujo sanguíneo.'
    },

    ['arm_splint'] = {
        label = 'Férula de brazo',
        weight = 200,
        stack = true,
        close = false,
        description = 'Dispositivo médico para inmovilizar un brazo lesionado.'
    },

    ['leg_splint'] = {
        label = 'Férula de pierna',
        weight = 300,
        stack = true,
        close = false,
        description = 'Dispositivo médico para inmovilizar una pierna lesionada.'
    },

    ['trauma_kit'] = {
        label = 'Kit de trauma',
        weight = 800,
        stack = true,
        close = false,
        description = 'Equipo médico avanzado para tratar heridas graves y traumatismos.'
    },

    -- ================ 0Resmond Mechanic ===================

    ["usb_tuning"] = {
        label = "USB de Tuneo",
        weight = 3,
        stack = true,
        close = true,
    },
    ["suspension_controller"] = {
        label = "Control de Suspencion",
        weight = 3,
        stack = true,
        close = true,
    },
    ["tuning_tablet"] = {
        label = "Tablet de Tuneo",
        weight = 3,
        stack = true,
        close = true,
    },

    ['bumper_f'] = {
        label = 'Paragolpes delantero',
        weight = 1,
        stack = false,
        close = false,
        description = 'Una pieza frontal del vehículo diseñada para proteger la carrocería y mejorar su apariencia.'
    },

    ['bumper_r'] = {
        label = 'Paragolpes trasero',
        weight = 1,
        stack = false,
        close = false,
        description = 'Una pieza trasera del vehículo que protege la carrocería ante pequeños impactos.'
    },

    ['bonnet'] = {
        label = 'Capó',
        weight = 1,
        stack = false,
        close = false,
        description = 'El panel que cubre y protege el compartimento del motor del vehículo.'
    },

    ['xenon'] = {
        label = 'Luces de xenón',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un sistema de iluminación mejorado que ofrece una luz más intensa y moderna.'
    },

    ['grille'] = {
        label = 'Parrilla',
        weight = 1,
        stack = false,
        close = false,
        description = 'La rejilla frontal del vehículo que mejora la ventilación y el estilo.'
    },

    ['skirt'] = {
        label = 'Faldones laterales',
        weight = 1,
        stack = false,
        close = false,
        description = 'Piezas laterales que mejoran la estética y la aerodinámica del vehículo.'
    },

    ['roof'] = {
        label = 'Techo',
        weight = 1,
        stack = false,
        close = false,
        description = 'La parte superior del vehículo que cubre el habitáculo.'
    },

    ['plate'] = {
        label = 'Matrícula',
        weight = 1,
        stack = false,
        close = false,
        description = 'La placa identificativa del vehículo con su número de registro.'
    },

    ['boot'] = {
        label = 'Maletero',
        weight = 1,
        stack = false,
        close = false,
        description = 'La compuerta o sección trasera del vehículo destinada al almacenamiento.'
    },

    ['neon'] = {
        label = 'Luces de neón',
        weight = 1,
        stack = false,
        close = false,
        description = 'Iluminación decorativa para personalizar el aspecto exterior del vehículo.'
    },

    ['wing'] = {
        label = 'Alerón',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un accesorio aerodinámico que mejora la estabilidad y el estilo del vehículo.'
    },

    ['brake'] = {
        label = 'Frenos',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un componente de mejora que optimiza la capacidad de frenado del vehículo.'
    },

    ['exhaust'] = {
        label = 'Escape',
        weight = 1,
        stack = false,
        close = false,
        description = 'El sistema de escape del vehículo, diseñado para evacuar gases y modificar su sonido.'
    },

    ['engine'] = {
        label = 'Motor',
        weight = 1,
        stack = false,
        close = false,
        description = 'La pieza principal que proporciona potencia y rendimiento al vehículo.'
    },

    ['transmission'] = {
        label = 'Transmisión',
        weight = 1,
        stack = false,
        close = false,
        description = 'El sistema encargado de transferir la potencia del motor a las ruedas.'
    },

    ['interior'] = {
        label = 'Interior',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un conjunto de mejoras estéticas para personalizar el interior del vehículo.'
    },

    ['livery'] = {
        label = 'Vinilo',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un diseño decorativo exterior para darle una apariencia única al vehículo.'
    },

    ['windscreen'] = {
        label = 'Parabrisas',
        weight = 1,
        stack = false,
        close = false,
        description = 'El cristal frontal del vehículo que protege al conductor y mejora la visibilidad.'
    },

    ['horn'] = {
        label = 'Claxon',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un componente que permite emitir una señal acústica desde el vehículo.'
    },

    ['smoke'] = {
        label = 'Humo de neumáticos',
        weight = 1,
        stack = false,
        close = false,
        description = 'Una modificación visual que cambia el color o efecto del humo de los neumáticos.'
    },

    ['chassis'] = {
        label = 'Chasis',
        weight = 1,
        stack = false,
        close = false,
        description = 'La estructura base del vehículo sobre la que se montan el resto de componentes.'
    },

    ['wheel'] = {
        label = 'Ruedas',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un juego de ruedas para mejorar la estética o el comportamiento del vehículo.'
    },

    ['repair_kit'] = {
        label = 'Kit de reparación',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un conjunto de herramientas y materiales básicos para reparar averías mecánicas.'
    },

    ['repair_wheel'] = {
        label = 'Kit de reparación de ruedas',
        weight = 1,
        stack = false,
        close = false,
        description = 'Un kit pensado para arreglar pinchazos y daños leves en las ruedas del vehículo.'
    },

    ['handlingtablet'] = {
        label = 'Tablet de ajustes',
        weight = 1,
        stack = false,
        close = false,
        description = 'Una tablet especializada para revisar y modificar ajustes técnicos del vehículo.'
    },
    ['mechanictablet'] = {
        label = 'Tablet de mecanico',
        weight = 1,
        stack = false,
        close = false,
        description = 'Una tablet del taller para abrir y gestionar el menu principal del mecanico.',
        client = {
            event = 'bp_multimechanic:mechanictablet_use',
            image = "tuning_tablet.png",
        }
    },
    ['spraygun'] = {
        label = 'Pistola de pintura',
        weight = 1,
        stack = false,
        close = false,
        description = 'Una herramienta para aplicar pintura de forma precisa sobre piezas y carrocerias.',
        client = {
            event = 'bp_multimechanic:spraygun_use'
        }
    },

    ['spraybottle'] = {
        label = 'Bote de pintura',
        weight = 1,
        stack = true,
        close = false,
        description = 'Un bote de pintura en aerosol listo para trabajos de retoque y personalizacion.',
        client = {
            event = 'bp_multimechanic:spraybottle_use'
        }
    },
    -- ===============OX MOCHILAS ======================

    ["clothing_bag"] = {
        label = "Bolsa de Ropa",
        weight = 15,
        stack = true,
        close = true,
        description = "Una bolsa para llevar ropa.",
        client = { image = "clothing_bag.png", export = "clothing_bag.use_clothing_bag" }
    },


    ["backpack_small"] = {
        label = "Mochila pequeña",
        weight = 500,
        stack = false,
        close = false,
        description = "Una mochila pequeña para llevar objetos extra.",
        modelp = 'xm3_prop_xm3_backpack_01a',
    },

    ["backpack_medium"] = {
        label = "Mochila mediana",
        weight = 750,
        stack = false,
        close = false,
        description = "Una mochila mediana para llevar más cosas.",
        modelp = 'prop_cs_heist_bag_01',

    },

    ["backpack_large"] = {
        label = "Mochila grande",
        weight = 1000,
        stack = false,
        close = false,
        description = "Una mochila grande para llevar muchos objetos.",
        modelp = 'prop_cs_heist_bag_01',
    },

    -- =============== OX CLOTHES ROPA ==================

    ["mask"] = {
        label = "Mascara",
        weight = 3,
        stack = true,
        close = true,
    },
    ["shirt"] = {
        label = "Camiseta",
        weight = 3,
        stack = true,
        close = true,
    },
    ["top"] = {
        label = "Chaqueta",
        weight = 3,
        stack = true,
        close = true,
    },
    ["backpack"] = {
        label = "Mochila",
        weight = 3,
        stack = true,
        close = true,
    },
    ["ear"] = {
        label = "Pendientes",
        weight = 3,
        stack = true,
        close = true,
    },
    ["gloves"] = {
        label = "Guantes",
        weight = 3,
        stack = true,
        close = true,
    },
    ["glasses"] = {
        label = "Gafas",
        weight = 3,
        stack = true,
        close = true,
    },
    ["shoes"] = {
        label = "Zapatos",
        weight = 3,
        stack = true,
        close = true,
    },
    ["pants"] = {
        label = "Pantalones",
        weight = 3,
        stack = true,
        close = true,
    },
    ["vest"] = {
        label = "Chaleco",
        weight = 3,
        stack = true,
        close = true,
    },
    ["necklace"] = {
        label = "Collar",
        weight = 3,
        stack = true,
        close = true,
    },
    ["hat"] = {
        label = "Gorra",
        weight = 3,
        stack = true,
        close = true,
    },


    -- =============== 0Resmond Music ================

    -- QUASAR FIVEM CARDS

    ---- AQUI YA ENTRAMOS A COMERCIOS OSEA QUE FUMADITA
    -- == AMIR KEBAB ==
    ["refresnaranja"] = {
        label = "Refresco Naranja",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una bebida dulce, gaseosa y refrescante, con un intenso sabor a naranja y un toque cítrico que la hace irresistible.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_orang_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "refresnaranja.png",
            notification = 'Dulce, cítrico y con muchas burbujas... qué refrescante.',
        }
    },

    ["refreslimon"] = {
        label = "Refresco Limón",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una bebida dulce, gaseosa y refrescante, con un sabor fresco a limón y un toque ácido que la hace especialmente refrescante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "refreslimon.png",
            notification = 'Dulce, ácido y lleno de burbujas... este limón entra solo.',
        }
    },

    ["kebabcaretacerdo"] = {
        label = "Kebab Careta de Cerdo",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un kebab relleno de careta de cerdo, perfecto para degustar una buena careta de cerdo.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "kebabcaretacerdo.png",
            notification = 'Careta de cerdo bien sabrosa dentro de un kebab... menudo invento.',
        }
    },


    ["shawarmabowlskebab"] = {
        label = "Shawarma Bowls",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un bowl de shawarma con ingredientes sabrosos y listo para disfrutar.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "shawarmabowlskebab.png",
            notification = 'Qué shawarma tan sabroso... ¡No he dejado nada en el bowl!',
        }
    },

    ["patataconquesoykebab"] = {
        label = "Patatas gratinadas con kebab",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una ración de patatas con queso fundido y carne de kebab.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "patataconquesoykebab.png",
            notification = 'Estas patatas con queso y kebab estaban increíbles.',
        }
    },

    ["kebab"] = {
        label = "Kebab",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un kebab relleno de carne y acompañamientos, perfecto para comer al momento.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "kebab.png",
            notification = 'Bofff... me he terminado el kebab en un momento.',
        }
    },

    ["baklapostreturco"] = {
        label = "Bakla",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un postre turco dulce y crujiente elaborado con capas finas y sirope.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_choc_pq', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "baklapostreturco.png",
            notification = 'Dulce, crujiente y lleno de sirope... estaba delicioso.',
        }
    },

    ["teturco"] = {
        label = "Té Turco",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Té negro de sabor intenso, ligeramente amargo y muy aromático.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "teturco.png",
            notification = 'Un té intenso y aromático, justo como debe ser.',
        }
    },

    ["refrescocola"] = {
        label = "Refresco Cola",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una bebida dulce, gaseosa y refrescante, con sabor a caramelo y un toque ácido.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "refrescocola.png",
            notification = 'Qué refrescante... me he acabado la cola en nada.',
        }
    },

    ["boza"] = {
        label = "Boza",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una bebida espesa, ligeramente dulce y con un toque ácido, hecha de cereales fermentados y con una textura suave y cremosa.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "bozabebidaturca.png",
            notification = 'Una bebida diferente, cremosa y con un sabor muy especial.',
        }
    },

    ["ayran"] = {
        label = "Ayran",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una bebida refrescante, salada y ligera, hecha de yogur diluido con agua y con un sabor suave y ácido.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "ayranbebidaturca.png",
            notification = 'Qué Ayran tan fresco y suave... me ha sentado genial.',
        }
    },


    -- WEEDLAND LDORGANICS LD


    ["duendecillocbd"] = {
        label = "Duendecillo",
        weight = 3,
        stack = true,
        close = true,
        description = "Un duende que desprende un gran aroma a la hoja de la felicidad.",
        client = {
            image = "duendecillocbd.png",
        }
    },


    ["browniecbd"] = {
        label = "Brownie con CBD",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un bizcocho de chocolate denso y jugoso con un toque botánico, ideal para disfrutar de un momento dulce y calmado.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_choc_pq', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "browniecbd.png",
            notification = 'Chocolate intenso y una sensación de calma... qué buen brownie.',
        }
    },

    ["galletacbd"] = {
        label = "Cookie con CBD",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "La clásica galleta con pepitas de chocolate, horneada con un extra de serenidad para un descanso delicioso.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood2', pos = vec3(0.02, -0.05, 0.02), rot = vec3(0.0, 0.0, 0.0), bone = 60309 },
            usetime = 3500,
            image = "galletacbd.png",
            notification = 'Crujiente, dulce y con muchas pepitas de chocolate... deliciosa.',
        }
    },

    ["gominolascbd"] = {
        label = "Gominolas Relajantes",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Pequeños bocados dulces y afrutados diseñados para desconectar y disfrutar de una pausa reconfortante.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'xs_prop_trinket_cup_01a', pos = vec3(0.03, 0.05, -0.13), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "gominolascbd.png",
            notification = 'Dulces, afrutadas y perfectas para disfrutar de una pausa.',
        }
    },

    ["chocolatinacbd"] = {
        label = "Tableta de Chocolate CBD",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Onzas de chocolate premium combinadas con un toque relajante, perfectas para derretir el estrés del día a día.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_choc_ego', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "chocolatinacbd.png",
            notification = 'Chocolate premium que se derrite en la boca... adiós al estrés.',
        }
    },


    ["elixircbd"] = {
        label = "Elixir LD",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "La receta secreta de la casa, una combinación exclusiva con un toque mágico e inolvidable.",
        client = {
            image = "elixircbd.png",
            notification = 'Una mezcla misteriosa, mágica y realmente inolvidable.',
        }
    },

    ["cafecbd"] = {
        label = "Café",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Tu dosis diaria de energía; un trago aromático, intenso y con cuerpo.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafecbd.png",
            notification = 'Aromático, intenso y con mucho cuerpo... justo lo que necesitaba.',
        }
    },

    ["refrescoldorganics"] = {
        label = "Refresco",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Refresco dulce y burbujeante, servido bien frío para disfrutar de una pausa refrescante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "refrescoldorganics.png",
            notification = 'Dulce, burbujeante y bien frío... qué refrescante.',
        }
    },

    ["zumoldorganics"] = {
        label = "Zumo LD",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Zumo de frutas lleno de vitaminas, refrescante y perfecto para cualquier momento del día.",
        client = {
            image = "zumoldorganics.png",
            notification = 'Fruta, vitaminas y mucho sabor... una recarga perfecta.',
        }
    },


    -- == BADULAKE BADULAQUE GROVE ==
    ["cervezabarriobg"] = {
        label = "Cerveza de Barrio",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Cerveza rubia suave, fría y con sabor del barrio.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'h4_prop_h4_can_beer_01a', pos = vec3(0.01, 0.01, 0.0), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "cervezabarriobg.png",
            notification = 'Rubia, suave y bien fría... una cerveza con sabor de barrio.',
        }
    },

    ["redbugbg"] = {
        label = "Red Bug",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Energética e intensa, con la fuerza y el carácter de una avispa.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_energy_drink', pos = vec3(0.03, 0.05, 0.0), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "redbugbg.png",
            notification = '¡Menudo aguijonazo de energía! Ya estoy preparado para todo.',
        }
    },

    ["berryblazebg"] = {
        label = "Berry Blaze",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una explosión de frutos rojos, dulce, intensa y con un toque ácido irresistible.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "berryblazebg.png",
            notification = 'Dulce, intenso y con el punto ácido perfecto... una explosión de frutos rojos.',
        }
    },

    ["potajeabuelabg"] = {
        label = "Potaje de la Abuela",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Plato casero tradicional de receta familiar Cortés, preparado con legumbres, chorizo suave y un caldo espeso.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "potajeabuelabg.png",
            notification = 'Legumbres, chorizo y caldo espeso... un potaje como el de la abuela.',
        }
    },

    ["tortillagitanabg"] = {
        label = "Tortilla Gitana",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Tortilla de patatas con pimiento, cebolla y un toque picante, acompañada de una aceituna y un trozo de pan.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "tortillagitanabg.png",
            notification = 'Jugosa, sabrosa y con ese toque picante... qué buena tortilla.',
        }
    },

    ["bocatacortesbg"] = {
        label = "Bocata Cortés",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Lomo, queso y jamón con salsa casera gitana en pan crujiente.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "bocatacortesbg.png",
            notification = 'Lomo, jamón, queso y salsa gitana... menudo bocata más bueno.',
        }
    },

    ["sandwichtrespisosbg"] = {
        label = "Sándwich de 3 Pisos",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Triple capa de pan con pollo, bacon, queso y salsa suave, un clásico perfecto para el barrio.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "sandwichtrespisosbg.png",
            notification = 'Tres pisos de pollo, bacon y queso... este sándwich sí que llena.',
        }
    },
    ["empanadillabg"] = {
        label = "Empanadilla",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Masa fina y crujiente, frita u horneada, rellena de un sabroso sofrito tradicional.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_taco_02', pos = vec3(0.03, 0.05, -0.01), bone = 58867, rot = vec3(90.0, 0.0, 45.0) },
            usetime = 3500,
            image = "empanadillabg.png",
            notification = 'Crujiente por fuera y con un sofrito delicioso por dentro.',
        }
    },

    ["pinchotortillabd"] = {
        label = "Pincho de Tortilla",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una jugosa porción de tortilla de patatas, con o sin cebolla.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "pinchotortillabd.png",
            notification = 'Jugosa y preparada en su punto... qué buen pincho de tortilla.',
        }
    },

    ["pinchoverdurasbg"] = {
        label = "Pincho de Verduras",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Brocheta ligera y saludable de verduras frescas de temporada hechas a la plancha.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_steak', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "pinchoverdurasbg.png",
            notification = 'Verduras frescas a la plancha... un pincho ligero y sabroso.',
        }
    },

    ["sandwichbg"] = {
        label = "Sándwich Triple",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Tres pisos de pan de molde que albergan capas de tus ingredientes favoritos para el doble de sabor.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "sandwichbg.png",
            notification = 'Tres pisos cargados de ingredientes... no podía estar más bueno.',
        }
    },

    ["berrybg"] = {
        label = "Berry Blaze",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una explosión frutal de bayas y frutos rojos con un balance perfecto entre dulce y ácido.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "berrybg.png",
            notification = 'Dulce, ácido y cargado de frutos rojos... una explosión de sabor.',
        }
    },

    ["cafebg"] = {
        label = "Café Frappé",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Café frío, cremoso y refrescante, mezclado con hielo para conseguir una textura suave y espumosa.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafebg.png",
            notification = 'Frío, cremoso y con un intenso sabor a café... qué buen frappé.',
        }
    },

    ["fantabg"] = {
        label = "Frizzle Naranja",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Bebida burbujeante con todo el sabor dulce y frutal de la naranja madura.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_orang_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "fantabg.png",
            notification = 'Dulce, burbujeante y con mucho sabor a naranja.',
        }
    },

    ["limonadabg"] = {
        label = "Limonada Fresca",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Limonada recién preparada, dulce y cítrica, servida bien fría con hielo y un toque de menta.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "limonadabg.png",
            notification = 'Dulce, cítrica y bien fría... esta limonada sienta de maravilla.',
        }
    },

    ["llaveroburgerbg"] = {
        label = "Llavero de Burger",
        weight = 3,
        stack = true,
        close = true,
        description = "Llavero coleccionable con forma de hamburguesa, un recuerdo exclusivo para los amantes de Burger.",
        client = {
            image = "llaveroburgerbg.png",
        }
    },


    -- == BADULAKE BADULAQUE CENTRAL ==

    ["tigrecinbaduc"] = {
        label = "Tigretin",
        weight = 3,
        stack = true,
        close = true,
        description = "Simpático tigre de peluche coleccionable y mascota especial de Baduc.",
        client = {
            image = "tigrecinbaduc.png",
        }
    },

    ["cafebcentral"] = {
        label = "Café Expresso",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Tu dosis diaria de energía; café aromático, intenso y con una capa de crema perfecta.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafebcentral.png",
            notification = 'Un café intenso y aromático... ya tengo la energía que necesitaba.',
        }
    },

    ["colabaduc"] = {
        label = "Cola Normal",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "La bebida de cola de siempre, con el balance perfecto de gas y ese sabor inconfundible.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "colabaduc.png",
            notification = 'Ese sabor clásico de cola nunca falla... qué refrescante.',
        }
    },

    ["cervezabaduc"] = {
        label = "Cerveza LTD",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una cerveza fría y refrescante, perfecta para disfrutar en cualquier momento.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'h4_prop_h4_can_beer_01a', pos = vec3(0.01, 0.01, 0.0), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "cervezabaduc.png",
            notification = 'Una cerveza bien fría... justo lo que necesitaba.',
        }
    },

    ["zumobaduc"] = {
        label = "Zumo de Naranja",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Zumo cítrico natural, refrescante, lleno de vitaminas y recién exprimido.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "zumobaduc.png",
            notification = 'Recién exprimido, cítrico y refrescante... qué bien sienta.',
        }
    },


    ["bocatabaconqueso"] = {
        label = "Bocata Bacon Queso",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un clásico irresistible de bacon crujiente y queso fundido dentro de un pan crujiente y caliente.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "bocatabaconqueso.png",
            notification = 'Bacon crujiente y queso fundido... este bocata estaba increíble.',
        }
    },

    ["patatasbaduc"] = {
        label = "Patatas Fritas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Bastones de patata dorados y crujientes por fuera, tiernos por dentro, listos para dipear.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "patatasbaduc.png",
            notification = 'Doradas, crujientes y perfectas para dipear... no ha quedado ni una.',
        }
    },

    ["perritobaduc"] = {
        label = "Perrito Caliente",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "La icónica salchicha servida en su tierno pan alargado, perfecta para acompañar con tus salsas favoritas.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_hotdog_02', pos = vec3(0.03, 0.05, -0.01), bone = 58867, rot = vec3(-90.0, 0.0, 45.0) },
            usetime = 3500,
            image = "perritobaduc.png",
            notification = 'Un perrito caliente con mis salsas favoritas... qué bueno estaba.',
        }
    },

    ["donutbaduc"] = {
        label = "Donut de chocolate",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un donut tierno y esponjoso cubierto con una deliciosa capa de chocolate.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_donut_02', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 90.0, -180.0), bone = 4186 },
            usetime = 3500,
            image = "donutbaduc.png",
            notification = 'Esponjoso y cubierto de chocolate... me lo he comido en dos bocados.',
        }
    },



    -- == BAHAMAS ==


    ["gominolasbahamas"] = {
        label = "Cuenco de Gominolas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cuenco de gominolas variadas, suaves y dulces, con diferentes colores y sabores, perfecto para compartir o disfrutar como snack.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'xs_prop_trinket_cup_01a', pos = vec3(0.03, 0.05, -0.13), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "gominolasbahamas.png",
            notification = 'Dulces, suaves y de muchos sabores... no ha quedado ni una.',
        }
    },

    ["frutossecosbahamas"] = {
        label = "Cuenco de Frutos Secos",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cuenco de frutos secos variados, tostados y crujientes, ideal como snack energético y saludable para cualquier momento.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "frutossecosbahamas.png",
            notification = 'Tostados, variados y crujientes... el aperitivo perfecto.',
        }
    },

    ["hamburguesacompletabahamas"] = {
        label = "Hamburguesa Completa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Hamburguesa completa con carne jugosa, pan suave y una combinación de ingredientes frescos y sabrosos, ideal como comida contundente y clásica.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "hamburguesacompletabahamas.png",
            notification = 'Carne jugosa, pan suave e ingredientes frescos... estaba espectacular.',
        }
    },

    ["cubatabahamas"] = {
        label = "Cubata Bahamas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un combinado refrescante de destilado y refresco, servido con abundante hielo y un toque cítrico.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "cubatabahamas.png",
            notification = 'Mucho hielo, un toque cítrico y la mezcla perfecta... sabe a Bahamas.',
        }
    },

    ["tequilalimonbahamas"] = {
        label = "Tequila Limón",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un trago intenso de tequila acompañado por el sabor fresco y ácido del limón.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "tequilalimonbahamas.png",
            notification = '¡Menudo trago! El limón le da el toque fresco perfecto.',
        }
    },

    ["mojitofresabahamas"] = {
        label = "Mojito Fresa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una versión dulce y afrutada del mojito clásico, preparada con fresas, lima, menta y abundante hielo.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "mojitofresabahamas.png",
            notification = 'Fresa, menta y lima... un mojito dulce y muy refrescante.',
        }
    },

    ["colabahamas"] = {
        label = "Refresco Cola",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una bebida de cola dulce, gaseosa y refrescante, con su característico sabor a caramelo.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "colabahamas.png",
            notification = 'Bien fría, con gas y ese sabor de siempre... qué refrescante.',
        }
    },

    ["swapsnaranjabahamas"] = {
        label = "Refresco Swaps Naranja",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un refresco de naranja dulce, cítrico y burbujeante, ideal para disfrutar bien frío.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_orang_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "swapsnaranjabahamas.png",
            notification = 'Dulce, cítrico y con muchas burbujas... me lo he bebido en nada.',
        }
    },

    -- == Bahamas ==

    ["jaggergalaxy"] = {
        label = "Dark Horn",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un trago intenso y misterioso, con notas oscuras y un carácter fuerte para los más atrevidos.",
        client = {
            image = "jaggergalaxy.png",
            notification = 'Un trago oscuro e intenso... no es para cualquiera.',
        }
    },

    ["nightpulse"] = {
        label = "Night Pulse",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Pura energía líquida diseñada para mantener el ritmo de la noche con un sabor vibrante.",
        client = {
            image = "nightpulse.png",
            notification = 'Night Pulse activado... todavía queda mucha noche.',
        }
    },

    ["coctelgalaxy"] = {
        label = "Bass Drop",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un estallido de sabor potente y electrizante que se siente en cada sorbo.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "coctelgalaxy.png",
            notification = 'Menudo estallido de sabor... este Bass Drop pega fuerte.',
        }
    },

    ["galacticogalaxy"] = {
        label = "Nebula Mist",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una mezcla exótica, visual y refrescante que parece sacada de otra galaxia.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "galacticogalaxy.png",
            notification = 'Exótico, refrescante y de otro mundo... una auténtica nebulosa.',
        }
    },

    ["bombagalaxy"] = {
        label = "Bomba",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un chute de energía y sabor concentrado, ideal para reactivar tu noche.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "bombagalaxy.png",
            notification = '¡Menuda bomba! Ya tengo energía para seguir toda la noche.',
        }
    },

    ["frutossecosgalaxy"] = {
        label = "Frutos Secos",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Selección de frutos secos variados, tostados y crujientes, ideales como snack saludable y energético en cualquier momento del día.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, 0.0, 0.0), rot = vec3(90.0, 0.0, 40.0) },
            usetime = 3500,
            image = "frutossecosgalaxy.png",
            notification = 'Tostados y crujientes... un buen chute de energía.',
        }
    },

    ["patatasgalaxy"] = {
        label = "Patatas de Bolsa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Patatas fritas en bolsa, crujientes y doradas, con un toque de sal y perfectas para picar en cualquier momento.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, 0.0, 0.0), rot = vec3(90.0, 0.0, 40.0) },
            usetime = 3500,
            image = "patatasgalaxy.png",
            notification = 'Crujientes y con el punto justo de sal... no podía dejar de comerlas.',
        }
    },

    ["aceitunasgalaxy"] = {
        label = "Aceitunas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Aceitunas seleccionadas, jugosas y ligeramente saladas, ideales como aperitivo o acompañamiento en cualquier ocasión.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "aceitunasgalaxy.png",
            notification = 'Jugosas y ligeramente saladas... un aperitivo perfecto.',
        }
    },





    -- == CASINO ==








    -- == CLUB 77 ==


    ["cubata77"] = {
        label = "Cubata",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "El combinado clásico por excelencia; una mezcla perfecta de destilado con refresco y un toque cítrico sobre mucho hielo.",
        client = {
            image = "cubata77.png",
            notification = 'Un combinado clásico, cargado de hielo y con el toque cítrico perfecto.',
        }
    },

    ["vodkalimon"] = {
        label = "Vodka Limón",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un trago largo, directo y muy refrescante que combina la pureza del vodka con la acidez del limón.",
        client = {
            image = "vodkalimon.png",
            notification = 'Fresco, ácido y directo... este vodka limón ha entrado solo.',
        }
    },

    ["mojito77"] = {
        label = "Mojito",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "El clásico trago cubano de menta y lima, disponible también en su versión más exótica con mango dulce.",
        client = {
            image = "mojito77.png",
            notification = 'Menta, lima y mucho hielo... qué mojito tan refrescante.',
        }
    },

    ["cola77"] = {
        label = "Refresco Cola",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "La bebida de cola de siempre, con el balance perfecto de gas y ese sabor inconfundible.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "cola77.png",
            notification = 'Bien fría y con el gas perfecto... una cola nunca falla.',
        }
    },

    ["naranja77"] = {
        label = "Refresco Naranja",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Zumo cítrico natural, refrescante, lleno de vitaminas y recién exprimido.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "naranja77.png",
            notification = 'Cítrico, dulce y muy refrescante... me lo he bebido en nada.',
        }
    },

    ["gominolas77"] = {
        label = "Cuenco de Gominolas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cuenco de gominolas variadas, suaves y dulces, con diferentes colores y sabores, perfecto para compartir o disfrutar como snack.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'xs_prop_trinket_cup_01a', pos = vec3(0.03, 0.05, -0.13), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "gominolas77.png",
            notification = 'Dulces, suaves y de todos los sabores... no ha quedado ni una.',
        }
    },

    ["frutossecos77"] = {
        label = "Cuenco de Frutos Secos",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cuenco de frutos secos variados, tostados y crujientes, ideal como snack energético y saludable para cualquier momento.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "frutossecos77.png",
            notification = 'Tostados, variados y crujientes... un aperitivo perfecto.',
        }
    },

    ["hamburguesacompleta77"] = {
        label = "Hamburguesa Completa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Hamburguesa completa con carne jugosa, pan suave y una combinación de ingredientes frescos y sabrosos, ideal como comida contundente y clásica.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "hamburguesacompleta77.png",
            notification = 'Carne jugosa, ingredientes frescos y pan suave... menuda hamburguesa.',
        }
    },

    -- == UWU CAFE ==


    ["cafeicelateuwu"] = {
        label = "Bubble Tea UwU",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Refrescante té con leche y perlas de tapioca, servido en un adorable vaso kawaii.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafeicelateuwu.png",
            notification = 'Dulce, refrescante y lleno de tapioca... ¡qué kawaii!',
        }
    },

    ["batidofresauwu"] = {
        label = "Batido de Fresa UwU",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Cremoso batido de fresa coronado con nata montada, dulce y perfecto para cualquier momento.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "batidofresauwu.png",
            notification = 'Cremoso, dulce y con mucho sabor a fresa... UwU.',
        }
    },

    ["zumodearandanosuwu"] = {
        label = "Bubble Tea de Arándanos UwU",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Bebida afrutada de arándanos con perlas de tapioca y un intenso sabor refrescante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "zumodearandanosuwu.png",
            notification = 'Afrutado, intenso y con deliciosas perlas de tapioca.',
        }
    },

    ["cafelatauwu"] = {
        label = "Chocolate Caliente UwU",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Reconfortante chocolate caliente con nata montada, ideal para los días más fríos del UwU Café.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafelatauwu.png",
            notification = 'Calentito, cremoso y cubierto de nata... qué bien sienta.',
        }
    },

    ["pokeuwucafe"] = {
        label = "Bowl de Pollo UwU",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Bowl de arroz con pollo crujiente, huevo cocido y verduras, servido al más puro estilo UwU.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "pokeuwucafe.png",
            notification = 'Pollo crujiente, arroz y verduras... ¡un bowl delicioso, UwU!',
        }
    },

    ["tartadefresauwu"] = {
        label = "Tarta de Fresa UwU",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Deliciosa porción de tarta de fresa con crema dulce y el inconfundible estilo kawaii del UwU Café.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood6', pos = vec3(0.01, 0.02, -0.01), rot = vec3(-170.0, 88.0, 30.0) },
            usetime = 3500,
            image = "tartadefresauwu.png",
            notification = 'Fresa, crema dulce y mucho estilo kawaii... estaba deliciosa.',
        }
    },

    ["tortitasdechocouwu"] = {
        label = "Pancakes UwU",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Esponjosos pancakes bañados en chocolate con mantequilla, nata y fresas frescas.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "tortitasdechocouwu.png",
            notification = 'Pancakes esponjosos con chocolate y fresas... no podía dejar nada.',
        }
    },

    ["hamburgesitauwucafe"] = {
        label = "Cat Burger UwU",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Tierna hamburguesa con pan en forma de gatito, carne, queso y vegetales frescos.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "hamburgesitauwucafe.png",
            notification = 'Era tan adorable que daba pena comerla... pero estaba buenísima, UwU.',
        }
    },

    -- == TEQUILALA ==

    ["cestadefritostequilala"] = {
        label = "Cesta de Fritura Variada",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cesta de frituras crujientes con nuggets de pollo, alitas de pollo, aros de cebolla dorados y cubitos de salsa para mojar.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "cestadefritostequilala.png",
            notification = 'Nuggets, alitas y aros de cebolla... no ha quedado nada en la cesta.',
        }
    },

    ["empanadilladeatun"] = {
        label = "Empanadilla de Atún",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Empanadilla dorada y crujiente rellena de una sabrosa mezcla de atún.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_taco_02', pos = vec3(0.03, 0.05, -0.01), bone = 58867, rot = vec3(90.0, 0.0, 45.0) },
            usetime = 3500,
            image = "empanadilladeatun.png",
            notification = 'Crujiente por fuera y con un sabroso relleno de atún.',
        }
    },

    ["pinchodetortilla"] = {
        label = "Pincho de Tortilla de Patatas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una generosa porción de tortilla de patatas, jugosa por dentro y dorada por fuera.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "pinchodetortilla.png",
            notification = 'Jugosa y dorada en su punto... qué buen pincho de tortilla.',
        }
    },

    ["supersandwich"] = {
        label = "Super Sándwich Boxing",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Super Sándwich Boxing de tres pisos, cargado de pollo, huevo, lechuga, tomate, queso y salsas, perfecto para saciar el mayor apetito.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "supersandwich.png",
            notification = 'Tres pisos cargados hasta arriba... este sándwich sí que sacia.',
        }
    },

    ["cervezatequilala"] = {
        label = "Cerveza Boxing",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Cerveza en jarra muy fría con un toque de tequila al estilo Boxing.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "cervezatequilala.png",
            notification = 'Bien fría y con un golpe de tequila... ¡esto sí que pega!',
        }
    },

    ["chupitotqequila"] = {
        label = "Chupito de Tequila",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un chupito intenso de tequila, servido para beber de un solo trago.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "chupitotqequila.png",
            notification = '¡De un solo trago! Este tequila baja fuerte.',
        }
    },

    ["copademartini"] = {
        label = "Copa de Martini",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un elegante martini de sabor intenso, servido bien frío y listo para disfrutar.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "copademartini.png",
            notification = 'Frío, elegante e intenso... un martini perfecto.',
        }
    },

    ["refrescodecola"] = {
        label = "Refresco de Cola",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Refresco de cola dulce y burbujeante, servido bien frío para combatir la sed.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "refrescodecola.png",
            notification = 'Bien frío, con gas y ese sabor clásico... qué refrescante.',
        }
    },

    ["peluchetequilala"] = {
        label = "Super Boxing Tequi-la-la",
        weight = 3,
        stack = true,
        close = true,
        description = "Peluche coleccionable del mejor oso boxeador de todo Los Santos: Tequilín Boxing.",
        client = {
            image = "peluchetequilala.png",
        }
    },

    -- == PACIFIC BLUFFS ==

    ["peluchepacifico"] = {
        label = "Peluche Pacífico",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Peluche coleccionable inspirado en Pacific Bluffs, con un diseño exclusivo y un relajado estilo costero.",
        client = {
            image = "peluchepacifico.png",
        }
    },

    ["boldepatatasfritas"] = {
        label = "Bowl de Patatas Fritas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Crujientes patatas fritas doradas al punto, recién preparadas y perfectas para disfrutar como aperitivo o acompañamiento.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "boldepatatasfritas.png",
            notification = 'Doradas y crujientes al punto... no ha quedado ni una patata.',
        }
    },

    ["gominolastropical"] = {
        label = "Bowl de Gominolas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Colorido bowl de gominolas surtidas, dulces y suaves, ideal para compartir o disfrutar como un delicioso snack.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'xs_prop_trinket_cup_01a', pos = vec3(0.03, 0.05, -0.13), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "gominolastropical.png",
            notification = 'Dulces, suaves y llenas de color... me he terminado todo el bowl.',
        }
    },

    ["tartadecafeconleche"] = {
        label = "Tarta de Café con Leche",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Deliciosa tarta de café con leche, de textura suave y cremosa, con el equilibrio perfecto entre el intenso sabor del café y la dulzura de la leche.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood6', pos = vec3(0.01, 0.02, -0.01), rot = vec3(-170.0, 88.0, 30.0) },
            usetime = 3500,
            image = "tartadecafeconleche.png",
            notification = 'Suave, cremosa y con el equilibrio perfecto de café y leche.',
        }
    },

    ["cocteldefresastropical"] = {
        label = "Cóctel de Fresa Tropical",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una deliciosa y dulce mezcla frutal con todo el sabor del trópico y fresas maduras.",
        client = {
            image = "cocteldefresastropical.png",
            notification = 'Dulce, afrutado y con todo el sabor de las fresas maduras.',
        }
    },

    ["coctelnaranjatropical"] = {
        label = "Cóctel de Naranja Tropical",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Combinación exótica y refrescante con base de cítricos y un toque caribeño.",
        client = {
            image = "coctelnaranjatropical.png",
            notification = 'Cítrico, exótico y refrescante... puro sabor caribeño.',
        }
    },

    ["ginebradefresatropical"] = {
        label = "Ginebra con Fresas Tropicales",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una versión afrutada y elegante del gin tradicional, aromatizada con fresas frescas.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "ginebradefresatropical.png",
            notification = 'Una ginebra elegante, afrutada y llena de fresas frescas.',
        }
    },

    ["mojitotropical"] = {
        label = "Mojito de Mango Tropical",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un cóctel refrescante con todo el sabor del mango maduro, un toque de menta fresca y un chorrito de lima para un viaje directo al Caribe en cada trago.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "mojitotropical.png",
            notification = 'Mango, menta y lima... un viaje directo al Caribe.',
        }
    },

    ["licordemelonconlima"] = {
        label = "Licor de Melón con Lima",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una combinación dulce y ácida a la vez, refrescante, golosa y de color vibrante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "licordemelonconlima.png",
            notification = 'Dulce, ácido y refrescante... una combinación muy golosa.',
        }
    },

    -- == VANILLA UNICORNS ==

    ["pollofrevanilla"] = {
        label = "Pollofre",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Crujiente pollo frito dorado, jugoso por dentro y con un rebozado sazonado, perfecto como plato principal o snack.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_turkey_leg_01', pos = vec3(0.03, -0.01, 0.0), rot = vec3(90.0, -10.0, 0.0), bone = 4186 },
            usetime = 3500,
            image = "pollofrevanilla.png",
            notification = 'Crujiente por fuera, jugoso por dentro... qué bueno estaba este pollo.',
        }
    },

    ["conofrevanilla"] = {
        label = "Coñofre",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Gofre tipo waffle dorado y esponjoso, con textura crujiente por fuera y suave por dentro, perfecto para acompañar con dulces o toppings.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "conofrevanilla.png",
            notification = 'Dorado, esponjoso y cubierto de dulces... un placer irresistible.',
        }
    },

    ["tangacomestible"] = {
        label = "Tanga Comestible",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Puro juego y diversión. Prenda íntima confeccionada con deliciosos hilos de caramelo o gominola frutal.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_choc_ego', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "tangacomestible.png",
            notification = 'Dulce, atrevido y muy divertido... no ha quedado ni un hilo.',
        }
    },

    ["roncolavanilla"] = {
        label = "Ron Cola",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "El combinado rey de la noche, una mezcla perfecta de ron añejo con refresco de cola y un toque de lima.",
        client = {
            image = "roncolavanilla.png",
            notification = 'Ron añejo, cola y un toque de lima... el rey de la noche.',
        }
    },

    ["gintonicvanilla"] = {
        label = "Gin Tonic",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Elegante, botánico y refrescante; ginebra premium combinada con tónica y un toque cítrico.",
        client = {
            image = "gintonicvanilla.png",
            notification = 'Elegante, botánico y con el toque cítrico perfecto.',
        }
    },

    ["coctelfresavanilla"] = {
        label = "Cóctel sin Alcohol",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Todo el sabor, la creatividad y la frescura de la alta coctelería, pero 100% libre de alcohol.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "coctelfresavanilla.png",
            notification = 'Fresco, creativo y lleno de sabor... sin una gota de alcohol.',
        }
    },

    ["esposasvanilla"] = {
        label = "Esposas Lujuriosas",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Unas provocativas esposas coleccionables de Vanilla, creadas para quienes disfrutan de los juegos más atrevidos.",
        client = {
            image = "esposasvanilla.png",
        }
    },

    ["fustavanilla"] = {
        label = "Fusta",
        weight = 3,
        stack = true,
        close = true,
        description = "Fusta coleccionable de diseño elegante y atrevido, recuerdo exclusivo de Vanilla.",
        client = {
            image = "fustavanilla.png",
        }
    },

    ["premiovanilla"] = {
        label = "Don Vanilla",
        weight = 3,
        stack = true,
        close = true,
        description = "Premio coleccionable de Don Vanilla, reservado para los clientes más especiales del local.",
        client = {
            image = "premiovanilla.png",
        }
    },

    ["antifazvanilla"] = {
        label = "Antifaz",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Misterioso antifaz coleccionable de Vanilla, perfecto para mantener el anonimato durante una noche inolvidable.",
        client = {
            image = "antifazvanilla.png",
        }
    },

    -- == BURGER SHOT ==

    ["babyshot"] = {
        label = "Baby Shot",
        weight = 3,
        stack = true,
        close = true,
        description = "Adorable figura coleccionable de Baby Shot, la pequeña mascota de Burger Shot.",
        client = {
            image = "babyshot.png",
        }
    },

    ["refrescoshot"] = {
        label = "Refresco Shot",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un pequeño y potente trago refrescante con un estallido de burbujas y sabor concentrado para revivir al instante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "refrescoshot.png",
            notification = 'Pequeño, burbujeante y cargado de sabor... ¡menudo shot!',
        }
    },

    ["energyshot"] = {
        label = "Energética Shot",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un concentrado de energía en formato mini, diseñado para darte ese empujón rápido y mantener el ritmo cuando más lo necesitas.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_energy_drink', pos = vec3(0.03, 0.05, 0.0), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "energyshot.png",
            notification = '¡Energía concentrada! Ya tengo el empujón que necesitaba.',
        }
    },

    ["cafeshot"] = {
        label = "Café Shot",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Café pequeño, fuerte y concentrado, con sabor intenso y ligeramente amargo.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafeshot.png",
            notification = 'Pequeño, fuerte y bien cargado... este café despierta a cualquiera.',
        }
    },

    ["zumoshot"] = {
        label = "Zumo Shot",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un chorro concentrado de fruta y vitaminas naturales, perfecto para una recarga rápida, fresca y saludable en un solo sorbo.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "zumoshot.png",
            notification = 'Fruta y vitaminas concentradas en un solo sorbo... qué fresco.',
        }
    },

    ["miniburgershot"] = {
        label = "Burger Completa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Jugosa carne a la parrilla con queso fundido, bacon crujiente, huevo, lechuga, tomate y nuestra salsa especial en tierno pan brioche.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "miniburgershot.png",
            notification = 'Carne, bacon, huevo y queso fundido... una burger realmente completa.',
        }
    },

    ["patatasburgershot"] = {
        label = "Patatas Gratinadas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Láminas de patata horneadas en salsa de nata y especias, cubiertas con una generosa capa de queso fundido y perfectamente tostado.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "patatasburgershot.png",
            notification = 'Cremosas, especiadas y cubiertas de queso tostado... qué buenas.',
        }
    },

    ["aritosburgershot"] = {
        label = "Aritos de Cebolla",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Aros de cebolla natural con un rebozado ligero y dorado. Crujientes por fuera, tiernos por dentro e ideales para dipear.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, 0.0, 0.0), rot = vec3(90.0, 0.0, 40.0) },
            usetime = 3500,
            image = "aritosburgershot.png",
            notification = 'Crujientes por fuera y tiernos por dentro... perfectos para dipear.',
        }
    },

    ["heladoshot"] = {
        label = "Helado",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Helado artesanal de textura cremosa y aterciopelada, elaborado con ingredientes de calidad. El postre ideal para refrescar el paladar.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'xs_prop_trinket_cup_01a', pos = vec3(0.03, 0.05, -0.13), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "heladoshot.png",
            notification = 'Cremoso, suave y refrescante... el final perfecto para la comida.',
        }
    },

    -- == TALLER AUTOEXOTIC ==

    ["ositoautoexotic"] = {
        label = "Peluche Autoexotic",
        weight = 3,
        stack = true,
        close = true,
        description = "Oso de peluche coleccionable con un diseño exclusivo inspirado en Auto Exotic.",
        client = {
            image = "ositoautoexotic.png",
        }
    },

    ["cocheautoexotic"] = {
        label = "Coche Autoexotic",
        weight = 3,
        stack = true,
        close = true,
        description = "Miniatura coleccionable del deportivo Jester con un acabado exclusivo de Auto Exotic.",
        client = {
            image = "cocheautoexotic.png",
        }
    },





    -- == TALLER BENNYS ==

    ["sultanbennys"] = {
        label = "Sultan RS",
        weight = 3,
        stack = true,
        close = true,
        description = "Miniatura coleccionable del Sultan RS, personalizada con el inconfundible estilo de Benny's.",
        client = {
            image = "sultanbennys.png",
        }
    },

    ["ositobennys"] = {
        label = "El Oso Benny",
        weight = 3,
        stack = true,
        close = true,
        description = "Adorable oso de peluche coleccionable inspirado en el estilo y los colores de Benny's.",
        client = {
            image = "ositobennys.png",
        }
    },




    -- == TALLER LS CUSTOMS ==
    ["ositolsc"] = {
        label = "El Oso Santo",
        weight = 3,
        stack = true,
        close = true,
        description = "Oso de peluche coleccionable inspirado en Los Santos Customs y su pasión por el motor.",
        client = {
            image = "ositolsc.png",
        }
    },

    ["cochelsc"] = {
        label = "Massacro",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Miniatura coleccionable del Massacro, preparada con el característico estilo de Los Santos Customs.",
        client = {
            image = "cochelsc.png",
        }
    },






    -- == TALLER HAYES ==
    ["cochehayes"] = {
        label = "Pfister",
        weight = 3,
        stack = true,
        close = true,
        description = "Miniatura coleccionable de un elegante deportivo Pfister con un acabado especial de Hayes.",
        client = {
            image = "cochehayes.png",
        }
    },

    ["ositohayes"] = {
        label = "El Oso Hayes",
        weight = 3,
        stack = true,
        close = true,
        description = "Oso de peluche coleccionable vestido con los colores y el estilo del taller Hayes.",
        client = {
            image = "ositohayes.png",
        }
    },

    ["amegokebab"] = {
        label = "Durumcito",
        weight = 3,
        stack = true,
        close = true,
        description = "¡La figura principal de Amir Kebab! El combo perfecto: kebab y cigarro.",
        client = {
            image = "amegokebab.png",
        }
    },

    ["llaverito77"] = {
        label = "Osito 77",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Adorable llavero coleccionable con la figura del Osito 77, perfecto para llevarlo siempre contigo.",
        client = {
            image = "llaverito77.png",
        }
    },

    ["peluchegalaxy"] = {
        label = "Nebulino",
        weight = 3,
        stack = true,
        close = true,
        description = "Misterioso peluche coleccionable llegado desde otra galaxia, con un diseño cósmico y adorable.",
        client = {
            image = "peluchegalaxy.png",
        }
    },

    ["pelucheuwucafe"] = {
        label = "Peluche UwU Café",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Peluche coleccionable de un adorable gatito kawaii del UwU Café, sosteniendo una taza de café con un tierno estilo pastel.",
        client = {
            image = "pelucheuwucafe.png",
        }
    },

    -- REX DINNER

    ["tortitasrexdinner"] = {
        label = "Tortitas Rex",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Tortitas suaves y esponjosas, con un sabor dulce y reconfortante.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "tortitasrexdinner.png",
            notification = 'Suaves, esponjosas y dulces... estas tortitas son un desayuno jurásico.',
        }
    },

    ["sandwichrexdinner"] = {
        label = "Sándwich Rex",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Sándwich sabroso y equilibrado, preparado con pan tierno y un relleno jugoso.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "sandwichrexdinner.png",
            notification = 'Pan tierno y un relleno muy jugoso... este sándwich estaba de miedo.',
        }
    },

    ["perritorexdinner"] = {
        label = "Perrito Rex",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Perrito caliente y sabroso, preparado con pan suave y una salchicha jugosa.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_hotdog_02', pos = vec3(0.03, 0.05, -0.01), bone = 58867, rot = vec3(-90.0, 0.0, 45.0) },
            usetime = 3500,
            image = "perritorexdinner.png",
            notification = 'Caliente, sabroso y muy jugoso... este perrito tiene apetito de dinosaurio.',
        }
    },

    ["alitasdepollorexdinner"] = {
        label = "Alitas de Pollo Rex",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Alitas de pollo crujientes por fuera y tiernas por dentro, con un sabor intenso y especiado.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_turkey_leg_01', pos = vec3(0.03, -0.01, 0.0), rot = vec3(90.0, -10.0, 0.0), bone = 4186 },
            usetime = 3500,
            image = "alitasdepollorexdinner.png",
            notification = 'Crujientes, tiernas y muy especiadas... no ha quedado ni un hueso.',
        }
    },

    ["refrescorexdinner"] = {
        label = "Refresco Rex",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Bebida gaseosa, dulce y refrescante, con un divertido toque chispeante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "refrescorexdinner.png",
            notification = 'Dulce, refrescante y lleno de burbujas... un refresco prehistórico.',
        }
    },

    ["cervezarexdinner"] = {
        label = "Cerveza Rex",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Cerveza suave y ligeramente amarga, con un sabor refrescante y equilibrado.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'h4_prop_h4_can_beer_01a', pos = vec3(0.01, 0.01, 0.0), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "cervezarexdinner.png",
            notification = 'Suave, equilibrada y bien fría... una cerveza digna del rey de los dinosaurios.',
        }
    },

    ["caderexdinner"] = {
        label = "Café Rex",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Café intenso y aromático, con un sabor fuerte y reconfortante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "caferexdinner.png",
            notification = 'Intenso, aromático y reconfortante... este café despierta hasta a un dinosaurio.',
        }
    },

    ["batirorexdinner"] = {
        label = "Batido Rex",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Batido cremoso, dulce y frío, con una textura suave y un sabor delicioso.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "batirorexdinner.png",
            notification = 'Dulce, frío y muy cremoso... un batido gigantescamente delicioso.',
        }
    },

    ["pelucherex"] = {
        label = "DinoRex",
        weight = 3,
        stack = true,
        close = true,
        description = "Un feroz T-Rex de peluche coleccionable que ahuyentará a todos los monstruos durante la noche.",
        client = {
            image = "pelucherex.png",
        }
    },

    ["stg_chess"] = {
    label = "Chess",
    weight = 2000,
    stack = false,
    close = true,
    client = {
        event = 'stg-chessv2:client:useItem'
    }
},

    -- STARLIGHT

    ["vodkastarlight"] = {
        label = "Vodka Sprunk",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una mezcla vibrante de vodka y refresco Sprunk, con un sabor cítrico, dulce y refrescante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "vodkastarlight.png",
            notification = 'Vodka y Sprunk... una mezcla cítrica que entra peligrosamente bien.',
        }
    },

    ["tigrebullstarlight"] = {
        label = "Ron Tigre",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Potente combinado de ron añejo con bebida energética, creado para mantener vivo el ritmo de la noche.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "tigrebullstarlight.png",
            notification = 'Ron y energía en un solo vaso... ¡ya estoy listo para rugir!',
        }
    },

    ["colalightstarlight"] = {
        label = "Cola Zero Zero",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Refresco de cola ligero y burbujeante, con todo el sabor clásico y sin azúcar.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "colalightstarlight.png",
            notification = 'Todo el sabor de la cola y sin azúcar... qué refrescante.',
        }
    },

    ["malibustarlight"] = {
        label = "Malibu con Piña",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Combinado tropical de licor de coco y zumo de piña, dulce, suave y refrescante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "malibustarlight.png",
            notification = 'Coco y piña... un viaje tropical en cada sorbo.',
        }
    },

    ["aguagasstarlight"] = {
        label = "Agua con Gas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Agua fría y refrescante con finas burbujas, perfecta para calmar la sed.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'vw_prop_casino_water_bottle_01a', pos = vec3(0.01, 0.01, -0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "aguagasstarlight.png",
            notification = 'Fría, ligera y llena de burbujas... justo lo que necesitaba.',
        }
    },

    ["kikosstarlight"] = {
        label = "Kikos Estrellados",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Crujientes granos de maíz tostado y sazonado, perfectos para picar mientras disfrutas de la noche.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, 0.0, 0.0), rot = vec3(90.0, 0.0, 40.0) },
            usetime = 3500,
            image = "kikosstarlight.png",
            notification = 'Crujientes y sabrosos... no podía parar de comerlos.',
        }
    },

    ["pinchostarlight"] = {
        label = "Pincho de Steak",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Jugoso pincho de steak cocinado al punto y sazonado para potenciar todo el sabor de la carne.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_steak', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "pinchostarlight.png",
            notification = 'Jugoso y cocinado al punto... este steak estaba increíble.',
        }
    },

    ["canapestarlight"] = {
        label = "Canapé de Gamba",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Delicado canapé coronado con una sabrosa gamba y acompañado de ingredientes frescos.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "canapestarlight.png",
            notification = 'Delicado, fresco y lleno de sabor... un canapé perfecto.',
        }
    },

    ["llaverostarlight"] = {
        label = "Llavero de Estrella",
        weight = 3,
        stack = true,
        close = true,
        description = "Elegante llavero coleccionable con forma de estrella y el distintivo diseño de Starlight.",
        client = {
            image = "llaverostarlight.png",
        }
    },

    ["abrebotellasstarlight"] = {
        label = "Abrebotellas Portátil",
        weight = 3,
        stack = true,
        close = true,
        description = "Abrebotellas portátil y coleccionable de Starlight, perfecto para llevarlo siempre contigo.",
        client = {
            image = "abrebotellasstarlight.png",
        }
    },

    -- ARCADE

    ['plush1'] = {
        label = 'Peluche 1',
        description = 'Un bonito peluche achuchable.',
        stack = false,
        weight = 10,
    },


    ['plush2'] = {
        label = 'Peluche 2',
        description = 'Un bonito peluche achuchable.',
        stack = false,
        weight = 10,
    },

    ['plush3'] = {
        label = 'Peluche 3',
        description = 'Un bonito peluche achuchable.',
        stack = false,
        weight = 10,
    },

    ['plush4'] = {
        label = 'Peluche 4',
        description = 'Un bonito peluche achuchable.',
        stack = false,
        weight = 10,
    },

    ['plush5'] = {
        label = 'Peluche 5',
        description = 'Un bonito peluche achuchable.',
        stack = false,
        weight = 10,
    },

    ['plush6'] = {
        label = 'Peluche 6',
        description = 'Un bonito peluche achuchable.',
        stack = false,
        weight = 10,
    },

    ['plushmaster'] = {
        label = 'Peluche Master',
        description = 'Un peluche maestro.',
        stack = false,
        weight = 10,
    },

    ['plushprincess'] = {
        label = 'Peluche Princesa',
        description = 'Un peluche de princesa.',
        stack = false,
        weight = 10,
    },

    ['plushwasabi'] = {
        label = 'Peluche Wasabi',
        description = 'Un peluche de wasabi.',
        stack = false,
        weight = 10,
    },

    ["palomitasarcade"] = {
        label = "Palomitas Arcade",
        weight = 3,
        stack = true,
        close = true,
        degrade = 1440,
        decay = true,
        description = "Clásicas palomitas de maíz, recién estalladas, suaves y deliciosamente crujientes.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'bbs_eating_spoon', clip = 'bbs_eating_spoon' },
            prop = { model = 'bbs_popcorn_seasoned', bone = 18905, pos = vec3(0.1500, 0.0570, 0.0200), rot = vec3(9.0, 4.0, -160.0) },
            usetime = 3500,
            image = "palomitasarcade.png",
            notification = 'Bofff... me he acabado todo en muy poco tiempo, que bueno estaba.',
        }
    },

    ["refrescoarcade"] = {
        label = "Refresco Eights Bit",
        weight = 3,
        stack = true,
        close = true,
        degrade = 1440,
        decay = true,
        description = "Una bebida refrescante y nostálgica con un toque original, perfecta para gamers y nostálgicos.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            image = "refrescoarcade.png",
            notification = 'Bofff... me lo he bebido en nada.',
        }
    },

    ["arcadecolecciongosh"] = {
        label = "H-B ARCADE Pixel Gosh",
        weight = 3,
        stack = true,
        close = true,
        description = "Figura coleccionable de Pixel Gosh con un divertido diseño inspirado en los videojuegos clásicos.",
        client = { image = "arcadecoleccion1.png" }
    },

    ["arcadecoleccion2"] = {
        label = "H-B ARCADE Robocín",
        weight = 3,
        stack = true,
        close = true,
        description = "Un pequeño robot coleccionable llegado directamente del universo arcade.",
        client = { image = "arcadecoleccion2.png" }
    },

    ["arcadecoleccion3"] = {
        label = "H-B ARCADE Conejito",
        weight = 3,
        stack = true,
        close = true,
        description = "Un adorable conejito coleccionable con estética de videojuego retro.",
        client = { image = "arcadecoleccion3.png" }
    },

    ["arcadecoleccion4"] = {
        label = "H-B ARCADE White Gosh",
        weight = 3,
        stack = true,
        close = true,
        description = "Edición blanca y especial de Gosh, creada para los coleccionistas del mundo arcade.",
        client = { image = "arcadecoleccion4.png" }
    },

    ["arcadecoleccion5"] = {
        label = "H-B ARCADE Retro Game",
        weight = 3,
        stack = true,
        close = true,
        description = "Una pieza coleccionable que rinde homenaje a las máquinas y videojuegos de otra época.",
        client = { image = "arcadecoleccion5.png" }
    },

    ["arcadecoleccion6"] = {
        label = "H-B ARCADE Gato Galáctico",
        weight = 3,
        stack = true,
        close = true,
        description = "Un gato espacial coleccionable preparado para recorrer las galaxias entre píxeles.",
        client = { image = "arcadecoleccion6.png" }
    },

    ["arcadecoleccion7"] = {
        label = "H-B ARCADE Super Star",
        weight = 3,
        stack = true,
        close = true,
        description = "Una brillante estrella coleccionable reservada para auténticos campeones del arcade.",
        client = { image = "arcadecoleccion7.png" }
    },
    -- KOI RESTAURANT

    ["ramenkoi"] = {
        label = "Ramen",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Caldo japonés cocinado a fuego lento, fideos artesanales, huevo marinado, cebollino y un toque de aceite aromático.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "ramenkoi.png",
            notification = 'Caliente, aromático y lleno de sabor... este ramen estaba increíble.',
        }
    },

    ["gyozaskoi"] = {
        label = "Gyozas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Delicadas empanadillas japonesas rellenas de carne y verduras, doradas a la plancha y cocinadas al vapor.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_taco_02', pos = vec3(0.03, 0.05, -0.01), bone = 58867, rot = vec3(90.0, 0.0, 45.0) },
            usetime = 3500,
            image = "gyozaskoi.png",
            notification = 'Doradas por fuera y jugosas por dentro... no ha quedado ni una gyoza.',
        }
    },

    ["sushikoi"] = {
        label = "Tabla de Sushi",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una cuidada selección de sushi elaborado al momento con pescado fresco, arroz sazonado y los mejores ingredientes japoneses.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "sushikoi.png",
            notification = 'Pescado fresco y arroz perfectamente sazonado... una tabla exquisita.',
        }
    },

    ["gambaskoi"] = {
        label = "Gambas en Tempura",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Jugosas gambas rebozadas en una ligera tempura japonesa, crujientes por fuera y tiernas por dentro.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "gambaskoi.png",
            notification = 'Tempura ligera y crujiente, con gambas tiernas por dentro... deliciosas.',
        }
    },

    ["cervezakoi"] = {
        label = "Cerveza KOI",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cerveza tipo lager refrescante, de sabor suave y equilibrado, ideal para disfrutar bien fría en cualquier ocasión.",
        client = {
            image = "cervezakoi.png",
            notification = 'Suave, equilibrada y bien fría... una lager perfecta.',
        }
    },

    ["ramunekoi"] = {
        label = "Ramune",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Refresco japonés Ramune, dulce y burbujeante, conocido por su icónica botella con canica de vidrio, perfecto para una bebida refrescante y divertida.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'vw_prop_casino_water_bottle_01a', pos = vec3(0.01, 0.01, -0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "ramunekoi.png",
            notification = 'Dulce, burbujeante y muy divertida... la canica le da un toque especial.',
        }
    },

    ["teverdekoi"] = {
        label = "Té Verde",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Té verde suave y aromático, de sabor ligero y refrescante, ideal para disfrutar caliente o frío en cualquier momento del día.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "teverdekoi.png",
            notification = 'Suave, ligero y aromático... este té verde transmite mucha calma.',
        }
    },

    ["sakekoi"] = {
        label = "Sake",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Bebida tradicional japonesa de arroz fermentado, suave y ligeramente afrutada, ideal para acompañar comidas o disfrutar en ocasiones especiales.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "sakekoi.png",
            notification = 'Suave, afrutado y tradicional... un sake perfecto para la ocasión.',
        }
    },

    ["pandakoi"] = {
        label = "Pandita",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Adorable panda de peluche coleccionable de KOI, con un encantador diseño inspirado en la cultura japonesa.",
        client = {
            image = "pandakoi.png",
        }
    },

    -- == YELLOW JACK ==

    ["cervezanegrayellow"] = {
        label = "Cerveza Negra",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una cerveza con cuerpo, notas intensas a malta tostada, café y chocolate. Ideal para quienes buscan un sabor profundo y complejo.",
        client = {
            image = "cervezanegrayellow.png",
            notification = 'Intensa, tostada y con mucho cuerpo... una cerveza con carácter.',
        }
    },

    ["jarracervezayellow"] = {
        label = "Jarra de Cerveza",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "La medida perfecta de cerveza bien fría, servida en jarra helada para mantener su frescura y espuma hasta el último sorbo.",
        client = {
            image = "jarracervezayellow.png",
            notification = 'Jarra helada, cerveza fresca y espuma hasta el último sorbo.',
        }
    },

    ["colazeroyellow"] = {
        label = "Cola Zero",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Todo el sabor refrescante y burbujeante de la cola clásica, pero sin azúcar y sin calorías.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "colazeroyellow.png",
            notification = 'Todo el sabor de la cola, muchas burbujas y nada de azúcar.',
        }
    },

    ["orangesodayellow"] = {
        label = "Soda de Naranja",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un refresco lleno de sabor frutal, brillante y burbujeante; la opción dulce y cítrica ideal para refrescarse.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_orang_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "orangesodayellow.png",
            notification = 'Dulce, cítrica y llena de burbujas... muy refrescante.',
        }
    },


    ["alitaspolloyellow"] = {
        label = "Alitas de Pollo Jack",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Crujientes alitas bañadas en nuestra exclusiva salsa barbacoa al estilo Jack Angel’s, con un equilibrio perfecto entre dulce y ahumado.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_turkey_leg_01', pos = vec3(0.03, -0.01, 0.0), rot = vec3(90.0, -10.0, 0.0), bone = 4186 },
            usetime = 3500,
            image = "alitaspolloyellow.png",
            notification = 'Crujientes, dulces y ahumadas... estas alitas estaban increíbles.',
        }
    },

    ["albondigasyellow"] = {
        label = "Albóndigas en Salsa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Jugosas albóndigas de carne seleccionada, cocinadas a fuego lento en una salsa tradicional casera llena de sabor.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "albondigasyellow.png",
            notification = 'Jugosas y cocinadas lentamente en una salsa casera deliciosa.',
        }
    },

    ["chuletonyellow"] = {
        label = "Chuletón",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Impresionante corte de carne madurada, hecho a la brasa para lograr un exterior marcado y un interior tierno y lleno de jugosidad.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_steak', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "chuletonyellow.png",
            notification = 'Marcado por fuera, tierno por dentro y lleno de jugosidad.',
        }
    },

    ["parrilladacarneyellow"] = {
        label = "Parrillada de Carne",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una selección premium de las mejores piezas de carne, asadas al punto perfecto para disfrutar de la máxima calidad y variedad.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_steak', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "parrilladacarneyellow.png",
            notification = 'Una selección de carnes premium asadas exactamente en su punto.',
        }
    },

    ["llaveromotoyellow"] = {
        label = "Llavero YellowJack",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Llavero coleccionable inspirado en el espíritu motero de Yellow Jack, perfecto para llevar las llaves con auténtico estilo.",
        client = {
            image = "llaveromotoyellow.png",
        }
    },

    ["montaditolastnight"] = {
        label = "Montadito del Barrio",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Pan tostado con lomo, queso y pimiento.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "montaditolastnight.png",
            notification = 'Lomo, queso y pimiento sobre pan tostado... todo un sabor de barrio.',
        }
    },

    ["pinchogitano"] = {
        label = "Pincho Gitano",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Brocheta de carne especiada con patatas.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_steak', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "pinchogitano.png",
            notification = 'Carne especiada y patatas... este pincho tenía muchísimo sabor.',
        }
    },

    ["bocatadelacasa"] = {
        label = "Bocata de la Casa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Bocadillo de lomo, jamón, queso y salsa especial de la casa.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "bocatadelacasa.png",
            notification = 'Lomo, jamón, queso y la salsa secreta... menudo bocata.',
        }
    },

    ["platodelaabuela"] = {
        label = "Plato de la Abuela",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Carne guisada lentamente con patatas caseras al estilo tradicional.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "platodelaabuela.png",
            notification = 'Carne guisada y patatas caseras... como lo preparaba la abuela.',
        }
    },

    ["malibusmash"] = {
        label = "Malibu Smash",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una smashburger de película, con carne jugosa, queso fundido y todo el sabor de Malibu.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "malibusmash.png",
            notification = 'Carne jugosa y queso fundido... esta smashburger era de película.',
        }
    },

    ["frutossecosmalibu"] = {
        label = "Frutos Secos",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Selección de frutos secos variados, tostados y crujientes, ideales como snack saludable y energético en cualquier momento del día.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, 0.0, 0.0), rot = vec3(90.0, 0.0, 40.0) },
            usetime = 3500,
            image = "frutossecosmalibu.png",
            notification = 'Tostados, variados y crujientes... un aperitivo perfecto.',
        }
    },

    ["rontigre"] = {
        label = "Ron Tigre",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Ron Tigre servido con abundante hielo para disfrutar de todo su carácter.",
        client = {
            image = "rontigre.png",
            notification = 'Ron Tigre con mucho hielo... un trago con auténtico carácter.',
        }
    },

    ["canadelbarrio"] = {
        label = "Caña del Barrio",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Cerveza fría tirada con espuma y auténtico sabor de barrio.",
        client = {
            image = "canadelbarrio.png",
            notification = 'Bien fría, recién tirada y con su espuma... una caña de barrio.',
        }
    },

    ["cafedelbarrio"] = {
        label = "Café del Barrio",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Tanta nata y suerte en una sola copa que te arregla la vida en dos tragos.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafedelbarrio.png",
            notification = 'Café, mucha nata y un golpe de suerte... la vida ya pinta mejor.',
        }
    },

    ["cocadelbarrio"] = {
        label = "Coca Cola del Barrio",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Coca Cola bien fresquita, que entra en el cuerpo del tirón.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "cocadelbarrio.png",
            notification = 'Bien fresquita y con muchas burbujas... ha entrado del tirón.',
        }
    },

    ["ciervoloco"] = {
        label = "Ciervo Loco",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un potente combinado energético preparado para darte la fuerza necesaria durante toda la noche.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_energy_drink', pos = vec3(0.03, 0.05, 0.0), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "ciervoloco.png",
            notification = '¡Menudo chute! Ahora tengo la energía de un toro.',
        }
    },

    ["purpleextasy"] = {
        label = "Purple Extasy",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una llamativa bebida morada, dulce y vibrante, creada para convertir cada sorbo en una experiencia.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "purpleextasy.png",
            notification = 'Dulce, vibrante y completamente morada... me he puesto morado.',
        }
    },

    ["yelloworgasm"] = {
        label = "Yellow Orgasm",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cóctel amarillo de sabor cítrico, intenso y refrescante, perfecto para sentir el frescor de la noche.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "yelloworgasm.png",
            notification = 'Cítrico, intenso y helado... menudo golpe de frescor.',
        }
    },

    ["roncolamalibu"] = {
        label = "Ron Cola",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Combinado burbujeante con el equilibrio perfecto entre el dulzor de la cola y el carácter ligeramente amargo del ron.",
        client = {
            image = "roncolamalibu.png",
            notification = 'Ron, cola y muchas burbujas... un clásico que nunca falla.',
        }
    },

    ["jaggermalibu"] = {
        label = "Jagger Malibu",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un trago intenso con un carácter fuerte, preparado para los más atrevidos.",
        client = {
            image = "jaggermalibu.png",
            notification = 'Oscuro, intenso y con mucho carácter... no es para cualquiera.',
        }
    },

    ["pitilleradelbarrio"] = {
        label = "Pitillera del Barrio",
        weight = 3,
        stack = true,
        close = true,
        description = "Estuche metálico vintage personalizado con el auténtico estilo del Barrio.",
        client = {
            image = "pitilleradelbarrio.png",
        }
    },

    ["llaveromalibu"] = {
        label = "Llavero Malibu",
        weight = 3,
        stack = true,
        close = true,
        description = "Elegante llavero coleccionable con el distintivo diseño de Malibu Pub.",
        client = {
            image = "llaveromalibu.png",
        }
    },

    --- ==== BOWLING
    ["refrescodenaranjabowlingbar"] = {
        label = "Refresco Naranja Bowling Bar",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "El clásico refresco de naranja, supercítrico y burbujeante, ideal para acompañar tus partidas.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_orang_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "refrescodenaranjabowlingbar.png",
            notification = 'Supercítrico, burbujeante y bien frío... perfecto para seguir jugando.',
        }
    },

    ["refrescodelimonbowlingbar"] = {
        label = "Refresco Limón Bowling Bar",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un trago ultrarrefrescante, ácido y chispeante que despierta los sentidos.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "refrescodelimonbowlingbar.png",
            notification = 'Ácido, chispeante y muy refrescante... me ha despertado los sentidos.',
        }
    },

    ["granizadodefresabowlingbar"] = {
        label = "Granizado Fresa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Hielo picado extrafino empapado en un dulce y refrescante sirope de fresa natural.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "granizadodefresabowlingbar.png",
            notification = 'Hielo picado y dulce sirope de fresa... qué granizado tan refrescante.',
        }
    },

    ["refrescodecolabowlingbar"] = {
        label = "Refresco Cola Bowling Bar",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "La bebida de cola de siempre, con el balance perfecto de gas y ese sabor inconfundible.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "refrescodecolabowlingbar.png",
            notification = 'Bien fría, con el gas perfecto y ese sabor clásico que nunca falla.',
        }
    },

    ["chocolatinabowlingbar"] = {
        label = "Chocolatina Bowling Bar",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una barrita de chocolate crujiente y divertida, perfecta para un subidón de energía entre partida y partida.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_choc_meto', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "chocolatinabowlingbar.png",
            notification = 'Crujiente y llena de chocolate... energía suficiente para otra partida.',
        }
    },

    ["gominolasbowlingba"] = {
        label = "Gominolas Bowling Bar",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un surtido multicolor de gominolas brillantes y ácidas, ideales para compartir mientras esperas tu turno.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'xs_prop_trinket_cup_01a', pos = vec3(0.03, 0.05, -0.13), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "gominolasbowlingba.png",
            notification = 'Dulces, ácidas y llenas de color... se han acabado antes de mi turno.',
        }
    },

    ["cacahuetesbowlingbar"] = {
        label = "Bowl de Cacahuetes",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "El clásico picoteo salado y crujiente, perfecto para acompañar cualquier bebida en la barra.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "cacahuetesbowlingbar.png",
            notification = 'Salados y crujientes... el picoteo perfecto para acompañar la bebida.',
        }
    },

    ["heladobowlingbar"] = {
        label = "Helado Bowling Bar",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una copa helada, cremosa y refrescante, coronada con tus siropes y toppings favoritos para cerrar la jugada con broche de oro.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'xs_prop_trinket_cup_01a', pos = vec3(0.03, 0.05, -0.13), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "heladobowlingbar.png",
            notification = 'Cremoso, helado y cargado de toppings... una jugada perfecta.',
        }
    },

    ["trofeobowlingbar"] = {
        label = "Peluche Trofeo Bowling-Bar",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Peluche coleccionable con forma de trofeo de Bowling-Bar, un premio perfecto para recordar tus mejores partidas.",
        client = {
            image = "trofeobowlingbar.png",
        }
    },

    -- ======= SKY

    ["nectardivino"] = {
        label = "Néctar Divino",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "La leche de los dioses, una bebida celestial reservada para los paladares más exigentes.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "nectardivino.png",
            notification = 'Cremoso, celestial y digno de los dioses... esto es otro nivel.',
        }
    },

    ["mojitofresa"] = {
        label = "Mojito de Fresa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un mojito dulce y refrescante de fresa que entra como el agua durante el verano.",
        client = {
            image = "mojitofresa.png",
            notification = 'Fresa, menta y mucho hielo... esto entra como agua en verano.',
        }
    },

    ["chupitosky"] = {
        label = "Chupito de Jäger",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un chupito intenso de Jäger, solo para valientes que estén más fuertes que una roca.",
        client = {
            image = "chupitosky.png",
            notification = '¡De un solo trago! Hay que estar más fuerte que una roca para esto.',
        }
    },

    ["champansky"] = {
        label = "Champán Diamante",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "El champán de los millonarios, elegante, exclusivo y lleno de burbujas.",
        client = {
            image = "champansky.png",
            notification = 'Elegante, exclusivo y lleno de burbujas... así beben los millonarios.',
        }
    },

    ["bebidadiosa"] = {
        label = "Bebida para una Diosa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una bebida dulce y seductora, preparada especialmente para conquistar a cualquier diosa.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "bebidadiosa.png",
            notification = 'Dulce y seductora... una bebida digna de una auténtica diosa.',
        }
    },

    ["pepitosky"] = {
        label = "Bocadillo de Pepito",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un sabroso bocadillo de pepito, perfecto para alegrarte la tarde.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "pepitosky.png",
            notification = 'Un buen pepito siempre consigue alegrarte la tarde.',
        }
    },

    ["patatasfritas"] = {
        label = "Patatas Fritas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Crujientes patatas fritas con el punto justo de sal, perfectas para picar y pasar el rato.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "patatasfritas.png",
            notification = 'Crujientes y con el punto justo de sal... no ha quedado ni una.',
        }
    },

    ["bocatamonsky"] = {
        label = "Bocamón de Jadillo",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un bocadillo enorme y lleno de sabor que te transportará directamente a las playas de España.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "bocatamonsky.png",
            notification = 'Un bocado y ya parece que estoy en una playa de España.',
        }
    },

    ["abrelatasky"] = {
        label = "Abrelatas",
        weight = 3,
        stack = true,
        close = true,
        description = "Abrelatas metálico, vintage y personalizado, perfecto para abrir cualquier botellín.",
        client = {
            image = "abrelatasky.png",
        }
    },

    ["peluchesky"] = {
        label = "El Peluche de los Dioses",
        weight = 3,
        stack = true,
        close = true,
        description = "Peluche celestial de edición especial, más suave que una nube de los mismísimos dioses.",
        client = {
            image = "peluchesky.png",
        }
    },

    -- ======= UP N ATOM

    ["burgertriple"] = {
        label = "Supernova Triple Burger",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Tres capas de carne a la parrilla, queso fundido y vegetales frescos en pan con sésamo. Una explosión de sabor de tamaño cósmico.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "burgertriple.png",
            notification = 'Tres capas de carne y queso fundido... una explosión de sabor cósmica.',
        }
    },

    ["nuggetscosmico"] = {
        label = "Nuggets Cósmicos",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Crujientes bocados de pechuga de pollo rebozada, fritos a la perfección. El acompañamiento ideal para compartir con la tripulación.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "nuggetscosmico.png",
            notification = 'Crujientes y dorados a la perfección... la tripulación no ha dejado ninguno.',
        }
    },

    ["patatasupn"] = {
        label = "Patatas Cráter con Queso",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Patatas fritas doradas bañadas en cremoso queso cheddar caliente y espolvoreadas con cebollino. Un clásico irresistible.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "patatasupn.png",
            notification = 'Doradas, cubiertas de cheddar y cebollino... no ha quedado ni un cráter.',
        }
    },

    ["burgerclasica"] = {
        label = "Orbital Cheese Burger",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Jugosa carne de ternera, queso derretido, lechuga y tomate fresco. Tu dosis de energía ideal para el día a día.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "burgerclasica.png",
            notification = 'Carne jugosa, queso derretido y vegetales frescos... energía orbital recargada.',
        }
    },

    ["refrescoatomico"] = {
        label = "Refresco Atómico",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Tu refresco favorito bien frío, servido en un vaso temático. La hidratación rápida que necesitas a la velocidad de la luz.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "refrescoatomico.png",
            notification = 'Bien frío y lleno de burbujas... hidratación a la velocidad de la luz.',
        }
    },

    ["aguaatomica"] = {
        label = "Agua H2O Estelar",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Agua mineral pura embotellada para mantenerte fresco y con energía durante tu misión.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'vw_prop_casino_water_bottle_01a', pos = vec3(0.01, 0.01, -0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "aguaatomica2.png",
            notification = 'Agua mineral pura y refrescante... ya puedo continuar con la misión.',
        }
    },

    ["batidoatomico"] = {
        label = "Batido Vía Láctea",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cremoso batido artesanal servido con una generosa capa de nata montada. El postre dulce definitivo del espacio.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "batidoatomico.png",
            notification = 'Cremoso y cubierto de nata... el batido definitivo de la galaxia.',
        }
    },

    ["juiceatomico"] = {
        label = "Kids Juice Blaster",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Zumo de frutas en brik con pajita, perfecto para recargar la energía de los pequeños astronautas.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "juiceatomico.png",
            notification = 'Fruta y energía para pequeños astronautas... ¡listo para despegar!',
        }
    },

    ["pelucheatomico"] = {
        label = "Peluche Astronauta Up-n-Atom",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Suave y mullido peluche coleccionable con traje espacial y casco visor. El recuerdo perfecto de tu visita a la estación.",
        client = {
            image = "pelucheatomico.png",
        }
    },


    -- ======= RUTA 68

    ["cocheruta68"] = {
        label = "GTR Naranja",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Miniatura coleccionable de un espectacular GTR naranja, diseñada para los amantes de la velocidad y de Ruta 68.",
        client = {
            image = "cocheruta68.png",
        }
    },

    ["ositotuta68"] = {
        label = "Osito Ruta",
        weight = 3,
        stack = true,
        close = true,
        description = "Adorable oso de peluche coleccionable inspirado en Ruta 68, perfecto como compañero de viaje.",
        client = {
            image = "ositotuta68.png",
        }
    },

    -- ======= BADURUTA 68
    ["bocatabadur"] = {
        label = "Bocata de Jamón",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Sencillo, tradicional y delicioso; excelente jamón de calidad con un toque de aceite de oliva en pan de barra.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "bocatabadur.png",
            notification =
            'Sencillo, tradicional y delicioso; excelente jamón de calidad con un toque de aceite de oliva en pan de barra.',
        }
    },

    ["donutbadur"] = {
        label = "Donut de fresa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Rosquilla tierna y esponjosa cubierta con un vistoso y dulce glaseado de fresa.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "donutbadur.png",
            notification = 'Rosquilla tierna y esponjosa cubierta con un vistoso y dulce glaseado de fresa.',
        }
    },

    ["pepitobadur"] = {
        label = "Pepito de Chocolate",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Bollo tierno y alargado, generosamente relleno o cubierto de una cremosa capa de chocolate.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "pepitobadur.png",
            notification = 'Bollo tierno y alargado, generosamente relleno o cubierto de una cremosa capa de chocolate.',
        }
    },

    ["pizzabadur"] = {
        label = "Porción Pizza 4 Quesos",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una jugosa porción de masa crujiente cubierta con una rica y fundente mezcla de cuatro quesos seleccionados.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "pizzabadur.png",
            notification =
            'Una jugosa porción de masa crujiente cubierta con una rica y fundente mezcla de cuatro quesos seleccionados.',
        }
    },

    ["cafeheladobadur"] = {
        label = "Café Helado",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Café batido con hielo, extra cremoso y refrescante, ideal para los días calurosos.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafeheladobadur.png",
            notification = 'Café batido con hielo, extra cremoso y refrescante, ideal para los días calurosos.',
        }
    },

    ["colabadur"] = {
        label = "Cola",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "La bebida de cola de siempre, con el balance perfecto de gas y ese sabor inconfundible.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'vw_prop_casino_water_bottle_01a', pos = vec3(0.01, 0.01, -0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "colabadur.png",
            notification = 'La bebida de cola de siempre, con el balance perfecto de gas y ese sabor inconfundible.',
        }
    },

    ["fantabadur"] = {
        label = "Soda de Naranja",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Agua carbonatada clásica o con un sutil toque cítrico de naranja, ligera y refrescante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "fantabadur.png",
            notification = 'Agua carbonatada clásica o con un sutil toque cítrico de naranja, ligera y refrescante.',
        }
    },

    ["teheladobadur"] = {
        label = "Té Helado",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Selección de hierbas naturales relajantes, disponible en caliente o en su versión helada y frutal.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "teheladobadur.png",
            notification =
            'Selección de hierbas naturales relajantes, disponible en caliente o en su versión helada y frutal.',
        }
    },

    ["patataarcade"] = {
        label = "Patatas Vargas Rush",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Frituras de maíz sazonadas con especias picantes y sal.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, 0.0, 0.0), rot = vec3(90.0, 0.0, 40.0) },
            usetime = 3500,
            image = "patataarcade.png",
            notification = 'Crujientes, saladas y con un toque picante... menudo vicio.',
        }
    },

    ["burgerarcade"] = {
        label = "Hamburguesa Arcade",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Pan de sésamo con carne de res, queso cheddar, tomate, lechuga y cebolla.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "burgerarcade.png",
            notification = 'Carne, cheddar y vegetales frescos... energía recargada para otra partida.',
        }
    },

    ["pizzaarcade"] = {
        label = "Arcade Pizza",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Masa de trigo horneada con salsa de tomate, queso mozzarella y pepperoni.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "pizzaarcade.png",
            notification = 'Mozzarella fundida y pepperoni... esta pizza se merece una puntuación récord.',
        }
    },

    ["nachosarcade"] = {
        label = "Nachos Cheese Arcade",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Totopos de maíz fritos cubiertos con queso fundido, crema y jalapeños.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "nachosarcade.png",
            notification = 'Queso fundido, crema y jalapeños... no ha quedado ni un nacho.',
        }
    },

    ["kebabcaretacerdo"] = {
        label = "Kebab Careta de Cerdo",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un kebab relleno de careta de cerdo, perfecto para degustar una buena careta de cerdo.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "kebabcaretacerdo.png",
            notification = 'Careta de cerdo bien sabrosa dentro de un kebab... menudo invento.',
        }
    },

    ["kebabpancetahinojos"] = {
        label = "Kebab de Panceta con Hinojos",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un kebab relleno de panceta con hinojos; quien poco a poco lo hinca, se lo merienda de un antojo.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "kebabpancetahinojos.png",
            notification = 'Panceta con hinojos... poco a poco lo he hincado y de un antojo me lo he acabado.',
        }
    },

    ["energeticaarcade"] = {
        label = "Energética Rush Arcade",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Bebida carbonatada elaborada con cafeína, taurina, azúcar y una intensa combinación de sabores.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_energy_drink', pos = vec3(0.03, 0.05, 0.0), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "energeticaarcade.png",
            notification = '¡Menudo chute de energía! Ya estoy listo para superar mi récord.',
        }
    },

    ["cafearcade"] = {
        label = "Café Pixel Brew",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Café negro concentrado con leche, azúcar y hielo.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafearcade.png",
            notification = 'Café intenso, leche y mucho hielo... energía en cada píxel.',
        }
    },

    ["granizadoarcade"] = {
        label = "Granizado Pixel Slush",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Hielo picado con jarabe concentrado de mora y cereza.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "granizadoarcade.png",
            notification = 'Mora, cereza y hielo picado... una recarga muy refrescante.',
        }
    },

    ["sodaarcade"] = {
        label = "Refresco Pixel Soda",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Refresco carbonatado con sabor dulce y cítrico a lima y limón.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "sodaarcade.png",
            notification = 'Lima, limón y muchas burbujas... refrescante hasta el último píxel.',
        }
    },

    ["refresnaranja"] = {
        label = "Refresco Naranja",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una bebida dulce, gaseosa y refrescante, con un intenso sabor a naranja y un toque cítrico que la hace irresistible.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_orang_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "refresnaranja.png",
            notification = 'Dulce, cítrico y con muchas burbujas... qué refrescante.',
        }
    },

    ["refresnestel"] = {
        label = "Renestel de Limón",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una bebida dulce, gaseosa y refrescante, con un sabor fresco a limón y un toque ácido que la hace especialmente refrescante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "refresnestel.png",
            notification = 'Dulce, ácido y lleno de burbujas... el limón entra solo.',
        }
    },

    ["llaveroarcade"] = {
        label = "Llavero Pixel-Blade",
        weight = 3,
        stack = true,
        close = true,
        description = "Llavero metálico de colección con una figura acrílica de refresco en forma de katana.",
        client = {
            image = "llaveroarcade.png",
        }
    },

    ["viparcade"] = {
        label = "Tarjeta VIP Arcade",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Tarjeta VIP coleccionable de Arcade, reservada para los jugadores más destacados y los auténticos maestros de las recreativas.",
        client = {
            image = "viparcade.png",
        }
    },
    ["vanillachips"] = {
        label = "Vanilla Chips",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Disfruta del sabor de la lujuria, con el punto perfecto de sal.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, 0.0, 0.0), rot = vec3(90.0, 0.0, 40.0) },
            usetime = 3500,
            image = "vanillachips.png",
            notification = 'Crujientes y con el punto perfecto de sal... puro sabor a lujuria.',
        }
    },

    ["vanillaalitas"] = {
        label = "Alitas Unicornio",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Alitas de pollo crujientes con salsa picante, al estilo Vanilla Unicorn.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_turkey_leg_01', pos = vec3(0.03, -0.01, 0.0), rot = vec3(90.0, -10.0, 0.0), bone = 4186 },
            usetime = 3500,
            image = "vanillaalitas.png",
            notification = 'Crujientes y picantes... estas alitas tienen fuego de unicornio.',
        }
    },

    ["vanillabocata"] = {
        label = "El Pecadito",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "El bocata que no pregunta, simplemente se disfruta.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "vanillabocata.png",
            notification = 'Este pecadito no hace preguntas... solo se disfruta.',
        }
    },

    ["vanillatortilla"] = {
        label = "La Tortillona",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Tortilla de patatas bien jugosa por dentro y perfectamente dorada por fuera.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "vanillatortilla.png",
            notification = 'Jugosa por dentro y doradita por fuera... menuda tortillona.',
        }
    },

    ["cuenco77"] = {
        label = "Cuenco de Maníes",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Crujientes maníes tostados y salados, el mejor acompañamiento para una buena cerveza.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "cuenco77.png",
            notification = 'Tostados, salados y crujientes... perfectos para acompañar la cerveza.',
        }
    },

    ["pizza77"] = {
        label = "Caja de Pizza",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una deliciosa pizza recién hecha, perfecta para compartir con amigos durante una buena fiesta.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "pizza77.png",
            notification = 'Pizza, amigos y una buena copa... no hace falta nada más.',
        }
    },

    ["papas77"] = {
        label = "Papas con Cheddar",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Papas fritas doradas cubiertas con abundante queso cheddar fundido, perfectas para acompañar una hamburguesa.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "papas77.png",
            notification = 'Doradas y cubiertas de cheddar... el acompañamiento perfecto.',
        }
    },

    ["tartacasino"] = {
        label = "Tarta Ruleta",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una espectacular tarta inspirada en la ruleta de un casino de lujo. El postre perfecto para celebrar una gran victoria.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood6', pos = vec3(0.01, 0.02, -0.01), rot = vec3(-170.0, 88.0, 30.0) },
            usetime = 3500,
            image = "tartacasino.png",
            notification = 'Una tarta digna de celebrar la mayor victoria del casino.',
        }
    },

    ["sushicasino"] = {
        label = "Selección de Sushi Diamond",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una exclusiva selección de sushi elaborada al momento con ingredientes premium.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "sushicasino.png",
            notification = 'Ingredientes premium y una preparación exquisita... auténtico sushi Diamond.',
        }
    },

    ["wagyucasino"] = {
        label = "Filete de Wagyu con Caviar",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un exquisito filete de Wagyu acompañado de caviar premium, reservado para los paladares más exigentes.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_steak', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "wagyucasino.png",
            notification = 'Wagyu y caviar premium... una experiencia gastronómica de lujo.',
        }
    },

    ["vipvanilla"] = {
        label = "Tarjeta VIP Vanilla",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP de Vanilla que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "vipvanilla.png",
        }
    },

    ["weazeltarjeta"] = {
        label = "Tarjeta de Empleado",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta identificativa de empleado de Weazel News.",
        client = {
            image = "weazeltarjeta.png",
        }
    },

    ["llaveroweazel"] = {
        label = "Llavero de Weazel News",
        weight = 3,
        stack = true,
        close = true,
        description = "Llavero coleccionable exclusivo con el distintivo diseño de Weazel News.",
        client = {
            image = "llaveroweazel.png",
        }
    },

    ["periodicoweazel"] = {
        label = "Periódico WZ",
        weight = 3,
        stack = true,
        close = true,
        description = "Periódico semanal de Weazel News con las noticias y los mejores chismes de la ciudad.",
        client = {
            image = "periodicoweazel.png",
        }
    },

    ["hambubadur"] = {
        label = "Hamburguesín",
        weight = 3,
        stack = true,
        close = true,
        description = "Figura coleccionable de Hamburguesín, la mascota principal del Badulaque de Ruta 68.",
        client = {
            image = "hambubadur.png",
        }
    },

    ["buffalos"] = {
        label = "Buffalo S",
        weight = 3,
        stack = true,
        close = true,
        description = "Miniatura coleccionable del Buffalo S, preparada para los amantes de los deportivos americanos.",
        client = {
            image = "buffalos.png",
        }
    },

    ["osoruta68"] = {
        label = "El Oso Ruta 68",
        weight = 3,
        stack = true,
        close = true,
        description = "Adorable oso de peluche coleccionable inspirado en la legendaria Ruta 68.",
        client = {
            image = "osoruta68.png",
        }
    },

    ["vip77"] = {
        label = "Tarjeta VIP Club 77",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP del Club 77 que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "vip77.png",
        }
    },

    ["clubcito"] = {
        label = "Clubcito 77",
        weight = 3,
        stack = true,
        close = true,
        description = "Divertida estrella bailona coleccionable y mascota oficial del Club 77.",
        client = {
            image = "clubcito.png",
        }
    },

    ["tarjetaabogado"] = {
        label = "Tarjeta de Contacto",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta de contacto de los abogados L.S. Luxury. Teléfono: (480) 907-2417.",
        client = {
            image = "tarjetaabogado.png",
        }
    },

    ["anilloabogado"] = {
        label = "Anillo de Plata",
        weight = 3,
        stack = true,
        close = true,
        description = "Anillo de plata de primera ley con el exclusivo grabado de L.S. Luxury.",
        client = {
            image = "anilloabogado.png",
        }
    },

    ["peluchetaxi"] = {
        label = "Peluche Taxi",
        weight = 3,
        stack = true,
        close = true,
        description = "Peluche coleccionable de un adorable osito acompañado por un taxi muy exclusivo.",
        client = {
            image = "peluchetaxi.png",
        }
    },

    ["taxidejuguete"] = {
        label = "Taxi de Juguete",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Miniatura coleccionable de un taxi de Los Santos, perfecta para los aficionados al transporte urbano.",
        client = {
            image = "taxidejuguete.png",
        }
    },

    ["asdelasuerte"] = {
        label = "As de la Suerte",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Un As de Picas legendario que atrae la fortuna a quien lo posee. Se dice que cada mano jugada con él puede cambiar el destino.",
        client = {
            image = "asdelasuerte.png",
        }
    },

    ["vipcasino"] = {
        label = "Tarjeta VIP Diamond Casino",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP del Diamond Casino que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "vipcasino.png",
        }
    },

    ["frescocola"] = {
        label = "Frescola",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Refresco con sabor a cola, fresco y burbujeante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "frescocola.png",
            notification = 'Fresca, dulce y llena de burbujas... qué bien entra.',
        }
    },

    ["vanillabeso"] = {
        label = "Beso Rosado",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Lujo y tentación en cada sorbo. La bebida exclusiva para noches que nadie olvida.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "vanillabeso.png",
            notification = 'Dulce, elegante y tentador... un beso difícil de olvidar.',
        }
    },

    ["vanillachampan"] = {
        label = "Champán Vanilla",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Lujo y tentación en cada sorbo. La bebida exclusiva para noches que nadie olvida.",
        client = {
            image = "vanillachampan.png",
            notification = 'Burbujas, lujo y tentación... una noche así no se olvida.',
        }
    },

    ["vanillachupito"] = {
        label = "Pecado Rosa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un chupito dulce, atrevido y peligrosamente fácil de beber.",
        client = {
            image = "vanillachupito.png",
            notification = 'Dulce, atrevido y peligrosamente fácil de beber.',
        }
    },

    ["vanillabatido"] = {
        label = "Unicorn Shake",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un batido dulce, cremoso y colorido que consigue subirte el azúcar y el ánimo.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "vanillabatido.png",
            notification = 'Cremoso, dulce y mágico... se me ha subido el azúcar y el ánimo.',
        }
    },

    ["cola77"] = {
        label = "KerryKcola",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "El clásico combinado de fernet y cola, intenso, refrescante y con un carácter inconfundible.",
        client = {
            image = "cola77.png",
            notification = 'Fernet, cola y mucho hielo... una combinación con auténtico carácter.',
        }
    },

    ["whisky77"] = {
        label = "Whiskey Stone",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un whiskey intenso y robusto, creado para quienes están más fuertes que una roca.",
        client = {
            image = "whisky77.png",
            notification = 'Intenso, robusto y duro como una roca... un whiskey con carácter.',
        }
    },

    ["vodka77"] = {
        label = "Vodka Merry",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "El vodka de los piratas, un trago intenso reservado para las tripulaciones más atrevidas.",
        client = {
            image = "vodka77.png",
            notification = 'Un vodka intenso digno de la tripulación pirata más atrevida.',
        }
    },

    ["cerveza77"] = {
        label = "Santa Beer",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una cerveza celestial y refrescante, bendecida para convertir cada sorbo en un pequeño milagro.",
        client = {
            image = "cerveza77.png",
            notification = 'Fría, celestial y bendecida... cada sorbo parece un milagro.',
        }
    },

    ["bluestart"] = {
        label = "Blue Star",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Whisky de lujo de alta gama, reconocido por su extraordinaria calidad y exclusividad.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "bluestart.png",
            notification = 'Elegante, exclusivo y de una calidad extraordinaria... auténtico lujo.',
        }
    },

    ["champancasino"] = {
        label = "Champán",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Botella de champán premium, perfecta para celebrar ocasiones especiales y grandes victorias.",
        client = {
            image = "champancasino.png",
            notification = 'Champán premium y muchas burbujas... brindemos por la victoria.',
        }
    },

    ["jalapenostekila"] = {
        label = "Jalapeños Picantes",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Crujientes por fuera, explosivos por dentro y con el picante necesario para aguantar cualquier asalto. Acompañados de nuestra salsa especial, son el bocado perfecto para quienes vienen a Tequila-La a jugar fuerte.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "jalapenostekila.png",
            notification = 'Crujientes, explosivos y muy picantes... este bocado pega más fuerte que un campeón.',
        }
    },

    ["aceitunastekila"] = {
        label = "Aceitunas Picantes",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Aceitunas aliñadas con chile, especias y mucho carácter. Pequeñas, picantes y con un golpe de sabor perfecto para abrir el apetito mientras disfrutas del ambiente del ring.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "aceitunastekila.png",
            notification = 'Pequeñas, picantes y llenas de carácter... menudo golpe de sabor.',
        }
    },

    ["churrostekila"] = {
        label = "Churros de Combate",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Churros crujientes, dorados y recién hechos, acompañados de chocolate caliente para mojar. El postre perfecto para recuperar energía después de cada asalto.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'bzzz_foodpack_croissant001', pos = vec3(0.0, 0.0, 0.0), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "churrostekila.png",
            notification = 'Dorados, crujientes y cubiertos de chocolate... energía recuperada para el siguiente asalto.',
        }
    },

    ["ensaladatekila"] = {
        label = "Ensalada de Puños",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una combinación fresca y contundente de ingredientes frescos y pollo a la parrilla, preparada para recuperar fuerzas entre asalto y asalto con el auténtico espíritu del ring de Tequila-La.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "ensaladatekila.png",
            notification = 'Fresca, contundente y con pollo a la parrilla... este sabor pega fuerte.',
        }
    },

    ["colatekila"] = {
        label = "Tequila-La Cola",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "El refresco que acompaña cada noche en Tequila-La. Sabor intenso, burbujas y ese toque especial que convierte cada trago en una experiencia. Destapa, disfruta y que empiece la fiesta.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "colatekila.png",
            notification = 'Sabor intenso, muchas burbujas y ganas de fiesta... la noche acaba de empezar.',
        }
    },

    ["tekilashot"] = {
        label = "Tequila-La Shot",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una bebida exclusiva, intensa y refrescante, con el auténtico sabor del tequila, un toque cítrico de lima y un acabado picante que despierta los sentidos.",
        client = {
            image = "tekilashot.png",
            notification = 'Tequila, lima y un final picante... ¡este shot despierta todos los sentidos!',
        }
    },

    ["tekila00"] = {
        label = "Tequila-La 0.0",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una cerveza sin alcohol, fría y refrescante, con todo el sabor necesario para seguir disfrutando de la noche, el ring y la fiesta sin perder el ritmo.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'h4_prop_h4_can_beer_01a', pos = vec3(0.01, 0.01, 0.0), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "tekila00.png",
            notification = 'Fría, refrescante y con sabor de campeón... todo el ritmo y cero alcohol.',
        }
    },

    ["tekilachelada"] = {
        label = "Tequila-La Chelada",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cerveza bien fría con lima, especias y un toque picante que pega desde el primer trago. Una mezcla intensa y refrescante para vivir la noche como un auténtico campeón.",
        client = {
            image = "tekilachelada.png",
            notification = 'Cerveza, lima y especias... un golpe picante y refrescante en cada sorbo.',
        }
    },

    ["avioncin"] = {
        label = "Avioncín",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Pequeño avión coleccionable de Airlanda, listo para despegar y ayudarte a planear tus próximos planes.",
        client = {
            image = "avioncin.png",
        }
    },

    ["paracaidasllavero"] = {
        label = "Llavero Paracaídas",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Llavero coleccionable de Airlanda con un pequeño paracaídas que hace todo lo posible para que tus llaves no se estrellen contra el suelo.",
        client = {
            image = "paracaidasllavero.png",
        }
    },

    ["doctoraems"] = {
        label = "La Doctora",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Figura coleccionable de la doctora del EMS, siempre preparada con su portapapeles y sus botas todoterreno para firmar altas después de cada tiroteo.",
        client = {
            image = "doctoraems.png",
        }
    },

    ["medicoems"] = {
        label = "El Médico",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Figura coleccionable del médico del EMS, con su maletín de urgencias y su mirada de turno interminable. El héroe que te revive pase lo que pase.",
        client = {
            image = "medicoems.png",
        }
    },

    ["vipbahamas"] = {
        label = "Tarjeta VIP Bahamas",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP de Bahamas que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "vipbahamas.png",
        }
    },

    ["peluchecompraventa"] = {
        label = "Peluche Compraventa",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Adorable peluche coleccionable de Compraventa, creado como recuerdo exclusivo para sus mejores clientes.",
        client = {
            image = "peluchecompraventa.png",
        }
    },

    ["llaverocompraventa"] = {
        label = "Llavero Canastero",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Llavero coleccionable de Compraventa con un diseño canastero exclusivo, perfecto para llevar tus llaves con personalidad.",
        client = {
            image = "llaverocompraventa.png",
        }
    },

    ["viptekila"] = {
        label = "Tarjeta VIP Tequila-La",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP de Tequila-La que otorga grandes beneficios a los auténticos campeones del local.",
        client = {
            image = "viptekila.png",
        }
    },

    --- ROCKFORD


    ["nachosrockford"] = {
        label = "Nachos “Vinyl Spin”",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Nachos con queso fundido, jalapeños y salsa de tomate ahumada, perfectos para picar mientras suena la música.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "nachosrockford.png",
            notification = 'Queso fundido, jalapeños y salsa ahumada... el picoteo perfecto para escuchar buena música.',
        }
    },

    ["burgerrockford"] = {
        label = "Burger “Studio Session”",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Hamburguesa doble con bacon crujiente, cebolla caramelizada y salsa especial de la casa.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "burgerrockford.png",
            notification = 'Doble carne, bacon crujiente y cebolla caramelizada... una sesión llena de sabor.',
        }
    },

    ["perritorockford"] = {
        label = "Hot Dog “Record”",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Hot dog con chili, cebolla crujiente y mostaza ahumada.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_hotdog_02', pos = vec3(0.03, 0.05, -0.01), bone = 58867, rot = vec3(-90.0, 0.0, 45.0) },
            usetime = 3500,
            image = "perritorockford.png",
            notification = 'Chili, cebolla crujiente y mostaza ahumada... este hot dog suena de maravilla.',
        }
    },

    ["alitasrockford"] = {
        label = "Alitas “Bass Drop”",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Alitas de pollo crujientes acompañadas de salsa BBQ picante o miel y mostaza.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_turkey_leg_01', pos = vec3(0.03, -0.01, 0.0), rot = vec3(90.0, -10.0, 0.0), bone = 4186 },
            usetime = 3500,
            image = "alitasrockford.png",
            notification = 'Crujientes y llenas de salsa... estas alitas golpean más fuerte que el bajo.',
        }
    },

    ["cocktailrockford"] = {
        label = "Rockford Signature Cocktail",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Cóctel exclusivo de la casa elaborado con whisky, limón y un toque de jengibre.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "cocktailrockford.png",
            notification = 'Whisky, limón y jengibre... una mezcla exclusiva con mucho carácter.',
        }
    },

    ["energeticarockford"] = {
        label = "Energy “Amplifier”",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Bebida energética premium con un intenso sabor a frutas rojas, perfecta para aguantar toda la noche.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_energy_drink', pos = vec3(0.03, 0.05, 0.0), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "energeticarockford.png",
            notification = 'Frutas rojas y energía amplificada... ya puedo aguantar toda la noche.',
        }
    },

    ["rockford00"] = {
        label = "Mocktail “Silent Vinyl”",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Bebida sin alcohol preparada con frutas tropicales, hierbabuena y un refrescante toque efervescente.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "rockford00.png",
            notification = 'Tropical, efervescente y sin alcohol... todo el sabor sin perder el ritmo.',
        }
    },

    ["caferockford"] = {
        label = "Café “Late Night Mix”",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Café frío o caliente con un toque de vainilla o licor de café, disponible en versión suave o con alcohol.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "caferockford.png",
            notification = 'Café intenso con un toque especial... la mezcla perfecta para terminar la noche.',
        }
    },

    ["discorockford"] = {
        label = "Disco de Vinilo “Rockford Records”",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Disco de vinilo decorativo, real o réplica, con el logotipo de Rockford Records y listo para colgar en la pared.",
        client = {
            image = "discorockford.png",
        }
    },


    -- YATCH

    ["entrecotyacht"] = {
        label = "Entrecot",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Jugoso corte de carne a la parrilla, dorado por fuera y tierno por dentro.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_steak', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "entrecotyacht.png",
            notification = 'Dorado por fuera, tierno por dentro y lleno de jugosidad... un corte perfecto.',
        }
    },

    ["langostayacht"] = {
        label = "Langosta",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Langosta fresca preparada al estilo de la casa, una auténtica joya del mar.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "langostayacht.png",
            notification = 'Fresca, delicada y preparada al estilo de la casa... una auténtica joya del mar.',
        }
    },

    ["doradayacht"] = {
        label = "Dorada al Horno",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Dorada horneada lentamente con un toque mediterráneo, ligera y llena de sabor.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "doradayacht.png",
            notification = 'Ligera, sabrosa y con un toque mediterráneo... una dorada exquisita.',
        }
    },

    ["cofreyacht"] = {
        label = "Cofre del Pirata",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un dulce tesoro de chocolate con un interior cremoso y una sorpresa escondida digna de un auténtico pirata.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_choc_ego', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "cofreyacht.png",
            notification = 'Chocolate, crema y una sorpresa escondida... he encontrado el tesoro del pirata.',
        }
    },

    ["krakenyacht"] = {
        label = "Kraken",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Cóctel oscuro e intenso a base de ron, con notas dulces y un misterioso toque de frutos negros.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "krakenyacht.png",
            notification = 'Oscuro, intenso y misterioso... el Kraken ha despertado.',
        }
    },

    ["viajeyacht"] = {
        label = "Último Viaje",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un chupito potente de la casa, corto pero intenso. Solo apto para marineros valientes.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "viajeyacht.png",
            notification = 'Corto, potente e intenso... un último viaje reservado para marineros valientes.',
        }
    },

    ["poseidonyacht"] = {
        label = "Poseidón Imperial",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Champán premium de burbuja fina y elegante, reservado para los brindis más especiales.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "poseidonyacht.png",
            notification = 'Elegante, exclusivo y de burbuja fina... un brindis digno de Poseidón.',
        }
    },

    ["tsunamiyacht"] = {
        label = "Tsunami",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Cóctel tropical refrescante, dulce y ligeramente ácido, con una explosión de sabores frutales.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "tsunamiyacht.png",
            notification = 'Dulce, tropical y ligeramente ácido... un tsunami de sabores frutales.',
        }
    },

    ["ositoyacht"] = {
        label = "Osito Marinero",
        weight = 3,
        stack = true,
        close = true,
        description = "Adorable osito de peluche vestido de marinero y preparado para vivir mil aventuras en alta mar.",
        client = {
            image = "ositoyacht.png",
        }
    },

    ["vipyacht"] = {
        label = "Tarjeta VIP Yacht",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP del Yacht que otorga grandes beneficios a sus invitados más exclusivos.",
        client = {
            image = "vipyacht.png",
        }
    },

    ["vipsky"] = {
        label = "Tarjeta Vip Sky Night Club",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP del Sky Night Club, la cuál te otorga grandes beneficios.",
        client = {
            image = "vipsky.png",
        }
    },

    ["vippacific"] = {
        label = "Tarjeta Vip Pacific Bluffs",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP del Pacific Bluffs, la cuál te otorga grandes beneficios.",
        client = {
            image = "vippacific.png",
        }
    },

    ["patubadu"] = {
        label = "Ambientapato",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Ambientador coleccionable con forma de Patubadu, perfecto para perfumar tu coche con el pato más molón.",
        client = {
            image = "patubadu.png",
        }
    },

    ["funkopatu"] = {
        label = "Funko Patubadu",
        weight = 3,
        stack = true,
        close = true,
        description = "Figura coleccionable de Patubadu, siempre preparada para repostar y conquistar corazones.",
        client = {
            image = "funkopatu.png",
        }
    },

    ["pelucheuwu"] = {
        label = "Peluche Gatito UwU Café",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Un adorable gatito de peluche inspirado en el famoso UwU Café. Suave, tierno y perfecto para llevar siempre contigo un poquito de dulzura y café.",
        client = {
            image = "pelucheuwu.png",
        }
    },

    ["cernicalo77"] = {
        label = "Cernícalo",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Pequeño personaje amarillo coleccionable con actitud de estrella de la fiesta y un sombrero negro tipo bucket con el logotipo del Club 77.",
        client = {
            image = "cernicalo77.png",
        }
    },

    ["patolada"] = {
        label = "Patolada",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una refrescante cerveza artesanal con el auténtico sabor de Patolada. Perfecta para relajarse después de un largo día.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'h4_prop_h4_can_beer_01a', pos = vec3(0.01, 0.01, 0.0), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "patolada.png",
            notification = 'Artesanal, refrescante y bien fría... perfecta para terminar un largo día.',
        }
    },

    ["sorpato"] = {
        label = "Sorpato",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un refrescante sorbete de limón servido en una copa con un simpático pato. Dulce, cítrico y perfecto para combatir el calor.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "sorpato.png",
            notification = 'Dulce, cítrico y muy refrescante... este pato sabe cómo combatir el calor.',
        }
    },

    ["saulfrutas"] = {
        label = "Saúl Frutas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "El zumo favorito de los patos, elaborado con una mezcla de frutas que aporta energía para continuar la aventura.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "saulfrutas.png",
            notification = 'Una mezcla de frutas llena de sabor... energía suficiente para continuar la aventura.',
        }
    },

    ["patocola"] = {
        label = "Pato Cola",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una refrescante lata de Pato Cola con cubitos de hielo en forma de pato. El refresco más popular de Patubadu.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "patocola.png",
            notification = 'Dulce, burbujeante y con hielo de pato... ahora entiendo por qué es tan popular.',
        }
    },

    ["batidouwu"] = {
        label = "Batido de Chocolate",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Batido de chocolate cremoso y delicioso, cubierto con nata, chocolate y un toque kawaii inspirado en el UwU Café.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "batidouwu.png",
            notification = 'Cremoso, dulce y cubierto de nata... un batido deliciosamente kawaii.',
        }
    },

    ["cafeuwu"] = {
        label = "Café Latte",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un café latte suave, cálido y aromático, preparado con leche cremosa para que cada sorbo se sienta como un pequeño abrazo.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafeuwu.png",
            notification = 'Suave, calentito y aromático... cada sorbo se siente como un abrazo.',
        }
    },

    ["teuwu"] = {
        label = "Bubble Tea de Fresa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Delicioso bubble tea de fresa, dulce y refrescante, con un intenso sabor a fresa y suaves perlas de tapioca.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "teuwu.png",
            notification = 'Dulce, refrescante y lleno de tapioca... una pequeña explosión de fresa en cada sorbo.',
        }
    },

    ["teauwu"] = {
        label = "Bubble Tea de Arándanos",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Delicioso bubble tea de arándanos, dulce y refrescante, con un sabor afrutado y ligeramente ácido acompañado de suaves perlas de tapioca.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_02', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "teauwu.png",
            notification = 'Afrutado, ligeramente ácido y lleno de tapioca... qué refrescante.',
        }
    },

    ["frigomano"] = {
        label = "Frigomano",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un delicioso helado de fresa con forma de mano que despierta los mejores recuerdos de la infancia.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood6', pos = vec3(0.01, 0.02, -0.01), rot = vec3(-170.0, 88.0, 30.0) },
            usetime = 3500,
            image = "frigomano.png",
            notification = 'Dulce, frío y con sabor a fresa... este helado me devuelve a la infancia.',
        }
    },

    ["bocatabadu"] = {
        label = "Jadillo de Calamardo",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un clásico bocadillo de calamares servido en pan crujiente, con salsa y un refrescante toque de limón.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "bocatabadu.png",
            notification = 'Calamares, pan crujiente y un toque de limón... menudo bocata.',
        }
    },

    ["chuchebadu"] = {
        label = "Chuches Badu",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una bolsa repleta de deliciosas chuches de todos los colores y sabores.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, 0.0, 0.0), rot = vec3(90.0, 0.0, 40.0) },
            usetime = 3500,
            image = "chuchebadu.png",
            notification = 'Dulces, coloridas y de todos los sabores... no ha quedado ni una chuche.',
        }
    },

    ["crepato"] = {
        label = "Crepato",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Crepes enrollados, suaves y bañados en abundante chocolate. Una auténtica dosis de felicidad.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "crepato.png",
            notification = 'Suave, enrollado y bañado en mucho chocolate... pura felicidad.',
        }
    },

    ["tartauwu"] = {
        label = "Tarta de Fresa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Tarta de fresa dulce y esponjosa, decorada con nata, fresas y un adorable toque kawaii inspirado en el UwU Café.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood6', pos = vec3(0.01, 0.02, -0.01), rot = vec3(-170.0, 88.0, 30.0) },
            usetime = 3500,
            image = "tartauwu.png",
            notification = 'Fresa, nata y mucho estilo kawaii... esta tarta estaba deliciosa.',
        }
    },

    ["galletasuwu"] = {
        label = "Galletitas UwU",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Tiernas galletitas con forma de gatito, crujientes por fuera y deliciosas por dentro. Perfectas para acompañar tu bebida favorita.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood2', pos = vec3(0.02, -0.05, 0.02), rot = vec3(0.0, 0.0, 0.0), bone = 60309 },
            usetime = 3500,
            image = "galletasuwu.png",
            notification = 'Crujientes, tiernas y con forma de gatito... adorables y deliciosas.',
        }
    },

    ["pancakesuwu"] = {
        label = "Pancakes UwU",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Pancakes esponjosos y deliciosos, suaves por dentro y dorados por fuera, acompañados de un irresistible toque dulce.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "pancakesuwu.png",
            notification = 'Esponjosos, doraditos y muy dulces... estos pancakes son puro UwU.',
        }
    },

    ["mochisuwu"] = {
        label = "Mochis UwU",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Suaves y deliciosos mochis, con una textura esponjosa y un relleno dulce que se derrite en cada bocado.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'xs_prop_trinket_cup_01a', pos = vec3(0.03, 0.05, -0.13), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "mochisuwu.png",
            notification = 'Suaves, esponjosos y con un relleno dulce... un caprichito adorable.',
        }
    },

    ["langostacasino"] = {
        label = "Diamond Lobster",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Langosta premium bañada en mantequilla de hierbas, preparada para los paladares más exigentes.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "langostacasino.png",
            notification = 'Langosta premium y mantequilla de hierbas... un plato digno del Diamond.',
        }
    },

    ["sandwichdiamond"] = {
        label = "Sándwich Club",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Sándwich gourmet de tres pisos con pollo, bacon crujiente, queso, lechuga y tomate, acompañado de patatas premium.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "sandwichdiamond.png",
            notification = 'Tres pisos de pollo, bacon y queso... lujo y sabor en cada bocado.',
        }
    },

    ["chocolatinaarcade"] = {
        label = "Choco Pixel",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Tableta de chocolate con leche de 100 gramos, relieve temático retro y un toque de energía extra.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_choc_meto', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "chocolatinaarcade.png",
            notification = 'Chocolate con leche y energía extra... recarga completada.',
        }
    },

    ["churrosarcade"] = {
        label = "Churros Arcade",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Ración de churros crujientes espolvoreados con azúcar, acompañados de chocolate fundido y virutas de colores.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'bzzz_foodpack_croissant001', pos = vec3(0.0, 0.0, 0.0), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "churrosarcade.png",
            notification = 'Crujientes, azucarados y bañados en chocolate... partida superada.',
        }
    },

    ["carbonarariviera"] = {
        label = "Carbonara della Riviera",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Pasta carbonara cremosa elaborada siguiendo la auténtica tradición romana.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "carbonarariviera.png",
            notification = 'Cremosa, intensa y auténticamente romana... una carbonara perfecta.',
        }
    },

    ["pizzariviera"] = {
        label = "Pizza Diavola",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Pizza italiana de masa horneada, queso fundido y embutido picante, con un irresistible toque de fuego.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "pizzariviera.png",
            notification = 'Queso fundido y un toque de fuego... esta Diavola hace honor a su nombre.',
        }
    },

    ["tagliatariviera"] = {
        label = "Tagliata di Manzo",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Jugosa carne de vacuno cortada en finas lonchas y preparada con la esencia de la parrilla italiana.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_steak', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "tagliatariviera.png",
            notification = 'Jugosa, tierna y marcada a la parrilla... auténtico sabor italiano.',
        }
    },

    ["tiramisuriviera"] = {
        label = "Tiramisú",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Clásico postre italiano de textura cremosa, café y cacao. El dulce final de toda buena velada.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood6', pos = vec3(0.01, 0.02, -0.01), rot = vec3(-170.0, 88.0, 30.0) },
            usetime = 3500,
            image = "tiramisuriviera.png",
            notification = 'Cremoso, dulce y con sabor a café... el final perfecto para la velada.',
        }
    },

    ["tacostekila"] = {
        label = "Tacos del Ring",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Tortillas calientes rellenas de carne jugosa, cebolla, cilantro y las salsas especiales de Tequila-La. Tres golpes de sabor capaces de dejarte fuera de combate.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_taco_02', pos = vec3(0.03, 0.05, -0.01), bone = 58867, rot = vec3(90.0, 0.0, 45.0) },
            usetime = 3500,
            image = "tacostekila.png",
            notification = 'Carne, cilantro y salsa especial... tres golpes de sabor directos al paladar.',
        }
    },

    ["nachostekila"] = {
        label = "Nachos Tequila-La",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una montaña de nachos crujientes bañados en cheddar, acompañados de carne sazonada, jalapeños y salsas de la casa.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "nachostekila.png",
            notification = 'Cheddar, carne y jalapeños... estos nachos entran con fuerza al ring.',
        }
    },

    ["browniewdl"] = {
        label = "Weeland Brownie",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Brownie de chocolate intenso, jugoso y cargado de sabor. Un bocado basta para entender por qué todos quieren repetir.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_choc_pq', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "browniewdl.png",
            notification = 'Jugoso, intenso y cargado de chocolate... ya entiendo por qué todos repiten.',
        }
    },

    ["cookiewdl"] = {
        label = "Weeland Cookie",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Cookie recién horneada, dorada por fuera y tierna por dentro, con generosas pepitas de chocolate.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood2', pos = vec3(0.02, -0.05, 0.02), rot = vec3(0.0, 0.0, 0.0), bone = 60309 },
            usetime = 3500,
            image = "cookiewdl.png",
            notification = 'Dorada por fuera, tierna por dentro y llena de chocolate... irresistible.',
        }
    },

    ["gomitaswdl"] = {
        label = "Weeland Gummies",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Ositos de colores llenos de sabor y diversión. Dulces, suaves y perfectos para darle un toque diferente al día.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'xs_prop_trinket_cup_01a', pos = vec3(0.03, 0.05, -0.13), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "gomitaswdl.png",
            notification = 'Dulces, suaves y llenas de color... qué divertido sabor.',
        }
    },

    ["chocowdl"] = {
        label = "Weeland Choco",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Chocolate premium con el característico toque Weeland. Intenso, dulce y perfecto para disfrutar de los pequeños momentos.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_choc_ego', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "chocowdl.png",
            notification = 'Intenso, dulce y de calidad premium... hay que disfrutar los pequeños momentos.',
        }
    },

    ["tartawdl"] = {
        label = "Weeland Cheesecake",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cremosa tarta de queso con la característica cobertura verde de Weeland. Suave, dulce y absolutamente irresistible.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood6', pos = vec3(0.01, 0.02, -0.01), rot = vec3(-170.0, 88.0, 30.0) },
            usetime = 3500,
            image = "tartawdl.png",
            notification = 'Suave, cremosa y con su cobertura verde... absolutamente irresistible.',
        }
    },

    ["magdalenawdl"] = {
        label = "Weeland Green Cupcake",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Esponjoso cupcake de chocolate coronado con la irresistible crema verde de Weeland. Pequeño por fuera, brutal por dentro.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood6', pos = vec3(0.01, 0.02, -0.01), rot = vec3(-170.0, 88.0, 30.0) },
            usetime = 3500,
            image = "magdalenawdl.png",
            notification = 'Pequeño por fuera, esponjoso y brutal por dentro... menudo cupcake.',
        }
    },

    ["frostcasino"] = {
        label = "Diamond Frost",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Refrescante mezcla sin alcohol de manzana verde, lima, soda premium y una suave espuma de vainilla.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "frostcasino.png",
            notification = 'Manzana, lima y espuma de vainilla... lujo refrescante sin alcohol.',
        }
    },

    ["elixircasino"] = {
        label = "Diamond Elixir",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "El cóctel insignia de la casa, una mezcla exclusiva que convierte cada sorbo en una experiencia inolvidable.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "elixircasino.png",
            notification = 'Exclusivo, elegante e inolvidable... el auténtico elixir del Diamond.',
        }
    },

    ["soleriviera"] = {
        label = "Sole d’Italia",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Aperitivo italiano refrescante y sofisticado, preparado sin una sola gota de alcohol.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "soleriviera.png",
            notification = 'Refrescante, sofisticado y sin alcohol... puro sol italiano.',
        }
    },

    ["riviera"] = {
        label = "Riviera Agrumi",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una bebida refrescante inspirada en los cítricos de la costa italiana.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "riviera.png",
            notification = 'Cítrico, ligero y refrescante... sabe a costa italiana.',
        }
    },

    ["chocoarcade"] = {
        label = "Choco Arcade",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Chocolate caliente, espeso y cubierto con una suave capa de espuma y marshmallows tostados, servido en una emblemática taza retro.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "chocoarcade.png",
            notification = 'Caliente, espeso y cubierto de marshmallows... energía recargada para otra partida.',
        }
    },

    ["tropicaltekila"] = {
        label = "Granizado Tropical",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Piña, coco y limón en una mezcla refrescante y tropical. Sabor de campeón, cero alcohol y toda la actitud de Tequila-La.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "tropicaltekila.png",
            notification = 'Piña, coco y limón... sabor de campeón y cero alcohol.',
        }
    },

    ["clamatotekila"] = {
        label = "Zumo de Tomate",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Mezcla intensa de tomate, lima y especias con un toque picante y el auténtico carácter del ring de Tequila-La.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "clamatotekila.png",
            notification = 'Tomate, lima y especias... un golpe picante desde el primer trago.',
        }
    },

    ["bebidawdl"] = {
        label = "Weeland Relax Drink",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Bebida refrescante pensada para bajar las revoluciones, desconectar y disfrutar tranquilamente del momento.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "bebidawdl.png",
            notification = 'Fresca y relajante... es hora de bajar las revoluciones.',
        }
    },

    ["mangowdl"] = {
        label = "Weeland Mango Kush",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "El sabor tropical del mango llevado al siguiente nivel. Dulce, refrescante y con una personalidad inconfundible.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "mangowdl.png",
            notification = 'Dulce, tropical y con mucha personalidad... mango a otro nivel.',
        }
    },

    ["berrywdl"] = {
        label = "Weeland Berry High",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una explosión de frutos rojos en cada sorbo. Dulce, intensa y refrescante desde el primer trago.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "berrywdl.png",
            notification = 'Dulce, intensa y llena de frutos rojos... engancha desde el primer trago.',
        }
    },

    ["frappewdl"] = {
        label = "Weeland Cannabis Frappé",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Frappé cremoso y frío, cubierto con una deliciosa crema. El capricho perfecto para los amantes de lo dulce.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "frappewdl.png",
            notification = 'Frío, cremoso y cubierto de crema... un capricho irresistible.',
        }
    },

    ["teawdl"] = {
        label = "Weeland Ice Tea CBD",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Té helado suave y refrescante con un toque diferente, perfecto para relajarte y disfrutar del momento.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "teawdl.png",
            notification = 'Suave, frío y refrescante... perfecto para desconectar.',
        }
    },

    ["spritzriviera"] = {
        label = "Spritz della Riviera",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un refrescante aperitivo italiano creado para brindar junto al Mediterráneo.",
        client = {
            image = "spritzriviera.png",
        }
    },

    ["negroniriviera"] = {
        label = "Negroni",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un clásico cóctel italiano, intenso y equilibrado, preparado para noches con carácter.",
        client = {
            image = "negroniriviera.png",
        }
    },

    ["birraarcade"] = {
        label = "Eight Birra",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cerveza artesanal con un refrescante toque cítrico, perfecta para olvidar hasta el último recuerdo de tu ex.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'h4_prop_h4_can_beer_01a', pos = vec3(0.01, 0.01, 0.0), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "birraarcade.png",
            notification = 'Artesanal, cítrica y bien fría... ¿quién era mi ex?',
        }
    },

    ["sodawdl"] = {
        label = "Weeland Cannabis Soda",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Refresco burbujeante con el auténtico sabor Weeland. Fresco, diferente y perfecto para cualquier momento.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'sf_prop_sf_can_01a', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "sodawdl.png",
            notification = 'Fresca, diferente y llena de burbujas... auténtico sabor Weeland.',
        }
    },

    ["licencia"] = {
        label = "Licencia de Vuelo",
        weight = 3,
        stack = true,
        close = true,
        description = "Certificado oficial que otorga a su titular el derecho a practicar vuelo libre.",
        client = {
            image = "licencia.png",
        }
    },

    ["vipweazel"] = {
        label = "Tarjeta VIP Weazel News",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP de Weazel News que otorga grandes beneficios a sus titulares más exclusivos.",
        client = {
            image = "vipweazel.png",
        }
    },

    ["weazelito"] = {
        label = "Weazelito",
        weight = 3,
        stack = true,
        close = true,
        description =
        "El pequeño reportero coleccionable de Weazel News, siempre preparado para cubrir cualquier noticia con su micrófono en la mano.",
        client = {
            image = "weazelito.png",
        }
    },

    ["arcadechakra"] = {
        label = "Plush Arcade Chakra",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Peluche coleccionable de edición Arcade capaz de absorber energía. Un objeto tan misterioso como exclusivo.",
        client = {
            image = "arcadechakra.png",
        }
    },

    ["funkocasino"] = {
        label = "Funko Casino",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Figura coleccionable exclusiva del Casino Diamond, con el estilo y la elegancia de un auténtico High Roller.",
        client = {
            image = "funkocasino.png",
        }
    },

    ["limonriviera"] = {
        label = "Don Limón",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Un divertido y suave limón coleccionable con mucho estilo, preparado para acompañarte allá donde vayas.",
        client = {
            image = "limonriviera.png",
        }
    },

    ["cinturontekila"] = {
        label = "Cinturón de Campeón Tequila-La",
        weight = 3,
        stack = true,
        close = true,
        description =
        "La máxima distinción de Tequila-La. Un cinturón exclusivo reservado para quienes han demostrado ser auténticas leyendas del ring.",
        client = {
            image = "cinturontekila.png",
        }
    },

    ["vipsantos"] = {
        label = "Tarjeta VIP Los Santos Customs",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Tarjeta VIP de Los Santos Customs que otorga grandes beneficios a los clientes más exclusivos del taller.",
        client = {
            image = "vipsantos.png",
        }
    },


    ["palmerabahamas"] = {
        label = "Palmera Cebra",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una crujiente palmera de hojaldre cubierta con chocolate blanco y negro. Las únicas rayas que te llevarán directamente a la pista.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'bzzz_foodpack_croissant001', pos = vec3(0.0, 0.0, 0.0), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "palmerabahamas.png",
            notification = 'Crujiente y cubierta de chocolate... estas rayas me llevan directamente a la pista.',
        }
    },

    ["alitasbahamas"] = {
        label = "Alitas Vulcano",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Alitas de pollo crujientes por fuera y ardientes por dentro. No existe ola capaz de apagar este fuego.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_turkey_leg_01', pos = vec3(0.03, -0.01, 0.0), rot = vec3(90.0, -10.0, 0.0), bone = 4186 },
            usetime = 3500,
            image = "alitasbahamas.png",
            notification = 'Crujientes por fuera y ardientes por dentro... ¡no hay ola que apague este fuego!',
        }
    },

    ["najabahamas"] = {
        label = "Naja Atra",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Coleccionable exclusivo de Bahamas Mamas inspirado en su famoso chupito. Dulce al primer sorbo, venenoso al último.",
        client = {
            image = "najabahamas.png",
        }
    },

    ["teabahamas"] = {
        label = "Flowlea",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Figura coleccionable exclusiva de Bahamas Mamas. Déjate llevar por el flow; del veneno se encarga ella.",
        client = {
            image = "teabahamas.png",
        }
    },

    ["longbahamas"] = {
        label = "BahaLong",
        weight = 3,
        stack = true,
        close = true,
        description =
        "El pequeño dragón del paraíso. Un coleccionable exclusivo de Bahamas Mamas que ha llegado para ponerle un poco de fuego al verano.",
        client = {
            image = "longbahamas.png",
        }
    },

    ["weazelpremio"] = {
        label = "Weazel Premio",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Trofeo de reconocimiento de Weazel News entregado al Empleado de la Semana o al ganador de un evento especial.",
        client = {
            image = "weazelpremio.png",
        }
    },

    ["vipriviera"] = {
        label = "Tarjeta VIP La Riviera",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP de La Riviera que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "vipriviera.png",
        }
    },

    ["munecavanilla"] = {
        label = "Muñeca Deseos Vanilla",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Muñeca coleccionable de diseño llamativo y moderno, con un toque divertido y atrevido y el estilo exclusivo de Vanilla Unicorn.",
        client = {
            image = "munecavanilla.png",
        }
    },

    ["munecobennys"] = {
        label = "Benny’s Mechanic",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Muñeco de peluche de Benny, el mecánico de Benny’s Motor Works, con gorra, mono de trabajo y llave inglesa. Perfecto para coleccionistas y aficionados a la mecánica.",
        client = {
            image = "munecobennys.png",
        }
    },

    ["llavebennys"] = {
        label = "Llave Benny’s",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Peluche con forma de llave inglesa de Benny’s, con gorra y detalles bordados. Un accesorio único para los amantes de la mecánica.",
        client = {
            image = "llavebennys.png",
        }
    },

    ["whiskyvanilla"] = {
        label = "Whisky Nocturno",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Whisky de carácter intenso y elegante, con notas cálidas y un sabor equilibrado. Perfecto para disfrutar solo, con hielo o como base de un buen combinado.",
    },

    ["cafevanilla"] = {
        label = "Café 100x100 Vanilla",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Café intenso y aromático, perfecto para empezar el día después de una noche de descontrol.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafevanilla.png",
            notification = 'Intenso y aromático... justo el café que necesitaba esta mañana.',
        }
    },

    ["burrito_vanilla"] = {
        label = "Burrito Vanilla",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Tortilla de trigo rellena de carne, arroz, frijoles, verduras, guacamole y queso fundido. Sabroso, completo y contundente.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "burrito_vanilla.png",
            notification = 'Carne, guacamole y queso fundido... este burrito no se queda corto.',
        }
    },

    ["patatasvanilla"] = {
        label = "Patatas Gajostuosas",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Patatas gajo crujientes por fuera y tiernas por dentro, acompañadas de una deliciosa salsa para disfrutar al máximo.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "patatasvanilla.png",
            notification =
            'Crujientes por fuera, tiernas por dentro y con una salsa deliciosa... no ha quedado ni un gajo.',
        }
    },

    ["hamburguesabs"] = {
        label = "Hamburguesa con Queso",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Carne jugosa a la parrilla coronada con queso fundido, lechuga y tomate en un tierno pan de hamburguesa.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "hamburguesabs.png",
            notification = 'Carne jugosa, queso fundido y vegetales frescos... una hamburguesa clásica que nunca falla.',
        }
    },

    ["macarronesbs"] = {
        label = "Macarrones con Tomate",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Un plato reconfortante de pasta en su punto, bañada en una sabrosa y casera salsa de tomate.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "macarronesbs.png",
            notification = 'Pasta en su punto y una salsa de tomate casera... un plato muy reconfortante.',
        }
    },

    ["papasadabs"] = {
        label = "Papa Asada",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Patata asada al horno, tierna por dentro y rellena de tus ingredientes y salsas preferidos.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "papasadabs.png",
            notification = 'Tierna, recién horneada y cargada de ingredientes... qué buena estaba.',
        }
    },

    ["pinchodepollobs"] = {
        label = "Pincho de Pollo",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Brocheta de dados de pollo marinados y cocinados a la plancha, jugosos y llenos de sabor.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_turkey_leg_01', pos = vec3(0.03, -0.01, 0.0), rot = vec3(90.0, -10.0, 0.0), bone = 4186 },
            usetime = 3500,
            image = "pinchodepollobs.png",
            notification = 'Pollo marinado, jugoso y preparado a la plancha... un pincho lleno de sabor.',
        }
    },

    ["llaveropizzabs"] = {
        label = "Llavero de Pizza",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Divertido llavero coleccionable con forma de pizza, perfecto para llevar tus llaves con todo el estilo de Burger Shot.",
        client = {
            image = "llaveropizzabs.png",
        }
    },

    ["colabs"] = {
        label = "Cola Loca",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "La bebida de cola de siempre, con el balance perfecto de gas y ese sabor inconfundible.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "colabs.png",
            notification = 'Dulce, burbujeante y bien fría... esta cola entra de locos.',
        }
    },

    ["cafebs"] = {
        label = "Café",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Café pequeño, fuerte y concentrado, con un sabor intenso y ligeramente amargo.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafebs.png",
            notification = 'Pequeño, fuerte y concentrado... este café despierta a cualquiera.',
        }
    },

    ["naranjabs"] = {
        label = "Nas de Naranja",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Bebida cítrica natural, ácida y refrescante, preparada para calmar la sed al instante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_orang_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "naranjabs.png",
            notification = 'Cítrico, ácido y muy refrescante... se me ha pasado la sed al instante.',
        }
    },

    ["granizadobs"] = {
        label = "Granizado de Limón",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Granizado de limón refrescante y helado, con un sabor cítrico intenso y una textura ligera y cristalizada, perfecto para combatir el calor.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "granizadobs.png",
            notification = 'Helado, cítrico y cristalizado... el calor acaba de desaparecer.',
        }
    },

    ["ambientadorcompraventa"] = {
        label = "Ambientador Compraventa Los Mendoza",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Ambientador elaborado con aroma de hinojos y presentado en un elegante frasco de cristal con tapón de corcho y cuerda para colgarlo en el vehículo. Un pequeño detalle de la familia Mendoza.",
        client = {
            image = "ambientadorcompraventa.png",
        }
    },

    ["matriculacompraventa"] = {
        label = "Mini Matrícula Los Mendoza",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Pequeña matrícula decorativa de Los Mendoza, ideal como distintivo para vehículos, remolques o como elemento de colección.",
        client = {
            image = "matriculacompraventa.png",
        }
    },

    ["pizzathis1"] = {
        label = "Porción de Pizza 4 Quesos",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una deliciosa porción de pizza preparada con una selección de los mejores quesos de Italia.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "pizzathis1.png",
            notification = 'Cuatro quesos italianos fundidos... una porción irresistible.',
        }
    },

    ["pizzathis2"] = {
        label = "Porción de Pizza 4 Estaciones",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una porción de pizza italiana dividida en cuatro sabores que representan las estaciones del año.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "pizzathis2.png",
            notification = 'Cuatro estaciones y cuatro sabores... todo en una sola porción.',
        }
    },

    ["pizzathis3"] = {
        label = "Porción de Pizza Vegetal",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una porción de pizza preparada con verduras frescas, perfecta para quienes prefieren una opción vegetal.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "pizzathis3.png",
            notification = 'Verduras frescas sobre una masa crujiente... una opción ligera y deliciosa.',
        }
    },

    ["pizzathis4"] = {
        label = "Porción de Pizza Pepperoni",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Una porción de pizza con queso fundido, pepperoni y un toque picante muy especial.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
            usetime = 3500,
            image = "pizzathis4.png",
            notification = 'Pepperoni, queso fundido y un toque picante... una combinación perfecta.',
        }
    },

    ["desayunoyellow"] = {
        label = "Desayuno Completo",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Plato contundente compuesto por huevos, bacon, salchichas, patatas y otros acompañamientos para empezar el día con energía.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "desayunoyellow.png",
            notification = 'Huevos, bacon, salchichas y patatas... energía de sobra para empezar el día.',
        }
    },

    ["bocatayellow"] = {
        label = "Mistery Kike",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Un secreto guardado entre dos panes. Una combinación misteriosa, intensa y llena de sabor que no dejará indiferente a nadie.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "bocatayellow.png",
            notification = 'Un secreto intenso y lleno de sabor escondido entre dos panes.',
        }
    },

    ["melonpacific"] = {
        label = "Brisa Mediterránea",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Melón fresco y dulce acompañado de finas lonchas de jamón serrano, una clásica combinación dulce y salada.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
            prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3500,
            image = "melonpacific.png",
            notification = 'Melón dulce y jamón serrano... una brisa mediterránea llena de sabor.',
        }
    },

    ["tacospacific"] = {
        label = "Trío de Coral",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Tres tacos crujientes de camarón con aguacate, mango y una suave salsa cítrica, frescos y con un toque tropical.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_taco_02', pos = vec3(0.03, 0.05, -0.01), bone = 58867, rot = vec3(90.0, 0.0, 45.0) },
            usetime = 3500,
            image = "tacospacific.png",
            notification = 'Camarón, aguacate y mango... tres tacos con auténtico sabor tropical.',
        }
    },

    ["burgergalaxy"] = {
        label = "Galaxy Burger",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Hamburguesa premium servida en pan negro con queso cheddar fundido y la exclusiva salsa Galaxy.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "burgergalaxy.png",
            notification = 'Pan negro, cheddar fundido y salsa Galaxy... una hamburguesa de otro mundo.',
        }
    },

    ["bitesgalaxy"] = {
        label = "Meteor Bites",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Bocados crujientes de pollo acompañados de dos salsas, perfectos para compartir.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "bitesgalaxy.png",
            notification = 'Crujientes y acompañados de dos salsas... estos meteoritos han desaparecido.',
        }
    },

    ["arosgalaxy"] = {
        label = "Saturn Rings",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Aros de cebolla premium, dorados y crujientes, presentados como los anillos del planeta Saturno.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
            prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, 0.0, 0.0), rot = vec3(90.0, 0.0, 40.0) },
            usetime = 3500,
            image = "arosgalaxy.png",
            notification = 'Dorados, crujientes y perfectamente alineados... me he comido los anillos de Saturno.',
        }
    },

    ["nachosgalaxy"] = {
        label = "Cosmic Nachos",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Nachos crujientes cargados de queso fundido, carne, jalapeños y la salsa especial de Galaxy.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
            usetime = 3500,
            image = "nachosgalaxy.png",
            notification = 'Queso, carne, jalapeños y salsa Galaxy... una montaña de sabor cósmico.',
        }
    },

    ["vinothis"] = {
        label = "Botella de Vino Chianti",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Vino Chianti italiano de 1986, reservado para quienes saben disfrutar de una buena comida.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "vinothis.png",
            notification = 'Un Chianti italiano de 1986... elegante, intenso y perfecto para acompañar la comida.',
        }
    },

    ["cervezathis"] = {
        label = "Cerveza Italiana",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cerveza italiana fría y refrescante, preparada para quienes quieren disfrutar del auténtico sabor de Italia.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'h4_prop_h4_can_beer_01a', pos = vec3(0.01, 0.01, 0.0), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "cervezathis.png",
            notification = 'Fría, suave y refrescante... auténtico sabor italiano.',
        }
    },

    ["cafethis"] = {
        label = "Café Nespresso Italiano",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Café intenso y aromático preparado con una selección de los mejores granos colombianos.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "cafethis.png",
            notification = 'Intenso y aromático... una excelente selección de granos colombianos.',
        }
    },

    ["cocathis"] = {
        label = "Coca Pizza",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Bebida de cola dulce y refrescante, con muchas burbujas y preparada con un toque de cariño.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 4000,
            image = "cocathis.png",
            notification = 'Fresca, burbujeante y preparada con cariño... perfecta para acompañar la pizza.',
        }
    },

    ["chupitoyellow"] = {
        label = "Chupito de Serpiente",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =        "Un chupito intenso para los más atrevidos, perfecto para acompañar el ambiente rebelde y motero de Yellow Jack.",

    },

    ["batidoyellow"] = {
        label = "Batido de Fresa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cremoso batido de fresa, servido frío y acompañado de una pajita. Una opción dulce y refrescante para cualquier momento.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "batidoyellow.png",
            notification = 'Frío, dulce y muy cremoso... un batido de fresa delicioso.',
        }
    },

    ["atardecerpacific"] = {
        label = "Atardecer Púrpura",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Mezcla sin alcohol de frutos del bosque, cítricos y lavanda, con un vibrante tono morado y rosado.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "atardecerpacific.png",
            notification = 'Frutos del bosque, cítricos y lavanda... un atardecer dentro de la copa.',
        }
    },

    ["besopacific"] = {
        label = "Beso de Sirena",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Cóctel tropical dulce y refrescante con notas de coco, piña y un toque cítrico de lima.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "besopacific.png",
            notification = 'Coco, piña y lima... un beso tropical difícil de olvidar.',
        }
    },

    ["supergalaxy"] = {
        label = "Supernova",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =  "Cóctel insignia de Galaxy, de color violeta brillante y preparado con vodka, frutos rojos y cítricos.",
    },

    ["holegalaxy"] = {
        label = "Black Hole",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Cóctel negro, fuerte y premium, decorado con elegantes detalles dorados.",
    },

    ["nebulagalaxy"] = {
        label = "Nebula",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cóctel azul y violeta con efecto degradado y humo, creado para ofrecer una experiencia visual de otra galaxia.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "nebulagalaxy.png",
            notification = 'Azul, violeta y cubierto de humo... una nebulosa lista para beber.',
        }
    },

    ["flaregalaxy"] = {
        label = "Solar Flare",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cóctel tropical de color naranja y dorado, ligeramente picante y presentado con un sorprendente efecto de fuego.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "flaregalaxy.png",
            notification = 'Tropical, dorado y ligeramente picante... una llamarada solar en cada sorbo.',
        }
    },

    ["ambientadorcompraventa"] = {
        label = "Ambientador Compraventa Los Mendoza",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Ambientador con aroma de hinojos presentado en un elegante frasco de cristal con tapón de corcho y cuerda para colgarlo en el vehículo.",
        client = {
            image = "ambientadorcompraventa.png",
        }
    },

    ["matriculacompraventa"] = {
        label = "Mini Matrícula Los Mendoza",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Pequeña matrícula decorativa de Los Mendoza, ideal como distintivo para vehículos, remolques o como pieza de colección.",
        client = {
            image = "matriculacompraventa.png",
        }
    },

    ["vipatom"] = {
        label = "Tarjeta VIP Up-n-Atom",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP de Up-n-Atom que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "vipatom.png",
        }
    },

    ["viprex"] = {
        label = "Tarjeta VIP Rex Dinner",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP de Rex Dinner que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "viprex.png",
        }
    },

    ["trofeothis"] = {
        label = "Trofeo Pizza This",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Trofeo coleccionable de Pizza This reservado para quienes han conseguido un logro digno de recordar.",
        client = {
            image = "trofeothis.png",
        }
    },

    ["motoautoexotic"] = {
        label = "Peluche Moto Auto Exotic",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Peluche coleccionable de una moto de Auto Exotic, diseñado especialmente para decorar tu vehículo.",
        client = {
            image = "motoautoexotic.png",
        }
    },

    ["mecanicoautoexotic"] = {
        label = "Peluche Mecánico Auto Exotic",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Peluche coleccionable de un mecánico de Auto Exotic, perfecto para decorar tu vehículo o tu taller.",
        client = {
            image = "mecanicoautoexotic.png",
        }
    },

    ["vipautoexotic"] = {
        label = "Tarjeta VIP Taller Auto Exotic",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP del taller Auto Exotic que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "vipautoexotic.png",
        }
    },

    ["mecahayes"] = {
        label = "Mecánico de Hayes Auto",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Muñeco articulado de un mecánico de Hayes Auto Repair, equipado con herramientas y detallados tatuajes.",
        client = {
            image = "mecahayes.png",
        }
    },

    ["llaverohayes"] = {
        label = "Llavero Hayes Auto",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Llavero de alta calidad de Hayes Auto con un medallón de la marca y varios dijes con forma de herramientas.",
        client = {
            image = "llaverohayes.png",
        }
    },

    ["viphayes"] = {
        label = "Tarjeta VIP Taller Hayes Auto",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP del taller Hayes Auto que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "viphayes.png",
        }
    },

    ["ositohayes"] = {
        label = "El Oso Hayes",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Adorable oso de peluche coleccionable vestido con los colores y el estilo característico de Hayes Auto.",
        client = {
            image = "ositohayes.png",
        }
    },

    ["coyotejack"] = {
        label = "Coyote Jack",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Adorable peluche inspirado en la mascota de Yellow Jack, con estética motera, pañuelo y chaleco negro.",
        client = {
            image = "coyotejack.png",
        }
    },

    ["osootto"] = {
        label = "El Oso Ottos",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Adorable oso de peluche coleccionable inspirado en el taller Ottos Autos y su pasión por el motor.",
        client = {
            image = "osootto.png",
        }
    },

    ["toroottos"] = {
        label = "Toro Ottos",
        weight = 3,
        stack = true,
        close = true,
        description = "Fuerte y simpático toro de peluche coleccionable, mascota exclusiva del taller Ottos Autos.",
        client = {
            image = "toroottos.png",
        }
    },

    ["vipotto"] = {
        label = "Tarjeta VIP Taller Ottos Autos",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP del taller Ottos Autos que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "vipotto.png",
        }
    },

    ["morupacific"] = {
        label = "Moru",
        weight = 3,
        stack = true,
        close = true,
        description = "Un pequeño pulpo kawaii, divertido y lleno de energía, con un alegre estilo playero y veraniego.",
        client = {
            image = "morupacific.png",
        }
    },

    ["monedagalaxy"] = {
        label = "Moneda Galaxy",
        weight = 3,
        stack = true,
        close = true,
        description = "Moneda coleccionable de edición especial con el distintivo diseño cósmico de Galaxy.",
        client = {
            image = "monedagalaxy.png",
        }
    },

    ["hnganh_anya"] = {
        label = "hnganh_anya",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_anya",
        client = {
            image = "hnganh_anya.png",
        }
    },
    ["hnganh_grinch"] = {
        label = "Pesadilla Navidad",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_grinch",
        client = {
            image = "hnganh_grinch.png",
        }
    },
    ["hnganh_bagdino"] = {
        label = "Dino",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_bagdino",
        client = {
            image = "hnganh_bagdino.png",
        }
    },
    ["hnganh_bee"] = {
        label = "Abeja",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_bee",
        client = {
            image = "hnganh_bee.png",
        }
    },
    ["hnganh_bee2"] = {
        label = "Abejita",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_bee2",
        client = {
            image = "hnganh_bee2.png",
        }
    },
    ["hnganh_bird"] = {
        label = "Pajaro",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_bird",
        client = {
            image = "hnganh_bird.png",
        }
    },
    ["hnganh_bunny"] = {
        label = "Conejito",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_bunny",
        client = {
            image = "hnganh_bunny.png",
        }
    },
    ["hnganh_calcifer"] = {
        label = "hnganh_calcifer",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_calcifer",
        client = {
            image = "hnganh_calcifer.png",
        }
    },
    ["hnganh_canhcutgs"] = {
        label = "Pinguino Navideño",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_canhcutgs",
        client = {
            image = "hnganh_canhcutgs.png",
        }
    },
    ["hnganh_chibikitty"] = {
        label = "Gato Amoroso",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_chibikitty",
        client = {
            image = "hnganh_chibikitty.png",
        }
    },
    ["hnganh_cowboy"] = {
        label = "Vaquero",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_cowboy",
        client = {
            image = "hnganh_cowboy.png",
        }
    },
    ["hnganh_cuhanh"] = {
        label = "hnganh_cuhanh",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_cuhanh",
        client = {
            image = "hnganh_cuhanh.png",
        }
    },
    ["hnganh_cutefeline"] = {
        label = "Leon",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_cutefeline",
        client = {
            image = "hnganh_cutefeline.png",
        }
    },
    ["hnganh_dachshund"] = {
        label = "Perrito",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_dachshund",
        client = {
            image = "hnganh_dachshund.png",
        }
    },
    ["hnganh_duckcute"] = {
        label = "Pato",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_duckcute",
        client = {
            image = "hnganh_duckcute.png",
        }
    },
    ["hnganh_frog"] = {
        label = "Rana",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_frog",
        client = {
            image = "hnganh_frog.png",
        }
    },
    ["hnganh_ghostly"] = {
        label = "Brujita",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_ghostly",
        client = {
            image = "hnganh_ghostly.png",
        }
    },
    ["hnganh_gingerbread"] = {
        label = "Galleta",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_gingerbread",
        client = {
            image = "hnganh_gingerbread.png",
        }
    },
    ["hnganh_giraffe"] = {
        label = "hnganh_giraffe",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_giraffe",
        client = {
            image = "hnganh_giraffe.png",
        }
    },
    ["hnganh_goose"] = {
        label = "hnganh_goose",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_goose",
        client = {
            image = "hnganh_goose.png",
        }
    },
    ["hnganh_goose2"] = {
        label = "hnganh_goose2",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_goose2",
        client = {
            image = "hnganh_goose2.png",
        }
    },
    ["hnganh_happyfox"] = {
        label = "Zorro",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_happyfox",
        client = {
            image = "hnganh_happyfox.png",
        }
    },
    ["hnganh_hippo"] = {
        label = "hnganh_hippo",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_hippo",
        client = {
            image = "hnganh_hippo.png",
        }
    },
    ["hnganh_hippo2"] = {
        label = "hnganh_hippo2",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_hippo2",
        client = {
            image = "hnganh_hippo2.png",
        }
    },
    ["hnganh_horse"] = {
        label = "hnganh_horse",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_horse",
        client = {
            image = "hnganh_horse.png",
        }
    },
    ["hnganh_kitten"] = {
        label = "Gato Negro",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_kitten",
        client = {
            image = "hnganh_kitten.png",
        }
    },
    ["hnganh_kittyice"] = {
        label = "Mochila Gatita",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_kittyice",
        client = {
            image = "hnganh_kittyice.png",
        }
    },
    ["hnganh_lions"] = {
        label = "Leoncito",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_lions",
        client = {
            image = "hnganh_lions.png",
        }
    },
    ["hnganh_minimalist"] = {
        label = "Oso",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_minimalist",
        client = {
            image = "hnganh_minimalist.png",
        }
    },
    ["hnganh_loving"] = {
        label = "Gato Amor",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_loving",
        client = {
            image = "hnganh_loving.png",
        }
    },
    ["hnganh_magickitty"] = {
        label = "hnganh_magickitty",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_magickitty",
        client = {
            image = "hnganh_magickitty.png",
        }
    },
    ["hnganh_mushroom"] = {
        label = "Seta Magica",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_mushroom",
        client = {
            image = "hnganh_mushroom.png",
        }
    },
    ["hnganh_naughty"] = {
        label = "Lobito Cuqui",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_naughty",
        client = {
            image = "hnganh_naughty.png",
        }
    },
    ["hnganh_nymph"] = {
        label = "Polluelo",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_nymph",
        client = {
            image = "hnganh_nymph.png",
        }
    },
    ["hnganh_otter"] = {
        label = "Nutria",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_otter",
        client = {
            image = "hnganh_otter.png",
        }
    },
    ["hnganh_otters1"] = {
        label = "Nutria Marron",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_otters1",
        client = {
            image = "hnganh_otters1.png",
        }
    },
    ["hnganh_owl"] = {
        label = "Buho",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_owl",
        client = {
            image = "hnganh_owl.png",
        }
    },
    ["hnganh_pancake"] = {
        label = "Tortitas",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_pancake",
        client = {
            image = "hnganh_pancake.png",
        }
    },
    ["hnganh_pandared"] = {
        label = "hnganh_pandared",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_pandared",
        client = {
            image = "hnganh_pandared.png",
        }
    },
    ["hnganh_parrot"] = {
        label = "Periquito",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_parrot",
        client = {
            image = "hnganh_parrot.png",
        }
    },
    ["hnganh_penguin"] = {
        label = "hnganh_penguin",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_penguin",
        client = {
            image = "hnganh_penguin.png",
        }
    },
    ["hnganh_piggy"] = {
        label = "hnganh_piggy",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_piggy",
        client = {
            image = "hnganh_piggy.png",
        }
    },
    ["hnganh_piggyv2"] = {
        label = "hnganh_piggyv2",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_piggyv2",
        client = {
            image = "hnganh_piggyv2.png",
        }
    },
    ["hnganh_pigs"] = {
        label = "hnganh_pigs",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_pigs",
        client = {
            image = "hnganh_pigs.png",
        }
    },
    ["hnganh_polarbear"] = {
        label = "Oso Polar",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_polarbear",
        client = {
            image = "hnganh_polarbear.png",
        }
    },
    ["hnganh_politoed"] = {
        label = "Ranita",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_politoed",
        client = {
            image = "hnganh_politoed.png",
        }
    },
    ["hnganh_puppy"] = {
        label = "Cachorro",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_puppy",
        client = {
            image = "hnganh_puppy.png",
        }
    },
    ["hnganh_puppysssv3"] = {
        label = "hnganh_puppysssv3",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_puppysssv3",
        client = {
            image = "hnganh_puppysssv3.png",
        }
    },
    ["hnganh_puppyv3"] = {
        label = "Perruna",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_puppyv3",
        client = {
            image = "hnganh_puppyv3.png",
        }
    },
    ["hnganh_puppyv3ss"] = {
        label = "Adorable",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_puppyv3ss",
        client = {
            image = "hnganh_puppyv3ss.png",
        }
    },
    ["hnganh_reindeer"] = {
        label = "Reno",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_reindeer",
        client = {
            image = "hnganh_reindeer.png",
        }
    },
    ["hnganh_sandwich"] = {
        label = "Sandwich",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_sandwich",
        client = {
            image = "hnganh_sandwich.png",
        }
    },
    ["hnganh_santaclaus"] = {
        label = "Santa Claus",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_santaclaus",
        client = {
            image = "hnganh_santaclaus.png",
        }
    },
    ["hnganh_sealbag"] = {
        label = "Foca",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_sealbag",
        client = {
            image = "hnganh_sealbag.png",
        }
    },
    ["hnganh_shark"] = {
        label = "hnganh_shark",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_shark",
        client = {
            image = "hnganh_shark.png",
        }
    },
    ["hnganh_snowman"] = {
        label = "Muñeco de Nieve",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_snowman",
        client = {
            image = "hnganh_snowman.png",
        }
    },
    ["hnganh_snowmanv2"] = {
        label = "Muñeco de Nieve 2",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_snowmanv2",
        client = {
            image = "hnganh_snowmanv2.png",
        }
    },
    ["hnganh_squirrel"] = {
        label = "Ardilla",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_squirrel",
        client = {
            image = "hnganh_squirrel.png",
        }
    },
    ["hnganh_squirrelv2"] = {
        label = "Ardillita",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_squirrelv2",
        client = {
            image = "hnganh_squirrelv2.png",
        }
    },
    ["hnganh_toadshaped"] = {
        label = "Consola",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_toadshaped",
        client = {
            image = "hnganh_toadshaped.png",
        }
    },
    ["hnganh_toddler"] = {
        label = "Mapache",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_toddler",
        client = {
            image = "hnganh_toddler.png",
        }
    },
    ["hnganh_toucan"] = {
        label = "Tucan",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_toucan",
        client = {
            image = "hnganh_toucan.png",
        }
    },
    ["hnganh_triceraptors"] = {
        label = "Triceraptor",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_triceraptors",
        client = {
            image = "hnganh_triceraptors.png",
        }
    },
    ["hnganh_violin"] = {
        label = "Violin",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_violin",
        client = {
            image = "hnganh_violin.png",
        }
    },
    ["hnganh_watermelon"] = {
        label = "Helado de Sandia",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_watermelon",
        client = {
            image = "hnganh_watermelon.png",
        }
    },
    ["hnganh_yellow"] = {
        label = "hnganh_yellow",
        weight = 0,
        stack = true,
        close = true,
        description = "hnganh_yellow",
        client = {
            image = "hnganh_yellow.png",
        }
    },


    ["costillayatch"] = {
        label = "Costilla del Caribe",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Costilla de cerdo cocinada lentamente y glaseada, acompañada de plátano maduro caramelizado y crema de coco, servida sobre una hoja de plátano.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_steak', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "costillayatch.png",
            notification = 'Costilla glaseada, plátano caramelizado y crema de coco... puro sabor caribeño.',
        }
    },

    ["solomilloyatch"] = {
        label = "Solomillo de Oro",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Jugoso solomillo de ternera coronado con auténtico oro comestible. Un plato exclusivo para los paladares más exigentes.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_steak', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "solomilloyatch.png",
            notification = 'Solomillo jugoso cubierto de oro comestible... un plato de auténtico lujo.',
        }
    },

    ["granizadoyatch"] = {
        label = "Granizado de Parchita",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Refrescante granizado de maracuyá con hielo triturado y un toque de Tajín en el borde. Tropical, dulce y ligeramente picante.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "granizadoyatch.png",
            notification = 'Maracuyá, hielo triturado y un toque de Tajín... dulce, tropical y ligeramente picante.',
        }
    },

    ["limonadayatch"] = {
        label = "Limonada de Coco",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Cremosa limonada de coco con hielo triturado, suave, refrescante y con todo el sabor tropical del Caribe.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "limonadayatch.png",
            notification = 'Cremosa, cítrica y llena de coco... el auténtico sabor del Caribe.',
        }
    },

    ["vipgalaxy"] = {
        label = "Tarjeta VIP Galaxy Night Club",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP de Galaxy Night Club que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "vipgalaxy.png",
        }
    },

    ["figurataxi"] = {
        label = "Taxi Driver",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Pequeña figura coleccionable de un taxista armado, inspirada en el icónico Taxi Driver e ideal para decorar cualquier espacio.",
        client = {
            image = "figurataxi.png",
        }
    },

    ["vippatubadu"] = {
        label = "Tarjeta VIP PatuBadu",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP de PatuBadu que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "vippatubadu.png",
        }
    },

    ["vipuwu"] = {
        label = "Tarjeta VIP UwU Café",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP de UwU Café que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "vipuwu.png",
        }
    },

    ["valetuneo"] = {
        label = "Vale por un Tuneo",
        weight = 3,
        stack = true,
        close = true,
        degrade = 120,
        decay = true,
        description =
        "Vale que otorga un tuneo gratuito en cualquier taller mecánico de la ciudad. Su uso es único e intransferible.",
        client = {
            image = "valetuneo.png",
        }
    },

    ["valecoleccionable"] = {
        label = "Vale por un Coleccionable",
        weight = 3,
        stack = true,
        close = true,
        degrade = 120,
        decay = true,
        description =
        "Vale canjeable por un artículo coleccionable exclusivo en cualquier local de la ciudad. Su uso es único e intransferible.",
        client = {
            image = "valecoleccionable.png",
        }
    },

    ["vale3x3"] = {
        label = "Vale por un 3x3",
        weight = 3,
        stack = true,
        close = true,
        degrade = 60,
        decay = true,
        description = "Vale canjeable por un pack 3x3 en cualquier local de la ciudad. Su uso es único e intransferible.",
        client = {
            image = "vale3x3.png",
        }
    },

    ["valevip"] = {
        label = "Vale por un Coche VIP",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Vale que otorga la adquisición de un vehículo de categoría VIP. Su uso es único e intransferible. Para canjearlo, contacta con el alcalde.",
        client = {
            image = "valevip.png",
        }
    },

    ["valedeluxe"] = {
        label = "Vale por un Coche Deluxe",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Vale que otorga la adquisición de un vehículo de categoría Deluxe. Su uso es único e intransferible. Para canjearlo, contacta con el alcalde.",
        client = {
            image = "valedeluxe.png",
        }
    },

    ["tiburonyatch"] = {
        label = "Capitán Aleta",
        weight = 3,
        stack = true,
        close = true,
        description = "El pequeño pirata marino: gruñón, feroz y siempre preparado para proteger su preciado tesoro.",
        client = {
            image = "tiburonyatch.png",
        }
    },

    ["churrosclub77"] = {
        label = "Churros con Chocolate",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Churros dorados y crujientes, cubiertos hasta la mitad con una generosa capa de chocolate.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'bzzz_foodpack_croissant001', pos = vec3(0.0, 0.0, 0.0), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "churrosclub77.png",
            notification = 'Dorados, crujientes y cubiertos de chocolate... qué buenos estaban.',
        }
    },

    ["lomitoclub77"] = {
        label = "Lomito 77",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Bocadillo argentino de tierna carne a la plancha, jamón, queso fundido, huevo, tomate y lechuga. Contundente y bien cargado.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
            usetime = 3500,
            image = "lomitoclub77.png",
            notification = 'Carne, jamón, queso y huevo... este lomito venía bien cargado.',
        }
    },

    ["tokioburger"] = {
        label = "Tokio Burger",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Una jugosa hamburguesa con un toque japonés, preparada con ingredientes frescos y una combinación de sabores única.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "tokioburger.png",
            notification = 'Carne jugosa y un toque japonés... una combinación realmente única.',
        }
    },

    ["dalsyburger"] = {
        label = "Dalsy Burger",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Hamburguesa jugosa acompañada de una jeringuilla de Dalsy para añadirle su característico toque especial.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
            usetime = 3500,
            image = "dalsyburger.png",
            notification = 'Una hamburguesa jugosa con su dosis especial... sabor inyectado directamente.',
        }
    },

    ["cupcakedefresauwu"] = {
        label = "Cupcake de Fresa",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Esponjoso cupcake de fresa cubierto con una nube de nata cremosa, fresas frescas y un adorable toque de amor UwU.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood6', pos = vec3(0.01, 0.02, -0.01), rot = vec3(-170.0, 88.0, 30.0) },
            usetime = 3500,
            image = "cupcakedefresauwu.png",
            notification = 'Fresa, nata y mucho amor UwU... era tan bonito que daba pena comérselo.',
        }
    },

    ["tartadechocolateuwu"] = {
        label = "Tarta de Chocolate",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Deliciosa tarta de chocolate cubierta de crema, café y mucho amor. Una dulce tentación del UwU Café.",
        client = {
            status = {
                hunger = 200000,
            },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            prop = { model = 'pata_christmasfood6', pos = vec3(0.01, 0.02, -0.01), rot = vec3(-170.0, 88.0, 30.0) },
            usetime = 3500,
            image = "tartadechocolateuwu.png",
            notification = 'Chocolate, crema y café... una dulce tentación cargada de amor UwU.',
        }
    },

    ["sevenvoltclub77"] = {
        label = "Seven Volt 77",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Bebida energética intensa y refrescante, con un toque cítrico y ligeramente dulce. Creada para mantener la energía hasta que cierre el Club 77.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_energy_drink', pos = vec3(0.03, 0.05, 0.0), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "sevenvoltclub77.png",
            notification = 'Cítrica, dulce y cargada de energía... aguanto hasta que cierre el Club 77.',
        }
    },

    ["seventeaclub77"] = {
        label = "Seven Tea",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Té helado de limón, refrescante y ligero, con un sabor cítrico y dulce. Servido bien frío para disfrutar de la noche en Club 77.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "seventeaclub77.png",
            notification = 'Ligero, cítrico y bien frío... perfecto para continuar la noche.',
        }
    },

    ["batidoburger"] = {
        label = "OHVEO",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Batido cremoso, dulce y refrescante, preparado para disfrutarlo bien frío.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "batidoburger.png",
            notification = 'Frío, dulce y muy cremoso... este batido entra solo.',
        }
    },

    ["hidromiel"] = {
        label = "Hidromiel",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description = "Bebida dulce y suave elaborada a base de miel, perfecta para disfrutar bien fría.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "hidromiel.png",
            notification = 'Dulce, suave y llena de miel... una bebida digna de los antiguos dioses.',
        }
    },

    ["batidodevainillauwu"] = {
        label = "Batido de Vainilla",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Delicioso batido de vainilla preparado con leche cremosa, nata montada, sirope dulce y pequeños detalles de chocolate.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
            usetime = 4000,
            image = "batidodevainillauwu.png",
            notification = 'Vainilla, nata y sirope dulce... un batido cremoso y adorable.',
        }
    },

    ["matchalatteuwu"] = {
        label = "Matcha Latte",
        weight = 3,
        stack = true,
        close = true,
        degrade = 10080,
        decay = true,
        description =
        "Delicioso té matcha cremoso con nata montada y un toque dulce, servido con el adorable estilo del UwU Café.",
        client = {
            status = {
                thirst = 200000,
            },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
            prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4000,
            image = "matchalatteuwu.png",
            notification = 'Cremoso, dulce y lleno de matcha... una bebida muy UwU.',
        }
    },

    ["burgercoin"] = {
        label = "Burger Coin",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Moneda coleccionable de Burger, perfecta para guardar como recuerdo o completar una colección especial.",
        client = {
            image = "burgercoin.png",
        }
    },

    ["vipweedland"] = {
        label = "Tarjeta VIP WeedLand",
        weight = 3,
        stack = true,
        close = true,
        description = "Tarjeta VIP de WeedLand que otorga grandes beneficios a sus clientes más exclusivos.",
        client = {
            image = "vipweedland.png",
        }
    },

    ["gatitocowboyuwu"] = {
        label = "Gatito Cowboy",
        weight = 3,
        stack = true,
        close = true,
        description =
        "Adorable gatito rosa de peluche con un sombrero de vaquero a juego, suave, tierno y preparado para cualquier aventura del Lejano Oeste.",
        client = {
            image = "gatitocowboyuwu.png",
        }
    },

-- =============== ITEMS COLECCIONABLES DE RASCAS ====================

["llaveburger"] = {
    label = "Llave Burger Shot",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Burger Shot.",
    client = {
        image = "llaveburger.png",
    }
},

["llaveriviera"] = {
    label = "Llave La Riviera",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de La Riviera.",
    client = {
        image = "llaveriviera.png",
    }
},

["llaverex"] = {
    label = "Llave Rex Dinner",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Rex Dinner.",
    client = {
        image = "llaverex.png",
    }
},

["llaveuwu"] = {
    label = "Llave UwU Café",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de UwU Café.",
    client = {
        image = "llaveuwu.png",
    }
},

["llaveyellow"] = {
    label = "Llave Yellow Jack Inm",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Yellow Jack Inm.",
    client = {
        image = "llaveyellow.png",
    }
},

["llaveyacht"] = {
    label = "Llave Yacht Restaurant",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Yacht Restaurant.",
    client = {
        image = "llaveyacht.png",
    }
},

["llavethis"] = {
    label = "Llave Pizza This",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Pizza This.",
    client = {
        image = "llavethis.png",
    }
},

["llavesantos"] = {
    label = "Llave Los Santos Customs",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del taller Los Santos Customs.",
    client = {
        image = "llavesantos.png",
    }
},

["llaveauto"] = {
    label = "Llave Auto Exotic",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del taller Auto Exotic.",
    client = {
        image = "llaveauto.png",
    }
},

["llaveruta"] = {
    label = "Llave Ruta 68",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del taller Ruta 68.",
    client = {
        image = "llaveruta.png",
    }
},

["llavebennys"] = {
    label = "Llave Benny's",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del taller Benny's.",
    client = {
        image = "llavebennys.png",
    }
},

["llavehayes"] = {
    label = "Llave Hayes Autos",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del taller Hayes Autos.",
    client = {
        image = "llavehayes.png",
    }
},

["llaveottos"] = {
    label = "Llave Ottos Autos",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del taller Ottos Autos.",
    client = {
        image = "llaveottos.png",
    }
},

["llavediner"] = {
    label = "Llave Rex Dinner",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Rex Dinner.",
    client = {
        image = "llavediner.png",
    }
},

["llavepatu"] = {
    label = "Llave Patu Badu",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del Badulaque Patu Badu.",
    client = {
        image = "llavepatu.png",
    }
},

["llavegrove"] = {
    label = "Llave Badu Grove",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del Badulaque Grove Street.",
    client = {
        image = "llavegrove.png",
    }
},

["llave68"] = {
    label = "Llave Badu Ruta 68",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del Badulaque Ruta 68.",
    client = {
        image = "llave68.png",
    }
},

["llavemirror"] = {
    label = "Llave Badulaque Mirror Park",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del Badulaque Mirror Park.",
    client = {
        image = "llavemirror.png",
    }
},

["llavetequila"] = {
    label = "Llave Tequila-La",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Tequila-La.",
    client = {
        image = "llavetequila.png",
    }
},

["llave77"] = {
    label = "Llave Club 77",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del Club 77.",
    client = {
        image = "llave77.png",
    }
},

["llavepacific"] = {
    label = "Llave Pacific",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Pacific Clubs.",
    client = {
        image = "llavepacific.png",
    }
},

["llavebahamas"] = {
    label = "Llave Bahamas",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Bahama Mamas West.",
    client = {
        image = "llavebahamas.png",
    }
},

["llavegalaxy"] = {
    label = "Llave Galaxy Club",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Galaxy Club.",
    client = {
        image = "llavegalaxy.png",
    }
},

["llavecasino"] = {
    label = "Llave Casino Diamond",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del Casino Diamond.",
    client = {
        image = "llavecasino.png",
    }
},

["llavearcade"] = {
    label = "Llave Eight Bit Arcade",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Eight Bit Arcade.",
    client = {
        image = "llavearcade.png",
    }
},

["llaveweedland"] = {
    label = "Llave WeedLand",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de WeedLand.",
    client = {
        image = "llaveweedland.png",
    }
},

["llavevanilla"] = {
    label = "Llave Vanilla Unicorn",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Vanilla Unicorn.",
    client = {
        image = "llavevanilla.png",
    }
},

["llaveweazel"] = {
    label = "Llave Weazel News",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Weazel News.",
    client = {
        image = "llaveweazel.png",
    }
},

["llavebolera"] = {
    label = "Llave Bowling Bar",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Bowling Bar.",
    client = {
        image = "llavebolera.png",
    }
},

["llaverockford"] = {
    label = "Llave Rockford Records",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Rockford Records.",
    client = {
        image = "llaverockford.png",
    }
},

["llavetaxis"] = {
    label = "Llave Downtown Cab Co.",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Downtown Cab Co.",
    client = {
        image = "llavetaxis.png",
    }
},

["llavecompraventa"] = {
    label = "Llave Compra-Venta",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Compra-Venta Los Mendoza.",
    client = {
        image = "llavecompraventa.png",
    }
},

["llaveairlanda"] = {
    label = "Llave Airlanda",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Airlanda.",
    client = {
        image = "llaveairlanda.png",
    }
},

["lasanariviera"] = {
    label = "Lasagna alla Bolognese",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Capas de pasta, ragú boloñés y bechamel, horneadas al estilo tradicional italiano. Un clásico que sabe a hogar.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
        prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
        usetime = 3500,
        image = "lasanariviera.png",
        notification = 'Pasta, ragú y bechamel horneada... una lasaña que sabe a hogar.',
    }
},

["gnocchiriviera"] = {
    label = "Gnocchi al Gorgonzola",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Tiernos gnocchi de patata bañados en una cremosa salsa de gorgonzola. Puro placer italiano.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
        prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
        usetime = 3500,
        image = "gnocchiriviera.png",
        notification = 'Gnocchi tiernos y una cremosa salsa de gorgonzola... puro placer italiano.',
    }
},

["chipstallerrex"] = {
    label = "Rex's Crunch Chips",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Patatas chips crujientes y doradas, con un toque de sal y todo el estilo retro americano.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'anim@amb@casino@hangout@ped_male@stand_withdrink@01a@exit', clip = 'exit' },
        prop = { model = 'prop_ld_snack_01', pos = vec3(0.0, 0.0, 0.0), rot = vec3(90.0, 0.0, 40.0) },
        usetime = 3500,
        image = "chipstallerrex.png",
        notification = 'Doradas, crujientes y con el punto justo de sal... puro estilo americano.',
    }
},

["donuttallerrex"] = {
    label = "Rex's Donut",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Donut americano con glaseado rosa brillante y toppings de colores. Un capricho dulce y salvaje.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
        prop = { model = 'prop_donut_02', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 90.0, -180.0), bone = 4186 },
        usetime = 3500,
        image = "donuttallerrex.png",
        notification = 'Glaseado rosa y toppings de colores... un capricho dulce y salvaje.',
    }
},

["patudog"] = {
    label = "PatuDog Deluxe",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Delicioso perrito caliente cargado de sabor, con salchicha jugosa, salsas irresistibles y el toque especial de Patubadu.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
        prop = { model = 'prop_cs_hotdog_02', pos = vec3(0.03, 0.05, -0.01), bone = 58867, rot = vec3(-90.0, 0.0, 45.0) },
        usetime = 3500,
        image = "patudog.png",
        notification = 'Salchicha jugosa y salsas irresistibles... ¡qué PatuDog tan bueno! ¡CUAK!',
    }
},

["patudonu"] = {
    label = "Patu Donut",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Delicioso donut esponjoso decorado con el toque especial de Patubadu. Dulzura en cada mordisco.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
        prop = { model = 'prop_donut_01', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 90.0, 0.0), bone = 4186 },
        usetime = 3500,
        image = "patudonu.png",
        notification = 'Esponjoso, dulce y con el toque de Patubadu... ¡CUAK!',
    }
},

["payobolera"] = {
    label = "Payo Supreme",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Sándwich bien jugoso, cargado con extra de cerdo y preparado con un sabor irresistible.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
        prop = { model = 'prop_sandwich_01', pos = vec3(0.03, -0.02, -0.02), rot = vec3(60.0, 0.0, 0.0) },
        usetime = 3500,
        image = "payobolera.png",
        notification = 'Jugoso, bien cargado y con extra de cerdo... un sándwich supremo.',
    }
},

["bolasbolera"] = {
    label = "El Secreto Fundido",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Crujientes bocados rellenos de queso fundido, acompañados de salsa secreta y un toque verde.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
        prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
        usetime = 3500,
        image = "bolasbolera.png",
        notification = 'Crujientes por fuera y llenas de queso fundido... el secreto estaba delicioso.',
    }
},

["birrariviera"] = {
    label = "Birra di la Riviera",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Cerveza ligera, refrescante y con auténtico espíritu italiano. Una birra suave para disfrutar sin renunciar al sabor.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
        prop = { model = 'h4_prop_h4_can_beer_01a', pos = vec3(0.01, 0.01, 0.0), rot = vec3(5.0, 5.0, -180.5) },
        usetime = 4000,
        image = "birrariviera.png",
        notification = 'Ligera, suave y refrescante... auténtico espíritu italiano.',
    }
},

["rivieravino"] = {
    label = "Rosso di la Riviera",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Un vino nacido a los pies del Vesubio, con carácter volcánico y esencia napolitana. Italia en cada copa.",
},

["fresastallerrex"] = {
    label = "Rex's Fresisuis",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Delicioso fresisuis cargado de fresas y dulzura. El capricho perfecto para refrescarse.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
        prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
        usetime = 4000,
        image = "fresastallerrex.png",
        notification = 'Frío, dulce y cargado de fresas... el capricho perfecto.',
    }
},

["sunnytallerrex"] = {
    label = "Sunny Rex's",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Refresco Sunny de naranja, dulce y refrescante, ideal para acompañar cualquier parada.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
        prop = { model = 'prop_orang_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
        usetime = 4000,
        image = "sunnytallerrex.png",
        notification = 'Dulce, cítrico y muy refrescante... perfecto para hacer una parada.',
    }
},

["patudaniels"] = {
    label = "Patu Daniels",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Whisky de sabor intenso y carácter único, inspirado en el clásico Jack Daniel's y acompañado del toque atrevido de Patubadu.",
        client = {
            image = "patudaniels.png",
        }
},

["patufrape"] = {
    label = "Patu Frappé",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Frappé de café cremoso y refrescante, coronado con nata, caramelo y el toque especial de Patubadu.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
        prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
        usetime = 4000,
        image = "patufrape.png",
        notification = 'Café, nata y caramelo... dulzura y energía en cada sorbo. ¡CUAK!',
    }
},

["cocobolera"] = {
    label = "Coco Paradise",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Exquisito cóctel tropical preparado con coco y ron, coronado con crema y un toque de magia.",
    client = {
        image = "cocobolera.png",
    }
},

["energeticabolera"] = {
    label = "Strike Energético",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Una explosión de uva intensa y energía vibrante, creada para dominar cada partida.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
        prop = { model = 'prop_energy_drink', pos = vec3(0.03, 0.05, 0.0), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
        usetime = 4000,
        image = "energeticabolera.png",
        notification = 'Uva intensa y energía vibrante... listo para conseguir otro strike.',
    }
},

["vipbolera"] = {
    label = "Tarjeta VIP Bowling Bar",
    weight = 3,
    stack = true,
    close = true,
    description = "Tarjeta VIP de Bowling Bar que otorga grandes beneficios a los clientes que la portan.",
    client = {
        image = "vipbolera.png",
    }
},

["cochegolfruta68"] = {
    label = "Coche Golf Ruta 68",
    weight = 3,
    stack = true,
    close = true,
    description = "Miniatura coleccionable exclusiva de un coche de golf de Ruta 68.",
    client = {
        image = "cochegolfruta68.png",
    }
},

["viprockford"] = {
    label = "Tarjeta VIP Rockford Records",
    weight = 3,
    stack = true,
    close = true,
    description = "Tarjeta VIP de Rockford Records que otorga grandes beneficios a los clientes que la portan.",
    client = {
        image = "viprockford.png",
    }
},

["panetoneriviera"] = {
    label = "Don Panettone",
    weight = 3,
    stack = true,
    close = true,
    description = "Un dulce abrazo con sabor italiano. Este adorable panettone de peluche es tan achuchable como irresistible.",
    client = {
        image = "panetoneriviera.png",
    }
},

["torerosantos"] = {
    label = "Llavero ToreroXO",
    weight = 3,
    stack = true,
    close = true,
    description = "Llavero coleccionable de Los Santos Customs, perfecto para llevar las llaves de tu superdeportivo.",
    client = {
        image = "torerosantos.png",
    }
},

["tussijijnsantos"] = {
    label = "El Tussijín Santa",
    weight = 3,
    stack = true,
    close = true,
    description = "El peluche más macarra de Los Santos Customs, preparado para acompañarte en cualquier trayecto.",
    client = {
        image = "tussijijnsantos.png",
    }
},

["llaverotallerrex"] = {
    label = "Llavero Rex's Biker",
    weight = 3,
    stack = true,
    close = true,
    description = "Llavero con una moto custom de estilo Harley, perfecto para los amantes de las dos ruedas.",
    client = {
        image = "llaverotallerrex.png",
    }
},

["mascotatallerrex"] = {
    label = "Rex-Reaper",
    weight = 3,
    stack = true,
    close = true,
    description = "Un T-Rex con mala leche y actitud de sobra. La mascota más salvaje para llevarte un recuerdo con mordida incluida.",
    client = {
        image = "mascotatallerrex.png",
    }
},

["viptallerrex"] = {
    label = "Tarjeta VIP Taller Rex's Diner",
    weight = 3,
    stack = true,
    close = true,
    description = "Tarjeta VIP del taller Rex's Diner que otorga grandes beneficios a los clientes que la portan.",
    client = {
        image = "viptallerrex.png",
    }
},

["bowlito"] = {
    label = "Bowlito",
    weight = 3,
    stack = true,
    close = true,
    description = "Nacido entre neones y plenos legendarios, este peluche guarda toda la magia y los secretos de Bowling Bar.",
    client = {
        image = "bowlito.png",
    }
},

-- ======================= EVENTO DE HALLOWEEN ========================

    ["halloweentarjetacementerio"] = { -- 1
        label = "Tarjeta de visita",
        weight = 3,
        stack = true,
        close = true,
        description = "El alcalde la entrega como autorización para investigar. Al enseñársela a Julián, acepta colaborar.",
        client = {
            image = "halloweentarjetacementerio.png",
        }
    },
    ["halloweenllavesdoradas"] = { -- 2
        label = "Llaves sospechosas",
        weight = 3,
        stack = true,
        close = true,
        description = "Julián las encontró cerca del cadáver. Llevan una pequeña etiqueta: «Santa Aurora · Almacén 3». Permiten abrir el almacén de la funeraria.",
        client = {
            image = "halloweenllavesdoradas.png",
        }
    },
    ["halloweenmaletincondocumentos"] = { -- 3
        label = "Maletin con documentos",
        weight = 3,
        stack = true,
        close = true,
        description = "Elisa lo apartó antes de que lo quemaran. Contiene recibos de sepulturas duplicadas y una nota de Samuel que conduce al archivo municipal.",
        client = {
            image = "halloweenmaletincondocumentos.png",
        }
    },
    ["halloweentarjetacementerioencargado"] = { -- 4
        label = "Tarjeta de Encargado",
        weight = 3,
        stack = true,
        close = true,
        description = "Viktor la dejó olvidada cuando consultó los expedientes que después intentó ocultar. Lleva su nombre, fotografía y acceso a la zona de mantenimiento.",
        client = {
            image = "halloweentarjetacementerioencargado.png",
        }
    },
    ["halloweengrabadoradevoz"] = { -- 5
        label = "Grabadora de voz antigua",
        weight = 3,
        stack = true,
        close = true,
        description = "La grabación vincula a Viktor con el asesinato. Con su tarjeta se puede acceder al cobertizo donde está preparando su huida.",
        client = {
            image = "halloweengrabadoradevoz.png",
        }
    },
    ["halloweencondecoracion"] = { -- 6
        label = "Medal of Valor",
        weight = 3,
        stack = true,
        close = true,
        description = "La medalla al valor por colaborar con la justicia sobre un crimen, dirigida a los ciudadanos por parte de la LSPD",
        client = {
            image = "halloweencondecoracion.png",
        }
    },

    ["tartademanzana"] = {
    label = "Tarta de Manzana",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Un postre dulce, suave y aromático, preparado con manzana cocida, un toque de canela y una deliciosa base crujiente.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
        prop = { model = 'pata_christmasfood6', pos = vec3(0.01, 0.02, -0.01), rot = vec3(-170.0, 88.0, 30.0) },
        usetime = 3500,
        image = "tartademanzana.png",
        notification = 'Manzana cocida, canela y una base crujiente... una tarta dulce y aromática.',
    }
},

["patatasfritascasey"] = {
    label = "Patatas Fritas",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Patatas fritas crujientes por fuera y tiernas por dentro, con el punto perfecto de sal.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
        prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
        usetime = 3500,
        image = "patatasfritascasey.png",
        notification = 'Crujientes, tiernas y con el punto perfecto de sal... no ha quedado ni una.',
    }
},

["desayunoamericano"] = {
    label = "Desayuno Americano",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Una abundante combinación de tortitas dulces, huevos, bacon crujiente y salchichas, mezclando sabores dulces y salados.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
        prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
        usetime = 3500,
        image = "desayunoamericano.png",
        notification = 'Tortitas, huevos, bacon y salchichas... un desayuno americano bien completo.',
    }
},

["burgercaseydinner"] = {
    label = "Burger Casey",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Hamburguesa jugosa y contundente, preparada con carne sabrosa, pan suave, ingredientes variados y una cremosa salsa Casey de sabor dulce y especiado.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
        prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, -0.02, -0.07), rot = vec3(10.0, 70.0, -90.0) },
        usetime = 3500,
        image = "burgercaseydinner.png",
        notification = 'Carne jugosa y salsa Casey dulce y especiada... una hamburguesa realmente contundente.',
    }
},

["rootbeercasey"] = {
    label = "Root Beer",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Bebida gaseosa, dulce y aromática, con sabor herbal y delicadas notas de vainilla y regaliz.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
        prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
        usetime = 4000,
        image = "rootbeercasey.png",
        notification = 'Dulce, aromática y con notas de vainilla y regaliz... una Root Beer muy especial.',
    }
},

["milkshake"] = {
    label = "Milkshake",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Batido dulce, cremoso y frío, preparado con leche y helado para conseguir una textura suave y un sabor intenso.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
        prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
        usetime = 4000,
        image = "milkshake.png",
        notification = 'Frío, dulce y muy cremoso... este milkshake estaba delicioso.',
    }
},

["cafeexpreso"] = {
    label = "Café Expreso",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Café pequeño, fuerte y concentrado, con un sabor intenso y ligeramente amargo.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
        prop = { model = 'p_ing_coffeecup_01', pos = vec3(0.03, 0.05, 0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
        usetime = 4000,
        image = "cafeexpreso.png",
        notification = 'Pequeño, fuerte y concentrado... este expreso despierta a cualquiera.',
    }
},

["refrescocolacasey"] = {
    label = "Refresco Cola",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Refresco de cola oscuro, gaseoso y extremadamente dulce, capaz de desafiar las leyes de la lógica.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
        prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
        usetime = 4000,
        image = "refrescocolacasey.png",
        notification = 'Oscuro, burbujeante y absurdamente dulce... la lógica acaba de desaparecer.',
    }
},

["ositincasey"] = {
    label = "Casey Sweet",
    weight = 3,
    stack = true,
    close = true,
    description = "Adorable y colorido osito de peluche con gorrito y comida en la mano, lleno de alegría y con un estilo dulce y juguetón.",
    client = {
        image = "ositincasey.png",
    }
},

["amirdurum"] = {
    label = "Amir Durum",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Torta de trigo enrollada con carne, lechuga fresca y extra de salsa blanca.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
        prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
        usetime = 3500,
        image = "amirdurum.png",
        notification = 'Carne, lechuga fresca y mucha salsa blanca... este durum estaba increíble.',
    }
},

["amirkebab"] = {
    label = "Amir Kebab",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Pan pita relleno de jugosa carne de kebab, lechuga fresca y abundante salsa blanca.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
        prop = { model = 'prop_food_bs_burger2', pos = vec3(0.07, 0.0, -0.07), rot = vec3(-12.0, 40.0, -90.0) },
        usetime = 3500,
        image = "amirkebab.png",
        notification = 'Carne jugosa, lechuga y mucha salsa blanca... un kebab bien cargado.',
    }
},

["falafelbox"] = {
    label = "Falafel Box",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Deliciosas croquetas de garbanzo, doradas y crujientes, acompañadas de una salsa especial.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
        prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
        usetime = 3500,
        image = "falafelbox.png",
        notification = 'Dorados, crujientes y acompañados de salsa especial... no ha quedado ni un falafel.',
    }
},

["patataskebab"] = {
    label = "Patatas Gratinadas con Carne",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Patatas crujientes cubiertas con carne de kebab y una generosa capa de queso fundido.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
        prop = { model = 'prop_food_chips', pos = vec3(0.05, -0.05, -0.05), rot = vec3(15.10, 0.0, -190.0), bone = 26612 },
        usetime = 3500,
        image = "patataskebab.png",
        notification = 'Patatas crujientes, carne de kebab y queso fundido... una combinación brutal.',
    }
},

["escabechepearls"] = {
    label = "Escabeche del Capitán",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Jugosos mejillones en escabeche, preparados como un auténtico tesoro del mar.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
        prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
        usetime = 3500,
        image = "escabechepearls.png",
        notification = 'Jugosos y llenos de sabor... el capitán escondía un auténtico tesoro.',
    }
},

["ostrapearls"] = {
    label = "Ostra Imperial",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Ostra fresca de sabor intenso, un capricho marino digno de Pearls Ocean.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
        prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
        usetime = 3500,
        image = "ostrapearls.png",
        notification = 'Fresca, intensa y exquisita... una ostra digna de la realeza.',
    }
},

["gambonespearls"] = {
    label = "Gambones Ola Azul",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Exquisitos gambones preparados con la exclusiva esencia marina de Pearls Ocean.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
        prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
        usetime = 3500,
        image = "gambonespearls.png",
        notification = 'Jugosos y llenos de esencia marina... auténtico lujo del océano.',
    }
},

["pastapearls"] = {
    label = "Pasta Marinera",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Pasta marinera sencilla y elegante, preparada con el toque exclusivo de Pearls Ocean.",
    client = {
        status = {
            hunger = 200000,
        },
        anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' },
        prop = { model = 'prop_cs_bowl_01b', pos = vec3(0.0, 0.0, 0.0), bone = 60309, rot = vec3(0.0, 0.0, 0.0) },
        usetime = 3500,
        image = "pastapearls.png",
        notification = 'Sencilla, elegante y con sabor a mar... el toque exclusivo de Pearls.',
    }
},

["colakebab"] = {
    label = "Refresco de Cola",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "El clásico refresco de cola, servido bien frío para calmar la sed.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
        prop = { model = 'prop_ecola_can', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
        usetime = 4000,
        image = "colakebab.png",
        notification = 'Dulce, burbujeante y bien frío... perfecto para acompañar el kebab.',
    }
},

["teakebab"] = {
    label = "Refresco de Té",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Té frío muy refrescante, con un toque dulce y cítrico.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
        prop = { model = 'prop_cs_paper_cup', pos = vec3(0.03, 0.05, -0.03), bone = 58867, rot = vec3(0.0, 0.0, 0.0) },
        usetime = 4000,
        image = "teakebab.png",
        notification = 'Frío, dulce y con un toque cítrico... qué té tan refrescante.',
    }
},

["naranjakebab"] = {
    label = "Refresco de Naranja",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Refresco burbujeante con un intenso y dulce sabor a naranja.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
        prop = { model = 'prop_orang_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
        usetime = 4000,
        image = "naranjakebab.png",
        notification = 'Dulce, cítrico y lleno de burbujas... naranja hasta el último sorbo.',
    }
},

["cervezakebab"] = {
    label = "Cerveza",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Cerveza bien fría, perfecta para acompañar cualquier menú de Amir Kebab.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
        prop = { model = 'h4_prop_h4_can_beer_01a', pos = vec3(0.01, 0.01, 0.0), rot = vec3(5.0, 5.0, -180.5) },
        usetime = 4000,
        image = "cervezakebab.png",
        notification = 'Bien fría y refrescante... la compañera perfecta para un buen kebab.',
    }
},

["cocopearls"] = {
    label = "Coco Loco",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Una combinación refrescante con la frescura de la lima y la suavidad del coco en cada sorbo.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
        prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
        usetime = 4000,
        image = "cocopearls.png",
        notification = 'Lima fresca y coco suave... una locura tropical muy refrescante.',
    }
},

["pearlsblack"] = {
    label = "Pearls Black",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Un cóctel oscuro y elegante. Un trago, mil historias y ninguna prisa.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
        prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
        usetime = 4000,
        image = "pearlsblack.png",
        notification = 'Oscuro, elegante y lleno de historias... no hay ninguna prisa.',
    }
},

["limonpearls"] = {
    label = "Pearls Lemon",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Una bebida con un intenso toque cítrico, servida bien fría y directa al alma.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
        prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
        usetime = 4000,
        image = "limonpearls.png",
        notification = 'Cítrico, helado y refrescante... directo al alma.',
    }
},

["nubepearls"] = {
    label = "Nube Tropical",
    weight = 3,
    stack = true,
    close = true,
    degrade = 10080,
    decay = true,
    description = "Una bebida tropical, cremosa y refrescante que sabe a vacaciones junto al mar.",
    client = {
        status = {
            thirst = 200000,
        },
        anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_a' },
        prop = { model = 'sf_p_sf_grass_gls_s_01a', pos = vec3(-0.01, 0.07, -0.13), bone = 58867, rot = vec3(-2.0, 10.0, 0.0) },
        usetime = 4000,
        image = "nubepearls.png",
        notification = 'Cremosa, tropical y refrescante... este sorbo sabe a vacaciones.',
    }
},

["persito"] = {
    label = "Persito",
    weight = 3,
    stack = true,
    close = true,
    description = "Un pequeño guardián del mar que lleva el espíritu de Pearls Ocean a todas partes.",
    client = {
        image = "persito.png",
    }
},

["vippearls"] = {
    label = "Tarjeta VIP Pearls Ocean",
    weight = 3,
    stack = true,
    close = true,
    description = "Tarjeta VIP de Pearls Ocean que otorga grandes beneficios a sus clientes más exclusivos.",
    client = {
        image = "vippearls.png",
    }
},

["amir"] = {
    label = "Peluche Amir",
    weight = 3,
    stack = true,
    close = true,
    description = "Peluche coleccionable del inconfundible Amir, con su característico aspecto tras largas jornadas preparando kebabs.",
    client = {
        image = "amir.png",
    }
},

["llavecasey"] = {
    label = "Llave Casey's Diner",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Casey's Diner.",
    client = {
        image = "llavecasey.png",
    }
},

["llavepearls"] = {
    label = "Llave Restaurante Pearls",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva del restaurante Pearls Ocean.",
    client = {
        image = "llavepearls.png",
    }
},

["llavekebab"] = {
    label = "Llave Amir Kebab",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Amir Kebab.",
    client = {
        image = "llavekebab.png",
    }
},

["llavecompraventanorte"] = {
    label = "Llave Compraventa Ruta 68",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Compraventa Ruta 68.",
    client = {
        image = "llavecompraventanorte.png",
    }
},

["llavecompraventasur"] = {
    label = "Llave Compraventa Ottos",
    weight = 3,
    stack = true,
    close = true,
    description = "¡Enhorabuena! Has conseguido la llave exclusiva de Compraventa Ottos.",
    client = {
        image = "llavecompraventasur.png",
    }
},

["dados568"] = {
    label = "Dados R.68",
    weight = 3,
    stack = true,
    close = true,
    description = "Dados coleccionables para quienes viven rápido y conducen todavía más rápido. Si no dejan de moverse, es que vas a tope.",
    client = {
        image = "dados568.png",
    }
},

["llaveror68"] = {
    label = "Llavero R.68",
    weight = 3,
    stack = true,
    close = true,
    description = "Los coches van y vienen, pero con este llavero coleccionable de Ruta 68 tus llaves siempre aparecen.",
    client = {
        image = "llaveror68.png",
    }
},

    -- ========================= pug-robberycreator =============

    ["bluetooth_speaker"] = {
        label = "Bluetooth Speaker",
        weight = 600,
        stack = true,
        close = false,
        description = "",
        rarity = "rare",
    },

    ["wireless_headphones"] = {
        label = "Wireless Headphones",
        weight = 350,
        stack = true,
        close = false,
        description = "",
        rarity = "rare",
    },

    ["game_console"] = {
        label = "Game Console",
        weight = 2200,
        stack = true,
        close = false,
        description = "",
        rarity = "rare",
    },

    ["car_stereo"] = {
        label = "Car Stereo",
        weight = 900,
        stack = true,
        close = false,
        description = "",
        rarity = "uncommon",
    },

    ["stolen_toolbox"] = {
        label = "Frank's Toolbox",
        weight = 3000,
        stack = true,
        close = false,
        description = "",
        rarity = "uncommon",
    },

    ["stolen_television"] = {
        label = "Flatscreen Television",
        weight = 5000,
        stack = true,
        close = false,
        description = "",
        rarity = "uncommon",
    },

    ["toaster"] = {
        label = "Toaster",
        weight = 1200,
        stack = true,
        close = false,
        description = "",
        rarity = "common",
    },

    ["microwave"] = {
        label = "Microwave",
        weight = 4500,
        stack = true,
        close = false,
        description = "",
        rarity = "uncommon",
    },

    ["coffee_machine"] = {
        label = "Coffee Machine",
        weight = 1800,
        stack = true,
        close = false,
        description = "",
        rarity = "common",
    },

    ["electric_kettle"] = {
        label = "Electric Kettle",
        weight = 1000,
        stack = true,
        close = false,
        description = "",
        rarity = "common",
    },

    ["standing_fan"] = {
        label = "Standing Fan",
        weight = 2000,
        stack = true,
        close = false,
        description = "",
        rarity = "common",
    },

    ["desk_lamp"] = {
        label = "Desk Lamp",
        weight = 700,
        stack = true,
        close = false,
        description = "",
        rarity = "common",
    },

    ["gaming_keyboard"] = {
        label = "Gaming Keyboard",
        weight = 650,
        stack = true,
        close = false,
        description = "",
        rarity = "uncommon",
    },

    ["computer_monitor"] = {
        label = "Computer Monitor",
        weight = 3200,
        stack = true,
        close = false,
        description = "",
        rarity = "uncommon",
    },

    ["air_fryer"] = {
        label = "Air Fryer",
        weight = 2100,
        stack = true,
        close = false,
        description = "",
        rarity = "common",
    },

    ["platinum_bar"] = {
        label = "Platinum Bar",
        weight = 1200,
        stack = true,
        close = false,
        description = "",
        rarity = "legendary",
    },

    ["luxury_watch"] = {
        label = "Luxury Watch",
        weight = 40,
        stack = true,
        close = false,
        description = "",
        rarity = "rare",
    },

    ["gaming_laptop"] = {
        label = "Gaming Laptop",
        weight = 2200,
        stack = true,
        close = false,
        description = "",
        rarity = "legendary",
    },

    ["camera_pro"] = {
        label = "Professional Camera",
        weight = 900,
        stack = true,
        close = false,
        description = "",
        rarity = "epic",
    },

    ["drone"] = {
        label = "Drone",
        weight = 1200,
        stack = true,
        close = false,
        description = "",
        rarity = "epic",
    },

    ["graphics_card"] = {
        label = "Graphics Card",
        weight = 400,
        stack = true,
        close = false,
        description = "",
        rarity = "legendary",
    },

    ["vr_headset"] = {
        label = "VR Headset",
        weight = 800,
        stack = true,
        close = false,
        description = "",
        rarity = "rare",
    },

    ["designer_handbag"] = {
        label = "Designer Handbag",
        weight = 300,
        stack = true,
        close = false,
        description = "",
        rarity = "epic",
    },

    ["designer_sneakers"] = {
        label = "Designer Sneakers",
        weight = 700,
        stack = true,
        close = false,
        description = "",
        rarity = "rare",
    },

    ["fur_coat"] = {
        label = "Luxury Fur Coat",
        weight = 1200,
        stack = true,
        close = false,
        description = "",
        rarity = "epic",
    },

    ["designer_sunglasses"] = {
        label = "Designer Sunglasses",
        weight = 50,
        stack = true,
        close = false,
        description = "",
        rarity = "rare",
    },

    ["gold_bar"] = {
        label = "Gold Bar",
        weight = 1000,
        stack = true,
        close = false,
        description = "",
        rarity = "legendary",
    },

    ["gold_scrap"] = {
        label = "Gold Scrap",
        weight = 150,
        stack = true,
        close = false,
        description = "",
        rarity = "epic",
    },

    ["silver_bar"] = {
        label = "Silver Bar",
        weight = 900,
        stack = true,
        close = false,
        description = "",
        rarity = "epic",
    },

    ["silver_scrap"] = {
        label = "Silver Scrap",
        weight = 140,
        stack = true,
        close = false,
        description = "",
        rarity = "rare",
    },

    ["diamond_watch"] = {
        label = "Diamond Watch",
        weight = 60,
        stack = true,
        close = false,
        description = "",
        rarity = "legendary",
    },

    ["ruby_necklace"] = {
        label = "Ruby Necklace",
        weight = 30,
        stack = true,
        close = false,
        description = "",
        rarity = "epic",
    },

    ["emerald_bracelet"] = {
        label = "Emerald Bracelet",
        weight = 25,
        stack = true,
        close = false,
        description = "",
        rarity = "epic",
    },

    ["sapphire_earrings"] = {
        label = "Sapphire Earrings",
        weight = 10,
        stack = true,
        close = false,
        description = "",
        rarity = "rare",
    },

    -- ========================= jj_recoil =============

    ["energetica_recoil"] = {
        label = "Energética de precisión",
        weight = 3,
        stack = true,
        close = true,
        description = "Te deja el pulso más firme durante un rato.",
        client = {
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
            prop = { model = 'prop_energy_drink', pos = vec3(0.03, 0.05, 0.0), bone = 58866, rot = vec3(0.0, 0.0, 0.0) },
            usetime = 5000,
            label = 'Bebiendo energética...',
            image = "energyshot.png",
        },
        server = {
            export = 'jj_recoil.energyDrink',
        },
    },

    ["tablet_crew"] = {
        label = "Tablet de Crews",
        weight = 10,
        stack = false,
        close = true,
        description = "Una tablet para gestionar tu crew de pilotos.",
        client = {
            export = "jj_crews.openTablet", image = "tablet_crew.png"
        },
        modelp = 'reh_prop_reh_tablet_01a',
    },

    ["tablet_reacing"] = {
        label = "Tablet de Carreras",
        weight = 10,
        stack = false,
        close = true,
        description = "Una tablet con los circuitos, las salas y los resultados de las carreras.",
        client = {
            export = "jj_racing.openTablet", image = "tablet_reacing.png"
        },
        modelp = 'reh_prop_reh_tablet_01a',
    },
}
