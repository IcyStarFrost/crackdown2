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

function GM:PlayerStartVoice()

end

local explosivemodels = {
    [ "models/props_c17/oildrum001_explosive.mdl" ] = 1,
    [ "models/props_junk/gascan001a.mdl" ] = 0.6
}

hook.Add( "CreateTeams", "crackdown2_createteams", function()
    team.SetUp( 1, "Agents", Color( 0, 140, 255), true )
end )


if SERVER then
    hook.Add( "OnEntityCreated", "crackdown2_explosivepropeffects", function( ent )
        timer.Simple( 0, function()
            if !IsValid( ent ) or explosivemodels[ ent:GetModel() ] == nil then return end
            ent:SetNW2Bool( "cd2_alwayslockon", true )
            ent:CallOnRemove( "explosiveeffect", function()
                sound.Play( "crackdown2/ambient/explosivebarrel.mp3", ent:GetPos(), 80, 100, 1 )
                net.Start( "cd2net_explosion" )
                net.WriteVector( ent:GetPos() )
                net.WriteFloat( explosivemodels[ ent:GetModel() ] )
                net.Broadcast()
            end )
        end )
    end )

    hook.Add( "PostCleanupMap", "crackdown2_regenmap", function()

        local hooktbl = hook.GetTable()
        local powernetworkhooks = hooktbl.CD2_PowerNetworkComplete

        if powernetworkhooks then
            for k, v in pairs( powernetworkhooks ) do
                hook.Remove( "CD2_PowerNetworkComplete", k )
            end
        end

        CD2GenerateMapData( true )

        for k, ply in ipairs( player.GetAll() ) do
            timer.Simple( 0.01, function()
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
            end )
        end 
    end )

end