AddCSLuaFile()

DEFINE_BASECLASS( "cd2_weaponbase" )

SWEP.Base = "cd2_weaponbase"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"
SWEP.PrintName = "Rocket Launcher"

SWEP.Primary.Ammo = "RPG_Round"
SWEP.Primary.ClipSize = 3
SWEP.Primary.DefaultClip = 36
SWEP.Primary.Automatic = false

SWEP.Primary.RPM = 60
SWEP.Primary.Damage = nil
SWEP.Primary.Force = nil
SWEP.Primary.Tracer = 5
SWEP.Primary.Spread = 0.03
SWEP.Primary.Bulletcount = 1
SWEP.ReloadTime = 2
SWEP.ReloadSounds = { { 0, "weapons/smg1/smg1_reload.wav" }, { 2, "weapons/slam/mine_mode.wav" } }

SWEP.DropMenu_SkillLevel = 4
SWEP.DropMenu_Damage = 10
SWEP.DropMenu_Range = 6
SWEP.DropMenu_FireRate = 1

SWEP.IsExplosive = true
SWEP.HoldType = "rpg"
SWEP.Primary.ShootSound = "weapons/rpg/rocketfire1.wav"

function SWEP:PrimaryAttack()
    if !self:CanPrimaryAttack() or CurTime() < self:GetNextPrimaryFire() or self:GetIsReloading() then return end

    self:TakePrimaryAmmo( 1 )

    if istable( self.Primary.ShootSound ) then
        local snd = self.Primary.ShootSound[ random( #self.Primary.ShootSound ) ]
        self:EmitSound( snd, 80, 100, 1, CHAN_WEAPON )
    else
        self:EmitSound( self.Primary.ShootSound, 80, 100, 1, CHAN_WEAPON )
    end

    self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

    if SERVER then
        local rocket = ents.Create( "rpg_missile" )
        rocket:SetPos( self:GetOwner():GetShootPos() + self:GetOwner():EyeAngles():Up() * 10 )
        rocket:SetAngles( self:GetOwner():EyeAngles() )
        rocket:SetOwner( self:GetOwner() )
        rocket:SetMoveType( MOVETYPE_FLYGRAVITY )
        rocket:SetAbsVelocity( self:GetForward() * 2000 + Vector( 0, 0, 128 ) )
        rocket:SetCollisionGroup( COLLISION_GROUP_DEBRIS ) -- SetOwner should prevent collision but it doesn't
        rocket:SetSaveValue( "m_flDamage", 150 ) -- Gmod RPG only does 150 damage
        rocket:Spawn()
    end

    self:SetNextPrimaryFire( CurTime() + 60 / self.Primary.RPM )
end

function SWEP:Reload()
    if self:GetIsReloading() or self:GetOwner():GetAmmoCount( self.Primary.Ammo ) <= 0 or self:Clip1() == self:GetMaxClip1() then return end
    if self:GetOwner():IsPlayer() then BroadcastLua( "Entity(" .. self:GetOwner():EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_HL2MP_GESTURE_RELOAD_SMG1, true )" ) end
    BaseClass.Reload( self )
end