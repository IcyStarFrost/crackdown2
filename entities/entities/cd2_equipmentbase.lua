AddCSLuaFile()

ENT.Base = "base_anim"
ENT.WorldModel = "models/weapons/w_grenade.mdl"
ENT.PrintName = "Equipment"
ENT.IsEquipment = true

-- Equipment settings
ENT.Cooldown = 3 -- The time before the grenade can be used again
ENT.MaxGrenadeCount = 8 -- The amount of grenades a player can have
ENT.TrailColor = color_white -- The trail color
ENT.DelayTime = 3 -- The time before the grenade blows up. 0 for no timed explosive
ENT.TickSound = nil -- The sound that will play as the grenade ticks
ENT.RemoveOnInvalid = false -- If true, the equipment will remove itself if its thrower is invalid
--

-- Drop menu shown stats. 
ENT.DropMenu_RequiresCollect = false -- If the player must bring this weapon to a Agency Landing Zone to pick it in the Drop Menu
ENT.DropMenu_SkillLevel = 0 -- The skill level the player's Weapon skill needs to be in order to use this weapon

-- These values must be clamped to 0 to 10!
ENT.DropMenu_Damage = 0
ENT.DropMenu_Range = 0
--


-- Util vars
ENT.NextTickSound = 0 -- Then next time the tick sound will play
ENT.Exploded = false -- If the grenade exploded or not

local clamp = math.Clamp
local max = math.max
local IsValid = IsValid
local util_SpriteTrail = util.SpriteTrail
local IsValid = IsValid
local clamp = math.Clamp
local LerpVector = LerpVector 
local Lerp = Lerp
local table_insert = table.insert
local math_rad = math.rad
local player_GetAll = player.GetAll
local surface_DrawPoly = CLIENT and surface.DrawPoly
local surface_SetDrawColor = CLIENT and surface.SetDrawColor
local surface_SetMaterial = CLIENT and surface.SetMaterial
local draw_NoTexture = CLIENT and draw.NoTexture
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
    self:NetworkVar( "Bool", 0, "HadThrower" )
    self:NetworkVar( "Bool", 1, "PermanentDrop" )
end

-- Explosion code here
function ENT:OnDelayEnd()
end

function ENT:GetPrintName()
    return self.PrintName
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

function ENT:InteractTest( ply )
    if !ply:IsCD2Agent() or ply:SqrRangeTo( self ) > 100 ^ 2 then return false end
    if ply:GetEquipment() == self:GetClass() then return false end

    return "Int3"
end

function ENT:Think()
    if self.Exploded then return end

    -- Set if we had a thrower
    if IsValid( self:GetThrower() ) then self:SetHadThrower( true ) end

    if SERVER then

        -- If our thrower is either invalid or dead, remove ourselves
        if self.RemoveOnInvalid and ( !IsValid( self:GetThrower() ) or IsValid( self:GetThrower() ) and self:GetThrower():IsPlayer() and !self:GetThrower():Alive() ) and self:GetHadThrower() or self.cd2_equipmentcount and self.cd2_equipmentcount == 0 then
            self:Remove()
            return
        end

        -- If we aren't picked up by any Agent after 30 seconds, remove ourselves

        if !self:GetPermanentDrop() and !IsValid( self:GetThrower() ) and !self:GetHadThrower() and CurTime() > self.DeleteTime then
            self:Remove()
            return
        elseif self:GetPermanentDrop() or IsValid( self:GetThrower() ) or self:GetHadThrower() then
            self.DeleteTime = CurTime() + 30
        end

    end

    -- Custom Pickup code for equipment
    if SERVER and !IsValid( self:GetThrower() ) and !self:GetHadThrower() and self:WaterLevel() == 0 then

        for _, ply in player.Iterator() do
            if !ply:IsCD2Agent() then continue end

            if IsValid( ply ) and self:IsAmmoToPlayer( ply ) and ply:GetEquipmentCount() < ply:GetMaxEquipmentCount() and ply:SqrRangeTo( self ) < 100 ^ 2 then
                ply:SetEquipmentCount( self.cd2_equipmentcount or clamp( ply:GetEquipmentCount() + ( ply:GetMaxEquipmentCount() / 4 ), 0, ply:GetMaxEquipmentCount() ) )
                ply:EmitSound( "items/ammo_pickup.wav", 60 )
                self:Remove()
            elseif IsValid( ply ) and !self:IsAmmoToPlayer( ply ) then

                if ply:IsButtonDown( ply:GetInfoNum( "cd2_interact3", KEY_R ) ) then ply.cd2_PickupWeaponDelay = ply.cd2_PickupWeaponDelay or CurTime() + 0.2 else ply.cd2_PickupWeaponDelay = nil end

                if ply:GetInteractable3() == self and ply.cd2_PickupWeaponDelay and CurTime() > ply.cd2_PickupWeaponDelay or ( ply:GetEquipmentCount() == 0 ) then
                    local oldequipment = ply:GetEquipment()
                    local oldcount = ply:GetEquipmentCount()

                    ply:SetEquipment( self:GetClass() )
                    ply:SetMaxEquipmentCount( self.MaxGrenadeCount )
                    ply:SetEquipmentCount( self.cd2_equipmentcount or self.MaxGrenadeCount )

                    ply:EmitSound( "items/ammo_pickup.wav", 60 )

                    local droppedequipment = ents.Create( oldequipment )
                    droppedequipment:SetPos( ply:GetShootPos() )
                    droppedequipment.cd2_equipmentcount = oldcount
                    droppedequipment:Spawn()

                    local phys = droppedequipment:GetPhysicsObject()
                    local pos = ply:GetPos() + ply:GetForward() * 50
                    local dist = clamp( droppedequipment:GetPos():Distance( pos ) * 150, 0, 100000 )
                
                    local arc = ( ( LerpVector( 0.5, droppedequipment:GetPos(), pos ) + Vector( 0, 0, 100 ) ) - droppedequipment:GetPos() ):GetNormalized()
                    if IsValid( phys ) then
                        phys:ApplyForceCenter( arc * dist )
                        phys:SetAngleVelocity( VectorRand( -500, 500 ) )
                    end

                    self:Remove()
                    ply.cd2_PickupDelay = math.huge
                    ply.cd2_PickupWeaponDelay = math.huge
                end

            end
        end

    end



    if IsValid( self:GetThrower() ) or self:GetHadThrower() then

        if !self:Trace( nil, self:GetPos() - Vector( 0, 0, 40 ) ).Hit then
            self.DelayCurTime = CurTime() + self.DelayTime
        end

        -- If time is up, booom
        if CurTime() > self.DelayCurTime and !self.Exploded then
            self:OnDelayEnd()
            self.Exploded = true
        end

        -- Tick sounds
        if SERVER and self.TickSound and self.DelayTime > 0 and CurTime() > self.NextTickSound then
            self:EmitSound( self.TickSound, 70, 100 + max( 100, ( 1 / ( self.DelayCurTime - CurTime() ) ) * 60 ), 1, CHAN_WEAPON )
            self.NextTickSound = CurTime() + 0.1
        end

    end


    if CLIENT then self:SetNextClientThink( CurTime() ) end
    self:NextThink( CurTime() )
    return true  
