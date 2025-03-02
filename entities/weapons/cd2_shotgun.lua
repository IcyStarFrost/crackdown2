AddCSLuaFile()

SWEP.Base = "cd2_weaponbase"
SWEP.WorldModel = "models/weapons/w_shotgun.mdl"
SWEP.PrintName = "Shotgun"

SWEP.Primary.Ammo = "Buckshot"
SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 60
SWEP.Primary.Automatic = false

SWEP.Primary.RPM = 110
SWEP.Primary.Damage = 6
SWEP.Primary.Force = 3
SWEP.Primary.Tracer = 1
SWEP.Primary.Spread = 0.06
SWEP.Primary.LockOnSpread = 0.04
SWEP.Primary.Bulletcount = 10
SWEP.ReloadTime = 2
SWEP.ReloadSounds = {}

SWEP.DropMenu_SkillLevel = 0
SWEP.DropMenu_Damage = 6
SWEP.DropMenu_Range = 2
SWEP.DropMenu_FireRate = 2

SWEP.IsShotgun = true
SWEP.HoldType = "shotgun"
SWEP.Primary.ShootSound = { "crackdown2/weapons/agencyshotgunfire1.mp3", "crackdown2/weapons/agencyshotgunfire2.mp3" }