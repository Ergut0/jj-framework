local ragdoll = false

local function Ragdoll()
  if cache.vehicle then return end

  ragdoll = not ragdoll

  CreateThread(function()
    while ragdoll do
      Citizen.Wait(0)
      if LocalPlayer.state.isDead or LocalPlayer.state.isLastStand or LocalPlayer.state.checkingIn then
        ragdoll = false
        return
      end
      if ragdoll then
        SetPedToRagdoll(cache.ped, 1000, 1000, 0, 0, 0, 0)
      end
    end
  end)
end


RegisterCommand("suelo", function(source, args, raw)
  Ragdoll()
end, false)

RegisterKeyMapping("suelo", "Tirarse al suelo", "keyboard", "H")
