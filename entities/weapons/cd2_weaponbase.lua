AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.PrintName = "CD2 Weapon"
SWEP.Category = "Crackdown 2"

SWEP.Spawnable = true
SWEP.ViewModelFOV = 62

SWEP.Primary.Ammo = "SMG1"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false

SWEP.Primary.RPM = 400
SWEP.Primary.Damage = 5
SWEP.Primary.Force = nil
SWEP.Primary.Tracer = 1
SWEP.Primary.TracerName = "Tracer"
SWEP.Primary.Spread = 0.03
SWEP.Primary.Bulletcount = 1
SWEP.ReloadTime = 2
SWEP.ReloadSounds = {}

SWEP.IsExplosive = false -- If the weapon is explosive. used to render the dropped weapon color to yellow
SWEP.DamageFalloffDiv = 200 -- The divisor amount to lower damage based on distance
SWEP.LockOnRange = 2000 -- How far can the player lock onto targets
SWEP.HoldType = "ar2"
SWEP.Primary.ShootSound = ""

local ipairs = ipairs
local IsValid = IsValid
local random = math.random
local clamp = math.Clamp
local table_insert = table.insert
local math_rad = math.rad
local surface_DrawPoly = CLIENT and surface.DrawPoly
local surface_SetDrawColor = CLIENT and surface.SetDrawColor
local surface_SetMaterial = CLIENT and surface.SetMaterial
local draw_NoTexture = CLIENT and draw.NoTexture
local surface_DrawRect = CLIENT and surface.DrawRect
local Trace = util.TraceLine
local IsValid = IsValid
local math_cos = math.cos
local LerpVector = LerpVector 
local Lerp = Lerp
local math_sin = math.sin
local droppedguncolor = Color( 0, 153, 255 )
local droppedexplosivecolor = Color( 255, 217, 0)
local surface_DrawTexturedRectRotated = CLIENT and surface.DrawTexturedRectRotated
local SysTime = SysTime
local math_atan2 = math.atan2
local util_SharedRandom = util.SharedRandom


local droppedguncolor_alpha = Color( 0, 153, 255, 50 )
local droppedexplosivecolor_alpha = Color( 255, 145, 0, 50 )

function SWEP:Initialize()
    self:SetHoldType( self.HoldType )
    self.DeleteTime = CurTime() + 30 -- The time until we will be deleted

    self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

    if SERVER then
        hook.Add( "Tick", self, function()
            if !IsValid( self:GetOwner() ) and CurTime() > self.DeleteTime then
                self:Remove()
            elseif IsValid( self:GetOwner() ) then
                self.DeleteTime = CurTime() + 30
            end
        end )
    end
end

function SWEP:NPCShoot_Secondary( shootPos, shootDir )
end

function SWEP:SecondaryAttack()
end

