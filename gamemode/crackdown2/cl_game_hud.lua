
CD2Progressbars = CD2Progressbars or {}

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

