
-- Received when a player finishes picking new weapons or refreshing their old weapons in a Agency Tactical Location
net.Receive( "cd2net_resupply", function( len, ply )
    local primary = net.ReadString()
    local secondary = net.ReadString()
    local equipment = net.ReadString()

    ply.cd2_WeaponSpawnDelay = CurTime() + 0.5
    ply:StripWeapons()
    ply:SetEquipmentCount( scripted_ents.Get( equipment ).MaxGrenadeCount )
    ply:SetMaxEquipmentCount( scripted_ents.Get( equipment ).MaxGrenadeCount )
    ply.cd2_Equipment = equipment
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