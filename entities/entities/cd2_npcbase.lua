AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "Crackdown 2 NPC"


include( "crackdown2/gamemode/crackdown2/npcbaseutil.lua" )

-- NPC Stats
ENT.cd2_Health = 100 -- The health the NPC has
ENT.cd2_Team = "lonewolf" -- The Team the NPC will be in. It will attack anything that isn't on its team
ENT.cd2_SightDistance = 1000 -- How far this NPC can see
ENT.cd2_Weapon = "cd2_pistol" -- The weapon this NPC will have
ENT.cd2_IsCD2NPC = true -- Crackdown 2 NPC
ENT.cd2_RunSpeed = 300 -- Run speed
ENT.cd2_WalkSpeed = 100 -- Walk speed
ENT.cd2_CrouchSpeed = 80 -- Crouch speed
ENT.cd2_damagedivider = 1 -- The amount we should divide damage caused by this npc
ENT.cd2_maxskillorbs = 0 -- The max amount of skill orbs the player can get out of this NPC when they kill it
--

-- Util variables
ENT.cd2_loggeddamage = {} -- A table of all the damage we have taken
ENT.cd2_NextDoorCheck = 0 -- The next time we will check for a door to open
ENT.cd2_FallVelocity = 0 -- How fast we are falling
ENT.cd2_AnimUpdate = 0 -- The next time our animations will update
ENT.cd2_PhysicsUpdate = 0 -- The next time our physics will update
ENT.cd2_NextPVScheck = 0 -- The next time we will check if we are in a player's pvs
ENT.cd2_StuckTimes = 0 -- The amount of times we got stuck
ENT.cd2_ShouldcheckPVS = true -- In singleplayer, if the npc should check if it's within the player's PVS and disable it self if it isn't
ENT.cd2_ClearStuckTimes = 0 -- The next time we will reset our stuck times
ENT.cd2_facetarget = nil -- The target we are facing
ENT.cd2_NextSpeak = 0 -- The next time we will speak
ENT.cd2_NextPainSound = 0 --The next time we can play a pain sound
ENT.cd2_Hooks = {} -- List of hooks we created
ENT.cd2_faceend = nil -- The time until we stop facing a target
ENT.cd2_holdtypetranslations = {

    [ "pistol" ] = {
        idle = ACT_HL2MP_IDLE_PISTOL,
        walk = ACT_HL2MP_WALK_PISTOL,
        run = ACT_HL2MP_RUN_PISTOL,
        jump = ACT_HL2MP_JUMP_PISTOL,
        crouch = ACT_HL2MP_IDLE_CROUCH_PISTOL,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_PISTOL,
        reload = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL
    },

    [ "smg" ] = {
        idle = ACT_HL2MP_IDLE_SMG1,
        walk = ACT_HL2MP_WALK_SMG1,
        run = ACT_HL2MP_RUN_SMG1,
        jump = ACT_HL2MP_JUMP_SMG1,
        crouch = ACT_HL2MP_IDLE_CROUCH_SMG1,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_SMG1,
        reload = ACT_HL2MP_GESTURE_RELOAD_SMG1,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1
    },

    [ "grenade" ] = {
        idle = ACT_HL2MP_IDLE_GRENADE,
        walk = ACT_HL2MP_WALK_GRENADE,
        run = ACT_HL2MP_RUN_GRENADE,
        jump = ACT_HL2MP_JUMP_GRENADE,
        crouch = ACT_HL2MP_IDLE_CROUCH_GRENADE,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_GRENADE,
        reload = ACT_HL2MP_GESTURE_RELOAD_GRENADE,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE
    },

    [ "ar2" ] = {
        idle = ACT_HL2MP_IDLE_AR2,
        walk = ACT_HL2MP_WALK_AR2,
        run = ACT_HL2MP_RUN_AR2,
        jump = ACT_HL2MP_JUMP_AR2,
        crouch = ACT_HL2MP_IDLE_CROUCH_AR2,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_AR2,
        reload = ACT_HL2MP_GESTURE_RELOAD_AR2,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2
    },

    [ "shotgun" ] = {
        idle = ACT_HL2MP_IDLE_SHOTGUN,
        walk = ACT_HL2MP_WALK_SHOTGUN,
        run = ACT_HL2MP_RUN_SHOTGUN,
        jump = ACT_HL2MP_JUMP_SHOTGUN,
        crouch = ACT_HL2MP_IDLE_CROUCH_SHOTGUN,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_SHOTGUN,
        reload = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN
    },

    [ "rpg" ] = {
        idle = ACT_HL2MP_IDLE_RPG,
        walk = ACT_HL2MP_WALK_RPG,
        run = ACT_HL2MP_RUN_RPG,
        jump = ACT_HL2MP_JUMP_RPG,
        crouch = ACT_HL2MP_IDLE_CROUCH_RPG,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_RPG,
        reload = ACT_HL2MP_GESTURE_RELOAD_RPG,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG
    },

    [ "physgun" ] = {
        idle = ACT_HL2MP_IDLE_PHYSGUN,
        walk = ACT_HL2MP_WALK_PHYSGUN,
        run = ACT_HL2MP_RUN_PHYSGUN,
        jump = ACT_HL2MP_JUMP_PHYSGUN,
        crouch = ACT_HL2MP_IDLE_CROUCH_PHYSGUN,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_PHYSGUN,
        reload = ACT_HL2MP_GESTURE_RELOAD_PHYSGUN,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_PHYSGUN
    },

    [ "crossbow" ] = {
        idle = ACT_HL2MP_IDLE_CROSSBOW,
        walk = ACT_HL2MP_WALK_CROSSBOW,
        run = ACT_HL2MP_RUN_CROSSBOW,
        jump = ACT_HL2MP_JUMP_CROSSBOW,
        crouch = ACT_HL2MP_IDLE_CROUCH_CROSSBOW,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_CROSSBOW,
        reload = ACT_HL2MP_GESTURE_RELOAD_CROSSBOW,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW
    },

    [ "melee" ] = {
        idle = ACT_HL2MP_IDLE_MELEE,
        walk = ACT_HL2MP_WALK_MELEE,
        run = ACT_HL2MP_RUN_MELEE,
        jump = ACT_HL2MP_JUMP_MELEE,
        crouch = ACT_HL2MP_IDLE_CROUCH_MELEE,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_MELEE,
        reload = ACT_HL2MP_GESTURE_RELOAD_MELEE,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE
    },

    [ "slam" ] = {
        idle = ACT_HL2MP_IDLE_SLAM,
        walk = ACT_HL2MP_WALK_SLAM,
        run = ACT_HL2MP_RUN_SLAM,
        jump = ACT_HL2MP_JUMP_SLAM,
        crouch = ACT_HL2MP_IDLE_CROUCH_SLAM,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_SLAM,
        reload = ACT_HL2MP_GESTURE_RELOAD_SLAM,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM
    },

    [ "normal" ] = {
        idle = ACT_HL2MP_IDLE,
        walk = ACT_HL2MP_WALK,
        run = ACT_HL2MP_RUN,
        jump = ACT_HL2MP_JUMP_FIST,
        crouch = ACT_HL2MP_IDLE_CROUCH,
        crouchwalk = ACT_HL2MP_WALK_CROUCH,
        reload = ACT_HL2MP_GESTURE_RELOAD,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK
    },

    [ "fist" ] = {
        idle = ACT_HL2MP_IDLE_FIST,
        walk = ACT_HL2MP_WALK_FIST,
        run = ACT_HL2MP_RUN_FIST,
        jump = ACT_HL2MP_JUMP_FIST,
        crouch = ACT_HL2MP_IDLE_CROUCH_FIST,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_FIST,
        reload = ACT_HL2MP_GESTURE_RELOAD_FIST,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST
    },

    [ "melee2" ] = {
        idle = ACT_HL2MP_IDLE_MELEE2,
        walk = ACT_HL2MP_WALK_MELEE2,
        run = ACT_HL2MP_RUN_MELEE2,
        jump = ACT_HL2MP_JUMP_MELEE2,
        crouch = ACT_HL2MP_IDLE_CROUCH_MELEE2,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_MELEE2,
        reload = ACT_HL2MP_GESTURE_RELOAD_MELEE2,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2
    },

    [ "knife" ] = {
        idle = ACT_HL2MP_IDLE_KNIFE,
        walk = ACT_HL2MP_WALK_KNIFE,
        run = ACT_HL2MP_RUN_KNIFE,
        jump = ACT_HL2MP_JUMP_KNIFE,
        crouch = ACT_HL2MP_IDLE_CROUCH_KNIFE,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_KNIFE,
        reload = ACT_HL2MP_GESTURE_RELOAD_KNIFE,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
    },

    [ "passive" ] = {
        idle = ACT_HL2MP_IDLE_PASSIVE,
        walk = ACT_HL2MP_WALK_PASSIVE,
        run = ACT_HL2MP_RUN_PASSIVE,
        jump = ACT_HL2MP_JUMP_PASSIVE,
        crouch = ACT_HL2MP_IDLE_CROUCH_PASSIVE,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_PASSIVE,
        reload = ACT_HL2MP_GESTURE_RELOAD_PASSIVE,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_PASSIVE
    },

    [ "duel" ] = {
        idle = ACT_HL2MP_IDLE_DUEL,
        walk = ACT_HL2MP_WALK_DUEL,
        run = ACT_HL2MP_RUN_DUEL,
        jump = ACT_HL2MP_JUMP_DUEL,
        crouch = ACT_HL2MP_IDLE_CROUCH_DUEL,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_DUEL,
        reload = ACT_HL2MP_GESTURE_RELOAD_DUEL,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_DUEL
    },

    [ "camera" ] = {
        idle = ACT_HL2MP_IDLE_CAMERA,
        walk = ACT_HL2MP_WALK_CAMERA,
        run = ACT_HL2MP_RUN_CAMERA,
        jump = ACT_HL2MP_JUMP_CAMERA,
        crouch = ACT_HL2MP_IDLE_CROUCH_CAMERA,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_CAMERA,
        reload = ACT_HL2MP_GESTURE_RELOAD_CAMERA,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_CAMERA
    },

    [ "magic" ] = {
        idle = ACT_HL2MP_IDLE_MAGIC,
        walk = ACT_HL2MP_WALK_MAGIC,
        run = ACT_HL2MP_RUN_MAGIC,
        jump = ACT_HL2MP_JUMP_MAGIC,
        crouch = ACT_HL2MP_IDLE_CROUCH_MAGIC,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_MAGIC,
        reload = ACT_HL2MP_GESTURE_RELOAD_MAGIC,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_MAGIC
    },

    [ "revolver" ] = {
        idle = ACT_HL2MP_IDLE_REVOLVER,
        walk = ACT_HL2MP_WALK_REVOLVER,
        run = ACT_HL2MP_RUN_REVOLVER,
        jump = ACT_HL2MP_JUMP_REVOLVER,
        crouch = ACT_HL2MP_IDLE_CROUCH_REVOLVER,
        crouchwalk = ACT_HL2MP_WALK_CROUCH_REVOLVER,
        reload = ACT_HL2MP_GESTURE_RELOAD_REVOLVER,
        fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER
    }
}

