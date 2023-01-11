AddCSLuaFile()

ENT.Base = "base_anim"

local random = math.random
local Angle = Angle
local clamp = math.Clamp
local LerpVector = LerpVector
local FrameTime = FrameTime
local Vector = Vector
local Trace = util.TraceLine
local beacontrace = {}

function ENT:Initialize()
    self:SetNoDraw( true )
    self:DrawShadow( false )
    self:SetAngles( Angle( 0, random( -180, 180 ), 0 ) )

    -- Look I can't model so I'm using one my starfall scripts as reference to recreate beacons
    if SERVER then
        self.BeaconBase = self:CreatePart( self:GetPos() + Vector( 0, 0, 70), Angle( 180, 0, 0 ), "models/hunter/misc/shell2x2a.mdl", "models/dav0r/hoverball", 1 )
        self.Leg1 = self:CreatePart( self:GetPos() + Vector( 0, -30, 23 ), Angle( 45, 90, -90 ), "models/hunter/triangles/075x075.mdl", "models/dav0r/hoverball", 1 )
        self.Leg2 = self:CreatePart( self:GetPos() + Vector( 0, 30, 23 ), Angle( 45, -90, -90 ), "models/hunter/triangles/075x075.mdl", "models/dav0r/hoverball", 1 )
        self.Leg3 = self:CreatePart( self:GetPos() + Vector( 30, 0, 23 ), Angle( 45, 180, -90 ), "models/hunter/triangles/075x075.mdl", "models/dav0r/hoverball", 1 )
        self.Leg4 = self:CreatePart( self:GetPos() + Vector( -30, 0, 23 ), Angle( 45, 0, -90 ), "models/hunter/triangles/075x075.mdl", "models/dav0r/hoverball", 1 )
        self.Core = self:CreatePart( self:GetPos() + Vector( 0, 0, 70 ), Angle( 0, 0, 180 ), "models/maxofs2d/hover_rings.mdl", nil, 4.8 )
        self.Core:SetMoveType( MOVETYPE_NONE )

        self.Ring = self:CreatePart( self:GetPos() + Vector( 0, 0, 120 ), Angle( 0, 0, 180 ), "models/hunter/tubes/tube2x2x1.mdl", "models/props_combine/metal_combinebridge001" , 1 )
        self.RingMid = self:CreatePart( self.Ring:GetPos(), Angle( 0, 0, 180 ), "models/hunter/tubes/tube2x2x05.mdl", "models/dav0r/hoverball" , 0.2 )
        self.RingMid:SetParent( self.Ring )

        self:SetEmitter( self.RingMid )
        self:SetCore( self.Core )

        self.cd2_currentlerp = 0

        for i = 1, 4 do
            self[ "Shell" .. i ] = self:CreatePart( self:GetPos() + Vector( 0, 0, 70 ), Angle( 0, 0 + ( 90 * i ), 0 ), "models/hunter/misc/shell2x2d.mdl", "models/dav0r/hoverball", 1 )
            self[ "Shell" .. i ]:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
            
            local phys = self[ "Shell" .. i ]:GetPhysicsObject()
            if IsValid( phys ) then phys:SetMass( 700 ) end
        end

        timer.Simple( 0.01, function()
            net.Start( "cd2net_beaconscale" )
            net.WriteEntity( self.Ring ) 
            net.WriteVector( Vector( 0.7, 0.7, 0.3 ) )
            net.Broadcast()
        end )
        
    end
end

function ENT:SetupDataTables()
    self:NetworkVar( "String", 0, "SoundTrack" )

    self:NetworkVar( "Bool", 0, "IsCharging" )
    self:NetworkVar( "Bool", 1, "IsDetonated" )
    self:NetworkVar( "Bool", 2, "IsDropping" )
    self:NetworkVar( "Bool", 3, "Active" )
    self:NetworkVar( "Bool", 4, "RingReturning" )
    self:NetworkVar( "Bool", 5, "BeamActive" )

    self:NetworkVar( "Float", 0, "ChargeDuration" )

    self:NetworkVar( "Vector", 0, "RingPos" )
    self:NetworkVar( "Vector", 1, "BeaconPos" )

    self:NetworkVar( "Entity", 0, "Emitter" )
    self:NetworkVar( "Entity", 1, "Core" )
