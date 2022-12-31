AddCSLuaFile()

SWEP.Base = "cd2_weaponbase"
SWEP.WorldModel = "models/weapons/w_smg1.mdl"
SWEP.PrintName = "SMG"

SWEP.Primary.Ammo = "SMG1"
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 300
SWEP.Primary.Automatic = true

SWEP.Primary.RPM = 900
SWEP.Primary.Damage = 8
SWEP.Primary.Force = nil
SWEP.Primary.Tracer = 1
SWEP.Primary.Spread = 0.06
SWEP.Primary.Bulletcount = 1
SWEP.ReloadTime = 2
SWEP.ReloadSounds = { { 0, "weapons/smg1/smg1_reload.wav" } }

SWEP.DropMenu_SkillLevel = 0
SWEP.DropMenu_Damage = 3
SWEP.DropMenu_Range = 4
SWEP.DropMenu_FireRate = 7

SWEP.DamageFalloffDiv = 250
SWEP.HoldType = "smg"
SWEP.Primary.ShootSound = "^weapons/smg1/npc_smg1_fire1.wav"