local IsValid = IsValid
local CurTime = CurTime
local clamp = math.Clamp
local Lerp = Lerp
local FrameTime = FrameTime
local random = math.random
local abs = math.abs


function ENT:Initialize()
    -- Set health
    self:SetHealth( self.cd2_Health )
    if SERVER then self:SetMaxHealth( self.cd2_Health ) end

    self:SetCD2Team( self.cd2_Team )
    self:SetSightDistance( self.cd2_SightDistance )
    self:SetState( "Idle" )

    self:PhysicsInitShadow()

    self:SetShouldServerRagdoll( true )
    self:AddFlags( FL_NPC )

    if SERVER and self.cd2_Weapon != "none" then self:Give( self.cd2_Weapon ) end

    if SERVER then
        local speed = self:GetCrouch() and self.cd2_CrouchSpeed or self:GetWalk() and self.cd2_WalkSpeed or self.cd2_RunSpeed
        
        self.loco:SetDesiredSpeed( speed )
        self.loco:SetStepHeight( 30 )

        self.cd2_NavArea = navmesh.GetNavArea( self:WorldSpaceCenter(), 200 )
        self.cd2_pvsremovetime = CurTime() + 10
    end

    self:AddCallback( "PhysicsCollide", function( us, data ) 
        self:HandleCollision( data )
    end )
    
    if CLIENT then self.cd2_candrawmodel = true self.cd2_nextdrawmodelcheck = CurTime() + 1 end

    if self.Initialize2 then self:Initialize2() end
    
