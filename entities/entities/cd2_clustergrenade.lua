AddCSLuaFile()

ENT.Base = "cd2_equipmentbase"
ENT.WorldModel = "models/weapons/w_eq_fraggrenade.mdl"
ENT.PrintName = "Cluster Grenade"

ENT.Cooldown = 1
ENT.MaxGrenadeCount = 8
ENT.TrailColor = Color( 255 ,174, 0)
ENT.DelayTime = 1 -- The time before the grenade blows up. 0 for no timed explosive
ENT.TickSound = "weapons/grenade/tick1.wav"

ENT.DropMenu_RequiresCollect = true
ENT.DropMenu_SkillLevel = 0
ENT.DropMenu_Damage = 8
ENT.DropMenu_Range = 10

ENT.Clusters = {}

local random = math.random
local util_SpriteTrail = util.SpriteTrail

local skillsounds = { [ 1 ] = "crackdown2/weapons/explosiveskill1.wav", [ 2 ] = "crackdown2/weapons/explosiveskill2.wav", [ 3 ] = "crackdown2/weapons/explosiveskill3.wav" }
local highskillsounds = { "crackdown2/weapons/explosiveskill4.wav", "crackdown2/weapons/explosiveskill5.wav", "crackdown2/weapons/explosiveskill6.wav" }


function ENT:CreateCluster()

    local cluster = ents.Create( "prop_physics" )
    cluster:SetModel( self:GetModel() )
    cluster:SetNoDraw( true )
    cluster:SetPos( self:GetPos() + Vector( 0, 0, 2 ) )
    cluster:SetOwner( self ) 
    cluster:SetCollisionGroup( COLLISION_GROUP_WORLD )
    cluster:Spawn()

    hook.Add( "EntityTakeDamage", cluster, function( entself, ent, info )
        if ent == cluster then return true end
    end )

    self.Clusters[ #self.Clusters + 1 ] = cluster

    if SERVER then
        util_SpriteTrail( cluster, 0, self.TrailColor, true, 5, 0, 2, 1 / ( 5 + 0 ) * 0.5, "trails/laser" )
    end

    local phys = cluster:GetPhysicsObject()

    if IsValid( phys ) then
        phys:ApplyForceCenter( Vector( random( -600, 600 ), random( -600, 600 ), random( 100, 600 )) )
    end

    cluster:AddCallback( "PhysicsCollide", function()

        local effect = EffectData()
        effect:SetOrigin( cluster:GetPos() )
        util.Effect( "Explosion", effect, true, true )

        util.Decal( "Scorch", cluster:GetPos(), cluster:GetPos() - Vector( 0, 0, 50 ), cluster )
    
        if SERVER then
            local skilllevel = self:GetThrower():IsPlayer() and self:GetThrower():GetExplosiveSkill() or 1
    
            local blast = DamageInfo()
            blast:SetAttacker( IsValid( self:GetThrower() ) and self:GetThrower() or self )
            blast:SetInflictor( self )
            blast:SetDamage( 200 + ( skilllevel > 1 and 50 * skilllevel or 0 ) )
            blast:SetDamageType( DMG_BLAST )
            blast:SetDamagePosition( cluster:GetPos() )
    
            if skilllevel < 4 then
                sound.Play( skillsounds[ skilllevel ], cluster:GetPos(), 80, 100, 1 )
            elseif skilllevel >= 4 then
                sound.Play( highskillsounds[ random( 3 ) ], cluster:GetPos(), 90, 100, 1 )
            end

            if skilllevel > 1 then
                sound.Play( "crackdown2/weapons/exp" .. random( 1, 4 ) .. ".wav", self:GetPos(), 90 + ( 10 * skilllevel ), 100, 1 )
            end
    
            util.BlastDamageInfo( blast, cluster:GetPos(), 400 + ( skilllevel > 1 and 50 * skilllevel or 0 ) )
    
            net.Start( "cd2net_explosion" )
            net.WriteVector( cluster:GetPos() )
            net.WriteFloat( 1 + ( skilllevel == 6 and 4 or skilllevel > 1 and 0.25 * skilllevel or 0 ) )
            net.Broadcast()
    
            cluster:Remove()
        end
    end )

end

function ENT:HasClusters()
    for i = 1, #self.Clusters do local cluster = self.Clusters[ i ] if IsValid( cluster ) then return true end end
    return false
end

function ENT:OnDelayEnd()

    if CLIENT then
        local effect = EffectData()
        effect:SetOrigin( self:GetPos() )
        util.Effect( "Explosion", effect, true, true )
    end

    util.Decal( "Scorch", self:GetPos(), self:GetPos() - Vector( 0, 0, 50 ), self )

    if SERVER then
        local skilllevel = self:GetThrower():IsPlayer() and self:GetThrower():GetExplosiveSkill() or 1

        local blast = DamageInfo()
        blast:SetAttacker( IsValid( self:GetThrower() ) and self:GetThrower() or self )
        blast:SetInflictor( self )
        blast:SetDamage( 200 + ( skilllevel > 1 and 50 * skilllevel or 0 ) )
        blast:SetDamageType( DMG_BLAST )
        blast:SetDamagePosition( self:GetPos() )

        if skilllevel < 4 then
            sound.Play( skillsounds[ skilllevel ], self:GetPos(), 80, 100, 1 )
        elseif skilllevel >= 4 then
            sound.Play( highskillsounds[ random( 3 ) ], self:GetPos(), 90, 100, 1 )
        end

        if skilllevel > 1 then
            sound.Play( "crackdown2/weapons/exp" .. random( 1, 4 ) .. ".wav", self:GetPos(), 90 + ( 10 * skilllevel ), 100, 1 )
        end

        util.BlastDamageInfo( blast, self:GetPos(), 400 + ( skilllevel > 1 and 50 * skilllevel or 0 ) )

        net.Start( "cd2net_explosion" )
        net.WriteVector( self:GetPos() )
        net.WriteFloat( 1 + ( skilllevel == 6 and 4 or skilllevel > 1 and 0.25 * skilllevel or 0 ) )
        net.Broadcast()

        CD2CreateThread( function()
            for i = 1, 8 do
                self:CreateCluster()
                coroutine.yield()
            end

            while self:HasClusters() do coroutine.yield() end

            self:Remove()
        end )
        
    end
end