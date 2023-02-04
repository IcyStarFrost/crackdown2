AddCSLuaFile()

local IsValid = IsValid
local Trace = util.TraceLine
local table_insert = table.insert
local math_max = math.max
local ipairs = ipairs
local clamp = math.Clamp
local random = math.random
local vistrace = {}
local normaltrace = {}

-- Fires our current weapon
function ENT:FireWeapon()
    local wep = self:GetActiveWeapon()
    if !IsValid( wep ) then return end
    wep:PrimaryAttack()
end

-- Simple trace function
function ENT:Trace( start, endpos, col, mask )
    normaltrace.start = start or self:EyePos2()
    normaltrace.endpos = ( isentity( endpos ) and endpos:WorldSpaceCenter() or endpos )
    normaltrace.filter = self
    normaltrace.mask = mask or MASK_SOLID
    normaltrace.collisiongroup = col or COLLISION_GROUP_NONE
    local result = Trace( normaltrace )
    return result
end

-- Look at a entity or position
function ENT:LookTo( target, endtime )
    self.cd2_facetarget = target
    self.cd2_faceend = endtime and CurTime() + endtime or nil
end

-- Move to position function
function ENT:MoveToPos( pos, options )
    if !pos then return end
    self.cd2_MoveGoal = pos

	local options = options or {}

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, ( isentity( self.cd2_MoveGoal ) and self.cd2_MoveGoal:GetPos() or self.cd2_MoveGoal ) )


	if !path:IsValid() then
        coroutine.wait( 1 )
        return "failed" 
    end

    self:SetIsMoving( true )

	while path:IsValid() do
        if self.cd2_stopmovement then self.cd2_stopmovement = nil self:SetIsMoving( false ) break end

        if !self:GetIsDisabled() then
		    path:Update( self )
            self:DoorCheck()
        end

        

        if GetConVar( "cd2_drawpathfinding" ):GetBool() then
            path:Draw()
        end

        if self.cd2_RecomputeMove then path:Compute( self, ( isentity( self.cd2_MoveGoal ) and self.cd2_MoveGoal:GetPos() or self.cd2_MoveGoal ) ) end
        
		if self.loco:IsStuck() then
            self.loco:Jump()
			self:HandleStuck()
			return "stuck"
		end

		if options.updatetime then
            local pathtime = math_max( options.updatetime, options.updatetime * ( path:GetLength() / 400 ) )
			if path:GetAge() > pathtime then path:Compute( self, ( isentity( self.cd2_MoveGoal ) and self.cd2_MoveGoal:GetPos() or self.cd2_MoveGoal ) ) end
		end

		coroutine.yield()

	end

    self:SetIsMoving( false ) 

	return "ok"

end

-- Returns if we can attack the entity or not
function ENT:CanAttack( ent )
    return ( ( ent:IsCD2NPC() or ent:IsCD2Agent() and !ent.cd2_notarget ) and ent:GetCD2Team() != self:GetCD2Team() ) and self:CanSee( ent )
end

-- Shared function of GetRangeSquaredTo()
function ENT:GetSquaredRangeTo( pos )
    return isentity( pos ) and self:GetPos():DistToSqr( pos:GetPos() ) or self:GetPos():DistToSqr( pos )
end

-- Returns if we can the entity
function ENT:CanSee( ent )
    if self:GetSquaredRangeTo( ent ) > ( self.cd2_SightDistance * self.cd2_SightDistance ) then return false end -- Distance check

    -- "FOV" check
    local norm = ( ent:GetPos() - self:GetPos() ):GetNormalized()
    local dot = norm:Dot( self:GetForward() )

    if dot < 0.4 then return false end

    -- Finally tracing out sight line
    vistrace.start = self:EyePos2()
    vistrace.endpos = ent:WorldSpaceCenter()
    vistrace.filter = self
    local result = Trace( vistrace )

    return result.Entity == ent
end

-- Checks for any entities we can attack and returns the closest
function ENT:CheckSightLine()
    local near = CD2FindInSphere( self:GetPos(), self.cd2_SightDistance, function( ent ) return self:CanAttack( ent ) end )
    return CD2GetClosestInTable( near, self )
end

-- Changes the movement goal position or entity
function ENT:SetMoveGoal( pos )
    self.cd2_MoveGoal = pos
end

-- Recomputes our current path
function ENT:RecomputePath()
    self.cd2_RecomputeMove = self:GetIsMoving()
end

-- Stops any current movement
function ENT:StopMovement()
    self.cd2_stopmovement = self:GetIsMoving()
