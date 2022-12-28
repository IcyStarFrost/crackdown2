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

local function draw_Circle( x, y, radius, seg )
	local cir = {}

	table_insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math_rad( ( i / seg ) * -360 )
		table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )
	end

	local a = math_rad( 0 ) -- This is needed for non absolute segment counts
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
local explosiveicon = Material( "crackdown2/ui/explosive.png" )

local hplerp = -1
local shieldlerp = -1
local hlerp1
local hlerp2
CD2_equipmentpnl = nil
CD2_weaponpnl = nil
local peacekeeper = Material( "crackdown2/ui/peacekeeper.png", "smooth" )
local cell = Material( "crackdown2/ui/cell.png", "smooth" )
local peacekeepertrace = {}

-- Minimap vars
local minimapRT = GetRenderTarget( "crackdown2_minimaprt", 1024, 1024 )
local mmTrace = {}
local addfov = 0
local playerarrow = Material( "crackdown2/ui/playerarrow.png" )
local minimapRTMat = CreateMaterial( "crackdown2_minimapmaterial", "UnlitGeneric", {
	["$basetexture"] = "crackdown2_minimaprt",
	["$translucent"] = 1,
	["$vertexcolor"] = 1
} )
--

local function DrawEntOnMiniMap( ent, icon, color, cull )
    local radius = ScreenScale( 50 )
    local entpos = ent:GetPos()
    local plypos = LocalPlayer():GetPos()
    entpos[ 3 ] = plypos[ 3 ]
    local lpos, langle = WorldToLocal( entpos, ent:GetAngles(), plypos, CD2_viewangles )


    surface_SetDrawColor( color or color_white )
    surface_SetMaterial( icon or playerarrow )


    surface_DrawTexturedRectRotated( 200 + lpos[ 1 ], ( ScrH() - 200 ) - lpos[ 2 ], ScreenScale( 5 ), ScreenScale( 5 ), langle[ 2 ] )
end


local function RemoveHUDpanels()
    if IsValid( CD2_weaponpnl ) then CD2_weaponpnl:Remove() end
    if IsValid( CD2_equipmentpnl ) then CD2_equipmentpnl:Remove() end
end

