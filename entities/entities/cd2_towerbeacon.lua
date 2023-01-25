AddCSLuaFile()

ENT.Base = "base_anim"

-- The final beacon in the game

local beaconblue = Color( 0, 217, 255 )
local corebeamcolor = Color( 0, 255, 213)
local FreakIcon = Material( "crackdown2/ui/freak.png", "smooth" )
if SERVER then util.AddNetworkString( "cd2net_towerbeacon_beginmusic" ) end

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

        timer.Simple( 1, function() 
            self:BeginCharge()
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

    if self:GetIsCharging() then
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
        end

        if IsValid( core2 ) and ( self:GetIsCore2Charging() or self:GetCore2Charged() ) then
            render.DrawBeam( core2:GetPos() + Vector( 0, 0, 50 ), self:GetPos() + Vector( 0, 0, 700 ), 40, 0, math.random( 0, 400 ), beaconblue )
        end

        if IsValid( core3 ) and ( self:GetIsCore3Charging() or self:GetCore3Charged() ) then
            render.DrawBeam( core3:GetPos() + Vector( 0, 0, 50 ), self:GetPos() + Vector( 0, 0, 700 ), 40, 0, math.random( 0, 400 ), beaconblue )
        end

        -- Main Beam --
        
        render.DrawBeam( self:GetPos(), self:GetPos() + Vector( 0, 0, 100000 ), 120, 0, math.random( 0, 400 ), corebeamcolor )


        local light = DynamicLight( self:EntIndex() )
        if ( light ) then
            light.pos = self:GetPos()
            light.r = beaconblue.r
            light.g = beaconblue.g
            light.b = beaconblue.b
            light.brightness = 6
            light.Decay = 1000
            light.style = 1
            light.Size = 4000
            light.DieTime = CurTime() + 5
        end
    end

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

function ENT:Think()
    if CLIENT then return end

    if self:GetIsCharging() and self:GetCurrentCoreHealth() <= 0 then
        self:Remove()
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

        self.cd2_nextspawn = CurTime() + math.Rand( 0.1, 2 )
        self.cd2_freakcount = self.cd2_freakcount + 1
    end

    if self:GetIsCharging() and !self.cd2_haswarnedtable[ self:GetCurrentCore() ] and self:GetCurrentCoreHealth() < 70 then
        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/core" .. self:GetCurrentCore() .. "attacked.mp3" ) 
        self.cd2_haswarnedtable[ self:GetCurrentCore() ] = true
    end

    if self:GetIsCharging() and CurTime() > self:GetChargeCurTime() then
        self:EndCoreCharge( self:GetCurrentCore() )
    end
end

function ENT:EndCoreCharge( num )
    self[ "SetCore" .. num .. "Charged" ]( self, true )
    self[ "SetIsCore" .. num .. "Charging" ]( self, false )
    self:SetCurrentCoreHealth( 100 )
    self:SetChargeDuration( 175 )
    self:SetChargeStart( CurTime() )
    self:SetChargeCurTime( CurTime() + self:GetChargeDuration() )
    self:SetChargeDuration( 175 )
end

function ENT:BeginCoreCharge( num )
    self:SetIsCharging( true )
    self[ "SetIsCore" .. num .. "Charging" ]( self, true )
    self:SetCurrentCoreHealth( 100 )
    self:SetChargeDuration( 175 )
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
    --if KeysToTheCity() then return end
    for k, ply in ipairs( player.GetAll() ) do
        if ply:SqrRangeTo( self ) < ( 2000 * 2000 ) then
            ply:PlayDirectorVoiceLine( path )
        end
    end
end

function ENT:BeginCharge()

    CD2CreateThread( function() 

        self:StartMusic() 
        self.cd2_delay = CurTime() + 34
        self:BeginCoreCharge( 1 )
        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/finalfight1.mp3" ) 

        coroutine.wait( 10 )

        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/finalfight2.mp3" ) 

        coroutine.wait( 9 )

        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/finalfight3.mp3" ) 
        local core = self:GetActiveCore()

        while IsValid( core ) and core:IsCharging() do if !IsValid( self ) then return end coroutine.yield() end
    
        self:StartMusic() 
        self.cd2_delay = CurTime() + 15
        self:BeginCoreCharge( 2 )

        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/beaconcore1charged.mp3" ) 

        core = self:GetActiveCore()

        while IsValid( core ) and core:IsCharging() do if !IsValid( self ) then return end coroutine.yield() end

        self:StartMusic() 
        self.cd2_delay = CurTime() + 15
        self:BeginCoreCharge( 3 )

        self:DispatchDirectorLine( "sound/crackdown2/vo/agencydirector/beaconcore2charged.mp3" ) 

        core = self:GetActiveCore()

        while IsValid( core ) and core:IsCharging() do if !IsValid( self ) then return end coroutine.yield() end

        self:Remove()

    end )

end


if CLIENT then
    net.Receive( "cd2net_towerbeacon_beginmusic", function() 
        local tower = net.ReadEntity()
        if !IsValid( tower ) then return end 

        local core = tower:GetCurrentCore()

        CD2StartMusic( "sound/crackdown2/music/towerbeacon.mp3", 700, nil, nil, nil, nil, nil, nil, nil, function( CD2Musicchannel )
            if !IsValid( tower ) or core != tower:GetCurrentCore() then CD2Musicchannel:FadeOut() return end

            if LocalPlayer():SqrRangeTo( tower:GetPos() ) > ( 2000 * 2000 ) then
                CD2Musicchannel:GetChannel():SetVolume( 0 )
            else 
                CD2Musicchannel:GetChannel():SetVolume( 1 )
            end
        end )

    end )
end