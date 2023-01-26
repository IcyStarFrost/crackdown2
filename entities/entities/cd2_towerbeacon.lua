AddCSLuaFile()

ENT.Base = "base_anim"

-- The final beacon in the game

local beaconblue = Color( 0, 217, 255 )
local corebeamcolor = Color( 0, 255, 213)
local FreakIcon = Material( "crackdown2/ui/freak.png", "smooth" )
local energy = Material( "crackdown2/effects/energy.png", "smooth" )
if SERVER then util.AddNetworkString( "cd2net_towerbeacon_beginmusic" ) util.AddNetworkString( "cd2net_towerbeacon_ending" ) end

function ENT:Initialize()

    self:SetModel( "models/props_combine/combinethumper001a.mdl" )

    if SERVER then

        self.cd2_freakcount = 0
        self.cd2_delay = 0
        self.cd2_nextspawn = 0
        self.cd2_haswarnedtable = {}

        local function CreateCore( num, pos )
            local core = ents.Create( "base_anim" )
            core:SetModel( "models/props_combine/combine_generator01.mdl" )
            core:SetPos( pos )
            local ang = ( self:GetPos() - pos ):Angle() ang[ 1 ] = 0 ang[ 3 ] = 0
            core:SetOwner( self )
            core:SetAngles( ang + Angle( 0, 90, 0 ) )
            core.cd2_towerbeaconcore = true
            core:Spawn()

            function core:IsCharging()
                return self:GetOwner()[ "GetIsCore" .. num .. "Charging" ]( self:GetOwner() )
            end
    
            local mins = core:OBBMins()
            pos.z = pos.z - mins.z
            core:SetPos( pos )
    
            self:DeleteOnRemove( core )
    
            core:PhysicsInit( SOLID_VPHYSICS )
            core:SetMoveType( MOVETYPE_VPHYSICS )
            core:SetSolid( SOLID_VPHYSICS )
    
            local phys = core:GetPhysicsObject()
            if IsValid( phys ) then 
                phys:EnableMotion( false )
            end
    
            return core
        end

        self:SetCore1( CreateCore( 1, self:GetPos() + self:GetForward() * 100 ) )
        self:SetCore2( CreateCore( 2, ( self:GetPos() - self:GetForward() * 100 ) - self:GetRight() * 100 ) )
        self:SetCore3( CreateCore( 3, ( self:GetPos() - self:GetForward() * 100 ) + self:GetRight() * 100 ) )

        self:SetCurrentCore( 1 )
        self:SetCurrentCoreHealth( 100 )
    end

    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

    local phys = self:GetPhysicsObject()
    if IsValid( phys ) then
        phys:EnableMotion( false )
    end

    if CLIENT then
        self.cd2_corecolor = Color( 0, 110, 255 )
        self.cd2_lasthealth = 100
        self.cd2_nextfloatingenergyparticle = 0

        hook.Add( "HUDPaint", self, function() self:HUDDraw() end )
        hook.Add( "PreDrawEffects", self, function() self:DrawEffects() end )
    end

    if SERVER then
        hook.Add( "EntityTakeDamage", self, function( self, targ, info )
            local attacker = info:GetAttacker()
            if self:GetIsCharging() and IsValid( targ:GetOwner() ) and targ:GetOwner() == self and ( attacker:IsCD2NPC() and attacker:GetCD2Team() == "freak" ) then
                targ:EmitSound( "physics/metal/metal_box_impact_bullet" .. math.random( 1, 3 ) .. ".wav", 80, 100, 1 ) 
                self:SetCurrentCoreHealth( self:GetCurrentCoreHealth() - info:GetDamage() / 20 )
            end
        end )
    end
end


local blackish = Color( 39, 39, 39 )
local linecol = Color( 61, 61, 61, 100 )
local orangeish = Color( 202, 79, 22 )
local chargecol = Color( 0, 110, 255 )
local glow = Material( "crackdown2/ui/sprite2.png" )
local beam = Material( "crackdown2/effects/beam.png", "smooth" )
local coreicons = { Material( "crackdown2/ui/core1.png", "smooth" ), Material( "crackdown2/ui/core2.png", "smooth" ), Material( "crackdown2/ui/core3.png", "smooth" ) }

