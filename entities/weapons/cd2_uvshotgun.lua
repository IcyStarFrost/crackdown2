AddCSLuaFile()

DEFINE_BASECLASS( "cd2_weaponbase" )

SWEP.Base = "cd2_weaponbase"
SWEP.WorldModel = "models/weapons/w_physics.mdl"
SWEP.PrintName = "UV Shotgun"

SWEP.Primary.Ammo = "357"
SWEP.Primary.ClipSize = 20
SWEP.Primary.DefaultClip = 60
SWEP.Primary.Automatic = false

SWEP.Primary.RPM = 50
SWEP.Primary.Damage = nil
SWEP.Primary.Force = nil
SWEP.Primary.Tracer = 5
SWEP.Primary.Spread = 0.03
SWEP.Primary.LockOnSpread = 0
SWEP.Primary.Bulletcount = 1
SWEP.ReloadTime = 2
SWEP.ReloadSounds = { { 0, "buttons/button18.wav" }, { 1, "weapons/physcannon/physcannon_charge.wav" }, { 2, "buttons/button14.wav" }, { 2.1, "buttons/button14.wav" } }

SWEP.DropMenu_SkillLevel = 2
SWEP.DropMenu_Damage = 4
SWEP.DropMenu_Range = 3
SWEP.DropMenu_FireRate = 3

SWEP.HoldType = "physgun"
SWEP.Primary.ShootSound = { "crackdown2/weapons/uvfire1.mp3" }

local random = math.random

if SERVER then util.AddNetworkString( "cd2net_uvshotgun_fire" ) end

function SWEP:Initialize()
    self:SetSkin( 1 )
    BaseClass.Initialize( self )
end

function SWEP:PrimaryAttack()
    if !self:CanPrimaryAttack() or CurTime() < self:GetNextPrimaryFire() or self:GetIsReloading() then return end

    self:TakePrimaryAmmo( 1 )

    if istable( self.Primary.ShootSound ) then
        local snd = self.Primary.ShootSound[ random( #self.Primary.ShootSound ) ]
        self:EmitSound( snd, 80, 100, 1, CHAN_WEAPON )
    else
        self:EmitSound( self.Primary.ShootSound, 80, 100, 1, CHAN_WEAPON )
    end
    self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

    if SERVER then
        net.Start( "cd2net_uvshotgun_fire" )
        net.WriteVector( self:GetOwner():GetShootPos() )
        net.WriteNormal( self:GetOwner():GetAimVector() )
        net.Broadcast()

        local cone = ents.FindInCone( self:GetOwner():GetShootPos(), self:GetOwner():GetAimVector(), 600, 0.85 )

        for k, ent in ipairs( cone ) do
            if !IsValid( ent ) or ent == self:GetOwner() then continue end 
            
            if ent:IsCD2NPC() then

                if ent:GetCD2Team() == "freak" then
                    local blast = DamageInfo()
                    blast:SetAttacker( self:GetOwner() )
                    blast:SetInflictor( self )
                    blast:SetDamage( ent:GetClass() != "cd2_goliath" and ent:GetMaxHealth() or 100 )
                    blast:SetDamageType( DMG_BULLET )
                    blast:SetDamageForce( ( ent:WorldSpaceCenter() - self:GetPos() ):GetNormalized() * 80000 )
                    ent:TakeDamageInfo( blast )
                else
                    local blast = DamageInfo()
                    blast:SetAttacker( self:GetOwner() )
                    blast:SetInflictor( self )
                    blast:SetDamage( 15 )
                    blast:SetDamageType( DMG_BULLET )
                    blast:SetDamageForce( ( ent:WorldSpaceCenter() - self:GetPos() ):GetNormalized() * 80000 )
                    ent:TakeDamageInfo( blast )

                    ent:Ignite( 3 )

                    ent.loco:Jump()
                    ent.loco:SetVelocity( ent.loco:GetVelocity() + ( ent:WorldSpaceCenter() - self:GetPos() ):GetNormalized() * 1000 )
                end

            else
                local blast = DamageInfo()
                blast:SetAttacker( self:GetOwner() )
                blast:SetInflictor( self )
                blast:SetDamage( 15 )
                blast:SetDamageType( DMG_BULLET )
                blast:SetDamageForce( ( ent:WorldSpaceCenter() - self:GetPos() ):GetNormalized() * 80000 )
                ent:TakePhysicsDamage( blast )

                if ent:IsPlayer() then ent:SetPos( ent:GetPos() + Vector( 0, 0, 5 ) ) ent:SetVelocity( ( ent:WorldSpaceCenter() - self:GetPos() ):GetNormalized() * 1000 ) end
            end
        end
    end

    


    self:SetNextPrimaryFire( CurTime() + 60 / self.Primary.RPM )
end

function SWEP:Reload()
    if self:GetIsReloading() or ( self:GetOwner():IsPlayer() and self:GetOwner():GetAmmoCount( self.Primary.Ammo ) <= 0 ) or self:Clip1() == self:GetMaxClip1() then return end
    if self:GetOwner():IsCD2NPC() then self:GetOwner():AddGesture( ACT_HL2MP_GESTURE_RELOAD_SMG1, true ) end
    if self:GetOwner():IsPlayer() then BroadcastLua( "Entity(" .. self:GetOwner():EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_HL2MP_GESTURE_RELOAD_AR2, true )" ) end
    BaseClass.Reload( self )
end

if CLIENT then
    local energy = Material( "crackdown2/effects/energy.png", "smooth" )

    net.Receive( "cd2net_uvshotgun_fire", function()
        local pos = net.ReadVector()
        local norm = net.ReadNormal()

        hook.Add( "Think", "crackdown2_uvlight", function()
            local light = DynamicLight( random( 0, 1000000 ) )
            if ( light ) then
                light.pos = pos
                light.r = 0
                light.g = 153
                light.b = 255
                light.brightness = 5
                light.Decay = 800
                light.Size = 500
                light.DieTime = CurTime() + 5
                hook.Remove( "Think", "crackdown2_uvlight" )
            end
        end )

        local particle = ParticleEmitter( pos )
    
        for i = 1, 50 do
            local part = particle:Add( energy, pos )
    
            if part then
                part:SetStartSize( 60 )
                part:SetEndSize( 45 ) 
                part:SetStartAlpha( 100 )
                part:SetEndAlpha( 0 )
    
                part:SetColor( 255, 255, 255 )
                part:SetLighting( false )
    
                part:SetDieTime( 3 )
                part:SetGravity( Vector() )
                part:SetAirResistance( 200 )
    
                local randomvalue = 700 
    
                part:SetVelocity( ( norm * 2000 ) + Vector( random( -randomvalue, randomvalue ), random( -randomvalue, randomvalue ), random( -randomvalue, randomvalue ) ) )
                part:SetAngleVelocity( AngleRand( -0.5, 0.5 ) )
            end
    
        end
    
        particle:Finish()

        CD2:CreateThread( function()
            local lerppos = pos * 1

            for i = 1, 10 do 
                local effect = EffectData()
                effect:SetOrigin( lerppos )
                effect:SetScale( 1 )
                effect:SetMagnitude( 2 )
                effect:SetRadius( 5 )

                util.Effect( "Sparks", effect, true, true )
                lerppos = LerpVector( 5 * FrameTime(), lerppos, pos + norm * 1500 )

                sound.Play( "ambient/energy/spark" .. random( 1, 6 ) .. ".wav", lerppos, 60, 100, 1 )
                coroutine.wait( 0.05 )
            end
        
        end )

    end )

end