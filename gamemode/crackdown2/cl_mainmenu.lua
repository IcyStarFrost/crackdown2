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
    local channel = CD2StartMusic( "sound/crackdown2/music/startmenu.mp3", 490, true )
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

    function playbutton:DoClick()
        if IsValid( optionspnl ) then optionspnl:Remove() end
        surface.PlaySound( "crackdown2/ui/ui_select.mp3" )
        MenuPanelHolder:Clear()

        timer.Simple( 0, function()
            local toptextpnl = vgui.Create( "DPanel", MenuPanelHolder )
            toptextpnl:SetSize( 100, 100 )
            toptextpnl:Dock( TOP )

            function toptextpnl:Paint( w, h ) 
                surface_SetDrawColor( blackish )
                surface_DrawRect( 0, 0, w, h )
            end
        
            local toptext = vgui.Create( "DLabel", toptextpnl )
            toptext:SetFont( "crackdown2_font60" )
            toptext:SetSize( 100, 100 )
            toptext:SetText( "             AGENT SETUP" )
            toptext:Dock( TOP )
        
            local line = vgui.Create( "DPanel", MenuPanelHolder )
            line:SetSize( 100, 3 )
            line:Dock( TOP )

            local selecttext = vgui.Create( "DLabel", MenuPanelHolder )
            selecttext:SetFont( "crackdown2_font50" )
            selecttext:SetSize( 100, 60 )
            selecttext:SetColor( Color( 218, 103, 10 ) )
            selecttext:SetText( "             SELECT YOUR AGENT COLOR" )
            selecttext:Dock( TOP )

            local confirmbutton = vgui.Create( "DButton", MenuPanelHolder )
            confirmbutton:SetSize( 100, 50 )
            confirmbutton:SetFont( "crackdown2_font40" )
            confirmbutton:SetText( "CONFIRM" )
            confirmbutton:Dock( BOTTOM )

            local colorvector = CD2FILESYSTEM:ReadPlayerData( "cd2_agentcolorvector" )
            if !colorvector then colorvector = Vector( 1, 1, 1 ) CD2FILESYSTEM:WritePlayerData( "cd2_agentcolorvector", colorvector ) end

            local agentpreview = vgui.Create( "DModelPanel", MenuPanelHolder )
            agentpreview:SetSize( ScrW() / 2, ScrH() / 3 )
            agentpreview:Dock( RIGHT )
            agentpreview:SetModel( "models/player/combine_super_soldier.mdl" )
            agentpreview:GetEntity().GetPlayerColor = function( self ) return colorvector end
            function agentpreview:LayoutEntity() end

            local color = vgui.Create( "DColorMixer", MenuPanelHolder )
            color:SetSize( ScrW() / 2, ScrH() / 3 )
            color:DockMargin( 10, 10, 10, 10 )
            color:Dock( LEFT )
            color:SetColor( colorvector:ToColor() )

            function color:ValueChanged( col ) 
                colorvector = Vector( col.r / 255, col.g / 255, col.b / 255 )
                CD2FILESYSTEM:WritePlayerData( "cd2_agentcolorvector", colorvector )
            end

            function confirmbutton:Paint( w, h ) 
                surface_SetDrawColor( blackish )
                surface_DrawRect( 0, 0, w, h )
            end

            function confirmbutton:DoClick() 
                CD2_MainMenu:Remove()
                channel:Kill()

                net.Start( "cd2net_setplayercolor" )
                net.WriteVector( CD2FILESYSTEM:ReadPlayerData( "cd2_agentcolorvector" ) )
                net.SendToServer()

                local isreturningplayer = !KeysToTheCity() and CD2FILESYSTEM:ReadPlayerData( "c_isreturningplayer" ) or KeysToTheCity() and true
                local completedtutorial = !KeysToTheCity() and CD2FILESYSTEM:ReadPlayerData( "c_completedtutorial" ) or KeysToTheCity() and true
                
                -- If the player is new to the gamemode, then play the intro video
                if !isreturningplayer then
                    CD2CreateThread( function()

                        if BRANCH == "x86-64" or BRANCH == "chromium" then
                            CD2BeginIntroVideo()

                            while IsValid( CD2_videopanel ) do
                                coroutine.yield()
                            end
                        end

                        CD2_DrawAgilitySkill = false
                        CD2_DrawFirearmSkill = false
                        CD2_DrawStrengthSkill = false
                        CD2_DrawExplosiveSkill = false
                        CD2_CanOpenAgencyConsole = false

                        CD2_DrawTargetting = false
                        CD2_DrawHealthandShields = false
                        CD2_DrawWeaponInfo = false
                        CD2_DrawMinimap = false
                        CD2_DrawBlackbars = false

                        net.Start( "cd2net_starttutorial" )
                        net.SendToServer()

                    end )

                    CD2FILESYSTEM:WritePlayerData( "c_isreturningplayer", true )
                else -- If not then let them get in game already. If they haven't completed the tutorial then run it

                    if !completedtutorial then

                        CD2_DrawAgilitySkill = false
                        CD2_DrawFirearmSkill = false
                        CD2_DrawStrengthSkill = false
                        CD2_DrawExplosiveSkill = false
                        CD2_CanOpenAgencyConsole = false

                        CD2_DrawTargetting = false
                        CD2_DrawHealthandShields = false
                        CD2_DrawWeaponInfo = false
                        CD2_DrawMinimap = false
                        CD2_DrawBlackbars = false

                        net.Start( "cd2net_starttutorial" )
                        net.SendToServer()
                        return
                    end

                    timer.Simple( 1, function()
                        if !KeysToTheCity() then
                            sound.PlayFile( "sound/crackdown2/vo/agencydirector/droppoint.mp3", "noplay", function( snd, id, name ) snd:SetVolume( 10 ) snd:Play() end )
                        end
                    end )
            
                    CD2OpenSpawnPointMenu()
                    CD2StartMusic( "sound/crackdown2/music/droppointmusic.mp3", 500, true, false, nil, nil, nil, nil, nil, function( CD2Musicchannel ) 
                        if player_manager.GetPlayerClass( LocalPlayer() ) == "cd2_player" then CD2Musicchannel:FadeOut() end
                    end )

                end

            end

        end )


    end

    function optionsbutton:DoClick()
        surface.PlaySound( "crackdown2/ui/ui_select.mp3" )
        optionspnl = vgui.Create( "DFrame", MenuPanelHolder )
        optionspnl:SetSize( 500, 300 )
        optionspnl:Center()
        optionspnl:SetTitle( "CRACKDOWN 2 OPTIONS" )

        local scroll = vgui.Create( "DScrollPanel", optionspnl )
        scroll:Dock( FILL )

        local musicvolume = vgui.Create( "DNumSlider", scroll )
        musicvolume:SetSize( 200, 30 )
        musicvolume:SetConVar( "cd2_musicvolume" )
        musicvolume:SetText( "Music Volume" )
        musicvolume:SetDecimals( 2 )
        musicvolume:SetMin( 0 )
        musicvolume:SetMax( 1 )
        musicvolume:SetValue( GetConVar( "cd2_musicvolume" ):GetFloat() )


        function optionspnl:Paint( w, h ) 
            surface_SetDrawColor( blackish )
            surface_DrawRect( 0, 0, w, h )
        end
    end


    function MenuPanelHolder:Paint() end

    function toptextpnl:Paint( w, h ) 
        surface_SetDrawColor( blackish )
        surface_DrawRect( 0, 0, w, h )
    end

    function CD2_MainMenu:OnKeyCodePressed( key ) 
        local jumpbind = input.LookupBinding( "+jump" ) or "SPACE"
        local jumpcode = input.GetKeyCode( jumpbind )

        if key and !MenuPanelHolder:IsVisible() then
            surface.PlaySound( "crackdown2/ui/dropmenuopen" .. random( 1, 2 ) .. ".mp3" )
            MenuPanelHolder:Show()
            channel:FadeOut()
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

        draw.DrawText( "Press any Key to Start", "crackdown2_font50", ScrW() / 2, ScrH() / 1.5, color_white, TEXT_ALIGN_CENTER )
    end

end