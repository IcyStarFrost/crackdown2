
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

function PLAYER:HandsPos()
    local attach = self:GetAttachment( self:LookupAttachment( "anim_attachment_RH") )
    return attach.Pos
end

function PLAYER:HandsAngles()
    local attach = self:GetAttachment( self:LookupAttachment( "anim_attachment_RH") )
    return attach.Ang
end

function PLAYER:StartLevelUpEffect()


    
    net.Start( "cd2net_playerlevelupeffect" )
    net.WriteEntity( self ) 
    net.Broadcast()

    BroadcastLua( "Entity( " .. self:EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_GMOD_GESTURE_BOW, true )" )
    
    CD2CreateThread( function()
        coroutine.wait( 1 )
        if !IsValid( self ) then return end
        BroadcastLua( "Entity( " .. self:EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_GMOD_GESTURE_TAUNT_ZOMBIE, true )" )

        local near = CD2FindInSphere( self:GetPos(), 200, function( ent ) return ent != self end )

        for i = 1, #near do
            local ent = near[ i ]
            if !IsValid( ent ) then return end
            local force = ent:IsCD2NPC() and 20000 or IsValid( hitphys ) and hitphys:GetMass() * 10 or 20000
            local info = DamageInfo()
            info:SetAttacker( self )
            info:SetDamage( 100 )
            info:SetDamageType( DMG_CLUB + DMG_BLAST + DMG_BULLET )
            info:SetDamageForce( ( ent:WorldSpaceCenter() - self:GetPos() ):GetNormalized() * force )
            info:SetDamagePosition( self:GetPos() )
            ent:TakeDamageInfo( info )
        end
    end )

    
    CD2CreateThread( function()

        self:Freeze( true )

        coroutine.wait( 3.5 )
        if !IsValid( self ) then return end
        

        self:Freeze( false )

    end )

    CD2CreateThread( function()
        if !IsValid( self ) then return end

        for i = 1, 50 do
            if !IsValid( self ) then return end

            local trailer = ents.Create( "cd2_respawntrail" )
            trailer:SetPos( self:WorldSpaceCenter() + VectorRand( -150, 150 ) )
            trailer:SetPlayer( self )
            trailer:Spawn()

            coroutine.wait( 0.01 )
        end
    
    end )
end