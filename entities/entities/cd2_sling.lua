AddCSLuaFile()

ENT.Base = "base_anim"

function ENT:Initialize()
    self:DrawShadow( false )

    if SERVER then
        self:PhysicsInitSphere( 5, "default" )

        local phys = self:GetPhysicsObject()
        self:SetGravity( 0.3 )

        if IsValid( phys ) then  
            phys:SetMass( 100 )
        end

        self:AddCallback( "PhysicsCollide", function( self, data )
            local ent = data.HitEntity
            if !IsValid( ent ) then return end

            sound.Play( "crackdown2/npc/freak/freakslinghit.wav", self:GetPos(), 70, 100, 1 )

            local info = DamageInfo()
            info:SetAttacker( self )
            info:SetInflictor( self )
            info:SetDamageType( DMG_ACID )
            info:SetDamage( 10 )

            ent:TakeDamageInfo( info )

            self:Remove()
        end )

        util.SpriteTrail( self, 0, dangercolors[ "dangercol" .. self:GetDangerLevel() ], true, 5, 0, 1, 1 / ( 5 + 0 ) * 0.5, "trails/laser" )
    end
end

function ENT:ThrowAt( pos )
    pos = isentity( pos ) and pos:WorldSpaceCenter() or pos

    local phys = self:GetPhysicsObject()
    phys:ApplyForceCenter( ( pos - self:GetPos() ):GetNormalized() * 10000 )
end

function ENT:SetupDataTables()
    self:NetworkVar( "Int", 0, "DangerLevel" )
end

local dangercolors = {}
dangercolors.dangercol1 = Color( 30, 150, 0 )
dangercolors.dangercol2 = Color( 192, 173, 0)
dangercolors.dangercol3 = Color( 199, 90, 0)

function ENT:Draw()
    render.DrawSphere( self:GetPos(), 5, 5, 5, dangercolors[ "dangercol" .. self:GetDangerLevel() ] )
end
