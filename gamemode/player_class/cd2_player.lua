DEFINE_BASECLASS( "player_default" )

local black = Color( 0, 0, 0 )
 
local PLAYER = {} 

PLAYER.DisplayName = "Agent"

PLAYER.WalkSpeed = 200
PLAYER.RunSpeed  = 400
PLAYER.JumpPower = 400

-- Health
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

    self.Player:NetworkVar( "String", 0, "CD2Team" )

    -- Skill Stats
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

    self.Player:NetworkVar( "Int", 10, "SafeFallHeight" )
    self.Player:NetworkVar( "Int", 11, "EquipmentCount" )
    self.Player:NetworkVar( "Int", 12, "MaxPickupWeight" )

    self.Player:NetworkVar( "Bool", 0, "IsRechargingShield" )
    self.Player:NetworkVar( "Bool", 1, "IsRegeningHealth" )
    self.Player:NetworkVar( "Bool", 2, "CanRevive" )

    self.Player:NetworkVar( "Float", 0, "NWHealth" )
    self.Player:NetworkVar( "Float", 1, "NWShields" )

    self.Player:SetMaxPickupWeight( 200 )


end
 
player_manager.RegisterClass( "cd2_player", PLAYER, "player_default" )