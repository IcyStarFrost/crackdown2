local abs = math.abs
local random = math.random
local Trace = util.TraceLine
local tracetable = {}

-- Generates Map data by using the Navigation Mesh
function CD2GenerateMapData( randomize )

    CD2CreateThread( function()

        local navareas = navmesh.GetAllNavAreas()
        local averagetbl = {}
        local averageZ = 0
        local mapunderOrigin = false
        local highareas = {}
        local hiddenvectors = {}
        local pairsfunc = randomize and RandomPairs or ipairs

        local agilityorbdata = {}
        local tacticallocationdata = {}
        local hiddenorbdata = {}
        local onlineorbdata = {}
        local beacondata = {}

        CD2DebugMessage( "Generating Map Data for " .. game.GetMap() )

        -- Get all Nav area Z positions | Get Hiding Spots
        for k, nav in pairsfunc( navareas ) do
            if !IsValid( nav ) or nav:IsUnderwater() then continue end
            averagetbl[ #averagetbl + 1 ] = nav:GetCenter().z

            if #nav:GetAdjacentAreas() < 2 then 
                local hidden = nav:GetHidingSpots( 1 )
                for i = 1, #hidden do 
                    hiddenvectors[ #hiddenvectors + 1 ] = hidden[ i ] 
                end
            end
        end

        -- Calculate the average Z position
        local add = 0
        for i = 1, #averagetbl do 
            add = add + averagetbl[ i ]
        end
        averageZ = add / #averagetbl

        CD2DebugMessage( "Average Z position on the Navigation Mesh is " .. averageZ )

        -- get areas that are higher than the average
        for i = 1, #navareas do
            local nav = navareas[ i ]
            if !IsValid( nav ) then continue end

            if nav:GetCenter().z > averageZ then
                highareas[ #highareas + 1 ] = nav
            end

        end

        CD2DebugMessage( "Found a total of  " .. #highareas .. " Areas that are being considered for Agility Orbs " )

        -- Create Agility Orbs
        for k, nav in pairsfunc( highareas ) do
            if !IsValid( nav ) or nav:IsUnderwater() then continue end
            local pos = nav:GetRandomPoint()

            local nearorbs = CD2FindInSphere( pos, 2500, function( ent ) return ent:GetClass() == "cd2_agilityorb" end )

            if #nearorbs > 0 then continue end

            local agilityorb = ents.Create( "cd2_agilityorb" )
            agilityorb:SetPos( pos + Vector( 0, 0, 10) )

            agilityorb.cd2_map_isgenerated = true
            agilityorb.cd2_map_id = "agilityorb:" .. agilityorb:GetCreationID()

            if random( 1, 100 ) < 10 then
                agilityorb:SetPos( agilityorb:GetPos() + Vector( 0, 0, 380 ) )
                agilityorb:SetLevel( 4 )
            elseif random( 1, 100 ) < 10 then
                agilityorb:SetPos( agilityorb:GetPos() + Vector( 0, 0, 300 ) )
                agilityorb:SetLevel( 3 )
            elseif random( 1, 100 ) < 10 then
                agilityorb:SetPos( agilityorb:GetPos() + Vector( 0, 0, 150 ) )
                agilityorb:SetLevel( 2 )
            else
                agilityorb:SetLevel( 1 )
            end
            
            agilityorb:Spawn()
            
            agilityorbdata[ #agilityorbdata + 1 ] = { pos = agilityorb:GetPos(), level = agilityorb:GetLevel(), id = agilityorb.cd2_map_id }
            coroutine.wait( 0.01 )
        end

        CD2DebugMessage( "Generated " .. #agilityorbdata .. " Agility Orbs")

        -- Create Online Orbs
        for k, nav in pairsfunc( navareas ) do
            if !IsValid( nav ) or nav:IsUnderwater() then continue end
            local pos = nav:GetRandomPoint()
            
            local nearorbs = CD2FindInSphere( pos, 3500, function( ent ) return ent:GetClass() == "cd2_onlineorb" end )

            if #nearorbs > 0 then continue end

            local onlineorb = ents.Create( "cd2_onlineorb" )
            onlineorb:SetPos( pos + Vector( 0, 0, 10) )

            onlineorb.cd2_map_isgenerated = true
            onlineorb.cd2_map_id = "onlineorb:" .. onlineorb:GetCreationID()

            onlineorb:Spawn()
            
            onlineorbdata[ #onlineorbdata + 1 ] = { pos = onlineorb:GetPos(), id = onlineorb.cd2_map_id }
            coroutine.wait( 0.01 )
        end

        CD2DebugMessage( "Generated " .. #onlineorbdata .. " Online Orbs")

        CD2DebugMessage( "Generating Beacon/AU data.." )

        local incre = 0
        local incre2 = 0
        -- Create Beacon Positions
        for k, nav in pairsfunc( navareas ) do
            if !IsValid( nav ) or ( nav:GetSizeX() < 50 and nav:GetSizeY() < 50 ) or nav:IsUnderwater() then continue end
            local pos = nav:GetRandomPoint()
            
            
            local shouldcontinue = false
            for j = 1, #beacondata do
                local data = beacondata[ j ]
                if pos:DistToSqr( data.pos ) < ( 6000 * 6000 ) then shouldcontinue = true break end
            end
            if shouldcontinue then continue end
            incre2 = incre2 + 1

            local tbl = {}

            tracetable.start = pos
            tracetable.endpos = pos + Vector( 0, 0, 4000 )
            tracetable.mask = MASK_SOLID_BRUSHONLY
            tracetable.collisiongroup = COLLISION_GROUP_WORLD
        
            local result = Trace( tracetable )

            tbl.beaconspawnpos = result.HitPos - Vector( 0, 0, 130 )
            tbl.pos = pos 
            tbl.id = "beacon:" .. incre2
            tbl.AUID = incre2
            tbl.isdetonated = false
            tbl.AUs = {}

            for v = 1, 3 do
                incre = incre + 1
                local aupos = CD2GetRandomPos( 10000, pos )
                tbl.AUs[ #tbl.AUs + 1 ] = { aupos = aupos, isactive = false, id = "AU:" .. incre }
            end

            beacondata[ #beacondata + 1 ] = tbl
            coroutine.wait( 0.01 )
        end

        CD2DebugMessage( "Generated " .. ( #beacondata * 3 ) .. " AU positions and " .. #beacondata .. " Beacon Positions" )

        -- Create Hidden Orbs

        CD2DebugMessage( "Finding hiding places for Hidden Orbs.." )
        for k, pos in pairsfunc( hiddenvectors ) do
            if !pos then continue end

            local nearorbs = CD2FindInSphere( pos, 3000, function( ent ) return ent:GetClass() == "cd2_hiddenorb" end )

            if #nearorbs > 0 then continue end

            local hiddenorb = ents.Create( "cd2_hiddenorb" )
            hiddenorb:SetPos( pos + Vector( 0, 0, 10) )

            hiddenorb.cd2_map_isgenerated = true
            hiddenorb.cd2_map_id = "hiddenorb:" .. hiddenorb:GetCreationID()

            hiddenorb:Spawn()
            
            hiddenorbdata[ #hiddenorbdata + 1 ] = { pos = hiddenorb:GetPos(), id = hiddenorb.cd2_map_id }
            coroutine.wait( 0.01 )
        end

        CD2DebugMessage( "Generated " .. #hiddenorbdata .. " Hidden Orbs")

        CD2DebugMessage( "Looking for suitable areas for Tactical Locations.." )

        -- Create Tactical Locations
        local assignfirstlocation = true
        for k, nav in pairsfunc( navareas ) do
            if !IsValid( nav ) or nav:IsUnderwater() then continue end

            if nav:GetSizeX() > 80 and nav:GetSizeY() > 80 then
                local pos = nav:GetCenter()
                local nearlocations = CD2FindInSphere( pos, 5000, function( ent ) return ent:GetClass() == "cd2_locationmarker" and ent:GetLocationType() == "cell" end )
                if #nearlocations > 0 then continue end

                local location = ents.Create( "cd2_locationmarker" )
                location:SetPos( pos ) 
                location:SetDifficulty( 1 )

                location.cd2_map_isgenerated = true
                location.cd2_map_id = "tacticallocation:" .. location:GetCreationID()
                location:SetIsBeginningLocation( assignfirstlocation )
                if assignfirstlocation then SetGlobal2Vector( "cd2_beginnerlocation", location:GetPos() ) end

                location:SetLocationType( "cell" )
                location:Spawn()

                if assignfirstlocation then CD2DebugMessage( "Assigned beginning location to " .. location.cd2_map_id ) end

                assignfirstlocation = false
                tacticallocationdata[ #tacticallocationdata + 1 ] = { pos = location:GetPos(), id = location.cd2_map_id, difficulty = location:GetDifficulty(), type = location:GetLocationType(), isbeginninglocation = location:GetIsBeginningLocation() }
                coroutine.wait( 0.01 )
            end
        end

        CD2DebugMessage( "Generated " .. #tacticallocationdata .. " Tactical Locations" )

        -- First Beacon --
        local pos = GetGlobal2Vector( "cd2_beginnerlocation" )

        CD2_Firstbeacon = ents.Create( "cd2_beacon" )
        CD2_Firstbeacon:SetPos( CD2GetRandomPos( 1000, pos )  )
        CD2_Firstbeacon:Spawn()


        SetGlobal2Bool( "cd2_MapDataLoaded", true )
        CD2_BeaconCount = #beacondata
        CD2_BeaconData = beacondata
        CD2_CurrentBeacon = 1

        CD2CreateBeaconSet( beacondata[ 1 ] )

        CD2DebugMessage( "Completed Map Data Generation for " .. game.GetMap() )
        
        if !KeysToTheCity() then
            CD2FILESYSTEM:WriteMapData( "cd2_map_currentbeacon", 1 )
            CD2FILESYSTEM:WriteMapData( "cd2_map_beacondata", beacondata )
            CD2FILESYSTEM:WriteMapData( "cd2_map_agilityorbdata", agilityorbdata )
            CD2FILESYSTEM:WriteMapData( "cd2_map_hiddenorbdata", hiddenorbdata )
            CD2FILESYSTEM:WriteMapData( "cd2_map_tacticallocationdata", tacticallocationdata )
            CD2FILESYSTEM:WriteMapData( "cd2_map_onlineorbdata", onlineorbdata )
        end
    end )
end

-- Loads a Map Data File
function CD2LoadMapData()
    CD2DebugMessage( "Attempting to load map data for " .. game.GetMap() )
    local mapdata = CD2FILESYSTEM:ReadMapData( "TABLE" )
    if !mapdata then return false end
    
    local agilityorbs = mapdata.cd2_map_agilityorbdata
    local tacticallocations = mapdata.cd2_map_tacticallocationdata
    local hiddenorbs = mapdata.cd2_map_hiddenorbdata
    local onlineorbs = mapdata.cd2_map_onlineorbdata
    local beacondata = mapdata.cd2_map_beacondata

    -- Load agility orbs
    for i = 1, #agilityorbs do
        local orbdata = agilityorbs[ i ]
        local pos = orbdata.pos
        local level = orbdata.level
        local id = orbdata.id

        local agilityorb = ents.Create( "cd2_agilityorb" )
        agilityorb:SetPos( pos )

        agilityorb.cd2_map_isgenerated = true
        agilityorb.cd2_map_id = id

        agilityorb:SetLevel( level )
        agilityorb:Spawn()

    end

    CD2DebugMessage( "Loaded " .. #agilityorbs .. " Agility Orbs" )

    for i = 1, #onlineorbs do
        local orbdata = onlineorbs[ i ]
        local pos = orbdata.pos
        local id = orbdata.id

        local onlineorb = ents.Create( "cd2_onlineorb" )
        onlineorb:SetPos( pos )

        onlineorb.cd2_map_isgenerated = true
        onlineorb.cd2_map_id = id

        onlineorb:Spawn()
    end

    CD2DebugMessage( "Loaded " .. #onlineorbs .. " Online Orbs" )

    -- Load Hidden Orbs
    for i = 1, #hiddenorbs do
        local orbdata = hiddenorbs[ i ]
        local pos = orbdata.pos
        local id = orbdata.id

        local hiddenorb = ents.Create( "cd2_hiddenorb" )
        hiddenorb:SetPos( pos )

        hiddenorb.cd2_map_isgenerated = true
        hiddenorb.cd2_map_id = id

        hiddenorb:Spawn()

    end

    CD2DebugMessage( "Loaded " .. #hiddenorbs .. " Hidden Orbs" )


    local currentbeaconindex = mapdata.cd2_map_currentbeacon
    CD2_BeaconCount = #beacondata
    CD2_BeaconData = beacondata
    CD2_CurrentBeacon = currentbeaconindex

    for i = 1, #beacondata do
        local bdata = beacondata[ i ]
        local beaconspawnpos = bdata.beaconspawnpos
        local isdetonated = bdata.isdetonated 
        local id = bdata.id
        local auID = bdata.AUID
        local AUs = bdata.AUs

        if isdetonated then
            local beacon = ents.Create( "cd2_beacon" )
            beacon:SetPos( beaconspawnpos )
            
            beacon.cd2_map_isgenerated = true
            beacon.cd2_map_id = id

            beacon:Spawn()

            timer.Simple( 0.1, function() beacon:StartBeaconasActive() end )
        else
            local activeAUs = 0
            --if id == currentbeaconindex then
                for v = 1, #AUs do
                    if v > currentbeaconindex then continue end
                    local audata = AUs[ v ]
                    local aupos = audata.aupos
                    local active = audata.isactive
                    local aumapID = audata.id
    
                    local au = ents.Create( "cd2_au" )
                    au:SetPos( aupos ) 


                    au.cd2_map_isgenerated = true
                    au.cd2_map_id = aumapID

                    au:SetAUGroupID( auID )
                    au:SetBeamPos( beaconspawnpos + Vector( 0, 0, 120 ) )
                    au:Spawn()

                    if active then
                        activeAUs = activeAUs + 1
                        timer.Simple( 0.1, function() au:EnableBeam() end )
                    end
    
                end
            --end

            if activeAUs == 3 then
                local bdata = CD2_BeaconData[ auID ]
                local pos = bdata.pos

                local marker = ents.Create( "cd2_locationmarker" )
                marker:SetPos( pos ) 
                marker:SetLocationType( "beacon" )

                function marker:OnActivate( ply ) 
                    local sndtracks = { "sound/crackdown2/music/beacon/ptb.mp3", "sound/crackdown2/music/beacon/industrialfreaks.mp3" }
                    sound.Play( "crackdown2/ambient/tacticallocationactivate.mp3", self:GetPos(), 100, 100, 1 )

                    marker.cd2_beacon = ents.Create( "cd2_beacon" )
                    marker.cd2_beacon:SetPos( bdata.beaconspawnpos )
                    
                    marker.cd2_beacon.cd2_map_isgenerated = true
                    marker.cd2_beacon.cd2_map_id = bdata.id
                    marker.cd2_beacon.cd2_AUgroup = bdata.AUID

                    marker.cd2_beacon:SetSoundTrack( sndtracks[ math.random( #sndtracks ) ] )

                    marker.cd2_beacon:Spawn()

                    timer.Simple( 0.1, function() marker.cd2_beacon:DropBeacon() end )
                end

                marker:Spawn()

                CD2CreateThread( function()
                    while true do 
                        if !IsValid( marker ) then return end

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

                                CD2SetTypingText( nil, "OBJECTIVE COMPLETE!", "Beacon Detonated\n" .. count .. " of " .. CD2_BeaconCount .. " Beacons detonated" )
                                return
                            end

                        end

                        coroutine.yield()
                    end
                end )
            end
        end


    end


    -- Load tactical locations
    for i = 1, #tacticallocations do
        local locationdata = tacticallocations[ i ]
        local pos = locationdata.pos
        local id = locationdata.id
        local difficulty = locationdata.difficulty
        local type = locationdata.type
        local isbeginninglocation = locationdata.isbeginninglocation

        local location = ents.Create( "cd2_locationmarker" )
        location:SetPos( pos ) 
        location:SetDifficulty( difficulty )
        location:SetIsBeginningLocation( isbeginninglocation )
        
        if isbeginninglocation then  SetGlobal2Vector( "cd2_beginnerlocation", location:GetPos() ) end

        location.cd2_map_isgenerated = true
        location.cd2_map_id = id

        location:SetLocationType( type )
        location:Spawn()

    end

    CD2DebugMessage( "Loaded " .. #tacticallocations .. " Tactical Locations" )

    SetGlobal2Bool( "cd2_MapDataLoaded", true )


    return true
end


local table_remove = table.remove
hook.Add( "CD2_OnAgilityOrbCollected", "crackdown2_removeorbfrommapdata", function( orb, ply )
    if !orb.cd2_map_isgenerated or KeysToTheCity() then return end
    local agilityorbdata = CD2FILESYSTEM:ReadMapData( "cd2_map_agilityorbdata" )

    for i = 1, #agilityorbdata do
        local data = agilityorbdata[ i ]

        if data and data.id == orb.cd2_map_id then
            CD2DebugMessage( "Removing Map Generated Agility Orb ID " .. orb.cd2_map_id )
            table_remove( agilityorbdata, i )
        end
    end

    CD2FILESYSTEM:WriteMapData( "cd2_map_agilityorbdata", agilityorbdata )
end )



hook.Add( "CD2_OnOnlineOrbCollected", "crackdown2_removeorbfrommapdata", function( orb, ply )
    if !orb.cd2_map_isgenerated or KeysToTheCity() then return end
    local onlineorbdata = CD2FILESYSTEM:ReadMapData( "cd2_map_onlineorbdata" )

    for i = 1, #onlineorbdata do
        local data = onlineorbdata[ i ]

        if data and data.id == orb.cd2_map_id then
            CD2DebugMessage( "Removing Map Generated Online Orb ID " .. orb.cd2_map_id )
            table_remove( onlineorbdata, i )
        end
    end

    CD2FILESYSTEM:WriteMapData( "cd2_map_onlineorbdata", onlineorbdata )
end )

hook.Add( "CD2_OnHiddenOrbCollected", "crackdown2_removeorbfrommapdata", function( orb, ply )
    if !orb.cd2_map_isgenerated or KeysToTheCity() then return end
    local hiddenorbdata = CD2FILESYSTEM:ReadMapData( "cd2_map_hiddenorbdata" )

    for i = 1, #hiddenorbdata do
        local data = hiddenorbdata[ i ]

        if data and data.id == orb.cd2_map_id then
            CD2DebugMessage( "Removing Map Generated Hidden Orb ID " .. orb.cd2_map_id )
            table_remove( hiddenorbdata, i )
        end
    end

    CD2FILESYSTEM:WriteMapData( "cd2_map_hiddenorbdata", hiddenorbdata )
end )


hook.Add( "CD2_OnTacticalLocationCaptured", "crackdown2_locationcaptured", function( location ) 
    if !location.cd2_map_isgenerated then return end

    if !KeysToTheCity() then
        local locationdata = CD2FILESYSTEM:ReadMapData( "cd2_map_tacticallocationdata" )

        for i = 1, #locationdata do
            local data = locationdata[ i ]

            if data and data.id == location.cd2_map_id then
                CD2DebugMessage( "Updating Tactical Location status ID " .. location.cd2_map_id )
                data.type = "agency"
            end
        end

        CD2FILESYSTEM:WriteMapData( "cd2_map_tacticallocationdata", locationdata )
    end
    
    if location:GetIsBeginningLocation() then
        tracetable.start = location:GetPos()
        tracetable.endpos = location:GetPos() + Vector( 0, 0, 6000 )
        tracetable.mask = MASK_SOLID_BRUSHONLY
        tracetable.collisiongroup = COLLISION_GROUP_WORLD

        local result = Trace( tracetable )

        local copter = ents.Create( "cd2_agencyhelicopter" )
        copter:SetPos( result.HitPos ) 
        copter:Spawn()
        copter:ExtractEntity( CD2_Firstbeacon )
    end
    
    
    
end )