function ENT:HUDDraw()

    if !self:GetIsCharging() and !self:GetIsDetonated() and LocalPlayer():SqrRangeTo( self ) < ( 300 * 300 ) and self:CanBeActivated() then
        local usebind = input.LookupBinding( "+use" ) or "e"
        local code = input.GetKeyCode( usebind )
        local buttonname = input.GetKeyName( code )
        local screen = ( self:GetPos() + Vector( 0, 0, 100 ) ):ToScreen()
        CD2DrawInputbar( screen.x, screen.y, string.upper( buttonname ), "Start Beacon Charge" )
    end

    if !self:GetIsCharging() or LocalPlayer():SqrRangeTo( self ) > ( 2000 * 2000 ) then return end

    -- Base
    surface.SetDrawColor( blackish )
    draw.NoTexture()
    surface.DrawRect( ScrW() - 350,  40, 300, 64 )
    
    surface.SetDrawColor( linecol )
    surface.DrawOutlinedRect( ScrW() - 350,  40, 300, 64, 1 )
    --

    -- Icon
    surface.SetDrawColor( self.cd2_corecolor )
    surface.SetMaterial( glow )
    surface.DrawTexturedRect( ScrW() - 473,  5, 128, 128 )

    surface.SetDrawColor( color_white )
    surface.SetMaterial( coreicons[ self:GetCurrentCore() ] )
    surface.DrawTexturedRect( ScrW() - 460,  25, 100, 100 )

    self.cd2_corecolor.r = Lerp( 1 * FrameTime(), self.cd2_corecolor.r, 0 )
    self.cd2_corecolor.g = Lerp( 1 * FrameTime(), self.cd2_corecolor.g, 110 )
    self.cd2_corecolor.b = Lerp( 1 * FrameTime(), self.cd2_corecolor.b, 255 )


    --
    
    local progressW = ( ( CurTime() - self:GetChargeStart() ) / self:GetChargeDuration() ) * 280
    
    -- Progress bar
    surface.SetDrawColor( chargecol )
    surface.DrawRect( ScrW() - 340, 55, progressW, 10 )
    
    surface.SetDrawColor( linecol )
    surface.DrawOutlinedRect( ScrW() - 345,  50, 290, 20, 1 )

    local healthW = ( self:GetCurrentCoreHealth() / 100 ) * 280
    
    -- Health Bar
    surface.SetDrawColor( orangeish )
    surface.DrawRect( ScrW() - 340, 80, healthW, 10 )
    
    surface.SetDrawColor( linecol )
    surface.DrawOutlinedRect( ScrW() - 345,  75, 290, 20, 1 )
    
    if self:GetCurrentCoreHealth() != lasthealth then
        self.cd2_corecolor.r = 255 
        self.cd2_corecolor.g = 0
        self.cd2_corecolor.b = 0
    end

    lasthealth = self:GetCurrentCoreHealth()

end

