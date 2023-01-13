AddCSLuaFile()

ENT.Base = "base_anim"

local beaconblue = Color( 0, 217, 255 )
local blackish = Color( 39, 39, 39 )
local linecol = Color( 61, 61, 61, 100 )
local energy = Material( "crackdown2/effects/energy.png" )
local beam = Material( "crackdown2/effects/beam.png", "smooth" )
local peacekeeper = Material( "crackdown2/ui/peacekeeper.png", "smooth" )
local beaconiconcol = Color( 0, 110, 255 )

function ENT:Initialize()
    self:SetModel( "models/props_combine/combinethumper002.mdl" )
    self:SetModelScale( 0.5 )

    self.cd2_nextchargepoint = 0

    if CLIENT then
        hook.Add( "HUDPaint", self, function()
            if self:GetActive() or self:SqrRangeTo( LocalPlayer() ) > ( 300 * 300 ) then return end
        
            -- Base
            surface.SetDrawColor( blackish )
            draw.NoTexture()
            surface.DrawRect( ScrW() - 350,  45, 300, 30 )
        
            surface.SetDrawColor( linecol )
            surface.DrawOutlinedRect( ScrW() - 350,  45, 300, 30, 1 )
            --

            -- Icon
            surface.SetDrawColor( color_white )
            surface.SetMaterial( peacekeeper )
            surface.DrawTexturedRect( ScrW() - 440,  30, 80, 64 )
            --

            -- AU Progress bar
            surface.SetDrawColor( beaconiconcol )
            surface.DrawRect( ScrW() - 340, 55, ( self:GetCharge() / 100 ) * 280, 10 )
        
            surface.SetDrawColor( linecol )
            surface.DrawOutlinedRect( ScrW() - 345,  50, 290, 20, 1 )
        end )


        hook.Add( "PreDrawEffects", self, function()
            if self:GetActive() then
       
                render.SetMaterial( beam )
                render.DrawBeam( self:WorldSpaceCenter() + Vector( 0, 0, 30 ), self:GetBeamPos(), 30, 0, math.random( 0, 400 ), beaconblue )
        
                if SysTime() > self.cd2_nextparticle and LocalPlayer():SqrRangeTo( self ) < ( 2000 * 2000 ) then
                    local particle = ParticleEmitter( self:WorldSpaceCenter() + Vector( 0, 0, 30 ) )
                    local part = particle:Add( energy, self:WorldSpaceCenter() + Vector( 0, 0, 30 ) )
        
                    if part then
                        part:SetStartSize( 10 )
                        part:SetEndSize( 10 ) 
                        part:SetStartAlpha( 255 )
                        part:SetEndAlpha( 0 )
                
                        part:SetColor( 255, 255, 255 )
                        part:SetLighting( false )
                        part:SetCollide( false )
                
                        part:SetDieTime( 2 )
                        part:SetGravity( Vector() )
                        part:SetAirResistance( 300 )
                        part:SetVelocity( VectorRand( -200, 200 ) + ( self:GetBeamPos() - ( self:WorldSpaceCenter() + Vector( 0, 0, 30 ) ) ):GetNormalized() * 200 )
                        part:SetAngleVelocity( AngleRand( -1, 1 ) )
                    end
        
                    particle:Finish()
                    self.cd2_nextparticle = SysTime() + 0.08
                end
            end
        end )
    end

    if CLIENT then self.cd2_nextparticle = 0 end
end

function ENT:SetupDataTables()
    self:NetworkVar( "Float", 0, "Charge" )
    self:NetworkVar( "Int", 0, "AUGroupID" )
    self:NetworkVar( "Bool", 0, "Active" )
    self:NetworkVar( "Vector", 0, "BeamPos" )
end

function ENT:TypingText() 
    local AUs = ents.FindByClass( "cd2_au" )
    local othercount = 0
    for i = 1, #AUs do
        local au = AUs[ i ]
        if IsValid( au ) and au:GetActive() and au:GetAUGroupID() == self:GetAUGroupID() then
            othercount = othercount + 1
        end
    end

    if othercount == 3 then
        hook.Run( "CD2_PowerNetworkComplete", self:GetAUGroupID() )
        CD2SetTypingText( nil, "OBJECTIVE COMPLETE!", "Absorption Unit Activated\nA Beacon can now be deployed" )
    elseif othercount > 0 then
        CD2SetTypingText( nil, "OBJECTIVE COMPLETE!", "Absorption Unit Activated\n" .. othercount .. " of 3 units active" )
    end
end

function ENT:EnableBeam() 
    if SERVER then
        self:SetActive( true )
        BroadcastLua( "Entity(" .. self:EntIndex() .. "):EnableBeam()")
    elseif CLIENT then
        sound.PlayFile( "sound/crackdown2/ambient/au/charged.mp3", " 3d mono noplay", function( snd, id, name )
            if id then return end
            snd:SetVolume( 2 )
            snd:SetPos( self:GetPos() )
            snd:Play()
        end )

        sound.PlayFile( "sound/crackdown2/ambient/au/beamfire2.mp3", " 3d mono noplay", function( snd, id, name )
            if id then return end
            snd:SetVolume( 10 )
            snd:SetPos( self:GetPos() )
            snd:Play()
        end )

        sound.PlayFile( "sound/crackdown2/ambient/au/auambient.mp3", " 3d mono noplay", function( snd, id, name )
            if id then return end
            self.cd2_ambientsnd = snd
            snd:EnableLooping( true )
            snd:SetVolume( 8 )
            snd:Set3DFadeDistance( 300, 1000000000 )
            snd:SetPos( self:GetPos() )
            snd:Play()
        end )
    end
end

function ENT:OnRemove()
    if CLIENT then
        if IsValid( self.cd2_ambientsnd ) then self.cd2_ambientsnd:Stop() end
    end
end

function ENT:Think()

    if CLIENT and IsValid( self.cd2_ambientsnd ) then
        self.cd2_ambientsnd:SetVolume( self:SqrRangeTo( LocalPlayer() ) > ( 1000 * 1000 ) and 0 or 1 )
    end

    if CLIENT or self:GetActive() then return end

    local nearplayers = CD2FindInSphere( self:GetPos(), 100, function( ent ) return ent:IsCD2Agent() end )
    if #nearplayers > 0 and CurTime() > self.cd2_nextchargepoint then
        if !self.cd2_first then
            self:EmitSound( "crackdown2/ambient/au/chargenew" .. math.random( 1, 4 ) .. ".mp3", 80 )
            self.cd2_first = true
        end
        self:SetCharge( self:GetCharge() + 1 )

        if self:GetCharge() >= 100 then
            self:EnableBeam() 
            self:TypingText() 
        end

        if !self.cd2_nextsound or CurTime() > self.cd2_nextsound then
            self:EmitSound( "plats/elevbell1.wav", 60, 200, 0.5 )
            self.cd2_nextsound = CurTime() + 1
        end

        self.cd2_nextchargepoint = CurTime() + ( 0.1 / #nearplayers )
    elseif #nearplayers == 0 then
        self:SetCharge( Lerp( 1 * FrameTime(), self:GetCharge(), 0 ) )
        self.cd2_first = false
    end
    
end

function ENT:Draw() 
    self:DrawModel()
end