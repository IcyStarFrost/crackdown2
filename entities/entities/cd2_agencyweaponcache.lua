AddCSLuaFile()

ENT.Base = "base_anim"

local agencyweapons = { "cd2_assaultrifle", "cd2_uvshotgun", "cd2_shotgun", "cd2_grenade", "cd2_uvgrenade" }

function ENT:Initialize()
    self:SetModel( "models/items/ammocrate_ar2.mdl" )

    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetSolid( SOLID_VPHYSICS )

    local pos1 = ( self:GetPos() + Vector( 0, 0, 5 ) ) + self:GetForward() * 50 + self:GetRight() * 50
    local pos2 = ( self:GetPos() + Vector( 0, 0, 5 ) ) + self:GetForward() * 50 - self:GetRight() * 50
    local pos3 = ( self:GetPos() + Vector( 0, 0, 5 ) ) - self:GetForward() * 50 + self:GetRight() * 50
    local pos4 = ( self:GetPos() + Vector( 0, 0, 5 ) ) - self:GetForward() * 50 - self:GetRight() * 50
    self.cd2_positions = { pos1, pos2, pos3, pos4 }

    if SERVER then self.cd2_weapons = {} self.cd2_nextspawn = 0 end
end

function ENT:SpawnNewWeapon()
    if #self.cd2_weapons + 1 > 4 then return end
    local position = self.cd2_positions[ #self.cd2_weapons + 1 ]

    local wep = ents.Create( agencyweapons[ math.random( #agencyweapons ) ] )
    wep:SetPos( position )
    wep:SetPermanentDrop( true )
    wep:Spawn()

    self.cd2_weapons[ #self.cd2_weapons + 1 ] = wep
end

function ENT:OnRemove()
    if CLIENT then return end
    for k, wep in ipairs( self.cd2_weapons ) do
        if IsValid( wep ) then wep:Remove() end
    end
end

function ENT:Think()
    if CLIENT then return end

    for k, wep in ipairs( self.cd2_weapons ) do
        if !IsValid( wep ) then table.remove( self.cd2_weapons, k ) continue end
        if IsValid( wep:GetOwner() ) then wep:SetPermanentDrop( false ) table.remove( self.cd2_weapons, k ) end
    end

    if CurTime() > self.cd2_nextspawn and #self.cd2_weapons < 4 then
        self:SpawnNewWeapon()
        self.cd2_nextspawn = CurTime() + 20
    end

end