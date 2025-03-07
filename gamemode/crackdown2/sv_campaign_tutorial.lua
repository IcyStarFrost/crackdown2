local random = math.random
util.AddNetworkString( "cd2net_introduction_music" )

net.Receive( "cd2net_starttutorial", function( len, ply )

    ply.cd2_InTutorial = true

    pcall( function()
        CD2:CreateThread( function()
            local spawns = CD2:GetPossibleSpawns()
            local spawn = spawns[ random( #spawns ) ]

            if player_manager.GetPlayerClass( ply ) == "cd2_spectator" then
                player_manager.SetPlayerClass( ply, "cd2_player" )
                ply:Spectate( OBS_MODE_NONE )
            end

            ply:SetLockonEnabled( false )
            ply:SetCanUseMelee( false )
            CD2.FreezeTime = game.SinglePlayer()
        
            ply:Spawn()
            ply:SetPos(  spawn:GetPos() or Vector( -996.168945, 2360.628906, 593.605408 ) )
            ply:SetAngles(  spawn:GetAngles() or Angle( 0, 90, 0 ) )
            ply:SetEyeAngles(  spawn:GetAngles() or Angle( 0, 90, 0 ) )

            ply:Freeze( true )
            ply.cd2_godmode = true
            
            coroutine.wait( 3 )
            if !IsValid( ply ) then return end

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag1.mp3" ) 

            coroutine.wait( 21 )
            if !IsValid( ply ) then return end

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag2.mp3" ) 

            coroutine.wait( 4.5 )

            ply:SendLua( "surface.PlaySound( 'crackdown2/ui/hudactivate.mp3' )")
            net.Start( "cd2net_tutorial_activatehud" )
            net.WriteString( "DrawHealthandShields" )
            net.Send( ply )

            coroutine.wait( 4.8 )

            ply:SendLua( "surface.PlaySound( 'crackdown2/ui/hudactivate.mp3' )")
            net.Start( "cd2net_tutorial_activatehud" )
            net.WriteString( "DrawMinimap" )
            net.Send( ply )

            coroutine.wait( 2.3 )

            ply:SendLua( "surface.PlaySound( 'crackdown2/ui/hudactivate.mp3' )")
            net.Start( "cd2net_tutorial_activatehud" )
            net.WriteString( "DrawTargetting" )
            net.Send( ply )

            net.Start( "cd2net_tutorial_activatehud" )
            net.WriteString( "DrawWeaponInfo" )
            net.Send( ply )

            coroutine.wait( 3 )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag2_finish.mp3" ) 

            coroutine.wait( 4 )

            local uptrace = ply:Trace( nil, ply:GetPos() + Vector( 0, 0, 1000 ) )
            local pos = uptrace.HitPos - Vector( 0, 0, 100 )

            ply:SetPos( pos )

            CD2:CreateThread( function()
                if !IsValid( ply ) then return end
        
                for i = 1, 100 do
                    if !IsValid( ply ) then return end
        
                    local trailer = ents.Create( "cd2_respawntrail" )
                    trailer:SetPos( ply:WorldSpaceCenter() + VectorRand( -150, 150 ) )
                    trailer:SetPlayer( ply )
                    trailer:Spawn()
        
                    coroutine.wait( 0.01 )
                end
            
            end )

            net.Start( "cd2net_playerspawnlight" )
            net.WriteEntity( ply )
            net.Broadcast()

            coroutine.wait( 0.5 )

            local timeout = CurTime() + 6

            while ply:IsOnGround() do if CurTime() > timeout then break end coroutine.yield() end 
            while !ply:IsOnGround() do if CurTime() > timeout then break end coroutine.yield() end

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

            CD2:SendTextBoxMessage( ply, "Run to the Agility Orb and collect it" )

            ply:Freeze( false )
            net.Start( "cd2net_tutorial_activatehud" )
            net.WriteString( "DrawAgilitySkill" )
            net.Send( ply )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag5.mp3" ) 

            local pos =  CD2:GetRandomPos( 3000, ply:GetPos() ) or Vector( -519.097351, 3134.323486, 349.921356 )
            
            local agilityorb = ents.Create( "cd2_agilityorb" )
            agilityorb:SetPos( pos )
            agilityorb:SetLevel( 1 )
            agilityorb:Spawn()

            local guide = CD2:CreateGuide( ply:GetPos(), agilityorb:GetPos() )

            coroutine.wait( 8 )

            while true do 
                if !IsValid( agilityorb ) or IsValid( agilityorb ) and agilityorb:IsCollectedBy( ply ) then break end
                coroutine.yield() 
            end

            if IsValid( agilityorb ) then agilityorb:Remove() end
            if IsValid( guide ) then guide:Remove() end

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag5_finish.mp3" ) 

            coroutine.wait( 7 ) 

            net.Start( "cd2net_tutorial_activatehud" )
            net.WriteString( "DrawFirearmSkill" )
            net.Send( ply )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag6.mp3" ) 

            pos =  CD2:GetRandomPos( 3000, ply:GetPos() ) or Vector( 2770.546875, 958.698730, 153.634186 )

            local guide = CD2:CreateGuide( ply:GetPos(), pos )

            local rifle = ents.Create( "cd2_assaultrifle" )
            rifle:SetPos( pos + Vector( 0, 0, 5 ) )
            rifle:SetPermanentDrop( true )
            rifle.cd2_reservedplayer = ply
            rifle:Spawn()

            CD2:SendTextBoxMessage( ply, "Follow the trail to the weapon provided" )

            while !IsValid( rifle:GetOwner() ) do coroutine.yield() end

            if IsValid( guide ) then guide:Remove() end

            coroutine.wait( 0.5 )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag7.mp3" ) 

            coroutine.wait( 14 )

            pos =  CD2:GetRandomPos( 500, ply:GetPos() ) or Vector( 2862.898682, 775.964539, 71.023209 )
            
            local guide = CD2:CreateGuide( ply:GetPos(), pos )

            local ent = ents.Create( "cd2_freak" )
            ent:SetPos( pos )
            ent:SetIsDisabled( true )
            ent.cd2_ShouldcheckPVS = false
            ent:Spawn()

            while IsValid( ent ) do coroutine.yield() end

            if IsValid( guide ) then guide:Remove() end

            coroutine.yield( 1 )
        
            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag8.mp3" ) 

            coroutine.wait( 5 )

            CD2:SendTextBoxMessage( ply, "Hold your secondary fire while looking at the freak to lock onto it. While locked on, move your mouse up to target the head and move your mouse back down to return to the body" )
            ply:SetLockonEnabled( true )

            local guide = CD2:CreateGuide( ply:GetPos(), pos )

            local ent = ents.Create( "cd2_freak" )
            ent:SetPos( pos )
            ent.cd2_ShouldcheckPVS = false
            ent:SetIsDisabled( true )
            ent:Spawn()

            while IsValid( ent ) do coroutine.yield() end

            if IsValid( guide ) then guide:Remove() end

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag9.mp3" ) 

            local trace = ply:Trace( ply:WorldSpaceCenter(), ply:GetPos() + ply:GetForward() * 400 ).HitPos

            local guide = CD2:CreateGuide( ply:GetPos(), pos or trace )

            local shotgun = ents.Create( "cd2_shotgun" )
            shotgun:SetPos( pos or trace )
            shotgun:SetPermanentDrop( true )
            shotgun.cd2_reservedplayer = ply
            shotgun:Spawn()

            while !IsValid( shotgun:GetOwner() ) do coroutine.yield() end

            CD2:SendTextBoxMessage( ply, "Move your mouse wheel to switch to your secondary" )

            if IsValid( guide ) then guide:Remove() end

            coroutine.wait( 1 )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag10.mp3" ) 

            coroutine.wait( 8 )
            local freaks = {}
            for i = 1, 4 do
                pos = CD2:GetRandomPos( 500, ply:GetPos() )
                local ent = ents.Create( "cd2_freak" )
                ent:SetPos( pos )
                ent:AttackTarget( ply )
                freaks[ #freaks + 1 ] = ent
                ent:Spawn()
            end

            CD2:SendTextBoxMessage( ply, "Kill all Freaks" )

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

            pos =  CD2:GetRandomPos( 3000, ply:GetPos() ) or Vector( 1939.180298, -800.069397, 126.819649 )

            local guide = CD2:CreateGuide( ply:GetPos(), pos )

            coroutine.wait( 3 )

            while ply:GetPos():DistToSqr( pos ) > ( 200 * 200 ) do coroutine.yield() end

            if IsValid( guide ) then guide:Remove() end

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag11.mp3" ) 

            net.Start( "cd2net_tutorial_activatehud" )
            net.WriteString( "DrawStrengthSkill" )
            net.Send( ply )

            coroutine.wait( 8 )

            ply:SetCanUseMelee( true )

            CD2:SendTextBoxMessage( ply, "Hold USE key and press your attack/fire button to melee" )

            pos = CD2:GetRandomPos( 500, ply:GetPos() )

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
                pos = CD2:GetRandomPos( 500, ply:GetPos() )
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

            ply:SetCanUseMelee( false )

            net.Start( "cd2net_tutorial_activatehud" )
            net.WriteString( "DrawExplosiveSkill" )
            net.Send( ply )


            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag13.mp3" )

            local trace = ply:Trace( ply:WorldSpaceCenter(), ply:GetPos() + ply:GetForward() * 400 ).HitPos

            local guide = CD2:CreateGuide( ply:GetPos(), pos or trace )

            local grenade = ents.Create( "cd2_grenade" )
            grenade:SetPos( pos or trace )
            grenade:SetPermanentDrop( true )
            grenade.cd2_reservedplayer = ply
            grenade:Spawn()
            
            while IsValid( grenade ) do coroutine.yield() end

            CD2:SendTextBoxMessage( ply, "Bind a key to +grenade1 and press that key to throw grenades. Example console command, bind g +grenade1" )

            if IsValid( guide ) then guide:Remove() end

            ply:SetEquipmentCount( 8 )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag14.mp3" )

            coroutine.wait( 8 )

            CD2:SendTextBoxMessage( ply, "Press your +grenade1 bind/key to throw a grenade" )

            local freaks = {}
            pos =  CD2:GetRandomPos( 500, ply:GetPos() ) or Vector( 1807.129517, -1427.410889, -35.290722 )
            
            for i = 1, 5 do
                local ent = ents.Create( "cd2_freak" )
                ent:SetPos( pos + Vector( random( -100, 100 ), random( -100, 100 ) ) )
                ent.cd2_ShouldcheckPVS = false
                ent:SetIsDisabled( true )
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

            coroutine.wait( 2 )

            ply:Freeze( true )
            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag15.mp3" )

            coroutine.wait( 13 )

            ply:SetNW2Bool( "cd2_inintroduction", true )

            net.Start( "cd2net_introduction_music" )
            net.Send( ply )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/diag16.mp3" )

            coroutine.wait( 3 )

            local cam = ents.Create( "cd2_introcam" )
            cam:SetPos( ply:GetPos() )
            cam:SetAngles( ply:GetAngles() )
            cam:SetPlayer( ply )
            cam:Spawn()

            if !GetGlobal2Bool( "cd2_MapDataLoaded", false ) then CD2:GenerateMapData( true ) end

            coroutine.wait( 3 )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/introduction.mp3" )

            coroutine.wait( 103 )

            if IsValid( cam ) then cam:Remove() end

            ply:SetNW2Bool( "cd2_inintroduction", false )

            ply.cd2_InTutorial = false

            net.Start( "cd2net_enablehud" )
            net.Send( ply )

            local locationpos = GetGlobal2Vector( "cd2_beginnerlocation" )
            local playerspawnpos = CD2:GetRandomPos( 2000, locationpos )
            local ang = ( locationpos - playerspawnpos ):Angle() ang[ 1 ] = 0 ang[ 3 ] = 0

            ply:SetLockonEnabled( true )
            ply:SetCanUseMelee( true )
            CD2.FreezeTime = false
        
            ply:StripAmmo()
            ply:StripWeapons()
            ply:Spawn()
            ply:SetPos( playerspawnpos )
            ply:SetAngles( ang )
            ply:SetEyeAngles( ang )

            ply.cd2_WeaponSpawnDelay = CurTime() + 0.5
            ply:SetEquipmentCount( scripted_ents.Get( "cd2_grenade" ).MaxGrenadeCount )
            ply:SetMaxEquipmentCount( scripted_ents.Get( "cd2_grenade" ).MaxGrenadeCount )
            ply:SetEquipment( "cd2_grenade" )
            ply:Give( "cd2_assaultrifle" )
            ply:Give( "cd2_shotgun" )

            ply:Freeze( true )
            ply.cd2_godmode = true

            coroutine.wait( 1 )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/intel1.mp3" )

            coroutine.wait( 4 )

            ply:SendLua( "OpenIntelConsole()" )
            ply:SendLua( "CD2_CanOpenAgencyConsole = false" )
            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/intel2.mp3" )

            coroutine.wait( 9 )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/intel3.mp3" )

            coroutine.wait( 9 )

            CD2:PingLocation( ply, nil, GetGlobal2Vector( "cd2_beginnerlocation" ), 3, nil, true )

            coroutine.wait( 9 )

            ply:SendLua( "CD2_CanOpenAgencyConsole = true" )
            ply:SendLua( "OpenIntelConsole()" )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/firsttactical.mp3" )

            coroutine.wait( 5 )

            CD2:WritePlayerData( ply, "c_completedtutorial", 3, nil, true )

            ply:Freeze( false )
            ply.cd2_godmode = false

            CD2:PingLocation( ply, nil, GetGlobal2Vector( "cd2_beginnerlocation" ), 3 )

            while !CD2.BeginnerLocation:GetIsActive() do coroutine.yield() end

            coroutine.wait( 5 )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/usehud.mp3" )

            while CD2.BeginnerLocation:GetLocationType() == "cell" do coroutine.yield() end 

            local wait = true

            CD2:RequestPlayerData( ply, "cd2_firsttacticallocation", function( val ) 

                if !val then
                    ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/firsttacticallocation_achieve.mp3" )
                    CD2:WritePlayerData( ply, "cd2_firsttacticallocation", true )
                    timer.Simple( 6, function() wait = false end )
                else
                    wait = false
                end
                
            end )

            while wait do coroutine.yield() end 

            coroutine.wait( 10 )

            local aupos
            
            while true do 
                local near = CD2:FindInSphere( ply:GetPos(), 3000, function( ent ) return ent:GetClass() == "cd2_au" end )

                if #near > 0 then
                    local au = CD2:GetClosestInTable( near, ply )
                    aupos = au:GetPos()
                    break
                end
                coroutine.wait( 1 )
            end
            
            ply:Freeze( true )
            ply.cd2_godmode = true 
            
            ply:SendLua( "OpenIntelConsole()" )
            ply:SendLua( "CD2_CanOpenAgencyConsole = false" )
            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/au1.mp3" )

            coroutine.wait( 13 )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/au2.mp3" )

            coroutine.wait( 8 )

            CD2:PingLocation( ply, nil, aupos, 3, nil, true )

            coroutine.wait( 7 )

            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/au3.mp3" )

            coroutine.wait( 8 )

            ply:SendLua( "CD2_CanOpenAgencyConsole = true" )
            ply:SendLua( "OpenIntelConsole()" )

            ply:Freeze( false )
            ply.cd2_godmode = false

        end )
    end )
    
end )
