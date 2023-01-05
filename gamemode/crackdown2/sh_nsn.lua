local random = math.random
local rand = math.Rand
local IsValid = IsValid
local table_remove = table.remove
local RandomPairs = RandomPairs

if SERVER then
    -- Setting up the npc limits
    CD2_SpawnedNSNNpcs = CD2_SpawnedNSNNpcs or {}

    CD2_MaxCivilians = 15
    CD2_MaxCell = 2
    CD2_MaxPeaceKeepers = 2
    CD2_MaxFreaks = 15

    CD2_NextCivilianSpawn = CurTime() + 1
    CD2_NextFreakSpawn = CurTime() + 1
    CD2_NextCellSpawn = CurTime() + rand( 1, 25 )
    CD2_NextPeaceKeeperSpawn = CurTime() + rand( 1, 30 )
    local limitfreakkill = false

    for i = 1, #CD2_SpawnedNSNNpcs do
        local npc = CD2_SpawnedNSNNpcs[ i ]
        if IsValid( npc ) then npc:Remove() end
    end


    -- Functions for getting npc counts
    local function GetCivilianCount()
        return #ents.FindByClass( "cd2_civilian" )
    end

    local function GetCellCount()
        local enttbl = ents.GetAll() 
        local count = 0
        for i = 1, #enttbl do
            local ent = enttbl[ i ]
            if IsValid( ent ) and ent:IsCD2NPC() and ent:GetCD2Team() == "cell" then
                count = count + 1
            end
        end
        return count
    end

    local function GetFreaks()
        local enttbl = ents.GetAll() 
        local tbl = {}
        for i = 1, #enttbl do
            local ent = enttbl[ i ]
            if IsValid( ent ) and ent:IsCD2NPC() and ent:GetCD2Team() == "freak" then
                tbl[ #tbl + 1 ] = ent
            end
        end
        return tbl
    end

    local function GetPeaceKeeperCount()
        local enttbl = ents.GetAll() 
        local count = 0
        for i = 1, #enttbl do
            local ent = enttbl[ i ]
            if IsValid( ent ) and ent:IsCD2NPC() and ent:GetCD2Team() == "agency" then
                count = count + 1
            end
        end
        return count
    end
    --

    -- Returns a random player
    local function GetRandomPlayer()
        local players = player.GetAll()
        for i = 1, #players do
            local ply = players[ i ]
            if ply:IsCD2Agent() then return ply end
        end
    end

    -- Returns a table of filtered nav areas around a position
    local function GetNavAreasNear( pos, radius )
        local navareas = navmesh.GetAllNavAreas()
        local foundareas = {}
        for i = 1, #navareas do
            local nav = navareas[ i ]
            if IsValid( nav ) and nav:GetSizeX() > 20 and nav:GetSizeY() > 20 and !nav:IsUnderwater() and ( pos:DistToSqr( nav:GetClosestPointOnArea( pos ) ) < ( radius * radius ) and pos:DistToSqr( nav:GetClosestPointOnArea( pos ) ) > ( ( radius / 3 ) * ( radius / 3 ) ) )  then 
                foundareas[ #foundareas + 1 ] = nav 
            end
        end
        return foundareas
    end

    local function SpawnNPC( pos, class, ply )
        if !IsValid( ply ) then return end
        
        if !pos then
            local areas = GetNavAreasNear( ply:GetPos(), 3000 )
            local area = areas[ random( #areas ) ]
            if !IsValid( area ) then return end
            pos = area:GetRandomPoint()
        end

        local npc = ents.Create( class )
        npc:SetPos( pos )
        npc:SetAngles( Angle( 0, random( -180, 180 ), 0 ) )
        CD2_SpawnedNSNNpcs[ #CD2_SpawnedNSNNpcs + 1 ] = npc
        npc:Spawn()
        return npc
    end

    hook.Add( "OnCD2NPCKilled", "crackdown2_removefromnsntable", function( ent, info )
        for i = 1, #CD2_SpawnedNSNNpcs do
            local npc = CD2_SpawnedNSNNpcs[ i ]
            if npc == ent then table_remove( CD2_SpawnedNSNNpcs, i ) break end
        end
    end )

    hook.Add( "Tick", "crackdown2_naturalspawningnpcs", function()
        CD2_MaxCivilians = CD2IsDay() and 15 or !CD2IsDay() and 6


        -- Civilians --
        if GetCivilianCount() < CD2_MaxCivilians and CurTime() > CD2_NextCivilianSpawn then
            SpawnNPC( nil, "cd2_civilian", GetRandomPlayer() )
            CD2_NextCivilianSpawn = CD2IsDay() and CurTime() + 1 or !CD2IsDay() and CurTime() + 4
        end
        --

        -- Cell --
            if GetCellCount() < CD2_MaxCell and CurTime() > CD2_NextCellSpawn then
                local lead = SpawnNPC( nil, "cd2_smgcellsoldier", GetRandomPlayer() )

                if IsValid( lead ) and GetCellCount() < CD2_MaxCell then
                    SpawnNPC( lead:GetPos() + Vector( random( -80, 80 ), random( -80, 80 ), 0 ), "cd2_shotguncellsoldier", GetRandomPlayer() )
                end

                CD2_NextCellSpawn = CurTime() + rand( 1, 25 )
            end
        --
        
        -- PeaceKeepers --
        if GetPeaceKeeperCount() < CD2_MaxPeaceKeepers and CurTime() > CD2_NextPeaceKeeperSpawn then
            local lead = SpawnNPC( nil, "cd2_peacekeeper", GetRandomPlayer() )

            if IsValid( lead ) and GetPeaceKeeperCount() < CD2_MaxPeaceKeepers then
                SpawnNPC( lead:GetPos() + Vector( random( -80, 80 ), random( -80, 80 ), 0 ), "cd2_peacekeeper", GetRandomPlayer() )
            end

            CD2_NextPeaceKeeperSpawn = CurTime() + rand( 1, 30 )
        end
        --

        -- Freaks --
        if !CD2IsDay() and #GetFreaks() < CD2_MaxFreaks and CurTime() > CD2_NextFreakSpawn then
            SpawnNPC( nil, "cd2_freak", GetRandomPlayer() )
            limitfreakkill = false
            CD2_NextFreakSpawn = CurTime() + rand( 0.1, 3 )
        elseif CD2IsDay() and !limitfreakkill then

            CD2CreateThread( function()
                coroutine.wait( 3 )
                local freaks = GetFreaks()
                for i = 1, #freaks do
                    local ent = freaks[ i ]
                    if IsValid( ent ) and ent:IsCD2NPC() and ent:GetCD2Team() == "freak" then
                        ent:TakeDamage( ent:GetMaxHealth() + 1, Entity( 0 ) )
                    end
                    coroutine.wait( 0.1 )
                end
            end )

            limitfreakkill = true
        end
        --
    
    end )

end