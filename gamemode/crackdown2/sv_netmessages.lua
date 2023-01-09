
-- Received when a player finishes picking new weapons or refreshing their old weapons in a Agency Tactical Location
net.Receive( "cd2net_resupply", function( len, ply )
    local primary = net.ReadString()
    local secondary = net.ReadString()
    local equipment = net.ReadString()

    ply.cd2_WeaponSpawnDelay = CurTime() + 0.5
    ply:StripWeapons()
    ply:SetEquipmentCount( scripted_ents.Get( equipment ).MaxGrenadeCount )
    ply:SetMaxEquipmentCount( scripted_ents.Get( equipment ).MaxGrenadeCount )
    ply:SetEquipment( equipment )
    ply:Give( primary )
    ply:Give( secondary )
end )


-- Received when a dead player calls for help. Multiplayer only
net.Receive( "cd2net_playercallforhelp", function( len, ply ) 

    for k, v in ipairs( player.GetAll() ) do
        if v == ply then continue end
        net.Start( "cd2net_pingsounds" )
        net.WriteUInt( 3, 4 )
        net.Send( v )
        CD2SendTextBoxMessage( v, ply:Name() .. " needs to be revived!" )
    end
end )

local IsGenerating = false
net.Receive( "cd2net_generatenavmesh", function( len, ply )
    if IsGenerating then return end

    ply:ConCommand( "nav_max_view_distance 1" )
    ply:ConCommand( "nav_generate" )

    IsGenerating = true
end )

local oldtime = CD2_FreezeTime
net.Receive( "cd2net_playeropenintelconsole", function( len, ply )
    if !game.SinglePlayer() then return end
    local isopened = net.ReadBool()

    if isopened then
        oldtime = CD2_FreezeTime
        CD2_FreezeTime = true
        CD2_DisableAllAI = true
    else
        CD2_FreezeTime = oldtime
        CD2_DisableAllAI = false
    end
    
    
end )