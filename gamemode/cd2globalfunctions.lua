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
    print( "Crackdown 2 Console: ", ...)
end


-- Returns if ply can lock onto ent
function CD2CanLockOn( ply, ent )
    return ( ent:IsCD2NPC() or ent:IsPlayer() and ent:IsCD2Agent() ) and ent != ply and ( ent:GetCD2Team() != ply:GetCD2Team() and ent:GetCD2Team() != "civilian" ) or ent:AlwaysLockon() or false
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
        if !closest then closest = v dist = ply:GetPos():DistToSqr( v:GetPos() ) continue end

        if ply:GetPos():DistToSqr( v:GetPos() ) < dist then
            closest = v 
            dist = ply:GetPos():DistToSqr( v:GetPos() )
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

-- Find in Sphere function with a filter function
local FindInSphere = ents.FindInSphere
function CD2FindInSphere( pos, radius, filter )
    local entities = {}

    for k, v in ipairs( FindInSphere( pos, radius ) ) do
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
    for k, v in ipairs( tbl ) do 
        if !closest then closest = v dist = v:GetPos():DistToSqr( target:GetPos() ) continue end
        if v:GetPos():DistToSqr( target:GetPos() ) < dist then
            closest = v 
            dist = v:GetPos():DistToSqr( target:GetPos() )
        end
    end
    return closest
end

local ents_FindInCone = ents.FindInCone
-- Finds targets that the ply can lock onto using their view
function CD2FindInLockableTragets( ply )
    local wep = ply:GetActiveWeapon()
    if !IsValid( wep ) then return {} end
    local entities = {}
    local cone = ents_FindInCone( CLIENT and CD2_vieworigin or ply:EyePos(), CLIENT and CD2_viewangles:Forward() or ply:EyeAngles():Forward(), wep.LockOnRange, 0.99 )

    for k, v in ipairs( cone ) do
        if CD2CanLockOn( ply, v ) and ( CLIENT and ply:Trace( CD2_vieworigin, v:WorldSpaceCenter() ).Entity == v or SERVER and ply:Visible( v ) ) then entities[ #entities + 1 ] = v end
    end

    return entities
end

-- Removes all NPCs
function CD2ClearNPCS()
    for k, v in ipairs( ents.GetAll() ) do
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

            -- Getting the amount of damage types that have been dealt onto the npc
            local damagetypecount = 0
            if bulletdmg then damagetypecount = damagetypecount + 1 end
            if meleedmg then damagetypecount = damagetypecount + 1 end
            if explosivedmg then damagetypecount = damagetypecount + 1 end

            -- Calculating the orb counts --
            if bulletdmg and remaining_orbs != 0 then
                local orbcount = clamp( round( bulletdmg / ( victimnpc:GetMaxHealth() / ( maxskillorbs / damagetypecount ) ), 0 ), 0, maxskillorbs )
                for i = 1, orbcount do
                    if remaining_orbs <= 0 then break end
                    remaining_orbs = remaining_orbs - 1
                    CD2CreateSkillGainOrb( victimnpc:WorldSpaceCenter(), ply, "weapon", 0, weaponskillcolor )
                end
            end

            if meleedmg and remaining_orbs != 0 then
                local orbcount = clamp( round( meleedmg / ( victimnpc:GetMaxHealth() / ( maxskillorbs / damagetypecount ) ), 0 ), 0, maxskillorbs )
                for i = 1, orbcount do
                    if remaining_orbs <= 0 then break end
                    remaining_orbs = remaining_orbs - 1
                    CD2CreateSkillGainOrb( victimnpc:WorldSpaceCenter(), ply, "strength", 0, strengthskillcolor )
                end
            end

            if explosivedmg and remaining_orbs != 0 then
                local orbcount = clamp( round( explosivedmg / ( victimnpc:GetMaxHealth() / ( maxskillorbs / damagetypecount ) ), 0 ), 0, maxskillorbs )
                for i = 1, orbcount do
                    if remaining_orbs <= 0 then break end
                    remaining_orbs = remaining_orbs - 1
                    CD2CreateSkillGainOrb( victimnpc:WorldSpaceCenter(), ply, "explosive", 0, explosiveskillcolor )
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

function Cpos()
    return Entity( 1 ):GetEyeTrace().HitPos
end

function Ctrace()
    return Entity( 1 ):GetEyeTrace().Entity
end

--