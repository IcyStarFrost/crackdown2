if CLIENT then
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_DrawRect = surface.DrawRect
    local blackish = Color( 39, 39, 39 )
    local black = Color( 0, 0, 0 )
    local bg = Color( 39, 39, 39, 100 )
    local linecol = Color( 61, 61, 61, 100 )
    local orange = Color( 255, 115, 0 )
    local surface_DrawOutlinedRect = surface.DrawOutlinedRect
    local foldericon = Material( "crackdown2/ui/folder.png", "smooth" )

    surface.CreateFont( "crackdown2_kttc", {
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
    
    if IsValid( CD2_KeysToTheCityMenu ) then CD2_KeysToTheCityMenu:Remove() end



    
    --hook.Add( "PostGamemodeLoaded", "crackdown2_keystothecitymenu", function()
        if !KeysToTheCity() then return end

        hook.Add( "Think", "crackdown2_showhidekttcmenu", function()
            if !IsValid( CD2_KeysToTheCityMenu ) then return end

            if CD2_InDropMenu or CD2_InSpawnPointMenu or !LocalPlayer():Alive() then
                CD2_KeysToTheCityMenu:Hide()
            elseif !CD2_InDropMenu and !CD2_InSpawnPointMenu and LocalPlayer():Alive() then
                CD2_KeysToTheCityMenu:Show()
            end
        
        end )
    
        CD2_KeysToTheCityMenu = vgui.Create( "DPanel", GetHUDPanel() )
        CD2_KeysToTheCityMenu:SetPos( ScrW() - 400, ScrH() - 450 )
        CD2_KeysToTheCityMenu:SetSize( 350, 280 )

        CD2_KeysToTheCityMenu.Scroll = vgui.Create( "DScrollPanel", CD2_KeysToTheCityMenu )
        CD2_KeysToTheCityMenu.Scroll:Dock( FILL )
        local vbar = CD2_KeysToTheCityMenu.Scroll:GetVBar()

        function vbar:Paint( w, h ) end

        CD2_KeysToTheCityMenu.CurrentIndex = 1
        CD2_KeysToTheCityMenu.CurrentOptionPanel = nil
        CD2_KeysToTheCityMenu.CurrentFolder = "global"
        CD2_KeysToTheCityMenu.OptionFolders = { global = {} }
        CD2_KeysToTheCityMenu.OptionFolderPanels = {}

        function CD2_KeysToTheCityMenu:SelectIndex( i )
            local folder = CD2_KeysToTheCityMenu.OptionFolders[ CD2_KeysToTheCityMenu.CurrentFolder ]
            local pnl = folder[ i ]
            CD2_KeysToTheCityMenu.CurrentIndex = i
            CD2_KeysToTheCityMenu.CurrentOptionPanel = pnl
            CD2_KeysToTheCityMenu.Scroll:ScrollToChild( pnl )
        end

        function CD2_KeysToTheCityMenu:CallCurrentOption()
            local func = CD2_KeysToTheCityMenu.CurrentOptionPanel.callback
            func( CD2_KeysToTheCityMenu.CurrentOptionPanel )
        end

        function CD2_KeysToTheCityMenu:GetCurrentFolderTable()
            return CD2_KeysToTheCityMenu.OptionFolders[ CD2_KeysToTheCityMenu.CurrentFolder ]
        end

        function CD2_KeysToTheCityMenu:Paint( w, h ) 
            surface_SetDrawColor( bg )
            surface_DrawRect( 0, 0, w, h )

            surface_SetDrawColor( linecol )
            surface_DrawOutlinedRect( 0, 0, w, h, 2 )
        end
    
        local function AddOption( name, folder, type, options, callback )
            folder = folder or "global"
            local optionpnl = vgui.Create( "DPanel", CD2_KeysToTheCityMenu.Scroll )
            optionpnl:SetSize( 100, 30 )
            optionpnl:Dock( TOP )

            optionpnl.callback = callback

            optionpnl.label = vgui.Create( "DLabel", optionpnl )
            optionpnl.label:SetText( name )
            optionpnl.label:SetSize( 250, 100 )
            optionpnl.label:DockMargin( 2, 2, 2, 2 )
            optionpnl.label:Dock( LEFT )
            optionpnl.label:SetFont( "crackdown2_kttc" )


            CD2_KeysToTheCityMenu.OptionFolders[ folder ] = CD2_KeysToTheCityMenu.OptionFolders[ folder ] or {}

            if !CD2_KeysToTheCityMenu.OptionFolderPanels[ folder ] and folder != "global" then
                CD2_KeysToTheCityMenu.OptionFolderPanels[ folder ] = AddOption( folder, "global", "Folder", {}, function()
                    local tbl = CD2_KeysToTheCityMenu:GetCurrentFolderTable()
                    for i = 1, #tbl do
                        local pnl = tbl[ i ]
                        pnl:SetParent()
                        pnl:Hide()
                    end

                    local tbl2 = CD2_KeysToTheCityMenu.OptionFolders[ folder ]
                    CD2_KeysToTheCityMenu.CurrentFolder = folder
                    
                    for i = 1, #tbl2 do
                        local pnl = tbl2[ i ]
                        pnl:SetParent( CD2_KeysToTheCityMenu.Scroll )
                        pnl:Show()
                    end

                    CD2_KeysToTheCityMenu:SelectIndex( 1 )
                end )
            end

            if CD2_KeysToTheCityMenu.CurrentFolder != folder then optionpnl:SetParent() optionpnl:Hide() end

            local foldertable = CD2_KeysToTheCityMenu.OptionFolders[ folder ]

            if type == "Check" then
                optionpnl.OptionPnl = vgui.Create( "DCheckBox", optionpnl )
                optionpnl.OptionPnl:SetChecked( options.default )
                optionpnl.OptionPnl:SetSize( 30, 30 )
                optionpnl.OptionPnl:DockMargin( 2, 2, 2, 2 )
                optionpnl.OptionPnl:Dock( RIGHT )

                function optionpnl.OptionPnl:Paint( w, h )
                    surface_SetDrawColor( self:GetChecked() and orange or black )
                    surface_DrawRect( 0, 0, w, h )

                    surface_SetDrawColor( linecol )
                    surface_DrawOutlinedRect( 0, 0, w, h, 1 )
                end

                function optionpnl:GetValue()
                    return optionpnl.OptionPnl:GetChecked()
                end

                function optionpnl:SetValue( val )
                    optionpnl.OptionPnl:SetChecked( val )
                end
            elseif type == "Num" then
                optionpnl.OptionPnl = vgui.Create( "DLabel", optionpnl )
                optionpnl.OptionPnl:SetText( tostring( options.default ) )
                optionpnl.OptionPnl:SetSize( 30, 30 )
                optionpnl.OptionPnl:DockMargin( 2, 2, 2, 2 )
                optionpnl.OptionPnl:Dock( RIGHT )
                optionpnl.OptionPnl:SetFont( "crackdown2_kttc" )
                optionpnl.OptionPnl.Num = options.default
                optionpnl.OptionPnl.Max = options.max

                function optionpnl:GetValue()
                    return optionpnl.OptionPnl.Num
                end

                function optionpnl:SetValue( val )
                    optionpnl.OptionPnl.Num = val
                    optionpnl.OptionPnl:SetText( tostring( val ) )
                end
            elseif type == "Folder" then
                optionpnl.icon = vgui.Create( "DImage", optionpnl )
                optionpnl.icon:SetMaterial( foldericon )
                optionpnl.icon:SetSize( 30, 30 )
                optionpnl.icon:DockMargin( 2, 2, 2, 2 )
                optionpnl.icon:Dock( RIGHT )
            end

            function optionpnl:Paint( w, h ) 
                surface_SetDrawColor( bg )
                surface_DrawRect( 0, 0, w, h )
    
                surface_SetDrawColor( CD2_KeysToTheCityMenu.CurrentOptionPanel == self and color_white or linecol )
                surface_DrawOutlinedRect( 0, 0, w, h, 2 )
            end

            foldertable[ #foldertable + 1 ] = optionpnl
            return optionpnl
        end

        -- Adding the options now

        -- Weapons --

        for k, v in ipairs( weapons.GetList() ) do
            if !weapons.IsBasedOn( v.ClassName, "cd2_weaponbase" ) then continue end
            AddOption( "Spawn " .. v.PrintName, "Weapons", "Button", { default = false }, function( pnl )
                net.Start( "cd2net_kttc_spawnnpc" )
                net.WriteString( v.ClassName )
                net.WriteAngle( CD2_viewangles )
                net.SendToServer()
            end )
        end
--[[         AddOption( "Spawn SMG", "Weapons", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_smg" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )

        AddOption( "Spawn Agency Assault Rifle", "Weapons", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_assaultrifle" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )

        AddOption( "Spawn Agency Sniper", "Weapons", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_sniper" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )

        AddOption( "Spawn Machine Gun", "Weapons", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_machinegun" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )

        AddOption( "Spawn Shotgun", "Weapons", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_shotgun" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )

        AddOption( "Spawn Rocket Launcher", "Weapons", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_rocketlauncher" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )

        AddOption( "Spawn Pistol", "Weapons", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_pistol" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end ) ]]
        --

        
        -- Objects --
        AddOption( "Spawn Explosive Barrel", "Objects", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnprop" )
            net.WriteString( "models/props_c17/oildrum001_explosive.mdl" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )

        AddOption( "Spawn Radio", "Objects", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_radio" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )
        --


        -- Agency --
        AddOption( "Spawn PeaceKeeper", "Agency", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_peacekeeper" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )
        --

        -- Civilians --
        AddOption( "Spawn Civilian", "Civilian", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_civilian" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )
        --

        -- Cell --
        AddOption( "Spawn Cell SMG Soldier", "Cell", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_smgcellsoldier" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )

        AddOption( "Spawn Cell Shotgun Soldier", "Cell", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_shotguncellsoldier" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )
        --

        -- Freaks -- 
        AddOption( "Spawn Freak", "Freaks", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_freak" )
            net.WriteAngle( CD2_viewangles )
            net.SendToServer()
        end )
        --


        
        local agility = AddOption( "Agility Skill", "global", "Num", { default = 1, max = 6 }, function( pnl )
            pnl:SetValue( pnl:GetValue() + 1 )
            if pnl:GetValue() > 6 then pnl:SetValue( 1 ) end

            pnl:SetText( tostring( pnl:GetValue() ) )

            net.Start( "cd2net_kttc_setskill" )
            net.WriteUInt( pnl:GetValue(), 5 )
            net.WriteString( "Agility" )
            net.SendToServer()
        end )

        local firearm = AddOption( "Firearm Skill", "global", "Num", { default = 1, max = 6 }, function( pnl )
            pnl:SetValue( pnl:GetValue() + 1 )
            if pnl:GetValue() > 6 then pnl:SetValue( 1 ) end

            pnl:SetText( tostring( pnl:GetValue() ) )

            net.Start( "cd2net_kttc_setskill" )
            net.WriteUInt( pnl:GetValue(), 5 )
            net.WriteString( "Weapon" )
            net.SendToServer()
        end )

        local strength = AddOption( "Strength Skill", "global", "Num", { default = 1, max = 6 }, function( pnl )
            pnl:SetValue( pnl:GetValue() + 1 )
            if pnl:GetValue() > 6 then pnl:SetValue( 1 ) end

            pnl:SetText( tostring( pnl:GetValue() ) )

            net.Start( "cd2net_kttc_setskill" )
            net.WriteUInt( pnl:GetValue(), 5 )
            net.WriteString( "Strength" )
            net.SendToServer()
        end )

        local explosive = AddOption( "Explosive Skill", "global", "Num", { default = 1, max = 6 }, function( pnl )
            pnl:SetValue( pnl:GetValue() + 1 )
            if pnl:GetValue() > 6 then pnl:SetValue( 1 ) end

            pnl:SetText( tostring( pnl:GetValue() ) )

            net.Start( "cd2net_kttc_setskill" )
            net.WriteUInt( pnl:GetValue(), 5 )
            net.WriteString( "Explosive" )
            net.SendToServer()
        end )

        AddOption( "Set Skills To Maximum", "global", "Check", { default = false }, function( pnl )
            pnl:SetValue( !pnl:GetValue() )

            if pnl:GetValue() then
                agility:SetValue( 6 )
                firearm:SetValue( 6 )
                strength:SetValue( 6 )
                explosive:SetValue( 6 )

                net.Start( "cd2net_kttc_setskill" )
                net.WriteUInt( 6, 5 )
                net.WriteString( "Agility" )
                net.SendToServer()
                
                net.Start( "cd2net_kttc_setskill" )
                net.WriteUInt( 6, 5 )
                net.WriteString( "Weapon" )
                net.SendToServer()

                net.Start( "cd2net_kttc_setskill" )
                net.WriteUInt( 6, 5 )
                net.WriteString( "Strength" )
                net.SendToServer()

                net.Start( "cd2net_kttc_setskill" )
                net.WriteUInt( 6, 5 )
                net.WriteString( "Explosive" )
                net.SendToServer()
            else
                agility:SetValue( 1 )
                firearm:SetValue( 1 )
                strength:SetValue( 1 )
                explosive:SetValue( 1 )

                net.Start( "cd2net_kttc_setskill" )
                net.WriteUInt( 1, 5 )
                net.WriteString( "Agility" )
                net.SendToServer()

                net.Start( "cd2net_kttc_setskill" )
                net.WriteUInt( 1, 5 )
                net.WriteString( "Weapon" )
                net.SendToServer()

                net.Start( "cd2net_kttc_setskill" )
                net.WriteUInt( 1, 5 )
                net.WriteString( "Strength" )
                net.SendToServer()

                net.Start( "cd2net_kttc_setskill" )
                net.WriteUInt( 1, 5 )
                net.WriteString( "Explosive" )
                net.SendToServer()
            end
        end )

        AddOption( "Infinite Ammo", "global", "Check", { default = false }, function( pnl )
            pnl:SetValue( !pnl:GetValue() )
            net.Start( "cd2net_kttc_setinfiniteammo" )
            net.WriteBool( pnl:GetValue() )
            net.SendToServer()
        end )

        AddOption( "God Mode", "global", "Check", { default = false }, function( pnl )
            pnl:SetValue( !pnl:GetValue() )
            net.Start( "cd2net_kttc_godmode" )
            net.WriteBool( pnl:GetValue() )
            net.SendToServer()
        end )
        
        -------------------------

        CD2_KeysToTheCityMenu:SelectIndex( 1 )

        local nextcanpress = 0
        function CD2_KeysToTheCityMenu:Think()
            if SysTime() < nextcanpress or LocalPlayer():IsTyping() then return end
            local ply = LocalPlayer()

            if input.IsKeyDown( KEY_DOWN ) then

                local nextindex = CD2_KeysToTheCityMenu.CurrentIndex + 1
                local tbl = CD2_KeysToTheCityMenu:GetCurrentFolderTable()
                if nextindex > #tbl then
                    nextindex = 1
                end

                surface.PlaySound( "crackdown2/ui/hover.mp3" )
                CD2_KeysToTheCityMenu:SelectIndex( nextindex )
                nextcanpress = SysTime() + 0.2

            elseif input.IsKeyDown( KEY_UP ) then
            
                local nextindex = CD2_KeysToTheCityMenu.CurrentIndex - 1
                local tbl = CD2_KeysToTheCityMenu:GetCurrentFolderTable()
                if nextindex < 1 then
                    nextindex = #tbl
                end
    
                surface.PlaySound( "crackdown2/ui/hover.mp3" )
                CD2_KeysToTheCityMenu:SelectIndex( nextindex )
                nextcanpress = SysTime() + 0.2

            elseif input.IsKeyDown( KEY_ENTER ) then

                CD2_KeysToTheCityMenu:CallCurrentOption()
                surface.PlaySound( "crackdown2/ui/ui_select.mp3" )
                nextcanpress = SysTime() + 0.2

            elseif input.IsKeyDown( KEY_BACKSPACE ) and CD2_KeysToTheCityMenu.CurrentFolder != "global" then

                surface.PlaySound( "crackdown2/ui/ui_select.mp3" )

                local tbl = CD2_KeysToTheCityMenu:GetCurrentFolderTable()
                for i = 1, #tbl do
                    local pnl = tbl[ i ]
                    pnl:SetParent()
                    pnl:Hide()
                end

                local tbl2 = CD2_KeysToTheCityMenu.OptionFolders[ "global" ]
                CD2_KeysToTheCityMenu.CurrentFolder = "global"
                
                for i = 1, #tbl2 do
                    local pnl = tbl2[ i ]
                    pnl:SetParent( CD2_KeysToTheCityMenu.Scroll )
                    pnl:Show()
                end

                
                CD2_KeysToTheCityMenu:SelectIndex( 1 )

            end
        end
    
    --end )



elseif SERVER then

    util.AddNetworkString( "cd2net_kttc_godmode" )
    util.AddNetworkString( "cd2net_kttc_setinfiniteammo" )
    util.AddNetworkString( "cd2net_kttc_spawnnpc" )
    util.AddNetworkString( "cd2net_kttc_spawnprop" )
    util.AddNetworkString( "cd2net_kttc_setskill" )


    net.Receive( "cd2net_kttc_godmode", function( len, ply )
        ply.cd2_godmode = net.ReadBool()
    end )

    net.Receive( "cd2net_kttc_spawnprop", function( len, ply )
        if !KeysToTheCity() then return end
        local mdl = net.ReadString()
        local angles = net.ReadAngle()

        local ent = ents.Create( "prop_physics" )
        ent:SetPos( ply:GetPos() + ( Angle( 0, angles[ 2 ], 0 ):Forward() * 100 ) )
        ent:SetAngles( Angle( 0, angles[ 2 ], 0 ) )
        ent:SetModel( mdl )
        ent:Spawn()
    end )
    
    net.Receive( "cd2net_kttc_spawnnpc", function( len, ply )
        if !KeysToTheCity() then return end
        local class = net.ReadString()
        local angles = net.ReadAngle()

        local ent = ents.Create( class )
        ent:SetPos( ply:GetPos() + ( Angle( 0, angles[ 2 ], 0 ):Forward() * 100 ) )
        ent:SetAngles( Angle( 0, angles[ 2 ], 0 ) )
        ent:Spawn()
    end )

    net.Receive( "cd2net_kttc_setinfiniteammo", function( len, ply )
        if !KeysToTheCity() then return end
        ply.cd2_infiniteammo = net.ReadBool()
    end )
        
    net.Receive( "cd2net_kttc_setskill", function( len, ply )
        if !KeysToTheCity() then return end
        local lvl = net.ReadUInt( 5 )
        local skillname = net.ReadString()

        local skillsetfunc = ply[ "Set" .. skillname .. "Skill" ]

        skillsetfunc( ply, lvl )
        ply:BuildSkills()
    end )

end