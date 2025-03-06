AddCSLuaFile()

ENT.Base = "cd2_npcbase"
ENT.PrintName = "Goliath"

if CLIENT then language.Add( "cd2_goliath", "Goliath" ) end
if SERVER then util.AddNetworkString( "cd2net_goliathkill" ) end

-- NPC Stats
ENT.cd2_Health = 3000 -- The health the NPC has
ENT.cd2_Team = "freak" -- The Team the NPC will be in. It will attack anything that isn't on its team
ENT.cd2_SightDistance = 2000 -- How far this NPC can see
ENT.cd2_Weapon = "none" -- The weapon this NPC will have
ENT.cd2_IsCD2NPC = true -- Crackdown 2 NPC
ENT.cd2_RunSpeed = 400 -- Run speed
ENT.cd2_WalkSpeed = 100 -- Walk speed
ENT.cd2_CrouchSpeed = 60 -- Crouch speed
ENT.cd2_damagedivider = 1 -- The amount we should divide damage caused by this npc
ENT.cd2_maxskillorbs = 30 -- The max amount of skill orbs the player can get out of this NPC when they kill it
ENT.cd2_IsRanged = false -- If this freak is ranged
ENT.cd2_NoHeadShot = true -- This NPC can not be targetted in the head
--

ENT.cd2_holdtypetranslations = {

    [ "normal" ] = {
        idle = ACT_HL2MP_IDLE_ZOMBIE,
        walk = ACT_HL2MP_RUN_ZOMBIE,
        run = ACT_HL2MP_RUN_ZOMBIE,
        jump = ACT_HL2MP_JUMP_ZOMBIE,
        crouch = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_ZOMBIE,
        reload = ACT_HL2MP_GESTURE_RELOAD_ZOMBIE,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_ZOMBIE
    },

}

ENT.cd2_EnemyLastKnownPosition = Vector() -- The last know position of our enemy
ENT.cd2_CombatTimeout = 0 -- The time until we stop looking for our enemy
ENT.cd2_sightlinecheck = 0 -- The next time we will check our sightline for enemies
ENT.cd2_Gesture = nil -- The next gesture to play
ENT.cd2_nextattack = 0 -- The next time we can attack
ENT.cd2_NextIdleWalk = 0

local math_max = math.max

function ENT:ModelGet()
    return "models/player/zombie_soldier.mdl"
end

local random = math.random
local sound_Play = sound.Play
function ENT:Initialize2()
    self:SetModel( self:ModelGet() )
    self:SetState( "SpawnAnim" )

    if SERVER then
        net.Start( "cd2net_playerlandingdecal" )
        net.WriteVector( self:WorldSpaceCenter() )
        net.WriteBool( true )
        net.Broadcast()

        self:SetModelScale( 3, 0 )
        self:SetPos( self:GetPos() + Vector( 0, 0, 50 ))

        self:Hook( "EntityEmitSound", "hearing", function( snddata )
            if IsValid( self:GetEnemy() ) then return end
            local chan = snddata.Channel 
            local pos = snddata.Pos or IsValid( snddata.Entity ) and snddata.Entity or nil
            if self:GetRangeSquaredTo( pos ) > ( self.cd2_SightDistance * self.cd2_SightDistance ) or pos == self or pos == self:GetActiveWeapon() then return end

            local trace = self:Trace( nil, pos, COLLISION_GROUP_WORLD )
            if trace.Hit and random( 1, 4) == 1 then self.cd2_Goal = isentity( pos ) and pos:GetPos() or pos end

            if pos and chan == CHAN_WEAPON then self:LookTo( pos, 3 ) end
        end )
        
        sound_Play( "crackdown2/ply/hardland" .. random( 1, 2 ) .. ".wav", self:GetPos(), 65, 100, 1 )

        self.loco:SetStepHeight( 100 )
    end

    if SERVER then self.cd2_Path = Path( "Follow" ) self.loco:SetAcceleration( 2000 ) end
end

function ENT:HandleAnimEvent( event, time, cycle, type, options ) 

end

function ENT:PlayGesture( act )
    self.cd2_Gesture = act
end