end

-- Returns our weapon entity
function ENT:GetActiveWeapon()
    return self:GetWeaponEntity()
end

-- Returns our hand pos
function ENT:HandsPos()
    local attach = self:GetAttachment( self:LookupAttachment( "anim_attachment_RH") )
    return attach.Pos
end

-- Returns our hand Angles
function ENT:HandsAngles()
    local attach = self:GetAttachment( self:LookupAttachment( "anim_attachment_RH") )
    return attach.Ang
end

-- Makes the npc drop their weapons and equipment
function ENT:DropWeapons()
    local wep = self:GetActiveWeapon()
    if IsValid( wep ) then

        wep.cd2_Ammocount = clamp( random( 1, wep.Primary.DefaultClip ), 0, wep.Primary.DefaultClip )
        wep:SetOwner( nil )
        wep:SetParent()
        wep:SetPos( self:HandsPos() )
        wep:SetAngles( self:HandsAngles() )
        wep:PhysWake()

        local phys = wep:GetPhysicsObject()

        if IsValid( phys ) then
            phys:ApplyForceCenter( Vector( random( -600, 600 ), random( -600, 600 ), random( 0, 600 ) ) )
        end
    end

    if self.cd2_Equipment and self.cd2_Equipment != "none" then
        local equipment = ents.Create( self.cd2_Equipment )
        equipment:SetPos( self:WorldSpaceCenter() )
        equipment:Spawn()

        local phys = equipment:GetPhysicsObject()

        if IsValid( phys ) then
            phys:ApplyForceCenter( Vector( random( -8000, 8000 ), random( -8000, 8000 ), random( 0, 8000 ) ) )
        end
    end
end

-- Gives the specified weapon classname to the npc
function ENT:Give( classname ) 
    if !classname then return end
    local wep = ents.Create( classname )
    if !IsValid( wep ) then return end
    wep:SetPos( self:GetPos() )
    wep:AddEffects( EF_BONEMERGE )
    wep:SetParent( self )
    wep:SetOwner( self )
    wep:Spawn()

    wep:SetMoveType( MOVETYPE_NONE )
    wep:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

    wep:Equip( self )
    wep:SetClip1( wep:GetMaxClip1() )
    self:SetWeaponEntity( wep )
end

-- Returns the position our bullets come from
function ENT:GetShootPos()
    if !IsValid( self:GetActiveWeapon() ) then return self:WorldSpaceCenter() end
    local muzzle = self:GetActiveWeapon():LookupAttachment( "muzzle" )
    if muzzle == 0 then return self:GetActiveWeapon():GetPos() end
    local attach = self:GetActiveWeapon():GetAttachment( muzzle )
    return attach.Pos
end

-- Returns our Eyes position
function ENT:EyePos2()
    local lookup = self:LookupAttachment( "eyes" )
    if lookup <= 0 then return self:WorldSpaceCenter() + Vector( 0, 0, 5 ) end
    return self:GetAttachment( lookup ).Pos
end

-- Returns where we are "aiming"
function ENT:GetAimVector()
    if IsValid( self:GetEnemy() ) then
        return ( self:GetEnemy():WorldSpaceCenter() - self:GetShootPos() ):GetNormalized()
    else
        return self:GetForward()
    end
end

-- Starts a simple timer
function ENT:SimpleTimer( time, func )
    timer.Simple( time, function() 
        if !IsValid( self ) then return end
        func()
    end )
end

-- Adds a hook
function ENT:Hook( hookname, uniquename, func )
    local id = self:EntIndex()
    hook.Add( hookname, "crackdown2NPC_" .. uniquename .. "_" .. id, function( ... )
        if !IsValid( self ) then hook.Remove( hookname, "crackdown2NPC_" .. uniquename .. "_" .. id ) return end
        local result = func( ... )
        if result == "end" then hook.Remove( hookname, "crackdown2NPC_" .. uniquename .. "_" .. id ) return end
        return result
    end )
    if !self:HookExists( hookname, uniquename ) then table_insert( self.cd2_Hooks, { hookname, "crackdown2NPC_" .. uniquename .. "_" .. id } ) end
end

-- Returns if a hook exists
function ENT:HookExists( hookname, uniquename )
    local id = self:EntIndex()
    for k, v in ipairs( self.cd2_Hooks ) do
        if v[ 1 ] == hookname and v[ 2 ] == "crackdown2NPC_" .. uniquename .. "_" .. id then return true end
    end
    return false
