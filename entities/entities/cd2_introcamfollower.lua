AddCSLuaFile()

ENT.Base = "base_anim"

function ENT:Initialize()

    if CLIENT then
        if LocalPlayer() != self:GetPlayer() then return end
        local currentviewpos = CD2_vieworigin * 1
        local currentviewangles = CD2_viewangles * 1

        CD2_DrawAgilitySkill = false
        CD2_DrawFirearmSkill = false
        CD2_DrawStrengthSkill = false
        CD2_DrawExplosiveSkill = false

        CD2_DrawTargetting = false
        CD2_DrawHealthandShields = false
        CD2_DrawWeaponInfo = false
        CD2_DrawMinimap = false
        CD2_DrawBlackbars = true

        local viewtbl = {}
        CD2_ViewOverride = function( ply, origin, angles, fov, znear, zfar )
            if !IsValid( self ) then CD2_ViewOverride = nil return end

            currentviewpos = LerpVector( 1 * FrameTime(), currentviewpos, self:Trace( self:GetPos() + Vector( 0, 0, 5 ), self:GetPos() + Vector( 0, 0, 1000 ) ).HitPos - Vector( 0, 0, 10 ) )
            currentviewangles = LerpAngle( 0.3 * FrameTime(), currentviewangles, self:GetAngles() )

            viewtbl.origin = currentviewpos
            viewtbl.angles = currentviewangles
            viewtbl.fov = 60
            viewtbl.znear = znear
            viewtbl.zfar = zfar
            viewtbl.drawviewer = true

            return viewtbl
        end
    end

    if SERVER then
        CD2CreateThread( function()

            while IsValid( self ) do

                if IsValid( self.Path ) then
                    if !IsValid( self ) then return end
                    local vecs = {}
                    local segments = self.Path:GetAllSegments()
                    for i = 1, #segments do if !IsValid( self ) then return end vecs[ #vecs + 1 ] = segments[ i ].pos end
        
                    for i = 1, #vecs do
                        if !IsValid( self ) then return end
                        local vector = vecs[ i ]
        
                        while IsValid( self ) and self:GetPos():DistToSqr( vector ) > ( 20 * 20 ) do
                            local ang = ( vector - self:GetPos() ):Angle() ang[ 1 ] = ang[ 1 ] + 20 ang[ 3 ] = 0
                            self:SetAngles( ang )
                            self:SetPos( self:GetPos() + ( vector - self:GetPos() ):GetNormalized() * 5 )
                            coroutine.yield()
                        end
        
                        coroutine.yield()
                    end

                    self.Path:Invalidate()
                end

                coroutine.yield()
            end

        end )

    end

end


function ENT:OnRemove()
    if CLIENT and LocalPlayer() == self:GetPlayer() then
        CD2_DrawAgilitySkill = true
        CD2_DrawFirearmSkill = true
        CD2_DrawStrengthSkill = true
        CD2_DrawExplosiveSkill = true

        CD2_DrawTargetting = true
        CD2_DrawHealthandShields = true
        CD2_DrawWeaponInfo = true
        CD2_DrawMinimap = true
        CD2_DrawBlackbars = false
    end
end


function ENT:Draw() end

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

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Player" )
end