end


function ENT:OnLand()
    if SERVER then
        net.Start( "cd2net_playerlandingdecal" )
        net.WriteVector( self.Core:GetPos() )
        net.WriteBool( true )
        net.Broadcast()
    elseif CLIENT then
        sound.PlayFile( "sound/crackdown2/ambient/beacon/beaconambient.mp3", "3d mono", function( snd, id, name )
            if id then return end
            self.cd2_beaconambient = snd
            snd:SetPos( self:GetPos() )
            snd:EnableLooping( true )
            snd:Set3DFadeDistance( 700, 1000000000  )
        end )

        local emitter = self:GetEmitter()

        if IsValid( emitter ) then
            sound.PlayFile( "sound/crackdown2/ambient/au/au_ring.mp3", "3d mono", function( snd, id, name )
                if id then return end
                self.cd2_ringambient = snd
                snd:SetPos( self:GetPos() )
                snd:EnableLooping( true )
                snd:Set3DFadeDistance( 700, 1000000000  )
            end )
        end
    end
end

local beaconblue = Color( 0, 217, 255 )
local beam = Material( "crackdown2/effects/beam.png", "smooth" )

ENT.SunBeamMult = 0.20
ENT.SunBeamDark = 0
ENT.SunSize = 0.05
ENT.SunDistance = 500
function ENT:OnBeamStart()
    if SERVER then
        self:SetBeamActive( true )
        self:SetChargeDuration( 200 )
        self.cd2_curtimeduration = CurTime() + 200
        self.cd2_BeaconChargeStart = CurTime() + 10
    elseif CLIENT then
        local beamlerp
        local starttime = SysTime()
        local endtime = SysTime() + 10
        
        hook.Add( "PreDrawEffects", self, function()
            local emitter = self:GetEmitter()
            local core = self:GetCore()
            if !IsValid( emitter ) or !IsValid( core ) then return end
            beamlerp = beamlerp or emitter:GetPos()

            render.SetMaterial( beam )
            render.DrawBeam( emitter:GetPos(), beamlerp, 50, 1, random( 1, 1000000 ), beaconblue )

            beamlerp = LerpVector( clamp( ( SysTime() - starttime ) / ( endtime - starttime ), 0, 1 ), beamlerp, core:GetPos() )

            cam.Start2D()
                local pos = core:GetPos()
                local screen = pos:ToScreen()

                if self:GetIsCharging() then
                    local time = self:GetChargeDuration()
                    self.cd2_currentbeamlerp = 0
                    self.cd2_currentbeamlerp = self.cd2_currentlerp + FrameTime()
                    
                    self.SunDistance = Lerp( self.cd2_currentbeamlerp / time, self.SunDistance, 1500 )
                end

                local dist_mult = -clamp( CD2_vieworigin:Distance( pos ) / self.SunDistance, 0, 1 ) + 1
            
                DrawSunbeams( self.SunBeamDark, dist_mult * self.SunBeamMult * ( math.Clamp( CD2_viewangles:Forward():Dot( ( pos - CD2_vieworigin ):GetNormalized() ) - 0.5, 0, 1 ) * 2 ) ^ 5, self.SunSize, screen.x / ScrW(), screen.y / ScrH() )
            cam.End2D()
        end )

        CD2CreateThread( function() 

            coroutine.wait( 0.5 )
            if !IsValid( self ) then return end

            if IsValid( self.cd2_intromusic ) then self.cd2_intromusic:Kill() end
            local first = true
            CD2StartMusic( self:GetSoundTrack(), 600, false, false, nil, nil, nil, nil, nil, function( chan )
                if !IsValid( self ) then chan:FadeOut() end

                if first then
                    net.Start( "cd2net_beaconduration" )
                    net.WriteEntity( self )
                    net.WriteFloat( chan:GetChannel():GetLength() )
                    net.SendToServer()
                    first = false
                end
            end )

        end )
    end
