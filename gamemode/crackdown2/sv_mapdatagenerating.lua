local random = math.random
local Trace = util.TraceLine
local tracetable = {}

-- Generates Map data by using the Navigation Mesh
function CD2GenerateMapData( randomize, agencystart )

    CD2CreateThread( function()

        local navareas = navmesh.GetAllNavAreas()
        local averagetbl = {}
        local averageZ = 0
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

            local nearorbs = CD2FindInSphere( pos, 1500, function( ent ) return ent:GetClass() == "cd2_agilityorb" end )

            if #nearorbs > 0 then continue end

            local agilityorb = ents.Create( "cd2_agilityorb" )
            agilityorb:SetPos( pos + Vector( 0, 0, 20 ) )

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
            
            local nearorbs = CD2FindInSphere( pos, 6500, function( ent ) return ent:GetClass() == "cd2_onlineorb" end )

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

            local tbl = {}

            tracetable.start = pos
            tracetable.endpos = pos + Vector( 0, 0, 4000 )
            tracetable.mask = MASK_SOLID_BRUSHONLY
            tracetable.collisiongroup = COLLISION_GROUP_WORLD
        
            local result = Trace( tracetable )

            if result.HitPos:DistToSqr( pos ) < ( 500 * 500 ) then CD2DebugMessage( "Rejecting a potential beacon position due to low ceiling" ) continue end

            incre2 = incre2 + 1

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

        if #beacondata < 1 then  
            coroutine.wait( 1 )
            CD2DebugMessage( "WARNING! MAP GENERATOR DEEMED THE CURRENT MAP UNPLAYABLE" )
            BroadcastLua( "CD2ShowFailMenu( 'The Map Data Generator deemed this map to be unplayable. Please pick a different map' )" )
            SetGlobal2Bool( "cd2_mapgenfailed", true )
            return 
        end 

        CD2DebugMessage( "Generated " .. ( #beacondata * 3 ) .. " AU positions and " .. #beacondata .. " Beacon Positions" )

        -- Create Hidden Orbs

        CD2DebugMessage( "Finding hiding places for Hidden Orbs.." )
        for k, pos in pairsfunc( hiddenvectors ) do
            if !pos then continue end

            local nearorbs = CD2FindInSphere( pos, 2500, function( ent ) return ent:GetClass() == "cd2_hiddenorb" end )

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

                location.cd2_map_isgenerated = true
                location.cd2_map_id = "tacticallocation:" .. location:GetCreationID()
                location:SetIsBeginningLocation( assignfirstlocation )
                if assignfirstlocation then SetGlobal2Vector( "cd2_beginnerlocation", location:GetPos() ) end

                location:SetLocationType( ( KeysToTheCity() or agencystart ) and assignfirstlocation and "agency" or "cell" )
                location:Spawn()

                if assignfirstlocation then CD2_BeginnerLocation = location CD2DebugMessage( "Assigned beginning location to " .. location.cd2_map_id ) end

                assignfirstlocation = false
                tacticallocationdata[ #tacticallocationdata + 1 ] = { pos = location:GetPos(), id = location.cd2_map_id, type = location:GetLocationType(), isbeginninglocation = location:GetIsBeginningLocation() }
                coroutine.wait( 0.01 )
            end
        end

        if #tacticallocationdata < 2 then  
            coroutine.wait( 1 )
            SetGlobal2Bool( "cd2_mapgenfailed", true )
            CD2DebugMessage( "WARNING! MAP GENERATOR DEEMED THE CURRENT MAP UNPLAYABLE" )
            BroadcastLua( "CD2ShowFailMenu( 'The Map Data Generator deemed this map to be unplayable. Please pick a different map' )" )
            return 
        end 

        CD2DebugMessage( "Generated " .. #tacticallocationdata .. " Tactical Locations" )


        -- Final Beacon --
        for k, nav in pairsfunc( navareas ) do
            if !IsValid( nav ) or nav:IsUnderwater() or nav:GetSizeX() < 80 and nav:GetSizeY() < 80 or !nav:IsFlat() then continue end
            local pos = nav:GetCenter()

            CD2_BeaconTower = ents.Create( "cd2_towerbeacon" )
            CD2_BeaconTower:SetPos( pos )
            CD2_BeaconTower:Spawn()

            finalbeacondata = { pos = pos, isdetonated = false }
            break
        end

        CD2DebugMessage( "Generated Beacon Tower" )
        

        -- First Beacon --
        local pos = GetGlobal2Vector( "cd2_beginnerlocation" )

        if !KeysToTheCity() or !agencystart then
            CD2_Firstbeacon = ents.Create( "cd2_beacon" )
            CD2_Firstbeacon:SetPos( CD2GetRandomPos( 1000, pos )  )
            CD2_Firstbeacon:Spawn()
        end


        
        CD2_BeaconCount = #beacondata
        CD2_AgilityOrbCount = #agilityorbdata
        CD2_HiddenOrbCount = #hiddenorbdata
        CD2_OnlineOrbCount = #onlineorbdata

        CD2_FinalBeaconData = finalbeacondata
        CD2_BeaconData = beacondata
        CD2_CurrentBeacon = 1

        SetGlobal2Bool( "cd2_MapDataLoaded", true )
        SetGlobal2Int( "cd2_beaconcount", CD2_BeaconCount )

        CD2CreateBeaconSet( beacondata[ 1 ] )

        CD2DebugMessage( "Completed Map Data Generation for " .. game.GetMap() )
        
        if !KeysToTheCity() then
            CD2FILESYSTEM:WriteMapData( "cd2_map_finalbeacon", finalbeacondata )
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
    local finalbeacondata = mapdata.cd2_map_finalbeacon

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

    CD2_BeaconTower = ents.Create( "cd2_towerbeacon" )
    CD2_BeaconTower:SetPos( finalbeacondata.pos )
    CD2_BeaconTower:Spawn()

    CD2DebugMessage( "Loaded the Tower Beacon" )

    CD2_AgilityOrbCount = #agilityorbs
    CD2_HiddenOrbCount = #hiddenorbs
    CD2_OnlineOrbCount = #onlineorbs

    local beaconindex = CD2FILESYSTEM:ReadMapData( "cd2_map_currentbeacon" )
    local detonatecount = 0
    local activeaucount = 0

    for i = 1, #beacondata do
        if i > beaconindex then break end
        local beacongroup = beacondata[ i ]

        CD2CreateBeaconSet( beacongroup )
    end

    CD2_BeaconCount = #beacondata
    CD2_BeaconData = beacondata
    CD2_CurrentBeacon = beaconindex

    SetGlobal2Int( "cd2_beaconcount", CD2_BeaconCount )

    CD2DebugMessage( "Loaded " .. detonatecount .. " active beacons. Loaded " .. activeaucount .. " active Absorption Units" )
    CD2DebugMessage( "Loaded " .. #beacondata .. " Beacons and " .. ( #beacondata * 3 ) .. " Absorption Units. Current beacon group is " .. beaconindex )


    -- Load tactical locations
    for i = 1, #tacticallocations do
        local locationdata = tacticallocations[ i ]
        local pos = locationdata.pos
        local id = locationdata.id
        local type = locationdata.type
        local isbeginninglocation = locationdata.isbeginninglocation

        local location = ents.Create( "cd2_locationmarker" )
        location:SetPos( pos ) 
        location:SetIsBeginningLocation( isbeginninglocation )
        
        if isbeginninglocation then CD2_BeginnerLocation = location SetGlobal2Vector( "cd2_beginnerlocation", location:GetPos() ) end

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


hook.Add( "CD2_AUActivated", "crackdown2_updateAUs", function( au ) 
    if !au.cd2_map_isgenerated or KeysToTheCity() then return end
    local Beacondata = CD2FILESYSTEM:ReadMapData( "cd2_map_beacondata" )

    for i = 1, #Beacondata do
        local beacongroupdata = Beacondata[ i ]
        local AUs = beacongroupdata.AUs

        for n = 1, #AUs do
            local AUdata = AUs[ n ]
            if AUdata.id == au.cd2_map_id then  
                AUdata.isactive = true
                break 
            end
        end
    end

    CD2FILESYSTEM:WriteMapData( "cd2_map_beacondata", Beacondata )
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
    
    if location:GetIsBeginningLocation() and !KeysToTheCity() then
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