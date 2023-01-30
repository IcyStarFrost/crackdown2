DEFINE_BASECLASS( "player_default" )

local black = Color( 0, 0, 0 )
 
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
        self.Player.cd2_deathequipment = self.Player:GetEquipment()
        local weps = self.Player:GetWeapons()
        for i = 1, #weps do 
            local wep = weps[ i ]
            if IsValid( wep ) then
                self.Player.cd2_deathweapons[ #self.Player.cd2_deathweapons + 1 ] = { wep:GetClass(), wep:Ammo1() }
            end
        end
        self.Player:StripAmmo()
    end

    

    net.Start( "cd2net_playerkilled" )
    net.Send( self.Player )
end





function PLAYER:Init()
    self.Player:SetCanUseLockon( true )
    self.Player:SetCanUseMelee( true )
    self.Player:SetCD2Team( "agency" )
    self.Player:SetEquipment( "cd2_grenade" )
    self.Player:SetMaxEquipmentCount( 8 )
    self.Player:SetMeleeDamage( 25 ) -- By default, players can only deal 25 damage with melee. This will change according to StrengthSkill
    self.Player:SetMaxPickupWeight( 200 ) -- By default, only pickup props with a mass of 200. This will change according to StrengthSkill
    self.Player:SetSafeFallSpeed( 40 ) -- By default, the safe falling speed is 600. This will change according to AgilitySkill

    self.Player:SetAgilitySkill( 1 )
    self.Player:SetWeaponSkill( 1 )
    self.Player:SetStrengthSkill( 1 )
    self.Player:SetExplosiveSkill( 1 )
    self.Player:SetDrivingSkill( 1 )

    self.Player:SetAgilityXP( 0 )
    self.Player:SetWeaponXP( 0 )
    self.Player:SetStrengthXP( 0 )
    self.Player:SetExplosiveXP( 0 )
    self.Player:SetDrivingXP( 0 )

    self.Player:SetNWShields( 100 )
    self.Player:SetNWHealth( 100 )

    if CLIENT then

        -- XP --

        self.Player:NetworkVarNotify( "AgilityXP", function( ply, name, old, new )
            if KeysToTheCity() then return end
            CD2FILESYSTEM:WritePlayerData( "cd2_skillxp_Agility", new )
        end )

        self.Player:NetworkVarNotify( "WeaponXP", function( ply, name, old, new )
            if KeysToTheCity() then return end
            CD2FILESYSTEM:WritePlayerData( "cd2_skillxp_Weapon", new )
        end )

        self.Player:NetworkVarNotify( "StrengthXP", function( ply, name, old, new )
            if KeysToTheCity() then return end
            CD2FILESYSTEM:WritePlayerData( "cd2_skillxp_Strength", new )
        end )

        self.Player:NetworkVarNotify( "ExplosiveXP", function( ply, name, old, new )
            if KeysToTheCity() then return end
            CD2FILESYSTEM:WritePlayerData( "cd2_skillxp_Explosive", new )
        end )


        -- Levels --

        self.Player:NetworkVarNotify( "AgilitySkill", function( ply, name, old, new )
            if KeysToTheCity() then return end
            CD2FILESYSTEM:WritePlayerData( "cd2_skill_Agility", new )
        end )

        self.Player:NetworkVarNotify( "WeaponSkill", function( ply, name, old, new )
            if KeysToTheCity() then return end
            CD2FILESYSTEM:WritePlayerData( "cd2_skill_Weapon", new )
        end )

        self.Player:NetworkVarNotify( "StrengthSkill", function( ply, name, old, new )
            if KeysToTheCity() then return end
            CD2FILESYSTEM:WritePlayerData( "cd2_skill_Strength", new )
        end )

        self.Player:NetworkVarNotify( "ExplosiveSkill", function( ply, name, old, new )
            if KeysToTheCity() then return end
            CD2FILESYSTEM:WritePlayerData( "cd2_skill_Explosive", new )
        end )
    end
end

function PLAYER:Spawn()
    local ply = self.Player

    ply:SetCanRevive( true )


    if !IsValid( ply.cd2_holsteredweapon ) then 

        local mdl

        for k, v in ipairs( ply:GetWeapons() ) do
            if v != ply:GetActiveWeapon() then mdl = v:GetModel() break end
        end

        ply.cd2_holsteredweapon = ents.Create( "base_anim" )
        ply.cd2_holsteredweapon:SetNoDraw( true )
        ply.cd2_holsteredweapon:SetModel( mdl or "" )
        ply.cd2_holsteredweapon:SetPos( ply:GetPos() )
        ply.cd2_holsteredweapon:SetAngles( ply:GetAngles() )
        ply.cd2_holsteredweapon:Spawn()

        local mins = ply.cd2_holsteredweapon:GetModelBounds()
        ply.cd2_holsteredweapon:FollowBone( ply, ply:LookupBone( "ValveBiped.Bip01_Spine2" ) )
        ply.cd2_holsteredweapon:SetLocalPos( Vector( -10, -9, 0 ) - mins / 2 ) 
        ply.cd2_holsteredweapon:SetLocalAngles( Angle( 40, 0, 0 ) )

        ply.cd2_holsteredweapon.Think = function( entself ) if entself:GetModel() != "models/error.mdl" then entself:SetNoDraw( !ply:Alive() and true or ply:GetNoDraw() ) end end

        if mdl then ply.cd2_holsteredweapon:SetNoDraw( false ) end
    end


    if ply.cd2_revived then
        ply.cd2_revived = false
        net.Start( "cd2net_playerrespawn_revive" )
        net.Send( ply )
    else
        net.Start( "cd2net_playerrespawn" )
        net.Send( ply )
    end

    net.Start( "cd2net_playerspawnlight" )
    net.WriteEntity( ply )
    net.Broadcast()

    ply:ScreenFade( SCREENFADE.IN, black, 2, 0.5 )

    ply:BuildSkills()

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
    self.Player:NetworkVar( "String", 1, "Equipment" )

    self.Player:NetworkVar( "Entity", 0, "Ragdoll" )

    -- Skill Stats --
    -- These skills should be capped at 6
    self.Player:NetworkVar( "Int", 0, "AgilitySkill" )
    self.Player:NetworkVar( "Int", 1, "WeaponSkill" )
    self.Player:NetworkVar( "Int", 2, "StrengthSkill" )
    self.Player:NetworkVar( "Int", 3, "ExplosiveSkill" )
    self.Player:NetworkVar( "Int", 4, "DrivingSkill" )

    self.Player:NetworkVar( "Float", 2, "AgilityXP" )
    self.Player:NetworkVar( "Float", 3, "WeaponXP" )
    self.Player:NetworkVar( "Float", 4, "StrengthXP" )
    self.Player:NetworkVar( "Float", 5, "ExplosiveXP" )
    self.Player:NetworkVar( "Float", 6, "DrivingXP" )
    --

    self.Player:NetworkVar( "Int", 5, "SafeFallSpeed" ) -- The speed the player won't take damage from
    self.Player:NetworkVar( "Int", 6, "EquipmentCount" ) -- The amount of equipment the player can have
    self.Player:NetworkVar( "Int", 7, "MaxPickupWeight" ) -- The max weight the player can pick up
    self.Player:NetworkVar( "Int", 8, "MaxEquipmentCount" ) -- The max amount of a certain equipment a player can have
    self.Player:NetworkVar( "Int", 9, "MeleeDamage" ) -- The amount of melee damage the player can deal

    self.Player:NetworkVar( "Bool", 0, "IsRechargingShield" ) -- If the Player's shields are recharging
    self.Player:NetworkVar( "Bool", 1, "IsRegeningHealth" ) -- If the Player's health is regenerating
    self.Player:NetworkVar( "Bool", 2, "CanRevive" ) -- If the player can be revived
    self.Player:NetworkVar( "Bool", 3, "IsStunned" ) -- If the player is stunned
    self.Player:NetworkVar( "Bool", 4, "CanUseLockon" ) -- if this player can lock onto things
    self.Player:NetworkVar( "Bool", 5, "CanUseMelee" ) -- If this player can melee

    self.Player:NetworkVar( "Float", 0, "NWHealth" ) -- Networked. Used for HUD and regen
    self.Player:NetworkVar( "Float", 1, "NWShields" ) -- Networked. Used for HUD and regen
    self.Player:NetworkVar( "Float", 7, "LockonSpreadDecay" ) -- This will increase spread but will decrease down to the weapon's set lock on spread

end

player_manager.RegisterClass( "cd2_player", PLAYER, "player_default" )