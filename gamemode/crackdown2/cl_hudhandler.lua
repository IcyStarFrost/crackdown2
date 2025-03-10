CD2.HUDCOMPONENENTS = { components = {}, components_3d = {} }
local hudcomponents = CD2.HUDCOMPONENENTS

-- Handles the drawing of HUD components

-- This was created so each hud component (I.e Crosshair) that was previously seen in the cl_game_hud.lua file can be seperated
-- for organization purposes.
hook.Add( "HUDPaint", "crackdown2_hudhandler", function()
    if !GetConVar( "cd2_drawhud" ):GetBool() then return end

    
    local scrw, scrh = ScrW(), ScrH()
    for name, func in pairs( hudcomponents.components ) do
        if hudcomponents[ "Draw" .. name ] == nil then
            hudcomponents[ "Draw" .. name ] = true
        end
        

        if hudcomponents[ "Draw" .. name ] and !CD2.InSpawnPointMenu and LocalPlayer():IsCD2Agent() then
            func( LocalPlayer(), scrw, scrh, CD2.HUD_SCALE )
        end
    end
end )


-- 3D context version
hook.Add( "PreDrawEffects", "crackdown2_3Dhandler", function()
    for name, func in pairs( hudcomponents.components_3d ) do
        if hudcomponents[ "Draw" .. name ] == nil then
            hudcomponents[ "Draw" .. name ] = true
        end
        

        if hudcomponents[ "Draw" .. name ] and !CD2.InSpawnPointMenu and LocalPlayer():IsCD2Agent() then
            func( LocalPlayer() )
        end
    end
end )

-- Returns whether the given HUD component is being drawn
function CD2:IsHUDComponentDrawing( name )
    return hudcomponents[ "Draw" .. name ] == true
end

-- Enables/disables drawing of a given hud component
function CD2:ToggleHUDComponent( name, bool )
    hudcomponents[ "Draw" .. name ] = bool
end