AddCSLuaFile()

ENT.Base = "base_anim"

local dangercolors = {}
dangercolors.dangercol1 = Color( 30, 150, 0 )
dangercolors.dangercol2 = Color( 192, 173, 0)
dangercolors.dangercol3 = Color( 199, 90, 0)

function ENT:Initialize()
    self:DrawShadow( false )

    if SERVER then
        self:PhysicsInitSphere( 2, "default" )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )

        local phys = self:GetPhysicsObject()

        if IsValid( phys ) then  
            phys:EnableGravity( false )
            phys:SetMass( 1 )
        end

        util.SpriteTrail( self, 0, dangercolors[ "dangercol" .. self:GetDangerLevel() ], true, 5, 0, 1, 1 / ( 5 + 0 ) * 0.5, "trails/laser" )
    end
end

function ENT:OnRemove()
    if CLIENT then
        local particle = ParticleEmitter( self:GetPos() )
        for i = 1, 10 do
    
            local part = particle:Add( "particle/SmokeStack", self:GetPos() )
    
            if part then
                part:SetStartSize( 5 )
                part:SetEndSize( 5 ) 
                part:SetStartAlpha( 255 )
                part:SetEndAlpha( 0 )
    
                part:SetColor( dangercolors[ "dangercol" .. self:GetDangerLevel() ] )
                part:SetLighting( false )
                part:SetCollide( true )
    
                part:SetDieTime( 2 )
                part:SetGravity( Vector( 0, 0, -80 ) )
                part:SetAirResistance( 200 )
                part:SetVelocity( Vector( math.random( -200, 200 ), math.random( -200, 200 ), math.random( -200, 200 ) ) )
                part:SetAngleVelocity( AngleRand( -1, 1 ) )
            end
    
        end
    
        particle:Finish()
    end
end

function ENT:PhysicsCollide( data, collider ) 
    local ent = data.HitEntity
            
    sound.Play( "crackdown2/npc/freak/freakslinghit.wav", self:GetPos(), 70, 100, 1 )
    if IsValid( ent ) then
        
        local info = DamageInfo()
        info:SetAttacker( self )
        info:SetInflictor( self )
        info:SetDamageType( DMG_ACID )
        info:SetDamage( 10 * self:GetDangerLevel() )

        ent:TakeDamageInfo( info )
        local tbl = {
            Damage = 0,
            Distance = 10,
            HullSize = 50,
            Tracer = 0,
            Dir = self:GetVelocity(),
            Src = self:GetPos(),
            IgnoreEntity = self
        }

        self:FireBullets( tbl )
    end

    self:Remove()
end

function ENT:Think()
    local phys = self:GetPhysicsObject()

    if IsValid( phys ) then  
        phys:ApplyForceCenter( Vector( 0, 0, -60 ) )
    end
end

function ENT:ThrowAt( pos )
    pos = isentity( pos ) and pos:WorldSpaceCenter() or pos

    local phys = self:GetPhysicsObject()
    phys:ApplyForceCenter( ( pos - self:GetPos() ):GetNormalized() * 3000 )
end

function ENT:SetupDataTables()
    self:NetworkVar( "Int", 0, "DangerLevel" )
end



function ENT:Draw()
    render.SetColorMaterial()
    render.DrawSphere( self:GetPos(), 2, 5, 5, dangercolors[ "dangercol" .. self:GetDangerLevel() ] )
end
