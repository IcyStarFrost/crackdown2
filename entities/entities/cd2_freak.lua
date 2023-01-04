AddCSLuaFile()

ENT.Base = "cd2_npcbase"
ENT.PrintName = "Freak"

if CLIENT then language.Add( "cd2_freak", "Freak" ) end

-- NPC Stats
ENT.cd2_Health = 80 -- The health the NPC has
ENT.cd2_Team = "freak" -- The Team the NPC will be in. It will attack anything that isn't on its team
ENT.cd2_SightDistance = 2000 -- How far this NPC can see
ENT.cd2_Weapon = "none" -- The weapon this NPC will have
ENT.cd2_IsCD2NPC = true -- Crackdown 2 NPC
ENT.cd2_RunSpeed = 200 -- Run speed
ENT.cd2_WalkSpeed = 100 -- Walk speed
ENT.cd2_CrouchSpeed = 60 -- Crouch speed
ENT.cd2_damagedivider = 1 -- The amount we should divide damage caused by this npc
ENT.cd2_maxskillorbs = 1 -- The max amount of skill orbs the player can get out of this NPC when they kill it
ENT.cd2_IsRanged = false -- If this freak is ranged
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
    return "models/player/zombie_classic.mdl"
end

local random = math.random
local sound_Play = sound.Play
local rand = math.Rand 
function ENT:Initialize2()
    self:SetModel( self:ModelGet() )
    self:SetState( "SpawnAnim" )

    if SERVER then
        net.Start( "cd2net_playerlandingdecal" )
        net.WriteVector( self:WorldSpaceCenter() )
        net.WriteBool( false  )
        net.Broadcast()

        self:Hook( "EntityEmitSound", "hearing", function( snddata )
            if IsValid( self:GetEnemy() ) then return end
            local chan = snddata.Channel 
            local pos = snddata.Pos or IsValid( snddata.Entity ) and snddata.Entity or nil
            if self:GetRangeSquaredTo( pos ) > ( self.cd2_SightDistance * self.cd2_SightDistance ) or pos == self or pos == self:GetActiveWeapon() then return end

            local trace = self:Trace( nil, pos, COLLISION_GROUP_WORLD )
            
            self.cd2_Goal = isentity( pos ) and pos:GetPos() or pos
            if pos and chan == CHAN_WEAPON then self:LookTo( pos, 3 ) end
        end )

        sound_Play( "crackdown2/ply/hardland" .. random( 1, 2 ) .. ".wav", self:GetPos(), 65, 100, 1 )
    end

    if SERVER then self.cd2_Path = Path( "Follow" ) self.loco:SetAcceleration( 2000 ) end
end


function ENT:PlayGesture( act )
    self.cd2_Gesture = act
end

function ENT:BehaveUpdate( fInterval )

    if self.cd2_Gesture then
        self:AddGesture( self.cd2_Gesture, true )
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
    self:SetEnemy( ent )
    self.cd2_EnemyLastKnownPosition = ent:GetPos()
    self.cd2_CombatTimeout = CurTime() + 10
end

function ENT:OnKilled2( info, ragdoll )
    ragdoll:EmitSound( "crackdown2/npc/freak/freakkill.mp3", 65 )
    ragdoll:EmitSound( "crackdown2/npc/freak/die" .. random( 1, 7 ) .. ".mp3", 70, 100, 1, CHAN_VOICE )

    ragdoll:Ignite( 10 )

    net.Start( "cd2net_freakkill" )
    net.WriteEntity( ragdoll )
    net.Broadcast()

    timer.Simple( 2, function()
        if !IsValid( ragdoll ) then return end
        ragdoll:Remove()
    end )
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

function ENT:Swipe()
    if CurTime() < self.cd2_nextattack then return end

    CD2CreateThread( function()
        self:PlayGesture( ACT_GMOD_GESTURE_RANGE_ZOMBIE )
        --self:EmitSound( "npc/zombie/zo_attack" .. random( 1, 2 ) .. ".wav", 70, 100, 1, CHAN_VOICE )
        coroutine.wait( 1 )
        if !IsValid( self ) or !IsValid( self:GetEnemy() ) or self:GetRangeSquaredTo( self:GetEnemy() ) > ( 60 * 60 ) then return end
        self:GetEnemy():EmitSound( "npc/zombie/claw_strike" .. random( 1, 3 ) .. ".wav", 70, 100, 1, CHAN_WEAPON )
        local info = DamageInfo()
        info:SetAttacker( self ) 
        info:SetDamage( 15 ) 
        info:SetDamageType( DMG_DIRECT )
        self:GetEnemy():TakeDamageInfo( info )
    end )
    self.cd2_nextattack = CurTime() + 2
end

local anims = { "zombie_slump_rise_02_fast", "zombie_slump_rise_02_slow", "zombie_slump_rise_01" }
function ENT:SpawnAnim()
    self:PlaySequenceAndWait( anims[ random( #anims ) ], speed )
    self:SetState( "MainThink" )
end

function ENT:MainThink()

    --self:PlayVoiceSound( "npc/zombie/zombie_voice_idle" .. random( 1, 14 ) .. ".wav", rand( 3, 10 ) )

    if IsValid( self:GetEnemy() ) and self:GetRangeSquaredTo( self:GetEnemy() ) <= ( 60 * 60 ) then
        self:LookTo( self:GetEnemy(), 3 )
        self:Swipe()
    end

    if self.MainThink2 then self:MainThink2() end

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
        self.cd2_sightlinecheck = CurTime() + 0.3
    end
    
    
    if self.cd2_Goal then
        self:ControlMovement( self.cd2_Goal, IsValid( self:GetEnemy() ) and math_max( 0.3, 0.3 * ( self.cd2_Path:GetLength() / 400 ) ) or 4 )
    end
end