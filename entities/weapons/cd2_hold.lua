AddCSLuaFile()

SWEP.Base = "weapon_base"

function SWEP:Initialize()
    self:SetNoDraw( true )
    self:SetHoldType( "melee" )
end

function SWEP:SecondaryAttack()
end

function SWEP:PrimaryAttack()
end

function SWEP:Holster()
    return false
end

function SWEP:Reload()
end