AddCSLuaFile()

SWEP.Base = "cd2_weaponbase"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.PrintName = "9mm Pistol"

SWEP.Primary.Ammo = "Pistol"
SWEP.Primary.ClipSize = 15
SWEP.Primary.DefaultClip = 300
SWEP.Primary.Automatic = false

SWEP.Primary.RPM = 400
SWEP.Primary.Damage = 12
SWEP.Primary.Force = nil
SWEP.Primary.Tracer = 1
SWEP.Primary.Spread = 0.03
SWEP.Primary.LockOnSpread = 0
SWEP.Primary.Bulletcount = 1
SWEP.ReloadTime = 2
SWEP.ReloadSounds = { { 0, "weapons/pistol/pistol_reload1.wav" } }
SWEP.DamageFalloffDiv = 300

SWEP.DropMenu_SkillLevel = 0
SWEP.DropMenu_Damage = 4
SWEP.DropMenu_Range = 2
SWEP.DropMenu_FireRate = 4

SWEP.HoldType = "pistol"
SWEP.Primary.ShootSound = "^weapons/pistol/pistol_fire3.wav"