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

    CD2_DrawBlackbars = true
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

net.Receive( "cd2net_setplayerangle", function()
    CD2_plyangle = net.ReadAngle()
end )

-- Respawn music
net.Receive( "cd2net_playerrespawn", function()
    
    CD2_DrawBlackbars = false 
     CD2StartMusic( "sound/crackdown2/music/playerspawn.mp3", 2, false, true )

end )

net.Receive( "cd2net_playerrespawn_revive", function()
    
    CD2_DrawBlackbars = false 
    CD2StartMusic( "sound/crackdown2/music/revive.mp3", 2, false, true )

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

    if !result then return end

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
    local isresupply = net.ReadBool()
    CD2OpenDropMenu( isresupply )
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

net.Receive( "cd2net_playdirectorsound", function()
    local path = net.ReadString()
    sound.PlayFile( path, "noplay", function( snd, id, name ) snd:SetVolume( 10 ) snd:Play() end )
end )

net.Receive( "cd2net_tutorial_activatehud", function()
    local variable = net.ReadString()
    _G[ variable ] = true
end )

local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_SetMaterial = surface.SetMaterial
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local background = Material( "crackdown2/dropmenu/bg.png", "smooth" )
local black = Color( 0, 0, 0 )
local blackish = Color( 39, 39, 39)
local grey = Color( 100, 100, 100 )
net.Receive( "cd2net_playerinitialspawn", function()
    CD2_HasNavMesh = net.ReadBool()

    if !CD2_HasNavMesh then
        local pnl = vgui.Create( "DPanel", GetHUDPanel() )
        pnl:Dock( FILL ) 
        pnl:MakePopup()
        
        local lbl = vgui.Create("DLabel", pnl )
        lbl:SetFont( "crackdown2_font60" )
        lbl:SetText( "This map does not have a Navigation Mesh! The CRACKDOWN 2 Gamemode requires you to play on a map with a Navigation Mesh! Press the button below to generate a Navigation Mesh or play a map that has one" )
        lbl:SetWrap( true )
        lbl:SetSize( ScrW() / 2, 500 )
        lbl:SetPos( ( ScrW() / 3 ), ( ScrH() / 5 ) - 250 )

        local button = vgui.Create( "DButton", pnl )
        button:SetSize( 200, 30 )
        button:SetPos( ( ScrW() / 2 ) - 30, ( ScrH() / 2 ) - 15 )
        button:SetText( "Generate NavMesh" )

        function button:DoClick()
            lbl:SetText( "Please wait while a nav mesh generates..")
            net.Start( "cd2net_generatenavmesh" )
            net.SendToServer()
        end

        function button:Paint( w, h )
            surface_SetDrawColor( blackish )
            surface_DrawRect( 0, 0, w, h )
        end

        CD2StartMusic( "sound/crackdown2/music/startmenu.mp3", 500, true, false, nil, nil, nil, nil, nil, function( CD2Musicchannel ) 
            if player_manager.GetPlayerClass( LocalPlayer() ) == "cd2_player" then CD2Musicchannel:FadeOut() end
        end )

        function pnl:Paint( w, h ) 
            surface_SetDrawColor( grey )
            surface_SetMaterial( background )
            surface_DrawTexturedRect( 0, 0, w, h )
        end
        return
    end

    CD2OpenMainMenu()
end )

net.Receive( "cd2net_pinglocation", function() 
    local pos = net.ReadVector()
    local pingconsole = net.ReadBool()

    if pingconsole then
        CD2PingLocationOnConsole( pos )
    else
        CD2PingLocationTracker( pos )
    end
end )

net.Receive( "cd2net_playergroundpound", function() 
    local pos = net.ReadVector()

    local particle = ParticleEmitter( pos )
        for i = 1, 30 do
            
            local part = particle:Add( "particle/SmokeStack", pos )
    
            if part then
                part:SetStartSize( 70 )
                part:SetEndSize( 70 ) 
                part:SetStartAlpha( 255 )
                part:SetEndAlpha( 0 )
    
                part:SetColor( 100, 100, 100 )
                part:SetLighting( false )
                part:SetCollide( false )
    
                part:SetDieTime( 2 )
                part:SetGravity( Vector() )
                part:SetAirResistance( 400 )
                part:SetVelocity( Vector( math.sin( i ) * 2000, math.cos( i ) * 2000, 0 ) )
                part:SetAngleVelocity( AngleRand( -1, 1 ) )
            end
    
        end
    
        particle:Finish()

end )

net.Receive( "cd2net_enablehud", function()
    CD2_DrawAgilitySkill = true
    CD2_DrawFirearmSkill = true
    CD2_DrawStrengthSkill = true
    CD2_DrawExplosiveSkill = true
    CD2_CanOpenAgencyConsole = true

    CD2_DrawTargetting = true
    CD2_DrawHealthandShields = true
    CD2_DrawWeaponInfo = true
    CD2_DrawMinimap = true
    CD2_DrawBlackbars = false
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

    CD2CreateThread( function()
        while !ply:Alive() do coroutine.yield() end

        CD2StartMusic( "sound/crackdown2/music/levelup.mp3", 3, false, true )
        ply:EmitSound( "crackdown2/ply/spawnenergy.mp3", 70, 100, 1, CHAN_AUTO )

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
        while !ply:Alive() do coroutine.yield() end

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

local flame = Material( "crackdown2/effects/flamelet1.png" )
net.Receive( "cd2net_freakkill", function()
    local pos = net.ReadVector()

    sound.Play( "ambient/fire/gascan_ignite1.wav", pos, 60, 100, 1 )
    local particle = ParticleEmitter( pos )
    for i = 1, 60 do

        local part = particle:Add( "particle/SmokeStack", pos )

        if part then
            part:SetStartSize( 10 )
            part:SetEndSize( 10 ) 
            part:SetStartAlpha( 255 )
            part:SetEndAlpha( 0 )

            part:SetColor( 255, 255, 50 )
            part:SetLighting( false )
            part:SetCollide( true )

            part:SetDieTime( 2 )
            part:SetGravity( Vector( 0, 0, -80 ) )
            part:SetAirResistance( 200 )
            part:SetVelocity( Vector( random( -200, 200 ), random( -200, 200 ), random( -200, 200 ) ) )
            part:SetAngleVelocity( AngleRand( -1, 1 ) )
        end

    end

    particle:Finish()

end )

net.Receive( "cd2net_emitsound2", function()
    local ent = net.ReadEntity()
    if !IsValid( ent ) then return end 
    local path = net.ReadString()
    local snddist = net.ReadUInt( 32 )
    local volume = net.ReadFloat()
    sound.PlayFile( path, "3d mono noplay", function( chan, id, name )
        if id then return end
        chan:SetVolume( volume )
        chan:SetPos( ent:GetPos() )
        chan:Play()

        hook.Add( "Think", ent, function()  
            if !IsValid( chan ) or chan:GetState() == GMOD_CHANNEL_STOPPED then hook.Remove( "Think", ent ) return end
            chan:SetPos( ent:GetPos() )
        end )
    end )
end )

net.Receive( "cd2net_explosion", function()
    local pos = net.ReadVector()
    local scale = net.ReadFloat()

    local addvec = VectorRand( 20 * -scale, 20 * scale )
    local particle = ParticleEmitter( pos, pos + addvec )


    hook.Add( "Think", "crackdown2_explosionlight", function()
        local light = DynamicLight( random( 0, 1000000 ) )
        if ( light ) then
            light.pos = pos
            light.r = 255
            light.g = 115
            light.b = 0
            light.brightness = 5
            light.Decay = 800
            light.Size = 500 + ( scale > 1 and 600 * scale or 0)
            light.DieTime = CurTime() + 5
            hook.Remove( "Think", "crackdown2_explosionlight" )
        end
    end )

    for i = 1, 25 + ( 5 * scale ) do
        addvec = VectorRand( 20 * -scale, 20 * scale )
        local part = particle:Add( "particle/SmokeStack", pos + addvec )

        if part then
            part:SetStartSize( 60 * scale )
            part:SetEndSize( 45 * scale ) 
            part:SetStartAlpha( 255 )
            part:SetEndAlpha( 0 )

            part:SetColor( 255, 115, 0 )
            part:SetLighting( false )

            part:SetDieTime( 2 )
            part:SetGravity( Vector() )
            part:SetAirResistance( 200 )

            local randomvalue = 300 + ( scale > 1 and 300 * scale or 0 )

            part:SetVelocity( Vector( random( -randomvalue, randomvalue ), random( -randomvalue, randomvalue ), random( -randomvalue, randomvalue ) ) )
            part:SetAngleVelocity( AngleRand( -0.5, 0.5 ) )
        end

    end


    particle:Finish()

    addvec = VectorRand( 20 * -scale, 20 * scale )
    local particle = ParticleEmitter( pos, pos + addvec )

    for i = 1, 25 + ( 5 * scale ) do
        addvec = VectorRand( 20 * -scale, 20 * scale )
        local part = particle:Add( "particle/SmokeStack", pos + addvec )

        if part then
            part:SetStartSize( 60 * scale )
            part:SetEndSize( 45 * scale ) 
            part:SetStartAlpha( 255 )
            part:SetEndAlpha( 0 )

            part:SetColor( 100, 100, 100 )
            part:SetLighting( false )

            part:SetDieTime( 6 )
            part:SetGravity( Vector() )
            part:SetAirResistance( 200 )

            local randomvalue = 200 + ( scale > 1 and 200 * scale or 0 )

            part:SetVelocity( Vector( random( -randomvalue, randomvalue ), random( -randomvalue, randomvalue ), random( -randomvalue, randomvalue ) ) )
            part:SetAngleVelocity( AngleRand( -0.5, 0.5 ) )
        end

    end

    particle:Finish()

end )

net.Receive( "cd2net_introduction_music", function()
    CD2StartMusic( "sound/crackdown2/music/flythrough.mp3", 500, true, false, nil, nil, nil, nil, nil, function( CD2Musicchannel ) 
        if !LocalPlayer():GetNW2Bool( "cd2_inintroduction", false ) then CD2Musicchannel:FadeOut() end
    end )
end )



net.Receive( "cd2net_sendtypingtext", function()
    local top = net.ReadString()
    local bottom = net.ReadString()
    local isred = net.ReadBool()
    CD2SetTypingText( top, bottom, isred )
end )


local function PlayerHasWeapon( class )
    local hasweapon = CD2FILESYSTEM:ReadPlayerData( "cd2_weaponcollect_" .. class )
    return hasweapon
end

net.Receive( "cd2net_checkweapons", function()
    local weps = LocalPlayer():GetWeapons()
    local equipment = LocalPlayer():GetEquipment()
    local texttbl = {}
    local newweps = false 

    for k , v in ipairs( weps ) do 
        if IsValid( v ) and v.DropMenu_RequiresCollect and !PlayerHasWeapon( v:GetClass() ) then 
            texttbl[ #texttbl + 1 ] = v:GetPrintName()
            CD2FILESYSTEM:WritePlayerData( "cd2_weaponcollect_" .. v:GetClass(), true )
            newweps = true 
        end
    end

    local enttbl = scripted_ents.Get( equipment )

    if enttbl.DropMenu_RequiresCollect and !PlayerHasWeapon( equipment ) then
        texttbl[ #texttbl + 1 ] = enttbl.PrintName
        CD2FILESYSTEM:WritePlayerData( "cd2_weaponcollect_" .. equipment, true )
        newweps = true 
    end

    if newweps then
        CD2SetTypingText( "Equipment Stored", table.concat( texttbl, ", " ) )
    end

end )