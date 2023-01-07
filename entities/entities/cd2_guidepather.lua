ENT.Base = "base_nextbot"

function ENT:Initialize()
    self:SetNoDraw( true )
    self:DrawShadow( false )

    self.incrementval = 0
    self.NextTrailer = CurTime() + 2
    self.Path = Path( "Follow" )

    self.loco:SetDeathDropHeight( 10000000 )
    self.loco:SetJumpHeight( 100000000 )

    self:SetMoveType( MOVETYPE_NONE )
    self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

    hook.Add( "EntityTakeDamage", self, function( self, ent )
        if ent == self then return true end
    end )
end

function ENT:SetupDataTables()
    self:NetworkVar( "Vector", 0, "GoalPosition" )
end

function ENT:OnRemove()
    self.Path:Invalidate()
end

function ENT:DispatchTrailer()
    local trailer = ents.Create( "cd2_guidetrailer" )
    trailer:SetPos( self:GetPos() )
    trailer:SetPather( self )
    trailer.Path = self.Path
    trailer:Spawn()
end

function ENT:RunBehaviour()
    if !IsValid( self.Path ) then
        self.Path:Compute( self, self:GetGoalPosition() )
    end

    self:DispatchTrailer()

    while true do 

        if CurTime() > self.NextTrailer then
            self:DispatchTrailer()
            self.NextTrailer = CurTime() + 2
        end

        coroutine.yield()
    end
end
