local ceil = math.ceil
local max = math.max



--[[ models/player/combine_soldier.mdl
models/player/combine_super_soldier.mdl
models/player/soldier_stripped.mdl ]]

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

function GM:PlayerCanHearPlayersVoice( listener, talker )
    return player_manager.GetPlayerClass( listener ) != "cd2_spectator"
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
    return max( 0, ceil( 0.2918 * speed - 141.75 ) - ply:GetSafeFallSpeed() )
end

local explosivemodels = {
    [ "models/props_c17/oildrum001_explosive.mdl" ] = 1,
    [ "models/props_junk/gascan001a.mdl" ] = 0.6
}

if SERVER then
hook.Add( "OnEntityCreated", "crackdown2_explosivepropeffects", function( ent )
    timer.Simple( 0, function()
        if !IsValid( ent ) or explosivemodels[ ent:GetModel() ] == nil then return end
        ent:SetNW2Bool( "cd2_alwayslockon", true )
        ent:CallOnRemove( "explosiveeffect", function()
            net.Start( "cd2net_explosion" )
            net.WriteVector( ent:GetPos() )
            net.WriteFloat( explosivemodels[ ent:GetModel() ] )
            net.Broadcast()
        end )
    end )
end )

end