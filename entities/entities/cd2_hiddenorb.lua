AddCSLuaFile()
ENT.Base = "cd2_orbbase"
ENT.AmbientFile = "sound/crackdown2/ambient/hiddenorb.mp3"
local BaseClass = baseclass.Get( "cd2_orbbase" )
local weaponskillcolor = Color( 0, 225, 255)
local agilityskillcolor = Color( 0, 255, 0 )
local strengthskillcolor = Color( 255, 251, 0)
local explosiveskillcolor = Color( 0, 110, 255 )
local beam = Material( "crackdown2/effects/lightbeam.png", "smooth" )

function ENT:Initialize()
    if CLIENT then
        self.glowcolor = Color( 43, 109, 207 )
    end
    BaseClass.Initialize( self )
end

function ENT:Render()

    self.glowcolor.a = math.max( math.abs( math.sin( SysTime() * 2 ) ) * 255, math.abs( math.cos( SysTime() * 2 ) ) * 255 )

    render.SetColorMaterial()
    render.DrawSphere( self:GetPos(), 15, 10, 10, self.glowcolor )

    cam.Start3D2D( self:GetPos(), Angle( 0, CD2.viewangles[ 2 ] + -90, 90 ), 2 )
        surface.SetMaterial( beam )
        surface.SetDrawColor( self.glowcolor )
        surface.DrawTexturedRect( -25, -80, 50, 90 )
    cam.End3D2D()

    local dlight = DynamicLight( self:EntIndex() )

    if dlight then
        dlight.pos = self:GetPos()
		dlight.r = self.glowcolor.r
		dlight.g = self.glowcolor.g
		dlight.b = self.glowcolor.b
		dlight.brightness = 5
		dlight.Decay = 1000
		dlight.Size = 100
		dlight.DieTime = CurTime() + 1
    end
end


function ENT:OnCollected( ply )
    CD2:DebugMessage( ply:Name() .. " collected a Hidden orb " .. self:EntIndex() )

    if CLIENT then
        sound.Play( "crackdown2/ambient/hiddenorb_collect.mp3", self:GetPos(), 80, 100, 1 )    
    end

    if SERVER then

        for i = 1, 6 do
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Agility", 2, agilityskillcolor )
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Weapon", 0.2, weaponskillcolor )
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Strength", 1, strengthskillcolor )
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Explosive", 0.4, explosiveskillcolor )
        end

        local totalcollected, total = self:GetAmountCollected( ply )
        
        CD2:CreateThread( function()
            CD2:SendTextBoxMessage( ply, "Collected " .. totalcollected .. " of " .. total .. " Hidden Orbs" )
            coroutine.wait( 4 )
            CD2:SendTextBoxMessage( ply, "Well done. You found an Hidden Orb! " .. totalcollected .. " Orbs of " .. total .. " collected." )
        end )

        if !CD2:KeysToTheCity() and !ply.cd2_hadfirsthiddenorb then
            CD2:RequestPlayerData( ply, "cd2_firsthiddenorb", function( val ) 
                if !val then
                    ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/firsthiddenorb_achieve.mp3" )
                    CD2:WritePlayerData( ply, "cd2_firsthiddenorb", true )
                end
                ply.cd2_hadfirsthiddenorb = true
            end )
        end
    end

    hook.Run( "CD2_OnHiddenOrbCollected", self, ply )
end