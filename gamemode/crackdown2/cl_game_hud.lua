local table_insert = table.insert
local math = math
local surface = surface
local clamp = math.Clamp
local ceil = math.ceil
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine
local draw_DrawText = draw.DrawText
local Trace = util.TraceLine
local surface_SetMaterial = surface.SetMaterial
local surface_DrawRect = surface.DrawRect
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local shadedwhite = Color( 177, 177, 177 )
local red = Color( 163, 12, 12)
local orangeish = Color( 202, 79, 22)
local blackish = Color( 39, 39, 39)
local black = Color( 0, 0, 0 )
local grey = Color( 61, 61, 61)
local linecol = Color( 61, 61, 61, 100 )
local surface_DrawCircle = surface.DrawCircle
local input_GetKeyName = input.GetKeyName
local render_SetMaterial = render.SetMaterial
local render_DrawSprite = render.DrawSprite
local beaconblue = Color( 0, 217, 255 )
local weaponskillcolor = Color( 0, 225, 255)
local strengthskillcolor = Color( 255, 251, 0)
local explosiveskillcolor = Color( 0, 110, 255 )
local agilityskillcolor = Color( 72, 255, 0)

local cellwhite = Color( 255, 255, 255 )
local celltargetred = Color( 255, 51, 0 )

local hpred = Color( 163, 12, 12)


CD2_lockon = false

local function draw_Circle( x, y, radius, seg, rotate )
    rotate = rotate or 0
	local cir = {}

	table_insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -360 + rotate )
		table_insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( rotate ) -- This is needed for non math.absolute segment counts
	table_insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end


local function DrawSkillCircle( x, y, radius, arc, rotate )
    local seg = 30
	local cir = {}

	table_insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -arc + rotate )
		table_insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( rotate ) -- This is needed for non math.absolute segment counts
	table_insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end



function CD2DrawInputbar( x, y, keyname, text )

    surface_SetFont( "crackdown2_font30" )
    local sizex = surface_GetTextSize( text )

    draw.NoTexture()
    surface_SetDrawColor( blackish )
    surface_DrawRect( x, y - 15, sizex + 30, 30 )
    
    surface_SetDrawColor( grey )
    draw_Circle( x, y, 20, 6 )

    draw_DrawText( keyname, "crackdown2_font30", x, y - 15, color_white, TEXT_ALIGN_CENTER )

    draw_DrawText( text, "crackdown2_font30", x + 20, y - 17, color_white, TEXT_ALIGN_LEFT )
    
end

local fireicon = Material( "crackdown2/ui/explosive.png" )

local pingtimes
local pinglocation
local canping = true
local pingscale = 0
local hplerp = -1
local shieldlerp = -1
local hlerp1
local hlerp2
local peacekeeper = Material( "crackdown2/ui/peacekeeper.png", "smooth" )
local cell = Material( "crackdown2/ui/cell.png", "smooth" )
local beaconicon = Material( "crackdown2/ui/beacon.png" )
local Auicon = Material( "crackdown2/ui/auicon.png" )
local upicon = Material( "crackdown2/ui/up.png", "smooth" )
local heloicon = Material( "crackdown2/ui/helo.png", "smooth" )
local downicon = Material( "crackdown2/ui/down.png", "smooth" )
local skillcircle = Material( "crackdown2/ui/skillcircle.png" )
local staricon = Material( "crackdown2/ui/star.png", "smooth" )
local FreakIcon = Material( "crackdown2/ui/freak.png", "smooth" )
local hex = Material( "crackdown2/ui/hex.png", "smooth" )
local agentdown = Material( "crackdown2/ui/agentdown.png", "smooth" )

local skillglow = Material( "crackdown2/ui/skillglow2.png" )
local agilityicon = Material( "crackdown2/ui/agilityicon.png", "smooth" )
local weaponicon = Material( "crackdown2/ui/weaponicon.png", "smooth" )
local strengthicon = Material( "crackdown2/ui/strengthicon.png", "smooth" )
local explosiveicon = Material( "crackdown2/ui/explosiveicon.png", "smooth" )
--local drivingicon = Material( "crackdown2/ui/drivingicon.png", "smooth" )

