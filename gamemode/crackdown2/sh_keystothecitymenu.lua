if CLIENT then
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_DrawRect = surface.DrawRect
    local black = Color( 0, 0, 0 )
    local bg = Color( 39, 39, 39, 100 )
    local linecol = Color( 61, 61, 61, 100 )
    local orange = Color( 255, 115, 0 )
    local surface_DrawOutlinedRect = surface.DrawOutlinedRect
    local foldericon = Material( "crackdown2/ui/folder.png", "smooth" )


    function CreateKeysTotheCityMenu()
        if !CD2:KeysToTheCity() then return end

        if IsValid( CD2.KeysToTheCityMenu ) then CD2.KeysToTheCityMenu:Remove() end

        hook.Add( "Think", "crackdown2_showhidekttcmenu", function()
            if !IsValid( CD2.KeysToTheCityMenu ) then return end

            if CD2.InDropMenu or CD2.InSpawnPointMenu or !LocalPlayer():Alive() then
                CD2.KeysToTheCityMenu:Hide()
            elseif !CD2.InDropMenu and !CD2.InSpawnPointMenu and LocalPlayer():Alive() then
                CD2.KeysToTheCityMenu:Show()
            end
        
        end )
    
        CD2.KeysToTheCityMenu = vgui.Create( "DPanel", GetHUDPanel() )
        CD2.KeysToTheCityMenu:SetPos( ScrW() - 400, ScrH() - 450 )
        CD2.KeysToTheCityMenu:SetSize( 350, 280 )

        CD2.KeysToTheCityMenu.Scroll = vgui.Create( "DScrollPanel", CD2.KeysToTheCityMenu )
        CD2.KeysToTheCityMenu.Scroll:Dock( FILL )
        local vbar = CD2.KeysToTheCityMenu.Scroll:GetVBar()

        function vbar:Paint( w, h ) end

        CD2.KeysToTheCityMenu.CurrentIndex = 1
        CD2.KeysToTheCityMenu.CurrentOptionPanel = nil
        CD2.KeysToTheCityMenu.CurrentFolder = "global"
        CD2.KeysToTheCityMenu.OptionFolders = { global = {} }
        CD2.KeysToTheCityMenu.OptionFolderPanels = {}

        function CD2.KeysToTheCityMenu:SelectIndex( i )
            local folder = CD2.KeysToTheCityMenu.OptionFolders[ CD2.KeysToTheCityMenu.CurrentFolder ]
            local pnl = folder[ i ]
            CD2.KeysToTheCityMenu.CurrentIndex = i
            CD2.KeysToTheCityMenu.CurrentOptionPanel = pnl
            CD2.KeysToTheCityMenu.Scroll:ScrollToChild( pnl )
        end

        function CD2.KeysToTheCityMenu:CallCurrentOption()
            local func = CD2.KeysToTheCityMenu.CurrentOptionPanel.callback
            func( CD2.KeysToTheCityMenu.CurrentOptionPanel )
        end

        function CD2.KeysToTheCityMenu:GetCurrentFolderTable()
            return CD2.KeysToTheCityMenu.OptionFolders[ CD2.KeysToTheCityMenu.CurrentFolder ]
        end

        function CD2.KeysToTheCityMenu:Paint( w, h ) 
            surface_SetDrawColor( bg )
            surface_DrawRect( 0, 0, w, h )

            surface_SetDrawColor( linecol )
            surface_DrawOutlinedRect( 0, 0, w, h, 2 )
        end
    
        local function AddOption( name, folder, type, options, callback )
            folder = folder or "global"
            local optionpnl = vgui.Create( "DPanel", CD2.KeysToTheCityMenu.Scroll )
            optionpnl:SetSize( 100, 30 )
            optionpnl:Dock( TOP )

            optionpnl.callback = callback

            optionpnl.label = vgui.Create( "DLabel", optionpnl )
            optionpnl.label:SetText( name )
            optionpnl.label:SetSize( 250, 100 )
            optionpnl.label:DockMargin( 2, 2, 2, 2 )
            optionpnl.label:Dock( LEFT )
            optionpnl.label:SetFont( "crackdown2_font30" )


            CD2.KeysToTheCityMenu.OptionFolders[ folder ] = CD2.KeysToTheCityMenu.OptionFolders[ folder ] or {}

            if !CD2.KeysToTheCityMenu.OptionFolderPanels[ folder ] and folder != "global" then
                CD2.KeysToTheCityMenu.OptionFolderPanels[ folder ] = AddOption( folder, "global", "Folder", {}, function()
                    local tbl = CD2.KeysToTheCityMenu:GetCurrentFolderTable()
                    for i = 1, #tbl do
                        local pnl = tbl[ i ]
                        pnl:SetParent()
                        pnl:Hide()
                    end

                    local tbl2 = CD2.KeysToTheCityMenu.OptionFolders[ folder ]
                    CD2.KeysToTheCityMenu.CurrentFolder = folder
                    
                    for i = 1, #tbl2 do
                        local pnl = tbl2[ i ]
                        pnl:SetParent( CD2.KeysToTheCityMenu.Scroll )
                        pnl:Show()
                    end

                    CD2.KeysToTheCityMenu:SelectIndex( 1 )
                end )
            end

            if CD2.KeysToTheCityMenu.CurrentFolder != folder then optionpnl:SetParent() optionpnl:Hide() end

            local foldertable = CD2.KeysToTheCityMenu.OptionFolders[ folder ]

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
                optionpnl.OptionPnl:SetFont( "crackdown2_font30" )
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
    
                surface_SetDrawColor( CD2.KeysToTheCityMenu.CurrentOptionPanel == self and color_white or linecol )
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
                net.WriteAngle( CD2.viewangles )
                net.SendToServer()
            end )
        end

        --

        -- Equipment --
        for ClassName, basetable in pairs( scripted_ents.GetList() ) do
            if basetable.Base != "cd2_equipmentbase" then continue end
            AddOption( "Spawn " .. basetable.t.PrintName, "Equipment", "Button", { default = false }, function( pnl )
                net.Start( "cd2net_kttc_spawnnpc" )
                net.WriteString( ClassName )
                net.WriteAngle( CD2.viewangles )
                net.SendToServer()
            end )
        end
        --

        -- Game Objects --
        AddOption( "Spawn Hidden Orb", "Objects", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_hiddenorb")
            net.WriteAngle( CD2.viewangles )
            net.SendToServer()
        end )
        --

        
        -- Objects --
        AddOption( "Spawn Explosive Barrel", "Objects", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnprop" )
            net.WriteString( "models/props_c17/oildrum001_explosive.mdl" )
            net.WriteAngle( CD2.viewangles )
            net.SendToServer()
        end )

        AddOption( "Spawn Radio", "Objects", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_radio" )
            net.WriteAngle( CD2.viewangles )
            net.SendToServer()
        end )

        AddOption( "Spawn Speaker", "Objects", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_speaker" )
            net.WriteAngle( CD2.viewangles )
            net.SendToServer()
        end )
        --


        -- Agency --

        for ClassName, basetable in pairs( scripted_ents.GetList() ) do
            if basetable.Base != "cd2_combathumanbase" or basetable.t.cd2_Team != "agency" then continue end
            AddOption( "Spawn " .. basetable.t.PrintName, "Agency", "Button", { default = false }, function( pnl )
                net.Start( "cd2net_kttc_spawnnpc" )
                net.WriteString( ClassName )
                net.WriteAngle( CD2.viewangles )
                net.SendToServer()
            end )
        end

        AddOption( "Spawn Beacon", "Agency", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnbeacon" )
            net.SendToServer()
        end )

        AddOption( "Spawn Tower Beacon", "Agency", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_towerbeacon" )
            net.WriteAngle( Angle() )
            net.SendToServer()
        end )
        --

        -- Civilians --
        AddOption( "Spawn Civilian", "Civilian", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_spawnnpc" )
            net.WriteString( "cd2_civilian" )
            net.WriteAngle( CD2.viewangles )
            net.SendToServer()
        end )
        --

        -- Cell --
        for ClassName, basetable in pairs( scripted_ents.GetList() ) do
            if basetable.Base != "cd2_combathumanbase" or basetable.t.cd2_Team != "cell" then continue end
            AddOption( "Spawn " .. basetable.t.PrintName, "Cell", "Button", { default = false }, function( pnl )
                net.Start( "cd2net_kttc_spawnnpc" )
                net.WriteString( ClassName )
                net.WriteAngle( CD2.viewangles )
                net.SendToServer()
            end )
        end
        --

        -- Freaks -- 

        for ClassName, basetable in pairs( scripted_ents.GetList() ) do
            if basetable.t.cd2_Team != "freak" then continue end
            AddOption( "Spawn " .. basetable.t.PrintName, "Freaks", "Button", { default = false }, function( pnl )
                net.Start( "cd2net_kttc_spawnnpc" )
                net.WriteString( ClassName )
                net.WriteAngle( CD2.viewangles )
                net.SendToServer()
            end )
        end
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

        AddOption( "No Target", "global", "Check", { default = false }, function( pnl )
            pnl:SetValue( !pnl:GetValue() )
            net.Start( "cd2net_kttc_notarget" )
            net.WriteBool( pnl:GetValue() )
            net.SendToServer()
        end )
        
        AddOption( "Freeze Time", "global", "Check", { default = false }, function( pnl )
            pnl:SetValue( !pnl:GetValue() )
            net.Start( "cd2net_kttc_freezetime" )
            net.WriteBool( pnl:GetValue() )
            net.SendToServer()
        end )

        AddOption( "Free Cam", "global", "Check", { default = false }, function( pnl )
            pnl:SetValue( !pnl:GetValue() )
            CD2.FreeCamMode = pnl:GetValue()
        end )

        AddOption( "Hide HUD", "global", "Check", { default = false }, function( pnl )
            pnl:SetValue( !pnl:GetValue() )
            CD2_HideKTTCMenu = !pnl:GetValue()

            if pnl:GetValue() then
                CD2.KeysToTheCityMenu:SetPos( -10000, -100000 )
            else
                CD2.KeysToTheCityMenu:SetPos( ScrW() - 400, ScrH() - 450 )
            end

            RunConsoleCommand( "cd2_drawhud", !pnl:GetValue() and "1" or "0" )
        end )
        
        AddOption( "Empty Streets", "global", "Check", { default = false }, function( pnl )
            pnl:SetValue( !pnl:GetValue() )
            net.Start( "cd2net_kttc_emptystreets" )
            net.WriteBool( pnl:GetValue() )
            net.SendToServer()
        end )

        AddOption( "Skip to Next Dawn/Dusk", "global", "Button", { default = false }, function( pnl )
            net.Start( "cd2net_kttc_nexttime" )
            net.SendToServer()
        end )
        
        -------------------------

        CD2.KeysToTheCityMenu:SelectIndex( 1 )

        local nextcanpress = 0
        function CD2.KeysToTheCityMenu:Think()
            if SysTime() < nextcanpress or LocalPlayer():IsTyping() then return end

            if input.IsKeyDown( KEY_DOWN ) then

                local nextindex = CD2.KeysToTheCityMenu.CurrentIndex + 1
                local tbl = CD2.KeysToTheCityMenu:GetCurrentFolderTable()
                if nextindex > #tbl then
                    nextindex = 1
                end

                surface.PlaySound( "crackdown2/ui/hover.mp3" )
                CD2.KeysToTheCityMenu:SelectIndex( nextindex )
                nextcanpress = SysTime() + 0.2

            elseif input.IsKeyDown( KEY_UP ) then
            
                local nextindex = CD2.KeysToTheCityMenu.CurrentIndex - 1
                local tbl = CD2.KeysToTheCityMenu:GetCurrentFolderTable()
                if nextindex < 1 then
                    nextindex = #tbl
                end
    
                surface.PlaySound( "crackdown2/ui/hover.mp3" )
                CD2.KeysToTheCityMenu:SelectIndex( nextindex )
                nextcanpress = SysTime() + 0.2

            elseif input.IsKeyDown( KEY_ENTER ) then

                CD2.KeysToTheCityMenu:CallCurrentOption()
                surface.PlaySound( "crackdown2/ui/ui_select.mp3" )
                nextcanpress = SysTime() + 0.2

            elseif input.IsKeyDown( KEY_BACKSPACE ) and CD2.KeysToTheCityMenu.CurrentFolder != "global" then

                surface.PlaySound( "crackdown2/ui/ui_select.mp3" )

                local tbl = CD2.KeysToTheCityMenu:GetCurrentFolderTable()
                for i = 1, #tbl do
                    local pnl = tbl[ i ]
                    pnl:SetParent()
                    pnl:Hide()
                end

                local tbl2 = CD2.KeysToTheCityMenu.OptionFolders[ "global" ]
                CD2.KeysToTheCityMenu.CurrentFolder = "global"
                
                for i = 1, #tbl2 do
                    local pnl = tbl2[ i ]
                    pnl:SetParent( CD2.KeysToTheCityMenu.Scroll )
                    pnl:Show()
                end

                
                CD2.KeysToTheCityMenu:SelectIndex( 1 )

            end
        end
    
    end 


    CreateKeysTotheCityMenu()
    
    hook.Add( "PostGamemodeLoaded", "crackdown2_keystothecitymenu", CreateKeysTotheCityMenu )

