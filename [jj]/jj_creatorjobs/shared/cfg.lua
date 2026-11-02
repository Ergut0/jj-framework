Config = {}

Config.ImageServer = "https://r2.fivemanage.com/pIKMGpPJgjMPxqPrXQTzX/03_logo_atlantis_original.png" -- Imagen por defecto de los trabajos nuevos

Config.MaxLevel = 4 -- Nivel máximo de los trabajos

Config.MaxExp = 100 -- Experiencia necesaria para subir de nivel

Config.MaxMoneyBillLevel = 2000 -- Importe de factura que da la experiencia máxima

Config.ExpBill = 5 -- Experiencia máxima por factura pagada; baja si el importe es menor

Config.Target = false -- true para hablar con el proveedor de la lonja con ox_target; false para usar la tecla E

Config.Lonja = {
    {
        nameLonja = "Gabrielas market",
        coords = vector4(52.99, -1478.92, 29.29, 181.83),
        ped = "a_m_y_business_01",
    },
    {
        nameLonja = "Mayorista Norte",
        coords = vector4(1779.19, 3640.99, 34.50, 20.46),
        ped = "a_m_y_business_01",
    },
}

Config.addKeyVehicle = function(veh, plate)
    Entity(veh).state:set('HotWire', 'StopNeedHotWire', true)
end

-- Días que se guarda el registro de cada empresa
-- Los webhooks de Discord están en server/logs.lua, que no llega a los jugadores a diferencia de este archivo
Config.LogDays = 30

-- La cuenta de la sociedad es la cuenta de empresa de fd_banking, la misma que ve el jefe en el banco y en el móvil.
-- Con false, o si fd_banking no está arrancado, se usa la columna money de jobscreator_jobs.
Config.UseBanking = true

-- Con true, los sueldos salen de la cuenta de la sociedad a las :00 y las :30, y solo se cobran de servicio.
-- Con false, los paga jj-framework con sus nóminas normales, sin sacarlos de la sociedad.
Config.SocietyPaycheck = true
