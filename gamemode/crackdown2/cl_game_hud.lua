
CD2Progressbars = CD2Progressbars or {}

CD2.lockon = false


function CD2RegisterProgressBar( ent, distance, priority, drawfunc )
    CD2Progressbars[ #CD2Progressbars + 1 ] = { ent = ent, priority = priority, distance = distance, drawfunc = drawfunc }
    table.sort( CD2Progressbars, function( a, b ) return a.priority > b.priority end )
end


hook.Add( "HUDPaint", "crackdown2_hud", function()
    if !GetConVar( "cd2_drawhud" ):GetBool() then RemoveHUDpanels() return end 

    for k, tbl in ipairs( CD2Progressbars ) do
        if !IsValid( tbl.ent ) or tbl.ent:SqrRangeTo( LocalPlayer() ) > tbl.distance ^ 2 then continue end
        local active = tbl.drawfunc( tbl.ent )
        if active then break end
    end
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