function SWEP:PrimaryAttack()
    if !self:CanPrimaryAttack() or CurTime() < self:GetNextPrimaryFire() or self:GetIsReloading() then return end

    self:TakePrimaryAmmo( 1 )

    if istable( self.Primary.ShootSound ) then
        local snd = self.Primary.ShootSound[ random( #self.Primary.ShootSound ) ]
        self:EmitSound( snd, 80, 100, 1, CHAN_WEAPON )
    else
        self:EmitSound( self.Primary.ShootSound, 80, 100, 1, CHAN_WEAPON )
    end

    if self:GetOwner():IsCD2NPC() then
        local anim = self:GetOwner().cd2_holdtypetranslations[ self:GetHoldType() ].fire
        self:GetOwner():AddGesture( anim, true )
    end

    self:ShootBullet( self.Primary.Damage, self.Primary.Bulletcount, self.Primary.Spread, self.Primary.Ammo, self.Primary.Force, self.Primary.Tracer, self.Primary.TracerName )

    self:SetNextPrimaryFire( CurTime() + 60 / self.Primary.RPM )
end

function SWEP:CanPrimaryAttack()
    local owner = self:GetOwner()

    if IsValid( owner ) and owner:IsPlayer() and owner:KeyDown( IN_USE ) or self:GetPickupMode() then return false end

	if self:Clip1() <= 0 and !self:GetIsReloading() then
	
		self:EmitSound( "Weapon_Pistol.Empty" )
		self:SetNextPrimaryFire( CurTime() + 0.2 )
		self:Reload()
		return false

	end

	return true

end

function SWEP:DamageFalloff( attacker, tr, info )
    local hitent = tr.Entity
    if !IsValid( hitent ) then return end
    local dist = attacker:GetPos():Distance( hitent:GetPos() )
    local sub = dist / self.DamageFalloffDiv
    info:SetDamage( info:GetDamage() - sub )
end

function SWEP:ShootBullet( damage, num_bullets, spread, ammo_type, force, tracer, tracername )
    
	self.bullet = self.bullet or {}
	self.bullet.Num	= num_bullets
	self.bullet.Src	= self:GetOwner():GetShootPos()
	self.bullet.Dir	= IsValid( self:GetOwner().cd2_lockontarget ) and ( self:GetOwner().cd2_lockontarget:WorldSpaceCenter() - self:GetOwner():GetShootPos() ):GetNormalized() or self:GetOwner():GetAimVector()
	self.bullet.Spread = self:GetOwner():IsPlayer() and IsValid( self:GetOwner():GetNW2Entity( "cd2_lockontarget", nil ) ) and Vector( 0.001, 0.001 ) or Vector( spread, spread, 0 )
	self.bullet.Tracer = tracer or 1
    self.bullet.TracerName = tracername or "Tracer"
	self.bullet.Force = force or damage
	self.bullet.Damage = damage
	self.bullet.AmmoType = ammo_type or self.Primary.Ammo
    self.bullet.Callback = function( attacker, tr, info ) self:DamageFalloff( attacker, tr, info ) end

	self:GetOwner():FireBullets( self.bullet )

	self:ShootEffects()

end

function SWEP:SetupDataTables()
    self:NetworkVar( "Bool", 0, "IsReloading" )
    self:NetworkVar( "Bool", 1, "PickupMode" )
end

function SWEP:EnterPickupMode()
    if self:GetPickupMode() then return end

    self:SetPickupMode( true )
    self:SetHoldType( "melee" )
    self:SetNoDraw( true )
    self:DrawShadow( false )
end

function SWEP:ExitPickupMode()
    if !self:GetPickupMode() then return end

    self:SetPickupMode( false )
    self:SetHoldType( self.HoldType )
    self:SetNoDraw( false )
    self:DrawShadow( true )
end

function SWEP:Holster( wep )
    if self:GetPickupMode() then return end
    self:SetIsReloading( false )
    self:SetHoldType( "passive" )
    self:GetOwner():EmitSound( "crackdown2/ply/switchweapon.wav", 70, 100, 0.5, CHAN_AUTO )

    timer.Simple( 0.6, function()
        if !IsValid( self ) or !IsValid( self:GetOwner() ) then return end
        if SERVER then
            self:GetOwner():SetActiveWeapon( wep )
        end
        self:SetHoldType( self.HoldType )
    end )

end

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

local effecttrace = {}
local rectmat = Material( "crackdown2/effects/weaponrect.png" )
local lightbeam = Material( "crackdown2/effects/weaponlightbeam.png" )
local ammoicon = Material( "crackdown2/effects/ammo.png" )

-- Returns if the player already has this weapon
function SWEP:IsAmmoToLocalPlayer()
    local ply = LocalPlayer() 
    return ply:HasWeapon( self:GetClass() )
end

function SWEP:DrawWorldModel()
    self:DrawModel()

    self.cd2_effectdelay = self.cd2_effectdelay or SysTime() + 0.5
    if !IsValid( self:GetOwner() ) and self:GetVelocity():IsZero() then
        local wep = LocalPlayer():GetWeapon( self:GetClass() )
        if SysTime() < self.cd2_effectdelay or ( IsValid( wep ) and wep:Ammo1() >= ( wep.Primary.DefaultClip - wep.Primary.ClipSize ) ) then 
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
            surface_SetDrawColor( self.IsExplosive and droppedexplosivecolor_alpha or droppedguncolor_alpha )
            surface_SetMaterial( lightbeam )
            surface_DrawTexturedRectRotated( 0, -20, self.cd2_lightbeamw, self.cd2_lightbeamh, 0 )

            if self:IsAmmoToLocalPlayer() then
                surface_SetMaterial( ammoicon )
                surface_DrawTexturedRectRotated( 0, -60, 16, 16, 0 )
            end
        cam.End3D2D()
        
        cam.Start3D2D( self.cd2_effectpos, Angle( 0, 180 + SysTime() * 60, 90 ), 1 )
            surface_SetDrawColor( self.IsExplosive and droppedexplosivecolor_alpha or droppedguncolor_alpha )
            surface_SetMaterial( lightbeam )
            surface_DrawTexturedRectRotated( 0, -20, self.cd2_lightbeamw, self.cd2_lightbeamh, 0 )

            if self:IsAmmoToLocalPlayer() then
                surface_SetMaterial( ammoicon )
                surface_DrawTexturedRectRotated( 0, -60, 16, 16, 0 )
            end
        cam.End3D2D()

        cam.Start3D2D( self.cd2_effectpos, Angle( 0, 0, 0 ), 0.1 )
            
            surface_SetDrawColor( self.IsExplosive and droppedexplosivecolor_alpha or droppedguncolor_alpha )
            
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

function SWEP:Reload()
    if self:GetIsReloading() or self:GetOwner():IsPlayer() and self:GetOwner():GetAmmoCount( self.Primary.Ammo ) <= 0 or self:Clip1() == self:GetMaxClip1() or self:GetPickupMode() then return end

    self:SetIsReloading( true )

    if self:GetOwner():IsCD2NPC() and SERVER then
        local anim = self:GetOwner().cd2_holdtypetranslations[ self:GetHoldType() ].reload
        self:GetOwner():AddGesture( anim, true )
    else
        self:GetOwner():SetAnimation( PLAYER_RELOAD )
    end

    for k, v in ipairs( self.ReloadSounds ) do
        timer.Simple( v[ 1 ], function()
            if !IsValid( self ) or !IsValid( self:GetOwner() ) or self:GetOwner():GetActiveWeapon() != self then return end
            self:EmitSound( v[ 2 ], 80, 100, 1, CHAN_WEAPON )
        end )
    end

    timer.Simple( self.ReloadTime, function()
        if !IsValid( self ) or !IsValid( self:GetOwner() ) or self:GetOwner():GetActiveWeapon() != self or !self:GetIsReloading() then return end
        self:SetIsReloading( false )

        if self:GetOwner():IsPlayer() then

            local reserve = self:GetOwner():GetAmmoCount( self.Primary.Ammo )
            local count = clamp( self.Primary.ClipSize, 0, reserve )
            local oldclip = self:Clip1()
            self:SetClip1( count )

            if SERVER then 
                print( count - oldclip )
                self:GetOwner():RemoveAmmo( count - oldclip, self.Primary.Ammo )
            end
        else
            self:SetClip1( self:GetMaxClip1() )
        end
    end )

end