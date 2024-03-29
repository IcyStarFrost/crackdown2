local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_SetMaterial = surface.SetMaterial
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local background = Material( "crackdown2/dropmenu/bg.png", "smooth" )
local blackish = Color( 39, 39, 39)
local grey = Color( 100, 100, 100 )

local channel

function CD2ShowFailMenu( text, isnavmesh )
    if IsValid( CD2_FailPanel ) then CD2_FailPanel:Remove() end
    if IsValid( CD2_AgencyConsole ) then CD2_AgencyConsole:Remove() end 
    if IsValid( CD2_DropMenu ) then CD2_DropMenu:Remove() end
    if IsValid( CD2_SpawnPointMenu ) then CD2_SpawnPointMenu:Remove() end
    if IsValid( CD2_MainMenu ) then CD2_MainMenu:Remove() end
    if IsValid( channel ) then channel:Kill() end
    
    CD2_FailPanel = vgui.Create( "DPanel", GetHUDPanel() )
    CD2_FailPanel:Dock( FILL ) 
    CD2_FailPanel:MakePopup()
    
    local lbl = vgui.Create("DLabel", CD2_FailPanel )
    lbl:SetFont( "crackdown2_font60" )
    lbl:SetText( text )
    lbl:SetWrap( true )
    lbl:SetSize( ScrW() / 2, 500 )
    lbl:SetPos( ( ScrW() / 3 ), ( ScrH() / 5 ) - 250 )

    if isnavmesh then
        local button = vgui.Create( "DButton", CD2_FailPanel )
        button:SetSize( 200, 30 )
        button:SetPos( ( ScrW() / 2 ) - 30, ( ScrH() / 2 ) - 15 )
        button:SetText( "Generate NavMesh" )

        function button:DoClick()
            lbl:SetText( "Please wait while a nav mesh generates..")
            net.Start( "cd2net_generatenavmesh" )
            net.SendToServer()
        end

        function button:Paint( w, h )
            surface_SetDrawColor( blackish )
            surface_DrawRect( 0, 0, w, h )
        end
    end



    channel = CD2StartMusic( "sound/crackdown2/music/startmenu.mp3", 2000, true, false, nil, nil, nil, nil, nil, function( CD2Musicchannel ) 
        if player_manager.GetPlayerClass( LocalPlayer() ) == "cd2_player" or !IsValid( CD2_FailPanel ) then CD2Musicchannel:FadeOut() end
    end )

    function CD2_FailPanel:Paint( w, h ) 
        surface_SetDrawColor( grey )
        surface_SetMaterial( background )
        surface_DrawTexturedRect( 0, 0, w, h )
    end
end