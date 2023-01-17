AddCSLuaFile()

ENT.Base = "cd2_equipmentbase"
ENT.WorldModel = "models/weapons/w_grenade.mdl"
ENT.PrintName = "Frag Grenade"

ENT.Cooldown = 1
ENT.MaxGrenadeCount = 8
ENT.TrailColor = Color( 255 ,174, 0)
ENT.DelayTime = 1 -- The time before the grenade blows up. 0 for no timed explosive
ENT.TickSound = "crackdown2/weapons/fragtick.mp3"

ENT.DropMenu_SkillLevel = 0
ENT.DropMenu_Damage = 5
ENT.DropMenu_Range = 5

local random = math.random

local skillsounds = { [ 2 ] = "crackdown2/weapons/explosiveskill2.wav", [ 3 ] = "crackdown2/weapons/explosiveskill3.wav" }
local highskillsounds = { "crackdown2/weapons/explosiveskill4.wav", "crackdown2/weapons/explosiveskill5.wav", "crackdown2/weapons/explosiveskill6.wav" }

function ENT:OnDelayEnd()

    local effect = EffectData()
    effect:SetOrigin( self:GetPos() )
    util.Effect( "Explosion", effect, true, true )


    util.Decal( "Scorch", self:GetPos(), self:GetPos() - Vector( 0, 0, 50 ), self )

    if SERVER then
        local skilllevel = self:GetThrower():IsPlayer() and self:GetThrower():GetExplosiveSkill() or 1

        local blast = DamageInfo()
        blast:SetAttacker( IsValid( self:GetThrower() ) and self:GetThrower() or self )
        blast:SetInflictor( self )
        blast:SetDamage( 200 + ( skilllevel > 1 and 50 * skilllevel or 0 ) )
        blast:SetDamageType( DMG_BLAST )
        blast:SetDamagePosition( self:GetPos() )

        if skilllevel > 1 and skilllevel < 4 then
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

        self:Remove()
    end
end