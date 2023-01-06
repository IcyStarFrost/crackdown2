local table_insert = table.insert
local math_rad = math.rad
local math_sin = math.sin
local math_cos = math.cos
local clamp = math.Clamp
local ceil = math.ceil
local surface_DrawPoly = surface.DrawPoly
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine
local FrameTime = FrameTime
local draw_DrawText = draw.DrawText
local Lerp = Lerp
local ScreenScale = ScreenScale
local upper = string.upper
local Trace = util.TraceLine
local surface_SetMaterial = surface.SetMaterial
local surface_DrawRect = surface.DrawRect
local player_GetAll = player.GetAll
local draw_NoTexture = draw.NoTexture
local IsValid = IsValid
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local table_Copy = table.Copy
local shadedwhite = Color( 177, 177, 177 )
local red = Color( 163, 12, 12)
local orangeish = Color( 202, 79, 22)
local blackish = Color( 39, 39, 39)
local black = Color( 0, 0, 0 )
local grey = Color( 61, 61, 61)
local linecol = Color( 61, 61, 61, 100 )
local math_cos = math.cos
local math_sin = math.sin
local ipairs = ipairs
local SysTime = SysTime
local surface_DrawCircle = surface.DrawCircle
local abs = math.abs
local surface_DrawTexturedRect = surface.DrawTexturedRect
local WorldToLocal = WorldToLocal
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local input_LookupBinding = input.LookupBinding
local input_GetKeyCode = input.GetKeyCode
local math_max = math.max
local input_GetKeyName = input.GetKeyName
local render_SetMaterial = render.SetMaterial
local render_DrawSprite = render.DrawSprite
local weaponskillcolor = Color( 0, 225, 255)
local strengthskillcolor = Color( 255, 251, 0)
local explosiveskillcolor = Color( 0, 110, 255 )
local agilityskillcolor = Color( 72, 255, 0)
local math_atan2 = math.atan2
local math_deg = math.deg
local math_sqrt = math.sqrt

local cellwhite = Color( 255, 255, 255 )
local celltargetred = Color( 255, 51, 0 )

local hpred = Color( 163, 12, 12)


CD2_lockon = false

