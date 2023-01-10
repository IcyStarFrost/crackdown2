local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local Trace = util.TraceLine
local LerpVector = LerpVector
local blackish = Color( 39, 39, 39 )
local gold = Color( 255, 209, 5 )
local draw_NoTexture = draw.NoTexture
local orange = Color( 218, 103, 10 )
local random = math.random
local input_GetKeyName = input.GetKeyName
local input_LookupBinding = input.LookupBinding
local upper = string.upper
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local surface_SetMaterial = surface.SetMaterial
local input_GetKeyCode = input.GetKeyCode
local star = Material( "crackdown2/ui/star.png" )

CD2_SpawnPointMenu = CD2_SpawnPointMenu or nil
CD2_SpawnPointIndex = 1
CD2_SelectedSpawnPoint = Vector()
CD2_SelectedSpawnAngle = Angle()
CD2_InSpawnPointMenu = false
local viewtrace = {}
local viewtbl = {}

surface.CreateFont( "crackdown2_spawnpointmenubottomtext", {
    font = "Agency FB",
	extended = false,
	size = 60,
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

function CD2OpenSpawnPointMenu()

    CD2_DrawBlackbars = false
    surface.PlaySound( "crackdown2/ui/dropmenuopen" .. random( 1, 2 ) .. ".mp3" )

    net.Start( "cd2net_playerregenerate" )
    net.SendToServer()

    CD2CreateThread( function()

        CD2_InSpawnPointMenu = true

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

        CD2_SpawnPointMenu = vgui.Create( "DPanel", GetHUDPanel() )
        CD2_SpawnPointMenu:Dock( FILL )
        CD2_SpawnPointMenu:MakePopup()
        CD2_SpawnPointMenu:SetKeyBoardInputEnabled( false )

        local toptext = vgui.Create( "DLabel", CD2_SpawnPointMenu )
        toptext:SetFont( "crackdown2_dropmenutoptext" )
        toptext:SetSize( 100, 100 )
        toptext:SetText( "             AGENCY REDEPLOYMENT PROGRAM" )
        toptext:Dock( TOP )

        local line = vgui.Create( "DPanel", CD2_SpawnPointMenu )
        line:SetSize( 100, 3 )
        line:Dock( TOP )

        local selecttext = vgui.Create( "DLabel", CD2_SpawnPointMenu )
        selecttext:SetFont( "crackdown2_dropmenutext1" )
        selecttext:SetSize( 100, 60 )
        selecttext:SetColor( Color( 218, 103, 10 ) )
        selecttext:SetText( "             CHOOSE A DROP POINT TO DEPLOY YOUR AGENT" )
        selecttext:Dock( TOP )

        function CD2_SpawnPointMenu:OnRemove()
            CD2_InSpawnPointMenu = false
            CD2_ViewOverride = nil
        end

        local viewpos
        local spawnpointpanels = {}

        CD2_ViewOverride = function( ply, origin, angles, fov, znear, zfar )
            local spawns = CD2_SpawnPoints
            local spawnpoint = spawns[ CD2_SpawnPointIndex ]

            if CD2_SelectedSpawnPoint != spawnpoint[ 1 ] then
                CD2_SelectedSpawnPoint = spawnpoint[ 1 ]
            end

            if CD2_SelectedSpawnAngle != spawnpoint[ 2 ] then
                CD2_SelectedSpawnAngle = spawnpoint[ 2 ]
            end

            viewpos = viewpos or spawnpoint[ 1 ]
            viewpos = LerpVector( 4 * FrameTime(), viewpos, spawnpoint[ 1 ] )


            viewtrace.start = viewpos + Vector( 0, 0, 5 )
            viewtrace.endpos = viewpos + Vector( 0, 0, 20000 )
            viewtrace.mask = MASK_SOLID_BRUSHONLY
            viewtrace.collisiongroup = COLLISION_GROUP_WORLD
            local result = Trace( viewtrace )

            viewtbl.origin = viewpos + Vector( 0, 0, 20000 )
            viewtbl.angles = Angle( 90, 0, 0 )
            viewtbl.znear = result.Hit and result.HitPos:Distance( viewtrace.endpos ) or 10
            viewtbl.fov = 20
            viewtbl.zfar = zfar
            viewtbl.drawviewer = true

            return viewtbl
        end


        function CD2_SpawnPointMenu:Paint( w, h ) 
            local spawns = CD2_SpawnPoints

            for k, v in ipairs( spawns ) do
                local screen = v[ 1 ]:ToScreen()

                surface_SetDrawColor( gold )
                surface_SetMaterial( star )
                surface_DrawTexturedRectRotated( screen.x, screen.y, 20, 20, k == CD2_SpawnPointIndex and -( SysTime() * 200 ) or 0 )

                draw_NoTexture()

                if !IsValid( spawnpointpanels[ k ] ) then
                    local spawnpoint = v[ 1 ]
                    local screen2 = spawnpoint:ToScreen()
                    local index = k
                    local button = vgui.Create( "DButton", CD2_SpawnPointMenu )
                    button:SetText( "" )
                    button:SetSize( 30, 30 )
                    button:SetPos( screen2.x - 15, screen2.y - 15 )

                    function button:Think() 
                        if !CD2_InSpawnPointMenu then self:Remove() return end
                        screen2 = spawnpoint:ToScreen()
                        button:SetPos( screen2.x - 15, screen2.y - 15 )
                    end

                    function button:DoClick()
                        CD2_SpawnPointIndex = index
                        surface.PlaySound( "crackdown2/ui/ui_spawnselect.mp3" )
                    end

                    function button:Paint() end

                    spawnpointpanels[ k ] = button
                end
            end

            surface_SetDrawColor( blackish )
            surface_DrawRect( 0, 0, w, 100 )

            surface_SetDrawColor( blackish )
            surface_DrawRect( 0, h - 50, w, 100 )

            local usebind = input_LookupBinding( "+use" ) or "e"
            local code = input_GetKeyCode( usebind )
            local buttonname = input_GetKeyName( code )
    
            local reloadbind = input_LookupBinding( "+reload" ) or "r"
            local rcode = input_GetKeyCode( reloadbind )
            local reloadname = input_GetKeyName( rcode )

            local jumpbind = input_LookupBinding( "+jump" ) or "SPACE"
            local jumpcode = input_GetKeyCode( jumpbind )
            local jumpname = input_GetKeyName( jumpcode )

            CD2DrawInputbar( 100, 200, upper( buttonname ), " Select previous Drop Point" )
            CD2DrawInputbar( 150, 250, upper( reloadname ), " Select next Drop Point" )

            draw.DrawText( "Press " .. jumpname .. " to confirm your Drop Point", "crackdown2_spawnpointmenubottomtext", w / 2, h - 55, orange, TEXT_ALIGN_CENTER )

        end


    end )

end

hook.Add( "Think", "crackdown2_spawnpointmenu", function()
    local ply = LocalPlayer()

    if !CD2_InSpawnPointMenu then return end


    if ply:KeyPressed( IN_USE ) then
        surface.PlaySound( "crackdown2/ui/ui_spawnselect.mp3" )
        CD2_SpawnPointIndex = CD2_SpawnPointIndex - 1
        if CD2_SpawnPointIndex <= 0 then CD2_SpawnPointIndex = #CD2_SpawnPoints end
    elseif ply:KeyPressed( IN_RELOAD ) then
        surface.PlaySound( "crackdown2/ui/ui_spawnselect.mp3" )
        CD2_SpawnPointIndex = CD2_SpawnPointIndex + 1
        if CD2_SpawnPointIndex > #CD2_SpawnPoints then CD2_SpawnPointIndex = 1 end
    elseif ply:KeyPressed( IN_JUMP ) then 
        surface.PlaySound( "crackdown2/ui/ui_select.mp3" )
        CD2_SpawnPointMenu:Remove()
        if !CD2_InDropMenu then
            CD2OpenDropMenu()
        end
    end

end )