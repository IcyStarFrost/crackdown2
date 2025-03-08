AddCSLuaFile()

local BaseClass = baseclass.Get( "cd2_orbbase" )
ENT.Base = "cd2_orbbase"
ENT.AmbientFile = "sound/crackdown2/ambient/agilityorb_stereo.mp3"

local beam = Material( "crackdown2/effects/lightbeam.png", "smooth" )

function ENT:Initialize()
    if CLIENT then
        self.glowcolor = Color( 43, 207, 43 )
    end
    BaseClass.Initialize( self )
end

function ENT:Render()
    self.glowcolor.a = math.max( math.abs( math.sin( SysTime() * 2 ) ) * 255, math.abs( math.cos( SysTime() * 2 ) ) * 255 )

    render.SetColorMaterial()
    render.DrawSphere( self:GetPos(), 15, 10, 10, self.glowcolor )

    for i = 1, self:GetLevel() do
        render.SetColorMaterial()
        render.DrawSphere( ( self:GetPos() + Vector( 0, 0, 20 ) ) + Vector( 0, 0, 20 * i ) , 5, 10, 10, self.glowcolor )
    end

    cam.Start3D2D( self:GetPos(), Angle( 0, CD2.viewangles[ 2 ] + -90, 90 ), 2 )
        surface.SetMaterial( beam )
        surface.SetDrawColor( self.glowcolor )
        surface.DrawTexturedRect( -25, -140, 50, 150 )
    cam.End3D2D()

    local dlight = DynamicLight( self:EntIndex() )

    if dlight then
        dlight.pos = self:GetPos()
		dlight.r = self.glowcolor.r
		dlight.g = self.glowcolor.g
		dlight.b = self.glowcolor.b
		dlight.brightness = 5
		dlight.Decay = 1000
		dlight.Size = 400
		dlight.DieTime = CurTime() + 1
    end
end

function ENT:OnCollected( ply )
    CD2:DebugMessage( ply:Name() .. " collected a agility orb " .. self:EntIndex() )

    if CLIENT then
        sound.Play( "crackdown2/ambient/agilityorbcollect.mp3", self:GetPos(), 80, 100, 1 )    
    end

    if SERVER then
        local orbcount = 4 * self:GetLevel()

        for i = 1, orbcount do
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Agility", 2, Color( 0, 255, 0 ) )
        end

        local totalcollected, total = self:GetAmountCollected( ply )

        CD2:SendTextBoxMessage( ply, "Collected " .. totalcollected .. " of " .. total .. " Agility Orbs" )
        CD2:SendTextBoxMessage( ply, "Well done. You found an Agility Orb! " .. totalcollected .. " Orbs of " .. total .. " collected." )

        if !CD2:KeysToTheCity() and !ply.cd2_InTutorial and !ply.cd2_hadfirstagilityorb then
            CD2:RequestPlayerData( ply, "cd2_firstagilityorb", function( val ) 
                if !val then
                    ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/firstagilityorb_achieve.mp3" )
                    CD2:WritePlayerData( ply, "cd2_firstagilityorb", true )
                end
                ply.cd2_hadfirstagilityorb = true
            end )
        end
    end

    hook.Run( "CD2_OnAgilityOrbCollected", self, ply )
end

function ENT:SetupDataTables()
    self:NetworkVar( "Int", 0, "Level" )
end