end

function ENT:DropBeacon()
    beacontrace.start = self:GetPos()
    beacontrace.endpos = self:GetPos() - Vector( 0, 0, 1000000 )
    beacontrace.collisiongroup = COLLISION_GROUP_WORLD
    beacontrace.mask = MASK_SOLID_BRUSHONLY
    local result = Trace( beacontrace )

    BroadcastLua( "Entity(" .. self:EntIndex() .. "):StartIntroMusic()" )

    self:SetIsDropping( true )
    self:SetRingPos( self.Ring:GetPos() )
    self:SetBeaconPos( result.HitPos )
    self:SetActive( true )
end

function ENT:PlayClientSound( path, pos, volume )
    net.Start( "cd2net_beaconplaysound" ) 
    net.WriteString( path ) 
    net.WriteFloat( volume )
    net.WriteVector( pos )
    net.Broadcast()
end

function ENT:StartIntroMusic()
    self.cd2_intromusic = CD2StartMusic( string.StripExtension( self:GetSoundTrack() ) .. "_intro.mp3", 590, true, false, nil, nil, nil, nil, nil, function( chan )
        if !IsValid( self ) then chan:FadeOut() end
    end )
end

local viewtbl = {}
function ENT:BeaconDetonate()
    if SERVER then
        self:SetIsDetonated( true )
        self:SetIsCharging( false )
        self:PlayClientSound( "crackdown2/ambient/beacon/beacondetonate.mp3", self:GetPos(), 5 )

        CD2CreateThread( function()

            coroutine.wait( 2 )

            local near = CD2FindInSphere( self:GetPos(), 2000, function( ent ) return !ent:IsPlayer() end )

            for i = 1, #near do
                local ent = near[ i ]
                if !IsValid( ent ) then continue end
                ent:TakeDamage( ent:GetMaxHealth(), Entity( 0 ) )
            end
        
            coroutine.wait( 4 )

            self:PlayClientSound( "crackdown2/ambient/beacon/beaconfinish.mp3", self:GetPos(), 5 )

            coroutine.wait( 20 )

            self:Remove()
        
        end )
    elseif CLIENT then

        if IsValid( self.cd2_beaconambient ) then self.cd2_beaconambient:Stop() end

        sound.PlayFile( "sound/crackdown2/ambient/beacon/beaconambient.mp3", "3d mono", function( snd, id, name )
            if id then return end
            self.cd2_beaconambient = snd
            snd:SetPos( self:GetPos() )
            snd:EnableLooping( true )
            snd:Set3DFadeDistance( 700, 1000000000  )
        end )

        if LocalPlayer():GetPos():DistToSqr( self:GetPos() ) > ( 2500 * 2500 ) then return end

        CD2CreateThread( function()
            coroutine.wait( 2 ) 
            LocalPlayer():ScreenFade( SCREENFADE.IN, color_white, 2, 1 )
        end )
        CD2CreateThread( function()

            CD2StartMusic( "sound/crackdown2/music/beacon_victory.mp3", 600 )

            CD2_PreventMovement = true
            CD2_DrawAgilitySkill = false
            CD2_DrawFirearmSkill = false
            CD2_DrawStrengthSkill = false
            CD2_DrawExplosiveSkill = false

            CD2_DrawTargetting = false
            CD2_DrawHealthandShields = false
            CD2_DrawWeaponInfo = false
            CD2_DrawMinimap = false
            CD2_DrawBlackbars = true

            
            local lerpup = true
            local pos = self:GetPos() + Vector( math.sin( SysTime() ) * 2000, math.cos( SysTime() ) * 2000, 1000 )
            CD2_ViewOverride = function( ply, origin, angles, fov, znear, zfar )

                if lerpup then
                    self.SunBeamMult = Lerp( 1 * FrameTime(), self.SunBeamMult, 3 )
                end

                viewtbl.origin = pos
                viewtbl.angles = ( self:GetPos() - pos ):Angle()
                viewtbl.fov = 60
                viewtbl.znear = znear
                viewtbl.zfar = zfar
                viewtbl.drawviewer = true

                return viewtbl
            end

            coroutine.wait( 3 )
            local time = SysTime() + 3
            lerpup = false
            
            while true do
                if SysTime() > time then break end
                self.SunBeamMult = Lerp( 1 * FrameTime(), self.SunBeamMult, 0.20 )
                coroutine.yield()
            end

            coroutine.wait( 3 )
            
            CD2_PreventMovement = nil
            CD2_ViewOverride = nil

            CD2_DrawAgilitySkill = true
            CD2_DrawFirearmSkill = true
            CD2_DrawStrengthSkill = true
            CD2_DrawExplosiveSkill = true

            CD2_DrawTargetting = true
            CD2_DrawHealthandShields = true
            CD2_DrawWeaponInfo = true
            CD2_DrawMinimap = true
            CD2_DrawBlackbars = false


        end )
        
    end
