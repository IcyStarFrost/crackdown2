
local ENT = FindMetaTable( "Entity" )
local PLAYER = FindMetaTable( "Player" )

-- Returns if the entity is a Crackdown 2 NPC
function ENT:IsCD2NPC()
    return self.cd2_IsCD2NPC or false
end

-- Returns if the entity should always be able to be locked on
function ENT:AlwaysLockon()
    return self.cd2_AlwaysLockon or self:GetNW2Bool( "cd2_alwayslockon", false ) or false
end

function ENT:IsCD2Agent()
    return false
end

-- Returns the entity's Eye Pos. You can't override Nextbot's eyepos function so we are using this function to substitute it for NPCs and players
function ENT:CD2EyePos()
    return ( self:IsCD2NPC() and self:EyePos2() ) or ( ( self:IsPlayer() or self:IsNPC() ) and self:EyePos() )
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


function PLAYER:SaveProgress()

    CD2FILESYSTEM:WritePlayerData( self, "cd2_skill_Agility", self:GetAgilitySkill() )
    CD2FILESYSTEM:WritePlayerData( self, "cd2_skill_Weapon", self:GetWeaponSkill() )
    CD2FILESYSTEM:WritePlayerData( self, "cd2_skill_Strength", self:GetStrengthSkill() )
    CD2FILESYSTEM:WritePlayerData( self, "cd2_skill_Explosive", self:GetExplosiveSkill() )

    CD2FILESYSTEM:WritePlayerData( self, "cd2_skillxp_Agility", self:GetAgilityXP() )
    CD2FILESYSTEM:WritePlayerData( self, "cd2_skillxp_Weapon", self:GetWeaponXP() )
    CD2FILESYSTEM:WritePlayerData( self, "cd2_skillxp_Strength", self:GetStrengthXP() )
    CD2FILESYSTEM:WritePlayerData( self, "cd2_skillxp_Explosive", self:GetExplosiveXP() )

end

function PLAYER:LoadProgress()
    local wait = true
    CD2CreateThread( function()

        -- Skills
        CD2FILESYSTEM:RequestPlayerData( self, "cd2_skill_Agility", function( value ) if value then self:SetAgilitySkill( value ) end wait = false end )

        while wait do coroutine.yield() end

        wait = true

        CD2FILESYSTEM:RequestPlayerData( self, "cd2_skill_Weapon", function( value ) if value then self:SetWeaponSkill( value ) end wait = false end )

        while wait do coroutine.yield() end

        wait = true

        CD2FILESYSTEM:RequestPlayerData( self, "cd2_skill_Strength", function( value ) if value then self:SetStrengthSkill( value ) end wait = false end )

        while wait do coroutine.yield() end

        wait = true

        CD2FILESYSTEM:RequestPlayerData( self, "cd2_skill_Explosive", function( value ) if value then self:SetExplosiveSkill( value ) end wait = false end )

        while wait do coroutine.yield() end

        wait = true

        -- XP
        CD2FILESYSTEM:RequestPlayerData( self, "cd2_skillxp_Agility", function( value ) if value then self:SetAgilityXP( value ) end wait = false end )

        while wait do coroutine.yield() end

        wait = true

        CD2FILESYSTEM:RequestPlayerData( self, "cd2_skillxp_Weapon", function( value ) if value then self:SetWeaponXP( value ) end wait = false end )

        while wait do coroutine.yield() end

        wait = true

        CD2FILESYSTEM:RequestPlayerData( self, "cd2_skillxp_Strength", function( value ) if value then self:SetStrengthXP( value ) end wait = false end )

        while wait do coroutine.yield() end

        wait = true

        CD2FILESYSTEM:RequestPlayerData( self, "cd2_skillxp_Explosive", function( value ) if value then self:SetExplosiveXP( value ) end wait = false end )

        while wait do coroutine.yield() end
        self:BuildSkills()

    end )
end

function PLAYER:Stun( force )
    self:SetPos( self:GetPos() + Vector( 0, 0, 2 ) )
    self:SetVelocity( force / 40 )
    self:SetIsStunned( true )
end


function PLAYER:BuildSkills()
    local strength = self:GetStrengthSkill()
    local firearm = self:GetWeaponSkill()
    local agility = self:GetAgilitySkill()
    local explosive = self:GetExplosiveSkill()

    self:SetMeleeDamage( 25 * strength )
    self:SetMaxPickupWeight( 200 * strength )

    self:SetHealth( 100 * strength )
    self:SetMaxHealth( 100 * strength )

    self:SetSafeFallSpeed( 40 * agility )
    self:SetJumpPower( 400 + ( agility > 1 and 50 * agility or 0 ) )
    self:SetWalkSpeed( 200 + ( agility > 1 and 50 * agility or 0 ) )
    self:SetRunSpeed( 400 + ( agility > 1 and 50 * agility or 0 ) )
end