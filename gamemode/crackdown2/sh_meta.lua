
local ENT = FindMetaTable( "Entity" )
local PLAYER = FindMetaTable( "Player" )

-- Returns if the entity is a Crackdown 2 NPC
function ENT:IsCD2NPC()
    return self.cd2_IsCD2NPC or false
end

-- Returns if the entity should always be able to be locked on
function ENT:AlwaysLockon()
    return self.cd2_AlwaysLockon or false
end

function ENT:IsCD2Agent()
    return false
end

function PLAYER:IsCD2Agent()
    return player_manager.GetPlayerClass( self ) == "cd2_player"
end

local Trace = util.TraceLine
local normaltrace = {}
function PLAYER:Trace( start, endpos, col, mask )
    normaltrace.start = start or self:EyePos()
    normaltrace.endpos = ( isentity( endpos ) and endpos:WorldSpaceCenter() or endpos )
    normaltrace.filter = self
    normaltrace.mask = mask or MASK_SOLID
    normaltrace.collisiongroup = col or COLLISION_GROUP_NONE
    local result = Trace( normaltrace )
    return result
end