function ENT:DrawEffects()

    if self:GetIsCharging() or self:GetIsDetonated() then
        local core1 = self:GetCore1()
        local core2 = self:GetCore2()
        local core3 = self:GetCore3()

        local nearby = CD2FindInSphere( self:GetPos(), 2000, function( ent ) return ent:IsCD2NPC() and ent:GetCD2Team() == "freak" end )

        for i = 1, #nearby do
            local freak = nearby[ i ]
            if !IsValid( freak ) or !IsValid( freak:GetEnemy() ) then continue end

            if freak:GetEnemy() == self or freak:GetEnemy():GetOwner() == self then
                render.SetMaterial( FreakIcon )
                render.DepthRange( 0, 0 )
                    render.DrawSprite( freak:WorldSpaceCenter() + ( freak:OBBCenter() + Vector( 0, 0, 20 ) ), 30, 30, color_white )
                render.DepthRange( 0, 1 )
            end
        end

        render.SetMaterial( beam )

        if IsValid( core1 ) and ( self:GetIsCore1Charging() or self:GetCore1Charged() ) then
            render.DrawBeam( core1:GetPos() + Vector( 0, 0, 50 ), self:GetPos() + Vector( 0, 0, 700 ), 40, 0, math.random( 0, 400 ), beaconblue )

            local light = DynamicLight( core1:EntIndex() )
            if ( light ) then
                light.pos = core1:GetPos()
                light.r = beaconblue.r
                light.g = beaconblue.g
                light.b = beaconblue.b
                light.brightness = 7
                light.Decay = 1000
                light.style = 1
                light.Size = 600
                light.DieTime = CurTime() + 5
            end

            if !self.cd2_nextfloatingenergyparticle2 or SysTime() > self.cd2_nextfloatingenergyparticle2 then
        
                local particle = ParticleEmitter( core1:WorldSpaceCenter())
                local part = particle:Add( energy, core1:WorldSpaceCenter())
                
                if part then
                    local size = math.random( 4, 20 )
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
                    part:SetVelocity( VectorRand( -200, 200 ) )
                    part:SetAngleVelocity( AngleRand( -1, 1 ) )
                end
        
                particle:Finish()
        
                self.cd2_nextfloatingenergyparticle2 = SysTime() + 0.06
            end
        end

        if IsValid( core2 ) and ( self:GetIsCore2Charging() or self:GetCore2Charged() ) then
            render.DrawBeam( core2:GetPos() + Vector( 0, 0, 50 ), self:GetPos() + Vector( 0, 0, 700 ), 40, 0, math.random( 0, 400 ), beaconblue )

            local light = DynamicLight( core2:EntIndex() )
            if ( light ) then
                light.pos = core2:GetPos()
                light.r = beaconblue.r
                light.g = beaconblue.g
                light.b = beaconblue.b
                light.brightness = 7
                light.Decay = 1000
                light.style = 1
                light.Size = 600
                light.DieTime = CurTime() + 5
            end

            if !self.cd2_nextfloatingenergyparticle3 or SysTime() > self.cd2_nextfloatingenergyparticle3 then
        
                local particle = ParticleEmitter( core2:WorldSpaceCenter())
                local part = particle:Add( energy, core2:WorldSpaceCenter())
                
                if part then
                    local size = math.random( 4, 20 )
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
                    part:SetVelocity( VectorRand( -200, 200 ) )
                    part:SetAngleVelocity( AngleRand( -1, 1 ) )
                end
        
                particle:Finish()
        
                self.cd2_nextfloatingenergyparticle3 = SysTime() + 0.06
            end

        end

        if IsValid( core3 ) and ( self:GetIsCore3Charging() or self:GetCore3Charged() ) then
            render.DrawBeam( core3:GetPos() + Vector( 0, 0, 50 ), self:GetPos() + Vector( 0, 0, 700 ), 40, 0, math.random( 0, 400 ), beaconblue )

            local light = DynamicLight( core3:EntIndex() )
            if ( light ) then
                light.pos = core3:GetPos()
                light.r = beaconblue.r
                light.g = beaconblue.g
                light.b = beaconblue.b
                light.brightness = 7
                light.Decay = 1000
                light.style = 1
                light.Size = 600
                light.DieTime = CurTime() + 5
            end

            if !self.cd2_nextfloatingenergyparticle4 or SysTime() > self.cd2_nextfloatingenergyparticle4 then
        
                local particle = ParticleEmitter( core3:WorldSpaceCenter() )
                local part = particle:Add( energy, core3:WorldSpaceCenter() )
                
                if part then
                    local size = math.random( 4, 20 )
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
                    part:SetVelocity( VectorRand( -200, 200 ) )
                    part:SetAngleVelocity( AngleRand( -1, 1 ) )
                end
        
                particle:Finish()
        
                self.cd2_nextfloatingenergyparticle4 = SysTime() + 0.06
            end
        end

        -- Main Beam --
        
        render.DrawBeam( self:GetPos(), self:GetPos() + Vector( 0, 0, 100000 ), 120, 0, math.random( 0, 400 ), corebeamcolor )

    end

end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "IsCharging" )
    self:NetworkVar( "Bool", 1, "IsDetonated" )

    self:NetworkVar( "Bool", 2, "Core1Charged" )
    self:NetworkVar( "Bool", 3, "Core2Charged" )
    self:NetworkVar( "Bool", 4, "Core3Charged" )

    self:NetworkVar( "Bool", 5, "IsCore1Charging" )
    self:NetworkVar( "Bool", 6, "IsCore2Charging" )
    self:NetworkVar( "Bool", 7, "IsCore3Charging" )
    
    self:NetworkVar( "Float", 0, "ChargeDuration" )
    self:NetworkVar( "Float", 1, "CurrentCoreHealth" )
    self:NetworkVar( "Float", 2, "ChargeStart" )
    self:NetworkVar( "Float", 3, "ChargeCurTime" )

    self:NetworkVar( "Entity", 0, "Core1" )
    self:NetworkVar( "Entity", 1, "Core2" )
    self:NetworkVar( "Entity", 2, "Core3" )

    self:NetworkVar( "Int", 0, "CurrentCore" )
end

function ENT:GetActiveCore()
    return self[ "GetCore" .. self:GetCurrentCore() ]( self )
end

function ENT:OnRemove()
    if CLIENT and IsValid( self.cd2_chargesound ) then self.cd2_chargesound:Stop() end
end

