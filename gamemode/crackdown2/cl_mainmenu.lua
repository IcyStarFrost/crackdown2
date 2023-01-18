local grey = Color( 100, 100, 100 )
local blackish = Color( 0, 0, 0, 200 )
local random = math.random
local backgrounds = { Material( "crackdown2/mainmenu/menubg1.jpg" ), Material( "crackdown2/mainmenu/menubg2.jpg" ), Material( "crackdown2/mainmenu/menubg3.jpg" ) }
local startbg = Material( "crackdown2/mainmenu/start.png" )
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawRect = surface.DrawRect

local function GetMapName()
    local map = game.GetMap()
    local explode = string.Explode( "_", map )
    local largest = ""
    for k, v in ipairs( explode ) do if #v > #largest then largest = v end end
    return string.upper( largest )
end

function CD2OpenMainMenu()

    local mapname = GetMapName()
    local optionspnl

    CD2_MainMenu = vgui.Create( "DPanel", GetHUDPanel() )
    CD2_MainMenu:Dock( FILL )
    CD2_MainMenu:MakePopup()

    local MenuPanelHolder = vgui.Create( "DPanel", CD2_MainMenu )
    MenuPanelHolder:Dock( FILL )
    MenuPanelHolder:Hide()

    local toptextpnl = vgui.Create( "DPanel", MenuPanelHolder )
    toptextpnl:SetSize( 100, 100 )
    toptextpnl:Dock( TOP )

    local toptext = vgui.Create( "DLabel", toptextpnl )
    toptext:SetFont( "crackdown2_font60" )
    toptext:SetSize( 100, 100 )
    toptext:SetText( "             CRACKDOWN 2" )
    toptext:Dock( TOP )

    local line = vgui.Create( "DPanel", MenuPanelHolder )
    line:SetSize( 100, 3 )
    line:Dock( TOP )

    local selecttext = vgui.Create( "DLabel", MenuPanelHolder )
    selecttext:SetFont( "crackdown2_font50" )
    selecttext:SetSize( 100, 60 )
    selecttext:SetColor( Color( 218, 103, 10 ) )
    selecttext:SetText( "             DESTROY THE FREAK VIRUS TO SAVE " .. mapname )
    selecttext:Dock( TOP )

    local playbutton = vgui.Create( "DButton", MenuPanelHolder )
    playbutton:SetSize( 150, 40 )
    playbutton:SetPos( 100, ScrH() / 2.2 )
    playbutton:SetFont( "crackdown2_font30" ) 
    playbutton:SetText( "MAIN GAME" )

    local optionsbutton = vgui.Create( "DButton", MenuPanelHolder )
    optionsbutton:SetSize( 150, 40 )
    optionsbutton:SetPos( 100, ScrH() / 2 )
    optionsbutton:SetFont( "crackdown2_font30" ) 
    optionsbutton:SetText( "OPTIONS" )

    function optionsbutton:Paint( w, h ) 
        surface_SetDrawColor( blackish )
        surface_DrawRect( 0, 0, w, h )
    end

    function playbutton:Paint( w, h ) 
        surface_SetDrawColor( blackish )
        surface_DrawRect( 0, 0, w, h )
    end

    function optionsbutton:DoClick()
        optionspnl = vgui.Create( "DFrame", MenuPanelHolder )
        optionspnl:SetSize( 500, 300 )
        optionspnl:Center()
        optionspnl:SetTitle( "CRACKDOWN 2 OPTIONS" )

        local scroll = vgui.Create( "DScrollPanel", optionspnl )
        scroll:Dock( FILL )


        function optionspnl:Paint( w, h ) 
            surface_SetDrawColor( blackish )
            surface_DrawRect( 0, 0, w, h )
        end
    end

    local channel = CD2StartMusic( "sound/crackdown2/music/startmenu.mp3", 490, true )


    function MenuPanelHolder:Paint() end

    function toptextpnl:Paint( w, h ) 
        surface_SetDrawColor( blackish )
        surface_DrawRect( 0, 0, w, h )
    end

    function CD2_MainMenu:OnKeyCodePressed( key ) 
        if key and !MenuPanelHolder:IsVisible() then
            surface.PlaySound( "crackdown2/ui/dropmenuopen" .. random( 1, 2 ) .. ".mp3" )
            MenuPanelHolder:Show()
            channel:Kill()
            channel = CD2StartMusic( "sound/crackdown2/music/mainmusic.mp3", 490, true )

            local fadepanel = vgui.Create( "DPanel" )
            fadepanel:Dock( FILL )
            fadepanel:SetDrawOnTop( true )
            local fadecol = Color( 0, 0, 0, 255 )
            function fadepanel:Paint( w, h )
                if fadecol.a <= 5 then self:Remove() return end
                fadecol.a = Lerp( 2 * FrameTime(), fadecol.a, 0 )
                surface_SetDrawColor( fadecol )
                surface_DrawRect( 0, 0, w, h )
            end
        end
    end
    

    local bg = backgrounds[ random( 3 ) ]
    function MenuPanelHolder:Paint( w, h ) 
        surface_SetDrawColor( color_white )
        surface_SetMaterial( bg )
        surface_DrawTexturedRect( 0, 0, w, h )
    end

    function CD2_MainMenu:Paint( w, h ) 
        surface_SetDrawColor( grey )
        surface_SetMaterial( startbg )
        surface_DrawTexturedRect( 0, 0, w, h )
    end

end