local plycolor = Vector( 1, 1, 1 )
local random = math.random

-- Set the player's class
hook.Add( "PlayerSpawn", "crackdown2_setplayerclass", function( ply )
    if !ply.cd2_firsttimespawn then ply.cd2_firsttimespawn = true return end
    player_manager.SetPlayerClass( ply, "cd2_player" )
    ply:SetPlayerColor( plycolor )
end )

hook.Add( "PlayerInitialSpawn", "crackdown2_setplayerclass", function( ply )
    player_manager.SetPlayerClass( ply, "cd2_spectator" )
    ply:SetPlayerColor( plycolor )

    local vecs = {}
    for k, v in ipairs( CD2GetPossibleSpawns() ) do vecs[ #vecs + 1 ] = { v:GetPos(), v:GetAngles() } end

    net.Start( "cd2net_sendspawnvectors" )
    net.WriteString( util.TableToJSON( vecs ) )
    net.Send( ply )
end )
--

hook.Add( "PlayerSelectSpawn", "crackdown2_selectnearestspawn", function( ply )
    if !ply:IsCD2Agent() then return end

    if ply.cd2_spawnatnearestspawn then
        local near = CD2GetClosestSpawn( ply )
        ply.cd2_spawnatnearestspawn = false
        return near
    end

end )


-- Received when a player finishes picking weapons in the Drop Menu
net.Receive( "cd2net_playerdropmenuconfirm", function( len, ply )
    local primary = net.ReadString() -- The primary weapon the player chose
    local secondary = net.ReadString() -- The secondary weapon the player chose
    local equipment = net.ReadString() -- The equipment the player chose
    local spawnposition = net.ReadVector() -- The selected spawn pos
    local spawnangles = net.ReadAngle() -- Spawn point angles

    -- Typically players that spawned for the first time will be in the spectator class.
    -- We set them to Agents so they can play
    if player_manager.GetPlayerClass( ply ) == "cd2_spectator" then
        player_manager.SetPlayerClass( ply, "cd2_player" )
        ply:Spectate( OBS_MODE_NONE )
        if !KeysToTheCity() then ply:LoadProgress() end -- Load their progress
    end

    --ply.cd2_spawnatposition = spawnposition
    ply.cd2_WeaponSpawnDelay = CurTime() + 0.5 -- Disables the custom weapon pickup for a bit so we can force give these weapons
    ply:Spawn()
    ply:SetPos( spawnposition )
    ply:SetAngles( spawnangles )
    ply:SetEyeAngles( spawnangles )
    ply:Give( primary )
    ply:Give( secondary )

    ply:SetEquipment( equipment )
    ply:SetEquipmentCount( scripted_ents.Get( equipment ).MaxGrenadeCount )
    ply:SetMaxEquipmentCount( scripted_ents.Get( equipment ).MaxGrenadeCount )
    ply.cd2_lastspawnprimary = primary
    ply.cd2_lastspawnsecondary = secondary
end )


-- Received when a player presses the IN_RELOAD key when dead to spawn them at the nearest spawn point
net.Receive( "cd2net_spawnatnearestspawn", function( len, ply )
    local primary = net.ReadString() -- The primary weapon the player originally had
    local secondary = net.ReadString() -- The secondary weapon the player originally had
    local equipment = net.ReadString() -- The equipment the player originally had

    CD2CreateThread( function()
        if !game.SinglePlayer() and ply.cd2_deathweapons then
            local weps = ply.cd2_deathweapons
            local ragdoll = ply:GetRagdollEntity()
            local pos = IsValid( ragdoll ) and ragdoll:GetPos() or ply:GetPos()
            for i = 1, #weps do
                
                local class = weps[ i ][ 1 ]
                local reserve = weps[ i ][ 2 ]

                local wep = ents.Create( class ) 
                wep:SetPos( pos + Vector( 0, 0, 20 ) )
                wep:Spawn()
                wep.cd2_Ammocount = reserve

                local phys = wep:GetPhysicsObject()

                if IsValid( phys ) then
                    phys:ApplyForceCenter( Vector( random( -600, 600 ), random( -600, 600 ), random( 0, 600 ) ) )
                end
                coroutine.yield()
            end

            local equipment = ents.Create( ply.cd2_deathequipment )
            equipment:SetPos( pos + Vector( 0, 0, 20 ) )
            equipment:Spawn()

            local phys = equipment:GetPhysicsObject()

            if IsValid( phys ) then
                phys:ApplyForceCenter( Vector( random( -8000, 8000 ), random( -8000, 8000 ), random( 0, 8000 ) ) )
            end

        end

        if player_manager.GetPlayerClass( ply ) == "cd2_spectator" then
            player_manager.SetPlayerClass( ply, "cd2_player" )
            ply:Spectate( OBS_MODE_NONE )
            if !KeysToTheCity() then ply:LoadProgress() end
        end

        ply.cd2_WeaponSpawnDelay = CurTime() + 0.5
        ply.cd2_spawnatnearestspawn = true
        ply:Spawn()
        ply:Give( primary )
        ply:Give( secondary )

        ply:SetEquipmentCount( scripted_ents.Get( equipment ).MaxGrenadeCount )
        ply:SetMaxEquipmentCount( scripted_ents.Get( equipment ).MaxGrenadeCount )
        ply:SetEquipment( equipment )
        ply.cd2_lastspawnprimary = primary
        ply.cd2_lastspawnsecondary = secondary
    end )
end )


-- Received when a Player revives another Player
-- ply = Reviving player
-- agent = Originally dead player
net.Receive( "cd2net_reviveplayer", function( len, ply ) 
    local agent = net.ReadEntity()
    if agent:Alive() or !agent:GetCanRevive() then return end

    agent.cd2_revived = true
    agent.cd2_WeaponSpawnDelay = CurTime() + 0.5

    agent:Spawn()
    agent:SetPos( ply:GetPos() + ply:GetForward() * 60 + Vector( 0, 0, 5 ) )
    agent:EmitSound( "crackdown2/ply/revived.mp3", 80 )

    agent:SetNoDraw( true )
    agent:Freeze( true )
    agent.cd2_godmode = true

    local riseent = ents.Create( "cd2_riseent" )
    riseent:SetPos( agent:GetPos() )
    riseent:SetAngles( Angle( 0, agent:EyeAngles()[ 2 ], 0 ) )
    riseent:SetParent( agent )
    riseent:SetPlayer( agent )
    riseent:Spawn()
    riseent.Callback = function( self )
        agent:SetNoDraw( false )
        agent:Freeze( false )
        agent.cd2_godmode = false
    end

    local primary = agent:Give( agent.cd2_lastspawnprimary )
    local secondary = agent:Give( agent.cd2_lastspawnsecondary )

    local weps = agent.cd2_deathweapons
    for i = 1, #weps do
        local class = weps[ i ][ 1 ]
        local reserve = weps[ i ][ 2 ]

        if class == primary:GetClass() then
            agent:SetAmmo( reserve, primary.Primary.Ammo )
        elseif class == secondary:GetClass() then
            agent:SetAmmo( reserve, secondary.Primary.Ammo )
        end
    end

end )


-- Received when a player presses their IN_USE key when dead and enters the spawn point menu.
-- This will stop the player from being able to be revived and if in multiplayer, drops all their weapons
local random = math.random
net.Receive( "cd2net_playerregenerate", function( len, ply )
    if !ply:IsCD2Agent() then return end
    ply:SetCanRevive( false )

    if !game.SinglePlayer() and ply.cd2_deathweapons then
        local weps = ply.cd2_deathweapons
        local ragdoll = ply:GetRagdollEntity()
        for i = 1, #weps do
            
            local class = weps[ i ][ 1 ]
            local reserve = weps[ i ][ 2 ]

            local wep = ents.Create( class ) 
            wep:SetPos( ragdoll:GetPos() + Vector( 0, 0, 20 ) )
            wep:Spawn()
            wep.cd2_Ammocount = reserve

            local phys = wep:GetPhysicsObject()

            if IsValid( phys ) then
                phys:ApplyForceCenter( Vector( random( -600, 600 ), random( -600, 600 ), random( 0, 600 ) ) )
            end
        end

        local equipment = ents.Create( ply.cd2_deathequipment )
        equipment:SetPos( ragdoll:GetPos() + Vector( 0, 0, 20 ) )
        equipment:Spawn()

        local phys = equipment:GetPhysicsObject()

        if IsValid( phys ) then
            phys:ApplyForceCenter( Vector( random( -8000, 8000 ), random( -8000, 8000 ), random( 0, 8000 ) ) )
        end

    end
end )