end

local energy = Material( "crackdown2/effects/energy.png" )
function ENT:BeginBeaconCharge()
    if SERVER then
        for i = 1, 4 do
            local shell = self[ "Shell" .. i ]
            shell:SetParent()
            shell:PhysWake()
            shell:SetPos( self:GetPos() + Vector( 0, 0, 70 ) )
            shell:SetAngles( Angle( 0, 0 + ( 90 * i ) ) )  
            timer.Simple( 0.01, function()
                local phys = shell:GetPhysicsObject()
                if IsValid( phys ) then
                    phys:ApplyForceCenter( ( shell:WorldSpaceCenter() - self.Core:GetPos() ):GetNormalized() * 302500 )
                end
            end )
        end

        self.Core:SetParent()
        self.Core:SetPos( self:GetPos() + Vector( 0, 0, 70 ) )
        self.cd2_chargestart = CurTime()
        self:SetIsCharging( true )
        self:PlayClientSound( "crackdown2/ambient/beacon/beaconshellbreak.mp3", self.Core:GetPos(), 5 )
    elseif CLIENT then
        if IsValid( self.cd2_beaconambient ) then self.cd2_beaconambient:Stop() end
        sound.PlayFile( "sound/crackdown2/ambient/beacon/beaconambientcharge.mp3", "3d mono", function( snd, id, name )
            if id then return end
            self.cd2_beaconambient = snd
            snd:SetPos( self:GetCore():GetPos() )
            snd:EnableLooping( true )
            snd:Set3DFadeDistance( 900, 1000000000  )
        end )


        local particle = ParticleEmitter( self:GetCore():GetPos() )
        for i = 1, 150 do
            
            local part = particle:Add( energy, self:GetCore():GetPos() )
    
            if part then
                part:SetStartSize( 50 )
                part:SetEndSize( 50 ) 
                part:SetStartAlpha( 255 )
                part:SetEndAlpha( 0 )
    
                part:SetColor( 255, 255, 255 )
                part:SetLighting( false )
                part:SetCollide( false )
    
                part:SetDieTime( 3 )
                part:SetGravity( Vector() )
                part:SetAirResistance( 100 )
                part:SetVelocity( VectorRand( -1000, 1000 ) )
                part:SetAngleVelocity( AngleRand( -1, 1 ) )
            end
    
        end

        particle:Finish()

    end
end

function ENT:ReturnRing()
    self.Ring:SetParent()
    self:SetRingReturning( true )
end

