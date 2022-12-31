AddCSLuaFile()

SWEP.Base = "cd2_weaponbase"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"
SWEP.PrintName = "Assault Rifle"

SWEP.Primary.Ammo = "AR2"
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 300
SWEP.Primary.Automatic = true

SWEP.Primary.RPM = 600
SWEP.Primary.Damage = 13
SWEP.Primary.Force = nil
SWEP.Primary.Tracer = 1
SWEP.Primary.TracerName = "AR2Tracer"
SWEP.Primary.Spread = 0.04
SWEP.Primary.Bulletcount = 1
SWEP.ReloadTime = 2
SWEP.ReloadSounds = { { 0, "weapons/ar2/npc_ar2_reload.wav" } }

SWEP.DropMenu_SkillLevel = 2
SWEP.DropMenu_Damage = 3
SWEP.DropMenu_Range = 5
SWEP.DropMenu_FireRate = 5

SWEP.HoldType = "ar2"
SWEP.Primary.ShootSound = { "^weapons/ar1/ar1_dist1.wav", "^weapons/ar1/ar1_dist2.wav" }