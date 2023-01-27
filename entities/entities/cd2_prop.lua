ENT.Base = "base_anim"

function ENT:Initialize()
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
end

if SERVER then

    function ENT:VisCheck()
        local players = player.GetAll()
        local withinPVS = false
        for i = 1, #players do
            local ply = players[ i ]
            if ply:IsCD2Agent() and self:SqrRangeTo( ply ) < ( 3000 * 3000 ) then withinPVS = true end
        end
        if !withinPVS then self:Remove() end
    end

    function ENT:Think()
        self:VisCheck()
        self:NextThink( CurTime() + 1 )
        return true
    end

end

function ENT:Draw()
    if LocalPlayer():SqrRangeTo( self ) > ( 2000 * 2000 ) then return end
    self:DrawModel()
end