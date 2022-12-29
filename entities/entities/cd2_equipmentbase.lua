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
local IsValid = IsValid
local random = math.random
local clamp = math.Clamp
local LerpVector = LerpVector 
local Lerp = Lerp
local table_insert = table.insert
local math_rad = math.rad
local surface_DrawPoly = CLIENT and surface.DrawPoly
local surface_SetDrawColor = CLIENT and surface.SetDrawColor
local surface_SetMaterial = CLIENT and surface.SetMaterial
local draw_NoTexture = CLIENT and draw.NoTexture
local surface_DrawRect = CLIENT and surface.DrawRect
local Trace = util.TraceLine
local math_cos = math.cos
local math_sin = math.sin
local droppedexplosivecolor_alpha = Color( 255, 145, 0, 50 )
local surface_DrawTexturedRectRotated = CLIENT and surface.DrawTexturedRectRotated
local SysTime = SysTime
local math_atan2 = math.atan2
local util_SharedRandom = util.SharedRandom


function ENT:Initialize()
    self.DelayCurTime = CurTime() + self.DelayTime
    self.DeleteTime = CurTime() + 30 -- The time until we will be deleted
    
    if CLIENT then return end
    self:SetModel( self.WorldModel )

    self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:PhysWake()

    local phys = self:GetPhysicsObject()

    if IsValid( phys ) then phys:SetMass( 100 ) end

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

    if SERVER then
        util_SpriteTrail( self, 0, self.TrailColor, true, 5, 0, 2, 1 / ( 5 + 0 ) * 0.5, "trails/laser" )
    end
end


function ENT:Think()
    if self.Exploded then return end

    if SERVER then
        if !IsValid( self:GetThrower() ) and CurTime() > self.DeleteTime then
            self:Remove()
            return
        elseif IsValid( self:GetThrower() ) then
            self.DeleteTime = CurTime() + 30
        end
    end

    if SERVER and !IsValid( self:GetThrower() ) then

        local nearents = CD2FindInSphere( self:GetPos(), 50, function( ent ) return ent:IsCD2Agent() and self:IsAmmoToPlayer( ent ) and ent:GetEquipmentCount() < ent:GetMaxEquipmentCount() end )
        local ply = nearents[ 1 ]
        if IsValid( ply ) then
            ply:SetEquipmentCount( clamp( ply:GetEquipmentCount() + ( ply:GetMaxEquipmentCount() / 4 ), 0, ply:GetMaxEquipmentCount() ) )
            ply:EmitSound( "items/ammo_pickup.wav", 60 )
            self:Remove()
        end
    end

    if !IsValid( self:GetThrower() ) then return end

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


-- Returns if the player already has this weapon
function ENT:IsAmmoToPlayer( ply )
    if CLIENT then
        local ply = LocalPlayer() 
        local equipment = ply.cd2_Equipment
        return ply.cd2_Equipment == self:GetClass()
    elseif SERVER then
        local equipment = ply.cd2_Equipment
        return ply.cd2_Equipment == self:GetClass()
    end
end

local effecttrace = {}
local rectmat = Material( "crackdown2/effects/weaponrect.png" )
local lightbeam = Material( "crackdown2/effects/weaponlightbeam.png" )
local ammoicon = Material( "crackdown2/effects/ammo.png" )

local function draw_Circle( x, y, radius, seg )
	local cir = {}

	table_insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math_rad( ( i / seg ) * -360 )
		table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )
	end

	local a = math_rad( 0 ) -- This is needed for non absolute segment counts
	table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )

	surface_DrawPoly( cir )
end

