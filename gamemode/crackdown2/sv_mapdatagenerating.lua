local random = math.random
local Trace = util.TraceLine
local tracetable = {}

-- Generates Map data by using the Navigation Mesh
function CD2:GenerateMapData( randomize, agencystart )

    self:CreateThread( function()
        if !navmesh.IsLoaded() then return end

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

        self:DebugMessage( "Generating Map Data for " .. game.GetMap() )

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

        self:DebugMessage( "Average Z position on the Navigation Mesh is " .. averageZ )

        -- get areas that are higher than the average
        for i = 1, #navareas do
            local nav = navareas[ i ]
            if !IsValid( nav ) then continue end

            if nav:GetCenter().z > averageZ then
                highareas[ #highareas + 1 ] = nav
            end

        end

        self:DebugMessage( "Found a total of  " .. #highareas .. " Areas that are being considered for Agility Orbs " )

        -- Create Agility Orbs
        for k, nav in pairsfunc( highareas ) do
            if !IsValid( nav ) or nav:IsUnderwater() then continue end
            local pos = nav:GetRandomPoint()

            local nearorbs = self:FindInSphere( pos, 1500, function( ent ) return ent:GetClass() == "cd2_agilityorb" end )

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

        self:DebugMessage( "Generated " .. #agilityorbdata .. " Agility Orbs")

        -- Create Online Orbs
        for k, nav in pairsfunc( navareas ) do
            if !IsValid( nav ) or nav:IsUnderwater() then continue end
            local pos = nav:GetRandomPoint()
            
            local nearorbs = self:FindInSphere( pos, 6500, function( ent ) return ent:GetClass() == "cd2_onlineorb" end )

            if #nearorbs > 0 then continue end

            local onlineorb = ents.Create( "cd2_onlineorb" )
            onlineorb:SetPos( pos + Vector( 0, 0, 10) )

            onlineorb.cd2_map_isgenerated = true
            onlineorb.cd2_map_id = "onlineorb:" .. onlineorb:GetCreationID()

            onlineorb:Spawn()
            
            onlineorbdata[ #onlineorbdata + 1 ] = { pos = onlineorb:GetPos(), id = onlineorb.cd2_map_id }
            coroutine.wait( 0.01 )
        end

        self:DebugMessage( "Generated " .. #onlineorbdata .. " Online Orbs")

        self:DebugMessage( "Generating Beacon/AU data.." )

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

            if result.HitPos:DistToSqr( pos ) < ( 500 * 500 ) then self:DebugMessage( "Rejecting a potential beacon position due to low ceiling" ) continue end

            incre2 = incre2 + 1

            tbl.beaconspawnpos = result.HitPos - Vector( 0, 0, 130 )
            tbl.pos = pos 
            tbl.id = "beacon:" .. incre2
            tbl.AUID = incre2
            tbl.isdetonated = false
            tbl.AUs = {}


            for v = 1, 3 do
                incre = incre + 1
                local aupos = self:GetRandomPos( 10000, pos )
                tbl.AUs[ #tbl.AUs + 1 ] = { aupos = aupos, isactive = false, id = "AU:" .. incre }
            end

            beacondata[ #beacondata + 1 ] = tbl
            coroutine.wait( 0.01 )
        end

        if #beacondata < 1 then  
            coroutine.wait( 1 )
            self:DebugMessage( "WARNING! MAP GENERATOR DEEMED THE CURRENT MAP UNPLAYABLE" )
            BroadcastLua( "CD2:ShowFailMenu( 'The Map Data Generator deemed this map to be unplayable. Please pick a different map' )" )
            SetGlobal2Bool( "cd2_mapgenfailed", true )
            return 
        end 

        self:DebugMessage( "Generated " .. ( #beacondata * 3 ) .. " AU positions and " .. #beacondata .. " Beacon Positions" )

        -- Create Hidden Orbs

        self:DebugMessage( "Finding hiding places for Hidden Orbs.." )
        for k, pos in pairsfunc( hiddenvectors ) do
            if !pos then continue end

            local nearorbs = self:FindInSphere( pos, 2500, function( ent ) return ent:GetClass() == "cd2_hiddenorb" end )

            if #nearorbs > 0 then continue end

            local hiddenorb = ents.Create( "cd2_hiddenorb" )
            hiddenorb:SetPos( pos + Vector( 0, 0, 10) )

            hiddenorb.cd2_map_isgenerated = true
            hiddenorb.cd2_map_id = "hiddenorb:" .. hiddenorb:GetCreationID()

            hiddenorb:Spawn()
            
            hiddenorbdata[ #hiddenorbdata + 1 ] = { pos = hiddenorb:GetPos(), id = hiddenorb.cd2_map_id }
            coroutine.wait( 0.01 )
        end

        self:DebugMessage( "Generated " .. #hiddenorbdata .. " Hidden Orbs")

        self:DebugMessage( "Looking for suitable areas for Tactical Locations.." )

        -- Create Tactical Locations
        local assignfirstlocation = true
        for k, nav in pairsfunc( navareas ) do
            if !IsValid( nav ) or nav:IsUnderwater() then continue end

            if nav:GetSizeX() > 80 and nav:GetSizeY() > 80 then
                local pos = nav:GetCenter()
                local nearlocations = self:FindInSphere( pos, 5000, function( ent ) return ent:GetClass() == "cd2_locationmarker" and ent:GetLocationType() == "cell" end )
                if #nearlocations > 0 then continue end

                local location = ents.Create( "cd2_locationmarker" )
                location:SetPos( pos ) 

                location.cd2_map_isgenerated = true
                location.cd2_map_id = "tacticallocation:" .. location:GetCreationID()
                location:SetIsBeginningLocation( assignfirstlocation )
                if assignfirstlocation then SetGlobal2Vector( "cd2_beginnerlocation", location:GetPos() ) end

                location:SetLocationType( ( self:KeysToTheCity() or agencystart ) and assignfirstlocation and "agency" or "cell" )
                location:Spawn()

                if assignfirstlocation then self.BeginnerLocation = location self:DebugMessage( "Assigned beginning location to " .. location.cd2_map_id ) end

                assignfirstlocation = false
                tacticallocationdata[ #tacticallocationdata + 1 ] = { pos = location:GetPos(), id = location.cd2_map_id, type = location:GetLocationType(), isbeginninglocation = location:GetIsBeginningLocation() }
                coroutine.wait( 0.01 )
            end
        end

        if #tacticallocationdata < 2 then  
            coroutine.wait( 1 )
            SetGlobal2Bool( "cd2_mapgenfailed", true )
            self:DebugMessage( "WARNING! MAP GENERATOR DEEMED THE CURRENT MAP UNPLAYABLE" )
            BroadcastLua( "CD2:ShowFailMenu( 'The Map Data Generator deemed this map to be unplayable. Please pick a different map' )" )
            return 
        end 

        self:DebugMessage( "Generated " .. #tacticallocationdata .. " Tactical Locations" )


        -- Final Beacon --
        for k, nav in pairsfunc( navareas ) do
            if !IsValid( nav ) or nav:IsUnderwater() or nav:GetSizeX() < 80 and nav:GetSizeY() < 80 or !nav:IsFlat() then continue end
            local pos = nav:GetCenter()

            self.BeaconTower = ents.Create( "cd2_towerbeacon" )
            self.BeaconTower:SetPos( pos )
            self.BeaconTower:Spawn()

            finalbeacondata = { pos = pos, isdetonated = false }
            break
        end

        self:DebugMessage( "Generated Beacon Tower" )
        

        -- First Beacon --
        local pos = GetGlobal2Vector( "cd2_beginnerlocation" )

        if !self:KeysToTheCity() or !agencystart then
            self.Firstbeacon = ents.Create( "cd2_beacon" )
            self.Firstbeacon:SetPos( self:GetRandomPos( 1000, pos )  )
            self.Firstbeacon:Spawn()
        end


        
        self.BeaconCount = #beacondata
        self.AgilityOrbCount = #agilityorbdata
        self.HiddenOrbCount = #hiddenorbdata
        self.OnlineOrbCount = #onlineorbdata

        self.FinalBeaconData = finalbeacondata
        self.BeaconData = beacondata
        self.CurrentBeacon = 1

        SetGlobal2Bool( "cd2_MapDataLoaded", true )
        SetGlobal2Int( "cd2_beaconcount", self.BeaconCount )

        self:CreateBeaconSet( beacondata[ 1 ] )

        self:DebugMessage( "Completed Map Data Generation for " .. game.GetMap() )
        
        if !self:KeysToTheCity() then
            self:WriteMapData( "cd2_map_finalbeacon", finalbeacondata )
            self:WriteMapData( "cd2_map_currentbeacon", 1 )
            self:WriteMapData( "cd2_map_beacondata", beacondata )
            self:WriteMapData( "cd2_map_agilityorbdata", agilityorbdata )
            self:WriteMapData( "cd2_map_hiddenorbdata", hiddenorbdata )
            self:WriteMapData( "cd2_map_tacticallocationdata", tacticallocationdata )
            self:WriteMapData( "cd2_map_onlineorbdata", onlineorbdata )
        end
    end )
end

-- Loads a Map Data File
function CD2:LoadMapData()
    self:DebugMessage( "Attempting to load map data for " .. game.GetMap() )
    local mapdata = self:ReadMapData( "TABLE" )
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

    self:DebugMessage( "Loaded " .. #agilityorbs .. " Agility Orbs" )

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

    self:DebugMessage( "Loaded " .. #onlineorbs .. " Online Orbs" )

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

    self:DebugMessage( "Loaded " .. #hiddenorbs .. " Hidden Orbs" )

    self.BeaconTower = ents.Create( "cd2_towerbeacon" )
    self.BeaconTower:SetPos( finalbeacondata.pos )
    self.BeaconTower:Spawn()

    self:DebugMessage( "Loaded the Tower Beacon" )

    self.AgilityOrbCount = #agilityorbs
    self.HiddenOrbCount = #hiddenorbs
    self.OnlineOrbCount = #onlineorbs

    local beaconindex = self:ReadMapData( "cd2_map_currentbeacon" )
    local detonatecount = 0
    local activeaucount = 0

    for i = 1, #beacondata do
        if i > beaconindex then break end
        local beacongroup = beacondata[ i ]

        self:CreateBeaconSet( beacongroup )
    end

    self.BeaconCount = #beacondata
    self.BeaconData = beacondata
    self.CurrentBeacon = beaconindex

    SetGlobal2Int( "cd2_beaconcount", self.BeaconCount )

    self:DebugMessage( "Loaded " .. detonatecount .. " active beacons. Loaded " .. activeaucount .. " active Absorption Units" )
    self:DebugMessage( "Loaded " .. #beacondata .. " Beacons and " .. ( #beacondata * 3 ) .. " Absorption Units. Current beacon group is " .. beaconindex )


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
        
        if isbeginninglocation then self.BeginnerLocation = location SetGlobal2Vector( "cd2_beginnerlocation", location:GetPos() ) end

        location.cd2_map_isgenerated = true
        location.cd2_map_id = id

        location:SetLocationType( type )
        location:Spawn()

    end

    self:DebugMessage( "Loaded " .. #tacticallocations .. " Tactical Locations" )

    SetGlobal2Bool( "cd2_MapDataLoaded", true )


    return true
end


-- TODO: Do not delete agility orbs after collection. 
-- Instead, make them track steamids that collected them and become invisble for those that have collected them.
-- This will ensure all players are able to collect all agility orbs.
local table_remove = table.remove
hook.Add( "CD2_OnAgilityOrbCollected", "crackdown2_removeorbfrommapdata", function( orb, ply )
    if !orb.cd2_map_isgenerated or CD2:KeysToTheCity() then return end
    local agilityorbdata = CD2:ReadMapData( "cd2_map_agilityorbdata" )

    for i = 1, #agilityorbdata do
        local data = agilityorbdata[ i ]

        if data and data.id == orb.cd2_map_id then
            CD2:DebugMessage( "Removing Map Generated Agility Orb ID " .. orb.cd2_map_id )
            table_remove( agilityorbdata, i )
        end
    end

    CD2:WriteMapData( "cd2_map_agilityorbdata", agilityorbdata )
end )


hook.Add( "CD2_AUActivated", "crackdown2_updateAUs", function( au ) 
    if !au.cd2_map_isgenerated or CD2:KeysToTheCity() then return end
    local Beacondata = CD2:ReadMapData( "cd2_map_beacondata" )

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

    CD2:WriteMapData( "cd2_map_beacondata", Beacondata )
end )


hook.Add( "CD2_OnOnlineOrbCollected", "crackdown2_removeorbfrommapdata", function( orb, ply )
    if !orb.cd2_map_isgenerated or CD2:KeysToTheCity() then return end
    local onlineorbdata = CD2:ReadMapData( "cd2_map_onlineorbdata" )

    for i = 1, #onlineorbdata do
        local data = onlineorbdata[ i ]

        if data and data.id == orb.cd2_map_id then
            CD2:DebugMessage( "Removing Map Generated Online Orb ID " .. orb.cd2_map_id )
            table_remove( onlineorbdata, i )
        end
    end

    CD2:WriteMapData( "cd2_map_onlineorbdata", onlineorbdata )
end )

hook.Add( "CD2_OnHiddenOrbCollected", "crackdown2_removeorbfrommapdata", function( orb, ply )
    if !orb.cd2_map_isgenerated or CD2:KeysToTheCity() then return end
    local hiddenorbdata = CD2:ReadMapData( "cd2_map_hiddenorbdata" )

    for i = 1, #hiddenorbdata do
        local data = hiddenorbdata[ i ]

        if data and data.id == orb.cd2_map_id then
            CD2:DebugMessage( "Removing Map Generated Hidden Orb ID " .. orb.cd2_map_id )
            table_remove( hiddenorbdata, i )
        end
    end

    CD2:WriteMapData( "cd2_map_hiddenorbdata", hiddenorbdata )
end )


hook.Add( "CD2_OnTacticalLocationCaptured", "crackdown2_locationcaptured", function( location ) 
    if !location.cd2_map_isgenerated then return end

    if !CD2:KeysToTheCity() then
        local locationdata = CD2:ReadMapData( "cd2_map_tacticallocationdata" )

        for i = 1, #locationdata do
            local data = locationdata[ i ]

            if data and data.id == location.cd2_map_id then
                CD2:DebugMessage( "Updating Tactical Location status ID " .. location.cd2_map_id )
                data.type = "agency"
            end
        end

        CD2:WriteMapData( "cd2_map_tacticallocationdata", locationdata )
    end
    
    if location:GetIsBeginningLocation() and !CD2:KeysToTheCity() and IsValid( CD2.Firstbeacon ) then
        tracetable.start = location:GetPos()
        tracetable.endpos = location:GetPos() + Vector( 0, 0, 6000 )
        tracetable.mask = MASK_SOLID_BRUSHONLY
        tracetable.collisiongroup = COLLISION_GROUP_WORLD

        local result = Trace( tracetable )

        local copter = ents.Create( "cd2_agencyhelicopter" )
        copter:SetPos( result.HitPos ) 
        copter:Spawn()
        copter:ExtractEntity( CD2.Firstbeacon )
    end
    
    
    
end )

hook.Add( "PostCleanupMap", "crackdown2_regenmap", function()

    local hooktbl = hook.GetTable()
    local powernetworkhooks = hooktbl.CD2_PowerNetworkComplete

    if powernetworkhooks then
        for k, v in pairs( powernetworkhooks ) do
            hook.Remove( "CD2_PowerNetworkComplete", k )
        end
    end

    CD2:GenerateMapData( true )

    for k, ply in ipairs( player.GetAll() ) do
        timer.Simple( 0.01, function()
            if !IsValid( ply.cd2_holsteredweapon ) then 
    
                local mdl
    
                for k, v in ipairs( ply:GetWeapons() ) do
                    if v != ply:GetActiveWeapon() then mdl = v:GetModel() break end
                end
    
                ply.cd2_holsteredweapon = ents.Create( "base_anim" )
                ply.cd2_holsteredweapon:SetNoDraw( true )
                ply.cd2_holsteredweapon:SetModel( mdl or "" )
                ply.cd2_holsteredweapon:SetPos( ply:GetPos() )
                ply.cd2_holsteredweapon:SetAngles( ply:GetAngles() )
                ply.cd2_holsteredweapon:Spawn()
    
                local mins = ply.cd2_holsteredweapon:GetModelBounds()
                ply.cd2_holsteredweapon:FollowBone( ply, ply:LookupBone( "ValveBiped.Bip01_Spine2" ) )
                ply.cd2_holsteredweapon:SetLocalPos( Vector( -10, -9, 0 ) - mins / 2 ) 
                ply.cd2_holsteredweapon:SetLocalAngles( Angle( 40, 0, 0 ) )
    
                ply.cd2_holsteredweapon.Think = function( entself ) if entself:GetModel() != "models/error.mdl" then entself:SetNoDraw( !ply:Alive() and true or ply:GetNoDraw() ) end end
    
                if mdl then ply.cd2_holsteredweapon:SetNoDraw( false ) end
            end
        end )
    end 
end )