surface.CreateFont( "crackdown2_ammoreserve", {
    font = "Agency FB",
	extended = false,
	size = 40,
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

surface.CreateFont( "crackdown2_inputbarkey", {
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

surface.CreateFont( "crackdown2_equipmentcount", {
    font = "Agency FB",
	extended = false,
	size = 45,
	weight = 1000,
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

surface.CreateFont( "crackdown2_agentnames", {
    font = "Agency FB",
	extended = false,
	size = 20,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,

})

local function draw_Circle( x, y, radius, seg, rotate )
    rotate = rotate or 0
	local cir = {}

	table_insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math_rad( ( i / seg ) * -360 + rotate )
		table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )
	end

	local a = math_rad( rotate ) -- This is needed for non absolute segment counts
	table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )

	surface_DrawPoly( cir )
end


local function DrawSkillCircle( x, y, radius, arc, rotate )
    local seg = 30
	local cir = {}

	table_insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math_rad( ( i / seg ) * -arc + rotate )
		table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )
	end

	local a = math_rad( rotate ) -- This is needed for non absolute segment counts
	table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )

	surface_DrawPoly( cir )
end



function CD2DrawInputbar( x, y, keyname, text )

    surface_SetFont( "crackdown2_inputbarkey" )
    local sizex, sizey = surface_GetTextSize( text )

    draw_NoTexture()
    surface_SetDrawColor( blackish )
    surface_DrawRect( x, y - 15, sizex + 30, 30 )
    
    surface_SetDrawColor( grey )
    draw_Circle( x, y, 20, 6 )

    draw_DrawText( keyname, "crackdown2_inputbarkey", x, y - 15, color_white, TEXT_ALIGN_CENTER )

    draw_DrawText( text, "crackdown2_inputbarkey", x + 20, y - 17, color_white, TEXT_ALIGN_LEFT )
    
end

local explosives = {}
local fireicon = Material( "crackdown2/ui/explosive.png" )

local hplerp = -1
local shieldlerp = -1
local hlerp1
local hlerp2
CD2_equipmentpnl = nil
CD2_weaponpnl = nil
local peacekeeper = Material( "crackdown2/ui/peacekeeper.png", "smooth" )
local cell = Material( "crackdown2/ui/cell.png", "smooth" )
local skillcircle = Material( "crackdown2/ui/skillcircle.png" )
local hex = Material( "crackdown2/ui/hex.png", "smooth" )
local peacekeepertrace = {}


local skillglow = Material( "crackdown2/ui/skillglow2.png" )
local agilityicon = Material( "crackdown2/ui/agilityicon.png", "smooth" )
local weaponicon = Material( "crackdown2/ui/weaponicon.png", "smooth" )
local strengthicon = Material( "crackdown2/ui/strengthicon.png", "smooth" )
local explosiveicon = Material( "crackdown2/ui/explosiveicon.png", "smooth" )
--local drivingicon = Material( "crackdown2/ui/drivingicon.png", "smooth" )

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
--
local curfov = 90
function WorldVectorToScreen(worldVector, origin, scale, rotation, radius, fov )
    local relativePosition = worldVector - origin
    relativePosition = relativePosition * ( 60 / curfov ) 

    local vel = LocalPlayer():GetVelocity():Length()
    vel = vel > 500 and vel % 10 or 0

    curfov = Lerp( 3 * FrameTime(), curfov, ( 90 + ( fov > 7 and fov * vel or 0 ) ) )

    relativePosition:Rotate( Angle( 0, -rotation, 0 ) )

    local angle = math_atan2( relativePosition.y, relativePosition.x )

    angle = math_deg( angle )

    local distance = relativePosition:Length()

    local x = math_cos( math_rad( angle ) ) * distance * scale
    local y = math_sin( math_rad( angle ) ) * distance * scale

    local distance = math_sqrt( x ^ 2 + y ^ 2 )

    if distance > radius then
        local angle = math_atan2( y, x )
        x = math_cos( angle ) * radius
        y = math_sin( angle ) * radius
    end

    return Vector(x, y, 0)
end


local function DrawCoordsOnMiniMap( pos, ang, icon, iconsize, color, fov )
    local radius = ScreenScale( 45 )
    pos[ 3 ] = 0
    local plypos = LocalPlayer():GetPos() plypos[ 3 ] = 0
    
    local _, angs = WorldToLocal( pos, Angle( 0, ang[ 2 ], 0 ), LocalPlayer():GetPos(), CD2_viewangles )

    surface_SetDrawColor( color or color_white )
    surface_SetMaterial( icon or playerarrow )

    local vec = WorldVectorToScreen( pos, plypos, 0.2, CD2_viewangles[ 2 ] - 90, radius, fov )
    surface_DrawTexturedRectRotated( 200 + vec[ 1 ], ( ScrH() - 200 ) - vec[ 2 ], ScreenScale( iconsize ), ScreenScale( iconsize ), ( angs[ 2 ] ) )
end

local skillvars = {}

local function DrawSkillHex( x, y, icon, level, xp, col, skillname )
    skillvars[ skillname ] = skillvars[ skillname ] or {}
    skillvars[ skillname ].col = skillvars[ skillname ].col or col

    draw_NoTexture()

    -- Outlined circle pathing behind each skill dot
    surface_DrawCircle( x, y, 30, 0, 0, 0 )

    surface_SetDrawColor( color_white )
    surface_SetMaterial( skillcircle )

    -- White circle pathing behind each skill dot
    DrawSkillCircle( x, y, 33, Lerp( xp / 100, ( 55 * level ), ( 55 * ( level + 1 ) ) ) , -160 )

    draw_NoTexture()

    surface_SetDrawColor( blackish )
    draw_Circle( x, y, 25, 6, 30 ) -- Base hex

    if icon then
        surface_SetDrawColor( color_white )
        surface_SetMaterial( icon )
        draw_Circle( x, y, 30, 6, 30 )
    end

    draw_NoTexture()

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
    if CD2_InDropMenu then RemoveHUDpanels() return end
    if !CD2_DrawWeaponInfo then RemoveHUDpanels() end

    if !game.SinglePlayer() then
        for k, v in ipairs( player_GetAll() ) do
            if v == LocalPlayer() or !v:IsCD2Agent() then continue end
            local ent = IsValid( v:GetRagdollEntity() ) and v:GetRagdollEntity() or v
            local screen = ( ent:GetPos() + Vector( 0, 0, 100 ) ):ToScreen()
            draw_DrawText( v:Name(), "crackdown2_agentnames", screen.x, screen.y, v:GetPlayerColor():ToColor(), TEXT_ALIGN_CENTER )
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
        local usebind = input_LookupBinding( "+use" ) or "e"
        local code = input_GetKeyCode( usebind )
        local buttonname = input_GetKeyName( code )

        local reloadbind = input_LookupBinding( "+reload" ) or "r"
        local rcode = input_GetKeyCode( reloadbind )
        local reloadname = input_GetKeyName( rcode )
        

        CD2DrawInputbar( scrw / 2.1, 200, upper( buttonname ), "Regenerate" )
        CD2DrawInputbar( scrw / 2, 250, upper( reloadname ), "Regenerate at nearest spawn" )

        if #player_GetAll() > 1 then
            local fbind = input_LookupBinding( "+forward" ) or "w"
            local fcode = input_GetKeyCode( fbind )
            local forwardname = input_GetKeyName( fcode )

            CD2DrawInputbar( scrw / 1.9, 300, upper( forwardname ), "Hold to call for help" )
        end

        RemoveHUDpanels()
        return 
    end

    -- Crosshair --
    if CD2_DrawTargetting then
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
                surface_DrawTexturedRectRotated( ( scrw / 2 ), ( scrh / 2 ), spread, spread, ( SysTime() * 300 ) )
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
        local hp, maxhp, shield, maxshields, hpbars = ply:Health(), ply:GetMaxHealth(), clamp( ply:Armor(), 0, 100 ), ply:GetMaxArmor(), ( ceil( ply:Health() / 100 ) )

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
                draw_NoTexture()
                surface_SetDrawColor( orangeish )
                draw_Circle( 60 + ( 20 * ( i - 1 ) ), 90, ceil( ScreenScale( 2.5 ) ), 6, 30 )
            end
        end


        surface_SetDrawColor( color_white )
        surface_DrawRect( 75, 55, shieldlerp, 10 )

        if hpbars == 1 then
            hpred.r = math_max( 30, ( abs( math_sin( SysTime() * 1.5 ) * 163 ) ), ( abs( math_cos( SysTime() * 1.5 ) * 163 ) ) )
            hpred.g = ( abs( math_sin( SysTime() * 1.5 ) * 12 ) )
            hpred.b = ( abs( math_sin( SysTime() * 1.5 ) * 12 ) )
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

            draw_DrawText( weapon:Ammo1(), "crackdown2_ammoreserve", scrw - 35, scrh - 140, color_white, TEXT_ALIGN_RIGHT )


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
            surface_DrawOutlinedRect( scrw - 120, scrh - 100, 90, 60, 2 )
            surface_DrawOutlinedRect( scrw - 100, scrh - 140, 70, 40, 2 )
            surface_DrawOutlinedRect( scrw - 400, scrh - 130, 300, 30, 2 )
            surface_DrawOutlinedRect( scrw - 400, scrh - 100, 280, 60, 2 )
    
            
            
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
    
            draw_DrawText( ply:GetEquipmentCount(), "crackdown2_equipmentcount", scrw - 60, scrh - 90, color_white, TEXT_ALIGN_CENTER )

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
            surface_DrawRect( toscreen.x - 28, toscreen.y + 2, ( target:GetNWFloat( "cd2_health", 0 ) / target:GetMaxHealth() ) * 56, 8 )
        
        end
    end
    ------


    -- MiniMap --
    if CD2_DrawMinimap then
        local vel = ply:GetVelocity():Length()
        vel = vel > 500 and vel or 0
        addfov = Lerp( 1 * FrameTime(), addfov, vel % 10 )

        render.PushRenderTarget( minimapRT )

            mmTrace.start = ply:WorldSpaceCenter()
            mmTrace.endpos = ply:GetPos() + Vector( 0, 0, 20000 )
            mmTrace.mask = MASK_SOLID_BRUSHONLY
            mmTrace.collisiongroup = COLLISION_GROUP_WORLD
            local result = Trace( mmTrace )
            local fov = 6 + addfov

            render.RenderView( {
                origin = ply:GetPos() + Vector( 0, 0, 20000 ),
                angles = Angle( 90, CD2_viewangles[ 2 ], 0 ),
                znear = result.Hit and result.HitPos:Distance( mmTrace.endpos ) or 10,
                fov = fov,
                x = 0, y = 0,
                w = 1024, h = 1024
            } )

        render.PopRenderTarget()

        draw_NoTexture()
        surface_SetDrawColor( blackish )
        draw_Circle( 200, scrh - 200, ScreenScale( 50 ), 30 )

        surface_SetDrawColor( color_white )
        surface_SetMaterial( minimapRTMat )
        draw_Circle( 200, scrh - 200, ScreenScale( 50 ) - 10, 30 )

        surface_SetDrawColor( color_white )
        surface_SetMaterial( playerarrow )
        local _, angle = WorldToLocal( Vector(), ply:GetAngles(), ply:GetPos(), CD2_viewangles )
        surface_DrawTexturedRectRotated( 200, scrh - 200, ScreenScale( 10 ), ScreenScale( 10 ), angle[ 2 ] )

        local nearbyminimap = CD2FindInSphere( LocalPlayer():GetPos(), 1500, function( ent ) return ent:IsCD2NPC() and ent:GetCD2Team() == "cell" end )

        -- Cell --
        for i = 1, #nearbyminimap do
            local ent = nearbyminimap[ i ]
            DrawCoordsOnMiniMap( ent:GetPos(), ent:GetAngles(), cellicon, 4, ent:GetEnemy() == ply and celltargetred or cellwhite, fov )
        end
        --

        -- Players --
        local players = player_GetAll()

        for i = 1, #players do
            local otherplayer = players[ i ]
            if IsValid( otherplayer ) and otherplayer:IsCD2Agent() and otherplayer != ply then
                DrawCoordsOnMiniMap( otherplayer:GetPos(), otherplayer:EyeAngles(), playerarrow, 10, otherplayer:GetPlayerColor():ToColor(), fov )
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
    local scrw, scrh, ply = ScrW(), ScrH(), LocalPlayer()
    if CD2_InDropMenu or !ply:IsCD2Agent() or CD2_InSpawnPointMenu or !ply:Alive() then return end
    

    -- Peacekeeper --
    local near = CD2FindInSphere( ply:GetPos(), 1500, function( ent ) return ent:IsCD2NPC() and ent:GetCD2Team() == "agency" end )

    for k, v in ipairs( near ) do

        render_SetMaterial( peacekeeper )
        render_DrawSprite( v:GetPos() + Vector( 0, 0, 100 ), 32, 20, color_white )
    end
    ----

    -- Explosives --
    local near = CD2FindInSphere( ply:GetPos(), 1500, function( ent ) return explosivemodels[ ent:GetModel() ] end )

    for k, v in ipairs( near ) do

        render_SetMaterial( fireicon )
        render_DrawSprite( v:GetPos() + Vector( 0, 0, v:GetModelRadius() + 40 ), 16, 16, color_white )
    end
    ----

    -- Cell --
    local near = CD2FindInSphere( ply:GetPos(), 1500, function( ent ) return ent:IsCD2NPC() and ent:GetCD2Team() == "cell" end )

    for k, v in ipairs( near ) do

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