end

function ENT:Draw()
    if CurTime() > self.cd2_nextdrawmodelcheck then
        self.cd2_candrawmodel = self:GetPos():DistToSqr( LocalPlayer():GetPos() ) <= ( 3000 * 3000 )
        self.cd2_nextdrawmodelcheck = CurTime() + 1
    end

    if self.cd2_candrawmodel then
        self:DrawModel()
    end
end

function ENT:SetupDataTables()
    self:NetworkVar( "String", 0, "CD2Team" )
    self:NetworkVar( "String", 1, "State" )

    self:NetworkVar( "Entity", 0, "WeaponEntity" )
    self:NetworkVar( "Entity", 1, "Enemy" )

    self:NetworkVar( "Bool", 0, "Crouch" )
    self:NetworkVar( "Bool", 1, "Walk" )
    self:NetworkVar( "Bool", 2, "IsMoving" )
    self:NetworkVar( "Bool", 3, "IsDisabled" )

    self:NetworkVar( "Int", 0, "SightDistance" )

    if self.SetupDataTables2 then self:SetupDataTables2() end

end


function ENT:HandleCollision( data )
    local collider = data.HitEntity

    if !IsValid( collider ) then return end

    local mass = data.HitObject:GetMass() or 500
    local impactdmg = ( ( data.TheirOldVelocity:Length() * mass ) / 1000 )

    if impactdmg > 10 then
        local dmginfo = DamageInfo()
        dmginfo:SetAttacker( collider )
        if IsValid( collider:GetPhysicsAttacker() ) then
            dmginfo:SetAttacker( collider:GetPhysicsAttacker() )
        elseif collider:IsVehicle() and IsValid( collider:GetDriver() ) then
            dmginfo:SetAttacker( collider:GetDriver() )
            dmginfo:SetDamageType(DMG_VEHICLE)     
        end
        dmginfo:SetInflictor( collider )
        dmginfo:SetDamage( impactdmg )
        dmginfo:SetDamageType( DMG_CRUSH + DMG_CLUB )
        dmginfo:SetDamageForce( data.TheirOldVelocity )
        self.loco:SetVelocity( self.loco:GetVelocity() + data.TheirOldVelocity )
        self:TakeDamageInfo( dmginfo )
    end

