local bg = Material( "crackdown2/ui/textboxbg.png" )
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local linecol = Color( 61, 61, 61, 100 )

surface.CreateFont( "crackdown2_textbox", {
    font = "Agency FB",
	extended = false,
	size = 30,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,

})

function CD2SetTextBoxText( txt )
    CD2_CurrentTextBoxText = txt
end

CD2_CurrentTextBoxText = nil -- The current text being displayed in the text box
CD2_textend = nil
CD2_TextBox = CD2_TextBox or nil -- The text box itself

--hook.Add( "OnGamemodeLoaded", "crackdown2_textbox", function()
    if IsValid( CD2_TextBox ) then CD2_TextBox:Remove() end
    local x, y = ScreenScale( 178 ), ScreenScale( 67 )
    CD2_TextBox = vgui.Create( "DPanel", GetHUDPanel() )
    CD2_TextBox:SetPos( ( ScrW() / 2 ) - ( x / 2) , ScrH() - 205 )
    CD2_TextBox:SetSize( x, y )

    CD2_TextBox.lbl = vgui.Create( "DLabel", CD2_TextBox )
    CD2_TextBox.lbl:SetFont( "crackdown2_textbox" )
    CD2_TextBox.lbl:SetText( "" )
    CD2_TextBox.lbl:DockMargin( 5, 5, 5, 5 )
    CD2_TextBox.lbl:Dock( FILL )
    CD2_TextBox.lbl:SetWrap( true )
    
    function CD2_TextBox:Think() 
        if CD2_CurrentTextBoxText and CD2_TextBox.lbl:GetText() != CD2_CurrentTextBoxText then
            CD2_TextBox.lbl:SetText( CD2_CurrentTextBoxText )
            CD2_textend = CD2_textend or SysTime() + 5
        end

        if CD2_textend and SysTime() > CD2_textend then CD2_CurrentTextBoxText = nil CD2_textend = nil CD2_TextBox.lbl:SetText( "" ) end
    end

    function CD2_TextBox:Paint( w, h ) 
        if !CD2_CurrentTextBoxText then return end
        surface_SetDrawColor( color_white )
        surface_SetMaterial( bg )
        surface_DrawTexturedRect( 0, 0, w, h )

        surface_SetDrawColor( linecol )
        surface_DrawOutlinedRect( 0, 0, w, h, 2 )
    end
--end )