RegisterCommand("cross", function(source, args, raw)
    if not IsEntityPlayingAnim(PlayerPedId(), "amb@world_human_hang_out_street@male_c@idle_a", "idle_b", 3) then
        ExecuteCommand("e crossarms2")
    else
        ExecuteCommand("e c")
    end
end, false)

RegisterKeyMapping('cross', 'Cruzar brazos', 'keyboard', 'G')
