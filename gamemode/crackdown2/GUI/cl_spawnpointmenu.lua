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

CD2.SpawnPointMenu = CD2.SpawnPointMenu or nil
CD2.SpawnPointIndex = 1
CD2.SelectedSpawnPoint = Vector()
CD2.SelectedSpawnAngle = Angle()
CD2.InSpawnPointMenu = false
local viewtrace = {}
local viewtbl = {}



function CD2:OpenSpawnPointMenu()

    self.DrawBlackbars = false
    surface.PlaySound( "crackdown2/ui/dropmenuopen" .. random( 1, 2 ) .. ".mp3" )

    net.Start( "cd2net_playerregenerate" )
    net.SendToServer()

    self:CreateThread( function()

        self.InSpawnPointMenu = true

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

        self.SpawnPointMenu = vgui.Create( "DPanel", GetHUDPanel() )
        self.SpawnPointMenu:Dock( FILL )
        self.SpawnPointMenu:MakePopup()
        self.SpawnPointMenu:SetKeyBoardInputEnabled( false )

        hook.Add( "SetupWorldFog", self.SpawnPointMenu, function()
            render.FogStart( 0 )
            render.FogEnd( 0 )
            render.FogMaxDensity( 0 )
            render.FogMode( MATERIAL_FOG_LINEAR )
            render.FogColor( 0, 0, 0 )
            return true 
        end )
    
        hook.Add( "SetupSkyboxFog", self.SpawnPointMenu, function()
            render.FogStart( 0 )
            render.FogEnd( 0 )
            render.FogMaxDensity( 0 )
            render.FogMode( MATERIAL_FOG_LINEAR )
            render.FogColor( 0, 0, 0 )
            return true 
        end )

        local toptext = vgui.Create( "DLabel", self.SpawnPointMenu )
        toptext:SetFont( "crackdown2_font60" )
        toptext:SetSize( 100, 100 )
        toptext:SetText( "             AGENCY REDEPLOYMENT PROGRAM" )
        toptext:Dock( TOP )

        local line = vgui.Create( "DPanel", self.SpawnPointMenu )
        line:SetSize( 100, 3 )
        line:Dock( TOP )

        local selecttext = vgui.Create( "DLabel", self.SpawnPointMenu )
        selecttext:SetFont( "crackdown2_font50" )
        selecttext:SetSize( 100, 60 )
        selecttext:SetColor( Color( 218, 103, 10 ) )
        selecttext:SetText( "             CHOOSE A DROP POINT TO DEPLOY YOUR AGENT" )
        selecttext:Dock( TOP )

        function self.SpawnPointMenu:OnRemove()
            CD2.InSpawnPointMenu = false
            CD2.ViewOverride = nil
        end

        local viewpos
        local spawnpointpanels = {}

        self.ViewOverride = function( ply, origin, angles, fov, znear, zfar )
            local spawns = self.SpawnPoints
            local spawnpoint = spawns[ self.SpawnPointIndex ]

            if self.SelectedSpawnPoint != spawnpoint[ 1 ] then
                self.SelectedSpawnPoint = spawnpoint[ 1 ]
            end

            if self.SelectedSpawnAngle != spawnpoint[ 2 ] then
                self.SelectedSpawnAngle = spawnpoint[ 2 ]
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
            viewtbl.zfar = 1000000000
            viewtbl.drawviewer = true

            return viewtbl
        end


        function CD2.SpawnPointMenu:Paint( w, h ) 
            local spawns = CD2.SpawnPoints

            for k, v in ipairs( spawns ) do
                local screen = v[ 1 ]:ToScreen()

                surface_SetDrawColor( gold )
                surface_SetMaterial( star )
                surface_DrawTexturedRectRotated( screen.x, screen.y, 20, 20, k == CD2.SpawnPointIndex and -( SysTime() * 200 ) or 0 )

                draw_NoTexture()

                if !IsValid( spawnpointpanels[ k ] ) then
                    local spawnpoint = v[ 1 ]
                    local screen2 = spawnpoint:ToScreen()
                    local index = k
                    local button = vgui.Create( "DButton", CD2.SpawnPointMenu )
                    button:SetText( "" )
                    button:SetSize( 30, 30 )
                    button:SetPos( screen2.x - 15, screen2.y - 15 )

                    function button:Think() 
                        if !CD2.InSpawnPointMenu then self:Remove() return end
                        screen2 = spawnpoint:ToScreen()
                        button:SetPos( screen2.x - 15, screen2.y - 15 )
                    end

                    function button:DoClick()
                        CD2.SpawnPointIndex = index
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

            CD2:DrawInputBar( 100, 200, KEY_E, " Select previous Drop Point" )
            CD2:DrawInputBar( 150, 250, KEY_R, " Select next Drop Point" )

            draw.DrawText( "Press " .. input.GetKeyName( KEY_SPACE ) .. " to confirm your Drop Point", "crackdown2_font60", w / 2, h - 55, orange, TEXT_ALIGN_CENTER )

        end


    end )

end

hook.Add( "CD2_ButtonPressed", "crackdown2_spawnpointmenu", function( ply, button )
    local ply = LocalPlayer()

    if !CD2.InSpawnPointMenu then return end


    if button == KEY_E then
        surface.PlaySound( "crackdown2/ui/ui_spawnselect.mp3" )
        CD2.SpawnPointIndex = CD2.SpawnPointIndex - 1
        if CD2.SpawnPointIndex <= 0 then CD2.SpawnPointIndex = #CD2.SpawnPoints end
    elseif button == KEY_R then
        surface.PlaySound( "crackdown2/ui/ui_spawnselect.mp3" )
        CD2.SpawnPointIndex = CD2.SpawnPointIndex + 1
        if CD2.SpawnPointIndex > #CD2.SpawnPoints then CD2.SpawnPointIndex = 1 end
    elseif button == KEY_SPACE then 
        surface.PlaySound( "crackdown2/ui/ui_select.mp3" )
        CD2.SpawnPointMenu:Remove()
        if !CD2.InDropMenu then
            CD2:OpenDropMenu()
        end
    end

end )