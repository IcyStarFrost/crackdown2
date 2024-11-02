CD2.MAPPROPGENERATOR = CD2.MAPPROPGENERATOR or {}
CD2.MAPPROPGENERATOR.cd2_generatefunctions = {}


-- Returns if the generator can spawn stuff at the specified position
function CD2.MAPPROPGENERATOR:CanGenerateAt( pos )
    local nearby = CD2:FindInSphere( pos, 3000, function( ent ) return ent.cd2_mpggenerated end )
    return #nearby == 0
end

-- Performs a vis check for the entity provided and deletes it if it fails
function CD2.MAPPROPGENERATOR:VisCheck( ent )
    local players = player.GetAll()
    local withinPVS = false
    for i = 1, #players do
        local ply = players[ i ]
        if ply:IsCD2Agent() and ent:SqrRangeTo( ply ) < ( 3000 * 3000 ) then withinPVS = true end
    end
    if !withinPVS then ent:Remove() end
end

-- Adds a optimizing Tick hook onto the specified entity
function CD2.MAPPROPGENERATOR:InstallTick( ent )
    local freq = 0
    hook.Add( "Tick", ent, function() 
        if CurTime() < freq then return end 
        self:VisCheck( ent )
        freq = CurTime() + 2
    end )
end

-- Helper function for creating props
function CD2.MAPPROPGENERATOR:SpawnProp( pos, angle, model, frozen )
    local prop = ents.Create( "prop_physics" )
    prop:SetModel( model )
    prop:SetPos( pos )
    prop:SetAngles( angle )
    prop:Spawn()

    local mins = prop:OBBMins()
    pos.z = pos.z - mins.z
    prop:SetPos( pos )

    local phys = prop:GetPhysicsObject()
    if frozen and IsValid( phys ) then phys:EnableMotion( false ) end

    prop.cd2_mpggenerated = true

    self:InstallTick( prop )

    return prop
end

-- Returns what type of generate functions should be used at this position
function CD2.MAPPROPGENERATOR:DetermineGenerateType( pos )
    local nearby = CD2:FindInSphere( pos, 2000 )
    for k, v in ipairs( nearby ) do
        if v:GetClass() == "cd2_locationmarker" and v:GetLocationType() == "cell" then return "cell" end
        if v:GetClass() == "cd2_locationmarker" and ( v:GetLocationType() == "agency" or v:GetLocationType() == "beacon" ) then return "agency" end
        if v:GetClass() == "cd2_towerbeacon" then return "agency" end
    end
    return "global"
end

-- Adds a prop generation function to a list of generating types
function CD2.MAPPROPGENERATOR:AddGenerateFunction( name, type, func )
    self.cd2_generatefunctions[ type ] = self.cd2_generatefunctions[ type ] or {}
    local typefunctions = self.cd2_generatefunctions[ type ]
    typefunctions[ #typefunctions + 1 ] = { name, func }
end

-- Runs a random generation function
function CD2.MAPPROPGENERATOR:RunRandomGenerationFunction( type, pos )
    local typefunctions = self.cd2_generatefunctions[ type ]

    if !typefunctions then return end

    local generatefunction = typefunctions[ math.random( #typefunctions ) ]

    if !generatefunction then return end

    local ok, msg = pcall( function() generatefunction[ 2 ]( pos ) end )
    if !ok then ErrorNoHaltWithStack( "CD2 Map Props Generator had a error in the " .. generatefunction[ 1 ] .. " generation function", msg ) else CD2:DebugMessage( "CD2.MAPPROPGENERATOR Generated " .. generatefunction[ 1 ] ) end
end


CD2.MAPPROPGENERATOR:AddGenerateFunction( "Base 1", "cell", function( generatepos )

    for i = 1, math.random( 1, 5 ) do
        local pos = CD2:GetRandomPos( 500, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), "models/props_c17/concrete_barrier001a.mdl", true )
    end

    for i = 1, math.random( 1, 5 ) do
        local pos = CD2:GetRandomPos( 500, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), "models/props_c17/oildrum001_explosive.mdl", false )
    end
    
    local pos = CD2:GetRandomPos( 500, generatepos )
    local speaker = ents.Create( "cd2_speaker" )
    speaker:SetPos( pos )
    speaker:SetAngles( Angle( 0, math.random( -180, 180 ), 0 ) )
    speaker:Spawn()

    speaker.cd2_mpggenerated = true
    CD2.MAPPROPGENERATOR:InstallTick( speaker )

end )

CD2.MAPPROPGENERATOR:AddGenerateFunction( "Base 2", "cell", function( generatepos )

    for i = 1, math.random( 3, 5 ) do
        local pos = CD2:GetRandomPos( 500, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), "models/props_c17/concrete_barrier001a.mdl", true )
    end

    for i = 1, math.random( 1, 3 ) do
        local pos = CD2:GetRandomPos( 500, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), "models/props_c17/oildrum001_explosive.mdl", false )
    end

    local pos = CD2:GetRandomPos( 500, generatepos )
    CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), "models/props_vehicles/truck001a.mdl", false )

    local pos = CD2:GetRandomPos( 500, generatepos )

    local speaker = ents.Create( "cd2_speaker" )
    speaker:SetPos( pos )
    speaker:SetAngles( Angle( 0, math.random( -180, 180 ), 0 ) )
    speaker:Spawn()

    speaker.cd2_mpggenerated = true
    CD2.MAPPROPGENERATOR:InstallTick( speaker )

