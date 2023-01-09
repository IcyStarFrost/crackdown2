AddCSLuaFile()

ENT.Base = "base_nextbot"
local LerpVector = LerpVector
local FrameTime = FrameTime
local LerpAngle = LerpAngle


function ENT:Initialize()
    self:DrawShadow( false )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )


    if SERVER then
        self.Path = Path( "Follow" )
        self.loco:SetDeathDropHeight( 10000000 )
        self.loco:SetJumpHeight( 100000000 )

        self.CamFollower = ents.Create( "cd2_introcamfollower" )
        self.CamFollower:SetPos( self:GetPos() )
        self.CamFollower:SetOwner( self )
        self.CamFollower:SetAngles( self:GetAngles() )
        self.CamFollower:SetPlayer( self:GetPlayer() )
        self.CamFollower:Spawn()
        self.CamFollower.Path = self.Path
        self:DeleteOnRemove( self.CamFollower )
    end

    hook.Add( "SetupPlayerVisibility", self, function( self, ply, view ) 
        AddOriginToPVS( self.CamFollower:GetPos() )
    end )

   
end

function ENT:Draw() end


function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Player" )
end

local Trace = util.TraceLine
local normaltrace = {}
function ENT:Trace( start, endpos )
    normaltrace.start = start
    normaltrace.endpos = endpos
    normaltrace.filter = self
    normaltrace.mask = MASK_SOLID_BRUSHONLY
    normaltrace.collisiongroup = COLLISION_GROUP_WEAPON
    local result = Trace( normaltrace )
    return result
end

function ENT:Think()
    if IsValid( self.CamFollower ) then self:SetPos( self.CamFollower:GetPos() ) end
    
end

function ENT:RunBehaviour()

    while true do

        if !IsValid( self.Path ) or self.CamFollower:GetPos():DistToSqr( self.Path:GetEnd() ) <= ( 50 * 50 ) or self.cd2_recompute then
            self.Path:Compute( self, self.cd2_gotoposition or CD2GetRandomPos() )
            self.cd2_recompute = false
        end

        coroutine.yield()
    end

end