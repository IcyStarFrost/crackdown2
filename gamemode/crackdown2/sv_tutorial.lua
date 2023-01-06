local random = math.random


net.Receive( "cd2net_starttutorial", function( len, ply )

    ply.cd2_InTutorial = true

    CD2CreateThread( function()
        local spawns = CD2GetPossibleSpawns()
        local spawn = spawns[ random( #spawns ) ]

        if player_manager.GetPlayerClass( ply ) == "cd2_spectator" then
            player_manager.SetPlayerClass( ply, "cd2_player" )
            ply:Spectate( OBS_MODE_NONE )
        end

        ply:SetCanUseLockon( false )
        ply:SetCanUseMelee( false )
        CD2_FreezeTime = game.SinglePlayer()
    
        ply:Spawn()
        ply:SetPos( spawn:GetPos() )
        ply:SetAngles( spawn:GetAngles() )
        ply:SetEyeAngles( spawn:GetAngles() )

        ply:Freeze( true )
        ply.cd2_godmode = true
        
        coroutine.wait( 3 )

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag1.mp3" ) 

        coroutine.wait( 21 )

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag2.mp3" ) 

        coroutine.wait( 4.5 )

        net.Start( "cd2net_tutorial_activatehud" )
        net.WriteString( "CD2_DrawHealthandShields" )
        net.Send( ply )

        coroutine.wait( 4.8 )

        net.Start( "cd2net_tutorial_activatehud" )
        net.WriteString( "CD2_DrawMinimap" )
        net.Send( ply )

        coroutine.wait( 2.3 )

        net.Start( "cd2net_tutorial_activatehud" )
        net.WriteString( "CD2_DrawTargetting" )
        net.Send( ply )

        net.Start( "cd2net_tutorial_activatehud" )
        net.WriteString( "CD2_DrawWeaponInfo" )
        net.Send( ply )

        coroutine.wait( 3 )

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag2_finish.mp3" ) 

        coroutine.wait( 4 )

        local uptrace = ply:Trace( nil, ply:GetPos() + Vector( 0, 0, 1000 ) )
        local pos = uptrace.HitPos - Vector( 0, 0, 100 )

        ply:SetPos( pos )

        net.Start( "cd2net_playerspawnlight" )
        net.WriteEntity( ply )
        net.Broadcast()

        coroutine.wait( 0.5 )

        while !ply:IsOnGround() do coroutine.yield() end

        ply:SetHealth( 30 )
        ply:SetArmor( 0 )

        net.Start( "cd2net_playerlandingdecal" )
        net.WriteVector( ply:WorldSpaceCenter() )
        net.WriteBool( true  )
        net.Broadcast()

        sound.Play( "crackdown2/ply/hardland" .. random( 1, 2 ) .. ".wav", ply:GetPos(), 65, 100, 1 )

        ply.cd2_NextRegenTime = CurTime() + 4

        coroutine.wait( 1 )

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag4.mp3" ) 

        coroutine.wait( 14 ) 

        CD2SendTextBoxMessage( ply, "Run to the Agility Orb and collect it" )

        ply:Freeze( false )

        net.Start( "cd2net_tutorial_activatehud" )
        net.WriteString( "CD2_DrawAgilitySkill" )
        net.Send( ply )

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag5.mp3" ) 

        local pos = CD2GetRandomPos( 1000, ply:GetPos() )

        local agilityorb = ents.Create( "cd2_agilityorb" )
        agilityorb:SetPos( pos )
        agilityorb:SetLevel( 1 )
        agilityorb:Spawn()

        local guide = CD2CreateGuide( ply:GetPos(), agilityorb:GetPos() )

        coroutine.wait( 8 )

        while IsValid( agilityorb ) or IsValid( agilityorb ) and !agilityorb:IsCollectedBy( ply ) do coroutine.yield() end

        if IsValid( agilityorb ) then agilityorb:Remove() end
        if IsValid( guide ) then guide:Remove() end

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag5_finish.mp3" ) 

        coroutine.wait( 7 ) 

        net.Start( "cd2net_tutorial_activatehud" )
        net.WriteString( "CD2_DrawFirearmSkill" )
        net.Send( ply )

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag6.mp3" ) 

        pos = CD2GetRandomPos( 2000, ply:GetPos() )

        local guide = CD2CreateGuide( ply:GetPos(), pos )

        local rifle = ents.Create( "cd2_assaultrifle" )
        rifle:SetPos( pos + Vector( 0, 0, 5 ) )
        rifle:SetPermanentDrop( true )
        rifle.cd2_reservedplayer = ply
        rifle:Spawn()

        while !IsValid( rifle:GetOwner() ) do coroutine.yield() end

        if IsValid( guide ) then guide:Remove() end

        coroutine.wait( 0.5 )

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag7.mp3" ) 

        coroutine.wait( 14 )

        pos = CD2GetRandomPos( 500, ply:GetPos() )

        local guide = CD2CreateGuide( ply:GetPos(), pos )

        local ent = ents.Create( "cd2_freak" )
        ent:SetPos( pos )
        ent:SetIsDisabled( true )
        ent:Spawn()

        while IsValid( ent ) do coroutine.yield() end

        if IsValid( guide ) then guide:Remove() end

        coroutine.yield( 1 )
    
        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag8.mp3" ) 

        coroutine.wait( 5 )

        CD2SendTextBoxMessage( ply, "Hold your secondary fire while looking at the freak to lock onto it. While locked on, move your mouse up to target the head and move your mouse back down to return to the body" )
        ply:SetCanUseLockon( true )

        local guide = CD2CreateGuide( ply:GetPos(), pos )

        local ent = ents.Create( "cd2_freak" )
        ent:SetPos( pos )
        ent:SetIsDisabled( true )
        ent:Spawn()

        while IsValid( ent ) do coroutine.yield() end

        if IsValid( guide ) then guide:Remove() end

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag9.mp3" ) 

        local trace = ply:Trace( ply:WorldSpaceCenter(), ply:GetPos() + ply:GetForward() * 400 ).HitPos

        local guide = CD2CreateGuide( ply:GetPos(), trace )

        local shotgun = ents.Create( "cd2_shotgun" )
        shotgun:SetPos( trace )
        shotgun:SetPermanentDrop( true )
        shotgun.cd2_reservedplayer = ply
        shotgun:Spawn()

        while !IsValid( shotgun:GetOwner() ) do coroutine.yield() end

        if IsValid( guide ) then guide:Remove() end

        coroutine.wait( 1 )

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag10.mp3" ) 

        coroutine.wait( 10 )
        local freaks = {}
        for i = 1, 4 do
            pos = CD2GetRandomPos( 500, ply:GetPos() )
            local ent = ents.Create( "cd2_freak" )
            ent:SetPos( pos )
            ent:AttackTarget( ply )
            freaks[ #freaks + 1 ] = ent
            ent:Spawn()
        end

        while true do
            local shouldbreak = true
            for i = 1, #freaks do
                local freak = freaks[ i ]
                if IsValid( freak ) then shouldbreak = false end 
            end
            if shouldbreak then break end
            coroutine.wait( 0.2 )
        end

        coroutine.wait( 0.5 )

        ply:StripAmmo()

        local weps = ply:GetWeapons()
        for i = 1, #weps do
            local wep = weps[ i ]
            wep:SetClip1( 0 )
        end

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag10_finish.mp3" ) 

        pos = CD2GetRandomPos( 3000, ply:GetPos() )

        local guide = CD2CreateGuide( ply:GetPos(), pos )

        coroutine.wait( 3 )

        while ply:GetPos():DistToSqr( pos ) > ( 200 * 200 ) do coroutine.yield() end

        if IsValid( guide ) then guide:Remove() end

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag11.mp3" ) 

        net.Start( "cd2net_tutorial_activatehud" )
        net.WriteString( "CD2_DrawStrengthSkill" )
        net.Send( ply )

        coroutine.wait( 8 )

        ply:SetCanUseMelee( true )

        CD2SendTextBoxMessage( ply, "Hold USE key and press your attack/fire button to melee" )

        pos = CD2GetRandomPos( 500, ply:GetPos() )
        local ent = ents.Create( "cd2_freak" )
        ent:SetPos( pos )
        ent:AttackTarget( ply )
        ent:Spawn()

        while IsValid( ent ) do coroutine.yield() end

        coroutine.wait( 0.5 )

        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag12.mp3" )

        coroutine.wait( 14 )

        local freaks = {}
        for i = 1, 7 do
            pos = CD2GetRandomPos( 500, ply:GetPos() )
            local ent = ents.Create( "cd2_freak" )
            ent:SetPos( pos )
            ent:AttackTarget( ply )
            freaks[ #freaks + 1 ] = ent
            ent:Spawn()
        end

        while true do
            local shouldbreak = true
            for i = 1, #freaks do
                local freak = freaks[ i ]
                if IsValid( freak ) then shouldbreak = false end 
            end
            if shouldbreak then break end
            coroutine.wait( 0.2 )
        end

        coroutine.wait( 1 )

        net.Start( "cd2net_tutorial_activatehud" )
        net.WriteString( "CD2_DrawExplosiveSkill" )
        net.Send( ply )


        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag13.mp3" )

        local trace = ply:Trace( ply:WorldSpaceCenter(), ply:GetPos() + ply:GetForward() * 400 ).HitPos

        local guide = CD2CreateGuide( ply:GetPos(), trace )

        local grenade = ents.Create( "cd2_grenade" )
        grenade:SetPos( trace )
        grenade:SetPermanentDrop( true )
        grenade.cd2_reservedplayer = ply
        grenade:Spawn()

    end )

end )
