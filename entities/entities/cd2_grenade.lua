AddCSLuaFile()

ENT.Base = "cd2_equipmentbase"
ENT.WorldModel = "models/weapons/w_grenade.mdl"
ENT.PrintName = "Frag Grenade"

ENT.MaxGrenadeCount = 8
ENT.TrailColor = Color( 255 ,174, 0)
ENT.DelayTime = 3 -- The time before the grenade blows up. 0 for no timed explosive
ENT.TickSound = "crackdown2/weapons/fragtick.mp3"

function ENT:OnDelayEnd()

    if CLIENT then
        local effect = EffectData()
        effect:SetOrigin( self:GetPos() )
        util.Effect( "Explosion", effect, true, true )
    end

    if SERVER then
        local blast = DamageInfo()
        blast:SetAttacker( self:GetThrower() or self )
        blast:SetInflictor( self )
        blast:SetDamage( 200 )
        blast:SetDamageType( DMG_BLAST )
        blast:SetDamagePosition( self:GetPos() )

        util.BlastDamageInfo( blast, self:GetPos(), 300 )

        self:Remove()
    end
end