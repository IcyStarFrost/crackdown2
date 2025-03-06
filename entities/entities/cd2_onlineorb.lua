AddCSLuaFile()

ENT.Base = "base_anim"

local IsValid = IsValid
local abs = math.abs
local math_sin = math.sin
local max = math.max
local math_cos = math.cos
local pairs = pairs
local ipairs = ipairs

local sprite = Material( "crackdown2/ui/skillglow.png" )

function ENT:Initialize()
    if CLIENT then self.cd2_color = Color( 68, 68, 68 ) end
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

    if CLIENT then
        hook.Add("HUDPaint", self, function() 
            if LocalPlayer():SqrRangeTo( self ) > 70 ^ 2 or !ply:Alive() then return end 

            if !self.cd2_collectedby[ LocalPlayer():SteamID() ] then
                local screen = ( self:GetPos() + Vector( 0, 0, 5 ) ):ToScreen()
                CD2:DrawInputBar( screen.x, screen.y, "", !game.SinglePlayer() and "Not enough players in range!" or "Play with other Agents to collect this orb!" )
            end
        end )
    end

end

function ENT:Draw()
    if !self.cd2_missingplayers[ LocalPlayer():SteamID() ] then return end

    local isfar = LocalPlayer():GetPos():DistToSqr( self:GetPos() ) >= ( 2000 * 2000 )

    self.cd2_color.a = max( abs( math_sin( SysTime() * 2 ) ) * 255, abs( math_cos( SysTime() * 2 ) ) * 255 )

    render.SetColorMaterial()
    render.DrawSphere( self:GetPos(), 15, isfar and 5 or 10, isfar and 5 or 10, self.cd2_color )


    render.SetMaterial( sprite )
    render.DrawSprite( self:GetPos(), 100, 100, self.cd2_color )

end



function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "IsCollected" )
end

function ENT:OnRemove()

    if CLIENT and IsValid( self.cd2_onlineorbsound ) then
        self.cd2_onlineorbsound:Stop()
    end

end

local weaponskillcolor = Color( 0, 225, 255)
local agilityskillcolor = Color( 0, 255, 0 )
local strengthskillcolor = Color( 255, 251, 0)
local explosiveskillcolor = Color( 0, 110, 255 )

function ENT:OnCollected( ply )
    CD2:DebugMessage( ply:Name() .. " collected a agility orb " .. self:EntIndex() )
    self.cd2_missingplayers[ ply:SteamID() ] = false
    self.cd2_collectedby[ ply:SteamID() ] = true

    if CLIENT then
        sound.Play( "crackdown2/ambient/hiddenorb_collect.mp3", self:GetPos(), 80, 100, 1 )    
    end

    if SERVER then

        CD2:SendTextBoxMessage( ply, "Well done. You found a Online Orb!" )

        for i = 1, 6 do
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Agility", 2, agilityskillcolor )
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Weapon", 0.2, weaponskillcolor )
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Strength", 1, strengthskillcolor )
            CD2:CreateSkillGainOrb( self:GetPos(), ply, "Explosive", 0.4, explosiveskillcolor )
        end
    end

    hook.Run( "CD2_OnOnlineOrbCollected", self, ply )
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
    if shouldremove then CD2:DebugMessage( "Online Orb " .. self:EntIndex() .. " has been collected by all players. Removing." ) self:Remove() end
end

function ENT:Think()

    self:CheckPlayers()

    local players = CD2:FindInSphere( self:GetPos(), 70, function( ent ) return ent:IsCD2Agent() end )
    for i = 1, #players do
        local ply = players[ i ]
        if !ply.cd2_onlineorb_notified and SERVER then if !CD2:KeysToTheCity() then ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/onlineorb.mp3" ) end  CD2:SendTextBoxMessage( ply, "Team up with another Agent to collect this Orb!" ) ply.cd2_onlineorb_notified = true end
        if #players > 1 and self.cd2_missingplayers[ ply:SteamID() ] then
            self:OnCollected( ply )
        end
    end
    
    if CLIENT then
        if !self.cd2_missingplayers[ LocalPlayer():SteamID() ] then

            if IsValid( self.cd2_onlineorbsound ) then
                self.cd2_onlineorbsound:Stop()
            end
            
            return
        end

        
        if !self.cd2_onlineorbsound then
            sound.PlayFile( "sound/crackdown2/ambient/orb1.mp3", "3d mono", function( snd, id, name )
                if id then print( id, name ) end
                self.cd2_onlineorbsound = snd
                snd:EnableLooping( true )
                snd:Set3DFadeDistance( 400, 1000000000 )
            end )
        end

        if IsValid( self.cd2_onlineorbsound ) then
            self.cd2_onlineorbsound:SetVolume( self:SqrRangeTo( LocalPlayer() ) < ( 2000 * 2000 ) and 1 or 0 )
            self.cd2_onlineorbsound:SetPos( self:GetPos() )
        end

    end

    if CLIENT then
        self:SetNextClientThink( CurTime() + 0.1 )
    end
    self:NextThink( CurTime() + 0.1 )
    return true
end