local pingmat = Material( "crackdown2/ui/pingcircle.png" )
-- Minimap vars
local minimapRT = GetRenderTarget( "crackdown2_minimaprt", 1024, 1024 )
local mmTrace = {}
local addfov = 0
local playerarrow = Material( "crackdown2/ui/playerarrow.png" )
local cellicon = Material( "crackdown2/ui/celltrackericon.png" )
local minimapRTMat = CreateMaterial( "crackdown2_minimapmaterial", "UnlitGeneric", {
	["$basetexture"] = "crackdown2_minimaprt",
	["$translucent"] = 1,
	["$vertexcolor"] = 1
} )

local function WorldVectorToScreen2( pos, origin, rotation, scale, radius )
    local relativePosition = pos - origin

    relativePosition:Rotate( Angle( 0, -rotation, 0 ) )

    local angle = math.atan2( relativePosition.y, relativePosition.x )
    angle = math.deg( angle )

    local distance = relativePosition:Length()

    local x = math.cos( math.rad( angle ) ) * distance * scale
    local y = math.sin( math.rad( angle ) ) * distance * scale

    sqr = math.sqrt( x ^ 2 + y ^ 2 )

    if sqr > radius then
        local angle = math.atan2( y, x )
        x = math.cos( angle ) * radius
        y = math.sin( angle ) * radius
    end

    return Vector( x, y )
end

function CD2PingLocationTracker( pos )
    canping = true
    pinglocation = pos
    pingtimes = 0
    pingscale = 0
end

local function DrawCoordsOnMiniMap( pos, ang, icon, iconsize, color, fov )
    local radius = ScreenScale( 45 )
    pos[ 3 ] = 0
    local plypos = LocalPlayer():GetPos() plypos[ 3 ] = 0
    
    local _, angs = WorldToLocal( pos, Angle( 0, ang[ 2 ], 0 ), LocalPlayer():GetPos(), CD2_viewangles )

    surface_SetDrawColor( color or color_white )
    surface_SetMaterial( icon or playerarrow )

    local vec = WorldVectorToScreen2( pos, plypos, CD2_viewangles[ 2 ] - 90, radius / ( fov * 170 ), radius ) --WorldVectorToScreen( pos, plypos, 0.2, CD2_viewangles[ 2 ] - 90, radius, fov )
    surface.DrawTexturedRectRotated( 200 + vec[ 1 ], ( ScrH() - 200 ) - vec[ 2 ], ScreenScale( iconsize ), ScreenScale( iconsize ), ( angs[ 2 ] ) )
end

local skillvars = {}

local function DrawSkillHex( x, y, icon, level, xp, col, skillname )
    skillvars[ skillname ] = skillvars[ skillname ] or {}
    skillvars[ skillname ].col = skillvars[ skillname ].col or col

    draw.NoTexture()

    -- Outlined circle pathing behind each skill dot
    surface_DrawCircle( x, y, 30, 0, 0, 0 )

    surface_SetDrawColor( color_white )
    surface_SetMaterial( skillcircle )

    -- White circle pathing behind each skill dot
    DrawSkillCircle( x, y, 33, Lerp( xp / 100, ( 55 * level ), ( 55 * ( level + 1 ) ) ) , -160 )

    draw.NoTexture()

    surface_SetDrawColor( blackish )
    draw_Circle( x, y, 25, 6, 30 ) -- Base hex

    if icon then
        surface_SetDrawColor( color_white )
        surface_SetMaterial( icon )
        draw_Circle( x, y, 30, 6, 30 )
    end

    draw.NoTexture()

    local dotsize = 6
    
    -- Top left dot
    surface_SetDrawColor( level == 6 and orangeish or blackish )
    draw_Circle( x - 15, y - 25, dotsize, 20, 0 )
    surface_DrawCircle( x - 15, y - 25, dotsize, 160, 160, 160, 30 )

    -- Top right dot
    surface_SetDrawColor( level >= 1 and orangeish or blackish )
    draw_Circle( x + 15, y - 25, dotsize, 20, 0 )
    surface_DrawCircle( x + 15, y - 25, dotsize, 160, 160, 160, 30 )

    -- Right dot
    surface_SetDrawColor( level >= 2 and orangeish or blackish )
    draw_Circle( x + 30, y, dotsize, 20, 0 )
    surface_DrawCircle( x + 30, y, dotsize, 160, 160, 160, 30 )

    -- Left dot
    surface_SetDrawColor( level >= 5 and orangeish or blackish )
    draw_Circle( x - 30, y, dotsize, 20, 0 )
    surface_DrawCircle( x - 30, y, dotsize, 160, 160, 160, 30 )

    -- Bottom left dot
    surface_SetDrawColor( level >= 4 and orangeish or blackish )
    draw_Circle( x - 15, y + 25, dotsize, 20, 0 )
    surface_DrawCircle( x - 15, y + 25, dotsize, 160, 160, 160, 30 )

    -- Bottom right dot
    surface_SetDrawColor( level >= 3 and orangeish or blackish )
    draw_Circle( x + 15, y + 25, dotsize, 20, 0 )
    surface_DrawCircle( x + 15, y + 25, dotsize, 160, 160, 160, 30 )

    skillvars[ skillname ].col.a = Lerp( 3 * FrameTime(), skillvars[ skillname ].col.a, 0 )

    if skillvars[ skillname ].col.a > 5 then
        surface_SetDrawColor( skillvars[ skillname ].col )
        surface_SetMaterial( skillglow )
        draw_Circle( x, y, 40, 50, 30 )
    end

    if xp != skillvars[ skillname ].lastxp then
        skillvars[ skillname ].col.a = 255
    end
    
    skillvars[ skillname ].lastxp = xp
