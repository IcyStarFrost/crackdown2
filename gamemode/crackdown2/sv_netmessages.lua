
net.Receive( "cd2net_playerdropmenuconfirm", function( len, ply )
    local primary = net.ReadString()
    local secondary = net.ReadString()
    local equipment = net.ReadString()
    local spawnposition = net.ReadVector()
    local spawnangles = net.ReadAngle()

    if player_manager.GetPlayerClass( ply ) == "cd2_spectator" then
        player_manager.SetPlayerClass( ply, "cd2_player" )
        ply:Spectate( OBS_MODE_NONE )
        CD2SetUpPlayer( ply )
    end

    --ply.cd2_spawnatposition = spawnposition
    ply:Spawn()
    ply:SetPos( spawnposition )
    ply:SetAngles( spawnangles )
    ply:SetEyeAngles( spawnangles )
    ply:Give( primary )
    ply:Give( secondary )

    ply.cd2_Equipment = equipment
    ply:SetEquipmentCount( scripted_ents.Get( equipment ).MaxGrenadeCount )
    ply.cd2_lastspawnprimary = primary
    ply.cd2_lastspawnsecondary = secondary
end )

net.Receive( "cd2net_spawnatnearestspawn", function( len, ply )
    local primary = net.ReadString()
    local secondary = net.ReadString()
    local equipment = net.ReadString()

    if player_manager.GetPlayerClass( ply ) == "cd2_spectator" then
        player_manager.SetPlayerClass( ply, "cd2_player" )
        ply:Spectate( OBS_MODE_NONE )
        CD2SetUpPlayer( ply )
    end

    ply.cd2_spawnatnearestspawn = true
    ply:Spawn()
    ply:Give( primary )
    ply:Give( secondary )

    ply:SetEquipmentCount( scripted_ents.Get( equipment ).MaxGrenadeCount )
    ply.cd2_lastspawnprimary = primary
    ply.cd2_lastspawnsecondary = secondary
end )

net.Receive( "cd2net_reviveplayer", function( len, ply ) 
    local agent = net.ReadEntity()
    if agent:Alive() or !agent:GetCanRevive() then return end

    agent:Spawn()
    agent:SetPos( ply:GetPos() + ply:GetForward() * 60 )
    agent:Give( agent.cd2_lastspawnprimary )
    agent:Give( agent.cd2_lastspawnsecondary )
end )

net.Receive( "cd2net_playerregenerate", function( len, ply )
    if !ply:IsCD2Agent() then return end
    ply:SetCanRevive( false )
end )