AddCSLuaFile()

SWEP.Base = "cd2_weaponbase"
SWEP.WorldModel = "models/weapons/w_smg_ump45.mdl"
SWEP.PrintName = "Ingalls XGS"

SWEP.Primary.Ammo = "SMG1"
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 400
SWEP.Primary.Automatic = true

SWEP.Primary.RPM = 900
SWEP.Primary.Damage = 12
SWEP.Primary.Force = nil
SWEP.Primary.Tracer = 1
SWEP.Primary.Spread = 0.06
SWEP.Primary.LockOnSpread = 0
SWEP.Primary.Bulletcount = 1
SWEP.ReloadTime = 1.2
SWEP.ReloadSounds = { { 0, "weapons/smg1/smg1_reload.wav" } }

SWEP.DropMenu_RequiresCollect = true
SWEP.DropMenu_SkillLevel = 0
SWEP.DropMenu_Damage = 2
SWEP.DropMenu_Range = 5
SWEP.DropMenu_FireRate = 6

SWEP.DamageFalloffDiv = 100
SWEP.HoldType = "smg"
SWEP.Primary.ShootSound = "crackdown2/weapons/ingallsxgsfire1.mp3"