function ENT:Think()

    if CLIENT and self:GetIsCharging() and !IsValid( self.cd2_chargesound )then

        sound.PlayFile( "sound/crackdown2/ambient/beacon/beaconambientcharge.mp3", "3d mono", function( snd, id, name )
            if id then return end
            self.cd2_chargesound = snd
            snd:SetPos( self:GetPos() )
            snd:SetVolume( 2 )
            snd:EnableLooping( true )
            snd:Set3DFadeDistance( 900, 1000000000  )
        end )
    elseif CLIENT and !self:GetIsCharging() and IsValid( self.cd2_chargesound )then
        self.cd2_chargesound:Stop()
    end

    if CLIENT and self:GetIsCharging() and SysTime() > self.cd2_nextfloatingenergyparticle then
        
        local particle = ParticleEmitter( self:GetPos() + VectorRand( -600, 600 ) )
        local part = particle:Add( energy, self:GetPos() + VectorRand( -600, 600 ) )
        
        if part then
            local size = math.random( 20, 50 )
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

        self.cd2_nextfloatingenergyparticle = SysTime() + 2
    end

    if CLIENT then return end

    if !self:GetIsCharging() and !self:GetIsDetonated() and self:CanBeActivated() then
        local near = CD2FindInSphere( self:GetPos() + Vector( 0, 0, 100 ), 300, function( ent ) return ent:IsCD2Agent() end )

        for k, ply in ipairs( near ) do
            if ply:KeyDown( IN_USE ) then
                self:BeginCharge()
            end
        end
    end

    if self:GetIsCharging() and self:GetCurrentCoreHealth() <= 0 then
        net.Start( "cd2net_explosion" )
        net.WriteVector( self:GetPos() )
        net.WriteFloat( 6 )
        net.Broadcast()

        local players = player.GetAll()
        for i = 1, #players do 
            local ply = players[ i ]
            if IsValid( ply ) and ply:SqrRangeTo( self:GetPos() ) < ( 2000 * 2000 ) then CD2SetTypingText( ply, "OBJECTIVE INCOMPLETE", "Beacon Core Destroyed", true ) ply:Kill() end
        end

        self:FlareFreaks()

        self:SetIsCharging( false )
        self:SetIsCore1Charging( false )
        self:SetIsCore2Charging( false )
        self:SetIsCore3Charging( false )

        self:SetCore1Charged( false )
        self:SetCore2Charged( false )
        self:SetCore3Charged( false )
    end

    if self:GetIsCharging() and CurTime() > self.cd2_delay and ( self.cd2_freakcount < 8 ) and CurTime() > self.cd2_nextspawn then
        
        local freakagent = ents.Create( "cd2_freakagent" )
        freakagent:SetPos( CD2GetRandomPos( 800, self:GetPos() ) )
        local ang = ( self:GetPos() - freakagent:GetPos() ):Angle() ang[ 1 ] = 0 ang[ 3 ] = 0
        freakagent:SetAngles( ang )
        freakagent:Spawn()

        freakagent.cd2_IsMelee = tobool( math.random( 0, 1 ) )

        if math.random( 100 ) < 60 then
            freakagent:AttackTarget( self:GetActiveCore() )
        end 

        self:DeleteOnRemove( freakagent )

        freakagent:CallOnRemove( "removeselffromcount", function()
            if IsValid( self ) then self.cd2_freakcount = self.cd2_freakcount - 1 end
        end )

        self.cd2_nextspawn = CurTime() + math.Rand( 0.1, 3.5 )
        self.cd2_freakcount = self.cd2_freakcount + 1
    end

    if self:GetIsCharging() and !self.cd2_haswarnedtable[ self:GetCurrentCore() ] and self:GetCurrentCoreHealth() < 70 then
        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/core" .. self:GetCurrentCore() .. "attacked.mp3" ) 
        self.cd2_haswarnedtable[ self:GetCurrentCore() ] = true
    end

    if self:GetIsCharging() and self:GetCurrentCore() == 3 and ( self:GetChargeCurTime() - CurTime() ) < 7 and !self.cd2_finishstatement then
        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/finalbeaconfinished.mp3" ) 
        self.cd2_finishstatement = true 
        timer.Simple( 10, function() if IsValid( self ) then self.cd2_finishstatement = false end end )
    end

    if self:GetIsCharging() and CurTime() > self:GetChargeCurTime() then
        self:EndCoreCharge( self:GetCurrentCore() )
    end

end

function ENT:CanBeActivated() 
    local beacons = ents.FindByClass( "cd2_beacon" )
    local count = 0 
    for k, v in ipairs( beacons ) do if v:GetIsDetonated() then count = count + 1 end end
    return count == GetGlobal2Int( "cd2_beaconcount", 0 ) 
end

function ENT:EndCoreCharge( num )
    self:FlareFreaks()
    self[ "SetCore" .. num .. "Charged" ]( self, true )
    self[ "SetIsCore" .. num .. "Charging" ]( self, false )
    self:SetCurrentCoreHealth( 100 )
    self:SetChargeDuration( 169 )
    self:SetChargeStart( CurTime() )
    self:SetChargeCurTime( CurTime() + self:GetChargeDuration() )
