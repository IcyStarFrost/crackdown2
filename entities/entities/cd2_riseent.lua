AddCSLuaFile()

ENT.Base = "base_anim"
ENT.AutomaticFrameAdvance = true

local anims = { "zombie_slump_rise_02_fast", "zombie_slump_rise_01" }
local random = math.random
function ENT:Initialize()
    self:SetModel( self:GetPlayer():GetModel() )

    CD2:CreateThread( function()
        local len = self:SetSequence( anims[ random( 2 ) ] )
        self:ResetSequenceInfo()
        self:SetCycle( 0 )
        self:SetPlaybackRate( 3 )
        coroutine.wait( len / 3 )
        if !IsValid( self ) or !IsValid( self:GetPlayer() ) then return end
        if SERVER then self:Remove() self:Callback() end
    end )

    self.GetPlayerColor = function() return self:GetPlayer():GetPlayerColor() end
end

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Player" )
end

function ENT:Think()
    if SERVER and !self:GetPlayer():Alive() then self:Remove() end
	self:NextThink( CurTime() )
	return true
end