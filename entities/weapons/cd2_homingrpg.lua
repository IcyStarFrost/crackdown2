AddCSLuaFile()

DEFINE_BASECLASS( "cd2_weaponbase" )

SWEP.Base = "cd2_weaponbase"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"
SWEP.PrintName = "Homing Missile Launcher"

SWEP.Primary.Ammo = "RPG_Round"
SWEP.Primary.ClipSize = 3
SWEP.Primary.DefaultClip = 36
SWEP.Primary.Automatic = false

SWEP.Primary.RPM = 30
SWEP.Primary.Damage = nil
SWEP.Primary.Force = nil
SWEP.Primary.Tracer = 5
SWEP.Primary.Spread = 0.03
SWEP.Primary.LockOnSpread = 0
SWEP.Primary.Bulletcount = 1
SWEP.ReloadTime = 2
SWEP.ReloadSounds = { { 0, "weapons/smg1/smg1_reload.wav" }, { 2, "weapons/slam/mine_mode.wav" } }

SWEP.DropMenu_RequiresCollect = true
SWEP.DropMenu_SkillLevel = 1
SWEP.DropMenu_Damage = 7
SWEP.DropMenu_Range = 5
SWEP.DropMenu_FireRate = 1

SWEP.LockOnRange = 1500
SWEP.IsExplosive = true
SWEP.HoldType = "rpg"
SWEP.Primary.ShootSound = { "crackdown2/weapons/rpgfire1.mp3", "crackdown2/weapons/rpgfire2.mp3", "crackdown2/weapons/rpgfire3.mp3" }

local random = math.random

local skillsounds = { [ 1 ] = "crackdown2/weapons/explosiveskill1.wav", [ 2 ] = "crackdown2/weapons/explosiveskill2.wav", [ 3 ] = "crackdown2/weapons/explosiveskill3.wav" }
local highskillsounds = { "crackdown2/weapons/explosiveskill4.wav", "crackdown2/weapons/explosiveskill5.wav", "crackdown2/weapons/explosiveskill6.wav" }

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
        local skilllevel = self:GetOwner():IsPlayer() and self:GetOwner():GetExplosiveSkill() or 1

        local rocket = ents.Create( "rpg_missile" )
        rocket:SetPos( self:GetOwner():GetShootPos() + self:GetOwner():EyeAngles():Up() * 10 )
        rocket:SetAngles( self:GetOwner():IsCD2NPC() and ( self:GetOwner():GetEnemy():GetPos() - self:GetOwner():CD2EyePos() ):Angle() or self:GetOwner():EyeAngles() )
        rocket:SetOwner( self:GetOwner() )
        rocket:SetMoveType( MOVETYPE_FLYGRAVITY )
        rocket:SetAbsVelocity( self:GetForward() * 1500 + Vector( 0, 0, 128 ) )
        rocket:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
        rocket:SetSaveValue( "m_flDamage", 120 + ( skilllevel > 1 and 50 * skilllevel or 0 ) )
        rocket:Spawn()

        CD2:CreateThread( function()
            local target = self:GetOwner():IsPlayer() and self:GetOwner():GetNW2Entity( "CD2_lockontarget", nil ) or self:GetOwner():IsCD2NPC() and self:GetOwner():GetEnemy()
            
            while true do 
                if !IsValid( target ) or !IsValid( rocket ) then return end
                rocket:SetAngles( LerpAngle( 10 * FrameTime(), rocket:GetAngles(), ( target:GetPos() - rocket:GetPos() ):Angle() ) )
                rocket:SetLocalVelocity( rocket:GetForward() * 1500 )
                coroutine.yield()
            end
            
        end )

        rocket:CallOnRemove( "explodeeffects", function()

            if skilllevel > 1 then
                local blast = DamageInfo()
                blast:SetAttacker( IsValid( self:GetOwner() ) and self:GetOwner() or rocket )
                blast:SetInflictor( rocket )
                blast:SetDamage( 200 + ( skilllevel > 1 and 50 * skilllevel or 0 ) )
                blast:SetDamageType( DMG_BLAST )
                blast:SetDamagePosition( rocket:GetPos() )

                util.BlastDamageInfo( blast, rocket:GetPos(), 300 + ( skilllevel > 1 and 50 * skilllevel or 0 ) )

                if skilllevel < 4 then
                    sound.Play( skillsounds[ skilllevel ], rocket:GetPos(), 80, 100, 1 )
                elseif skilllevel >= 4 then
                    sound.Play( highskillsounds[ random( 3 ) ], rocket:GetPos(), 90, 100, 1 )
                end

                sound.Play( "crackdown2/weapons/exp" .. random( 1, 4 ) .. ".wav", rocket:GetPos(), 90 + ( 10 * skilllevel ), 100, 1 )
            end

            net.Start( "cd2net_explosion" )
            net.WriteVector( rocket:GetPos() )
            net.WriteFloat( 1 + ( skilllevel == 6 and 4 or skilllevel > 1 and 0.25 * skilllevel or 0 ) )
            net.Broadcast()
        end )

    end

    self:SetNextPrimaryFire( CurTime() + 60 / self.Primary.RPM )
end

function SWEP:Reload()
    if self:GetIsReloading() or ( self:GetOwner():IsPlayer() and self:GetOwner():GetAmmoCount( self.Primary.Ammo ) <= 0 ) or self:Clip1() == self:GetMaxClip1() then return end
    if self:GetOwner():IsCD2NPC() then self:GetOwner():AddGesture( ACT_HL2MP_GESTURE_RELOAD_SMG1, true ) end
    if self:GetOwner():IsPlayer() then BroadcastLua( "Entity(" .. self:GetOwner():EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_HL2MP_GESTURE_RELOAD_SMG1, true )" ) end
    BaseClass.Reload( self )
end