end


local function RemoveHUDpanels()
    if IsValid( CD2_weaponpnl ) then CD2_weaponpnl:Remove() end
    if IsValid( CD2_equipmentpnl ) then CD2_equipmentpnl:Remove() end
end

CD2_CheapMinimap = true

CD2_DrawTargetting = true -- Draws crosshair and target healthbars
CD2_DrawHealthandShields = true -- Draws health and shields bars
CD2_DrawWeaponInfo = true -- Draws weapon info and equipment
CD2_DrawMinimap = true -- Draws the tracker
CD2_DrawBlackbars = false -- Draws the top and bottom black bars

CD2_DrawAgilitySkill = true
CD2_DrawFirearmSkill = true
CD2_DrawStrengthSkill = true
CD2_DrawExplosiveSkill = true

hook.Add( "HUDPaint", "crackdown2_hud", function()
    local scrw, scrh, ply = ScrW(), ScrH(), LocalPlayer()
    if CD2_InDropMenu or IsValid( CD2_AgencyConsole ) then RemoveHUDpanels() return end
    if !CD2_DrawWeaponInfo then RemoveHUDpanels() end

    if !game.SinglePlayer() and GetConVar( "cd2_drawhud" ):GetBool() then
        for k, v in ipairs( player.GetAll() ) do
            if v == LocalPlayer() or !v:IsCD2Agent() then continue end
            local ent = IsValid( v:GetRagdollEntity() ) and v:GetRagdollEntity() or v
            local screen = ( ent:GetPos() + Vector( 0, 0, 100 ) ):ToScreen()
            draw_DrawText( v:Name(), "crackdown2_agentnames", screen.x, screen.y, v:GetPlayerColor():ToColor(), TEXT_ALIGN_CENTER )

            if !v:Alive() then 
                local screen = ( ent:GetPos() + Vector( 0, 0, 10 ) ):ToScreen()
                surface_SetMaterial( agentdown )
                surface_SetDrawColor( color_white )
                surface.DrawTexturedRect( screen.x - 65, screen.y - 25, 130, 70 )
            end
        end
    end

    if CD2_InSpawnPointMenu or !ply:IsCD2Agent() then RemoveHUDpanels() return end

    if CD2_DrawBlackbars then
        hlerp1 = hlerp1 or -150
        hlerp2 = hlerp2 or scrh

        hlerp1 = Lerp( 2 * FrameTime(), hlerp1, 0 )
        hlerp2 = Lerp( 2 * FrameTime(), hlerp2, scrh - 150 )

        surface_SetDrawColor( black )

        surface_DrawRect( 0, hlerp1, scrw, 150 )
        surface_DrawRect( 0, hlerp2, scrw, 150 )
    else
        hlerp1 = -100
        hlerp2 = scrh
    end

    if !ply:Alive() then 
        local usebind = input.LookupBinding( "+use" ) or "e"
        local code = input.GetKeyCode( usebind )
        local buttonname = input_GetKeyName( code )

        local reloadbind = input.LookupBinding( "+reload" ) or "r"
        local rcode = input.GetKeyCode( reloadbind )
        local reloadname = input_GetKeyName( rcode )
        

        CD2DrawInputbar( scrw / 2.1, 200, string.upper( buttonname ), "Regenerate" )
        CD2DrawInputbar( scrw / 2, 250, string.upper( reloadname ), "Regenerate at nearest spawn" )

        if #player.GetAll() > 1 then
            local fbind = input.LookupBinding( "+forward" ) or "w"
            local fcode = input.GetKeyCode( fbind )
            local forwardname = input_GetKeyName( fcode )

            CD2DrawInputbar( scrw / 1.9, 300, string.upper( forwardname ), "Hold to call for help" )
        end

        RemoveHUDpanels()
        return 
    end

    if !GetConVar( "cd2_drawhud" ):GetBool() then RemoveHUDpanels() return end 

    -- Crosshair --
    if CD2_DrawTargetting then
        draw.NoTexture()
        surface_SetDrawColor( !CD2_lockon and shadedwhite or red )
        draw_Circle( scrw / 2, scrh / 2, 2, 30 )

        if CD2_lockon then
            local target = ply:GetNW2Entity( "cd2_lockontarget", nil )
            surface_DrawLine( ( scrw / 2 ), ( scrh / 2 ) + 10, ( scrw / 2 ), ( scrh / 2 ) + 20 )
            surface_DrawLine( ( scrw / 2 ), ( scrh / 2 ) - 10, ( scrw / 2 ), ( scrh / 2 ) - 20 )
            surface_DrawLine( ( scrw / 2 ) + 10, ( scrh / 2 ), ( scrw / 2 ) + 20, ( scrh / 2 ) )
            surface_DrawLine( ( scrw / 2 ) - 10, ( scrh / 2 ), ( scrw / 2 ) - 20, ( scrh / 2 ) )

            if IsValid( target ) then
                local spread = ply:GetLockonSpreadDecay() * 500
                surface_SetDrawColor( shadedwhite )
                surface_SetMaterial( hex )
                surface.DrawTexturedRectRotated( ( scrw / 2 ), ( scrh / 2 ), spread, spread, ( SysTime() * 300 ) )
            end
        end
    end
    ------
    
    

    
    
    
    -- Skill Counters --
    if CD2_DrawAgilitySkill then DrawSkillHex( 130, 170, agilityicon, ply:GetAgilitySkill(), ply:GetAgilityXP(), agilityskillcolor, "Agility" ) end
    if CD2_DrawFirearmSkill then DrawSkillHex( 130, 170 * 1.5, weaponicon, ply:GetWeaponSkill(), ply:GetWeaponXP(), weaponskillcolor, "Weapon" ) end
    if CD2_DrawStrengthSkill then DrawSkillHex( 130, 170 * 2, strengthicon, ply:GetStrengthSkill(), ply:GetStrengthXP(), strengthskillcolor, "Strength" ) end
    if CD2_DrawExplosiveSkill then DrawSkillHex( 130, 170 * 2.5, explosiveicon, ply:GetExplosiveSkill(), ply:GetExplosiveXP(), explosiveskillcolor, "Explosive" ) end
    ------


    -- Health and Shields --
    if CD2_DrawHealthandShields then
        local hp, shield, maxshields, hpbars = ply:Health(), clamp( ply:Armor(), 0, 100 ), ply:GetMaxArmor(), ( ceil( ply:Health() / 100 ) )

        hplerp = hplerp == -1 and hp or hplerp
        shieldlerp = shieldlerp == -1 and shield or shieldlerp

        local modulate =  ( ( hp % 100 ) / 100 ) * ScreenScale( 96 )
        hplerp = Lerp( 30 * FrameTime(), hplerp, modulate == 0 and ScreenScale( 96 ) or modulate)
        shieldlerp = Lerp( 30 * FrameTime(), shieldlerp, ( shield / maxshields ) * ScreenScale( 96 ) )

        surface_SetDrawColor( blackish )
        surface_DrawRect( 70, 50, ScreenScale( 100 ), 35 )

        if hpbars > 1 then
            surface_SetDrawColor( blackish )
            surface_DrawRect( 70, 80, ScreenScale( 30 ), 13 )

            for i = 1, hpbars do
                if i == 1 then continue end
                draw.NoTexture()
                surface_SetDrawColor( orangeish )
                draw_Circle( 60 + ( 20 * ( i - 1 ) ), 90, ceil( ScreenScale( 2.5 ) ), 6, 30 )
            end
        end


        surface_SetDrawColor( color_white )
        surface_DrawRect( 75, 55, shieldlerp, 10 )

        if hpbars == 1 then
            hpred.r = math.max( 30, ( math.abs( math.sin( SysTime() * 1.5 ) * 163 ) ), ( math.abs( math.cos( SysTime() * 1.5 ) * 163 ) ) )
            hpred.g = ( math.abs( math.sin( SysTime() * 1.5 ) * 12 ) )
            hpred.b = ( math.abs( math.sin( SysTime() * 1.5 ) * 12 ) )
        end

        surface_SetDrawColor( hpbars > 1 and orangeish or hpred  )
        surface_DrawRect( 75, 70, hplerp, 10 )
    end
    ------


    -- Weapon Info --
    if CD2_DrawWeaponInfo then
        local weapon = ply:GetActiveWeapon()

        if IsValid( weapon ) then
            local mdl = weapon:GetWeaponWorldModel()

            surface_SetDrawColor( blackish )
            surface_DrawRect( scrw - 400, scrh - 130, 300, 30 )

            surface_SetDrawColor( blackish )
            surface_DrawRect( scrw - 100, scrh - 140, 70, 40 )

            surface_SetDrawColor( blackish )
            surface_DrawRect( scrw - 400, scrh - 100, 300, 60 )

            draw_DrawText( weapon.Ammo1 and weapon:Ammo1() or "NONE", "crackdown2_font40", scrw - 35, scrh - 140, color_white, TEXT_ALIGN_RIGHT )


            for i = 1, weapon:Clip1() do
                local wscale = 300 / weapon:GetMaxClip1()
                local x = ( scrw - 395 ) + ( wscale * ( i - 1 ) )
                if x >= scrw - 395 and x + wscale / 2 <= scrw - 100 then
                    surface_SetDrawColor(color_white)
                    surface_DrawRect(x, scrh - 125, ceil( wscale / 2 ), 20)
                end
            end

            if !IsValid( CD2_weaponpnl ) then
                CD2_weaponpnl = vgui.Create( "DModelPanel", GetHUDPanel() )
                CD2_weaponpnl:SetModel( mdl )
                CD2_weaponpnl:SetPos( scrw - 400 , scrh - 100 )
                CD2_weaponpnl:SetSize( 300, 60 )
                CD2_weaponpnl:SetFOV( 50 )
        
                local ent = CD2_weaponpnl:GetEntity()
                ent:SetMaterial( "models/debug/debugwhite" )
                CD2_weaponpnl:SetCamPos( Vector( 0, 80, 0 ) )
                CD2_weaponpnl:SetLookAt( ent:OBBCenter() )
                
        
                local thinkpanel = vgui.Create( "DPanel", CD2_weaponpnl )
        
                function CD2_weaponpnl:PostDrawModel( ent ) 
                    render.SuppressEngineLighting( false )
                end
        
                function CD2_weaponpnl:PreDrawModel( ent ) 
                    render.SuppressEngineLighting( true )
                end
                function CD2_weaponpnl:LayoutEntity() end
                function thinkpanel:Paint( w, h ) end
                function thinkpanel:Think()
                    if CD2_InDropMenu or !ply:IsCD2Agent() or CD2_InSpawnPointMenu or !ply:Alive() then self:GetParent():Remove() return end
                    local wep = ply:GetActiveWeapon()
                    if IsValid( CD2_weaponpnl ) and IsValid( wep ) then local ent = CD2_weaponpnl:GetEntity() ent:SetModel( wep:GetWeaponWorldModel() ) CD2_weaponpnl:SetLookAt( ent:OBBCenter() ) end
                    
                    if CD2_weaponpnl != self:GetParent() then
                        self:GetParent():Remove()
                    end
                end
            end


            surface_SetDrawColor( blackish )
            surface_DrawRect( scrw - 120, scrh - 100, 90, 60 )
    
    
            surface_SetDrawColor( linecol )
            surface.DrawOutlinedRect( scrw - 120, scrh - 100, 90, 60, 2 )
            surface.DrawOutlinedRect( scrw - 100, scrh - 140, 70, 40, 2 )
            surface.DrawOutlinedRect( scrw - 400, scrh - 130, 300, 30, 2 )
            surface.DrawOutlinedRect( scrw - 400, scrh - 100, 280, 60, 2 )

            if !IsValid( CD2_equipmentpnl ) then
                local mdl = scripted_ents.Get( ply:GetEquipment() ).WorldModel
    
                CD2_equipmentpnl = vgui.Create( "DModelPanel", GetHUDPanel() )
                CD2_equipmentpnl:SetModel( mdl )
                CD2_equipmentpnl:SetPos( scrw - 135 , scrh - 85 )
                CD2_equipmentpnl:SetSize( 64, 64 )
                CD2_equipmentpnl:SetFOV( 60 )
    
                local ent = CD2_equipmentpnl:GetEntity()
                ent:SetMaterial( "models/debug/debugwhite" )
                CD2_equipmentpnl:SetCamPos( Vector( 0, 15, 0 ) )
                CD2_equipmentpnl:SetLookAt( ent:OBBCenter() )
                
    
                local thinkpanel = vgui.Create( "DPanel", CD2_equipmentpnl )
    
                function CD2_equipmentpnl:PostDrawModel( ent ) 
                    render.SuppressEngineLighting( false )
                end
    
                function CD2_equipmentpnl:PreDrawModel( ent ) 
                    render.SuppressEngineLighting( true )
                end
                function CD2_equipmentpnl:LayoutEntity() end
                function thinkpanel:Paint( w, h ) end
                function thinkpanel:Think()
                    if CD2_InDropMenu or !ply:IsCD2Agent() or CD2_InSpawnPointMenu or !ply:Alive() then self:GetParent():Remove() return end
    
                    if IsValid( CD2_equipmentpnl ) then
                        local mdl = scripted_ents.Get( ply:GetEquipment() ).WorldModel
                        local ent = CD2_equipmentpnl:GetEntity()
    
                        if IsValid( ent ) and ent:GetModel() != mdl then ent:SetModel( mdl ) end
                    end
                    
    
                    if CD2_equipmentpnl != self:GetParent() then
                        self:GetParent():Remove()
                    end
                end
            end
    
            draw_DrawText( ply:GetEquipmentCount(), "crackdown2_font45", scrw - 60, scrh - 90, color_white, TEXT_ALIGN_CENTER )

        end

        
    end
    ------


    -- Lock on Entity health bars --
    if CD2_DrawTargetting then
        local lockables = CD2FindInLockableTragets( ply )
        local target = ply.cd2_lockontarget or lockables[ 1 ]

        if IsValid( target ) then 
            local toscreen = ( target:GetPos() + Vector( 0, 0, target:GetModelRadius() ) ):ToScreen()
        
            surface_SetDrawColor( blackish )
            surface_DrawRect( toscreen.x - 30, toscreen.y, 60, 12 )

            surface_SetDrawColor( orangeish )
            surface_DrawRect( toscreen.x - 28, toscreen.y + 2, ( target:GetNW2Float( "cd2_health", 0 ) / target:GetMaxHealth() ) * 56, 8 )
        
        end
    end
    ------


    -- MiniMap --
    if CD2_DrawMinimap then
        local fov = 15

        if !CD2_CheapMinimap then
            local vel = ply:GetVelocity():Length()
            vel = vel > 500 and vel or 0
            addfov = Lerp( 1 * FrameTime(), addfov, vel % 10 )

            render.PushRenderTarget( minimapRT )

                mmTrace.start = ply:WorldSpaceCenter()
                mmTrace.endpos = ply:GetPos() + Vector( 0, 0, 20000 )
                mmTrace.mask = MASK_SOLID_BRUSHONLY
                mmTrace.collisiongroup = COLLISION_GROUP_WORLD
                local result = Trace( mmTrace )
                fov = 15 + addfov

                render.RenderView( {
                    origin = ply:GetPos() + Vector( 0, 0, 20000 ),
                    angles = Angle( 90, CD2_viewangles[ 2 ], 0 ),
                    znear = result.Hit and result.HitPos:Distance( mmTrace.endpos ) or 10,
                    fov = fov,
                    x = 0, y = 0,
                    w = 1024, h = 1024
                } )

            render.PopRenderTarget()
        end

        draw.NoTexture()
        surface_SetDrawColor( blackish )
        draw_Circle( 200, scrh - 200, ScreenScale( 50 ), 30 )

        if !CD2_CheapMinimap then
            surface_SetDrawColor( color_white )
            surface_SetMaterial( minimapRTMat )
            draw_Circle( 200, scrh - 200, ScreenScale( 50 ) - 10, 30 )
        end

        if pingtimes then
            
            if pingtimes == 3 then
                pingtimes = nil
            else
                pingscale = Lerp( 3.5 * FrameTime(), pingscale, 40 )
                DrawCoordsOnMiniMap( pinglocation, CD2_viewangles, pingmat, pingscale, cellwhite, fov )

                if canping then
                    surface.PlaySound( "crackdown2/ui/ping.mp3" )
                    canping = false
                end
            end



            if pingscale > 35 then
                canping = true
                pingscale = 0
                pingtimes = pingtimes + 1
            end
        end

        surface_SetDrawColor( ply:GetPlayerColor():ToColor() )
        surface_SetMaterial( playerarrow )
        local _, angle = WorldToLocal( Vector(), ply:GetAngles(), ply:GetPos(), CD2_viewangles )
        surface.DrawTexturedRectRotated( 200, scrh - 200, ScreenScale( 10 ), ScreenScale( 10 ), angle[ 2 ] )

        local nearbyminimap = CD2FindInSphere( LocalPlayer():GetPos(), 3500, function( ent ) return ent:IsCD2NPC() and ent:GetCD2Team() == "cell" end )

        -- Cell --
        for i = 1, #nearbyminimap do
            local ent = nearbyminimap[ i ]
            local z = ent:GetPos().z
            local icon = z > ply:GetPos().z + 50 and upicon or z < ply:GetPos().z - 50 and downicon or cellicon
            DrawCoordsOnMiniMap( ent:GetPos(), CD2_viewangles, icon, 4, ent:GetEnemy() == ply and celltargetred or cellwhite, fov )
        end
        --
        
        
        -- Tacticle Locations | Helicopters | ect --
        local ents_ = ents.FindByClass( "cd2_*" )
        for i = 1, #ents_ do
            local ent = ents_[ i ]
    
            if IsValid( ent ) and ent:GetClass() == "cd2_locationmarker" and ( ent:SqrRangeTo( LocalPlayer() ) < ( 6000 * 6000 ) or ent:GetLocationType() == "beacon" ) then 
                DrawCoordsOnMiniMap( ent:GetPos(), Angle( 0, CD2_viewangles[ 2 ], 0 ), ent:GetLocationType() == "beacon" and beaconicon or ent:GetLocationType() == "cell" and cell or peacekeeper, ent:GetLocationType() == "beacon" and 20 or 10, ent:GetLocationType() == "cell" and celltargetred or color_white, fov )
            elseif IsValid( ent ) and ent:GetClass() == "cd2_agencyhelicopter" and ent:SqrRangeTo( LocalPlayer() ) < ( 6000 * 6000 ) then
                DrawCoordsOnMiniMap( ent:GetPos(), ent:GetAngles(), heloicon, 15, color_white, fov )
            elseif IsValid( ent ) and ent:GetClass() == "cd2_au" and !ent:GetActive() then
                DrawCoordsOnMiniMap( ent:GetPos(), Angle( 0, CD2_viewangles[ 2 ], 0 ), Auicon, 10, color_white, fov )
            elseif IsValid( ent ) and ent:GetClass() == "cd2_towerbeacon" and !ent:GetIsDetonated() and ent:CanBeActivated() then
                DrawCoordsOnMiniMap( ent:GetPos(), Angle( 0, CD2_viewangles[ 2 ], 0 ), staricon, 10, beaconblue, fov )
            elseif IsValid( ent ) and ent:IsCD2NPC() and ent:GetCD2Team() == "freak" and IsValid( ent:GetEnemy() ) and ( ( ent:GetEnemy():GetNWBool( "cd2_beaconpart", false ) or ent:GetEnemy():GetClass() == "cd2_beacon" ) or ( ent:GetEnemy():GetNWBool( "cd2_towerbeaconpart", false ) ) ) then
                DrawCoordsOnMiniMap( ent:GetPos(), Angle( 0, CD2_viewangles[ 2 ], 0 ), FreakIcon, 10, color_white, fov )
            end
        end
        --
        
        -- Players --
        local players = player.GetAll()

        for i = 1, #players do
            local otherplayer = players[ i ]
            if IsValid( otherplayer ) and otherplayer:IsCD2Agent() and otherplayer != ply then
                DrawCoordsOnMiniMap( otherplayer:GetPos(), otherplayer:EyeAngles(), otherplayer:Alive() and playerarrow or agentdown, 10, otherplayer:GetPlayerColor():ToColor(), fov )
            end
        end
        --
        
        

    end
    ------

end )

