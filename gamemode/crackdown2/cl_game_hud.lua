local math = math
local surface = surface
local shadedwhite = Color( 177, 177, 177 )
local red = Color( 163, 12, 12)
local orangeish = Color( 202, 79, 22)
local blackish = Color( 39, 39, 39)
local black = Color( 0, 0, 0 )
local grey = Color( 61, 61, 61)
local linecol = Color( 61, 61, 61, 100 )
local beaconblue = Color( 0, 217, 255 )
local weaponskillcolor = Color( 0, 225, 255)
local strengthskillcolor = Color( 255, 251, 0)
local explosiveskillcolor = Color( 0, 110, 255 )
local agilityskillcolor = Color( 72, 255, 0)
local cellwhite = Color( 255, 255, 255 )
local celltargetred = Color( 255, 51, 0 )
local hpred = Color( 163, 12, 12)
local alphawhite = Color( 255, 255, 255, 10 )
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
local pingmat = Material( "crackdown2/ui/pingcircle.png" )
local playerarrow = Material( "crackdown2/ui/playerarrow.png" )
local cellicon = Material( "crackdown2/ui/celltrackericon.png" )

CD2Progressbars = CD2Progressbars or {}
local ping_locations = {}
local hplerp = -1
local shieldlerp = -1
local hlerp1
local hlerp2

CD2.lockon = false

local function draw_Circle( x, y, radius, seg, rotate )
    rotate = rotate or 0
	local cir = {}

	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -360 + rotate )
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( rotate ) -- This is needed for non math.absolute segment counts
	table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end


local function DrawSkillCircle( x, y, radius, arc, rotate )
    local seg = 30
	local cir = {}

	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -arc + rotate )
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( rotate ) -- This is needed for non math.absolute segment counts
	table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end


