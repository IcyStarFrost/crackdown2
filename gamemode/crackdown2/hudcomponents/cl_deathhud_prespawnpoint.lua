function CD2.HUDCOMPONENENTS.components.DeathHud( ply, scrw, scrh, hudscale )
    if !ply:Alive() and !CD2.InSpawnPointMenu then 

        CD2:DrawInputBar( scrw / 2.1, 200, KEY_R, "Regenerate" )
        CD2:DrawInputBar( scrw / 2, 250, KEY_E, "Regenerate at nearest spawn" )

        if #player.GetAll() > 1 then
            CD2:DrawInputBar( scrw / 1.9, 300, KEY_W, "Hold to call for help" )
        end

        return 
    end
end