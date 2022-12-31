local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local draw_DrawText = draw.DrawText
local surface_SetMaterial = surface.SetMaterial
local ceil = math.ceil
local blackish = Color( 39, 39, 39)
local fadedwhite = Color( 255, 255, 255, 10 )
local orange = Color( 255, 115, 0 )
local grey = Color( 100, 100, 100 )
local lightgrey = Color( 143, 143, 143)
local background = Material( "crackdown2/dropmenu/bg.png", "smooth" )
local lockiconmat = Material( "crackdown2/ui/lock.png" )
local Lerp = Lerp
local IsValid = IsValid
local pairs = pairs
local ipairs = ipairs

CD2_InDropMenu = false
CD2_DropMenu = CD2_DropMenu or nil

surface.CreateFont( "crackdown2_dropmenutoptext", {
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

surface.CreateFont( "crackdown2_dropmenutext1", {
    font = "Agency FB",
	extended = false,
	size = 50,
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

surface.CreateFont( "crackdown2_dropmenutext2", {
    font = "Agency FB",
	extended = false,
	size = 45,
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

surface.CreateFont( "crackdown2_weaponstattext", {
    font = "Agency FB",
	extended = false,
	size = ceil( ScreenScale( 6.5 ) ),
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

CD2_DropPrimary = "cd2_smg"
CD2_DropSecondary = "cd2_pistol"
CD2_DropEquipment = "cd2_grenade"

function CD2OpenDropMenu( issupplypoint )

    surface.PlaySound( "crackdown2/ui/dropmenuopen.mp3" )

    CD2_DropPrimary = CD2FILESYSTEM:ReadPlayerData( "cd2_dropprimary" ) or CD2_DropPrimary
    CD2_DropSecondary = CD2FILESYSTEM:ReadPlayerData( "cd2_dropsecondary" ) or CD2_DropSecondary
    CD2_DropEquipment = CD2FILESYSTEM:ReadPlayerData( "cd2_dropequipment" ) or CD2_DropEquipment



    CD2CreateThread( function()

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


        CD2_DropMenu = vgui.Create( "DPanel", GetHUDPanel() )
        CD2_DropMenu:Dock( FILL )


        CD2_DropMenu:MakePopup()
        CD2_InDropMenu = true
        function CD2_DropMenu:OnRemove()
            CD2_InDropMenu = false
            CD2_DropMenu:SetMouseInputEnabled( false )
            CD2_DropMenu:SetKeyBoardInputEnabled( false )
        end

        function CD2_DropMenu:Paint( w, h )
            surface_SetDrawColor( grey )
            surface_SetMaterial( background )
            surface_DrawTexturedRect( 0, 0, w, h )
        end

        local toptext = vgui.Create( "DLabel", CD2_DropMenu )
        toptext:SetFont( "crackdown2_dropmenutoptext" )
        toptext:SetSize( 100, 100 )
        toptext:SetText( !issupplypoint and "             AGENCY REDEPLOYMENT PROGRAM" or "             AGENCY SUPPORT" )
        toptext:Dock( TOP )

        local line = vgui.Create( "DPanel", CD2_DropMenu )
        line:SetSize( 100, 3 )
        line:Dock( TOP )

        local selecttext = vgui.Create( "DLabel", CD2_DropMenu )
        selecttext:SetFont( "crackdown2_dropmenutext1" )
        selecttext:SetSize( 100, 60 )
        selecttext:SetColor( Color( 218, 103, 10 ) )
        selecttext:SetText( "             SELECT YOUR EQUIPMENT" )
        selecttext:Dock( TOP )

        local weapondetailpanel = vgui.Create( "DPanel", CD2_DropMenu )
        weapondetailpanel:SetSize( 500, 200 )
        weapondetailpanel:Dock( RIGHT )
        weapondetailpanel:InvalidateParent( true )

        function weapondetailpanel:Paint( w, h )
            surface_SetDrawColor( fadedwhite )
            surface_DrawOutlinedRect( 0, 0, w, h, 3 )
        end
        
        coroutine.wait( 0 ) -- Delay so CD2_DropMenu can re-layout so we can get accurate position/sizing value


        local plyweaponskill = CD2FILESYSTEM:ReadPlayerData( "cd2_skill_Weapon" ) or 1
        local plyexplosiveskill = CD2FILESYSTEM:ReadPlayerData( "cd2_skill_Explosive" ) or 1


        local function CreateWeaponStatsPanel( isequipment )
            local panel = vgui.Create( "DPanel", weapondetailpanel )
            panel:DockMargin( 3, 3, 3, 3 )
            panel:SetSize( 250, weapondetailpanel:GetTall() / 3 )
            panel:Dock( TOP )
            panel:InvalidateParent()

            coroutine.wait( 0 )
    
            local label = vgui.Create( "DLabel", panel )
            label:SetFont( "crackdown2_dropmenutext2" )
            label:SetSize( 100, 50 )
            label:SetColor( Color( 218, 103, 10 ) )
            label:SetText( "  UNAVAILABLE" )
            label:Dock( TOP )

            local statsholder = vgui.Create( "DPanel", panel )
            statsholder:SetSize( 100, panel:GetTall() / 3 )
            statsholder:Dock( BOTTOM )

            local modelpanel = vgui.Create( "DModelPanel", panel )
            modelpanel:SetSize( 100, panel:GetTall() / 3 )
            modelpanel:SetModel( "models/error.mdl" )
            modelpanel:Dock( TOP )
            modelpanel:SetFOV( 50 )

            local ent = modelpanel:GetEntity()
            modelpanel:SetCamPos( Vector( -70, 70, 0 ) )
            modelpanel:SetLookAt( ent:OBBCenter() + Vector( 0, 0, 5 ) )

            local dmg 
            local range 
            local firerate
            local skilllevel
            local isexplosive

            -- Returns if the player can use this weapon
            function panel:PassesWeaponSkillTest()
                return ( !isequipment and !isexplosive ) and skilllevel and skilllevel <= plyweaponskill or ( isequipment or isexplosive ) and skilllevel and skilllevel <= plyexplosiveskill
            end

            function statsholder:Paint( w, h )
                surface_SetDrawColor( fadedwhite )
                surface_DrawOutlinedRect( 0, 0, w, h, 2 )
                draw_DrawText( !isequipment and "BULLET DAMAGE" or "DAMAGE", "crackdown2_weaponstattext", 10, 10, lightgrey, TEXT_ALIGN_LEFT )
                draw_DrawText( !isequipment and "EFFECTIVE RANGE" or "BLAST RADIUS", "crackdown2_weaponstattext", 10, 35, lightgrey, TEXT_ALIGN_LEFT )

                local scale = ScreenScale( 5 )

                if dmg then

                    for i = 1, 10 do
                        surface_SetDrawColor( blackish )
                        surface_DrawRect( ( panel:GetWide() / 2 ) + ( 20 * i ), 10, scale, scale )
                    end

                    for i = 1, dmg do
                        surface_SetDrawColor( orange )
                        surface_DrawRect( ( panel:GetWide() / 2 ) + ( 20 * i ), 10, scale, scale )
                    end
                end

                if range then

                    for i = 1, 10 do
                        surface_SetDrawColor( blackish )
                        surface_DrawRect( ( panel:GetWide() / 2 ) + ( 20 * i ), 35, scale, scale )
                    end
                    
                    for i = 1, range do
                        surface_SetDrawColor( orange )
                        surface_DrawRect( ( panel:GetWide() / 2 ) + ( 20 * i ), 35, scale, scale )
                    end
                end

                if !isequipment and firerate then

                    for i = 1, 10 do
                        surface_SetDrawColor( blackish )
                        surface_DrawRect( ( panel:GetWide() / 2 ) + ( 20 * i ), 60, scale, scale )
                    end

                    for i = 1, firerate do
                        surface_SetDrawColor( orange )
                        surface_DrawRect( ( panel:GetWide() / 2 ) + ( 20 * i ), 60, scale, scale )
                    end
                end

                if !isequipment then 
                    draw_DrawText( "FIRE RATE", "crackdown2_weaponstattext", 10, 60, lightgrey, TEXT_ALIGN_LEFT )
                end
            end

            local oldpaint = modelpanel.Paint

            function modelpanel:Paint( w, h )
                oldpaint( self, w, h )

                if ( !isequipment and !isexplosive ) and skilllevel and skilllevel > plyweaponskill then
                    draw_DrawText( "UNLOCKED AT FIREARMS LEVEL " .. skilllevel, "crackdown2_weaponstattext", 10, h - 20, lightgrey, TEXT_ALIGN_LEFT )
                elseif ( isequipment or isexplosive ) and skilllevel and skilllevel > plyexplosiveskill then
                    draw_DrawText( "UNLOCKED AT EXPLOSIVES LEVEL " .. skilllevel, "crackdown2_weaponstattext", 10, h - 20, lightgrey, TEXT_ALIGN_LEFT )
                end
            end

            function modelpanel:LayoutEntity() end

            function panel:SetWeaponData( data )
                label:SetText( "  " .. data.PrintName )
                modelpanel:SetModel( data.WorldModel )
                dmg = data.DropMenu_Damage
                range = data.DropMenu_Range
                firerate = data.DropMenu_FireRate
                skilllevel = data.DropMenu_SkillLevel
                isexplosive = data.IsExplosive
            end

            return panel
        end

        local detailtoppanel = CreateWeaponStatsPanel()
        local detailmidpanel =  CreateWeaponStatsPanel()
        local detailbottompanel =  CreateWeaponStatsPanel( true )

        function detailtoppanel:Paint( w, h ) 
            surface_SetDrawColor( fadedwhite )
            surface_DrawRect( 0, h - 2, w, 2 )
        end

        function detailbottompanel:Paint( w, h ) 
            surface_SetDrawColor( fadedwhite )
            surface_DrawRect( 0, 0, w, 2 )
        end

        function detailmidpanel:Paint( w, h ) 
        end

        local PRIMARYROW 
        local SECONDARYROW
        local EQUIPMENTROW
        
        -- Helper function
        local function CreateWeaponRow( text, varname, statpanel, isequipment )
            local variable = _G[ varname ]
            local weaponlist = {}
            local tblindex = 1

            if !isequipment then
                for k, v in pairs( weapons.GetList() ) do
                    if weapons.IsBasedOn( v.ClassName, "cd2_weaponbase" ) then
                        weaponlist[ #weaponlist + 1 ] = v
                    end
                end
            else
                for ClassName, v in pairs( scripted_ents.GetList() ) do
                    if v.Base == "cd2_equipmentbase" then
                        local tbl = v.t
                        tbl.ClassName = ClassName
                        weaponlist[ #weaponlist + 1 ] = tbl
                    end
                end
            end


            for k, v in ipairs( weaponlist ) do
                if v.ClassName == variable then
                    tblindex = k
                    break
                end
            end

            local label = vgui.Create( "DLabel", CD2_DropMenu )
            label:SetFont( "crackdown2_dropmenutext2" )
            label:SetSize( 100, 60 )
            label:SetColor( Color( 218, 103, 10) )
            label:SetText( "             " .. text )
            label:Dock( TOP )

            local row = vgui.Create( "DPanel", CD2_DropMenu )
            row:SetSize( 100, 150 )
            row:Dock( TOP )

            -- Returns the currently selected weapon
            function row:GetWeapon() 
                return variable
            end

            -- Returns the current table index
            function row:GetIndex()
                return tblindex
            end

            local function CreateWeaponHolder( isselectingpanel, indexadd )
                local variable = _G[ varname ]


                local panel = vgui.Create( "DPanel", row )
                panel:SetSize( ( ScrW() - 500 ) / 3, 150 )
                panel:Dock( LEFT )

                local mdlpanel = vgui.Create( "DModelPanel", panel )
                mdlpanel:SetModel( "models/error.mdl" )
                mdlpanel:DockMargin( 3, 3, 3, 3 )
                mdlpanel:Dock( FILL )
                mdlpanel:SetFOV( 60 )
                local ent = mdlpanel:GetEntity()
                mdlpanel:SetCamPos( Vector( 0, 70, 0 ) )
                mdlpanel:SetLookAt( ent:OBBCenter() )
                mdlpanel:InvalidateParent()

                coroutine.wait( 0 )

                local w, h = mdlpanel:GetSize()
                local lockicon = vgui.Create( "DImage", mdlpanel )
                lockicon:SetSize( 32, 32 )
                lockicon:SetPos( w - 32, 32 )
                lockicon:SetMaterial( lockiconmat )
                lockicon:Hide()

                function mdlpanel:DoClick()
                    if isselectingpanel then return end
                    tblindex = tblindex + indexadd
                    if PRIMARYROW == row and tblindex == SECONDARYROW:GetIndex() then tblindex = tblindex + ( tblindex > 0 and indexadd or -indexadd ) end
                    if SECONDARYROW == row and tblindex == PRIMARYROW:GetIndex() then tblindex = tblindex + ( tblindex > 0 and indexadd or -indexadd ) end
                    if tblindex == 0 then tblindex = #weaponlist elseif tblindex > #weaponlist then tblindex = 1 end
                    surface.PlaySound( "crackdown2/ui/ui_select.mp3" )
                end

                for k, v in ipairs( weaponlist ) do
                    if v.ClassName == variable then
                        ent = mdlpanel:GetEntity()
    
                        if IsValid( ent ) then
                            
                            
                            if v.IsEquipment and v.DropMenu_SkillLevel and v.DropMenu_SkillLevel > plyexplosiveskill then
                                lockicon:Show()
                            elseif !v.IsEquipment and v.DropMenu_SkillLevel and v.DropMenu_SkillLevel > plyweaponskill then
                                lockicon:Show()
                            else
                                lockicon:Hide()
                            end
                            
                            mdlpanel:SetModel( v.WorldModel )
                            mdlpanel:SetCamPos( Vector( 0, 70, 0 ) )
                            mdlpanel:SetLookAt( ent:OBBCenter() )
    
                            variable = v.ClassName
                            
                            if isselectingpanel then
                                _G[ varname ] = v.ClassName
                                statpanel:SetWeaponData( v )
                            end
                        end

                        break
                    end
                end



                function mdlpanel:LayoutEntity() end

                

                function panel:Think()
                    local sub = tblindex + indexadd
                    if sub == 0 then sub = #weaponlist elseif sub > #weaponlist then sub = 1 end

                    local wepdata = weaponlist[ sub ]

                    if wepdata and wepdata.ClassName != variable then
                        ent = mdlpanel:GetEntity()

                        if IsValid( ent ) then

                            if wepdata.IsEquipment and wepdata.DropMenu_SkillLevel and wepdata.DropMenu_SkillLevel > plyexplosiveskill then
                                lockicon:Show()
                            elseif !wepdata.IsEquipment and wepdata.DropMenu_SkillLevel and wepdata.DropMenu_SkillLevel > plyweaponskill then
                                lockicon:Show()
                            else
                                lockicon:Hide()
                            end

                            mdlpanel:SetModel( wepdata.WorldModel )
                            mdlpanel:SetCamPos( Vector( 0, 70, 0 ) )
                            mdlpanel:SetLookAt( ent:OBBCenter() )

                            variable = wepdata.ClassName

                            if isselectingpanel then
                                _G[ varname ] = wepdata.ClassName
                                statpanel:SetWeaponData( wepdata )
                            end
                        end

                    end
                end

                if isselectingpanel then
                    function panel:Paint( w, h )
                        surface_SetDrawColor( fadedwhite )
                        surface_DrawRect( 3, 0, 3, h )
            
                        surface_SetDrawColor( fadedwhite )
                        surface_DrawRect( w - 3, 0, 3, h )
                    end
                else
                    function panel:Paint( w, h ) end
                end

                return panel
            end

            CreateWeaponHolder( false, -1 )
            CreateWeaponHolder( true, 0 )
            CreateWeaponHolder( false, 1 )


            function row:Paint( w, h )
                surface_SetDrawColor( fadedwhite )
                surface_DrawRect( 0, 0, w, 3 )

                surface_SetDrawColor( fadedwhite )
                surface_DrawRect( 0, h - 3, w, 3 )
            end

            return row
        end

        
        local bottombuttonspanel = vgui.Create( "DPanel", CD2_DropMenu )
        bottombuttonspanel:DockMargin( 3, 3, 3, 3 )
        bottombuttonspanel:SetSize( 250, 30 )
        bottombuttonspanel:Dock( BOTTOM )
        bottombuttonspanel:InvalidateParent( true )

        function bottombuttonspanel:Paint() end

        coroutine.wait( 0 )

        local confirmbutton = vgui.Create( "DButton", bottombuttonspanel )
        confirmbutton:SetSize( bottombuttonspanel:GetWide(), 30 )
        confirmbutton:SetText( "CONFIRM" )
        confirmbutton:Dock( LEFT )

--[[         local backbutton = vgui.Create( "DButton", bottombuttonspanel )
        backbutton:SetSize( bottombuttonspanel:GetWide() / 2, 30 )
        backbutton:Dock( LEFT ) ]]
        
        
        PRIMARYROW = CreateWeaponRow( "PRIMARY", "CD2_DropPrimary", detailtoppanel )
        SECONDARYROW = CreateWeaponRow( "SECONDARY", "CD2_DropSecondary", detailmidpanel )
        EQUIPMENTROW = CreateWeaponRow( "EXPLOSIVE", "CD2_DropEquipment", detailbottompanel, true )
        
        function line:Paint( w, h )
            surface_SetDrawColor( color_white )
            surface_DrawRect( 0, 0, w, h )
        end

        function confirmbutton:Paint( w, h ) 
            surface_SetDrawColor( blackish )
            surface_DrawRect( 0, 0, w, h )
        end

        





        function confirmbutton:DoClick()
            local skilltest1 = detailtoppanel:PassesWeaponSkillTest()
            local skilltest2 = detailmidpanel:PassesWeaponSkillTest()
            local skilltest3 = detailbottompanel:PassesWeaponSkillTest()
            if !skilltest1 or !skilltest2 or !skilltest3 then surface.PlaySound( "buttons/button10.wav" ) return end
            CD2_DropMenu:Remove()

            CD2FILESYSTEM:WritePlayerData( "cd2_dropprimary", CD2_DropPrimary )
            CD2FILESYSTEM:WritePlayerData( "cd2_dropsecondary", CD2_DropSecondary )
            CD2FILESYSTEM:WritePlayerData( "cd2_dropequipment", CD2_DropEquipment )

            if !issupplypoint then
                net.Start( "cd2net_playerdropmenuconfirm" )
                net.WriteString( CD2_DropPrimary )
                net.WriteString( CD2_DropSecondary )
                net.WriteString( CD2_DropEquipment )
                net.WriteVector( CD2_SelectedSpawnPoint )
                net.WriteAngle( CD2_SelectedSpawnAngle )
                net.SendToServer()

                LocalPlayer().cd2_Equipment = CD2_DropEquipment
                LocalPlayer().cd2_lastspawnprimary = CD2_DropPrimary
                LocalPlayer().cd2_lastspawnsecondary = CD2_DropSecondary
            else
                net.Start( "cd2net_resupply" )
                net.WriteString( CD2_DropPrimary )
                net.WriteString( CD2_DropSecondary )
                net.WriteString( CD2_DropEquipment )
                net.SendToServer()

                LocalPlayer().cd2_Equipment = CD2_DropEquipment
                LocalPlayer().cd2_lastspawnprimary = CD2_DropPrimary
                LocalPlayer().cd2_lastspawnsecondary = CD2_DropSecondary
            end
        end

    end )

end






hook.Add( "Think", "crackdown2_regeneratemenu", function()
    local ply = LocalPlayer()

    if CD2_InDropMenu or CD2_InSpawnPointMenu or ply:Alive() then return end

    if ply:KeyPressed( IN_USE ) then
        if !CD2_InSpawnPointMenu then
            CD2OpenSpawnPointMenu()
        end
    elseif ply:KeyPressed( IN_RELOAD ) then
        net.Start( "cd2net_spawnatnearestspawn" )
        net.WriteString( CD2_DropPrimary )
        net.WriteString( CD2_DropSecondary )
        net.WriteString( CD2_DropEquipment )
        net.SendToServer()
    end

    -- Call for help --
    if ply:KeyDown( IN_FORWARD ) then
        ply.cd2_callforhelpdelay = ply.cd2_callforhelpdelay or CurTime() + 1
        ply.cd2_callforhelpcooldown = ply.cd2_callforhelpcooldown or 0

        if CurTime() > ply.cd2_callforhelpdelay and CurTime() > ply.cd2_callforhelpcooldown then
            net.Start( "cd2net_playercallforhelp" )
            net.SendToServer()
            CD2SetTextBoxText( "Call for help has been sent to other Agents" )
            ply.cd2_callforhelpcooldown = CurTime() + 10
        end
    else
        ply.cd2_callforhelpdelay = nil
    end

end )