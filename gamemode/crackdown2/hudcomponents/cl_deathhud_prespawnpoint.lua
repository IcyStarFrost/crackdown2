function CD2.HUDCOMPONENENTS.components.DeathHud( ply, scrw, scrh, hudscale )
    if !ply:Alive() and !CD2.InSpawnPointMenu then 

        CD2:DrawInputBar( scrw / 2.1, 200, KEY_E, "Regenerate" )
        CD2:DrawInputBar( scrw / 2, 250, KEY_R, "Regenerate at nearest spawn" )

        if #player.GetAll() > 1 then
            CD2:DrawInputBar( scrw / 1.9, 300, KEY_W, "Hold to call for help" )
        end

        return 
    end
end

hook.Add( "CD2_ButtonPressed", "crackdown2_regeneratemenu", function( ply, button )
    if CD2.InDropMenu or CD2.InSpawnPointMenu or ply:Alive() then return end

    if button == KEY_E then
        if !CD2.InSpawnPointMenu then
            CD2:OpenSpawnPointMenu()

            if !CD2:KeysToTheCity() then
                local directorcommented = CD2:ReadPlayerData( "cd2_director_dead" )

                if !directorcommented then
                    sound.PlayFile( "sound/crackdown2/vo/agencydirector/regenerate.mp3", "noplay", function( snd, id, name ) snd:SetVolume( 10 ) snd:Play() end )
                    CD2:WritePlayerData( "cd2_director_dead", true )
                end
            end
        end
    elseif button == KEY_R then
        net.Start( "cd2net_spawnatnearestspawn" )
        net.WriteString( CD2.DropPrimary )
        net.WriteString( CD2.DropSecondary )
        net.WriteString( CD2.DropEquipment )
        net.SendToServer()
    end

    -- Call for help --
    if button == KEY_W and !game.SinglePlayer() and ( !ply.cd2_callforhelpcooldown or CurTime() > ply.cd2_callforhelpcooldown ) then
        net.Start( "cd2net_playercallforhelp" )
        net.SendToServer()
        CD2SetTextBoxText( "Call for help has been sent to other Agents" )

        ply.cd2_callforhelpcooldown = CurTime() + 10
    end

end )