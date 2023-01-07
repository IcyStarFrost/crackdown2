DEFINE_BASECLASS( "player_default" )

local black = Color( 0, 0, 0 )
 
local PLAYER = {} 

PLAYER.DisplayName = "Spectator"

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

function PLAYER:Spawn()
    self.Player:Spectate( OBS_MODE_ROAMING )

    net.Start( "cd2net_playerinitialspawn" )
    net.WriteBool( navmesh.IsLoaded() )
    net.Send( self.Player )
    
end

function PLAYER:SetupDataTables()
end
 
player_manager.RegisterClass( "cd2_spectator", PLAYER, "player_default" )