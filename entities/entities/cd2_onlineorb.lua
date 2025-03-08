AddCSLuaFile()

local BaseClass = baseclass.Get( "cd2_orbbase" )
ENT.Base = "cd2_orbbase"
ENT.AmbientFile = "sound/crackdown2/ambient/orb1.mp3"

local weaponskillcolor = Color( 0, 225, 255)
local agilityskillcolor = Color( 0, 255, 0 )
local strengthskillcolor = Color( 255, 251, 0)
local explosiveskillcolor = Color( 0, 110, 255 )
local sprite = Material( "crackdown2/ui/skillglow.png" )

function ENT:Initialize()
    if CLIENT then
        self.glowcolor = Color( 68, 68, 68 )

        hook.Add("HUDPaint", self, function() 
            if LocalPlayer():SqrRangeTo( self ) > 70 ^ 2 or !LocalPlayer():Alive() then return end 

            if !self:IsCollectedBy( LocalPlayer() ) then
                local screen = ( self:GetPos() + Vector( 0, 0, 5 ) ):ToScreen()
                CD2:DrawInputBar( screen.x, screen.y, "", !game.SinglePlayer() and "Not enough players in range!" or "Play with other Agents to collect this orb!" )
            end
        end )
    end

    BaseClass.Initialize( self )
end

function ENT:Render()
    self.glowcolor.a = math.max( math.abs( math.sin( SysTime() * 2 ) ) * 255, math.abs( math.cos( SysTime() * 2 ) ) * 255 )

    render.SetColorMaterial()
    render.DrawSphere( self:GetPos(), 15, 10, 10, self.glowcolor )

    render.SetMaterial( sprite )
    render.DrawSprite( self:GetPos(), 100, 100, self.glowcolor )
end

function ENT:CanBeCollected( ply )
    local players = 0
    for _, ent in ipairs( ents.FindInSphere( self:GetPos(), 80 ) ) do
        if ent:IsPlayer() then
            players = players + 1
        end
    end
    return players > 1
end

function ENT:OnCollected( ply )
    CD2:DebugMessage( ply:Name() .. " collected an Online orb " .. self:EntIndex() )

    if CLIENT then
        sound.Play( "crackdown2/ambient/hiddenorb_collect.mp3", self:GetPos(), 80, 100, 1 )    
    end

    if SERVER then

        local totalcollected, total = self:GetAmountCollected( ply )

        CD2:CreateThread( function()
            CD2:SendTextBoxMessage( ply, "Collected " .. totalcollected .. " of " .. total .. " Online Orbs" )
            coroutine.wait( 4 )
            CD2:SendTextBoxMessage( ply, "Well done. You found an Online Orb! " .. totalcollected .. " Orbs of " .. total .. " collected." )
        end )

        for i = 1, 6 do
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Agility", 2, agilityskillcolor )
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Weapon", 0.2, weaponskillcolor )
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Strength", 1, strengthskillcolor )
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Explosive", 0.4, explosiveskillcolor )
        end
    end

    hook.Run( "CD2_OnOnlineOrbCollected", self, ply )
end