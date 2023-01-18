local ipairs = ipairs
local IsValid = IsValid
local random = math.random

-- Simple function for creating coroutine threads easily
function CD2CreateThread( func )
    local thread = coroutine.create( func ) 
    hook.Add( "Think", "Crackdown2Thread_" .. tostring( func ), function() 
        if coroutine.status( thread ) != "dead" then
            local ok, msg = coroutine.resume( thread )
            if !ok then ErrorNoHaltWithStack( msg ) end
        else
            hook.Remove( "Think", "Crackdown2Thread_" .. tostring( func ) )
        end
    end )
end

function CD2DebugMessage( ... )
    if !GetConVar( "cd2_enableconsolemessages" ):GetBool() then return end
    print( "Crackdown 2 Console: ", ...)
end


-- Throws the specified equipment to the position. Owned by thrower
function CD2ThrowEquipment( class, thrower, pos )
    local grenade = ents.Create( class )
    grenade:SetPos( thrower:GetShootPos() )
    grenade:SetThrower( thrower ) 
    grenade:SetOwner( thrower )
    grenade:Spawn()

    grenade:ThrowTo( pos )
end


local FindByClass = ents.FindByClass
local table_Add = table.Add
function CD2GetPossibleSpawns()
    local info_player_starts = FindByClass( "info_player_start" )
    local info_player_teamspawns = FindByClass( "info_player_teamspawn" )
    local info_player_terrorist = FindByClass( "info_player_terrorist" )
    local info_player_counterterrorist = FindByClass( "info_player_counterterrorist" )
    local info_player_combine = FindByClass( "info_player_combine" )
    local info_player_rebel = FindByClass( "info_player_rebel" )
    local info_player_allies = FindByClass( "info_player_allies" )
    local info_player_axis = FindByClass( "info_player_axis" )
    local info_coop_spawn = FindByClass( "info_coop_spawn" )
    local info_survivor_position = FindByClass( "info_survivor_position" )


    table_Add( info_player_starts, info_player_teamspawns )
    table_Add( info_player_starts, info_player_terrorist )
    table_Add( info_player_starts, info_player_counterterrorist )
    table_Add( info_player_starts, info_player_combine )
    table_Add( info_player_starts, info_player_rebel )
    table_Add( info_player_starts, info_player_allies )
    table_Add( info_player_starts, info_player_axis )
    table_Add( info_player_starts, info_coop_spawn )
    table_Add( info_player_starts, info_survivor_position )
    return info_player_starts
end

-- Returns the closest spawn to the player
function CD2GetClosestSpawn( ply )
    local closest
    local dist
    local spawns = CD2GetPossibleSpawns()

    for k, v in ipairs( spawns ) do
        local range = ply:SqrRangeTo( v )
        if !closest then closest = v dist = range continue end

        if range < dist then
            closest = v 
            dist = range
        end
    end
    return closest
end

