AddCSLuaFile()

ENT.Base = "base_anim"

function ENT:Initialize()
    self:SetModel( "models/hunter/tubes/tube2x2x1.mdl" )
    self:SetMaterial( "models/props_combine/metal_combinebridge001" )

    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

    if CLIENT then
        local mat = Matrix()
        mat:Scale( Vector( 0.7, 0.7, 0.3 ) )
        self:EnableMatrix( "RenderMultiply", mat )
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end
