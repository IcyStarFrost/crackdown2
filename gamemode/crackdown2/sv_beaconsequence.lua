
hook.Add( "CD2_BeaconDetonate", "crackdown2_beaconsequence", function( beacon )
    if !beacon.cd2_map_isgenerated then return end
    
    if !KeysToTheCity() then
        local Beacondata = CD2FILESYSTEM:ReadMapData( "cd2_map_beacondata" )

        local beaconid = beacon.cd2_AUgroup
        local tbl = Beacondata[ beaconid + 1 ]

        CD2DebugMessage( "Beacon of AU Group " .. beaconid .. " has been detonated")

        
        for i = 1, #Beacondata do
            local bdata = Beacondata[ i ]
            if bdata.id == beacon.cd2_map_id then CD2DebugMessage( "Marking " .. bdata.id .. " as detonated in map data" ) bdata.isdetonated = true CD2FILESYSTEM:WriteMapData( "cd2_map_beacondata", Beacondata ) break end
        end

        CD2CreateBeaconSet( tbl )
    else
        local beaconid = beacon.cd2_AUgroup
        local tbl = CD2_BeaconData[ beaconid + 1 ]
        
        CD2DebugMessage( "Beacon of AU Group " .. beaconid .. " has been detonated")

        CD2CreateBeaconSet( tbl )
    end
    
    
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

        CD2PingLocation( nil, beacondata.pos )
    
        function marker:OnActivate( ply ) 
            sound.Play( "crackdown2/ambient/tacticallocationactivate.mp3", self:GetPos(), 100, 100, 1 )

            CD2DebugMessage( self, "A Beacon for AUGroup " .. beacondata.AUID .. " has been called by " .. ply:Name() )
    
            marker.cd2_beacon = ents.Create( "cd2_beacon" )
            marker.cd2_beacon:SetPos( beacondata.beaconspawnpos )
            
            marker.cd2_beacon.cd2_map_isgenerated = true
            marker.cd2_beacon.cd2_map_id = beacondata.id
            marker.cd2_beacon.cd2_AUgroup = beacondata.AUID
    
            marker.cd2_beacon:SetRandomSoundTrack()
    
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
    
                if IsValid( marker.cd2_beacon ) and marker.cd2_beacon:GetIsDetonated() then
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

                        CD2CreateThread( function()
                            coroutine.wait( 8 )
                            for k, v in ipairs( player.GetAll() ) do
                                v:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/final1.mp3" )
                            end

                            coroutine.wait( 4 )

                            for k, v in ipairs( player.GetAll() ) do
                                v:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/final2.mp3" )
                            end

                            coroutine.wait( 2 )

                            for k, v in ipairs( player.GetAll() ) do
                                v:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/final3.mp3" )
                            end

                            coroutine.wait( 9 )

                            for k, v in ipairs( player.GetAll() ) do
                                v:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/final4.mp3" )
                            end

                            coroutine.wait( 6 )

                            for k, v in ipairs( player.GetAll() ) do
                                CD2PingLocation( v, CD2_BeaconTower:GetPos() )
                            end

                            coroutine.wait( 2 )

                            for k, v in ipairs( player.GetAll() ) do
                                CD2PingLocation( v, CD2_BeaconTower:GetPos() )
                            end
                        
                        end )
                    end
    
                    CD2SetTypingText( nil, "OBJECTIVE COMPLETE!", "Beacon Detonated\n" .. count .. " of " .. CD2_BeaconCount .. " Beacons detonated" )
                    break
                end
    
                coroutine.yield()
            end
        end )
    
    end )

end