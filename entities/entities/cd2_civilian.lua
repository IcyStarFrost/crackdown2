AddCSLuaFile()

ENT.Base = "cd2_npcbase"
ENT.PrintName = "Civilian"

if CLIENT then language.Add( "cd2_civilian", "Civilian" ) end

ENT.cd2_Health = 40 -- The health the NPC has
ENT.cd2_Team = "civilian" -- Cell and Agency forces won't attack civilians
ENT.cd2_SightDistance = 2000 -- How far this NPC can see
ENT.cd2_Weapon = "none" -- This is a civilian. They are pretty boring not having conceal carry or something
ENT.cd2_RunSpeed = 200 -- Run speed
ENT.cd2_WalkSpeed = 100 -- Walk speed
ENT.cd2_CrouchSpeed = 80 -- Crouch speed

ENT.cd2_holdtypetranslations = {
    [ "normal" ] = {
        idle = ACT_IDLE,
        run = ACT_RUN,
        walk = ACT_WALK,
        jump = ACT_JUMP,
        crouch = ACT_CROUCH,
        crouchwalk = ACT_WALK_CROUCH
    }
}

include( "crackdown2/gamemode/crackdown2/civilianvoicelines.lua" )

ENT.cd2_PanicEnd = 0 -- The next time we will stop panicking

local RandomPairs = RandomPairs
local string_find = string.find
local random = math.random
local rand = math.Rand
local IsValid = IsValid

local mdls = {
    "models/humans/group01/male_01.mdl",
    "models/humans/group01/male_02.mdl",
    "models/humans/group01/male_03.mdl",
    "models/humans/group01/male_04.mdl",
    "models/humans/group01/male_05.mdl",
    "models/humans/group01/male_06.mdl",
    "models/humans/group01/male_07.mdl",
    "models/humans/group01/male_08.mdl",
    "models/humans/group01/male_09.mdl",

    "models/humans/group01/female_01.mdl",
    "models/humans/group01/female_02.mdl",
    "models/humans/group01/female_03.mdl",
    "models/humans/group01/female_04.mdl",
    "models/humans/group01/female_06.mdl",
    "models/humans/group01/female_07.mdl",
}