elseif SERVER then

    util.AddNetworkString( "cd2net_kttc_godmode" )
    util.AddNetworkString( "cd2net_kttc_setinfiniteammo" )
    util.AddNetworkString( "cd2net_kttc_spawnnpc" )
    util.AddNetworkString( "cd2net_kttc_spawnprop" )
    util.AddNetworkString( "cd2net_kttc_setskill" )
    util.AddNetworkString( "cd2net_kttc_nexttime" )
    util.AddNetworkString( "cd2net_kttc_freezetime" )
    util.AddNetworkString( "cd2net_kttc_spawnbeacon" )
    util.AddNetworkString( "cd2net_kttc_emptystreets" )
    util.AddNetworkString( "cd2net_kttc_notarget" )

    local Trace = util.TraceLine
    local tracetable = {}

    net.Receive( "cd2net_kttc_notarget", function( len, ply ) 
        ply.cd2_notarget = net.ReadBool()
    end )
    
    net.Receive( "cd2net_kttc_spawnbeacon", function( len, ply )
        local pos = ply:GetPos() + ply:GetForward() * 100

        if !util.IsInWorld( pos ) then return end

        tracetable.start = pos
        tracetable.endpos = pos + Vector( 0, 0, 4000 )
        tracetable.mask = MASK_SOLID_BRUSHONLY
        tracetable.collisiongroup = COLLISION_GROUP_WORLD

        local result = Trace( tracetable )

        local beacon = ents.Create( "cd2_beacon" )
        beacon:SetPos( result.HitPos - Vector( 0, 0, 130 ) )
        beacon:SetRandomSoundTrack()
        beacon:Spawn()

        timer.Simple( 0.3, function() beacon:DropBeacon() end )
    end )

    net.Receive( "cd2net_kttc_emptystreets", function( len, ply )
        local val = net.ReadBool()
        CD2_EmptyStreets = val

        if val then
            CD2:ClearNPCS()
            table.Empty( CD2_SpawnedNSNNpcs )
        end
    end )

    net.Receive( "cd2net_kttc_nexttime", function( len, ply )
        if !CD2:KeysToTheCity() then return end
        CD2_NextFreakSpawn = CurTime() + 10
        SetGlobalBool( "cd2_isday", !GetGlobalBool( "cd2_isday", false ) )

        CD2:DebugMessage( "Time is now changing to " .. ( GetGlobalBool( "cd2_isday", false ) and "Dawn" or "Dusk" ) )

        net.Start( "cd2net_dawndusk_changetime" )
        net.WriteBool( GetGlobalBool( "cd2_isday", false ) )
        net.Broadcast()

        CD2_NextTimeChange = CurTime() + 720
    end )

    net.Receive( "cd2net_kttc_freezetime", function( len, ply )
        if !CD2:KeysToTheCity() then return end
        local bool = net.ReadBool()
        CD2_FreezeTime = bool
    end )

    net.Receive( "cd2net_kttc_godmode", function( len, ply )
        if !CD2:KeysToTheCity() then return end
        ply.cd2_godmode = net.ReadBool()
    end )

    net.Receive( "cd2net_kttc_spawnprop", function( len, ply )
        if !CD2:KeysToTheCity() then return end
        local mdl = net.ReadString()
        local angles = net.ReadAngle()

        local ent = ents.Create( "prop_physics" )
        ent:SetPos( ply:GetPos() + ( Angle( 0, angles[ 2 ], 0 ):Forward() * 100 ) )
        ent:SetAngles( Angle( 0, angles[ 2 ], 0 ) )
        ent:SetModel( mdl )
        ent:Spawn()
    end )
    
    net.Receive( "cd2net_kttc_spawnnpc", function( len, ply )
        if !CD2:KeysToTheCity() then return end
        local class = net.ReadString()
        local angles = net.ReadAngle()

        local ent = ents.Create( class )
        ent:SetPos( ply:GetPos() + ( Angle( 0, angles[ 2 ], 0 ):Forward() * 100 ) )
        ent:SetAngles( Angle( 0, angles[ 2 ], 0 ) )
        ent:Spawn()
    end )

    net.Receive( "cd2net_kttc_setinfiniteammo", function( len, ply )
        if !CD2:KeysToTheCity() then return end
        ply.cd2_infiniteammo = net.ReadBool()
    end )
        
    net.Receive( "cd2net_kttc_setskill", function( len, ply )
        if !CD2:KeysToTheCity() then return end
        local lvl = net.ReadUInt( 5 )
        local skillname = net.ReadString()

        local skillsetfunc = ply[ "Set" .. skillname .. "Skill" ]

        skillsetfunc( ply, lvl )
        ply:BuildSkills()
    end )

end