end

function ENT:FlareFreaks()
    for k, v in ipairs( ents.FindByClass( "cd2_freakagent" ) ) do
        if IsValid( v ) and IsValid( v:GetEnemy() ) and v:GetEnemy().cd2_towerbeaconcore then v:SetEnemy( nil ) end
    end
end

function ENT:BeginCoreCharge( num )
    self:SetIsCharging( true )
    self[ "SetIsCore" .. num .. "Charging" ]( self, true )
    self:SetCurrentCoreHealth( 100 )
    self:SetChargeDuration( 169 )
    self:SetChargeStart( CurTime() )
    self:SetChargeCurTime( CurTime() + self:GetChargeDuration() )
    self:SetCurrentCore( num )
end

function ENT:StartMusic() 
    net.Start( "cd2net_towerbeacon_beginmusic" )
    net.WriteEntity( self )
    net.Broadcast()
end

function ENT:DispatchDirectorLine( path ) 
    if KeysToTheCity() then return end
    for k, ply in ipairs( player.GetAll() ) do
        if ply:SqrRangeTo( self ) < ( 2000 * 2000 ) then
            ply:PlayDirectorVoiceLine( path )
        end
    end
end

function ENT:BeginCharge()

    CD2CreateThread( function() 

        
        self.cd2_delay = CurTime() + 34
        self:BeginCoreCharge( 1 )
        timer.Simple( 0, function() self:StartMusic() end ) 
        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/finalfight1.mp3" ) 

        coroutine.wait( 10 )
        if !IsValid( self ) or !self:GetIsCharging() then return end

        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/finalfight2.mp3" ) 

        coroutine.wait( 9 )
        if !IsValid( self ) or !self:GetIsCharging() then return end

        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/finalfight3.mp3" ) 
        local core = self:GetActiveCore()

        while IsValid( core ) and core:IsCharging() do if !IsValid( self ) then return end coroutine.yield() end
        if !IsValid( self ) or !self:GetIsCharging() then return end
    
        
        self.cd2_delay = CurTime() + 15
        self:BeginCoreCharge( 2 )
        timer.Simple( 0, function() self:StartMusic() end ) 

        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/beaconcore1charged.mp3" ) 

        core = self:GetActiveCore()

        while IsValid( core ) and core:IsCharging() do if !IsValid( self ) then return end coroutine.yield() end
        if !IsValid( self ) or !self:GetIsCharging() then return end

        self.cd2_delay = CurTime() + 15
        self:BeginCoreCharge( 3 )
        timer.Simple( 0, function() self:StartMusic() end ) 
        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/beaconcore2charged.mp3" ) 

        core = self:GetActiveCore()

        while IsValid( core ) and core:IsCharging() do if !IsValid( self ) then return end coroutine.yield() end
        if !IsValid( self ) or !self:GetIsCharging() then return end

        self:SetIsDetonated( true )
        self:SetCore1Charged( true )
        self:SetCore2Charged( true )
        self:SetCore3Charged( true )
        self:SetIsCharging( false )

        timer.Simple( 60, function() if !IsValid( self ) then return end self:SetIsDetonated( false ) end )

        CD2_EmptyStreets = true
        CD2ClearNPCS()
        self:StartEndingCutscene()

    end )

end


function ENT:StartEndingCutscene()

    net.Start( "cd2net_towerbeacon_ending" )
    net.WriteVector( self:GetPos() )
    net.Broadcast()

