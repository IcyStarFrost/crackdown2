local grey = Color( 100, 100, 100 )
local random = math.random
local backgrounds = { Material( "crackdown2/mainmenu/menubg1.jpg" ), Material( "crackdown2/mainmenu/menubg2.jpg" ), Material( "crackdown2/mainmenu/menubg3.jpg" ) }
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect


function CD2OpenMainMenu()

    CD2_MainMenu = vgui.Create( "DPanel", GetHUDPanel() )
    CD2_MainMenu:Dock( FILL )
    CD2_MainMenu:MakePopup()

    local MenuPanelHolder = vgui.Create( "DPanel", CD2_MainMenu )
    MenuPanelHolder:Dock( FILL )
    MenuPanelHolder:Hide()

    local channel = CD2StartMusic( "sound/crackdown2/music/startmenu.mp3", 490, true )


    function MenuPanelHolder:Paint() end

    function CD2_MainMenu:OnKeyCodePressed( key ) 
        if key and !MenuPanelHolder:IsVisible() then
            surface.PlaySound( "crackdown2/ui/dropmenuopen" .. random( 1, 2 ) .. ".mp3" )
            MenuPanelHolder:Show()
            channel:Kill()
            channel = CD2StartMusic( "sound/crackdown2/music/mainmusic.mp3", 490, true )
        end
    end
    

    local bg = backgrounds[ random( 3 ) ]
    function CD2_MainMenu:Paint( w, h ) 
        surface_SetDrawColor( grey )
        surface_SetMaterial( bg )
        surface_DrawTexturedRect( 0, 0, w, h )
    end

end