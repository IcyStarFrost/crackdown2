AddCSLuaFile()
ENT.Base = "base_anim"

local beaconblue = Color( 0, 217, 255 )
local blackish = Color( 39, 39, 39 )
local linecol = Color( 61, 61, 61, 100 )
local energy = Material( "crackdown2/effects/energy.png", "smooth" )
local beam = Material( "crackdown2/effects/beam.png", "smooth" )
local peacekeeper = Material( "crackdown2/ui/peacekeeper.png", "smooth" )
local beaconiconcol = Color( 0, 110, 255 )

function ENT:Initialize()
    if SERVER then
        self:SetModel( "models/props_combine/combinethumper002.mdl" )
        self:SetModelScale( 0.5 )

        self.au_nextcharge = 0
    end

    if CLIENT then
        self.cd2_nextparticle = 0 


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


        CD2:SetupProgressBar( self, 500, function( ply, index )
            if !GetConVar( "cd2_drawhud" ):GetBool() then return end
            if self:GetActive() then return end

            local y = 100 * index
        
            -- Base
            surface.SetDrawColor( blackish )
            draw.NoTexture()
            surface.DrawRect( ScrW() - 350,  45 + y, 300, 30 )
        
            surface.SetDrawColor( linecol )
            surface.DrawOutlinedRect( ScrW() - 350,  45 + y, 300, 30, 1 )
            --

            -- Icon
            surface.SetDrawColor( color_white )
            surface.SetMaterial( peacekeeper )
            surface.DrawTexturedRect( ScrW() - 440,  30 + y, 80, 64 )
            --

            -- AU Progress bar
            surface.SetDrawColor( beaconiconcol )
            surface.DrawRect( ScrW() - 340, 55 + y, ( self:GetCharge() / 100 ) * 280, 10 )
        
            surface.SetDrawColor( linecol )
            surface.DrawOutlinedRect( ScrW() - 345,  50 + y, 290, 20, 1 )

            return true
        end )
    end
end

function ENT:SetupDataTables()
    self:NetworkVar( "Float", 0, "Charge" )
    self:NetworkVar( "Int", 0, "AUGroupID" )
    self:NetworkVar( "Vector", 0, "BeamPos" )
    self:NetworkVar( "Bool", 0, "Active" )
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end


-- Takes care of all the ambient sounds and firing effects
function ENT:HandleSounds()
    if self:GetActive() and !IsValid( self.au_ambient ) and !self.au_attemptingambient then
        self.au_attemptingambient = true

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


        sound.PlayFile( "sound/crackdown2/ambient/au/auambient.mp3", "3d mono noplay", function( snd )
            self.au_ambient = snd
            self.au_attemptingambient = false
            snd:EnableLooping( true )
            snd:SetVolume( 8 )
            snd:Set3DFadeDistance( 500, 1000000000 )
            snd:SetPos( self:GetPos() )
            snd:Play()
        end )
    end
end

-- Gets the total amount of players charging this AU
function ENT:GetNearbyPlayerCount()
    local total = 0
    for _, ply in player.Iterator() do
        if ply:IsCD2Agent() and ply:Alive() and ply:SqrRangeTo( self ) < 100 ^ 2 then
            total = total + 1
        end
    end
    return total
end

function ENT:CompletedText()

    -- Get active AUs
    local AUs = ents.FindByClass( "cd2_au" )
    local totalactive = 0
    local totalgroupactive = 0
    for _, au in ipairs( AUs ) do
        if au:GetActive() then
            totalactive = totalactive + 1
        end

        if au:GetActive() and au:GetAUGroupID() == self:GetAUGroupID() then
            totalgroupactive = totalgroupactive + 1
        end
    end

    -- Achievement thing
    if !CD2:KeysToTheCity() and ( CD2.BeaconCount * 3 ) == activecount then
        for _, ply in player.Iterator() do
            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/allau_achieve.mp3" )
        end
    end

    if totalgroupactive == 3 then
        hook.Run( "CD2_PowerNetworkComplete", self:GetAUGroupID() )
    end

    for k, ply in player.Iterator() do
        if ply:SqrRangeTo( self ) > 1000 ^ 2 then continue end

        if totalgroupactive == 3 then
            CD2:SetTypingText( ply, "OBJECTIVE COMPLETE!", "Absorption Unit Activated\nA Beacon can now be deployed" )
        elseif totalgroupactive > 0 then
            CD2:SetTypingText( ply, "OBJECTIVE COMPLETE!", "Absorption Unit Activated\n" .. totalgroupactive .. " of 3 units active" )
        end
    end
end

-- Checks if this was a player's first AU activation
function ENT:FirstPlyAUCheck()
    if !CD2:KeysToTheCity() then
        for _, ply in player.Iterator() do
            if ply.cd2_hadfirstau or ply:SqrRangeTo( self ) > 100 ^ 2 then continue end

            CD2:RequestPlayerData( ply, "cd2_firstau", function( val ) 
                if !val then
                    ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/firstau_achieve.mp3" )
                    CD2:WritePlayerData( ply, "cd2_firstau", true )
                end
                ply.cd2_hadfirstau = true
            end )
        end
    end
end

function ENT:CompleteCharge()
    self:SetActive( true )
    CD2:DebugMessage( self, "AU unit of Group " .. self:GetAUGroupID() .. " has been activated" )
    hook.Run( "CD2_AUActivated", self )

    self:CompletedText()
    self:FirstPlyAUCheck()
end

function ENT:Ping()
    if !self.cd2_nextsound or CurTime() > self.cd2_nextsound then
        self:EmitSound( "plats/elevbell1.wav", 60, 200, 0.5 )
        self.cd2_nextsound = CurTime() + 1
    end
end

function ENT:SpatialCharging()
    local playersnear = false

    for _, ply in player.Iterator() do
        if ply:IsCD2Agent() and ply:Alive() and ply:SqrRangeTo( self ) < 100 ^ 2 then
            playersnear = true

            if CurTime() > self.au_nextcharge then
                local nearestplayers = self:GetNearbyPlayerCount()

                self:SetCharge( self:GetCharge() + ( 2 * nearestplayers ) )

                self.au_nextcharge = CurTime() + ( 0.1 / nearestplayers )
            end

        end
    end

    

    if playersnear then
        self:Ping()

        if !self.au_startedcharge then
            self:EmitSound( "crackdown2/ambient/au/chargenew" .. math.random( 1, 4 ) .. ".mp3", 80 )
            self.au_startedcharge = true
        end
    else
        self.au_startedcharge = false

        if self.au_nextcharge < CurTime() and self:GetCharge() > 0 then
            self:SetCharge( self:GetCharge() - 1 )
            self.au_nextcharge = CurTime() + 0.1
        end
    end
end

function ENT:Think()
    if CLIENT then
        self:HandleSounds()
    end

    if SERVER and !self:GetActive() then
        self:SpatialCharging()
    end

    
    if SERVER and self:GetCharge() >= 100 and !self:GetActive() then
        self:CompleteCharge()
    end
end
