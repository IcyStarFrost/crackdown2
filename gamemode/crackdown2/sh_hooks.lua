local plycolor = Vector( 1, 1, 1 )
local clamp = math.Clamp
local LerpAngle = LerpAngle
local ipairs = ipairs
local Lerp = Lerp
local LerpVector = LerpVector
local abs = math.abs
local FrameTime = FrameTime
local Trace = util.TraceLine
local IsValid = IsValid
local player_GetAll = player.GetAll
local sound_Play = sound.Play
local max = math.max
local upper = string.upper
local util_Effect = util.Effect
local ents_FindInCone = ents.FindInCone
local random = math.random
local net = net


-- Set the player's class
hook.Add( "PlayerSpawn", "crackdown2_setplayerclass", function( ply )
    if !ply.cd2_firsttimespawn then ply.cd2_firsttimespawn = true return end
    player_manager.SetPlayerClass( ply, "cd2_player" )
    ply:SetPlayerColor( plycolor )
end )

hook.Add( "PlayerInitialSpawn", "crackdown2_setplayerclass", function( ply )
    player_manager.SetPlayerClass( ply, "cd2_spectator" )
    ply:SetPlayerColor( plycolor )

    local vecs = {}
    for k, v in ipairs( CD2GetPossibleSpawns() ) do vecs[ #vecs + 1 ] = { v:GetPos(), v:GetAngles() } end

    net.Start( "cd2net_sendspawnvectors" )
    net.WriteString( util.TableToJSON( vecs ) )
    net.Send( ply )
end )
--

hook.Add( "PlayerSelectSpawn", "crackdown2_selectnearestspawn", function( ply )
    if !ply:IsCD2Agent() then return end

    if ply.cd2_spawnatnearestspawn then
        local near = CD2GetClosestSpawn( ply )
        ply.cd2_spawnatnearestspawn = false
        return near
    end

end )


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

-- Remove Pickup notif
function GM:HUDItemPickedUp()
end

function GM:HUDAmmoPickedUp()
end

function GM:HUDWeaponPickedUp()
end
--

function GM:AllowPlayerPickup()
    return false
end

function GM:HUDDrawTargetID()
end

-- Disable default kill feed
function GM:DrawDeathNotice( x, y )
end

-- Disable ear ringing effect
function GM:OnDamagedByExplosion( ply, info )
end

function GM:GetFallDamage( ply, speed ) 
    if ply:IsCD2Agent() and speed < ply:GetSafeFallSpeed() then return 0 end
    return math.max( 0, math.ceil( 0.3318 * speed - 141.75 ) )
end

-- Shield and Health Regeneration
hook.Add( "Tick", "crackdown2_regeneration", function()
    local players = player_GetAll() 
    for i = 1, #players do
        local ply = players[ i ]

        if !ply:Alive() then ply.cd2_delayregens = CurTime() + 0.5 continue end
        if !ply:IsCD2Agent() or ( ply.cd2_delayregens and CurTime() < ply.cd2_delayregens ) then continue end

        if ( !ply.cd_NextRegenTime or CurTime() > ply.cd_NextRegenTime ) then
            if ply:GetNWShields() < ply:GetMaxArmor() and ( !ply.cd_NextRegen or CurTime() > ply.cd_NextRegen ) then
                if SERVER then
                    ply:SetArmor( ply:GetNWShields() + 1 )
                end
                ply:SetIsRechargingShield( true )
                if ply.cd2_cancallshieldhook then hook.Run( "CD2_OnPlayerShieldRegen", ply ) ply.cd2_cancallshieldhook = false end
                ply.cd_NextRegen = CurTime() + 0.05
            elseif ply:GetNWHealth() < ply:GetMaxHealth() and ( !ply.cd_NextRegen or CurTime() > ply.cd_NextRegen ) then
                ply:SetHealth( ply:GetNWHealth() + 1 )
                ply:SetIsRegeningHealth( true )
                if ply.cd2_cancallhealthhook then hook.Run( "CD2_OnPlayerHealthRegen", ply ) ply.cd2_cancallhealthhook = false end
                ply.cd_NextRegen = CurTime() + 0.05
            end
            
            if ply:GetNWShields() == ply:GetMaxArmor() then
                ply.cd2_cancallshieldhook = true
                ply:SetIsRechargingShield( false )
            end

            if ply:GetNWHealth() == ply:GetMaxHealth() then
                ply.cd2_cancallhealthhook = true
                ply:SetIsRegeningHealth( false )
            end

        end

    end
end )
---------


if SERVER then
    hook.Add( "Tick", "crackdown2_updateplayernw", function()
        local players = player_GetAll() 
        for i = 1, #players do
            local ply = players[ i ]
            if !ply:IsCD2Agent() then continue end
            ply:SetNWShields( ply:Armor() )
            ply:SetNWHealth( ply:Health() )
        end
    end )
end



hook.Add( "KeyPress", "crackdown2_equipmentuse", function( ply, key )
    if key == IN_GRENADE1 and ply:GetEquipmentCount() > 0 and ( !ply.cd2_grenadecooldown or CurTime() > ply.cd2_grenadecooldown ) then

        CD2CreateThread( function()

            ply:SetEquipmentCount( ply:GetEquipmentCount() - 1 )

            local tbl = scripted_ents.Get( CLIENT and CD2_DropEquipment or ply.cd2_Equipment )
            ply.cd2_grenadecooldown = CurTime() + tbl.Cooldown

            BroadcastLua( "Entity( " .. ply:EntIndex() .. " ):AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_GMOD_GESTURE_ITEM_THROW, true )" )
            coroutine.wait( 0.5 )

            ply:EmitSound( "crackdown2/weapons/grenadethrow.mp3", 60, 100, 1, CHAN_WEAPON )

            coroutine.wait( 0.3 )

            if SERVER then
                local pos = ply:GetEyeTrace().HitPos
                CD2ThrowEquipment( ply.cd2_Equipment , ply, pos )
            end

        end )
    end
end )

if SERVER then
    


    -- Jump sounds
    hook.Add( "KeyPress", "crackdown2_jump", function( ply, key ) 
        if !ply:IsCD2Agent() then return end
        if key == IN_JUMP and ply:IsOnGround() then ply:EmitSound( "crackdown2/ply/jump" .. random( 1, 4 ) .. ".wav", 60, 100, 0.2, CHAN_AUTO ) end
    end )

    -- Network all health so the target health bars are accurate
    local ents_GetAll = ents.GetAll
    local nextupdate = 0
    hook.Add( "Tick", "crackdown2_networkvars", function()
        if CurTime() < nextupdate then return end

        for k, v in ipairs( ents_GetAll() ) do
            v:SetNWFloat( "cd2_health", v:Health() )

            if IsValid( v:GetPhysicsObject() ) then
                v:SetNW2Int( "cd2_mass", v:GetPhysicsObject():GetMass() )
            end

        end

        nextupdate = CurTime() + 0.1
    end )

    local TraceHull = util.TraceHull
    local FindInBox = ents.FindInBox
    local hulltbl = {}
    -- Melee System
    hook.Add( "KeyPress", "crackdown2_meleesystem", function( ply, key )
        if !ply:IsCD2Agent() then return end

        local wep = ply:GetActiveWeapon()

        if IsValid( wep ) and !wep:GetIsReloading() and key == IN_ATTACK and ply:KeyDown( IN_USE ) and ( !ply.cd2_meleecooldown or CurTime() > ply.cd2_meleecooldown ) then
            
            if IsValid( ply.cd2_HeldObject ) then
                BroadcastLua( "Entity( " .. ply:EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE, true )" )
            else
                BroadcastLua( "Entity( " .. ply:EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST, true )" )
            end
            ply:EmitSound( "WeaponFrag.Throw", 80, 100, 1, CHAN_WEAPON )

            local start = ply:GetPos() + ply:GetForward() * 50 + Vector( 0, 0, 5 )
            local mins = Vector( -70, -70, 0 )
            local maxs = Vector( 70, 70, 53 )
            local entities = FindInBox( start + mins, start + maxs )

            if #entities > 0 then
                for i = 1, #entities do
                    local hitent = entities[ i ]
                    if !IsValid( hitent ) then continue end

                    local trace = ply:Trace( nil, hitent:WorldSpaceCenter() )

                    if hitent != ply and hitent != ply.cd2_HeldObject and ( trace.Entity == hitent or !trace.Hit ) then
                        hitent:EmitSound( "physics/flesh/flesh_impact_hard" .. random( 1, 6 ) .. ".wav")
                        local heldobjectphys = IsValid( ply.cd2_HeldObject ) and ply.cd2_HeldObject:GetPhysicsObject()
                        local add = IsValid( heldobjectphys ) and heldobjectphys:GetMass() / 10 or 0

                        local hitphys = hitent:GetPhysicsObject()
                        local force = hitent:IsCD2NPC() and 20000 or IsValid( hitphys ) and hitphys:GetMass() * 10 or 20000
                        local normal = ( hitent:WorldSpaceCenter() - ply:WorldSpaceCenter() ):GetNormalized()
                        
                        local info = DamageInfo()
                        info:SetAttacker( ply )
                        info:SetInflictor( wep )
                        info:SetDamage( 25 + add )
                        info:SetDamageType( DMG_CLUB )
                        info:SetDamageForce( normal * force )
                        hitent:TakeDamageInfo( info )
                    end
                end
            end
            
            ply.cd2_meleecooldown = CurTime() + 0.5
        end 

    end )



    hook.Add( "PostEntityTakeDamage", "crackdown2_fireexplosions", function( ent, info )
        if info:IsExplosionDamage() and ( ent:IsPlayer() or ent:IsCD2NPC() ) then
            ent:Ignite( 4 )
        end
    end )

end


-- Crackdown 2 Lockon system --
-- Client and server teamwork woooooo
local limitlockonsound = false
hook.Add( "Think", "crackdown2_lockon", function()

    if SERVER then

        local players = player_GetAll() 
        for i = 1, #players do
            local ply = players[ i ]
    
            if !ply:Alive() or !ply:IsCD2Agent() then continue end

            if ply:KeyDown( IN_ATTACK2 ) then

                local lockables = CD2FindInLockableTragets( ply )
                ply.cd2_lockontarget = IsValid( ply.cd2_lockontarget ) and ply:GetPos():DistToSqr( ply.cd2_lockontarget:GetPos() ) <= ( 2000 * 2000 ) and ply.cd2_lockontarget or IsValid( lockables[ 1 ] ) and ply:GetPos():DistToSqr( lockables[ 1 ]:GetPos() ) <= ( 2000 * 2000 ) and lockables[ 1 ] or nil

                if IsValid( ply.cd2_lockontarget ) then
                    ply:SetEyeAngles( ( ply.cd2_lockontarget:WorldSpaceCenter() - ply:EyePos() ):Angle() )
                end

            else
                ply.cd2_lockontarget = nil
            end

        end

    else
        local ply = LocalPlayer()

        if !IsValid( ply ) or !ply:IsCD2Agent() then return end

        local lockables = CD2FindInLockableTragets( ply )

        if ply:KeyDown( IN_ATTACK2 ) then
            ply.cd2_lockontarget = IsValid( ply.cd2_lockontarget ) and ply:GetPos():DistToSqr( ply.cd2_lockontarget:GetPos() ) <= ( 2000 * 2000 ) and ply.cd2_lockontarget or IsValid( lockables[ 1 ] ) and ply:GetPos():DistToSqr( lockables[ 1 ]:GetPos() ) <= ( 2000 * 2000 ) and lockables[ 1 ] or nil

            if IsValid( ply.cd2_lockontarget ) then 
                if !limitlockonsound then 
                    surface.PlaySound( "crackdown2/ply/lockon.mp3" ) 
                    limitlockonsound = true 
                end 
                local dir = ( ply.cd2_lockontarget:WorldSpaceCenter() - CD2_vieworigin ):Angle() 
                dir:Normalize()
                CD2_viewangles = dir
                ply:SetEyeAngles( ( ply.cd2_lockontarget:WorldSpaceCenter() - ply:EyePos() ):Angle() )
                CD2_viewlockedon = true
            else
                CD2_viewlockedon = false
            end
        else
            CD2_viewlockedon = false
            ply.cd2_lockontarget = nil
            limitlockonsound = false
        end

        if #lockables > 0 then
            CD2_lockon = true
        else
            CD2_lockon = false
        end

    end
end )
------
local actcommands = {
    "act group",
    "act forward",
    "act halt"
}

hook.Add( "Tick", "crackdown2_passiveactcommands", function()
    local players = player_GetAll() 
    for i = 1, #players do
        local ply = players[ i ]

        if !ply:Alive() or !ply:IsCD2Agent() then continue end
        
        ply.cd2_nextgesture = ply.cd2_nextgesture or CurTime() + random( 5, 60 )

        if CurTime() > ply.cd2_nextgesture then
            ply:ConCommand( actcommands[ random( 3 ) ])
            ply.cd2_nextgesture = CurTime() + random( 5, 60 )
        end

    end
end )


-- Reviving system --

if !game.SinglePlayer() and CLIENT then
    local input_LookupBinding = input.LookupBinding
    local input_GetKeyCode = input.GetKeyCode
    local input_GetKeyName = input.GetKeyName

    hook.Add( "Tick", "crackdown2_playerreviving", function()
        local players = player_GetAll() 
        for i = 1, #players do
            local ply = players[ i ]
    
            if ply:Alive() or !ply:IsCD2Agent() or ply == LocalPlayer() or !ply:GetCanRevive() then continue end

            local ragdoll = ply:GetRagdollEntity()

            if IsValid( ragdoll ) and LocalPlayer():GetPos():DistToSqr( ragdoll:GetPos() ) <= ( 70 * 70 ) then
                LocalPlayer().cd2_revivetarget = ragdoll

                if LocalPlayer():KeyDown( IN_USE ) then
                    LocalPlayer().cd2_revivetime = LocalPlayer().cd2_revivetime or CurTime() + 1

                    if CurTime() > LocalPlayer().cd2_revivetime then

                        net.Start( "cd2net_reviveplayer" )
                        net.WriteEntity( ply )
                        net.SendToServer()

                        LocalPlayer().cd2_revivetime = math.huge
                    end

                else
                    LocalPlayer().cd2_revivetime = nil
                end
                
            else
                LocalPlayer().cd2_revivetarget = nil
            end

        end
    end )

    hook.Add( "HUDPaint", "crackdown2_revivepaint", function()
        local targ = LocalPlayer().cd2_revivetarget
        if !IsValid( targ ) or !targ:GetRagdollOwner():GetCanRevive() then return end

        local usebind = input_LookupBinding( "+use" ) or "e"
        local code = input_GetKeyCode( usebind )
        local buttonname = input_GetKeyName( code )
        
        local screen = ( targ:GetPos() + Vector( 0, 0, 30 ) ):ToScreen()
        CD2DrawInputbar( screen.x, screen.y, upper( buttonname ), "Revive " .. targ:GetRagdollOwner():Name() )
    end )

end


-----

if CLIENT then
    local limit = false

    local function PlayShieldsOfflineSound() 
        local ply = LocalPlayer()

        sound.PlayFile( "sound/crackdown2/ply/shielddown.mp3", "noplay", function( snd, id, name ) 
            if id then print( id, name ) return end
    
            snd:SetVolume( 0.1 )
            snd:Play()
            snd:EnableLooping( true )
    
            hook.Add( "Think", "crackdown2_shieldofflinesoundhandler", function()
                if !IsValid( snd ) or snd:GetState() == GMOD_CHANNEL_STOPPED then hook.Remove( "Think", "crackdown2_shieldofflinesoundhandler" ) return end
                if !ply:Alive() or ply:GetNWShields() > 30 then hook.Remove( "Think", "crackdown2_shieldofflinesoundhandler" ) snd:Stop() return end
            end )
    
        end )

    end


    local lowhealthchannel
    -- Low health music
    hook.Add( "Tick", "crackdown2_healthcheck", function()
        local ply = LocalPlayer()

        if !IsValid( ply ) or !ply:IsCD2Agent() then return end
        
        if ply:Alive() and ply:GetNWHealth() < 70 and !limit then
            lowhealthchannel = CD2StartMusic( "sound/crackdown2/music/lowhealth.mp3", 5, true )
            ply:SetDSP( 30 )
            limit = true
        elseif ply:GetNWHealth() > 70 and limit then
            if IsValid( lowhealthchannel ) then lowhealthchannel:FadeOut() end
            ply:SetDSP( 1 )
            limit = false
        end
    end )

    -- Shield offline and low sounds
    local limitlow = false
    local limitoffline = false
    hook.Add( "Tick", "crackdown2_shieldoffline", function()
        local ply = LocalPlayer()

        if !IsValid( ply ) or !ply:IsCD2Agent() then return end

        if ply:GetNWShields() <= 30 and !limitlow then
            PlayShieldsOfflineSound() 
            limitlow = true
        elseif ply:GetNWShields() > 30 and limitlow then
            limitlow = false
        end

        if ply:GetNWShields() <= 0 and !limitoffline then
            sound.PlayFile( "sound/crackdown2/ply/shield_takedown.mp3", "noplay", function( snd, id ) if id then return end snd:SetVolume( 0.3 ) snd:Play() end )
            limitoffline = true
        elseif ply:GetNWShields() > 0 and limitoffline then
            limitoffline = false
        end

    end )

    -- Wind sounds for falling 
    hook.Add( "Tick", "crackdown2_fallsounds", function()
        local ply = LocalPlayer()
        if !IsValid( ply ) or !ply:IsCD2Agent() then return end
        local vel = ply:GetVelocity()[ 3 ]
    
        if vel < -400 or vel > 400 then 
            if !ply.cd2_fallsoundpatch then
                ply.cd2_fallsoundpatch = CreateSound( ply, "ambient/wind/wind_rooftop1.wav" )
                ply.cd2_fallsoundpatch:Play()
                ply.cd2_fallsoundpatch:ChangeVolume( 0 )
            end
            ply.cd2_fallsoundpatch:ChangeVolume( vel % 1000, 3 )
        else
            if ply.cd2_fallsoundpatch then ply.cd2_fallsoundpatch:ChangeVolume( 0, 1 ) if ply.cd2_fallsoundpatch:GetVolume() == 0 then ply.cd2_fallsoundpatch:Stop() end end
            ply.cd2_fallsoundpatch = nil
        end
        
    end )


    -- Connect messages --
    hook.Add( "PlayerConnect", "crackdown2_connectmessage", function( name )
        if game.SinglePlayer() then return end
        CD2SetTextBoxText( name .. " joined the game" )
    end )

    gameevent.Listen( "player_disconnect" )

    hook.Add( "player_disconnect", "crackdown2_disconnectmessage", function( data )
        if game.SinglePlayer() then return end
        CD2SetTextBoxText( data.name .. " left the game (" .. data.reason .. ")"  )
    end )


    -- Ambient music --
    local nexttrack = CurTime() + random( 90, 250 )
    local tracks = { "sound/crackdown2/music/ambient/agency.mp3", "sound/crackdown2/music/ambient/hope.mp3", "sound/crackdown2/music/ambient/ambient1.mp3", "sound/crackdown2/music/ambient/ambient2.mp3", "sound/crackdown2/music/ambient/ambient3.mp3", "sound/crackdown2/music/ambient/ambient4.mp3" }
    hook.Add( "Tick", "crackdown2_ambientmusic", function()
        if nexttrack and CurTime() > nexttrack then 
            nexttrack = nil

            CD2StartMusic( tracks[ random( #tracks ) ], 0, false, true, nil, nil, nil, nil, nil, function( chan )
                if !nexttrack then
                    nexttrack = CurTime() + chan:GetChannel():GetLength() + random( 90, 250 )
                end
            end )

        end
    end )

end



-- Regen Sounds
hook.Add( "CD2_OnPlayerShieldRegen", "crackdown2_onshieldregen", function( ply )
    if CLIENT and ply == LocalPlayer() then
        surface.PlaySound( "buttons/combine_button7.wav" )
    end
end )

hook.Add( "CD2_OnPlayerHealthRegen", "crackdown2_onhealthregen", function( ply )
    if CLIENT and ply == LocalPlayer() then
        surface.PlaySound( "buttons/combine_button5.wav" )
    end
end )
-------

-- Shield system
hook.Add( "EntityTakeDamage", "crackdown2_shieldsystem", function( ent, info ) 
    local attacker = info:GetAttacker()
    if attacker:IsCD2NPC() then info:SetDamage( info:GetDamage() / attacker.cd2_damagedivider ) end

    if !ent:IsPlayer() then return end

    local shields = ent:Armor()
    local damage = info:GetDamage()
    local shielddamage = ent:Armor() - damage
    local leftover = abs( shielddamage )

    if shields >= damage then
        ent:SetArmor( shields - damage )
        hook.Run( "PlayerHurt", ent, info:GetAttacker(), ent:Health(), damage )

        if info:IsExplosionDamage() then ent:Ignite( 4 ) end
        return true
    elseif shields > 0 then
        info:SetDamage( damage - shields )
        ent:SetArmor( 0 )
        ent:TakeDamageInfo( info )
        return true
    end

end )

-- Set the client's regen time
hook.Add( "PlayerHurt", "crackdown2_delayregen", function( ply, attacker, remaining, damagetaken )
    ply.cd_NextRegenTime = CurTime() + 6
    net.Start( "cd2net_playerhurt" )
    net.Send( ply )
end )


hook.Add( "PlayerCanPickupWeapon", "crackdown2_npcweapons", function( ply, wep )
    local wepowner = wep:GetOwner()

    if IsValid( wepowner ) and wepowner:IsCD2NPC() then
        return false
    end

end )

if SERVER then
    hook.Add( "OnPlayerHitGround", "crackdown2_landingdecals", function( ply, inwater, onfloater, vel )

        if vel >= 700 then
            net.Start( "cd2net_playerlandingdecal" )
            net.WriteVector( ply:WorldSpaceCenter() )
            net.WriteBool( vel >= 1000  )
            net.Broadcast()

            sound_Play( "crackdown2/ply/hardland" .. random( 1, 2 ) .. ".wav", ply:GetPos(), 65, 100, 1 )
        else
            net.Start( "cd2net_playersoftland" )
            net.WriteVector( ply:GetPos() )
            net.Broadcast()
        end

        sound_Play( "crackdown2/ply/defaultland" .. random( 1, 3 ) .. ".wav", ply:GetPos(), 65, 100, 1 )
    end )
end


local HUDBlock = {
    [ "CHudAmmo" ] = true,
    [ "CHudBattery" ] = true,
    [ "CHudHealth" ] = true,
    [ "CHudSecondaryAmmo" ] = true,
    [ "CHudWeapon" ] = true,
    [ "CHudZoom" ] = true,
    [ "CHudSuitPower" ] = true,
    [ "CHUDQuickInfo" ] = true,
    [ "CHudCrosshair" ] = true,
    [ "CHudDamageIndicator" ] = true,
    [ "CHudWeaponSelection" ] = true
}

hook.Add( "HUDShouldDraw", "crackdown2_hidehuds", function( name )
    if HUDBlock[ name ] then return false end
end )

local modify = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 1,
	[ "$pp_colour_mulr" ] = 0,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0
}

hook.Add( "RenderScreenspaceEffects", "crackdown2_lowhealthcolors", function()
    local ply = LocalPlayer()
    
    if !ply:IsCD2Agent() then return end

    if ply:Alive() and ply:GetNWHealth() < 70 then
        modify[ "$pp_colour_addr" ] = Lerp( 2 * FrameTime(), modify[ "$pp_colour_addr" ], 0.15 )
    else
        modify[ "$pp_colour_addr" ] = Lerp( 2 * FrameTime(), modify[ "$pp_colour_addr" ], 0 )
    end

    if !ply:Alive() and !CD2_InSpawnPointMenu then
        DrawBokehDOF( 5, 0, 1 )
    end
    
    DrawColorModify( modify )
end )

hook.Add( "NeedsDepthPass", "crackdown2_bokehdepthpass", function()
    return !LocalPlayer():Alive()
end )


-- View stuff. This took way too long to figure out --


local calctable = {} -- Recycled table
CD2_viewangles = Angle() -- Our view angles
local plyangle -- The angle our player is facing
CD2_viewlockedon = false
local lockonoffset = Vector()
local zerovec = Vector()
local viewtrace = {}
local fieldofview

function GM:CalcView( ply, origin, angles, fov, znear, zfar )

    if CD2_ViewOverride then
        return CD2_ViewOverride( ply, origin, angles, fov, znear, zfar )
    end

    fieldofview = fieldofview or fov
    if !ply:IsCD2Agent() then return end

    if ply:Alive() then

        viewtrace.start = ( origin + Vector( 0, 0, 18 ) ) + lockonoffset
        viewtrace.endpos = ( ( origin + Vector( 0, 0, 18 ) ) - CD2_viewangles:Forward() * 130 ) + lockonoffset
        viewtrace.filter = ply
        local result = Trace( viewtrace )
        local pos = result.HitPos - result.Normal * 8

        if CD2_viewlockedon then
            lockonoffset = LerpVector( 20 * FrameTime(), lockonoffset, ( CD2_viewangles:Right() * 30 - Vector( 0, 0, 10 ) ) )
            fieldofview = Lerp( 20 * FrameTime(), fieldofview, 60 )
        else
            lockonoffset = LerpVector( 20 * FrameTime(), lockonoffset, zerovec )
            fieldofview = Lerp( 20 * FrameTime(), fieldofview, fov )
        end

        CD2_vieworigin = pos
        calctable.origin = pos
        calctable.angles = CD2_viewangles
        calctable.fov = fieldofview
        calctable.znear = znear
        calctable.zfar = zfar
        calctable.drawviewer  = true

        return calctable

    else
        local ragdoll = ply:GetRagdollEntity()

        if !IsValid( ragdoll ) then return end

        local ang = Angle( 0, SysTime() * 2, 0 )
        viewtrace.start = ragdoll:GetPos() + Vector( 0, 0, 10 )
        viewtrace.endpos = ( ragdoll:GetPos() + Vector( 0, 0, 10 ) ) - ang:Forward() * 100
        local result = Trace( viewtrace )

        fieldofview = Lerp( 5 * FrameTime(), fieldofview, 50 )

        local pos = result.HitPos - result.Normal * 8

        calctable.origin = pos
        calctable.angles = ang
        calctable.fov = fieldofview
        calctable.znear = znear
        calctable.zfar = zfar
        calctable.drawviewer  = true

        return calctable

    end
end


local lookatcursorTime = 0
local switchcooldown = 0
function GM:CreateMove( cmd )
    local self = LocalPlayer()

    if !self:IsCD2Agent() then return end

    local vec = Vector( cmd:GetForwardMove(), -cmd:GetSideMove(), 0 )

    if !plyangle then
        CD2_viewangles = self:EyeAngles()
        plyangle = CD2_viewangles * 1
    end

    vec:Rotate( Angle( CD2_viewangles[ 1 ], CD2_viewangles[ 2 ], CD2_viewangles[ 3 ] ) )


    CD2_viewangles[ 2 ] = CD2_viewangles[ 2 ] - cmd:GetMouseX() * 0.02
    
    CD2_viewangles[ 1 ] = clamp( CD2_viewangles[ 1 ] +  cmd:GetMouseY() * 0.02, -90, 90 )

    plyangle[ 1 ] = CD2_viewangles[ 1 ]


    if cmd:GetMouseWheel() != 0 and CurTime() > switchcooldown then 
        for k, wep in ipairs( self:GetWeapons() ) do
            if wep != self:GetActiveWeapon() then cmd:SelectWeapon( wep ) break end
        end
        switchcooldown = CurTime() + 0.2
    end
    if cmd:KeyDown( IN_ATTACK ) and !cmd:KeyDown( IN_USE ) or cmd:KeyDown( IN_ATTACK2 ) or cmd:KeyDown( IN_GRENADE1 ) then lookatcursorTime = CurTime() + 1 end
    
    if CurTime() < lookatcursorTime then plyangle = CD2_viewangles * 1 cmd:SetViewAngles( CD2_viewangles ) return end

    if cmd:GetForwardMove() != 0 or cmd:GetSideMove() != 0 then
        plyangle = vec:Angle()
        cmd:SetViewAngles( LerpAngle( FrameTime() * 20, cmd:GetViewAngles(), plyangle ) )
        cmd:SetForwardMove( self:GetRunSpeed() )
        cmd:SetSideMove( 0 )
    else
        cmd:SetViewAngles( plyangle )
    end
end