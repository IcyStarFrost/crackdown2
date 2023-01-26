AddCSLuaFile()

ENT.Base = "cd2_equipmentbase"
ENT.WorldModel = "models/items/combine_rifle_ammo01.mdl"
ENT.PrintName = "UV Grenade"
ENT.IsEquipment = true

ENT.Cooldown = 1
ENT.MaxGrenadeCount = 8
ENT.TrailColor = Color( 0 ,153, 255 )
ENT.DelayTime = 1 -- The time before the grenade blows up. 0 for no timed explosive
ENT.TickSound = "buttons/button18.wav"

ENT.DropMenu_SkillLevel = 2
ENT.DropMenu_Damage = 2
ENT.DropMenu_Range = 7

if SERVER then util.AddNetworkString( "cd2net_uvgrenadeexplode" ) end

local random = math.random

function ENT:OnDelayEnd()

    if SERVER then
        local skilllevel = self:GetThrower():IsPlayer() and self:GetThrower():GetExplosiveSkill() or 1

        local blast = DamageInfo()
        blast:SetAttacker( IsValid( self:GetThrower() ) and self:GetThrower() or self )
        blast:SetInflictor( self )
        blast:SetDamage( 20 + ( skilllevel > 1 and 30 * skilllevel or 0 ) )
        blast:SetDamageType( DMG_BLAST + DMG_SHOCK )
        blast:SetDamagePosition( self:GetPos() )
        
        util.BlastDamageInfo( blast, self:GetPos(), 600 + ( skilllevel > 1 and 50 * skilllevel or 0 ) )

        for k, v in ipairs( CD2FindInSphere( self:GetPos(), 600 + ( skilllevel > 1 and 50 * skilllevel or 0 ), function( ent ) return ent:IsCD2NPC() and ent:GetCD2Team() == "freak" end ) ) do
            blast = DamageInfo()
            blast:SetAttacker( IsValid( self:GetThrower() ) and self:GetThrower() or self )
            blast:SetInflictor( self )
            blast:SetDamage( v:GetMaxHealth() )
            blast:SetDamageType( DMG_BLAST + DMG_SHOCK )
            blast:SetDamagePosition( self:GetPos() )

            if v:GetClass() == "cd2_goliath" then
                blast:SetDamage( 300 )
            end

            v:TakeDamageInfo( blast )
        end
        sound.Play( "ambient/levels/labs/electric_explosion" .. random( 1, 5 ) .. ".wav", self:GetPos(), 90, 100, 1 )
        sound.Play( "crackdown2/weapons/uvgrenadeblast" .. random( 1, 2 ) .. ".mp3", self:GetPos(), 120, 100, 1 )

        net.Start( "cd2net_uvgrenadeexplode" )
        net.WriteVector( self:GetPos() )
        net.WriteFloat( 2 + ( skilllevel == 6 and 4 or skilllevel > 1 and 0.25 * skilllevel or 0 ) )
        net.Broadcast()

        local pos = self:GetPos()
        CD2CreateThread( function()
            local scale = 2 + ( skilllevel == 6 and 4 or skilllevel > 1 and 0.25 * skilllevel or 0 )
            
            for i = 1, 30 do 

                local randomvalue = 500 + ( scale > 1 and 200 * scale or 0 )
                local rndpos = pos + Vector( random( -randomvalue, randomvalue ), random( -randomvalue, randomvalue ), random( -randomvalue, randomvalue )  )
                local effect = EffectData()
                effect:SetOrigin( rndpos )
                effect:SetScale( 1 )
                effect:SetMagnitude( 4 )
                effect:SetRadius( 10 )

                util.Effect( "Sparks", effect, true, true )

                sound.Play( "ambient/energy/spark" .. random( 1, 6 ) .. ".wav", rndpos, 70, 100, 1 )

                coroutine.wait( 0.1 )
            end
        end )

        self:Remove()
    end
end

if CLIENT then
    local energy = Material( "crackdown2/effects/energy.png", "smooth" )

    net.Receive( "cd2net_uvgrenadeexplode", function()
        local pos = net.ReadVector()
        local scale = net.ReadFloat()

        hook.Add( "Think", "crackdown2_explosionlight", function()
            local light = DynamicLight( random( 0, 1000000 ) )
            if ( light ) then
                light.pos = pos
                light.r = 0
                light.g = 153
                light.b = 255
                light.brightness = 5
                light.Decay = 800
                light.Size = 500 + ( scale > 1 and 600 * scale or 0)
                light.DieTime = CurTime() + 5
                hook.Remove( "Think", "crackdown2_explosionlight" )
            end
        end )
    
        addvec = VectorRand( 20 * -scale, 20 * scale )
        local particle = ParticleEmitter( pos, pos + addvec )
    
        for i = 1, 25 + ( 5 * scale ) do
            addvec = VectorRand( 20 * -scale, 20 * scale )
            local part = particle:Add( energy, pos + addvec )
    
            if part then
                part:SetStartSize( 60 * scale )
                part:SetEndSize( 45 * scale ) 
                part:SetStartAlpha( 255 )
                part:SetEndAlpha( 0 )
    
                part:SetColor( 255, 255, 255 )
                part:SetLighting( false )
    
                part:SetDieTime( 6 )
                part:SetGravity( Vector() )
                part:SetAirResistance( 200 )
    
                local randomvalue = 2000 + ( scale > 1 and 200 * scale or 0 )
    
                part:SetVelocity( Vector( random( -randomvalue, randomvalue ), random( -randomvalue, randomvalue ), random( -randomvalue, randomvalue ) ) )
                part:SetAngleVelocity( AngleRand( -0.5, 0.5 ) )
            end
    
        end
    
        particle:Finish()

        particle = ParticleEmitter( pos )
        for i = 1, 40 do
            
            local part = particle:Add( energy, pos )
    
            if part then
                part:SetStartSize( 70 )
                part:SetEndSize( 70 ) 
                part:SetStartAlpha( 255 )
                part:SetEndAlpha( 0 )
    
                part:SetColor( 255, 255, 255 )
                part:SetLighting( false )
                part:SetCollide( false )
    
                part:SetDieTime( 2 )
                part:SetGravity( Vector() )
                part:SetAirResistance( 200 )

                local randomvalue = 1000 + ( scale > 1 and 200 * scale or 0 )

                part:SetVelocity( Vector( math.sin( i ) * randomvalue, math.cos( i ) * randomvalue, 0 ) )
                part:SetAngleVelocity( AngleRand( -1, 1 ) )
            end
    
        end
    
        particle:Finish()
    
    end )
end