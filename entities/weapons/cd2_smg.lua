AddCSLuaFile()

SWEP.Base = "cd2_weaponbase"
SWEP.WorldModel = "models/weapons/w_smg1.mdl"
SWEP.PrintName = "SMG"

SWEP.Primary.Ammo = "SMG1"
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 480
SWEP.Primary.Automatic = true

SWEP.Primary.RPM = 1050
SWEP.Primary.Damage = 6
SWEP.Primary.Force = nil
SWEP.Primary.Tracer = 1
SWEP.Primary.Spread = 0.04
SWEP.Primary.LockOnSpread = 0
SWEP.Primary.Bulletcount = 1
SWEP.ReloadTime = 1.2
SWEP.ReloadSounds = { { 0, "weapons/smg1/smg1_reload.wav" } }

SWEP.DropMenu_RequiresCollect = true
SWEP.DropMenu_SkillLevel = 0
SWEP.DropMenu_Damage = 2
SWEP.DropMenu_Range = 4
SWEP.DropMenu_FireRate = 5

SWEP.DamageFalloffDiv = 250
SWEP.HoldType = "smg"
SWEP.Primary.ShootSound = "crackdown2/weapons/agencysmgfire1.mp3"