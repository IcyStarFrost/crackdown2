AddCSLuaFile()

ENT.Base = "base_anim"

local IsValid = IsValid
local LerpVector = LerpVector
local util_SpriteTrail = util.SpriteTrail

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel( "models/error.mdl" )
    self:SetNoDraw( true )
    self:DrawShadow( false )

    self.cd2_killtime = CurTime() + 1

    util_SpriteTrail( self, 0, color_white, true, 5, 0, 1, 1 / ( 5 + 0 ) * 0.5, "trails/laser" )
end

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Player" )
end

function ENT:Think()
    if CLIENT then return end
    if CurTime() > self.cd2_killtime then self:Remove() return end

    if IsValid( self:GetPlayer() ) then
        self:SetPos( LerpVector( 50 * FrameTime(), self:GetPos(), self:GetPlayer():WorldSpaceCenter() ) )
    end

end