-- Returns a random CD2 weapon classname
function CD2GetRandomWeapon()
    local weps = {}

    for k, v in ipairs( weapons.GetList() ) do
        if weapons.IsBasedOn( v.ClassName, "cd2_weaponbase" ) then
            weps[ #weps + 1 ] = v.ClassName
        end
    end

    return weps[ random( #weps ) ]
end

-- Returns a random CD2 equipment classname
function CD2GetRandomEquipment()
    local equipment = {}

    for ClassName, tbl in pairs( scripted_ents.GetList() ) do
        if tbl.Base == "cd2_equipmentbase" then
            equipment[ #equipment + 1 ] = ClassName
        end
    end

    return equipment[ random( #equipment ) ]
end

-- Find in Sphere function with a filter function
local FindInSphere = ents.FindInSphere
function CD2FindInSphere( pos, radius, filter )
    local entities = {}
    local find = FindInSphere( pos, radius )

    for i = 1, #find do
        local v = find[ i ]
        if IsValid( v ) and ( !filter or filter( v ) == true ) then
            entities[ #entities + 1 ] = v
        end
    end
    return entities
end

-- Returns the closest entity in the table near target
function CD2GetClosestInTable( tbl, target )
    local closest
    local dist 
    for i = 1, #tbl do
        local v = tbl[ i ] 

        if !closest then closest = v dist = v:SqrRangeTo( target ) continue end
        
        if v:SqrRangeTo( target ) < dist then
            closest = v 
            dist = v:SqrRangeTo( target )
        end
    end
    return closest
end


-- Returns if ply can lock onto ent
function CD2CanLockOn( ply, ent )
    return ( ent:IsCD2NPC() or ent:IsPlayer() and ent:IsCD2Agent() ) and ent != ply and ( ent:GetCD2Team() != ply:GetCD2Team() and ent:GetCD2Team() != "civilian" ) or ent:AlwaysLockon() or false
end

local ents_FindInCone = ents.FindInCone
-- Finds targets that the ply can lock onto using their view
function CD2FindInLockableTragets( ply )
    local wep = ply:GetActiveWeapon()
    if !IsValid( wep ) then return {} end
    local entities = {}
    local cone = ents_FindInCone( CLIENT and CD2_vieworigin or ply:EyePos(), CLIENT and CD2_viewangles:Forward() or ply:EyeAngles():Forward(), ( wep.LockOnRange or 2000 ), 0.99 )

    for i = 1, #cone do
        local ent = cone[ i ]
        if CD2CanLockOn( ply, ent ) and ( CLIENT and ply:Trace( CD2_vieworigin, ent:WorldSpaceCenter() ).Entity == ent or SERVER and ply:Visible( ent ) ) then entities[ #entities + 1 ] = ent end
    end

    return entities
end

-- Removes all NPCs
function CD2ClearNPCS()
    local ents_ = ents.FindByClass( "cd2_*" )
    for i = 1, #ents_ do
        local v = ents_[ i ]
        if IsValid( v ) and v:IsCD2NPC() then v:Remove() end
    end
end

-- Function describes itself
function CD2CreateSkillGainOrb( pos, ply, skillname, xp, col )
    local orb = ents.Create( "cd2_skillgainorb" )
    orb:SetPos( pos )
    orb:SetPlayer( ply )
    orb:SetSkill( skillname or "nil" )
    orb:SetXP( xp or 0 )
    orb:SetTrailColor( col and col:ToVector() or Vector( 1, 1, 1 ) )
    orb:Spawn()
end

-- Creates a guide entity that spawns trailers that pathfinds from start to endpos
function CD2CreateGuide( start, endpos )
    local ent = ents.Create( "cd2_guidepather" )
    ent:SetPos( start )
    ent:SetGoalPosition( endpos )
    ent:Spawn()
    CD2DebugMessage( "Created Trailer Guide at ", start, " that ends at ", endpos  )
    return ent
end

-- Sends a message to a player's or all player's chat
function CD2SendText( ply, ... )
    net.Start( "cd2net_sendtext" )
    net.WriteString( util.TableToJSON( { ... } ) )
    if ply then
        net.Send( ply )
    else
        net.Broadcast()
    end
end

-- Takes three damage types from a NPC's damage log and calculates the skill orbs to give to players
local round = math.Round
local clamp = math.Clamp
local bit_band = bit.band

local weaponskillcolor = Color( 0, 225, 255)
local agilityskillcolor = Color( 0, 255, 0 )
local strengthskillcolor = Color( 255, 251, 0)
local explosiveskillcolor = Color( 0, 110, 255 )
function CD2AssessSkillGainOrbs( victimnpc, damagelog )
    if victimnpc.cd2_maxskillorbs == 0 then return end -- Do not run for npcs that don't allow skill orbs

    for steamid, dmgtbl in pairs( damagelog ) do
        local ply = player.GetBySteamID( steamid ) -- Get the damaging player
        if !IsValid( ply ) then continue end
        local maxskillorbs = victimnpc.cd2_maxskillorbs -- The max amount of skill orbs that can drop
        local remaining_orbs = maxskillorbs -- The remaining amount of skill orbs

        for dmgtype, damage in pairs( dmgtbl ) do
            -- Getting Damage Type damage
            local bulletdmg = bit_band( dmgtype, DMG_BULLET ) == DMG_BULLET and damage or nil
            local meleedmg = bit_band( dmgtype, DMG_CLUB ) == DMG_CLUB and damage or nil
            local explosivedmg = ( bit_band( dmgtype, DMG_BLAST ) == DMG_BLAST ) and damage or nil
            local agilitybonus = ( bit_band( dmgtype, DMG_FALL ) == DMG_FALL ) and damage or nil

            -- Getting the amount of damage types that have been dealt onto the npc
            local damagetypecount = 0
            if bulletdmg then damagetypecount = damagetypecount + 1 end
            if meleedmg then damagetypecount = damagetypecount + 1 end
            if explosivedmg then damagetypecount = damagetypecount + 1 end
            if agilitybonus then damagetypecount = damagetypecount + 1 end

            -- Calculating the orb counts --

            if agilitybonus and remaining_orbs != 0 then
                local orbcount = clamp( round( agilitybonus / ( victimnpc:GetMaxHealth() / ( maxskillorbs / damagetypecount ) ), 0 ), 0, maxskillorbs )
                for i = 1, orbcount do
                    if remaining_orbs <= 0 then break end
                    remaining_orbs = remaining_orbs - 1
                    CD2CreateSkillGainOrb( victimnpc:WorldSpaceCenter(), ply, "Agility", 2, agilityskillcolor )
                end
            end

            if bulletdmg and remaining_orbs != 0 then
                local orbcount = clamp( round( bulletdmg / ( victimnpc:GetMaxHealth() / ( maxskillorbs / damagetypecount ) ), 0 ), 0, maxskillorbs )
                for i = 1, orbcount do
                    if remaining_orbs <= 0 then break end
                    remaining_orbs = remaining_orbs - 1
                    CD2CreateSkillGainOrb( victimnpc:WorldSpaceCenter(), ply, "Weapon", 0.2, weaponskillcolor )
                end
            end

            if meleedmg and remaining_orbs != 0 then
                local orbcount = clamp( round( meleedmg / ( victimnpc:GetMaxHealth() / ( maxskillorbs / damagetypecount ) ), 0 ), 0, maxskillorbs )
                for i = 1, orbcount do
                    if remaining_orbs <= 0 then break end
                    remaining_orbs = remaining_orbs - 1
                    CD2CreateSkillGainOrb( victimnpc:WorldSpaceCenter(), ply, "Strength", 1, strengthskillcolor )
                end
            end

            if explosivedmg and remaining_orbs != 0 then
                local orbcount = clamp( round( explosivedmg / ( victimnpc:GetMaxHealth() / ( maxskillorbs / damagetypecount ) ), 0 ), 0, maxskillorbs )
                for i = 1, orbcount do
                    if remaining_orbs <= 0 then break end
                    remaining_orbs = remaining_orbs - 1
                    CD2CreateSkillGainOrb( victimnpc:WorldSpaceCenter(), ply, "Explosive", 0.4, explosiveskillcolor )
                end
            end

        end
    end
end
--

-- Sends a message to a player or players via the Text Box
function CD2SendTextBoxMessage( ply, text )
    net.Start( "cd2net_sendtextboxmessage" ) 
    net.WriteString( text )
    if !ply then 
        net.Broadcast() 
    else 
        net.Send( ply ) 
    end
end

local RandomPairs = RandomPairs
function CD2GetClosestNavAreas( pos, dist )
    local navareas = navmesh.GetAllNavAreas()
    local areas = {} 
    for i = 1, #navareas do
        local v = navareas[ i ]
        if IsValid( v ) and v:GetClosestPointOnArea( pos ):DistToSqr( pos ) <= ( dist * dist ) and !v:IsUnderwater() and v:GetSizeX() > 40 and v:GetSizeY() > 40 then
            areas[ #areas + 1 ] = v
        end
    end
    return areas
end

-- Returns a list of nav areas that are specifically filtered
function CD2GetNavmeshFiltered()
    local navareas = navmesh.GetAllNavAreas()
    local areas = {} 
    for i = 1, #navareas do
        local v = navareas[ i ]
        if IsValid( v ) and !v:IsUnderwater() and v:GetSizeX() > 40 and v:GetSizeY() > 40 then
            areas[ #areas + 1 ] = v
        end
    end
    return areas
end

local TraceHull = util.TraceHull
local hulltrace = {}

-- Returns a random position on the navmesh
function CD2GetRandomPos( dist, pos ) 
    local areas = dist and CD2GetClosestNavAreas( pos, dist ) or CD2GetNavmeshFiltered()
    
    for k, v in RandomPairs( areas ) do
        if IsValid( v ) then
            local spot = v:GetRandomPoint()
            hulltrace.start = spot
            hulltrace.endpos = spot
            hulltrace.maxs = Vector( 17, 17, 72 )
            hulltrace.mins = Vector( -17, -17, 0 )
            local result = TraceHull( hulltrace )
            if !result.Hit then return spot end
        end
    end
    return Vector()
end

if SERVER then
    -- Sets the text to type in the middle of the player's screen
    function CD2SetTypingText( ply, top, bottom, isred )
        net.Start( "cd2net_sendtypingtext" )
        net.WriteString( top )
        net.WriteString( bottom )
        net.WriteBool( isred or false )
        if !ply then net.Broadcast() else net.Send( ply ) end
    end

    -- Pings a location on a Player's minimap or intel console
    function CD2PingLocation( ply, pos, pingintelconsole )
        net.Start( "cd2net_pinglocation" )
        net.WriteVector( pos )
        net.WriteBool( pingintelconsole or false )
        if !ply then net.Broadcast() else net.Send( ply ) end
    end
end


-- Returns if the server is currently running Keys to the city mode
function KeysToTheCity()
    return GetConVar( "cd2_keystothecitymode" ):GetBool()
end

-- Returns if the map is the pacific city map
function InPacificCity()
    return game.GetMap() == "cd2_pacificcity_remap"
end

-- Quick test functions

function CD2QuickSpawnCellNPC()
    local ent = ents.Create( "cd2_smgcellsoldier" )
    ent:SetPos( Entity( 1 ):GetEyeTrace().HitPos )
    ent:Spawn()
end

function CD2QuickSpawnCivilianNPC()
    local ent = ents.Create( "cd2_civilian" )
    ent:SetPos( Entity( 1 ):GetEyeTrace().HitPos )
    ent:Spawn()
end

function CD2QuickSpawnPeaceKeeperNPC()
    local ent = ents.Create( "cd2_peacekeeper" )
    ent:SetPos( Entity( 1 ):GetEyeTrace().HitPos )
    ent:Spawn()
end

function CD2QuickSpawnFreakNPC()
    local ent = ents.Create( "cd2_freak" )
    ent:SetPos( Entity( 1 ):GetEyeTrace().HitPos )
    ent:Spawn()
end

function Cpos()
    return Entity( 1 ):GetEyeTrace().HitPos
end

function Ctrace()
    return Entity( 1 ):GetEyeTrace().Entity
end

--