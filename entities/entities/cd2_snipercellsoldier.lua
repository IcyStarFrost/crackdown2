AddCSLuaFile()

ENT.Base = "cd2_combathumanbase"
ENT.PrintName = "Sniper Cell Soldier"

if CLIENT then language.Add( "cd2_snipercellsoldier", "Sniper Cell Soldier" ) end

ENT.cd2_Health = 100 -- The health the NPC has
ENT.cd2_Team = "cell" -- The Team the NPC will be in. It will attack anything that isn't on its team
ENT.cd2_SightDistance = 4000 -- How far this NPC can see
ENT.cd2_Weapon = "cd2_sniper" -- The weapon this NPC will have
ENT.cd2_Equipment = "cd2_shrapnelgrenade" -- The equipment this npc can use
ENT.cd2_RunSpeed = 200 -- Run speed
ENT.cd2_WalkSpeed = 100 -- Walk speed
ENT.cd2_CrouchSpeed = 80 -- Crouch speed
ENT.cd2_damagedivider = 1
ENT.cd2_spreadoverride = 0.01
ENT.cd2_maxskillorbs = 7

local random = math.random
local rand = math.Rand
local IsValid = IsValid
function ENT:ModelGet()
    return "models/player/group03/male_0" .. random( 1, 9 ) .. ".mdl"
end

function ENT:MainThink2()
    if self:CanSpeak() and IsValid( self:GetEnemy() ) then
        self:PlayVoiceSound( "crackdown2/vo/cell/male2/idle" .. random( 1, 4 ) .. ".mp3", rand( 5, 15 ) )
    end
end