end

function ENT:Think()

    if SERVER and self.cd2_ShouldcheckPVS then
        if game.SinglePlayer() and !Entity( 1 ):TestPVS( self ) or CD2_DisableAllAI then
            self:SetIsDisabled( true )
            if !Entity( 1 ):TestPVS( self ) and CurTime() > self.cd2_pvsremovetime then self:Remove() end
        elseif game.SinglePlayer() and Entity( 1 ):TestPVS( self ) and !CD2_DisableAllAI then 
            self:SetIsDisabled( false )
        end
        if Entity( 1 ):TestPVS( self ) then self.cd2_pvsremovetime = CurTime() + 10 end
    end

    if CurTime() > self.cd2_PhysicsUpdate then
        local phys = self:GetPhysicsObject()

        if IsValid( phys ) then
            phys:SetPos( self:GetPos() )
            phys:SetAngles( self:GetAngles() )
        end

        self.cd2_PhysicsUpdate = CurTime() + 0.05
    end

    if !self:GetIsDisabled() and IsValid( self:GetActiveWeapon() ) and self:GetActiveWeapon():Clip1() == 0 then
        self:GetActiveWeapon():Reload()
    end

    if SERVER then self.cd2_FallVelocity = !self:IsOnGround() and self.loco:GetVelocity()[ 3 ] or self.cd2_FallVelocity end
    
    if SERVER and ( self.cd2_NextRegenTime and CurTime() > self.cd2_NextRegenTime ) and self:Health() < self:GetMaxHealth() then

        if !self.cd2_NextRegen or CurTime() > self.cd2_NextRegen then
            self:SetHealth( self:Health() + 1 )
            self.cd2_NextRegen = CurTime() + 0.03
        end
    end

    if SERVER and CurTime() > self.cd2_NextPVScheck then
        self:VisCheck()
        self.cd2_NextPVScheck = CurTime() + 5
    end

    if SERVER and CurTime() > self.cd2_AnimUpdate and !self.cd2_dontupdateanims then
        if self:WaterLevel() != 0 then
            local info = DamageInfo()
            info:SetAttacker( Entity( 0 ) )
            info:SetDamage( 10 )
            self:OnKilled( info )
        end

        local speed = self:GetCrouch() and self.cd2_CrouchSpeed or self:GetWalk() and self.cd2_WalkSpeed or self.cd2_RunSpeed
        self.loco:SetDesiredSpeed( speed )

        local wep = self:GetActiveWeapon()
        local holdtype = IsValid( wep ) and wep:GetHoldType() or "normal"

        if self.loco:GetVelocity():IsZero() and self:IsOnGround() and !self:GetCrouch() and self:GetActivity() != self.cd2_holdtypetranslations[ holdtype ].idle then
            self:StartActivity( self.cd2_holdtypetranslations[ holdtype ].idle )
        elseif self.loco:GetVelocity():IsZero() and self:IsOnGround() and self:GetCrouch() and self:GetActivity() != self.cd2_holdtypetranslations[ holdtype ].crouch then
            self:StartActivity( self.cd2_holdtypetranslations[ holdtype ].crouch )
        elseif !self.loco:GetVelocity():IsZero() and self:IsOnGround() and !self:GetCrouch() and !self:GetWalk() and self:GetActivity() != self.cd2_holdtypetranslations[ holdtype ].run then
            self:StartActivity( self.cd2_holdtypetranslations[ holdtype ].run )
        elseif !self.loco:GetVelocity():IsZero() and self:IsOnGround() and !self:GetCrouch() and self:GetWalk() and self:GetActivity() != self.cd2_holdtypetranslations[ holdtype ].walk then
            self:StartActivity( self.cd2_holdtypetranslations[ holdtype ].walk )
        elseif !self.loco:GetVelocity():IsZero() and self:IsOnGround() and self:GetCrouch() and self:GetActivity() != self.cd2_holdtypetranslations[ holdtype ].crouchwalk then
            self:StartActivity( self.cd2_holdtypetranslations[ holdtype ].crouchwalk )
        elseif !self:IsOnGround() and self:GetActivity() != self.cd2_holdtypetranslations[ holdtype ].jump then
            self:StartActivity( self.cd2_holdtypetranslations[ holdtype ].jump )
        end

        self.cd2_AnimUpdate = CurTime() + 0.1
    end


    if SERVER and !self:GetIsDisabled() then

        if self.cd2_facetarget then
            if self.cd2_faceend and CurTime() > self.cd2_faceend then self.cd2_faceend = nil self.cd2_facetarget = nil return end
            if isentity( self.cd2_facetarget ) and !IsValid( self.cd2_facetarget ) then self.cd2_facetarget = nil return end
            local pos = isentity( self.cd2_facetarget ) and self.cd2_facetarget:WorldSpaceCenter() or self.cd2_facetarget 
            self.loco:FaceTowards( pos )
            self.loco:FaceTowards( pos )


            local aimangle = ( pos - self:EyePos2() ):Angle()

            local loca = self:WorldToLocalAngles( aimangle )
            local approachy = Lerp( 5 * FrameTime(), self:GetPoseParameter('head_yaw'), loca[2] )
            local approachp = Lerp( 5 * FrameTime(), self:GetPoseParameter('head_pitch'), loca[1] )
            local approachaimy = Lerp( 5 * FrameTime(), self:GetPoseParameter('aim_yaw'), loca[2] )
            local approachaimp = Lerp( 5 * FrameTime(), self:GetPoseParameter('aim_pitch'), loca[1] )

            self:SetPoseParameter( 'head_yaw', approachy )
            self:SetPoseParameter( 'head_pitch', approachp )
            self:SetPoseParameter( 'aim_yaw', approachaimy )
            self:SetPoseParameter( 'aim_pitch', approachaimp )
        else
            local approachy = Lerp( 4 * FrameTime(), self:GetPoseParameter('head_yaw'), 0 )
            local approachp = Lerp( 4 * FrameTime(), self:GetPoseParameter('head_pitch'), 0 )
            local approachaimy = Lerp( 4 * FrameTime(), self:GetPoseParameter('aim_yaw'), 0 )
            local approachaimp = Lerp( 4 * FrameTime(), self:GetPoseParameter('aim_pitch'), 0 )

            self:SetPoseParameter( 'head_yaw', approachy )
            self:SetPoseParameter( 'head_pitch', approachp )
            self:SetPoseParameter( 'aim_yaw', approachaimy )
            self:SetPoseParameter( 'aim_pitch', approachaimp )
        end

    end

    if self.Think2 then self:Think2() end

