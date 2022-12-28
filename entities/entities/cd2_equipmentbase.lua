AddCSLuaFile()

ENT.Base = "base_anim"
ENT.WorldModel = "models/weapons/w_grenade.mdl"
ENT.PrintName = "Equipment"

-- Equipment settings
ENT.Cooldown = 3 -- The time before the grenade can be used again
ENT.MaxGrenadeCount = 8 -- The amount of grenades a player can have
ENT.TrailColor = color_white -- The trail color
ENT.DelayTime = 3 -- The time before the grenade blows up. 0 for no timed explosive
ENT.TickSound = nil -- The sound that will play as the grenade ticks
--

-- Util vars
ENT.NextTickSound = 0 -- Then next time the tick sound will play
ENT.Exploded = false -- If the grenade exploded or not

local clamp = math.Clamp
local max = math.max
local IsValid = IsValid
local util_SpriteTrail = util.SpriteTrail

function ENT:Initialize()
    self.DelayCurTime = CurTime() + self.DelayTime
    
    if CLIENT then return end
    self:SetModel( self.WorldModel )

    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:PhysWake()

    local phys = self:GetPhysicsObject()

    if IsValid( phys ) then phys:SetMass( 100 ) end

    if SERVER then
        util_SpriteTrail( self, 0, self.TrailColor, true, 5, 0, 2, 1 / ( 5 + 0 ) * 0.5, "trails/laser" )
    end
end

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Thrower" )
end

-- Explosion code here
function ENT:OnDelayEnd()
end

-- Make the equipment bounce less
function ENT:PhysicsCollide( data, phys )
    phys:SetVelocity( data.OurNewVelocity / 2)
end

-- Function for simply throwing the equipment near a certain position
function ENT:ThrowTo( pos )
    local phys = self:GetPhysicsObject()
    local dist = clamp( self:GetPos():Distance( pos ) * 150, 0, 100000 )

    local arc = ( ( LerpVector( 0.5, self:GetPos(), pos ) + Vector( 0, 0, 100 ) ) - self:GetPos() ):GetNormalized()
    if IsValid( phys ) then
        phys:ApplyForceCenter( arc * dist )
        phys:SetAngleVelocity( VectorRand( -500, 500 ) )
    end
end

function ENT:Think()
    if self.Exploded then return end

    if CurTime() > self.DelayCurTime and !self.Exploded then
        self:OnDelayEnd()
        self.Exploded = true
    end

    if SERVER and self.TickSound and self.DelayTime > 0 and CurTime() > self.NextTickSound then

        self:EmitSound( self.TickSound, 70, 100 + max( 100, ( 1 / ( self.DelayCurTime - CurTime() ) ) * 60 ), 1, CHAN_WEAPON )
        self.NextTickSound = CurTime() + 0.1
    end

    if CLIENT then self:SetNextClientThink( CurTime() ) end
    self:NextThink( CurTime() )
    return true  
end