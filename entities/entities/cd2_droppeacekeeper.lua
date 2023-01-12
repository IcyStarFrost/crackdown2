AddCSLuaFile()

ENT.Base = "cd2_combathumanbase"
ENT.PrintName = "Drop PeaceKeeper"

if CLIENT then language.Add( "cd2_droppeacekeeper", "Drop PeaceKeeper" ) end

ENT.cd2_Health = 150 -- The health the NPC has
ENT.cd2_Team = "agency" -- The Team the NPC will be in. It will attack anything that isn't on its team
ENT.cd2_SightDistance = 2000 -- How far this NPC can see
ENT.cd2_Weapon = "cd2_assaultrifle" -- The weapon this NPC will have
ENT.cd2_Equipment = "cd2_grenade" -- The equipment this npc can use
ENT.cd2_RunSpeed = 200 -- Run speed
ENT.cd2_WalkSpeed = 100 -- Walk speed
ENT.cd2_CrouchSpeed = 80 -- Crouch speed
ENT.cd2_damagedivider = 3


function ENT:ModelGet()
    return "models/player/combine_soldier.mdl"
end

local random = math.random
local rand = math.Rand
function ENT:MainThink2()
    if self:CanSpeak() and IsValid( self:GetEnemy() ) then
        self:PlayVoiceSound( "crackdown2/vo/peacekeeper/combat" .. random( 1, 49 ) .. ".mp3", rand( 5, 15 ) )
    end
end