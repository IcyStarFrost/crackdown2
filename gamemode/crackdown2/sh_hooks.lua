local ceil = math.ceil
local max = math.max


-- Set playermodels
function GM:PlayerSetModel( ply )
    ply:SetModel( "models/player/combine_super_soldier.mdl" )
end

-- Prevent spawn so the Drop Menu is the way of spawning
function GM:PlayerDeathThink() 
    return false
end

function GM:CanPlayerSuicide( ply ) 
    return player_manager.GetPlayerClass( ply ) == "cd2_player"
end

-- Mute death sound
function GM:PlayerDeathSound( ply ) 
    return true
end

-- Remove Pickup notifs
function GM:HUDItemPickedUp()
end

function GM:HUDAmmoPickedUp()
end

function GM:HUDWeaponPickedUp()
end
--

-- Prevent default Source pickup system
function GM:AllowPlayerPickup()
    return false
end

-- Disable default player name display
function GM:HUDDrawTargetID()
end

-- Disable default kill feed
function GM:DrawDeathNotice( x, y )
end

-- Disable ear ringing effect
function GM:OnDamagedByExplosion( ply, info )
end

-- Basic fall damage
function GM:GetFallDamage( ply, speed ) 
    if ply:IsCD2Agent() and speed < ply:GetSafeFallSpeed() or ply.cd2_IsUsingGroundStrike and speed < ( ply:GetSafeFallSpeed() * 1.5 ) then return 0 end
    return max( 0, ceil( 0.3318 * speed - 141.75 ) )
end