end

local Trace = util.TraceLine
local normaltrace = {}
function ENT:Trace( start, endpos, col, mask )
    normaltrace.start = start or self:GetPos()
    normaltrace.endpos = ( isentity( endpos ) and endpos:WorldSpaceCenter() or endpos )
    normaltrace.filter = self
    normaltrace.mask = mask or MASK_SOLID
    normaltrace.collisiongroup = col or COLLISION_GROUP_NONE
    local result = Trace( normaltrace )
    return result
end


-- Returns if the player already has this equipment
function ENT:IsAmmoToPlayer( ply )
    if CLIENT then
        local ply = LocalPlayer() 
        return ply:GetEquipment() == self:GetClass()
    elseif SERVER then
        return ply:GetEquipment() == self:GetClass()
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

    if self:WaterLevel() != 0 then return false end

    self.cd2_effectdelay = self.cd2_effectdelay or SysTime() + 0.5
    if !IsValid( self:GetThrower() ) and !self:GetHadThrower() and self:GetVelocity():IsZero() and LocalPlayer():SqrRangeTo( self ) < ( 2000 * 2000 ) then
        if !LocalPlayer():IsCD2Agent() or SysTime() < self.cd2_effectdelay or ( LocalPlayer():GetEquipmentCount() == LocalPlayer():GetMaxEquipmentCount() and LocalPlayer():GetEquipment() == self:GetClass() ) then 
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
            self.cd2_effectpos = result.HitPos + Vector( 0, 0, 2 )
        end

        self:SetupBones()
        self:SetAngles( Angle( 0, SysTime() * 60, 0 ) )

        -- For some reason this glitches out in single player and this is the way to atleast dampen that 
        self:SetPos( !game.SinglePlayer() and LerpVector( 3 * FrameTime(), self:GetPos(), self.cd2_effectpos + Vector( 0, 0, 40 ) ) or self.cd2_effectpos + Vector( 0, 0, 40 ) )
        
        self.cd2_lightbeamw = self.cd2_lightbeamw and Lerp( 1 * FrameTime(), self.cd2_lightbeamw, 30 ) or 0
        self.cd2_lightbeamh = self.cd2_lightbeamh and Lerp( 1 * FrameTime(), self.cd2_lightbeamh, 40 ) or 0

        -- Light beam front
        cam.Start3D2D( self.cd2_effectpos, Angle( 0, 0 + SysTime() * 60, 90 ), 1 )
            surface_SetDrawColor( droppedexplosivecolor_alpha )
            surface_SetMaterial( lightbeam )
            surface_DrawTexturedRectRotated( 0, -20, self.cd2_lightbeamw, self.cd2_lightbeamh, 0 )

            if self:IsAmmoToPlayer() then
                surface_SetMaterial( ammoicon )
                surface_DrawTexturedRectRotated( 0, -60, 16, 16, 0 )
            end
        cam.End3D2D()
        
        -- Light beam back
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
            
            -- Rectangle things
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