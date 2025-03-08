AddCSLuaFile()

ENT.Base = "base_anim"

ENT.AmbientFile = nil -- Filepath to the ambient sound
ENT.CollectionRange = 40

function ENT:Initialize()
    self:SetModel( "models/error.mdl" )
    self:DrawShadow( false )

    self.collectedby = {} -- Table of steamids that have collected this orb
end

-- Function meant to draw the visuals of the orb
function ENT:Render()
end

function ENT:Draw()
    if self.collectedby[ LocalPlayer():SteamID() ] then return end

    self:Render()
end

function ENT:OnRemove()
    if IsValid( self.ambientsound ) then
        self.ambientsound:Stop()
    end
end

-- If the given player can collect this orb
function ENT:CanBeCollected( ply )
    return true
end

function ENT:HandleAmbientSound()
    if self:IsCollectedBy( LocalPlayer() ) then
        if IsValid( self.ambientsound ) then
            self.ambientsound:Stop()
        end
        return
    end
    
    if self.AmbientFile and !IsValid( self.ambientsound ) and !self.startingambientsound then
        self.startingambientsound = true

        sound.PlayFile( self.AmbientFile, "3d mono noplay", function( snd )
            self.ambientsound = snd
            self.startingambientsound = false

            snd:SetPos( self:GetPos() )
            snd:EnableLooping( true )
            snd:Set3DFadeDistance( 200, 1000000000 )

            snd:Play()
        end )
    end
end

-- Returns the amount of orbs of this type the player collected and the total amount of orbs that exist
function ENT:GetAmountCollected( ply )
    local class = self:GetClass()
    local total = 0
    local totalcollected = 0
    for _, ent in ents.Iterator() do
        if ent:GetClass() == class then
            total = total + 1

            if ent:IsCollectedBy( ply ) then
                totalcollected = totalcollected + 1
            end
        end
    end

    return totalcollected, total
end

-- Returns whether ply had collected this orb
function ENT:IsCollectedBy( ply )
    return self.collectedby[ ply:SteamID() ]
end

-- Called when this orb is collected by a player
function ENT:OnCollected( ply )
end

function ENT:AwaitPlayerCollection()
    for _, ply in player.Iterator() do
        if IsValid( ply ) and ply:IsCD2Agent() and !self:IsCollectedBy( ply ) and ply:SqrRangeTo( self ) < self.CollectionRange ^ 2 and self:CanBeCollected( ply ) then
            self.collectedby[ ply:SteamID() ] = true
            self:OnCollected( ply )
            net.Start( "cd2net_orbcollected" )
            net.WriteEntity( self )
            net.Send( ply )
        end
    end
end

function ENT:Think()
    if CLIENT then
        self:HandleAmbientSound()
    elseif SERVER then
        self:AwaitPlayerCollection()
    end
end

net.Receive( "cd2net_orbcollected", function()
    local orb = net.ReadEntity()

    if IsValid( orb ) then
        orb.collectedby[ LocalPlayer():SteamID() ] = true
        orb:OnCollected( LocalPlayer() )
    end
end )