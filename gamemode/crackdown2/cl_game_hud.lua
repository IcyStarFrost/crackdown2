local math = math
local surface = surface
local red = Color( 163, 12, 12)
local blackish = Color( 39, 39, 39)
local grey = Color( 61, 61, 61)
--local alphawhite = Color( 255, 255, 255, 10 )
local peacekeeper = Material( "crackdown2/ui/peacekeeper.png", "smooth" )
local cell = Material( "crackdown2/ui/cell.png", "smooth" )

local agentdown = Material( "crackdown2/ui/agentdown.png", "smooth" )


CD2Progressbars = CD2Progressbars or {}

CD2.lockon = false

function CD2:DrawCircle( x, y, radius, seg, rotate )
    rotate = rotate or 0
	local cir = {}

	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -360 + rotate )
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( rotate ) -- This is needed for non math.absolute segment counts
	table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end



function CD2RegisterProgressBar( ent, distance, priority, drawfunc )
    CD2Progressbars[ #CD2Progressbars + 1 ] = { ent = ent, priority = priority, distance = distance, drawfunc = drawfunc }
    table.sort( CD2Progressbars, function( a, b ) return a.priority > b.priority end )
end


function CD2:DrawInputBar( x, y, key, text )

    surface.SetFont( "crackdown2_font30" )
    local sizex = surface.GetTextSize( text )

    draw.NoTexture()
    surface.SetDrawColor( blackish )
    surface.DrawRect( x, y - 15, sizex + 30, 30 )
    
    surface.SetDrawColor( grey )
    CD2:DrawCircle( x, y, 20, 6 )

    local keyname = key != "" and input.GetKeyName( key ) or ""

    draw.DrawText( string.upper( keyname ), "crackdown2_font30", x, y - 15, color_white, TEXT_ALIGN_CENTER )

    draw.DrawText( text, "crackdown2_font30", x + 20, y - 17, color_white, TEXT_ALIGN_LEFT )
    
end

local fireicon = Material( "crackdown2/ui/explosive.png" )

hook.Add( "HUDPaint", "crackdown2_hud", function()
    local scrw, ply = ScrW(), LocalPlayer()

    if !game.SinglePlayer() and GetConVar( "cd2_drawhud" ):GetBool() then
        for k, v in ipairs( player.GetAll() ) do
            if v == LocalPlayer() or !v:IsCD2Agent() then continue end
            local ent = IsValid( v:GetRagdollEntity() ) and v:GetRagdollEntity() or v
            local screen = ( ent:GetPos() + Vector( 0, 0, 100 ) ):ToScreen()
            draw.DrawText( v:Name(), "crackdown2_agentnames", screen.x, screen.y, v:GetPlayerColor():ToColor(), TEXT_ALIGN_CENTER )

            if !v:Alive() then 
                local screen = ( ent:GetPos() + Vector( 0, 0, 10 ) ):ToScreen()
                surface.SetMaterial( agentdown )
                surface.SetDrawColor( color_white )
                surface.DrawTexturedRect( screen.x - 65, screen.y - 25, 130, 70 )
            end
        end
    end


    if !ply:Alive() and !CD2.InSpawnPointMenu then 
        local usebind = input.LookupBinding( "+use" ) or "e"
        local code = input.GetKeyCode( usebind )
        local buttonname = input.GetKeyName( code )

        local reloadbind = input.LookupBinding( "+reload" ) or "r"
        local rcode = input.GetKeyCode( reloadbind )
        local reloadname = input.GetKeyName( rcode )
        

        CD2:DrawInputBar( scrw / 2.1, 200, CD2:GetInteractKey2(), "Regenerate" )
        CD2:DrawInputBar( scrw / 2, 250, CD2:GetInteractKey3(), "Regenerate at nearest spawn" )

        if #player.GetAll() > 1 then
            local fbind = input.LookupBinding( "+forward" ) or "w"
            local fcode = input.GetKeyCode( fbind )
            local forwardname = input.GetKeyName( fcode )

            CD2:DrawInputBar( scrw / 1.9, 300, KEY_W, "Hold to call for help" )
        end

        return 
    end

    if !GetConVar( "cd2_drawhud" ):GetBool() then RemoveHUDpanels() return end 

    for k, tbl in ipairs( CD2Progressbars ) do
        if !IsValid( tbl.ent ) or tbl.ent:SqrRangeTo( LocalPlayer() ) > tbl.distance ^ 2 then continue end
        local active = tbl.drawfunc( tbl.ent )
        if active then break end
    end
    
end )

local explosivemodels = {
    [ "models/props_c17/oildrum001_explosive.mdl" ] = true,
    [ "models/props_junk/gascan001a.mdl" ] = true
}

local effects_ents
local next_update_effects = 0

-- Peacekeeper/Cell logos --
hook.Add( "PreDrawEffects", "crackdown2_peacekeepericons/cellicons", function()
    local ply = LocalPlayer()
    if CD2.InDropMenu or !ply:IsCD2Agent() or CD2.InSpawnPointMenu or !ply:Alive() then return end
    
    if CurTime() > next_update_effects then
        effects_ents = CD2:FindInSphere( ply:GetPos(), 1500 )
        next_update_effects = CurTime() + 0.5
    end

    for i = 1, #effects_ents do
        local v = effects_ents[ i ]
        if !IsValid( v ) then continue end

        -- Peacekeeper --
        if v:IsCD2NPC() and v:GetCD2Team() == "agency" then
            render.SetMaterial( peacekeeper )
            render.DrawSprite( v:GetPos() + Vector( 0, 0, 100 ), 32, 20, color_white )
        -- Explosives --
        elseif explosivemodels[ v:GetModel() ] then
            render.SetMaterial( fireicon )
            render.DrawSprite( v:GetPos() + Vector( 0, 0, v:GetModelRadius() + 40 ), 16, 16, color_white )
        -- Cell --
        elseif v:IsCD2NPC() and v:GetCD2Team() == "cell" then
            render.SetMaterial( cell )
            render.DrawSprite( v:GetPos() + Vector( 0, 0, 100 ), 16, 16, red )
        end
    end
end )
----



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

    if CD2:IsDay() then
        modify[ "$pp_colour_brightness" ] = Lerp( 0.1 * FrameTime(), modify[ "$pp_colour_brightness" ], 0 )
    else
        modify[ "$pp_colour_brightness" ] = Lerp( 0.1 * FrameTime(), modify[ "$pp_colour_brightness" ], -0.2 )
    end
    
    if !ply:IsCD2Agent() then return end

    if ply:Alive() and ply:Health() < 70 then
        modify[ "$pp_colour_addr" ] = Lerp( 2 * FrameTime(), modify[ "$pp_colour_addr" ], 0.15 )
    else
        modify[ "$pp_colour_addr" ] = Lerp( 2 * FrameTime(), modify[ "$pp_colour_addr" ], 0 )
    end

    if !ply:Alive() and !CD2.InSpawnPointMenu then
        DrawBokehDOF( 5, 0, 1 )
    end
    
    DrawColorModify( modify )
end )

hook.Add( "NeedsDepthPass", "crackdown2_bokehdepthpass", function()
    return !LocalPlayer():Alive()
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