-- Desactivar el rastreador desde dentro del vehículo
local function disableTracker()
    local contract = Boosting.contract
    if not contract or not contract.tracker or Boosting.hacking then return end

    local result = Boosting.Call('disableTracker')
    if not result then return end

    if not result.ok then
        Boosting.Notify(result.message, 'error')
    elseif result.needHack then
        Boosting.StartHack('tracker')
    end
end

lib.addKeybind({
    name = 'jj_boosting_tracker',
    description = 'Boosting: desactivar el rastreador',
    defaultKey = Config.Tracker.key,
    onPressed = disableTracker,
})