end

-- Removes all hooks currently set
function ENT:RemoveAllHooks()
    for k, v in ipairs( self.cd2_Hooks ) do
        hook.Remove( v[ 1 ], v[ 2 ] )
    end
end

-- Removes a hook
function ENT:RemoveHook( hookname, uniquename )
    hook.Remove( v, "crackdown2NPC_" .. uniquename .. "_" .. id )
end

-- Makes the NPC approach the position for the duration of time
function ENT:Approach( pos, time )
    time = time and CurTime() + time or CurTime() + 1
    self:Hook( "Tick", "approachposition", function()
        if CurTime() > time then return "end" end
        self.loco:Approach( pos, 99 )
    end )
end

local ents_FindByName = ents.FindByName
local tracetable = {}
local doorClasses = {
    ["prop_door_rotating"] = true,
    ["func_door"] = true,
    ["func_door_rotating"] = true
}

-- Fires a trace in front of the npc that will open doors if it hits a door
function ENT:DoorCheck()
    if CurTime() < self.cd2_NextDoorCheck then return end

    tracetable.start = self:WorldSpaceCenter()
    tracetable.endpos = ( tracetable.start + self:GetForward() * 50 )
    tracetable.filter = self
    
    local ent = Trace( tracetable ).Entity
    if IsValid( ent ) then
        local class = ent:GetClass()
        if doorClasses[ class ] and ent.Fire then

            -- Back up when opening a door
            if ent:GetInternalVariable( "m_eDoorState" ) != 0 or ent:GetInternalVariable( "m_toggle_state" ) != 0 then
                self:Approach( self:GetPos() - self:GetForward() * 50, 0.8 )
            end

            if class == "prop_door_rotating" then
                ent:Fire( "OpenAwayFrom", "!activator", 0, self )
                local keys = ent:GetKeyValues()
                local slaveDoor = ents_FindByName( keys.slavename )
                if IsValid( slaveDoor ) then slaveDoor:Fire( "OpenAwayFrom", "!activator", 0, self ) end
            else
                ent:Fire( "Open" )
            end
        end
    end

    self.cd2_NextDoorCheck = CurTime() + 0.2
end

-- Returns a table of nav areas close to the position within a distance
local function GetClosestNavAreas( pos, dist )
    local areas = {} 
    for k, v in ipairs( navmesh.GetAllNavAreas() ) do
        if IsValid( v ) and v:GetClosestPointOnArea( pos ):DistToSqr( pos ) <= ( dist * dist ) then
            areas[ #areas + 1 ] = v
        end
    end
    return areas
end

-- Returns a list of nav areas that are specifically filtered
local function GetNavmeshFiltered()
    local areas = {} 
    for k, v in ipairs( navmesh.GetAllNavAreas() ) do
        if IsValid( v ) and !v:IsUnderwater() and v:GetSizeX() > 40 and v:GetSizeY() > 40 then
            areas[ #areas + 1 ] = v
        end
    end
    return areas
end

-- Returns a random position on the navmesh
function ENT:GetRandomPos( dist ) 
    local areas = dist and GetClosestNavAreas( self:GetPos(), dist ) or GetNavmeshFiltered()


    for k, v in RandomPairs( areas ) do
        if IsValid( v ) then
            return v:GetRandomPoint()
        end
    end
end

-- Returns if we can speak
function ENT:CanSpeak()
    return CurTime() > self.cd2_NextSpeak
end

-- Simple function for playing Voice lines
function ENT:PlayVoiceSound( path, timeadd, bypasstime )
    if !self:CanSpeak() and !bypasstime then return end
    timeadd = timeadd or 0
    self:EmitSound( path, 70, 100, 1, CHAN_VOICE )
    self.cd2_NextSpeak = CurTime() + SoundDuration( path ) + timeadd
end

-- Simple function for playing pain sounds
function ENT:PlayPainSound( path )
    if CurTime() < self.cd2_NextPainSound then return end
    self:EmitSound( path, 70, 100, 1, CHAN_VOICE )
    self.cd2_NextPainSound = CurTime() + SoundDuration( path )
end

-- Checks if we should be removed if we aren't within a Player's PVS
function ENT:VisCheck()
    local players = player.GetAll()
    local withinPVS = false
    for i = 1, #players do
        local ply = players[ i ]
        if ply:IsCD2Agent() and self:GetRangeSquaredTo( ply ) < ( 3000 * 3000 ) then withinPVS = true end
    end
    if !withinPVS then self:Remove() end
end