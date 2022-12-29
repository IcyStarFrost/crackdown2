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

SWEP.DamageFalloffDiv = 200 -- The divisor amount to lower damage based on distance
SWEP.LockOnRange = 2000 -- How far can the player lock onto targets
SWEP.HoldType = "ar2"
SWEP.Primary.ShootSound = ""

local ipairs = ipairs
local IsValid = IsValid
local random = math.random
local clamp = math.Clamp

function SWEP:Initialize()
    self:SetHoldType( self.HoldType )
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

function SWEP:Reload()
    if self:GetIsReloading() or self:GetOwner():IsPlayer() and !self:HasAmmo() or self:Clip1() == self:GetMaxClip1() or self:GetPickupMode() then return end

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
            self:SetClip1( count )

            if SERVER then 
                --self:GetOwner():RemoveAmmo( count, self.Primary.Ammo )
            end
        else
            self:SetClip1( self:GetMaxClip1() )
        end
    end )

end