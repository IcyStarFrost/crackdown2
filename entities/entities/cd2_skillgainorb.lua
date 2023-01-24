AddCSLuaFile()

ENT.Base = "base_anim"

local IsValid = IsValid
local random = math.random
local Trace = util.TraceLine
local ztrace = {}
local skillparticle = Material( "crackdown2/effects/skillparticle.png" )

local util_SpriteTrail = util.SpriteTrail

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel( "models/error.mdl" )

    self:DrawShadow( false )

    self:PhysicsInitSphere( 5, "default" )
    
    local phys = self:GetPhysicsObject()

    if IsValid( phys ) then  
        phys:EnableMotion( false )
        phys:EnableCollisions( false )
        phys:SetMass( 100 )
    end

    self.cd2_first = true
    self.cd2_SeekPlayer = false
    self.cd2_seekspeed = 3

    ztrace.start = self:GetPos()
    ztrace.endpos = self:GetPos() - Vector( 0, 0, 100000 )
    ztrace.mask = MASK_SOLID_BRUSHONLY
    ztrace.collisiongroup = COLLISION_GROUP_WORLD
    local result = Trace( ztrace )

    self.cd2_TargetZ = result.HitPos[ 3 ] + 10

    self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

    util_SpriteTrail( self, 0, self:GetTrailColor():ToColor(), true, 5, 0, 1, 1 / ( 5 + 0 ) * 0.5, "trails/laser" )
end

function ENT:Draw()

    render.SetColorMaterial()
    render.DrawSphere( self:GetPos(), 2, 10, 10, self:GetTrailColor():ToColor() )

--[[     local dlight = DynamicLight( self:EntIndex() )

    if dlight then
        dlight.pos = self:GetPos()
		dlight.r = self:GetTrailColor().r
		dlight.g = self:GetTrailColor().g
		dlight.b = self:GetTrailColor().b
		dlight.brightness = 5
		dlight.Decay = 1000
		dlight.Size = 256
		dlight.DieTime = CurTime() + 1
    end ]]

end

function ENT:OnRemove()

    if SERVER then
        CD2HandleSkillXP( self:GetPlayer(), self:GetSkill(), self:GetXP() )
    end

    if CLIENT then
        if LocalPlayer() == self:GetPlayer() then
            surface.PlaySound( "crackdown2/ply/skillorbcollect.mp3" )
        end

        local particle = ParticleEmitter( self:GetPos() )
        for i = 1, 20 do
            
            local part = particle:Add( skillparticle, self:GetPos() )
    
            if part then
                part:SetStartSize( 1 )
                part:SetEndSize( 1 ) 
                part:SetStartAlpha( 255 )
                part:SetEndAlpha( 0 )

                local col = self:GetTrailColor()
                part:SetColor( col.r * 255, col.g * 255, col.b * 255 )
                part:SetLighting( false )
    
                part:SetDieTime( 0.5 )
                part:SetGravity( Vector() )
                part:SetAirResistance( 700 )
                part:SetVelocity( Vector( random( -400, 400 ), random( -400, 400 ), random( -400, 400 ) ) )
                part:SetAngleVelocity( AngleRand( -1, 1 ) )
            end
    
        end
    
        particle:Finish()
    end

end

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Player" )

    self:NetworkVar( "String", 0, "Skill" )

    self:NetworkVar( "Float", 0, "XP" )

    self:NetworkVar( "Vector", 0, "TrailColor" )
end


function ENT:Think()
    if CLIENT then return end

    if !IsValid( self:GetPlayer() ) then self:Remove() return end

    if self:GetPos()[ 3 ] < self.cd2_TargetZ then
        self.cd2_SeekPlayer = true
    end

    if self.cd2_first then

        local phys = self:GetPhysicsObject()

        if IsValid( phys ) then  
            phys:EnableMotion( true )
            phys:ApplyForceCenter( Vector( random( -8000, 8000 ), random( -8000, 8000 ), random( 20000, 70000 ) ))
        end
        
        self.cd2_first = false
    end

    if self.cd2_SeekPlayer and IsValid( self:GetPlayer() ) then
        self.cd2_seekspeed = Lerp( 0.2 * FrameTime(), self.cd2_seekspeed, 30 )
        self:SetPos( self:GetPos() + ( self:GetPlayer():WorldSpaceCenter() - self:GetPos() ):GetNormalized() * self.cd2_seekspeed )

        if self:GetPos():DistToSqr( self:GetPlayer():WorldSpaceCenter() ) <= ( 10 * 10 ) then
            self:Remove()
        end

    end

    self:NextThink( CurTime() )
    return true
end