function CD2RegisterProgressBar( ent, distance, priority, drawfunc )
    CD2Progressbars[ #CD2Progressbars + 1 ] = { ent = ent, priority = priority, distance = distance, drawfunc = drawfunc }
    table.sort( CD2Progressbars, function( a, b ) return a.priority > b.priority end )
end


function CD2DrawInputbar( x, y, keyname, text )

    surface.SetFont( "crackdown2_font30" )
    local sizex = surface.GetTextSize( text )

    draw.NoTexture()
    surface.SetDrawColor( blackish )
    surface.DrawRect( x, y - 15, sizex + 30, 30 )
    
    surface.SetDrawColor( grey )
    draw_Circle( x, y, 20, 6 )

    draw.DrawText( keyname, "crackdown2_font30", x, y - 15, color_white, TEXT_ALIGN_CENTER )

    draw.DrawText( text, "crackdown2_font30", x + 20, y - 17, color_white, TEXT_ALIGN_LEFT )
    
end

local fireicon = Material( "crackdown2/ui/explosive.png" )



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


local uniqueid = 0
function CD2:PingLocationTracker( id, pos, times, persist )
    id = id or uniqueid
    ping_locations[ id ] = { pos = pos, ping_scale = 0, times = times, can_ping = true, times_pinged = 0, persist = persist }
    uniqueid = uniqueid + 1
    return id
end

function CD2:RemovePingLocation( id )
    ping_locations[ id ] = nil
end

local function DrawCoordsOnMiniMap( pos, ang, icon, iconsize, color, fov )
    local radius = ScreenScale( 45 )
    pos[ 3 ] = 0
    local plypos = LocalPlayer():GetPos() plypos[ 3 ] = 0
    
    local _, angs = WorldToLocal( pos, Angle( 0, ang[ 2 ], 0 ), LocalPlayer():GetPos(), CD2.viewangles )

    surface.SetDrawColor( color or color_white )
    surface.SetMaterial( icon or playerarrow )

    local vec = WorldVectorToScreen2( pos, plypos, CD2.viewangles[ 2 ] - 90, radius / ( fov * 170 ), radius ) --WorldVectorToScreen( pos, plypos, 0.2, CD2.viewangles[ 2 ] - 90, radius, fov )
    surface.DrawTexturedRectRotated( 200 + vec[ 1 ], ( ScrH() - 200 ) - vec[ 2 ], ScreenScale( iconsize ), ScreenScale( iconsize ), ( angs[ 2 ] ) )
end

local skillvars = {}

local function DrawSkillHex( x, y, icon, level, xp, col, skillname )
    skillvars[ skillname ] = skillvars[ skillname ] or {}
    skillvars[ skillname ].col = skillvars[ skillname ].col or col

    draw.NoTexture()

    -- Outlined circle pathing behind each skill dot
    surface.DrawCircle( x, y, 30, 0, 0, 0 )

    surface.SetDrawColor( color_white )
    surface.SetMaterial( skillcircle )

    -- White circle pathing behind each skill dot
    DrawSkillCircle( x, y, 33, Lerp( xp / 100, ( 55 * level ), ( 55 * ( level + 1 ) ) ) , -160 )

    draw.NoTexture()

    surface.SetDrawColor( blackish )
    draw_Circle( x, y, 25, 6, 30 ) -- Base hex

    if icon then
        surface.SetDrawColor( color_white )
        surface.SetMaterial( icon )
        draw_Circle( x, y, 30, 6, 30 )
    end

    draw.NoTexture()

    local dotsize = 6
    
    -- Top left dot
    surface.SetDrawColor( level == 6 and orangeish or blackish )
    draw_Circle( x - 15, y - 25, dotsize, 20, 0 )
    surface.DrawCircle( x - 15, y - 25, dotsize, 160, 160, 160, 30 )

    -- Top right dot
    surface.SetDrawColor( level >= 1 and orangeish or blackish )
    draw_Circle( x + 15, y - 25, dotsize, 20, 0 )
    surface.DrawCircle( x + 15, y - 25, dotsize, 160, 160, 160, 30 )

    -- Right dot
    surface.SetDrawColor( level >= 2 and orangeish or blackish )
    draw_Circle( x + 30, y, dotsize, 20, 0 )
    surface.DrawCircle( x + 30, y, dotsize, 160, 160, 160, 30 )

    -- Left dot
    surface.SetDrawColor( level >= 5 and orangeish or blackish )
    draw_Circle( x - 30, y, dotsize, 20, 0 )
    surface.DrawCircle( x - 30, y, dotsize, 160, 160, 160, 30 )

    -- Bottom left dot
    surface.SetDrawColor( level >= 4 and orangeish or blackish )
    draw_Circle( x - 15, y + 25, dotsize, 20, 0 )
    surface.DrawCircle( x - 15, y + 25, dotsize, 160, 160, 160, 30 )

    -- Bottom right dot
    surface.SetDrawColor( level >= 3 and orangeish or blackish )
    draw_Circle( x + 15, y + 25, dotsize, 20, 0 )
    surface.DrawCircle( x + 15, y + 25, dotsize, 160, 160, 160, 30 )

    skillvars[ skillname ].col.a = Lerp( 3 * FrameTime(), skillvars[ skillname ].col.a, 0 )

    if skillvars[ skillname ].col.a > 5 then
        surface.SetDrawColor( skillvars[ skillname ].col )
        surface.SetMaterial( skillglow )
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

CD2.DrawTargetting = true -- Draws crosshair and target healthbars
CD2.DrawHealthandShields = true -- Draws health and shields bars
CD2.DrawWeaponInfo = true -- Draws weapon info and equipment
CD2.DrawMinimap = true -- Draws the tracker
CD2.DrawBlackbars = false -- Draws the top and bottom black bars

CD2.DrawAgilitySkill = true
CD2.DrawFirearmSkill = true
CD2.DrawStrengthSkill = true
CD2.DrawExplosiveSkill = true

hook.Add( "HUDPaint", "crackdown2_hud", function()
    local scrw, scrh, ply = ScrW(), ScrH(), LocalPlayer()
    if CD2.InDropMenu or IsValid( CD2_AgencyConsole ) then RemoveHUDpanels() return end
    if !CD2.DrawWeaponInfo then RemoveHUDpanels() end

    if game.GetTimeScale() < 0.90 then

        draw.DrawText( "Damping frame loss.. (" .. ( math.Round( ( 1 - game.GetTimeScale() ) * 100, 0 ) ) .."%)", "crackdown2_font30", 60, scrh / 2, alphawhite, TEXT_ALIGN_LEFT )
    end

    if !game.SinglePlayer() and GetConVar( "cd2_drawhud" ):GetBool() then
        for k, v in ipairs( player.GetAll() ) do
            if v == LocalPlayer() or !v:IsCD2Agent() then continue end
            local ent = IsValid( v:GetRagdollEntity() ) and v:GetRagdollEntity() or v
            local screen = ( ent:GetPos() + Vector( 0, 0, 100 ) ):ToScreen()
            draw.DrawText( v:Name(), "crackdown2_agentnames", screen.x, screen.y, v:GetPlayerColor():ToColor(), TEXT_ALIGN_CENTER )

            if !v:Alive() then 
                local screen = ( ent:GetPos() + Vector( 0, 0, 10 ) ):ToScreen()
                surface.SetMaterial( agentdown )
                surface.SetDrawColor( color_white )
                surface.DrawTexturedRect( screen.x - 65, screen.y - 25, 130, 70 )
            end
        end
    end

    if CD2.InSpawnPointMenu or !ply:IsCD2Agent() then RemoveHUDpanels() return end

    if CD2.DrawBlackbars then
        hlerp1 = hlerp1 or -150
        hlerp2 = hlerp2 or scrh

        hlerp1 = Lerp( 2 * FrameTime(), hlerp1, 0 )
        hlerp2 = Lerp( 2 * FrameTime(), hlerp2, scrh - 150 )

        surface.SetDrawColor( black )

        surface.DrawRect( 0, hlerp1, scrw, 150 )
        surface.DrawRect( 0, hlerp2, scrw, 150 )
    else
        hlerp1 = -100
        hlerp2 = scrh
    end

    if !ply:Alive() then 
        local usebind = input.LookupBinding( "+use" ) or "e"
        local code = input.GetKeyCode( usebind )
        local buttonname = input.GetKeyName( code )

        local reloadbind = input.LookupBinding( "+reload" ) or "r"
        local rcode = input.GetKeyCode( reloadbind )
        local reloadname = input.GetKeyName( rcode )
        

        CD2DrawInputbar( scrw / 2.1, 200, string.upper( buttonname ), "Regenerate" )
        CD2DrawInputbar( scrw / 2, 250, string.upper( reloadname ), "Regenerate at nearest spawn" )

        if #player.GetAll() > 1 then
            local fbind = input.LookupBinding( "+forward" ) or "w"
            local fcode = input.GetKeyCode( fbind )
            local forwardname = input.GetKeyName( fcode )

            CD2DrawInputbar( scrw / 1.9, 300, string.upper( forwardname ), "Hold to call for help" )
        end

        RemoveHUDpanels()
        return 
    end

    if !GetConVar( "cd2_drawhud" ):GetBool() then RemoveHUDpanels() return end 

    -- Crosshair --
    if CD2.DrawTargetting then
        draw.NoTexture()
        surface.SetDrawColor( !CD2.lockon and shadedwhite or red )
        draw_Circle( scrw / 2, scrh / 2, 2, 30 )

        if CD2.lockon then
            local target = ply:GetNW2Entity( "CD2.lockontarget", nil )
            surface.DrawLine( ( scrw / 2 ), ( scrh / 2 ) + 10, ( scrw / 2 ), ( scrh / 2 ) + 20 )
            surface.DrawLine( ( scrw / 2 ), ( scrh / 2 ) - 10, ( scrw / 2 ), ( scrh / 2 ) - 20 )
            surface.DrawLine( ( scrw / 2 ) + 10, ( scrh / 2 ), ( scrw / 2 ) + 20, ( scrh / 2 ) )
            surface.DrawLine( ( scrw / 2 ) - 10, ( scrh / 2 ), ( scrw / 2 ) - 20, ( scrh / 2 ) )

            if IsValid( target ) then
                local spread = ply:GetLockonSpreadDecay() * 500
                surface.SetDrawColor( shadedwhite )
                surface.SetMaterial( hex )
                surface.DrawTexturedRectRotated( ( scrw / 2 ), ( scrh / 2 ), spread, spread, ( SysTime() * 300 ) )
            end
        end
    end
    ------
    
    for k, tbl in ipairs( CD2Progressbars ) do
        if !IsValid( tbl.ent ) or tbl.ent:SqrRangeTo( LocalPlayer() ) > tbl.distance ^ 2 then continue end
        local active = tbl.drawfunc( tbl.ent )
        if active then break end
    end
    
    
    
    -- Skill Counters --
    if CD2.DrawAgilitySkill then DrawSkillHex( 130, 170, agilityicon, ply:GetAgilitySkill(), ply:GetAgilityXP(), agilityskillcolor, "Agility" ) end
    if CD2.DrawFirearmSkill then DrawSkillHex( 130, 170 * 1.5, weaponicon, ply:GetWeaponSkill(), ply:GetWeaponXP(), weaponskillcolor, "Weapon" ) end
    if CD2.DrawStrengthSkill then DrawSkillHex( 130, 170 * 2, strengthicon, ply:GetStrengthSkill(), ply:GetStrengthXP(), strengthskillcolor, "Strength" ) end
    if CD2.DrawExplosiveSkill then DrawSkillHex( 130, 170 * 2.5, explosiveicon, ply:GetExplosiveSkill(), ply:GetExplosiveXP(), explosiveskillcolor, "Explosive" ) end
    ------


    -- Health and Shields --
    if CD2.DrawHealthandShields then
        local hp, shield, maxshields, hpbars = ply:Health(), math.Clamp( ply:Armor(), 0, 100 ), ply:GetMaxArmor(), ( math.ceil( ply:Health() / 100 ) )

        hplerp = hplerp == -1 and hp or hplerp
        shieldlerp = shieldlerp == -1 and shield or shieldlerp

        local modulate =  ( ( hp % 100 ) / 100 ) * ScreenScale( 96 )
        hplerp = Lerp( 30 * FrameTime(), hplerp, modulate == 0 and ScreenScale( 96 ) or modulate)
        shieldlerp = Lerp( 30 * FrameTime(), shieldlerp, ( shield / maxshields ) * ScreenScale( 96 ) )

        surface.SetDrawColor( blackish )
        surface.DrawRect( 70, 50, ScreenScale( 100 ), 35 )

        if hpbars > 1 then
            surface.SetDrawColor( blackish )
            surface.DrawRect( 70, 80, ScreenScale( 30 ), 13 )

            for i = 1, hpbars do
                if i == 1 then continue end
                draw.NoTexture()
                surface.SetDrawColor( orangeish )
                draw_Circle( 60 + ( 20 * ( i - 1 ) ), 90, math.ceil( ScreenScale( 2.5 ) ), 6, 30 )
            end
        end


        surface.SetDrawColor( color_white )
        surface.DrawRect( 75, 55, shieldlerp, 10 )

        if hpbars == 1 then
            hpred.r = math.max( 30, ( math.abs( math.sin( SysTime() * 1.5 ) * 163 ) ), ( math.abs( math.cos( SysTime() * 1.5 ) * 163 ) ) )
            hpred.g = ( math.abs( math.sin( SysTime() * 1.5 ) * 12 ) )
            hpred.b = ( math.abs( math.sin( SysTime() * 1.5 ) * 12 ) )
        end

        surface.SetDrawColor( hpbars > 1 and orangeish or hpred  )
        surface.DrawRect( 75, 70, hplerp, 10 )
    end
    ------


    -- Weapon Info --
    if CD2.DrawWeaponInfo then
        local weapon = ply:GetActiveWeapon()

        if IsValid( weapon ) then
            local mdl = weapon:GetWeaponWorldModel()

            surface.SetDrawColor( blackish )
            surface.DrawRect( scrw - 400, scrh - 130, 300, 30 )

            surface.SetDrawColor( blackish )
            surface.DrawRect( scrw - 100, scrh - 140, 70, 40 )

            surface.SetDrawColor( blackish )
            surface.DrawRect( scrw - 400, scrh - 100, 300, 60 )

            draw.DrawText( weapon.Ammo1 and weapon:Ammo1() or "NONE", "crackdown2_font40", scrw - 35, scrh - 140, color_white, TEXT_ALIGN_RIGHT )


            for i = 1, weapon:Clip1() do
                local wscale = 300 / weapon:GetMaxClip1()
                local x = ( scrw - 395 ) + ( wscale * ( i - 1 ) )
                if x >= scrw - 395 and x + wscale / 2 <= scrw - 100 then
                    surface.SetDrawColor(color_white)
                    surface.DrawRect(x, scrh - 125, math.ceil( wscale / 2 ), 20)
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
                    if CD2.InDropMenu or !ply:IsCD2Agent() or CD2.InSpawnPointMenu or !ply:Alive() then self:GetParent():Remove() return end
                    local wep = ply:GetActiveWeapon()
                    if IsValid( CD2_weaponpnl ) and IsValid( wep ) then local ent = CD2_weaponpnl:GetEntity() ent:SetModel( wep:GetWeaponWorldModel() ) CD2_weaponpnl:SetLookAt( ent:OBBCenter() ) end
                    
                    if CD2_weaponpnl != self:GetParent() then
                        self:GetParent():Remove()
                    end
                end
            end


            surface.SetDrawColor( blackish )
            surface.DrawRect( scrw - 120, scrh - 100, 90, 60 )
    
    
            surface.SetDrawColor( linecol )
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
                    if CD2.InDropMenu or !ply:IsCD2Agent() or CD2.InSpawnPointMenu or !ply:Alive() then self:GetParent():Remove() return end
    
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
    
            draw.DrawText( ply:GetEquipmentCount(), "crackdown2_font45", scrw - 60, scrh - 90, color_white, TEXT_ALIGN_CENTER )

        end

        
    end
    ------


    -- Lock on Entity health bars --
    if CD2.DrawTargetting then
        local lockables = CD2:FindInLockableTragets( ply )
        local target = ply.CD2.lockontarget or lockables[ 1 ]

        if IsValid( target ) then 
            local toscreen = ( target:GetPos() + Vector( 0, 0, target:GetModelRadius() ) ):ToScreen()
        
            surface.SetDrawColor( blackish )
            surface.DrawRect( toscreen.x - 30, toscreen.y, 60, 12 )

            surface.SetDrawColor( orangeish )
            surface.DrawRect( toscreen.x - 28, toscreen.y + 2, ( target:GetNW2Float( "cd2_health", 0 ) / target:GetMaxHealth() ) * 56, 8 )
        
        end
    end
    ------


    -- MiniMap --
    if CD2.DrawMinimap then
        local fov = 15

        draw.NoTexture()
        surface.SetDrawColor( blackish )
        draw_Circle( 200, scrh - 200, ScreenScale( 50 ), 30 )

        -- { id = uniqueid, pos = pos, times = times, ping_scale = 0, can_ping = true, times_pinged = 0, persist = persist }
        for id, ping in pairs( ping_locations ) do
            if ping.times <= ping.times_pinged and !ping.persist then
                ping_locations[ id ] = nil
                continue 
            end

            ping.ping_scale = Lerp( 3.5 * FrameTime(), ping.ping_scale, ping.times > ping.times_pinged and 40 or 20 )
            DrawCoordsOnMiniMap( ping.pos, CD2.viewangles, pingmat, ping.ping_scale, cellwhite, fov )

            if ping.can_ping and ping.times > ping.times_pinged then
                surface.PlaySound( "crackdown2/ui/ping.mp3" )
                ping.can_ping = false
            end

            if ping.ping_scale > ( ping.times > ping.times_pinged and 35 or 18 ) then
                ping.can_ping = true
                ping.ping_scale = 0
                ping.times_pinged = ping.times_pinged + 1
            end
        end

        surface.SetDrawColor( ply:GetPlayerColor():ToColor() )
        surface.SetMaterial( playerarrow )
        local _, angle = WorldToLocal( Vector(), ply:GetAngles(), ply:GetPos(), CD2.viewangles )
        surface.DrawTexturedRectRotated( 200, scrh - 200, ScreenScale( 10 ), ScreenScale( 10 ), angle[ 2 ] )

        local nearbyminimap = CD2:FindInSphere( LocalPlayer():GetPos(), 3500, function( ent ) return ent:IsCD2NPC() and ent:GetCD2Team() == "cell" end )

        -- Cell --
        for i = 1, #nearbyminimap do
            local ent = nearbyminimap[ i ]
            local z = ent:GetPos().z
            local icon = z > ply:GetPos().z + 50 and upicon or z < ply:GetPos().z - 50 and downicon or cellicon
            DrawCoordsOnMiniMap( ent:GetPos(), CD2.viewangles, icon, 4, ent:GetEnemy() == ply and celltargetred or cellwhite, fov )
        end
        --
        
        
        -- Tacticle Locations | Helicopters | ect --
        local ents_ = ents.FindByClass( "cd2_*" )
        for i = 1, #ents_ do
            local ent = ents_[ i ]
    
            if IsValid( ent ) and ent:GetClass() == "cd2_locationmarker" and ( ent:SqrRangeTo( LocalPlayer() ) < ( 6000 * 6000 ) or ent:GetLocationType() == "beacon" ) then 
                DrawCoordsOnMiniMap( ent:GetPos(), Angle( 0, CD2.viewangles[ 2 ], 0 ), ent:GetLocationType() == "beacon" and beaconicon or ent:GetLocationType() == "cell" and cell or peacekeeper, ent:GetLocationType() == "beacon" and 20 or 10, ent:GetLocationType() == "cell" and celltargetred or color_white, fov )
            elseif IsValid( ent ) and ent:GetClass() == "cd2_agencyhelicopter" and ent:SqrRangeTo( LocalPlayer() ) < ( 6000 * 6000 ) then
                DrawCoordsOnMiniMap( ent:GetPos(), ent:GetAngles(), heloicon, 15, color_white, fov )
            elseif IsValid( ent ) and ent:GetClass() == "cd2_au" and !ent:GetActive() then
                DrawCoordsOnMiniMap( ent:GetPos(), Angle( 0, CD2.viewangles[ 2 ], 0 ), Auicon, 10, color_white, fov )
            elseif IsValid( ent ) and ent:GetClass() == "cd2_towerbeacon" and !ent:GetIsDetonated() and ent:CanBeActivated() then
                DrawCoordsOnMiniMap( ent:GetPos(), Angle( 0, CD2.viewangles[ 2 ], 0 ), staricon, 10, beaconblue, fov )
            elseif IsValid( ent ) and ent:IsCD2NPC() and ent:GetCD2Team() == "freak" and IsValid( ent:GetEnemy() ) and ( ( ent:GetEnemy():GetNWBool( "cd2_beaconpart", false ) or ent:GetEnemy():GetClass() == "cd2_beacon" ) or ( ent:GetEnemy():GetNWBool( "cd2_towerbeaconpart", false ) ) ) then
                DrawCoordsOnMiniMap( ent:GetPos(), Angle( 0, CD2.viewangles[ 2 ], 0 ), FreakIcon, 10, color_white, fov )
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

local effects_ents
local next_update_effects = 0

-- Peacekeeper/Cell logos --
hook.Add( "PreDrawEffects", "crackdown2_peacekeepericons/cellicons", function()
    local ply = LocalPlayer()
    if CD2.InDropMenu or !ply:IsCD2Agent() or CD2.InSpawnPointMenu or !ply:Alive() then return end
    
    if CurTime() > next_update_effects then
        effects_ents = CD2:FindInSphere( ply:GetPos(), 1500 )
        next_update_effects = CurTime() + 0.5
    end

    for i = 1, #effects_ents do
        local v = effects_ents[ i ]
        if !IsValid( v ) then continue end

        -- Peacekeeper --
        if v:IsCD2NPC() and v:GetCD2Team() == "agency" then
            render.SetMaterial( peacekeeper )
            render.DrawSprite( v:GetPos() + Vector( 0, 0, 100 ), 32, 20, color_white )
        -- Explosives --
        elseif explosivemodels[ v:GetModel() ] then
            render.SetMaterial( fireicon )
            render.DrawSprite( v:GetPos() + Vector( 0, 0, v:GetModelRadius() + 40 ), 16, 16, color_white )
        -- Cell --
        elseif v:IsCD2NPC() and v:GetCD2Team() == "cell" then
            render.SetMaterial( cell )
            render.DrawSprite( v:GetPos() + Vector( 0, 0, 100 ), 16, 16, red )
        end
    end
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

    if ply:Alive() and ply:Health() < 70 then
        modify[ "$pp_colour_addr" ] = Lerp( 2 * FrameTime(), modify[ "$pp_colour_addr" ], 0.15 )
    else
        modify[ "$pp_colour_addr" ] = Lerp( 2 * FrameTime(), modify[ "$pp_colour_addr" ], 0 )
    end

    if !ply:Alive() and !CD2.InSpawnPointMenu then
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