hook.Add( "HUDPaint", "crackdown2_hud", function()
    local scrw, scrh, ply = ScrW(), ScrH(), LocalPlayer()
    if CD2_InDropMenu or !ply:IsCD2Agent() then RemoveHUDpanels() return end

    if !game.SinglePlayer() then
        for k, v in ipairs( player_GetAll() ) do
            if v == LocalPlayer() or !v:IsCD2Agent() then continue end
            local ent = IsValid( v:GetRagdollEntity() ) and v:GetRagdollEntity() or v
            local screen = ( ent:GetPos() + Vector( 0, 0, 100 ) ):ToScreen()
            draw_DrawText( v:Name(), "crackdown2_agentnames", screen.x, screen.y, v:GetPlayerColor():ToColor(), TEXT_ALIGN_CENTER )
        end
    end

    if CD2_InSpawnPointMenu then RemoveHUDpanels() return end

    if !ply:Alive() then 
        local usebind = input_LookupBinding( "+use" ) or "e"
        local code = input_GetKeyCode( usebind )
        local buttonname = input_GetKeyName( code )

        local reloadbind = input_LookupBinding( "+reload" ) or "r"
        local rcode = input_GetKeyCode( reloadbind )
        local reloadname = input_GetKeyName( rcode )
        
        hlerp1 = hlerp1 or -150
        hlerp2 = hlerp2 or scrh

        hlerp1 = Lerp( 2 * FrameTime(), hlerp1, 0 )
        hlerp2 = Lerp( 2 * FrameTime(), hlerp2, scrh - 150 )

        surface_SetDrawColor( black )

        surface_DrawRect( 0, hlerp1, scrw, 150 )
        surface_DrawRect( 0, hlerp2, scrw, 150 )

        CD2DrawInputbar( scrw / 2.1, 200, upper( buttonname ), "Regenerate" )
        CD2DrawInputbar( scrw / 2, 250, upper( reloadname ), "Regenerate at nearest spawn" )

        RemoveHUDpanels()
        return 
    else
        hlerp1 = -100
        hlerp2 = scrh
    end

    -- Crosshair --
    surface_SetDrawColor( !CD2_lockon and shadedwhite or red )
    draw_Circle( scrw / 2, scrh / 2, 2, 30 )

    if CD2_lockon then
        surface_DrawLine( ( scrw / 2 ), ( scrh / 2 ) + 10, ( scrw / 2 ), ( scrh / 2 ) + 20 )
        surface_DrawLine( ( scrw / 2 ), ( scrh / 2 ) - 10, ( scrw / 2 ), ( scrh / 2 ) - 20 )
        surface_DrawLine( ( scrw / 2 ) + 10, ( scrh / 2 ), ( scrw / 2 ) + 20, ( scrh / 2 ) )
        surface_DrawLine( ( scrw / 2 ) - 10, ( scrh / 2 ), ( scrw / 2 ) - 20, ( scrh / 2 ) )
    end
    ------


    -- Health and Shields --
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
        surface_DrawRect( 70, 80, ScreenScale( 33.5 ), 13 )

        for i = 1, hpbars do
            if i == 1 then continue end
            surface_SetDrawColor( orangeish )
            draw_Circle( 60 + ( 20 * ( i - 1 ) ), 90, 8, 5 )
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
    ------


    -- Weapon Info --
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

    end

    

    surface_SetDrawColor( blackish )
    surface_DrawRect( scrw - 120, scrh - 100, 90, 60 )


    surface_SetDrawColor( linecol )
    surface_DrawOutlinedRect( scrw - 120, scrh - 100, 90, 60, 2 )
    surface_DrawOutlinedRect( scrw - 100, scrh - 140, 70, 40, 2 )
    surface_DrawOutlinedRect( scrw - 400, scrh - 130, 300, 30, 2 )
    surface_DrawOutlinedRect( scrw - 400, scrh - 100, 280, 60, 2 )

    
    
    if !IsValid( CD2_equipmentpnl ) then
        local mdl = scripted_ents.Get( CD2_DropEquipment ).WorldModel

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

            if CD2_equipmentpnl != self:GetParent() then
                self:GetParent():Remove()
            end
        end
    end

    draw_DrawText( ply:GetEquipmentCount(), "crackdown2_equipmentcount", scrw - 60, scrh - 90, color_white, TEXT_ALIGN_CENTER )



    ------


    -- Lock on Entity health bars --
    local lockables = CD2FindInLockableTragets( ply )
    local target = ply.cd2_lockontarget or lockables[ 1 ]

    if IsValid( target ) then 
        local toscreen = ( target:GetPos() + Vector( 0, 0, target:GetModelRadius() ) ):ToScreen()
    
        surface_SetDrawColor( blackish )
        surface_DrawRect( toscreen.x - 30, toscreen.y, 60, 12 )

        surface_SetDrawColor( orangeish )
        surface_DrawRect( toscreen.x - 28, toscreen.y + 2, ( target:GetNWFloat( "cd2_health", 0 ) / target:GetMaxHealth() ) * 56, 8 )
    
    end
    ------


    -- MiniMap --
    local vel = ply:GetVelocity():Length()
    vel = vel > 500 and vel or 0
    addfov = Lerp( 1 * FrameTime(), addfov, vel % 10 )

    render.PushRenderTarget( minimapRT )

        mmTrace.start = ply:WorldSpaceCenter()
        mmTrace.endpos = ply:GetPos() + Vector( 0, 0, 20000 )
        mmTrace.mask = MASK_SOLID_BRUSHONLY
        mmTrace.collisiongroup = COLLISION_GROUP_WORLD
        local result = Trace( mmTrace )

        render.RenderView( {
            origin = ply:GetPos() + Vector( 0, 0, 20000 ),
            angles = Angle( 90, CD2_viewangles[ 2 ], 0 ),
            znear = result.Hit and result.HitPos:Distance( mmTrace.endpos ) or 10,
            fov = 6 + addfov,
            x = 0, y = 0,
            w = 1024, h = 1024
        } )

    render.PopRenderTarget()

    surface_SetDrawColor( blackish )
    draw_Circle( 200, scrh - 200, ScreenScale( 50 ), 30 )

    surface_SetDrawColor( color_white )
    surface_SetMaterial( minimapRTMat )
    draw_Circle( 200, scrh - 200, ScreenScale( 50 ) - 10, 30 )

    surface_SetDrawColor( color_white )
    surface_SetMaterial( playerarrow )
    local _, angle = WorldToLocal( Vector(), ply:GetAngles(), ply:GetPos(), CD2_viewangles )
    surface_DrawTexturedRectRotated( 200, scrh - 200, ScreenScale( 10 ), ScreenScale( 10 ), angle[ 2 ] )

--[[     local nearbyminimap = CD2FindInSphere( LocalPlayer():GetPos(), 2000, function( ent ) return ent:IsCD2NPC() end )

    for i = 1, #nearbyminimap do
        local ent = nearbyminimap[ i ]
        DrawEntOnMiniMap( ent )
    end ]]
    
    ------

end )

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

    -- Cell --
    local near = CD2FindInSphere( ply:GetPos(), 1500, function( ent ) return ent:IsCD2NPC() and ent:GetCD2Team() == "cell" end )

    for k, v in ipairs( near ) do

        render_SetMaterial( cell )
        render_DrawSprite( v:GetPos() + Vector( 0, 0, 100 ), 16, 16, red )
    end
    ----
end )
----