function ENT:Think()
    if !self:GetActive() then return end

    if SERVER then

        if self:GetBeamActive() then
            self.Ring:SetAngles( Angle( 0, CurTime() * 800, 0 ) )
        end

        if self.cd2_BeaconChargeStart and CurTime() > self.cd2_BeaconChargeStart then
            self:BeginBeaconCharge()
            BroadcastLua( "Entity(" .. self:EntIndex() .. "):BeginBeaconCharge()" )
            self.cd2_BeaconChargeStart = nil
        end

        if self:GetIsCharging() then
            local time = self:GetChargeDuration()
            self.cd2_currentlerp = 0
            self.cd2_currentlerp = self.cd2_currentlerp + FrameTime()
            self.Core:SetPos( LerpVector( self.cd2_currentlerp / time, self.Core:GetPos(), ( self:GetPos() + Vector( 0, 0, 70 ) ) + Vector( 0, 0, 90 ) ) )

            self.Core:SetAngles( Angle( CurTime() * 200, CurTime() * 200, CurTime() * 200 ) / ( self.cd2_curtimeduration - CurTime() )  )
        end

        if self:GetIsCharging() and CurTime() > self.cd2_curtimeduration then
            self:BeaconDetonate()
            BroadcastLua( "Entity(" .. self:EntIndex() .. "):BeaconDetonate()" )
        end

        if self:GetIsDropping() and self:GetPos():DistToSqr( self:GetBeaconPos() ) > ( 20 * 20 ) then

            self:SetPos( self:GetPos() + ( self:GetBeaconPos() - self:GetPos() ):GetNormalized() * 10 )

        elseif self:GetIsDropping() and self:GetPos():DistToSqr( self:GetBeaconPos() ) <= ( 20 * 20 ) then

            self:SetIsDropping( false )
            self:ReturnRing()
            self:SetPos( self:GetBeaconPos() )
            self:PlayClientSound( "crackdown2/ambient/beacon/beaconland.mp3", self:GetPos(), 5 )
            BroadcastLua( "Entity(" .. self:EntIndex() .. "):OnLand()" )
            self:OnLand()

        elseif self:GetRingReturning() and self.Ring:GetPos():DistToSqr( self:GetRingPos() ) > ( 20 * 20 ) then

            self.Ring:SetPos( self.Ring:GetPos() + ( self:GetRingPos() - self.Ring:GetPos() ):GetNormalized() * 4 )

        elseif self:GetRingReturning() and self.Ring:GetPos():DistToSqr( self:GetRingPos() ) <= ( 20 * 20 ) then
            BroadcastLua( "Entity(" .. self:EntIndex() .. "):OnBeamStart()" )
            self:OnBeamStart()
            self:SetRingReturning( false )
            self:PlayClientSound( "crackdown2/ambient/beacon/beaconcharge.mp3", self.Core:GetPos(), 5 )
        end

    elseif CLIENT then

        if IsValid( self.cd2_ringambient ) and IsValid( self:GetEmitter() ) then
            self.cd2_ringambient:SetPos( self:GetEmitter():GetPos() )
        end

        if self:GetIsCharging() then
            local light = DynamicLight( self:EntIndex() )
            if ( light ) then
                light.pos = self:GetPos()
                light.r = beaconblue.r
                light.g = beaconblue.g
                light.b = beaconblue.b
                light.brightness = 2
                light.Decay = 1000
                light.style = 1
                light.Size = 2000
                light.DieTime = CurTime() + 5
            end

            if !self.cd2_nextenergycoreparticle or SysTime() > self.cd2_nextenergycoreparticle then
                local particle = ParticleEmitter( self:GetCore():GetPos() )
                local part = particle:Add( energy, self:GetCore():GetPos() )

                self.cd2_coreparticlesize = self.cd2_coreparticlesize or 4
                self.cd2_coreparticlevelocity = self.cd2_coreparticlevelocity or 0

                local time = self:GetChargeDuration() / 2
                self.cd2_currentlerp = 0
                self.cd2_currentlerp = self.cd2_currentlerp + FrameTime()
                
                self.cd2_coreparticlevelocity = Lerp( self.cd2_currentlerp / time, self.cd2_coreparticlevelocity, 500 )
                self.cd2_coreparticlesize = Lerp( self.cd2_currentlerp / time, self.cd2_coreparticlesize, 80 )
    
                if part then
                    part:SetStartSize( self.cd2_coreparticlesize )
                    part:SetEndSize( self.cd2_coreparticlesize ) 
                    part:SetStartAlpha( 255 )
                    part:SetEndAlpha( 0 )
        
                    part:SetColor( 255, 255, 255 )
                    part:SetLighting( false )
                    part:SetCollide( false )
        
                    part:SetDieTime( 3 )
                    part:SetGravity( Vector() )
                    part:SetAirResistance( 100 )
                    part:SetVelocity( VectorRand( -50 - self.cd2_coreparticlevelocity, 50 + self.cd2_coreparticlevelocity ) )
                    part:SetAngleVelocity( AngleRand( -1, 1 ) )
                end

                particle:Finish()
                self.cd2_nextenergycoreparticle = SysTime() + 0.08
            end

            if !self.cd2_nextenergyparticle or SysTime() > self.cd2_nextenergyparticle then

                local particle = ParticleEmitter( self:GetCore():GetPos() + VectorRand( -600, 600 ) )
                    local part = particle:Add( energy, self:GetCore():GetPos() + VectorRand( -600, 600 ) )
                    
                    if part then
                        local size = random( 20, 50 )
                        part:SetStartSize( size )
                        part:SetEndSize( size ) 
                        part:SetStartAlpha( 255 )
                        part:SetEndAlpha( 0 )
            
                        part:SetColor( 255, 255, 255 )
                        part:SetLighting( false )
                        part:SetCollide( false )
            
                        part:SetDieTime( 3 )
                        part:SetGravity( Vector() )
                        part:SetAirResistance( 100 )
                        part:SetVelocity( Vector() )
                        part:SetAngleVelocity( AngleRand( -1, 1 ) )
                    end

                particle:Finish()

                local time = self:GetChargeDuration() - 10
                self.cd2_systimedparticledur = self.cd2_systimedparticledur or SysTime() + time
                self.cd2_nextenergyparticle = SysTime() + ( ( self.cd2_systimedparticledur - SysTime() ) / 30 )
            end
        end

    end

    self:NextThink( CurTime() + 0.01 )
    return true