local explosivemodels = {
    [ "models/props_c17/oildrum001_explosive.mdl" ] = true,
    [ "models/props_junk/gascan001a.mdl" ] = true
}

-- Peacekeeper/Cell logos --
hook.Add( "PreDrawEffects", "crackdown2_peacekeepericons/cellicons", function()
    local ply = LocalPlayer()
    if CD2_InDropMenu or !ply:IsCD2Agent() or CD2_InSpawnPointMenu or !ply:Alive() then return end
    

    -- Peacekeeper --
    local near = CD2FindInSphere( ply:GetPos(), 1500, function( ent ) return ent:IsCD2NPC() and ent:GetCD2Team() == "agency" end )

    for i = 1, #near do
        local v = near[ i ]
        render_SetMaterial( peacekeeper )
        render_DrawSprite( v:GetPos() + Vector( 0, 0, 100 ), 32, 20, color_white )
    end
    ----

    -- Explosives --
    local near = CD2FindInSphere( ply:GetPos(), 1500, function( ent ) return explosivemodels[ ent:GetModel() ] end )

    for i = 1, #near do
        local v = near[ i ]
        render_SetMaterial( fireicon )
        render_DrawSprite( v:GetPos() + Vector( 0, 0, v:GetModelRadius() + 40 ), 16, 16, color_white )
    end
    ----

    -- Cell --
    local near = CD2FindInSphere( ply:GetPos(), 1500, function( ent ) return ent:IsCD2NPC() and ent:GetCD2Team() == "cell" end )

    for i = 1, #near do
        local v = near[ i ]
        render_SetMaterial( cell )
        render_DrawSprite( v:GetPos() + Vector( 0, 0, 100 ), 16, 16, red )
    end
    ----
end )
----



