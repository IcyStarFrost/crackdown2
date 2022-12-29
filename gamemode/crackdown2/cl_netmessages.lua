local Lerp = Lerp
local Trace = util.TraceLine
local random = math.random

-- Setting a variable clientside
net.Receive( "cd2net_playerhurt", function()
    LocalPlayer().cd_NextRegenTime = CurTime() + 8
end )

local volume = 1
local fadeout = 1

-- Death music
net.Receive( "cd2net_playerkilled", function()
    local time = SysTime() + 0.5 -- Have to do this small delay or else the music will fade out instantly 
    CD2StartMusic( "sound/crackdown2/music/playerdead.mp3", 6, true, false, nil, nil, nil, nil, nil, function( channel )
        if LocalPlayer():Alive() and SysTime() > time then channel:FadeOut() end
    end )

    surface.PlaySound( "crackdown2/ply/die.mp3" )

end )


net.Receive( "cd2net_playerspawnlight", function() 
    local ply = net.ReadEntity()
    if !IsValid( ply ) then return end 
    local lightend = SysTime() + 2

    ply:EmitSound( "crackdown2/ply/spawnenergy.mp3", 70, 100, 1, CHAN_AUTO )

    hook.Add( "Think", "crackdown2_spawnlight", function()
        if SysTime() > lightend then hook.Remove( "Think", "crackdown2_spawnlight" ) return end
        local dlight = DynamicLight( ply:EntIndex() )

        if dlight then
            dlight.pos = ply:WorldSpaceCenter()
            dlight.r = 255
            dlight.g = 255
            dlight.b = 255
            dlight.brightness = 2
            dlight.Decay = 1000
            dlight.Size = 500
            dlight.style = 6
            dlight.DieTime = CurTime() + 1
        end
    end )

end )

-- Respawn music
net.Receive( "cd2net_playerrespawn", function()
    
    
    CD2StartMusic( "sound/crackdown2/music/playerspawn.mp3", 1, false, true )

end )

local util_DecalEx = util.DecalEx
local render_GetSurfaceColor = render.GetSurfaceColor
local landingtbl = {}
net.Receive( "cd2net_playerlandingdecal", function() 
    local pos = net.ReadVector()
    local bigfall = net.ReadBool()
    local mat = Material( "decals/rollermine_crater.vtf" )

    landingtbl.start = pos
    landingtbl.endpos = pos - Vector( 0, 0, 10000 )
    landingtbl.mask = MASK_SOLID_BRUSHONLY
    landingtbl.collisiongroup = COLLISION_GROUP_WORLD

    local result = Trace( landingtbl )
    local particle = ParticleEmitter( result.HitPos + Vector( 0, 0, 3) )
    local num = bigfall and 400 or 200
    for i = 1, 30 do
        
        local part = particle:Add( "particle/SmokeStack", result.HitPos + Vector( 0, 0, 3) )

        if part then
            part:SetStartSize( 20 )
            part:SetEndSize( 30 ) 
            part:SetStartAlpha( 255 )
            part:SetEndAlpha( 0 )

            part:SetColor( 100, 100, 100 )
            part:SetLighting( true )
            part:SetCollide( true )

            part:SetDieTime( 3 )
            part:SetGravity( Vector( 0, 0, -80 ) )
            part:SetAirResistance( 100 )
            part:SetVelocity( Vector( random( -num, num ), random( -num, num ), 0 ) )
            part:SetAngleVelocity( AngleRand( -1, 1 ) )
        end

    end

    particle:Finish()

    util_DecalEx( mat, Entity( 0 ), result.HitPos, result.HitNormal, color_white, bigfall and 2 or 1, bigfall and 2 or 1 )
end )


net.Receive( "cd2net_playersoftland", function()
    local pos = net.ReadVector()

    local particle = ParticleEmitter( pos )
    for i = 1, 20 do
        
        local part = particle:Add( "particle/SmokeStack", pos )

        if part then
            part:SetStartSize( 5 )
            part:SetEndSize( 10 ) 
            part:SetStartAlpha( 255 )
            part:SetEndAlpha( 0 )

            part:SetColor( 100, 100, 100 )
            part:SetLighting( true )
            part:SetCollide( true )

            part:SetDieTime( 2 )
            part:SetGravity( Vector( 0, 0, -80 ) )
            part:SetAirResistance( 200 )
            part:SetVelocity( Vector( random( -200, 200 ), random( -200, 200 ), 0 ) )
            part:SetAngleVelocity( AngleRand( -1, 1 ) )
        end

    end

    particle:Finish()

end )

net.Receive( "cd2net_opendropmenu", function() 
    CD2OpenDropMenu()
end )

net.Receive( "cd2net_openspawnpointmenu", function() 
    CD2OpenSpawnPointMenu()
end )

net.Receive( "cd2net_playmainmenumusic", function()
    CD2StartMusic( "sound/crackdown2/music/mainmusic.mp3", 500, true, false, nil, nil, nil, nil, nil, function( CD2Musicchannel ) 
        if player_manager.GetPlayerClass( LocalPlayer() ) == "cd2_player" then CD2Musicchannel:FadeOut() end
    end )
end )

net.Receive( "cd2net_sendspawnvectors", function()
    local json = net.ReadString()
    CD2_SpawnPoints = util.JSONToTable( json )
end )


net.Receive( "cd2net_playguitar", function()
    local path = net.ReadString()
    local entity = net.ReadEntity()
    if !IsValid( entity ) then return end
    local delay = SysTime() + 2

    CD2_GuitarPlayer = CD2StartMusic( path, 1, true, false, nil, true, nil, nil, entity )
end )

net.Receive( "cd2net_stopguitar", function()
    if IsValid( CD2_GuitarPlayer ) then
        CD2_GuitarPlayer:FadeOut()
    end
end )

net.Receive( "cd2net_pingsounds", function()
    local times = net.ReadUInt( 4 )

    CD2CreateThread( function()
        for i = 1, times do
            surface.PlaySound( "crackdown2/ui/ping.mp3" )
            coroutine.wait( 0.6 )
        end
    end )

end )

net.Receive( "cd2net_sendtext", function()
    local json = net.ReadString()
    local args = util.JSONToTable( json )
    chat.AddText( unpack( args ) )
end )

net.Receive( "cd2net_sendtextboxmessage", function()
    CD2SetTextBoxText( net.ReadString() )
end )
