AddCSLuaFile()

ENT.Base = "base_anim"
ENT.cd2_allowpickup = true

local IsValid = IsValid
local random = math.random

function ENT:Initialize()

    if SERVER then
        self:SetModel( "models/props_lab/reciever01b.mdl" )

        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:PhysWake()

        local phys = self:GetPhysicsObject()

        if IsValid( phys ) then phys:SetMass( 30 ) end
    end

    if CLIENT then
        self.cd2_channel = nil -- The current playing BASS Channel

        CD2:CreateThread( function()

            while IsValid( self ) do
                
                self:PlayNextVoice()

                coroutine.wait( 2 )

                while IsValid( self ) and IsValid( self.cd2_channel ) and self.cd2_channel:GetState() != GMOD_CHANNEL_STOPPED do coroutine.yield() end

                coroutine.wait( 10 )
            end

        end )
    end
end

function ENT:OnTakeDamage( info )
    net.Start( "cd2net_explosion" )
    net.WriteVector( self:GetPos() )
    net.WriteFloat( 0.2 )
    net.Broadcast()
    sound.Play( "ambient/levels/labs/electric_explosion1.wav", self:GetPos(), 70, 100, 1 )
    self:Remove()
end

function ENT:Think()
    if CLIENT and IsValid( self.cd2_channel ) then
        self.cd2_channel:SetPos( self:GetPos() )
    end
end

function ENT:OnRemove()
    if IsValid( self.cd2_channel ) then self.cd2_channel:Stop() end
end


-- Plays the next catalina thorne track
function ENT:PlayNextVoice()
    sound.PlayFile( "sound/crackdown2/ambient/radio/catalina" .. random( 1, 5 ) .. ".mp3", "3d mono", function( snd, id, name )
        if id then ErrorNoHaltWithStack( "CD2 Radio had a BASS error! " .. id .. " " .. name ) return end
        self.cd2_channel = snd
    end )
end