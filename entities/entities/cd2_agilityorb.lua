AddCSLuaFile()

ENT.Base = "base_anim"

local IsValid = IsValid
local beam = Material( "crackdown2/effects/lightbeam.png", "smooth" )
local abs = math.abs
local math_sin = math.sin
local max = math.max
local player_GetAll = player.GetAll
local math_cos = math.cos
local pairs = pairs
local ipairs = ipairs

function ENT:Initialize()
    if CLIENT then self.cd2_color = Color( 43, 207, 43 ) end
    self:SetModel( "models/error.mdl" )
    self:DrawShadow( false )

    self.cd2_missingplayers = {}
    self.cd2_collectedby = {}

    for k, v in ipairs( player.GetAll() ) do
        self.cd2_missingplayers[ v:SteamID() ] = true
    end

    if SERVER then
        hook.Add( "PlayerInitialSpawn", self, function( self, ply ) 
            if self.cd2_collectedby[ ply:SteamID() ] then return end
            self.cd2_missingplayers[ ply:SteamID() ] = true
        end )
    end


end

function ENT:Draw()
    if !self.cd2_missingplayers[ LocalPlayer():SteamID() ] then return end

    local isfar = LocalPlayer():GetPos():DistToSqr( self:GetPos() ) >= ( 2000 * 2000 )
    local istoofar = LocalPlayer():GetPos():DistToSqr( self:GetPos() ) >= ( 7000 * 7000 )

    self.cd2_color.a = max( abs( math_sin( SysTime() * 2 ) ) * 255, abs( math_cos( SysTime() * 2 ) ) * 255 )

    render.SetColorMaterial()
    render.DrawSphere( self:GetPos(), 15, isfar and 5 or 10, isfar and 5 or 10, self.cd2_color )

    if istoofar then return end

    for i = 1, self:GetLevel() do
        render.SetColorMaterial()
        render.DrawSphere( ( self:GetPos() + Vector( 0, 0, 20 ) ) + Vector( 0, 0, 20 * i ) , 5, isfar and 5 or 10, isfar and 5 or 10, self.cd2_color )
    end

    cam.Start3D2D( self:GetPos(), Angle( 0, CD2_viewangles[ 2 ] + -90, 90 ), 2 )
        surface.SetMaterial( beam )
        surface.SetDrawColor( self.cd2_color )
        surface.DrawTexturedRect( -25, -140, 50, 150 )
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
		dlight.Size = 400
		dlight.DieTime = CurTime() + 1
    end

end



function ENT:SetupDataTables()
    self:NetworkVar( "Int", 0, "Level" )
    self:NetworkVar( "Bool", 0, "IsCollected" )
end

function ENT:OnRemove()

    if CLIENT and IsValid( self.cd2_agilitysound ) then
        self.cd2_agilitysound:Stop()
    end

end

function ENT:OnCollected( ply )
    CD2DebugMessage( ply:Name() .. " collected a agility orb " .. self:EntIndex() )
    self.cd2_missingplayers[ ply:SteamID() ] = false
    self.cd2_collectedby[ ply:SteamID() ] = true

    if CLIENT then
        sound.Play( "crackdown2/ambient/agilityorbcollect.mp3", self:GetPos(), 80, 100, 1 )    
    end

    if SERVER then
        local orbcount = 4 * self:GetLevel()

        for i = 1, orbcount do
            CD2CreateSkillGainOrb( self:GetPos(), ply, "Agility", 2, Color( 0, 255, 0 ) )
        end

        CD2SendTextBoxMessage( ply, "Well done. You found a Agility Orb!" )

        if !KeysToTheCity() and !ply.cd2_InTutorial and !ply.cd2_hadfirstagilityorb then
            CD2FILESYSTEM:RequestPlayerData( ply, "cd2_firstagilityorb", function( val ) 
                if !val then
                    ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/firstagilityorb_achieve.mp3" )
                    CD2FILESYSTEM:WritePlayerData( ply, "cd2_firstagilityorb", true )
                end
                ply.cd2_hadfirstagilityorb = true
            end )
        end
    end

    hook.Run( "CD2_OnAgilityOrbCollected", self, ply )
end

-- Returns if this orb was collected by the player
function ENT:IsCollectedBy( ply )
    return self.cd2_collectedby[ ply:SteamID() ]
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

    local players = player_GetAll()
    for i = 1, #players do
        local ply = players[ i ]
        if IsValid( ply ) and ply:IsCD2Agent() and self.cd2_missingplayers[ ply:SteamID() ] and ply:SqrRangeTo( self ) < ( 40 * 40 ) then
            self:OnCollected( ply )
        end
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
                snd:Set3DFadeDistance( 200, 1000000000 )
            end )
        end

        if IsValid( self.cd2_agilitysound ) then
            self.cd2_agilitysound:SetVolume( self:SqrRangeTo( LocalPlayer() ) < ( 2000 * 2000 ) and 1 or 0 )
            self.cd2_agilitysound:SetPos( self:GetPos() )
        end

    end

    if CLIENT then
        self:SetNextClientThink( CurTime() + 0.1 )
    end
    self:NextThink( CurTime() + 0.1 )
    return true
end
