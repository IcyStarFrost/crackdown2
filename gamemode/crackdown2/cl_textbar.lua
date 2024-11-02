local bg = Material( "crackdown2/ui/textboxbg.png" )
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local linecol = Color( 61, 61, 61, 100 )



function CD2SetTextBoxText( txt )
    if !GetConVar( "cd2_drawhud" ):GetBool() then return end
    CD2.CurrentTextBoxText = txt
end

CD2.CurrentTextBoxText = nil -- The current text being displayed in the text box
CD2.textend = nil
CD2.TextBox = CD2.TextBox or nil -- The text box itself

hook.Add( "OnGamemodeLoaded", "crackdown2_textbox", function()
    if IsValid( CD2.TextBox ) then CD2.TextBox:Remove() end
    local x, y = ScreenScale( 178 ), ScreenScale( 67 )
    CD2.TextBox = vgui.Create( "DPanel", GetHUDPanel() )
    CD2.TextBox:SetPos( ( ScrW() / 2 ) - ( x / 2) , ScrH() - 205 )
    CD2.TextBox:SetSize( x, y )

    CD2.TextBox.lbl = vgui.Create( "DLabel", CD2.TextBox )
    CD2.TextBox.lbl:SetFont( "crackdown2_font30" )
    CD2.TextBox.lbl:SetText( "" )
    CD2.TextBox.lbl:DockMargin( 5, 5, 5, 5 )
    CD2.TextBox.lbl:Dock( FILL )
    CD2.TextBox.lbl:SetWrap( true )
    
    function CD2.TextBox:Think() 
        if CD2.CurrentTextBoxText and CD2.TextBox.lbl:GetText() != CD2.CurrentTextBoxText then
            CD2.TextBox.lbl:SetText( CD2.CurrentTextBoxText )
            CD2.textend = CD2.textend or SysTime() + 5
        end

        if CD2.textend and SysTime() > CD2.textend then CD2.CurrentTextBoxText = nil CD2.textend = nil CD2.TextBox.lbl:SetText( "" ) end
    end

    function CD2.TextBox:Paint( w, h ) 
        if !CD2.CurrentTextBoxText then return end
        surface_SetDrawColor( color_white )
        surface_SetMaterial( bg )
        surface_DrawTexturedRect( 0, 0, w, h )

        surface_SetDrawColor( linecol )
        surface_DrawOutlinedRect( 0, 0, w, h, 2 )
    end
end )