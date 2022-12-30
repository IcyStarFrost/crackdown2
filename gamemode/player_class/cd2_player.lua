DEFINE_BASECLASS( "player_default" )

local black = Color( 0, 0, 0 )
local random = math.random
 
local PLAYER = {} 

PLAYER.DisplayName = "Agent"

-- These are the default movement variables. During gameplay the movement will change according to AgilitySkill
PLAYER.WalkSpeed = 200
PLAYER.RunSpeed  = 400
PLAYER.JumpPower = 400

-- Health. During gameplay these settings will change according to StrengthSkill
PLAYER.StartHealth = 100
PLAYER.StartArmor = 100
PLAYER.MaxHealth = 100
PLAYER.MaxArmor = 100
--

PLAYER.DropWeaponOnDie = false
PLAYER.TeammateNoCollide = false
PLAYER.AvoidPlayers = true
PLAYER.CanUseFlashlight = false

 
function PLAYER:Loadout()
end

function PLAYER:Death()

    -- Save all weapons and equipment for if we decide to regenerate and drop them from then
    if !game.SinglePlayer() then
        self.Player.cd2_deathweapons = {}
        self.Player.cd2_deathequipment = self.Player.cd2_Equipment
        local weps = self.Player:GetWeapons()
        for i = 1, #weps do 
            local wep = weps[ i ]
            if IsValid( wep ) then
                self.Player.cd2_deathweapons[ #self.Player.cd2_deathweapons + 1 ] = { wep:GetClass(), wep:Ammo1() }
            end
        end
    end

    net.Start( "cd2net_playerkilled" )
    net.Send( self.Player )
end

function PLAYER:Init()
    self.Player:SetCD2Team( "agency" )
end

function PLAYER:Spawn()
    local ply = self.Player

    ply:SetCanRevive( true )

    net.Start( "cd2net_playerrespawn" )
    net.Send( ply )

    net.Start( "cd2net_playerspawnlight" )
    net.WriteEntity( ply )
    net.Broadcast()

    ply:ScreenFade( SCREENFADE.IN, black, 2, 0.5 )

    -- Respawn trail things
    CD2CreateThread( function()
        if !IsValid( ply ) then return end

        for i = 1, 100 do
            if !IsValid( ply ) then return end

            local trailer = ents.Create( "cd2_respawntrail" )
            trailer:SetPos( ply:WorldSpaceCenter() + VectorRand( -150, 150 ) )
            trailer:SetPlayer( ply )
            trailer:Spawn()

            coroutine.wait( 0.01 )
        end
    
    end )

end

function PLAYER:SetupDataTables()

    self.Player:NetworkVar( "String", 0, "CD2Team" ) -- The team this player is in. Obviously mainly set to agency

    -- Skill Stats --
    -- These skills should be capped at 6
    self.Player:NetworkVar( "Int", 0, "AgilitySkill" )
    self.Player:NetworkVar( "Int", 1, "WeaponSkill" )
    self.Player:NetworkVar( "Int", 2, "StrengthSkill" )
    self.Player:NetworkVar( "Int", 3, "ExplosiveSkill" )
    self.Player:NetworkVar( "Int", 4, "DrivingSkill" )

    self.Player:NetworkVar( "Int", 5, "AgilityXP" )
    self.Player:NetworkVar( "Int", 6, "WeaponXP" )
    self.Player:NetworkVar( "Int", 7, "StrengthXP" )
    self.Player:NetworkVar( "Int", 8, "ExplosiveXP" )
    self.Player:NetworkVar( "Int", 9, "DrivingXP" )
    --

    self.Player:NetworkVar( "Int", 10, "SafeFallSpeed" ) -- The speed the player won't take damage from
    self.Player:NetworkVar( "Int", 11, "EquipmentCount" ) -- The amount of equipment the player can have
    self.Player:NetworkVar( "Int", 12, "MaxPickupWeight" ) -- The max weight the player can pick up
    self.Player:NetworkVar( "Int", 13, "MaxEquipmentCount" ) -- The max amount of a certain equipment a player can have
    self.Player:NetworkVar( "Int", 13, "MeleeDamage" ) -- The amount of melee damage the player can deal

    self.Player:NetworkVar( "Bool", 0, "IsRechargingShield" ) -- If the Player's shields are recharging
    self.Player:NetworkVar( "Bool", 1, "IsRegeningHealth" ) -- If the Player's health is regenerating
    self.Player:NetworkVar( "Bool", 2, "CanRevive" ) -- If the player can be revived

    self.Player:NetworkVar( "Float", 0, "NWHealth" ) -- Networked. Used for HUD and regen
    self.Player:NetworkVar( "Float", 1, "NWShields" ) -- Networked. Used for HUD and regen

    self.Player:SetMeleeDamage( 25 ) -- By default, players can only deal 25 damage with melee. This will change according to StrengthSkill
    self.Player:SetMaxPickupWeight( 200 ) -- By default, only pickup props with a mass of 200. This will change according to StrengthSkill
    self.Player:SetSafeFallSpeed( 600 ) -- By default, the safe falling speed is 600. This will change according to AgilitySkill


end
 
player_manager.RegisterClass( "cd2_player", PLAYER, "player_default" )