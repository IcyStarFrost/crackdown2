AddCSLuaFile()

ENT.Base = "cd2_equipmentbase"
ENT.WorldModel = "models/items/ar2_grenade.mdl"
ENT.PrintName = "Shrapnel Grenade"
ENT.IsEquipment = true

ENT.Cooldown = 1
ENT.MaxGrenadeCount = 8
ENT.TrailColor = Color( 255 ,174, 0)
ENT.DelayTime = 1 -- The time before the grenade blows up. 0 for no timed explosive
ENT.TickSound = "buttons/button16.wav"

ENT.DropMenu_RequiresCollect = true
ENT.DropMenu_SkillLevel = 0
ENT.DropMenu_Damage = 8
ENT.DropMenu_Range = 10

ENT.Clusters = {}

local random = math.random
local Trace = util.TraceLine
local normaltrace = {}

local skillsounds = { [ 1 ] = "crackdown2/weapons/explosiveskill1.wav", [ 2 ] = "crackdown2/weapons/explosiveskill2.wav", [ 3 ] = "crackdown2/weapons/explosiveskill3.wav" }
local highskillsounds = { "crackdown2/weapons/explosiveskill4.wav", "crackdown2/weapons/explosiveskill5.wav", "crackdown2/weapons/explosiveskill6.wav" }



function ENT:OnDelayEnd()

--[[     if CLIENT then
        local effect = EffectData()
        effect:SetOrigin( self:GetPos() )
        util.Effect( "Explosion", effect, true, true )
    end
 ]]
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
            sound.Play( skillsounds[ skilllevel ], self:GetPos(), 90, 100, 1 )
        elseif skilllevel >= 4 then
            sound.Play( highskillsounds[ random( 3 ) ], self:GetPos(), 100, 100, 1 )
        end

        if skilllevel > 1 then
            sound.Play( "crackdown2/weapons/exp" .. random( 1, 4 ) .. ".wav", self:GetPos(), 90 + ( 10 * skilllevel ), 100, 1 )
        end

        util.BlastDamageInfo( blast, self:GetPos(), 400 + ( skilllevel > 1 and 50 * skilllevel or 0 ) )

        net.Start( "cd2net_explosion" )
        net.WriteVector( self:GetPos() )
        net.WriteFloat( 1 + ( skilllevel == 6 and 4 or skilllevel > 1 and 0.25 * skilllevel or 0 ) )
        net.Broadcast()

        CD2:CreateThread( function()

            coroutine.wait( 0.5 )

            for i = 1, 5 do
                local pos = self:GetPos() + Vector( math.sin( i ) * 300, math.cos( i ) * 300, 300 )

                normaltrace.start = self:GetPos()
                normaltrace.endpos = pos
                normaltrace.filter = self
                normaltrace.mask = mask or MASK_SOLID
                normaltrace.collisiongroup = col or COLLISION_GROUP_NONE
                local result = Trace( normaltrace )

                local blast = DamageInfo()
                blast:SetAttacker( IsValid( self:GetThrower() ) and self:GetThrower() or self )
                blast:SetInflictor( self )
                blast:SetDamage( 250 + ( skilllevel > 1 and 50 * skilllevel or 0 ) )
                blast:SetDamageType( DMG_BLAST )
                blast:SetDamagePosition( result.HitPos )
        
                if skilllevel < 4 then
                    sound.Play( skillsounds[ skilllevel ], result.HitPos, 90, 100, 1 )
                elseif skilllevel >= 4 then
                    sound.Play( highskillsounds[ random( 3 ) ], result.HitPos, 100, 100, 1 )
                end
        
                if skilllevel > 1 then
                    sound.Play( "crackdown2/weapons/exp" .. random( 1, 4 ) .. ".wav", result.HitPos, 90 + ( 10 * skilllevel ), 100, 1 )
                end
        
                util.BlastDamageInfo( blast, result.HitPos, 500 + ( skilllevel > 1 and 50 * skilllevel or 0 ) )
        
                net.Start( "cd2net_explosion" )
                net.WriteVector( result.HitPos )
                net.WriteFloat( 1.5 + ( skilllevel == 6 and 4 or skilllevel > 1 and 0.25 * skilllevel or 0 ) )
                net.Broadcast()

                coroutine.yield()
            end 

            self:Remove()
        end )
        
        
    end
end