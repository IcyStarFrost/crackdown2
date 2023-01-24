AddCSLuaFile()

SWEP.Base = "cd2_weaponbase"
SWEP.WorldModel = "models/weapons/w_rif_ak47.mdl"
SWEP.PrintName = "Ingalls AL-107"

SWEP.Primary.Ammo = "AR2"
SWEP.Primary.ClipSize = 40
SWEP.Primary.DefaultClip = 250
SWEP.Primary.Automatic = true

SWEP.Primary.RPM = 750
SWEP.Primary.Damage = 10
SWEP.Primary.Force = nil
SWEP.Primary.Tracer = 1
SWEP.Primary.TracerName = "AR2Tracer"
SWEP.Primary.Spread = 0.04
SWEP.Primary.LockOnSpread = 0
SWEP.Primary.Bulletcount = 1
SWEP.ReloadTime = 2
SWEP.ReloadSounds = { { 0, "weapons/ar2/npc_ar2_reload.wav" } }

SWEP.DamageFalloffDiv = 500

SWEP.DropMenu_RequiresCollect = true
SWEP.DropMenu_Damage = 4
SWEP.DropMenu_Range = 6
SWEP.DropMenu_FireRate = 6

SWEP.HoldType = "ar2"
SWEP.Primary.ShootSound = "crackdown2/weapons/ingalls107fire1.mp3"