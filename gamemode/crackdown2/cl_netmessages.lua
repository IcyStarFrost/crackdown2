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

net.Receive( "cd2net_playerinitialspawn", function()
    local delay = SysTime() + 6 
    CD2CreateThread( function()
        local clip = CD2BeginIntroVideo()

        while clip:isPlaying() or SysTime() < delay do
            coroutine.yield()
        end

        CD2OpenSpawnPointMenu()
        
        CD2StartMusic( "sound/crackdown2/music/mainmusic.mp3", 500, true, false, nil, nil, nil, nil, nil, function( CD2Musicchannel ) 
            if player_manager.GetPlayerClass( LocalPlayer() ) == "cd2_player" then CD2Musicchannel:FadeOut() end
        end )
    end )
end )


net.Receive( "cd2net_playguitar", function()
    local path = net.ReadString()
    local entity = net.ReadEntity()
    if !IsValid( entity ) then return end
    if IsValid( CD2_GuitarPlayer ) then CD2_GuitarPlayer:FadeOut() end

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

local energy = Material( "crackdown2/effects/energy.png" )
net.Receive( "cd2net_playerlevelupeffect", function() 
    local ply = net.ReadEntity()
    if !IsValid( ply ) then return end

    CD2StartMusic( "sound/crackdown2/music/levelup.mp3", 4, false, true )
    ply:EmitSound( "crackdown2/ply/spawnenergy.mp3", 70, 100, 1, CHAN_AUTO )

    CD2CreateThread( function()

        coroutine.wait( 1 )

        local particle = ParticleEmitter( ply:GetPos() )
        for i = 1, 150 do
            
            local part = particle:Add( energy, ply:GetPos() )
    
            if part then
                part:SetStartSize( 20 )
                part:SetEndSize( 20 ) 
                part:SetStartAlpha( 255 )
                part:SetEndAlpha( 0 )
    
                part:SetColor( 255, 255, 255 )
                part:SetLighting( false )
                part:SetCollide( false )
    
                part:SetDieTime( 2 )
                part:SetGravity( Vector() )
                part:SetAirResistance( 200 )
                part:SetVelocity( Vector( math.sin( i ) * 1000, math.cos( i ) * 1000, 0 ) )
                part:SetAngleVelocity( AngleRand( -1, 1 ) )
            end
    
        end
    
        particle:Finish()

    end )

    CD2CreateThread( function()

        coroutine.wait( 1 )


        local particle = ParticleEmitter( ply:GetPos() )
        for i = 1, 400 do
            
            local index = random( ply:GetBoneCount() )
            local pos = ply:GetBonePosition( index )
            if pos == ply:GetPos() then
                local matrix = ply:GetBoneMatrix( index )
                if !matrix then pos = ply:WorldSpaceCenter() else pos = matrix:GetTranslation() end
            end
            pos = pos or ply:WorldSpaceCenter()

            local part = particle:Add( energy, pos )
    
            if part then
                part:SetStartSize( 6 )
                part:SetEndSize( 6 ) 
                part:SetStartAlpha( 255 )
                part:SetEndAlpha( 0 )
    
                part:SetColor( 255, 255, 255 )
                part:SetLighting( false )
                part:SetCollide( false )
    
                part:SetDieTime( 0.2 )
                part:SetGravity( Vector() )
                part:SetAirResistance( 200 )
                part:SetVelocity( Vector() )
                part:SetAngleVelocity( AngleRand( -4, 4 ) )
            end
    
            coroutine.wait( 0.01 )
        end
    
        particle:Finish()

    end )
end )