function ENT:Initialize2()
    if SERVER then 
        local model = mdls[ random( #mdls ) ]
        self:SetModel( model ) 
        self.cd2_gender = string_find( model, "female" ) != nil and "female" or "male"

        self:Hook( "EntityFireBullets", "bullethearing", function( ent, bullet ) 
            local pos = bullet.Src 

            local trace = self:Trace( nil, pos, COLLISION_GROUP_WORLD )
            if trace.Hit then return end
            
            if !self:GetIsPanicked() and self:GetRangeSquaredTo( pos ) <= ( self.cd2_SightDistance * self.cd2_SightDistance ) then
                self.cd2_FirstPanic = true
                self.cd2_Panickedlocation = pos
                self:LookTo( bullet.Attacker, 3 )
                self.cd2_PanicEnd = CurTime() + rand( 15, 30 )
                self:SetState( "Panicked" )
                self:StopMovement() 
            end
        end )

        self:Hook( "EntityEmitSound", "hearing", function( snddata )
            local chan = snddata.Channel
            local pos = IsValid( snddata.Entity ) and snddata.Entity or snddata.Pos

            if isentity( pos ) and !self:CanSee( pos ) then return end

            if chan == CHAN_WEAPON and !self:GetIsPanicked() and self:GetRangeSquaredTo( pos ) <= ( self.cd2_SightDistance * self.cd2_SightDistance ) then
                self.cd2_FirstPanic = true
                self.cd2_Panickedlocation = isentity( pos ) and pos:GetPos() or pos
                self:LookTo( pos, 3 )
                self.cd2_PanicEnd = CurTime() + rand( 15, 60 )
                self:SetState( "Panicked" )
                self:StopMovement() 
            end
        end )

        

    end

    
end

function ENT:HandleVoiceLines()
    if CLIENT then return end

    if self:GetIsPanicked() and self:CanSpeak() then
        local voicelines = self.cd2_VoiceLines[ self.cd2_gender ].panic
        local line = voicelines[ random( #voicelines ) ]
        self:PlayVoiceSound( line, rand( 5, 15 ) )
    end
end

function ENT:OnInjured2( info )

    local voicelines = self.cd2_VoiceLines[ self.cd2_gender ].pain
    local line = voicelines[ random( #voicelines ) ]
    self:PlayPainSound( line )


    if !self:GetIsPanicked() then
        self.cd2_Panickedlocation = self:GetPos()
        self.cd2_PanicEnd = CurTime() + rand( 15, 30 )
        self:SetState( "Panicked" )
        self:StopMovement() 
    end
end

function ENT:OnOtherKilled( victim )
    if !self:Trace( nil, victim:WorldSpaceCenter(), COLLISION_GROUP_WORLD ).Hit and !self:GetIsPanicked() then
        self.cd2_Panickedlocation = self:GetPos()
        self.cd2_PanicEnd = CurTime() + rand( 15, 30 )
        self:SetState( "Panicked" )
        self:StopMovement() 
    end
end



function ENT:Think2()
    self:HandleVoiceLines()

    self:SetIsPanicked( self:GetState() == "Panicked" )

    if self:GetIsPanicked() and CurTime() > self.cd2_PanicEnd then
        self:SetState( "Idle" )
        self:StopMovement() 
    end
end


-- Starts and stops the panic animation
function ENT:StartPanicAnim()
    self.cd2_holdtypetranslations[ "normal" ].run = ACT_RUN_PROTECTED
    self.cd2_holdtypetranslations[ "normal" ].idle = ACT_COWER
end

function ENT:EndPanicAnim()
    self.cd2_holdtypetranslations[ "normal" ].run = ACT_RUN
    self.cd2_holdtypetranslations[ "normal" ].idle = ACT_IDLE
end
--

function ENT:SetupDataTables2()
    self:NetworkVar( "Bool", 3, "IsPanicked" )
end

local function GetNavmeshFiltered()
    local areas = {} 
    for k, v in ipairs( navmesh.GetAllNavAreas() ) do
        if IsValid( v ) and !v:IsUnderwater() and v:GetSizeX() > 40 and v:GetSizeY() > 40 then
            areas[ #areas + 1 ] = v
        end
    end
    return areas
end

-- Returns areas that are not near the position
local function GetAwayNavmesh( pos, dist )
    local areas = {} 
    for k, v in ipairs( navmesh.GetAllNavAreas() ) do
        if IsValid( v ) and !v:IsUnderwater() and v:GetSizeX() > 40 and v:GetSizeY() > 40 and v:GetClosestPointOnArea( pos ):DistToSqr( pos ) > ( dist * dist ) then
            areas[ #areas + 1 ] = v
        end
    end
    if #areas == 0 then return GetNavmeshFiltered() end
    return areas
end

function ENT:EquipGuitar()
    local guitar = ents.Create( "base_anim" )
    guitar:SetPos( self:HandsPos() )
    guitar:SetAngles( self:HandsAngles() )
    guitar:SetModel( "models/crackdown2/civilian/guitar.mdl" )
    guitar:SetParent( self, self:LookupAttachment( "anim_attachment_RH" ) )
    guitar:Spawn()
    guitar:SetMaterial( "models/crackdown2/civilian/guitar/guitar" )
    guitar:SetLocalPos( Vector( 10, 0, 0 ) )
    guitar:SetLocalAngles( Angle( 0, 0, 45 ) )
    self.cd2_Guitar = guitar

    guitar.Think = function( ent ) if self:GetState() != "GuitarState" then ent:Remove() end end
end

function ENT:Panicked()
    if self.cd2_FirstPanic then coroutine.wait( 1 ) self.cd2_FirstPanic = false self:LookTo() end

    local areas = GetAwayNavmesh( self.cd2_Panickedlocation, 3000 )
    local pos
    
    for k, v in RandomPairs( areas ) do
        if IsValid( v ) then pos = v:GetRandomPoint() break end
    end
    
    self:StartPanicAnim()

    local result = self:MoveToPos( pos )

end

local songs = {
    "sound/crackdown2/music/guitars/cellsideoftown.mp3",
    "sound/crackdown2/music/guitars/giveustheanswer.mp3",
    "sound/crackdown2/music/guitars/therose.mp3"
}

function ENT:GuitarState()
    local endtime = CurTime() + rand( 150, 300 )

    local hidingspot = random( 1, 2 ) == 1 and self:FindSpot( "random", { type = "hiding", pos = self:GetPos(), radius = 2000, stepup = 10, stepdown = 10 } ) or self:GetRandomPos( 1000 ) 
    if !hidingspot then self:SetState( "Idle" ) return end

    net.Start( "cd2net_stopguitar" )
    net.Broadcast()
    
    self:MoveToPos( hidingspot )
    self:LookTo( self.cd2_NavArea:GetCenter(), 2 )

    self.cd2_holdtypetranslations[ "normal" ].idle = ACT_IDLE_SHOTGUN_RELAXED

    self:EquipGuitar()

    net.Start( "cd2net_playguitar" )
    net.WriteString( songs[ random( 3 ) ] )
    net.WriteEntity( self ) 
    net.Broadcast()

    while self:GetState() == "GuitarState" and CurTime() < endtime do
        coroutine.yield()
    end

    net.Start( "cd2net_stopguitar" )
    net.Broadcast()

    self.cd2_holdtypetranslations[ "normal" ].idle = ACT_IDLE
    if self:GetState() == "GuitarState" then self:SetState( "Idle" ) end
end

-- Returns if we can play the guitar
function ENT:CanPlayGuitar()
    for k, v in ipairs( ents.FindByClass( "cd2_civilian" ) ) do
        if v:GetState() == "GuitarState" then return false end
    end
    return true
end

function ENT:Idle() 
    self:EndPanicAnim()

    self:SetWalk( true )
    local pos = self:GetRandomPos() 
    self:MoveToPos( pos )
    self:SetWalk( false )

    if self.cd2_gender == "male" and random( 1, 15 ) == 1 and self:CanPlayGuitar() then
        self:SetState( "GuitarState" )
    end

end