local math = math
local surface = surface
local red = Color( 163, 12, 12)
--local alphawhite = Color( 255, 255, 255, 10 )
local peacekeeper = Material( "crackdown2/ui/peacekeeper.png", "smooth" )
local cell = Material( "crackdown2/ui/cell.png", "smooth" )


CD2Progressbars = CD2Progressbars or {}

CD2.lockon = false


function CD2RegisterProgressBar( ent, distance, priority, drawfunc )
    CD2Progressbars[ #CD2Progressbars + 1 ] = { ent = ent, priority = priority, distance = distance, drawfunc = drawfunc }
    table.sort( CD2Progressbars, function( a, b ) return a.priority > b.priority end )
end


local fireicon = Material( "crackdown2/ui/explosive.png" )

hook.Add( "HUDPaint", "crackdown2_hud", function()
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

