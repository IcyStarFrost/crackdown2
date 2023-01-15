
hook.Add( "CD2_BeaconDetonate", "crackdown2_beaconsequence", function( beacon )
    local beaconid = beacon.cd2_AUgroup
    local tbl = CD2_BeaconData[ beaconid + 1 ]
    CD2CreateBeaconSet( tbl )
end )


function CD2CreateBeaconSet( beacondata )
    if !beacondata then return end

    local AUs = beacondata.AUs

    for i = 1, #AUs do
        local audata = AUs[ i ]
        local aumapID = audata.id
        local groupID = beacondata.AUID


        local au = ents.Create( "cd2_au" )
        au:SetPos( audata.aupos ) 

        au.cd2_map_isgenerated = true
        au.cd2_map_id = aumapID

        au:SetAUGroupID( groupID )
        au:SetBeamPos( beacondata.beaconspawnpos + Vector( 0, 0, 120 ) )
        au:Spawn()
    end

    local id = tostring( beacondata )

    hook.Add( "CD2_PowerNetworkComplete", "crackdown2_networkwatcher" .. id, function( group )
        if group != beacondata.AUID then return end
        CD2DebugMessage( "AU Group " .. group .. " power network has been completed!" )
        hook.Remove( "CD2_PowerNetworkComplete", "crackdown2_networkwatcher" .. id )

        local marker = ents.Create( "cd2_locationmarker" )
        marker:SetPos( beacondata.pos ) 
        marker:SetLocationType( "beacon" )
        marker.cd2_AUgroup = beacondata.AUID
    
        function marker:OnActivate( ply ) 
            local sndtracks = { "sound/crackdown2/music/beacon/ptb.mp3", "sound/crackdown2/music/beacon/industrialfreaks.mp3" }
            sound.Play( "crackdown2/ambient/tacticallocationactivate.mp3", self:GetPos(), 100, 100, 1 )

            CD2DebugMessage( self, "A Beacon for AUGroup " .. beacondata.AUID .. " has been called by " .. ply:Name() )
    
            marker.cd2_beacon = ents.Create( "cd2_beacon" )
            marker.cd2_beacon:SetPos( beacondata.beaconspawnpos )
            
            marker.cd2_beacon.cd2_map_isgenerated = true
            marker.cd2_beacon.cd2_map_id = beacondata.id
            marker.cd2_beacon.cd2_AUgroup = beacondata.AUID
    
            marker.cd2_beacon:SetSoundTrack( sndtracks[ math.random( #sndtracks ) ] )
    
            marker.cd2_beacon:Spawn()
    
            timer.Simple( 0.1, function() marker.cd2_beacon:DropBeacon() end )
        end
    
        marker:Spawn()

        CD2DebugMessage( marker, "Created Beacon Marker for AU Group " .. group )
    
        CD2CreateThread( function()
            while true do 
                if !IsValid( marker ) then break end
    
                marker:SetIsActive( IsValid( marker.cd2_beacon ) )
                marker:SetNoDraw( IsValid( marker.cd2_beacon ) )
    
                if IsValid( marker.cd2_beacon ) then
    
                    if marker.cd2_beacon:GetIsDetonated() then
                        marker:Remove()
    
                        local activecount = ents.FindByClass( "cd2_beacon" )
                        local count = 0 
                        for i = 1, #activecount do
                            local beacon = activecount[ i ]
                            if IsValid( beacon ) and beacon:GetIsDetonated() then count = count + 1 end
                        end
    
                        CD2_CurrentBeacon = group + 1
                        if !KeysToTheCity() then CD2FILESYSTEM:WriteMapData( "cd2_map_currentbeacon", group + 1 ) end
    
                        coroutine.wait( 7 )

                        if !KeysToTheCity() and count == CD2_BeaconCount then
                            for k, v in ipairs( player.GetAll() ) do
                                v:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/allbeacons_achieve.mp3" )
                            end
                        end
    
                        CD2SetTypingText( nil, "OBJECTIVE COMPLETE!", "Beacon Detonated\n" .. count .. " of " .. CD2_BeaconCount .. " Beacons detonated" )
                        break
                    end
    
                end
    
                coroutine.yield()
            end
        end )
    
    end )

end