end )

CD2.MAPPROPGENERATOR:AddGenerateFunction( "Base 3", "cell", function( generatepos )

    for i = 1, math.random( 3, 7 ) do
        local pos = CD2:GetRandomPos( 1000, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), "models/props_c17/concrete_barrier001a.mdl", true )
    end

    for i = 1, math.random( 1, 5 ) do
        local pos = CD2:GetRandomPos( 1000, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), "models/props_c17/oildrum001_explosive.mdl", false )
    end

    local mdls = { "models/props_c17/furnituretable002a.mdl", "models/props_c17/furniturechair001a.mdl", "models/props_c17/furniturecouch002a.mdl", "models/props_c17/oildrum001.mdl" }

    for i = 1, math.random( 1, 5 ) do
        local pos = CD2:GetRandomPos( 1000, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), mdls[ math.random( #mdls ) ], false )
    end

    local pos = CD2:GetRandomPos( 1000, generatepos )

    local speaker = ents.Create( "cd2_speaker" )
    speaker:SetPos( pos )
    speaker:SetAngles( Angle( 0, math.random( -180, 180 ), 0 ) )
    speaker:Spawn()

    speaker.cd2_mpggenerated = true
    CD2.MAPPROPGENERATOR:InstallTick( speaker )

end )

CD2.MAPPROPGENERATOR:AddGenerateFunction( "Radio", "global", function( generatepos )
    local radio = ents.Create( "cd2_radio" )
    radio:SetPos( generatepos )
    radio:SetAngles( Angle( 0, math.random( -180, 180 ), 0 ) )
    radio:Spawn()
    radio.cd2_mpggenerated = true
    CD2.MAPPROPGENERATOR:InstallTick( radio )
end )

CD2.MAPPROPGENERATOR:AddGenerateFunction( "Furniture", "global", function( generatepos )
    local mdls = { "models/props_c17/furnituretable002a.mdl", "models/props_c17/furniturechair001a.mdl", "models/props_c17/furniturecouch002a.mdl", "models/props_junk/garbage256_composite002b.mdl", "models/props_junk/garbage256_composite001b.mdl" }

    for i = 1, math.random( 1, 5 ) do
        local pos = CD2:GetRandomPos( 500, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), mdls[ math.random( #mdls ) ], false )
    end
end )

CD2.MAPPROPGENERATOR:AddGenerateFunction( "Vehicles", "global", function( generatepos )
    local mdls = { "models/props_vehicles/car002a_physics.mdl", "models/props_vehicles/car002b_physics.mdl", "models/props_vehicles/car003a_physics.mdl", "models/props_vehicles/car003b_physics.mdl", "models/props_vehicles/car004a_physics.mdl", "models/props_vehicles/car005b_physics.mdl", "models/props_vehicles/carparts_axel01a.mdl", "models/props_vehicles/carparts_muffler01a.mdl", "models/props_vehicles/carparts_muffler01a.mdl", "models/props_vehicles/truck002a_cab.mdl" }

    for i = 1, math.random( 1, 8 ) do
        local pos = CD2:GetRandomPos( 100, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), mdls[ math.random( #mdls ) ], false )
    end
end )

CD2.MAPPROPGENERATOR:AddGenerateFunction( "Base 1", "agency", function( generatepos )

    for i = 1, math.random( 3, 5 ) do
        local pos = CD2:GetRandomPos( 500, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), "models/props_combine/combine_barricade_short01a.mdl", true )
    end

    local cache = ents.Create( "cd2_agencyweaponcache" )
    cache:SetPos( generatepos + Vector( 0, 0, 60 ) )
    cache:SetAngles( Angle( 0, math.random( -180, 180 ), 0 ) )
    cache:Spawn()
    cache:DropToFloor()

    cache.cd2_mpggenerated = true
    CD2.MAPPROPGENERATOR:InstallTick( cache )
end )

CD2.MAPPROPGENERATOR:AddGenerateFunction( "Base 2", "agency", function( generatepos )

    for i = 1, math.random( 3, 5 ) do
        local pos = CD2:GetRandomPos( 500, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), "models/props_combine/combine_barricade_short01a.mdl", true )
    end

    local pos = CD2:GetRandomPos( 500, generatepos )
    CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), "models/props_combine/combine_booth_short01a.mdl", true )
    

    for i = 1, 2 do
        local pos = CD2:GetRandomPos( 300, generatepos )
        local cache = ents.Create( "cd2_agencyweaponcache" )
        cache:SetPos( pos + Vector( 0, 0, 60 ) )
        cache:SetAngles( Angle( 0, math.random( -180, 180 ), 0 ) )
        cache:Spawn()
        cache:DropToFloor()

        cache.cd2_mpggenerated = true
        CD2.MAPPROPGENERATOR:InstallTick( cache )
    end
end )

CD2.MAPPROPGENERATOR:AddGenerateFunction( "Base 3", "agency", function( generatepos )

    for i = 1, math.random( 3, 5 ) do
        local pos = CD2:GetRandomPos( 1000, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), "models/props_combine/combine_barricade_short01a.mdl", true )
    end

    local mdls = { "models/props_combine/combine_booth_short01a.mdl", "models/props_combine/combine_booth_med01a.mdl", "models/props_combine/combine_barricade_med03b.mdl", "models/props_combine/combine_barricade_med02a.mdl" }
    
    for i = 1, math.random( 3, 5 ) do
        local pos = CD2:GetRandomPos( 1000, generatepos )
        CD2.MAPPROPGENERATOR:SpawnProp( pos, Angle( 0, math.random( -180, 180 ), 0 ), mdls[ math.random( #mdls ) ], true )
    end

    for i = 1, 2 do
        local pos = CD2:GetRandomPos( 500, generatepos )
        local cache = ents.Create( "cd2_agencyweaponcache" )
        cache:SetPos( pos + Vector( 0, 0, 60 ) )
        cache:SetAngles( Angle( 0, math.random( -180, 180 ), 0 ) )
        cache:Spawn()
        cache:DropToFloor()

        cache.cd2_mpggenerated = true
        CD2.MAPPROPGENERATOR:InstallTick( cache )
    end
end )

local bypass_players = {} -- List of players to not run MPG on
local freq = 0
hook.Add( "Tick", "crackdown2_mappropgeneration", function()
    if !navmesh.IsLoaded() or CD2_EmptyStreets or !GetGlobal2Bool( "cd2_MapDataLoaded", false ) then return end
    if ( game.SinglePlayer() or IsValid( Entity( 1 ) ) and Entity( 1 ):IsListenServerHost() ) and ( !IsValid( Entity( 1 ) ) or !Entity( 1 ):IsCD2Agent() or Entity( 1 ).cd2_InTutorial ) then return end
    if CurTime() < freq then return end

    for k, ply in ipairs( player.GetAll() ) do
        if !IsValid( ply ) or !ply:IsCD2Agent() or bypass_players[ ply ] and bypass_players[ ply ] < CurTime() then continue end
        local genpos = CD2:GetRandomPos( 2000, ply:GetPos() ) 

        -- Do not run MPG for this player for a short time if no nav is found.
        if genpos == vector_origin then 
            bypass_players[ ply ] = CurTime() + 6 
            continue 
        end

        local cangenerate = CD2.MAPPROPGENERATOR:CanGenerateAt( genpos )

        if cangenerate then
            CD2:DebugMessage( "CD2.MAPPROPGENERATOR is now determining what function to use near " .. ply:Name() )
            local generationtype = CD2.MAPPROPGENERATOR:DetermineGenerateType( genpos )
            CD2.MAPPROPGENERATOR:RunRandomGenerationFunction( generationtype, genpos )
        end

    end


    freq = CurTime() + 1
end )