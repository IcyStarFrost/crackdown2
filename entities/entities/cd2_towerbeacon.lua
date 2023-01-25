AddCSLuaFile()

ENT.Base = "base_anim"

-- The final beacon in the game

function ENT:Initialize()

    self:SetModel( "models/props_combine/combinethumper001a.mdl" )

    if SERVER then
        local function CreateCore( pos )
            local core = ents.Create( "base_anim" )
            core:SetModel( "models/props_combine/combine_generator01.mdl" )
            core:SetPos( pos )
            local ang = ( self:GetPos() - pos ):Angle() ang[ 1 ] = 0 ang[ 3 ] = 0
            core:SetAngles( ang + Angle( 0, 90, 0 ) )
            core:Spawn()
    
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

        self:SetCore1( CreateCore( self:GetPos() + self:GetForward() * 100 ) )
        self:SetCore2( CreateCore( ( self:GetPos() - self:GetForward() * 100 ) - self:GetRight() * 100 ) )
        self:SetCore3( CreateCore( ( self:GetPos() - self:GetForward() * 100 ) + self:GetRight() * 100 ) )

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
        timer.Simple( 3, function() self:Remove() end )
    end
end


local blackish = Color( 39, 39, 39 )
local linecol = Color( 61, 61, 61, 100 )
local orangeish = Color( 202, 79, 22 )
local chargecol = Color( 0, 110, 255 )
local glow = Material( "crackdown2/ui/skillglow2.png" )
local core1icon = Material( "crackdown2/ui/core1.png", "smooth" )
local core2icon = Material( "crackdown2/ui/core2.png", "smooth" )
local core3icon = Material( "crackdown2/ui/core3.png", "smooth" )

function ENT:HUDDraw()

    -- Base
    surface.SetDrawColor( blackish )
    draw.NoTexture()
    surface.DrawRect( ScrW() - 350,  40, 300, 64 )
    
    surface.SetDrawColor( linecol )
    surface.DrawOutlinedRect( ScrW() - 350,  40, 300, 64, 1 )
    --

    -- Icon
    surface.SetDrawColor( color_white )
    surface.SetMaterial( core1icon )
    surface.DrawTexturedRect( ScrW() - 420,  40, 64, 64 )

    self.cd2_corecolor.r = Lerp( 1 * FrameTime(), self.cd2_corecolor.r, 0 )
    self.cd2_corecolor.g = Lerp( 1 * FrameTime(), self.cd2_corecolor.g, 110 )
    self.cd2_corecolor.b = Lerp( 1 * FrameTime(), self.cd2_corecolor.b, 255 )

    surface.SetDrawColor( self.cd2_corecolor )
    surface.SetMaterial( glow )
    surface.DrawTexturedRect( ScrW() - 452,  5, 128, 128 )
    --
    
    local progressW = 280
    
    -- Beacon Progress bar
    surface.SetDrawColor( chargecol )
    surface.DrawRect( ScrW() - 340, 55, progressW, 10 )
    
    surface.SetDrawColor( linecol )
    surface.DrawOutlinedRect( ScrW() - 345,  50, 290, 20, 1 )

    local healthW = ( self:GetCurrentCoreHealth() / 100 ) * 280
    
    -- Beacon Health Bar
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

end

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "IsCharging" )
    self:NetworkVar( "Bool", 1, "IsDetonated" )
    
    self:NetworkVar( "Float", 0, "ChargeDuration" )
    self:NetworkVar( "Float", 1, "CurrentCoreHealth" )

    self:NetworkVar( "Entity", 0, "Core1" )
    self:NetworkVar( "Entity", 1, "Core2" )
    self:NetworkVar( "Entity", 2, "Core3" )

    self:NetworkVar( "Int", 0, "CurrentCore" )
end



function ENT:BeginCharge()

end