local HUDBlock = {
    [ "CHudAmmo" ] = true,
    [ "CHudBattery" ] = true,
    [ "CHudHealth" ] = true,
    [ "CHudSecondaryAmmo" ] = true,
    [ "CHudWeapon" ] = true,
    [ "CHudZoom" ] = true,
    [ "CHudSuitPower" ] = true,
    [ "CHUDQuickInfo" ] = true,
    [ "CHudCrosshair" ] = true,
    [ "CHudDamageIndicator" ] = true,
    [ "CHudWeaponSelection" ] = true
}

hook.Add( "HUDShouldDraw", "crackdown2_hidehuds", function( name )
    if HUDBlock[ name ] then return false end
end )

local modify = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 1,
	[ "$pp_colour_mulr" ] = 0,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0
}

hook.Add( "RenderScreenspaceEffects", "crackdown2_lowhealthcolors", function()
    local ply = LocalPlayer()

    if CD2IsDay() then
        modify[ "$pp_colour_brightness" ] = Lerp( 0.1 * FrameTime(), modify[ "$pp_colour_brightness" ], 0 )
    else
        modify[ "$pp_colour_brightness" ] = Lerp( 0.1 * FrameTime(), modify[ "$pp_colour_brightness" ], -0.2 )
    end
    
    if !ply:IsCD2Agent() then return end

    if ply:Alive() and ply:GetNWHealth() < 70 then
        modify[ "$pp_colour_addr" ] = Lerp( 2 * FrameTime(), modify[ "$pp_colour_addr" ], 0.15 )
    else
        modify[ "$pp_colour_addr" ] = Lerp( 2 * FrameTime(), modify[ "$pp_colour_addr" ], 0 )
    end

    if !ply:Alive() and !CD2_InSpawnPointMenu then
        DrawBokehDOF( 5, 0, 1 )
    end
    
    DrawColorModify( modify )
end )

hook.Add( "NeedsDepthPass", "crackdown2_bokehdepthpass", function()
    return !LocalPlayer():Alive()
end )

-- Connect messages --
hook.Add( "PlayerConnect", "crackdown2_connectmessage", function( name )
    if game.SinglePlayer() then return end
    CD2SetTextBoxText( name .. " joined the game" )
end )

gameevent.Listen( "player_disconnect" )

hook.Add( "player_disconnect", "crackdown2_disconnectmessage", function( data )
    if game.SinglePlayer() then return end
    CD2SetTextBoxText( data.name .. " left the game (" .. data.reason .. ")"  )
end )