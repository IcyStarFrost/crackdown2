AddCSLuaFile()

ENT.Base = "base_anim"

local hex = Material( "crackdown2/effects/skillparticle.png" )
local util_SpriteTrail = util.SpriteTrail
local IsValid = IsValid
local random = math.random

function ENT:Initialize()
    self:SetNoDraw( true )

    if SERVER then
        util_SpriteTrail( self, 0, color_white, true, 30, 10, 1, 1 / ( 5 + 0 ) * 0.5, "trails/laser" )

        self.PathVectors = {}



        if !IsValid( self.Path ) then self:Remove() return end
        for k, v in ipairs( self.Path:GetAllSegments() ) do
            self.PathVectors[ #self.PathVectors + 1 ] = v.pos 
        end
    end

    if CLIENT then
        sound.PlayFile( "sound/crackdown2/ambient/guideambient.mp3", "3d mono", function( snd, id, name )
            if id then return end
        
            snd:Set3DFadeDistance( 300, 1000000000 )
            snd:EnableLooping( true )
            hook.Add( "Think", self, function()
                if self:GetReachedDestination() then snd:Stop() hook.Remove( "Think", self ) return end
                snd:SetPos( self:GetPos() )
            end )
        end )
        self.particledelay = SysTime() + 0.5
    end

    if SERVER then

        CD2CreateThread( function()

            for i = 1, #self.PathVectors do
                if !IsValid( self ) then return end
                local vector = self.PathVectors[ i ] + Vector( 0, 0, 5 )

                while IsValid( self ) and self:GetPos():DistToSqr( vector ) > ( 20 * 20 ) do
                    self:SetPos( self:GetPos() + ( vector - self:GetPos() ):GetNormalized() * 10 )
                    coroutine.yield()
                end

                coroutine.yield()
            end

            if !IsValid( self ) then return end

            self:SetReachedDestination( true )

            coroutine.wait( 3 )
            if !IsValid( self ) then return end

            self:Remove()
        end )

    end

end

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Pather" )
    self:NetworkVar( "Bool", 0, "ReachedDestination" )
end

function ENT:Think()
    if SERVER and !IsValid( self:GetPather() ) then
        self:Remove()
        return
    end
    
    if CLIENT and !self:GetReachedDestination() and SysTime() > self.particledelay then

        local particle = ParticleEmitter( self:GetPos() )

            local part = particle:Add( hex, self:GetPos() )
    
            if part then
                part:SetStartSize( 0 )
                part:SetEndSize( 3 ) 
                part:SetStartAlpha( 255 )
                part:SetEndAlpha( 255 )

                part:SetColor( 255, 255, 255 )
                part:SetLighting( false )
    
                part:SetDieTime( 1 )
                part:SetGravity( Vector() )
                part:SetAirResistance( 0 )
                part:SetVelocity( Vector( random( -50, 50 ), random( -50, 50 ), random( -50, 50 ) ) )
                part:SetAngleVelocity( AngleRand( -1, 1 ) )
            end
        particle:Finish()

        self.particledelay = SysTime() + 0.3
    end
end