AddCSLuaFile()

ENT.Base = "base_anim"

local IsValid = IsValid
local random = math.random
local beam = Material( "crackdown2/effects/lightbeam.png", "smooth" )
local abs = math.abs
local math_sin = math.sin
local max = math.max
local player_GetAll = player.GetAll
local math_cos = math.cos
local pairs = pairs
local ipairs = ipairs

function ENT:Initialize()
    if CLIENT then self.cd2_color = Color( 43, 109, 207) end
    self:SetModel( "models/error.mdl" )
    self:DrawShadow( false )

    self.cd2_missingplayers = {}

    for k, v in ipairs( player.GetAll() ) do
        self.cd2_missingplayers[ v:SteamID() ] = true
    end

end

function ENT:Draw()
    if !self.cd2_missingplayers[ LocalPlayer():SteamID() ] then return end

    local isfar = LocalPlayer():GetPos():DistToSqr( self:GetPos() ) >= ( 2000 * 2000 )

    self.cd2_color.a = max( abs( math_sin( SysTime() * 2 ) ) * 255, abs( math_cos( SysTime() * 2 ) ) * 255 )

    render.SetColorMaterial()
    render.DrawSphere( self:GetPos(), 15, isfar and 5 or 50, isfar and 5 or 50, self.cd2_color )

    cam.Start3D2D( self:GetPos(), Angle( 0, CD2_viewangles[ 2 ] + -90, 90 ), 2 )
        surface.SetMaterial( beam )
        surface.SetDrawColor( self.cd2_color )
        surface.DrawTexturedRect( -25, -80, 50, 90 )
    cam.End3D2D()

--[[     render.SetMaterial( beam )
    render.DrawSprite( self:GetPos(), 100, 500, self.cd2_color ) ]]

    if isfar then return end

    local dlight = DynamicLight( self:EntIndex() )

    if dlight then
        dlight.pos = self:GetPos()
		dlight.r = self.cd2_color.r
		dlight.g = self.cd2_color.g
		dlight.b = self.cd2_color.b
		dlight.brightness = 5
		dlight.Decay = 1000
		dlight.Size = 100
		dlight.DieTime = CurTime() + 1
    end

end



function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "IsCollected" )
end

function ENT:OnRemove()

    if CLIENT and IsValid( self.cd2_hiddensound ) then
        self.cd2_hiddensound:Stop()
    end

end

local weaponskillcolor = Color( 0, 225, 255)
local agilityskillcolor = Color( 0, 255, 0 )
local strengthskillcolor = Color( 255, 251, 0)
local explosiveskillcolor = Color( 0, 110, 255 )
function ENT:OnCollected( ply )
    CD2DebugMessage( ply:Name() .. " collected a Hidden orb " .. self:EntIndex() )
    self.cd2_missingplayers[ ply:SteamID() ] = false

    if CLIENT then
        sound.Play( "crackdown2/ambient/hiddenorb_collect.mp3", self:GetPos(), 80, 100, 1 )    
        if ply == LocalPlayer() then CD2SetTextBoxText( "Well done. You found a Hidden Orb!" ) end
    end

    if SERVER then

        for i = 1, 6 do
            CD2CreateSkillGainOrb( self:GetPos(), ply, "Agility", 2, agilityskillcolor )
            CD2CreateSkillGainOrb( self:GetPos(), ply, "Weapon", 0.2, weaponskillcolor )
            CD2CreateSkillGainOrb( self:GetPos(), ply, "Strength", 1, strengthskillcolor )
            CD2CreateSkillGainOrb( self:GetPos(), ply, "Explosive", 0.4, explosiveskillcolor )
        end
    end

    hook.Run( "CD2_OnHiddenOrbCollected", self, ply )
end

-- Returns if this orb was collected by the player
function ENT:IsCollectedBy( ply )
    for k, v in pairs( self.cd2_missingplayers ) do
        if k == ply:SteamID() then return false end
    end
    return true
end

function ENT:CheckPlayers()
    if CLIENT then return end
    local shouldremove = true
    for k, v in pairs( self.cd2_missingplayers ) do
        if v then shouldremove = false end
    end
    if shouldremove then CD2DebugMessage( "Hidden Orb " .. self:EntIndex() .. " has been collected by all players. Removing." ) self:Remove() end
end

function ENT:Think()

    self:CheckPlayers()

    local players = player_GetAll()
    for i = 1, #players do
        local ply = players[ i ]
        if IsValid( ply ) and ply:IsCD2Agent() and self.cd2_missingplayers[ ply:SteamID() ] and ply:GetPos():DistToSqr( self:GetPos() ) < ( 40 * 40 ) then
            self:OnCollected( ply )
        end
    end

    if CLIENT then
        if !self.cd2_missingplayers[ LocalPlayer():SteamID() ] then

            if IsValid( self.cd2_hiddensound ) then
                self.cd2_hiddensound:Stop()
            end
            
            return
        end
        
        if !self.cd2_hiddensound then
            sound.PlayFile( "sound/crackdown2/ambient/hiddenorb.mp3", "3d mono", function( snd, id, name )
                if id then print( id, name ) end
                self.cd2_hiddensound = snd
                snd:EnableLooping( true )
                snd:Set3DFadeDistance( 400, 1000000000 )
            end )
        end

        if IsValid( self.cd2_hiddensound ) then
            self.cd2_hiddensound:SetPos( self:GetPos() )
        end

    end

    if CLIENT then
        self:SetNextClientThink( CurTime() + 0.1 )
    end
    self:NextThink( CurTime() + 0.1 )
    return true
end
