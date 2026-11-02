-- Editor de circuitos en el mundo (solo administradores). El borrador vive en la NUI: al entrar
-- se envia aqui, se edita con el cursor (mira) o la posicion del jugador y al salir vuelve a la NUI.
-- El servidor valida y guarda; este modulo solo dibuja y recoge posiciones. Sin editor activo no hay bucles.

Creator = { active = false }

local C = nil
local KINDS = { 'normal', 'shortcut', 'pit', 'grid' }
local COLORS = {
    normal = { 168, 85, 247 }, shortcut = { 255, 190, 40 }, pit = { 60, 200, 255 }, grid = { 235, 235, 235 }, selected = { 90, 255, 140 },
}
local BLIP_COLOUR = { normal = 27, shortcut = 5, pit = 3 }
local BLOCKED_CONTROLS = { 37, 44, 23, 20, 38, 14, 15, 16, 17, 241, 242, 172, 173, 174, 175 }

local function round2(v) return math.floor(v * 100 + 0.5) / 100 end

local function clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

local function pressed(control)
    return IsControlJustPressed(0, control) or IsDisabledControlJustPressed(0, control)
end

local function held(control)
    return IsControlPressed(0, control) or IsDisabledControlPressed(0, control)
end

-- Estado hacia la NUI -----------------------------------------------------------------------------

local function normalCount()
    local n = 0
    for _, cp in ipairs(C.draft.checkpoints) do
        if cp.kind == 'normal' then n = n + 1 end
    end
    return n
end

local function pushHud()
    SendNUIMessage({
        action = 'creator:hud',
        data = {
            locale = Config.Locale, kind = C.kind, source = C.source, radius = C.radius, height = C.height, checkpoints = #C.draft.checkpoints,
            normals = normalCount(), grid = #C.draft.grid, selected = C.sel, keys = Config.Creator.KeyLabels, name = C.draft.name,
            selectedKind = C.draft.checkpoints[C.sel] and C.draft.checkpoints[C.sel].kind or nil,
        },
    })
end

-- Blips del minimapa -------------------------------------------------------------------------------------

local function clearBlips()
    for _, b in ipairs(C.blips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    C.blips = {}
end

local function rebuildBlips()
    clearBlips()
    local seq = 0
    for _, cp in ipairs(C.draft.checkpoints) do
        local b = AddBlipForCoord(cp.x, cp.y, cp.z)
        SetBlipSprite(b, 1)
        SetBlipColour(b, BLIP_COLOUR[cp.kind] or 1)
        SetBlipScale(b, 0.8)
        SetBlipAsShortRange(b, false)
        if cp.kind == 'normal' then
            seq = seq + 1
            ShowNumberOnBlip(b, seq)
        end
        C.blips[#C.blips + 1] = b
    end
    C.dirty = false
end

-- Geometria ------------------------------------------------------------------------------------------------

local function aimPoint()
    local cam = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local z, x = math.rad(rot.z), math.rad(rot.x)
    local num = math.abs(math.cos(x))
    local dx, dy, dz = -math.sin(z) * num, math.cos(z) * num, math.sin(x)
    local dist = Config.Creator.raycastDistance
    local handle = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z, cam.x + dx * dist, cam.y + dy * dist, cam.z + dz * dist, 17, PlayerPedId(), 7)
    local _, hit, coords = GetShapeTestResult(handle)
    if hit == 1 or hit == true then return coords.x, coords.y, coords.z, rot.z end
    return nil
end

local function playerPoint()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local found, gz = GetGroundZFor_3dCoord(c.x, c.y, c.z, false)
    local veh = GetVehiclePedIsIn(ped, false)
    return c.x, c.y, found and gz or (c.z - 1.0), GetEntityHeading(veh ~= 0 and veh or ped)
end

local function target()
    if C.source == 'player' then return playerPoint() end
    return aimPoint()
end

local function text3d(x, y, z, str, scale)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.0, scale or 0.35)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextOutline()
    SetTextColour(255, 255, 255, 235)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(str)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Edicion -------------------------------------------------------------------------------------------------------

--- Ajusta los enlaces de los atajos cuando se inserta (+1) o elimina (-1) un checkpoint normal
local function shiftLinks(fromSeq, delta)
    for _, cp in ipairs(C.draft.checkpoints) do
        if cp.kind == 'shortcut' then
            if cp.linkFrom and cp.linkFrom >= fromSeq then cp.linkFrom = math.max(1, cp.linkFrom + delta) end
            if cp.linkTo and cp.linkTo >= fromSeq then cp.linkTo = math.max(2, cp.linkTo + delta) end
        end
    end
end