function ENT:BehaveUpdate( fInterval )

    if self.cd2_Gesture then
        local id = self:AddGesture( self.cd2_Gesture, true )
        self:SetLayerPlaybackRate( id, 1 )
        self.cd2_Gesture = nil
    end

	if !self.BehaveThread then return end

	if coroutine.status( self.BehaveThread ) == "dead" then

		self.BehaveThread = nil
		Msg( self, " Warning: ENT:RunBehaviour() has finished executing\n" )

		return

	end

	local ok, message = coroutine.resume( self.BehaveThread )
	if ok == false then

		self.BehaveThread = nil
		ErrorNoHalt( self, " Error: ", message, "\n" )

	end

end


function ENT:OnInjured2( info ) 
    local attacker = info:GetAttacker()

    if ( ( attacker:IsCD2NPC() or attacker:IsCD2Agent() ) and attacker:GetCD2Team() != self:GetCD2Team() ) then
        self:AttackTarget( attacker )
    end
end

function ENT:AttackTarget( ent )
    if IsValid( self:GetEnemy() ) and ( self:GetEnemy().cd2_IsBeaconPart or self:GetEnemy():GetClass() == "cd2_beacon" ) then return end

    self:SetEnemy( ent )
    self.cd2_EnemyLastKnownPosition = ent:GetPos()
    self.cd2_CombatTimeout = CurTime() + 10
end

function ENT:OnKilled( info )

    self:Ignite( 10000 )

    self:RemoveAllHooks()

    CD2:AssessSkillGainOrbs( self, self.cd2_loggeddamage )

    hook.Run( "CD2_OnNPCKilled", self, info )

    self:SetState( "DieSequence" )

end


function ENT:EndMovementControl()
    self.cd2_Goal = nil
    self:SetIsMoving( false )
    self.cd2_Path:Invalidate()
end

function ENT:ControlMovement( pos, update )
    local shouldupdatepath = false

    --if pos != self.cd2_LastGoal then shouldupdatepath = true end

    self.cd2_LastGoal = pos

    local realpos = Vector( pos[ 1 ] , pos[ 2 ] , self:GetPos()[ 3 ] )
	local realrange = self:GetPos():DistToSqr( realpos )

    if realrange < ( 30 * 30 ) then self:EndMovementControl() return end

    self:SetIsMoving( true )

    if !IsValid( self.cd2_Path ) or update and self.cd2_Path:GetAge() > update or shouldupdatepath or self.cd2_RecomputeMove then

        shouldupdatepath = false
        self.cd2_RecomputeMove = false

        self.cd2_Path:Compute( self, pos )

    else

        self.cd2_Path:Update( self )
        self:DoorCheck()

        if self.loco:IsStuck() then
            self.loco:Jump()
            self.loco:ClearStuck()
        end


        if GetConVar( "developer" ):GetBool() then
            self.cd2_Path:Draw()
        end


    end

end

function ENT:CanAttack( ent )
    return ( ( ent:IsCD2NPC() or ent:IsCD2Agent() and !ent.cd2_notarget ) and ent:GetCD2Team() != self:GetCD2Team() or ( ent.cd2_IsBeaconPart and ent:GetOwner():GetIsCharging() ) ) and self:CanSee( ent )
end

function ENT:Swipe()
    if CurTime() < self.cd2_nextattack then return end

    self:EmitSound2( "crackdown2/npc/goliath/goliath_hit.mp3", 400, 5 )
    CD2:CreateThread( function()
        self:PlayGesture( ACT_GMOD_GESTURE_RANGE_ZOMBIE )

        coroutine.wait( 1 )
        if !IsValid( self ) or !IsValid( self:GetEnemy() ) or self:GetRangeSquaredTo( self:GetEnemy() ) > ( 200 * 200 ) then return end
        self:GetEnemy():EmitSound2( "crackdown2/npc/goliath/goliath_beaconhit.mp3", 600, 10 )
        local info = DamageInfo()
        info:SetAttacker( self ) 
        info:SetDamage( 40 ) 
        info:SetDamageType( DMG_DIRECT )
        self:GetEnemy():TakeDamageInfo( info )
    end )
    self.cd2_nextattack = CurTime() + 1.5
end