end

function ENT:OnRemove()
    if SERVER then
        
    elseif CLIENT then
        if IsValid( self.cd2_beaconambient ) then self.cd2_beaconambient:Stop() end
        if IsValid( self.cd2_ringambient ) then self.cd2_ringambient:Stop() end
    end
end

function ENT:CreatePart( pos, ang, mdl, mat, scale )
    local part = ents.Create( "base_anim" )
    part:SetPos( pos )
    part:SetAngles( ang )
    part:SetModel( mdl )
    part:SetModelScale( scale or 1, 0 )
    part:SetParent( self )
    part:SetOwner( self )
    part:SetMaterial( mat or "" )
    part:Spawn()

    self:DeleteOnRemove( part )

    part:PhysicsInit( SOLID_VPHYSICS )
    part:SetMoveType( MOVETYPE_VPHYSICS )
    part:SetSolid( SOLID_VPHYSICS )

    return part
end


if SERVER then
    util.AddNetworkString( "cd2net_beaconscale" )
    util.AddNetworkString( "cd2net_beaconduration" )
    util.AddNetworkString( "cd2net_beaconplaysound" )

    net.Receive( "cd2net_beaconduration", function( len, ply )
        local beacon = net.ReadEntity()
        local duration = net.ReadFloat()
        if !IsValid( beacon ) then return end
        beacon.cd2_curtimeduration = CurTime() + duration
        beacon:SetChargeDuration( duration )
    end )
    
elseif CLIENT then
    net.Receive( "cd2net_beaconscale", function()
        local ent = net.ReadEntity()
        local scale = net.ReadVector()
        if !IsValid( ent ) then return end
        local mat = Matrix()
        mat:Scale( scale )
        ent:EnableMatrix( "RenderMultiply", mat )
    end )

    net.Receive( "cd2net_beaconplaysound", function()
        local path = net.ReadString()
        local volume = net.ReadFloat()
        local pos = net.ReadVector()

        sound.PlayFile( "sound/" .. path, "3d mono noplay", function( snd, id, name )
            if id then return end
            snd:SetVolume( volume )
            snd:SetPos( pos )
            snd:Set3DFadeDistance( 700, 1000000000 )
            snd:Play()
        end )
    end )

end