local function normalsBefore(index)
    local n = 0
    for i = 1, index - 1 do
        if C.draft.checkpoints[i].kind == 'normal' then n = n + 1 end
    end
    return n
end

local function place()
    local x, y, z, h = target()
    if not x then
        Notify(L('n_creator_nohit'), 'error', 2500)
        return
    end
    local d = C.draft
    if C.kind == 'grid' then
        if #d.grid >= Config.Creator.maxGrid then return Notify(L('n_creator_limit'), 'error', 2500) end
        d.grid[#d.grid + 1] = { x = round2(x), y = round2(y), z = round2(z + 0.5), h = round2(h % 360.0) }
    else
        local cps = d.checkpoints
        if #cps >= Config.Creator.maxCheckpoints then return Notify(L('n_creator_limit'), 'error', 2500) end
        local cp = { kind = C.kind, x = round2(x), y = round2(y), z = round2(z), radius = C.radius, height = C.height }
        local at = (C.sel > 0 and C.sel < #cps) and C.sel + 1 or #cps + 1
        if cp.kind == 'normal' then
            shiftLinks(normalsBefore(at) + 1, 1)
        elseif cp.kind == 'shortcut' then
            cp.linkFrom = math.max(1, normalsBefore(at))
            cp.linkTo = cp.linkFrom + 2
        end
        table.insert(cps, at, cp)
        C.sel = at
    end
    C.dirty = true
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    pushHud()
end

local function remove()
    local d = C.draft
    if C.kind == 'grid' then
        if #d.grid > 0 then table.remove(d.grid) end
    else
        local i = C.sel > 0 and C.sel or #d.checkpoints
        if i < 1 then return end
        local cp = table.remove(d.checkpoints, i)
        if cp.kind == 'normal' then shiftLinks(normalsBefore(i) + 2, -1) end
        C.sel = clamp(i - 1, 0, #d.checkpoints)
        if C.sel == 0 and #d.checkpoints > 0 then C.sel = 1 end
    end
    C.dirty = true
    pushHud()
end

local function moveSelected()
    local cp = C.draft.checkpoints[C.sel]
    if not cp then return end
    local x, y, z = target()
    if not x then return Notify(L('n_creator_nohit'), 'error', 2500) end
    cp.x, cp.y, cp.z = round2(x), round2(y), round2(z)
    C.dirty = true
    pushHud()
end

local function select(delta)
    local n = #C.draft.checkpoints
    if n == 0 then return end
    C.sel = ((C.sel - 1 + delta) % n) + 1
    -- El seleccionado adopta el radio y la altura actuales para ajustarlos con la rueda
    local cp = C.draft.checkpoints[C.sel]
    C.radius, C.height = cp.radius, cp.height
    pushHud()
end

local function adjust(direction)
    local cr = Config.Creator
    if held(cr.Keys.modifier) then
        C.height = clamp(C.height + direction * 1.0, cr.minHeight, cr.maxHeight)
    else
        C.radius = clamp(C.radius + direction * 1.0, cr.minRadius, cr.maxRadius)
    end
    local cp = C.kind ~= 'grid' and C.draft.checkpoints[C.sel] or nil
    if cp then cp.radius, cp.height = C.radius, C.height end
    pushHud()
end

-- Dibujo --------------------------------------------------------------------------------------------------------------

local function drawScene(px, py, pz)
    local cps = C.draft.checkpoints
    local seq = 0
    local prev
    for i, cp in ipairs(cps) do
        local col = (i == C.sel) and COLORS.selected or COLORS[cp.kind]
        local dx, dy = px - cp.x, py - cp.y
        if dx * dx + dy * dy < 90000.0 then
            DrawMarker(1, cp.x, cp.y, cp.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, cp.radius * 2.0, cp.radius * 2.0, cp.height, col[1], col[2], col[3], 110, false, false, 2, false, nil, nil, false)
            local label
            if cp.kind == 'normal' then
                label = tostring(seq + 1)
            elseif cp.kind == 'shortcut' then
                label = ('S %s>%s'):format(tostring(cp.linkFrom), tostring(cp.linkTo))
            else
                label = 'PIT'
            end
            text3d(cp.x, cp.y, cp.z + cp.height + 1.0, label, 0.5)
        end
        if cp.kind == 'normal' then
            seq = seq + 1
            if prev then DrawLine(prev.x, prev.y, prev.z + 1.0, cp.x, cp.y, cp.z + 1.0, 255, 255, 255, 200) end
            prev = cp
        end
    end

    local rad = math.rad
    for i, g in ipairs(C.draft.grid) do
        DrawMarker(25, g.x, g.y, g.z - 0.4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.2, 4.4, 1.0, COLORS.grid[1], COLORS.grid[2], COLORS.grid[3], 140, false, false, 2, false, nil, nil, false)
        local hx, hy = -math.sin(rad(g.h)), math.cos(rad(g.h))
        DrawLine(g.x, g.y, g.z, g.x + hx * 3.5, g.y + hy * 3.5, g.z, 255, 60, 60, 255)
        text3d(g.x, g.y, g.z + 1.2, 'P' .. i, 0.45)
    end
end

local function drawAim(x, y, z)
    local col = COLORS[C.kind] or COLORS.normal
    if C.kind == 'grid' then
        DrawMarker(25, x, y, z + 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.2, 4.4, 1.0, col[1], col[2], col[3], 90, false, false, 2, false, nil, nil, false)
    else
        DrawMarker(1, x, y, z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, C.radius * 2.0, C.radius * 2.0, C.height, col[1], col[2], col[3], 70, false, false, 2, false, nil, nil, false)
    end
end

-- Bucle (solo mientras el editor esta activo) ----------------------------------------------------------------------------

function Creator.Stop()
    if not C then return end
    C.active = false
    Creator.active = false
    clearBlips()
    SendNUIMessage({ action = 'creator:stop' })
end

--- Sale del editor y devuelve el borrador a la NUI
function Creator.Exit()
    if not C then return end
    local draft = C.draft
    Creator.Stop()
    C = nil
    UI.Open('admin', { tab = 'creator', draft = draft })
end

local function loop()
    local keys = Config.Creator.Keys
    while C and C.active do
        Wait(0)
        for _, control in ipairs(BLOCKED_CONTROLS) do DisableControlAction(0, control, true) end

        local ped = PlayerPedId()
        local pc = GetEntityCoords(ped)
        drawScene(pc.x, pc.y, pc.z)

        local ax, ay, az = target()
        if ax then drawAim(ax, ay, az) end

        if pressed(keys.place) then place() end
        if pressed(keys.remove) then remove() end
        if pressed(keys.prev) then select(-1) end
        if pressed(keys.next) then select(1) end
        if pressed(keys.move) then moveSelected() end
        if pressed(keys.source) then
            C.source = C.source == 'aim' and 'player' or 'aim'
            pushHud()
        end
        if pressed(keys.kind) then
            for i, k in ipairs(KINDS) do
                if k == C.kind then C.kind = KINDS[(i % #KINDS) + 1] break end
            end
            pushHud()
        end
        if pressed(keys.radiusUp) or pressed(keys.radiusUp2) then adjust(1) end
        if pressed(keys.radiusDown) or pressed(keys.radiusDown2) then adjust(-1) end
        if C.dirty then rebuildBlips() end
        if pressed(keys.finish) then
            Creator.Exit()
            return
        end
    end
end

-- Entrada desde la NUI ------------------------------------------------------------------------------------------------------

local function sanitizeDraft(data)
    local draft = type(data) == 'table' and data or {}
    local cps, grid = {}, {}
    for _, cp in ipairs(type(draft.checkpoints) == 'table' and draft.checkpoints or {}) do
        if type(cp) == 'table' and type(cp.x) == 'number' and type(cp.y) == 'number' and type(cp.z) == 'number' then
            cps[#cps + 1] = {
                kind = (cp.kind == 'shortcut' or cp.kind == 'pit') and cp.kind or 'normal', x = cp.x, y = cp.y, z = cp.z,
                radius = type(cp.radius) == 'number' and cp.radius or Config.Creator.defaultRadius,
                height = type(cp.height) == 'number' and cp.height or Config.Creator.defaultHeight,
                linkFrom = cp.linkFrom, linkTo = cp.linkTo,
            }
        end
    end
    for _, g in ipairs(type(draft.grid) == 'table' and draft.grid or {}) do
        if type(g) == 'table' and type(g.x) == 'number' and type(g.y) == 'number' and type(g.z) == 'number' then
            grid[#grid + 1] = { x = g.x, y = g.y, z = g.z, h = type(g.h) == 'number' and g.h or 0.0 }
        end
    end
    draft.checkpoints, draft.grid = cps, grid
    return draft
end

RegisterNUICallback('creatorEnter', function(data, cb)
    if C and C.active then return cb({ ok = false }) end
    if not UI.isOpen then return cb({ ok = false }) end
    local draft = sanitizeDraft(data)
    C = {
        active = true, draft = draft, kind = 'normal', source = 'aim', sel = #draft.checkpoints, dirty = true, blips = {},
        radius = Config.Creator.defaultRadius, height = Config.Creator.defaultHeight,
    }
    Creator.active = true
    UI.Close()
    SendNUIMessage({ action = 'creator:start' })
    pushHud()
    CreateThread(loop)
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Creator.Stop() end
end)