local anims = { "zombie_slump_rise_02_fast", "zombie_slump_rise_02_slow", "zombie_slump_rise_01" }
function ENT:SpawnAnim()
    self:EmitSound2( "crackdown2/npc/goliath/goliath_roar.mp3", 200, 10 )
    self:PlaySequenceAndWait( anims[ random( #anims ) ], 0.7 )
    self:EmitSound2( "crackdown2/npc/goliath/goliath_roar.mp3", 200, 10 )
    self:PlaySequenceAndWait( "taunt_zombie", 0.5 )
    if self:GetState() == "DieSequence" then return end
    self:SetState( "MainThink" )
end

function ENT:DieSequence()
    self:LookTo()
    self:EmitSound2( "crackdown2/npc/goliath/goliath_die.mp3", 200, 10 )
    --sound.Play( "crackdown2/npc/goliath/goliath_die.mp3", self:GetPos(), 100, 1 )
    self:PlaySequenceAndWait( "death_04", 0.5 )
    net.Start( "cd2net_goliathkill", true )
    net.WriteVector( self:GetPos() )
    net.Broadcast()
    self:Remove()
end

function ENT:MainThink()

    while self:GetIsDisabled() do coroutine.yield() end

    --self:PlayVoiceSound( "npc/zombie/zombie_voice_idle" .. random( 1, 14 ) .. ".wav", rand( 3, 10 ) )

    if IsValid( self:GetEnemy() ) and self:GetRangeSquaredTo( self:GetEnemy() ) <= ( 60 * 60 ) then
        self:LookTo( self:GetEnemy(), 3 )
        self:Swipe()
    end

    if self.MainThink2 then self:MainThink2() end

    if !self.loco:GetVelocity():IsZero() and ( !self.cd2_stepcooldown or CurTime() > self.cd2_stepcooldown ) then
        sound.Play( "crackdown2/npc/goliath/goliath_step" .. random( 1, 3 ) .. ".mp3", self:GetPos(), 90, 100, 1 )
        net.Start( "cd2net_explosion" )
        net.WriteVector( self:GetPos() )
        net.WriteFloat( 0.8 )
        net.Broadcast()
        self.cd2_stepcooldown = CurTime() + 0.4
    end

    if IsValid( self:GetEnemy() ) and CurTime() > self.cd2_CombatTimeout then self:SetEnemy( NULL ) end
    
    self:SetWalk( !IsValid( self:GetEnemy() ) )

    if !IsValid( self:GetEnemy() ) and CurTime() > self.cd2_NextIdleWalk then
        
        self.cd2_Goal = self:GetPos() + Vector( random( -500, 500 ), random( -500, 500 ) )
        self.cd2_NextIdleWalk = CurTime() + 5
    elseif IsValid( self:GetEnemy() ) then 
       
        if !self:CanSee( self:GetEnemy() ) then
            self.cd2_Goal = self.cd2_EnemyLastKnownPosition
        else
            self:LookTo( self:GetEnemy(), 3 )
            self.cd2_Goal = self:GetEnemy():GetPos()
            self.cd2_EnemyLastKnownPosition = self:GetEnemy():GetPos()
            self.cd2_CombatTimeout = CurTime() + 10
        end

    end

    if CurTime() > self.cd2_sightlinecheck then
        local ent = self:CheckSightLine()
        if IsValid( ent ) then self:AttackTarget( ent ) end
        self.cd2_sightlinecheck = CurTime() + 0.5
    end
    
    
    if self.cd2_Goal then
        self:ControlMovement( self.cd2_Goal, IsValid( self:GetEnemy() ) and math_max( 0.3, 0.3 * ( self.cd2_Path:GetLength() / 400 ) ) or 4 )
    end
end


if CLIENT then
    net.Receive( "cd2net_goliathkill", function()
        local pos = net.ReadVector()

        sound.Play( "ambient/fire/gascan_ignite1.wav", pos, 90, 100, 1 )
        local particle = ParticleEmitter( pos )
        for i = 1, 80 do

            local part = particle:Add( "particle/SmokeStack", pos )

            if part then
                part:SetStartSize( 70 )
                part:SetEndSize( 70 ) 
                part:SetStartAlpha( 255 )
                part:SetEndAlpha( 0 )

                part:SetColor( 255, 255, 50 )
                part:SetLighting( false )
                part:SetCollide( false )

                part:SetDieTime( 2 )
                part:SetGravity( Vector( 0, 0, -80 ) )
                part:SetAirResistance( 200 )
                part:SetVelocity( Vector( random( -1000, 1000 ), random( -1000, 1000 ), random( -1000, 1000 ) ) )
                part:SetAngleVelocity( AngleRand( -1, 1 ) )
            end

        end

        particle:Finish()

    end )
end