end

function ENT:OnLandOnGround()
    
    if abs( self.cd2_FallVelocity ) > 1000 then
        local info = DamageInfo()
        info:SetAttacker( Entity( 0 ) )
        info:SetDamage( 10 )
        self:OnKilled( info )

        net.Start( "cd2net_playerlandingdecal" )
        net.WriteVector( self:WorldSpaceCenter() )
        net.WriteBool( self.cd2_FallVelocity >= 1000  )
        net.Broadcast()
    end


end

function ENT:PlaySequenceAndWait( name, speed )

    self.cd2_dontupdateanims = true
	local len = self:SetSequence( name )
	speed = speed or 1

	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( speed )

	coroutine.wait( len / speed )

    self.cd2_dontupdateanims = false

end


function ENT:OnNavAreaChanged( old, new )
    self.cd2_NavArea = new
end


function ENT:OnContact( ent )
    if ent:IsCD2Agent() then
        self:Approach( self:GetPos() + ( self:GetPos() - ent:GetPos() ):GetNormalized() * 50, 0.5 )
    end
end

function ENT:HandleStuck()
    if CurTime() > self.cd2_ClearStuckTimes then self.cd2_StuckTimes = 0 end

    if self.cd2_StuckTimes > 4 then
        self:TakeDamage( self:GetMaxHealth() + 1, Entity( 0 ) )
    elseif self.cd2_StuckTimes == 2 and IsValid( self.cd2_NavArea ) then
        self:SetPos( self.cd2_NavArea:GetCenter() )
    end

    self.cd2_ClearStuckTimes = CurTime() + 10
    self.cd2_StuckTimes = self.cd2_StuckTimes + 1

