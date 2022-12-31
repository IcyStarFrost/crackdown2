AddCSLuaFile()

SWEP.Base = "cd2_weaponbase"
SWEP.WorldModel = "models/weapons/w_snip_scout.mdl"
SWEP.PrintName = "Sniper"

SWEP.Primary.Ammo = "SniperRound"
SWEP.Primary.ClipSize = 15
SWEP.Primary.DefaultClip = 50
SWEP.Primary.Automatic = true

SWEP.Primary.RPM = 100
SWEP.Primary.Damage = 30
SWEP.Primary.Force = 3
SWEP.Primary.Tracer = 1
SWEP.Primary.TracerName = "AR2Tracer"
SWEP.Primary.Spread = 0.05
SWEP.Primary.LockOnSpread = 0
SWEP.Primary.Bulletcount = 1
SWEP.ReloadTime = 2
SWEP.ReloadSounds = { { 0, "weapons/ar2/npc_ar2_reload.wav" } }

SWEP.DropMenu_SkillLevel = 2
SWEP.DropMenu_Damage = 8
SWEP.DropMenu_Range = 10
SWEP.DropMenu_FireRate = 4

SWEP.DamageFalloffDiv = 400 -- The divisor amount to lower damage based on distance
SWEP.LockOnRange = 3000 -- How far can the player lock onto targets
SWEP.HoldType = "ar2"
SWEP.Primary.ShootSound = { "weapons/m4a1/m4a1-1.wav" }