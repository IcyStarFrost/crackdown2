AddCSLuaFile()

ENT.Base = "base_anim"

local IsValid = IsValid
local random = math.random
local beam = Material( "crackdown2/effects/lightbeam.png", "smooth" )
local abs = math.abs
local math_sin = math.sin
local max = math.max
local math_cos = math.cos
local pairs = pairs
local ipairs = ipairs

function ENT:Initialize()
    if CLIENT then self.cd2_color = Color( 43, 207, 43 ) end
    self:SetModel( "models/error.mdl" )
    self:DrawShadow( false )

    self.cd2_missingplayers = {}

    for k, v in ipairs( player.GetAll() ) do
        self.cd2_missingplayers[ v:SteamID() ] = true
    end

end

function ENT:Draw()
    if !self.cd2_missingplayers[ LocalPlayer():SteamID() ] then return end

    self.cd2_color.a = max( abs( math_sin( SysTime() * 2 ) ) * 255, abs( math_cos( SysTime() * 2 ) ) * 255 )

    render.SetColorMaterial()
    render.DrawSphere( self:GetPos(), 15, 50, 50, self.cd2_color )

    for i = 1, self:GetLevel() do
        render.SetColorMaterial()
        render.DrawSphere( ( self:GetPos() + Vector( 0, 0, 20 ) ) + Vector( 0, 0, 20 * i ) , 5, 30, 30, self.cd2_color )
    end

    cam.Start3D2D( self:GetPos(), Angle( 0, CD2_viewangles[ 2 ] + -90, 90 ), 2 )
        surface.SetMaterial( beam )
        surface.SetDrawColor( self.cd2_color )
        surface.DrawTexturedRect( -25, -140, 50, 150 )
    cam.End3D2D()

--[[     render.SetMaterial( beam )
    render.DrawSprite( self:GetPos(), 100, 500, self.cd2_color ) ]]

    local dlight = DynamicLight( self:EntIndex() )

    if dlight then
        dlight.pos = self:GetPos()
		dlight.r = self.cd2_color.r
		dlight.g = self.cd2_color.g
		dlight.b = self.cd2_color.b
		dlight.brightness = 5
		dlight.Decay = 1000
		dlight.Size = 400
		dlight.DieTime = CurTime() + 1
    end

end



function ENT:SetupDataTables()
    self:NetworkVar( "Int", 0, "Level" )
    self:NetworkVar( "Bool", 0, "IsCollected" )

    self:SetLevel( 1 )
end

function ENT:OnRemove()

    if CLIENT and IsValid( self.cd2_agilitysound ) then
        self.cd2_agilitysound:Stop()
    end

end

function ENT:OnCollected( ply )
    CD2DebugMessage( ply:Name() .. " collected a agility orb " .. self:EntIndex() )

    if CLIENT then
        sound.Play( "crackdown2/ambient/agilityorbcollect.mp3", self:GetPos(), 80, 100, 1 )    
        CD2SetTextBoxText( "Well done. You found a Agility Orb!" )
    end

    if SERVER then
        local orbcount = 4 * self:GetLevel()

        for i = 1, orbcount do
            CD2CreateSkillGainOrb( self:GetPos(), ply, "nil", 0, Color( 0, 255, 0 ) )
        end
    end
end

function ENT:CheckPlayers()
    if CLIENT then return end
    local shouldremove = true
    for k, v in pairs( self.cd2_missingplayers ) do
        if v then shouldremove = false end
    end
    if shouldremove then CD2DebugMessage( "Agility Orb " .. self:EntIndex() .. " has been collected by all players. Removing." ) self:Remove() end
end

function ENT:Think()

    self:CheckPlayers()

    local near = CD2FindInSphere( self:GetPos(), 40, function( ent ) return ent:IsCD2Agent() and self.cd2_missingplayers[ ent:SteamID() ] end )

    for k, v in ipairs( near ) do
        self:OnCollected( v )
        self.cd2_missingplayers[ v:SteamID() ] = false
    end

    if CLIENT then
        if !self.cd2_missingplayers[ LocalPlayer():SteamID() ] then

            if IsValid( self.cd2_agilitysound ) then
                self.cd2_agilitysound:Stop()
            end
            
            return
        end
        
        if !self.cd2_agilitysound then
            sound.PlayFile( "sound/crackdown2/ambient/agilityorb_stereo.mp3", "3d mono", function( snd, id, name )
                if id then print( id, name ) end
                self.cd2_agilitysound = snd
                snd:EnableLooping( true )
            end )
        end

        if IsValid( self.cd2_agilitysound ) then
            self.cd2_agilitysound:SetPos( self:GetPos() )
        end

    end

    if CLIENT then
        self:SetNextClientThink( CurTime() + 0.1)
    end
    self:NextThink( CurTime() + 0.1 )
    return true
end