end

function ENT:OnInjured( info )
    local attacker = info:GetAttacker()
    self.cd2_NextRegenTime = CurTime() + 6
    if self.OnInjured2 then self:OnInjured2( info ) end
    if !IsValid( attacker ) or !attacker:IsPlayer() then return end
    self.cd2_loggeddamage[ attacker:SteamID() ] = self.cd2_loggeddamage[ attacker:SteamID() ] or {}

    self.cd2_loggeddamage[ attacker:SteamID() ][ info:GetDamageType() ] = self.cd2_loggeddamage[ attacker:SteamID() ][ info:GetDamageType() ] or 0
    self.cd2_loggeddamage[ attacker:SteamID() ][ info:GetDamageType() ] = self.cd2_loggeddamage[ attacker:SteamID() ][ info:GetDamageType() ] + info:GetDamage()
end

local function DropWeapons( pos, primary, equipment )

    local wep = ents.Create( primary )
    wep:SetPos( pos )
    wep:SetAngles( AngleRand( -180, 180 ) )
    wep:Spawn()
    wep.cd2_Ammocount = clamp( random( 1, wep.Primary.DefaultClip ), 0, wep.Primary.DefaultClip )
    wep:PhysWake()


    local phys = wep:GetPhysicsObject()

    if IsValid( phys ) then
        phys:ApplyForceCenter( Vector( random( -600, 600 ), random( -600, 600 ), random( 0, 600 ) ) )
    end

    if equipment and equipment != "none" then
        local equipment = ents.Create( equipment )
        equipment:SetPos( pos )
        equipment:Spawn()

        local phys = equipment:GetPhysicsObject()

        if IsValid( phys ) then
            phys:ApplyForceCenter( Vector( random( -8000, 8000 ), random( -8000, 8000 ), random( 0, 8000 ) ) )
        end
    end
end

function ENT:OnKilled( info )

    local ragdoll = self:BecomeRagdoll( info )
    if info:IsExplosionDamage() and info:GetDamage() > 100 then ragdoll:Ignite( 6 ) end

    local shoulddrop = IsValid( self:GetActiveWeapon() )

    if shoulddrop then
        local primary = self.cd2_Weapon
        local equipment = self.cd2_Equipment
        hook.Add( "Tick", ragdoll, function()
            if ragdoll:GetVelocity():Length() <= 50 then
                DropWeapons( ragdoll:GetPos() + Vector( 0, 0, 10 ), primary, equipment )
                hook.Remove( "Tick", ragdoll )
            end
        end )
    end
    
    self:RemoveAllHooks()

    CD2AssessSkillGainOrbs( self, self.cd2_loggeddamage )

    hook.Run( "OnCD2NPCKilled", self, info )
    
    timer.Simple( 15, function()
        if !IsValid( ragdoll ) then return end
        ragdoll:Remove()
    end )

    if self.OnKilled2 then self:OnKilled2( info, ragdoll ) end
end

function ENT:BodyUpdate()
    if game.SinglePlayer() and self:GetRangeSquaredTo( Entity( 1 ) ) > ( 2500 * 2500 ) then return end

    if !self.loco:GetVelocity():IsZero() and self:IsOnGround() then
        self:BodyMoveXY()
        return
    end

    self:FrameAdvance()
end



function ENT:RunBehaviour()

    while true do

        while self:GetIsDisabled() do coroutine.yield() end

        local func = self[ self:GetState() ]

        if func then
            func( self )
        end

        coroutine.yield()
    end

end