function ENT:Draw()
    self:DrawModel()

    self.cd2_effectdelay = self.cd2_effectdelay or SysTime() + 0.5
    if !IsValid( self:GetThrower() ) and self:GetVelocity():IsZero() then
        local wep = LocalPlayer():GetWeapon( self:GetClass() )

        if SysTime() < self.cd2_effectdelay or LocalPlayer():GetEquipmentCount() == LocalPlayer():GetMaxEquipmentCount() then 
            self:SetupBones()
            self:SetPos( self:GetNetworkOrigin() )
            self:SetAngles( self:GetNetworkAngles() )
            return 
        end

        if !self.cd2_effectpos then
            effecttrace.start = self:WorldSpaceCenter()
            effecttrace.endpos = self:WorldSpaceCenter() - Vector( 0, 0, 10000 )
            effecttrace.filter = self
            effecttrace.collisiongroup = COLLISION_GROUP_WORLD
            local result = Trace( effecttrace )
            self.cd2_effectpos = result.HitPos
        end

        self:SetupBones()
        self:SetAngles( Angle( 0, SysTime() * 60, 0 ) )
        self:SetPos( LerpVector( 3 * FrameTime(), self:GetPos(), self.cd2_effectpos + Vector( 0, 0, 40 ) ))
        
        self.cd2_lightbeamw = self.cd2_lightbeamw and Lerp( 1 * FrameTime(), self.cd2_lightbeamw, 30 ) or 0
        self.cd2_lightbeamh = self.cd2_lightbeamh and Lerp( 1 * FrameTime(), self.cd2_lightbeamh, 40 ) or 0
        cam.Start3D2D( self.cd2_effectpos, Angle( 0, 0 + SysTime() * 60, 90 ), 1 )
            surface_SetDrawColor( droppedexplosivecolor_alpha )
            surface_SetMaterial( lightbeam )
            surface_DrawTexturedRectRotated( 0, -20, self.cd2_lightbeamw, self.cd2_lightbeamh, 0 )

            if self:IsAmmoToPlayer() then
                surface_SetMaterial( ammoicon )
                surface_DrawTexturedRectRotated( 0, -60, 16, 16, 0 )
            end
        cam.End3D2D()
        
        cam.Start3D2D( self.cd2_effectpos, Angle( 0, 180 + SysTime() * 60, 90 ), 1 )
            surface_SetDrawColor( droppedexplosivecolor_alpha )
            surface_SetMaterial( lightbeam )
            surface_DrawTexturedRectRotated( 0, -20, self.cd2_lightbeamw, self.cd2_lightbeamh, 0 )

            if self:IsAmmoToPlayer() then
                surface_SetMaterial( ammoicon )
                surface_DrawTexturedRectRotated( 0, -60, 16, 16, 0 )
            end
        cam.End3D2D()

        cam.Start3D2D( self.cd2_effectpos, Angle( 0, 0, 0 ), 0.1 )
            
            surface_SetDrawColor( droppedexplosivecolor_alpha )
            
            for i = 1, 4 do
                local x, y = math_sin( SysTime() * util_SharedRandom( "x" .. i, 1, 4, self:EntIndex() ) ) * 300, math_cos( SysTime() * util_SharedRandom( "x" .. i, 1, 4, self:EntIndex() ) ) * 300
                surface_SetMaterial( rectmat)
                surface_DrawTexturedRectRotated( x, y, 200, 100, ( math_atan2( x, y ) * 180 / math.pi ) )
            end

            for i = 1, 4 do
                local x, y = math_sin( -SysTime() * util_SharedRandom( "2largex" .. i, 1, 4, self:EntIndex() ) ) * ( 100 * i ), math_cos( -SysTime() * util_SharedRandom( "2largex" .. i, 1, 4, self:EntIndex() ) ) * ( 100 * i )
                surface_SetMaterial( rectmat)
                surface_DrawTexturedRectRotated( x, y, 300, 200, ( math_atan2( x, y ) * 180 / math.pi ) )
            end

            for i = 1, 4 do
                local x, y = math_sin( -SysTime() * util_SharedRandom( "2x" .. i, 1, 4, self:EntIndex() ) ) * ( 100 * i ), math_cos( -SysTime() * util_SharedRandom( "2x" .. i, 1, 4, self:EntIndex() ) ) * ( 100 * i )
                surface_SetMaterial( rectmat)
                surface_DrawTexturedRectRotated( x, y, 200, 100, ( math_atan2( x, y ) * 180 / math.pi ) )
            end

            draw_NoTexture()
            draw_Circle( 0, 0, 300, 30 )
            draw_Circle( 0, 0, 100, 6 )
        cam.End3D2D()
    else
        self.cd2_effectdelay = SysTime() + 0.5
        self.cd2_effectpos = nil
    end
end