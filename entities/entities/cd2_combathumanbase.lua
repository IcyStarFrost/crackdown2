AddCSLuaFile()

ENT.Base = "cd2_npcbase"
ENT.PrintName = "Cd2 npc"

ENT.cd2_Health = 100 -- The health the NPC has
ENT.cd2_Team = "lonewolf" -- The Team the NPC will be in. It will attack anything that isn't on its team
ENT.cd2_SightDistance = 2000 -- How far this NPC can see
ENT.cd2_Weapon = "cd2_smg" -- The weapon this NPC will have
ENT.cd2_Equipment = "cd2_grenade" -- The equipment this npc can use
ENT.cd2_RunSpeed = 200 -- Run speed
ENT.cd2_WalkSpeed = 100 -- Walk speed
ENT.cd2_CrouchSpeed = 80 -- Crouch speed
ENT.cd2_damagedivider = 1


ENT.cd2_EnemyLastKnownPosition = Vector() -- The last know position of our enemy
ENT.cd2_CombatTimeout = 0 -- The time until we stop looking for our enemy
ENT.cd2_sightlinecheck = 0 -- The next time we will check our sightline for enemies


local rand = math.Rand
local random = math.random
local IsValid = IsValid

function ENT:ModelGet()
end

function ENT:Initialize2()
    self.cd2_NextIdleWalk = CurTime() + 5

    if SERVER then self:SetModel( self:ModelGet() ) self.cd2_Path = Path( "Follow" ) end

    if SERVER then
        self:Hook( "EntityEmitSound", "hearing", function( snddata )
            if IsValid( self:GetEnemy() ) then return end
            local chan = snddata.Channel 
            local pos = snddata.Pos or IsValid( snddata.Entity ) and snddata.Entity or nil
            if self:GetRangeSquaredTo( pos ) > ( self.cd2_SightDistance * self.cd2_SightDistance ) or pos == self or pos == self:GetActiveWeapon() then return end

            local trace = self:Trace( nil, pos, COLLISION_GROUP_WORLD )
            if trace.Hit and random( 1, 4) == 1 then self.cd2_Goal = isentity( pos ) and pos:GetPos() or pos end

            if pos and chan == CHAN_WEAPON then self:LookTo( pos, 3 ) end
        end )
    end

    self:SetState( "MainThink" )
end

function ENT:AttackTarget( ent )
    self:SetEnemy( ent )
    self.cd2_EnemyLastKnownPosition = ent:GetPos()
    self.cd2_CombatTimeout = CurTime() + 10
end


function ENT:OnInjured2( info ) 
    local attacker = info:GetAttacker()

    if ( ( attacker:IsCD2NPC() or attacker:IsCD2Agent() ) and attacker:GetCD2Team() != self:GetCD2Team() ) then
        self:AttackTarget( attacker )
    end

    if self:GetCD2Team() == "cell" then
        self:PlayPainSound( "vo/npc/male01/pain0" .. random( 1, 9 ) .. ".wav" )
    end
end


function ENT:CanAttack( ent )
    return ( ( ent:IsCD2NPC() or ent:IsCD2Agent() ) and ent:GetCD2Team() != self:GetCD2Team() and ent:GetCD2Team() != "civilian" ) and self:CanSee( ent )
end



function ENT:EndMovementControl()
    self.cd2_Goal = nil
    self:SetIsMoving( false )
    self.cd2_Path:Invalidate()
end

function ENT:ControlMovement( pos, update )
    local shouldupdatepath = false

    if pos != self.cd2_LastGoal then shouldupdatepath = true end

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

function ENT:MainThink()

    if IsValid( self:GetEnemy() ) and self:CanAttack( self:GetEnemy() ) then
        self:LookTo( self:GetEnemy(), 3 )
        self:FireWeapon()
        self.cd2_EnemyLastKnownPosition = self:GetEnemy():GetPos()
        self.cd2_CombatTimeout = CurTime() + 10
    end

    local wep = self:GetActiveWeapon()

    if IsValid( wep ) and !IsValid( self:GetEnemy() ) and wep:Clip1() < wep:GetMaxClip1() and random( 1, 100 ) == 1 and !wep:GetIsReloading() then
        wep:Reload()
    end

    if self.MainThink2 then self:MainThink2() end

    if IsValid( self:GetEnemy() ) and CurTime() > self.cd2_CombatTimeout then self:SetEnemy( NULL ) end
    
    self:SetWalk( !IsValid( self:GetEnemy() ) )

    if !IsValid( self:GetEnemy() ) and CurTime() > self.cd2_NextIdleWalk then
        
        self.cd2_Goal = self:GetRandomPos( 500 )
        self.cd2_NextIdleWalk = CurTime() + 5
    elseif IsValid( self:GetEnemy() ) then 

        if !self:CanSee( self:GetEnemy() ) then

            if self.cd2_NextLookAround and CurTime() > self.cd2_NextLookAround then
                self:LookTo( self:GetPos() + Vector( random( -500, 500 ), random( -500, 500 ) ), 3 )
                self.cd2_NextLookAround = CurTime() + 1
            end

            self.cd2_Goal = self.cd2_EnemyLastKnownPosition
        else

            if self.cd2_Equipment != "none" and random( 1, 1000 ) == 1 and ( !self.cd2_grenadecooldown or CurTime() > self.cd2_grenadecooldown ) then
                CD2CreateThread( function()
                    self:AddGesture( ACT_GMOD_GESTURE_ITEM_THROW, true )
                    coroutine.wait( 1 )
                    if !IsValid( self ) or !IsValid(  self:GetEnemy() ) then return end
                    CD2ThrowEquipment( self.cd2_Equipment, self, self:GetEnemy():GetPos() )
                end )
                self.cd2_grenadecooldown = CurTime() + rand( 5, 15 )
            end
            
            self.cd2_NextLookAround = CurTime() + 5
            if ( !self.cd2_MoveChange or CurTime() > self.cd2_MoveChange ) then
                self.cd2_Goal = self:GetPos() + Vector( random( -500, 500 ), random( -500, 500 ) )
                self.cd2_MoveChange = CurTime() + 3
            end
        end

    end

    if CurTime() > self.cd2_sightlinecheck then
        local ent = self:CheckSightLine()
        if IsValid( ent ) then self:SetEnemy( ent ) end
        self.cd2_sightlinecheck = CurTime() + 0.3
    end
    
    
    if self.cd2_Goal then
        self:ControlMovement( self.cd2_Goal, 5 )
    end
end