--[[     for k, ply in ipairs( player.GetAll() ) do
        ply:GodEnable()
        ply:Freeze( true )
        ply:SetNoDraw( true )
    end ]]

    self:SetIsDetonated( true )
    self:SetCore1Charged( true )
    self:SetCore2Charged( true )
    self:SetCore3Charged( true )

    CD2CreateThread( function()
    
        coroutine.wait( 8 )

        local freak = ents.Create( "cd2_freak" )
        freak:SetPos( CD2GetRandomPos( 3000, self:GetPos() ) )
        freak.CanAttack = function( self ) return false end
        local ang = ( self:GetPos() - freak:GetPos() ):Angle() ang[ 1 ] = 0 ang[ 3 ] = 0
        freak:SetAngles( ang )
        freak.cd2_NextPVScheck = math.huge
        self:DeleteOnRemove( freak )
        freak:Spawn()
        SetGlobal2Vector( "cd2_endingcutscenepos1", freak:GetPos() )
        freak.cd2_RunSpeed = 20
        freak.cd2_WalkSpeed = 20

        coroutine.wait( 1.4 )

        freak:LookTo( self:GetPos(), 3 )

        local freakspos = CD2GetRandomPos( 6000, self:GetPos() )
        local freaks = {}
        SetGlobal2Vector( "cd2_endingcutscenepos1", freakspos )

        coroutine.wait( 2 )

        freak:Remove()
        


        for i = 1, 7 do 
            local freak = ents.Create( "cd2_freak" )
            freak:SetPos( CD2GetRandomPos( 1000, freakspos ) )
            freak.CanAttack = function( self ) return false end
            local ang = ( freak:GetPos() - self:GetPos() ):Angle() ang[ 1 ] = 0 ang[ 3 ] = 0
            freak:SetAngles( ang )
            freak.cd2_NextPVScheck = math.huge
            self:DeleteOnRemove( freak )
            freak:Spawn()
            
            freak.cd2_RunSpeed = 200
            freak.cd2_WalkSpeed = 200
            freaks[ #freaks + 1 ] = freak
        end

        coroutine.wait( 2 )

        for k, v in ipairs( freaks ) do v:SetIsDisabled( true ) end

        coroutine.wait( 7.1 )

        for k, v in ipairs( freaks ) do v:TakeDamage( 10000, Entity( 0 ), Entity( 0 ) ) end

        self:SetIsDetonated( false )
        self:SetCore1Charged( false )
        self:SetCore2Charged( false )
        self:SetCore3Charged( false )

        coroutine.wait( 20 )
        CD2_EmptyStreets = false
    end )

end

if CLIENT then

    net.Receive( "cd2net_towerbeacon_ending", function()
        local pos = net.ReadVector()
        
        local viewtbl = {}

        CD2CreateThread( function()
            local endtime = SysTime() + 8

            while true do 
                if SysTime() > endtime then break end

                local particle = ParticleEmitter( pos + Vector( 0, 0, 600 ) )
                local part = particle:Add( energy, pos + Vector( 0, 0, 600 ) )
                
                if part then
                    part:SetStartSize( 50 )
                    part:SetEndSize( 20 ) 
                    part:SetStartAlpha( 255 )
                    part:SetEndAlpha( 0 )
                
                    part:SetColor( 255, 255, 255 )
                    part:SetLighting( false )
                    part:SetCollide( false )
                
                    part:SetDieTime( 3 )
                    part:SetGravity( Vector() )
                    part:SetAirResistance( 100 )
                    part:SetVelocity( VectorRand( -500, 500 ) )
                    part:SetAngleVelocity( AngleRand( -1, 1 ) )
                end
        
                particle:Finish()

                coroutine.wait( 0.01 )
            end

            endtime = SysTime() + 1.4
            while true do 
                if SysTime() > endtime then break end

                local particle = ParticleEmitter( pos + Vector( 0, 0, 600 ) )
                local part = particle:Add( energy, pos + Vector( 0, 0, 600 ) )
                
                if part then
                    part:SetStartSize( 50 )
                    part:SetEndSize( 20 ) 
                    part:SetStartAlpha( 255 )
                    part:SetEndAlpha( 0 )
                
                    part:SetColor( 255, 255, 255 )
                    part:SetLighting( false )
                    part:SetCollide( false )
                
                    part:SetDieTime( 3 )
                    part:SetGravity( Vector() )
                    part:SetAirResistance( 100 )
                    part:SetVelocity( VectorRand( -500, 500 ) )
                    part:SetAngleVelocity( AngleRand( -1, 1 ) )
                end
        
                particle:Finish()

                local particlepos = pos + Vector( 0, 0, 600 ) + VectorRand( -400, 400 )
                local particle = ParticleEmitter( particlepos )
                local part = particle:Add( energy, particlepos )
                
                if part then
                    part:SetStartSize( 30 )
                    part:SetEndSize( 20 ) 
                    part:SetStartAlpha( 255 )
                    part:SetEndAlpha( 0 )
                
                    part:SetColor( 255, 255, 255 )
                    part:SetLighting( false )
                    part:SetCollide( false )
                
                    part:SetDieTime( 3 )
                    part:SetGravity( Vector() )
                    part:SetAirResistance( 200 )
                    part:SetVelocity( ( ( pos + Vector( 0, 0, 600 ) ) - particlepos ):GetNormalized() * 1000 )
                    part:SetAngleVelocity( AngleRand( -1, 1 ) )
                end
        
                particle:Finish()

                coroutine.wait( 0.01 )
            end

            for i = 1, 200 do
                local particle = ParticleEmitter( pos + Vector( 0, 0, 600 ) )
                local part = particle:Add( energy, pos + Vector( 0, 0, 600 ) )
                
                if part then
                    part:SetStartSize( 300 )
                    part:SetEndSize( 300 ) 
                    part:SetStartAlpha( 255 )
                    part:SetEndAlpha( 0 )
                
                    part:SetColor( 255, 255, 255 )
                    part:SetLighting( false )
                    part:SetCollide( false )
                
                    part:SetDieTime( 10 )
                    part:SetGravity( Vector() )
                    part:SetAirResistance( 0 )
                    part:SetVelocity( Vector( math.sin( i ) * 2000, math.cos( i ) * 2000, 0 ) )
                    part:SetAngleVelocity( AngleRand( -1, 1 ) )
                end
        
                particle:Finish()
            end

            coroutine.wait( 4 )

            for i = 1, 200 do
                local particle = ParticleEmitter( pos + Vector( 0, 0, 600 ) )
                local part = particle:Add( energy, pos + Vector( 0, 0, 600 ) )
                
                if part then
                    part:SetStartSize( 1000 )
                    part:SetEndSize( 1000 ) 
                    part:SetStartAlpha( 255 )
                    part:SetEndAlpha( 0 )
                
                    part:SetColor( 255, 255, 255 )
                    part:SetLighting( false )
                    part:SetCollide( false )
                
                    part:SetDieTime( 10 )
                    part:SetGravity( Vector() )
                    part:SetAirResistance( 0 )
                    part:SetVelocity( Vector( math.sin( i ) * 2000, math.cos( i ) * 2000, 0 ) )
                    part:SetAngleVelocity( AngleRand( -1, 1 ) )
                end
        
                particle:Finish()
            end

            coroutine.wait( 6 )

            for i = 1, 200 do
                local particle = ParticleEmitter( pos + Vector( 0, 0, 600 ) )
                local part = particle:Add( energy, pos + Vector( 0, 0, 600 ) )
                
                if part then
                    part:SetStartSize( 1000 )
                    part:SetEndSize( 1000 ) 
                    part:SetStartAlpha( 255 )
                    part:SetEndAlpha( 0 )
                
                    part:SetColor( 255, 255, 255 )
                    part:SetLighting( false )
                    part:SetCollide( false )
                
                    part:SetDieTime( 10 )
                    part:SetGravity( Vector() )
                    part:SetAirResistance( 0 )
                    part:SetVelocity( Vector( math.sin( i ) * 2000, math.cos( i ) * 2000, 0 ) )
                    part:SetAngleVelocity( AngleRand( -1, 1 ) )
                end
        
                particle:Finish()
            end
        
        end )

        CD2CreateThread( function() 
            sound.PlayFile( "sound/crackdown2/ending/finalsequence.mp3", "noplay", function( snd, id, name ) snd:SetVolume( 10 ) snd:Play() end )

            CD2_InCutscene = true
            CD2_DrawAgilitySkill = false
            CD2_DrawFirearmSkill = false
            CD2_DrawStrengthSkill = false
            CD2_DrawExplosiveSkill = false

            CD2_DrawTargetting = false
            CD2_DrawHealthandShields = false
            CD2_DrawWeaponInfo = false
            CD2_DrawMinimap = false
            CD2_DrawBlackbars = true

            CD2_PreventMovement = true

            local newpos = pos + Vector( 500, 500, 50 )
            local fov2 = 80

            CD2_ViewOverride = function( ply, origin, angles, fov, znear, zfar )

                
                viewtbl.origin = newpos
                viewtbl.angles = ( ( pos + Vector( 0, 0, 500 ) ) - newpos ):Angle()
                viewtbl.fov = fov2
                viewtbl.znear = znear
                viewtbl.zfar = zfar
                viewtbl.drawviewer = true

                fov2 = Lerp( 0.1 * FrameTime(), fov2, 45 )
                newpos = LerpVector( 0.05 * FrameTime(), newpos, pos + Vector( 500, -500, 50 ) )

                return viewtbl
            end

            coroutine.wait( 8 )

            newpos = pos + Vector( 500, 500, 800 )
            fov2 = 50

            CD2_ViewOverride = function( ply, origin, angles, fov, znear, zfar )

                
                viewtbl.origin = newpos
                viewtbl.angles = ( ( pos + Vector( 0, 0, 600 ) ) - newpos ):Angle()
                viewtbl.fov = fov2
                viewtbl.znear = znear
                viewtbl.zfar = zfar
                viewtbl.drawviewer = true

                fov2 = Lerp( 0.5 * FrameTime(), fov2, 80 )

                return viewtbl
            end

            coroutine.wait( 1.4 )

            local angle = ( pos - ( GetGlobal2Vector( "cd2_endingcutscenepos1", Vector() ) + Vector( 0, 0, 55 ) ) ):Angle()
            newpos = GetGlobal2Vector( "cd2_endingcutscenepos1", Vector() ) + Vector( 0, 0, 55 ) - angle:Forward() * 200 + angle:Right() * 50
            fov2 = 50

            local lerpangle = ( ( GetGlobal2Vector( "cd2_endingcutscenepos1", Vector() ) + Vector( 0, 0, 55 ) ) - newpos ):Angle()

            CD2_ViewOverride = function( ply, origin, angles, fov, znear, zfar )

                
                viewtbl.origin = newpos
                viewtbl.angles = lerpangle
                viewtbl.fov = fov2
                viewtbl.znear = znear
                viewtbl.zfar = zfar
                viewtbl.drawviewer = true

                lerpangle = LerpAngle( 0.5 * FrameTime(), lerpangle, ( pos - newpos ):Angle() )
                fov2 = Lerp( 0.5 * FrameTime(), fov2, 30 )

                return viewtbl
            end

            coroutine.wait( 2 )

            newpos = GetGlobal2Vector( "cd2_endingcutscenepos1", Vector() ) + Vector( -5000, 0, 9000 ) 
            local nextpos = ( newpos * 1 ) + Vector( 0, 7000, 0 )
            local ang = ( pos - newpos ):Angle()
            ang:Normalize()
            fov2 = 50

            CD2_ViewOverride = function( ply, origin, angles, fov, znear, zfar )

                
                viewtbl.origin = newpos
                viewtbl.angles = ang
                viewtbl.fov = fov2
                viewtbl.znear = znear
                viewtbl.zfar = zfar
                viewtbl.drawviewer = true

                newpos = LerpVector( 0.1 * FrameTime(), newpos, nextpos )

                return viewtbl
            end

            coroutine.wait( 2 )

            local fogend = 4000
            hook.Add( "SetupWorldFog", "crackdown2_endingfog", function()
                render.FogStart( 100 )
                render.FogEnd( fogend )
                render.FogMaxDensity( 1 )
                render.FogMode( MATERIAL_FOG_LINEAR )
                render.FogColor( 0, 217, 255 )
                return true
            end )

            local freakpos = GetGlobal2Vector( "cd2_endingcutscenepos1", Vector() ) + Vector( 0, 0, 30)
            local lerppos = ( freakpos * 1 ) + ( freakpos - pos ):GetNormalized() * 500
            fov2 = 50

            CD2_ViewOverride = function( ply, origin, angles, fov, znear, zfar )

                
                viewtbl.origin = freakpos
                viewtbl.angles = ( pos - freakpos ):Angle()
                viewtbl.fov = fov2
                viewtbl.znear = znear
                viewtbl.zfar = zfar
                viewtbl.drawviewer = true

                fogend = Lerp( 0.4 * FrameTime(), fogend, 110 )
                freakpos = LerpVector( 0.1 * FrameTime(), freakpos, lerppos )

                return viewtbl
            end

            coroutine.wait( 7.1 )

            hook.Remove( "SetupWorldFog", "crackdown2_endingfog" )
            LocalPlayer():ScreenFade( SCREENFADE.IN, color_white, 1, 1.7 )

            newpos = ( pos * 1 ) + Vector( math.random( -2000, 2000 ), math.random( -2000, 2000 ), 0)
            ang = ( pos - newpos ):Angle()

            CD2_ViewOverride = function( ply, origin, angles, fov, znrea, zfar )

                
                viewtbl.origin = newpos
                viewtbl.angles = ang
                viewtbl.fov = fov2
                viewtbl.znear = znear
                viewtbl.zfar = zfar
                viewtbl.drawviewer = true

                newpos = LerpVector( 0.005 * FrameTime(), newpos, pos + Vector( 0, 0, 600 ) )

                return viewtbl
            end

            coroutine.wait( 14 )

            LocalPlayer():ScreenFade( SCREENFADE.OUT, Color( 0, 0, 0 ), 4, 4 )

            coroutine.wait( 8 )

            CD2_InCutscene = false

            CD2PlayCredits()


        end )
    end )

    net.Receive( "cd2net_towerbeacon_beginmusic", function() 
        local tower = net.ReadEntity()
        if !IsValid( tower ) then return end 

        CD2StartMusic( "sound/crackdown2/music/towerbeacon.mp3", 700, nil, nil, nil, nil, nil, nil, nil, function( CD2Musicchannel )
            if !IsValid( tower ) or !tower:GetIsCharging() then CD2Musicchannel:FadeOut() return end

            if LocalPlayer():SqrRangeTo( tower:GetPos() ) > ( 2000 * 2000 ) then
                CD2Musicchannel:GetChannel():SetVolume( 0 )
            else 
                CD2Musicchannel:GetChannel():SetVolume( 1 )
            end
        end )

    end )
end