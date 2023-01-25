AddCSLuaFile()

ENT.Base = "base_anim"

-- The final beacon in the game

function ENT:Initialize()

    self:SetModel( "models/props_combine/combinethumper001a.mdl" )

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

    if SERVER then
        self.Core1 = CreateCore( self:GetPos() + self:GetForward() * 100 )
        self.Core2 = CreateCore( ( self:GetPos() - self:GetForward() * 100 ) - self:GetRight() * 100 )
        self.Core3 = CreateCore( ( self:GetPos() - self:GetForward() * 100 ) + self:GetRight() * 100 )
    end

    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

    local phys = self:GetPhysicsObject()
    if IsValid( phys ) then
        phys:EnableMotion( false )
    end

    if SERVER then
        timer.Simple( 10, function() self:Remove() end )
    end
end

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "IsCharging" )
    
    self:NetworkVar( "Float", 0, "ChargeDuration" )
    self:NetworkVar( "Float", 1, "CurrentCoreHealth" )

    self:NetworkVar( "Int", 0, "CurrentCore" )
end