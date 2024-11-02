
local blur = Material( "pp/blurscreen" )
CD2_CanOpenAgencyConsole = true

local mmTrace = {}
local Trace = util.TraceLine

local blackish = Color( 39, 39, 39)
local fadedwhite = Color( 255, 255, 255, 10 )
local celltargetred = Color( 255, 51, 0 )
local orange = Color( 255, 115, 0 )
local beaconblue = Color( 0, 217, 255 )
local cellwhite = Color( 255, 255, 255 )

local heloicon = Material( "crackdown2/ui/helo.png", "smooth" )
local beaconicon = Material( "crackdown2/ui/beacon.png" )
local Auicon = Material( "crackdown2/ui/auicon.png" )
local playerarrow = Material( "crackdown2/ui/playerarrow.png" )
local staricon = Material( "crackdown2/ui/star.png", "smooth" )
local peacekeeper = Material( "crackdown2/ui/peacekeeper.png", "smooth" )
local pingmat = Material( "crackdown2/ui/pingcircle.png" )
local cell = Material( "crackdown2/ui/cell.png", "smooth" )
local agentdown = Material( "crackdown2/ui/agentdown.png", "smooth" )

local ping_locations = {}
local viewoffset = Vector()

local uniqueid = 0
function CD2:PingLocationOnConsole( id, pos, times, persist )
    id = id or uniqueid
    ping_locations[ id ] = { pos = pos, ping_scale = 0, times = times, can_ping = true, times_pinged = 0, persist = persist }
    uniqueid = uniqueid + 1
    return id
end

function CD2:RemovePingLocationConsole( id )
    ping_locations[ id ] = nil
end


local function WorldVectorToScreen2( pnl, pos, origin, rotation, scale, radius )
    local relativePosition = pos - origin

    relativePosition:Rotate( Angle( 0, -rotation, 0 ) )

    local angle = math.atan2( relativePosition.y, relativePosition.x )
    angle = math.deg( angle )

    local distance = relativePosition:Length()

    local x = math.cos( math.rad( angle ) ) * distance * scale
    local y = math.sin( math.rad( angle ) ) * distance * scale

    return Vector( x, y )
end

local function DrawCoordsOnMap( pnl, pos, origin, ang, icon, iconsize, color, fov )
    local radius = math.Distance( 0, 0, pnl:GetWide(), pnl:GetTall() )

    pos[ 3 ] = 0
    
    local _, angs = WorldToLocal( pos, Angle( 0, ang[ 2 ], 0 ), LocalPlayer():GetPos(), Angle() )

    surface.SetDrawColor( color or color_white )
    surface.SetMaterial( icon or playerarrow )

    local vec = WorldVectorToScreen2( pnl, pos, origin, -90, radius / ( fov * 390 ), radius )
    surface.DrawTexturedRectRotated( ( pnl:GetWide() / 2 ) + vec[ 1 ], ( pnl:GetTall() / 2 ) - vec[ 2 ], ScreenScale( iconsize ), ScreenScale( iconsize ), angs[ 2 ] )
end


function OpenIntelConsole()
    
    if IsValid( CD2_AgencyConsole ) then 
        CD2_AgencyConsole:Remove() 
        surface.PlaySound( "crackdown2/ui/ui_back.mp3" )
        
        net.Start( "cd2net_playeropenintelconsole" )
        net.WriteBool( false )
        net.SendToServer()

        return 
    end

    if IsValid( CD2_SpawnPointMenu ) or IsValid( CD2_DropMenu ) then return end

    if !CD2_CanOpenAgencyConsole then return end

    viewoffset = Vector()

    net.Start( "cd2net_playeropenintelconsole" )
    net.WriteBool( true )
    net.SendToServer()

    surface.PlaySound( "crackdown2/ui/ui_open.mp3" )

    CD2_AgencyConsole = vgui.Create( "DPanel", GetHUDPanel() )
    CD2_AgencyConsole:Dock( FILL )
    CD2_AgencyConsole:MakePopup()
    CD2_AgencyConsole:SetKeyBoardInputEnabled( false )


    hook.Add( "SetupWorldFog", CD2_AgencyConsole, function()
        render.FogStart( 0 )
        render.FogEnd( 0 )
        render.FogMaxDensity( 0 )
        render.FogMode( MATERIAL_FOG_LINEAR )
        render.FogColor( 0, 0, 0 )
        return true 
    end )

    hook.Add( "SetupSkyboxFog", CD2_AgencyConsole, function()
        render.FogStart( 0 )
        render.FogEnd( 0 )
        render.FogMaxDensity( 0 )
        render.FogMode( MATERIAL_FOG_LINEAR )
        render.FogColor( 0, 0, 0 )
        return true 
    end )

    CD2.PreventMovement = true

    function CD2_AgencyConsole:OnRemove() CD2.PreventMovement = nil end

    local toptext = vgui.Create( "DLabel", CD2_AgencyConsole )
    toptext:SetFont( "crackdown2_font60" )
    toptext:SetSize( 100, 100 )
    toptext:SetText( "             AGENCY INTEL" )
    toptext:Dock( TOP )

    local line = vgui.Create( "DPanel", CD2_AgencyConsole )
    line:SetSize( 100, 3 )
    line:Dock( TOP )

    local leftpnl = vgui.Create( "DPanel", CD2_AgencyConsole )
    leftpnl:SetSize( ScreenScale( 134 ), 100 )
    leftpnl:DockMargin( 30, 200, 30, 200 )
    leftpnl:Dock( LEFT )

    local buttonscroll = vgui.Create( "DScrollPanel", leftpnl )
    buttonscroll:Dock( FILL )
    function buttonscroll:Paint() end

    local midpnl = vgui.Create( "DPanel", CD2_AgencyConsole )
    midpnl:SetSize( ScreenScale( 317 ), 100 )
    midpnl:DockMargin( 30, 200, 30, 200 )
    midpnl:Dock( LEFT )

    local rightpnl = vgui.Create( "DPanel", CD2_AgencyConsole )
    rightpnl:SetSize( ScreenScale( 134 ), 100 )
    rightpnl:DockMargin( 30, 200, 30, 200 )
    rightpnl:Dock( LEFT )

    local beacons = ents.FindByClass( "cd2_beacon" )
    local locations = ents.FindByClass( "cd2_locationmarker" )
    local activecount = 0
    local agencylocations = 0
    local totallocations = 0
    local beginninglocationcaptured = false
    local beaconcount = GetGlobal2Int( "cd2_beaconcount", 0 )
    for k, v in ipairs( beacons ) do if v:GetIsDetonated() then activecount = activecount + 1 end end 
    for k, v in ipairs( locations ) do if v:GetLocationType() == "agency" and v:GetIsBeginningLocation() then beginninglocationcaptured = true end if v:GetLocationType() == "agency" then agencylocations = agencylocations + 1 end if v:GetLocationType() != "beacon" then totallocations = totallocations + 1 end end
    

    local rightpnltext = vgui.Create( "DLabel", rightpnl )
    rightpnltext:SetFont( "crackdown2_font50" )
    rightpnltext:SetSize( 100, 60 )
    rightpnltext:SetColor( orange )
    rightpnltext:Dock( TOP )
    rightpnltext:SetText( "             OBJECTIVES" )
    
    local rightpnlline = vgui.Create( "DPanel", rightpnl )
    rightpnlline:SetSize( 100, 3 )
    rightpnlline:Dock( TOP )

    if activecount < beaconcount then
        local beaconobjective = vgui.Create( "DLabel", rightpnl )
        beaconobjective:SetFont( "crackdown2_font30" )
        beaconobjective:SetSize( 100, 100 )
        beaconobjective:DockMargin( 10, 0, 0, 0 )
        beaconobjective:Dock( TOP )
        beaconobjective:SetText( "ERADICATE THE FREAKS\nDETONATE ALL BEACONS\n" .. activecount .. "/" .. beaconcount .. " BEACONS DETONATED"  )
    elseif activecount == beaconcount then
        local beaconobjective = vgui.Create( "DLabel", rightpnl )
        beaconobjective:SetFont( "crackdown2_font30" )
        beaconobjective:SetSize( 100, 100 )
        beaconobjective:DockMargin( 10, 0, 0, 0 )
        beaconobjective:Dock( TOP )
        beaconobjective:SetText( "ERADICATE THE FREAKS\nDETONATE THE FINAL BEACON"  )
    end

    if !beginninglocationcaptured then
        local tacticallocationobjective = vgui.Create( "DLabel", rightpnl )
        tacticallocationobjective:SetFont( "crackdown2_font30" )
        tacticallocationobjective:SetSize( 100, 100 )
        tacticallocationobjective:DockMargin( 10, 0, 0, 0 )
        tacticallocationobjective:Dock( TOP )
        tacticallocationobjective:SetText( "RECOVER THE BEACON PROTOTYPE\nSECURE TACTICAL LOCATION"  )
    elseif agencylocations < totallocations then
        local tacticallocationobjective = vgui.Create( "DLabel", rightpnl )
        tacticallocationobjective:SetFont( "crackdown2_font30" )
        tacticallocationobjective:SetSize( 100, 100 )
        tacticallocationobjective:DockMargin( 10, 0, 0, 0 )
        tacticallocationobjective:Dock( TOP )
        tacticallocationobjective:SetText( "SECURE ALL TACTICAL LOCATIONS\n" .. agencylocations .. "/" .. totallocations .. " LOCATIONS SECURED"  )
    end
    
    local panels = {}

    local function AddPanelToConsole( pnl, buttontext, first )
        panels[ #panels + 1 ] = pnl
        local button = vgui.Create( "DButton", buttonscroll )
        button:SetSize( 100, 40 )
        button:SetFont( "crackdown2_font30" )
        button:SetText( buttontext )
        button:Dock( TOP )

        function button:DoClick()
            surface.PlaySound( "crackdown2/ui/ui_select.mp3" )
            for k, panel in ipairs( panels ) do
                if panel != pnl then panel:Hide() else panel:Show() end
            end
        end
    
        function button:Paint( w, h )
            surface.SetDrawColor( blackish )
            surface.DrawRect( 0, 0, w, h )
    
            surface.SetDrawColor( fadedwhite )
            surface.DrawOutlinedRect( 0, 0, w, h, 3 )
        end

        if !first then pnl:Hide() end
    end



    local function Paint( self, w, h )
        surface.SetDrawColor( blackish )
        surface.DrawRect( 0, 0, w, h )

        surface.SetDrawColor( fadedwhite )
        surface.DrawOutlinedRect( 0, 0, w, h, 3 )
    end

    leftpnl.Paint = Paint
    rightpnl.Paint = Paint


    -- OVERHEAD VIEW --
    local mappnl = vgui.Create( "DPanel", midpnl )
    mappnl:Dock( FILL )

    AddPanelToConsole( mappnl, "Open Overhead View", true )

    local znear

    hook.Add( "Think", mappnl, function()
        if mappnl:IsVisible() then
            local ismoving = false

            local f = input.IsKeyDown( input.GetKeyCode( input.LookupBinding( "+forward" ) ) )
            local b = input.IsKeyDown( input.GetKeyCode( input.LookupBinding( "+back" ) ) )
            local r = input.IsKeyDown( input.GetKeyCode( input.LookupBinding( "+moveright" ) ) )
            local l = input.IsKeyDown( input.GetKeyCode( input.LookupBinding( "+moveleft" ) ) )

            local up = input.IsKeyDown( input.GetKeyCode( input.LookupBinding( "+jump" ) ) )
            local down = input.IsKeyDown( input.GetKeyCode( input.LookupBinding( "+duck" ) ) )

            if up then
                znear = znear - 50
            elseif down then
                znear = znear + 50
            end

            if f then
                viewoffset.x = viewoffset.x + 50
                ismoving = true
            end

            if b then
                viewoffset.x = viewoffset.x - 50
                ismoving = true
            end
            
            if r then
                viewoffset.y = viewoffset.y - 50
                ismoving = true
            end

            if l then
                viewoffset.y = viewoffset.y + 50
                ismoving = true
            end
            if ismoving then LocalPlayer():EmitSound( "crackdown2/ui/ui_move.mp3", 70, 100, 1, CHAN_WEAPON ) end
        end
    end )

    function mappnl:Paint( w, h )
        surface.SetDrawColor( blackish )
        surface.DrawRect( 0, 0, w, h )

        mmTrace.start = LocalPlayer():WorldSpaceCenter()
        mmTrace.endpos = LocalPlayer():GetPos() + Vector( 0, 0, 20000 )
        mmTrace.mask = MASK_SOLID_BRUSHONLY
        mmTrace.collisiongroup = COLLISION_GROUP_WORLD
        local result = Trace( mmTrace )

        local x, y =  self:GetParent():GetPos()

        znear = znear or result.Hit and result.HitPos:Distance( mmTrace.endpos )
        render.RenderView( {
            origin = LocalPlayer():GetPos() + Vector( 0, 0, 20000 ) + viewoffset,
            angles = Angle( 90, 0, 0 ),
            znear = znear,
            zfar = 10000000,
            fov = 30,
            x = x, y = y,
            w = w, h = h
        } )

        local plypos = LocalPlayer():GetPos()
        plypos[ 3 ] = 0

        for id, ping in pairs( ping_locations ) do
            if ping.times <= ping.times_pinged and !ping.persist then
                ping_locations[ id ] = nil
                continue 
            end

            ping.ping_scale = Lerp( 3.5 * FrameTime(), ping.ping_scale, ping.times > ping.times_pinged and 40 or 20 )
            DrawCoordsOnMap( self, ping.pos - viewoffset, plypos, CD2.viewangles, pingmat, ping.ping_scale, cellwhite, 30 )

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

        local entities = ents.FindByClass( "cd2_*" )

        -- Tacticle Locations | Helicopters | AUs --
        for i = 1, #entities do
            local ent = entities[ i ]

            if IsValid( ent ) and ent:GetClass() == "cd2_locationmarker" then 
                DrawCoordsOnMap( self, ent:GetPos() - viewoffset, plypos, Angle(), ent:GetLocationType() == "beacon" and beaconicon or ent:GetLocationType() == "cell" and cell or peacekeeper, 20, ent:GetLocationType() == "cell" and celltargetred or color_white, 30 )
            elseif IsValid( ent ) and ent:GetClass() == "cd2_agencyhelicopter" then
                DrawCoordsOnMap( self, ent:GetPos() - viewoffset, plypos, ent:GetAngles(), heloicon, 20, color_white, 30 )
            elseif IsValid( ent ) and ent:GetClass() == "cd2_au" and !ent:GetActive() then
                DrawCoordsOnMap( self, ent:GetPos() - viewoffset, plypos, Angle(), Auicon, 15, color_white, 30 )
            elseif IsValid( ent ) and ent:GetClass() == "cd2_towerbeacon" and !ent:GetIsDetonated() and ent:CanBeActivated() then
                DrawCoordsOnMap( self, ent:GetPos() - viewoffset, plypos, Angle( 0, 0, 0 ), staricon, 10, beaconblue, 30 )
            end
        end
        
        
        --
        
        -- Players --
        local players = player.GetAll()

        for i = 1, #players do
            local otherplayer = players[ i ]
            if IsValid( otherplayer ) and otherplayer:IsCD2Agent() then
                DrawCoordsOnMap( self, otherplayer:GetPos() - viewoffset, plypos, otherplayer:EyeAngles(), otherplayer:Alive() and playerarrow or agentdown, ScreenScale( 3 ), otherplayer:GetPlayerColor():ToColor(), 30 )
            end
        end
        --
    
    end

    --------


    -- PLAYER LIST --
    local players = {}
    local refreshcooldown = 0

    local playerlistmain = vgui.Create( "DPanel", midpnl )
    playerlistmain:Dock( FILL )
    playerlistmain:InvalidateParent( true )

    local toptext = vgui.Create( "DLabel", playerlistmain )
    toptext:SetFont( "crackdown2_font50" )
    toptext:SetSize( 100, 60 )
    toptext:DockMargin( ScreenScale( 317 ) / 3.5, 0, 0, 0 )
    toptext:Dock( TOP )
    toptext:SetText( GetHostName() )
    

    local line = vgui.Create( "DPanel", playerlistmain )
    line:SetSize( 100, 3 )
    line:Dock( TOP )

    local playerlistscroll = vgui.Create( "DScrollPanel", playerlistmain )
    playerlistscroll:Dock( FILL ) 
    function playerlistscroll:Paint() end

    function playerlistmain:Paint( w, h )
        surface.SetDrawColor( blackish )
        surface.DrawRect( 0, 0, w, h )
    end

    local function CreatePlayerBar( ply )
        local bar = vgui.Create( "DPanel", playerlistscroll )
        bar:SetSize( 10, 65 )
        bar:Dock( TOP )

        local profilepicture = vgui.Create( "AvatarImage", bar )
        profilepicture:SetSize( 59, 64 )
        profilepicture:DockMargin( 5, 5, 5, 5 )
        profilepicture:Dock( LEFT )
        profilepicture:SetPlayer( ply )

        local plyname = vgui.Create( "DLabel", bar )
        plyname:SetSize( 200, 100 )
        plyname:DockMargin( 10, 0, 0, 0 )
        plyname:Dock( LEFT )
        plyname:SetFont( "crackdown2_font50" )
        plyname:SetText( ply:Name() )

        local skillstats = vgui.Create( "DLabel", bar )
        skillstats:SetSize( 400, 100 )
        skillstats:DockMargin( 10, 0, 0, 0 )
        skillstats:Dock( LEFT )
        skillstats:SetFont( "crackdown2_font30" )
        skillstats:SetText( "Agility: " .. ply:GetAgilitySkill() .. " Strength: " .. ply:GetStrengthSkill() .. " Firearm: " .. ply:GetWeaponSkill() .. " Explosive: " .. ply:GetExplosiveSkill() )

        hook.Add( "Think", bar, function() 
            if !IsValid( ply ) then 

                bar:Remove()
                hook.Remove( "Think", bar )
            end
        end )

        function bar:Paint( w, h ) 
            surface.SetDrawColor( fadedwhite )
            surface.DrawOutlinedRect( 0, 0, w, h, 2 )
        end

        return bar
    end

    hook.Add( "Think", playerlistmain, function()
        if !playerlistmain:IsVisible() then return end
        if SysTime() < refreshcooldown then return end

        for k, ply in ipairs( player.GetAll() ) do
            if !players[ ply ] then
                local bar = CreatePlayerBar( ply )
                players[ ply ] = bar
            end
        end

        refreshcooldown = SysTime() + 1
    end )

    AddPanelToConsole( playerlistmain, "Open Player List" )
    -------

    -- Skill Progress --
    local skillmain = vgui.Create( "DPanel", midpnl )
    skillmain:Dock( FILL )
    skillmain:InvalidateParent( true )

    function skillmain:Paint( w, h )
        surface.SetDrawColor( blackish )
        surface.DrawRect( 0, 0, w, h )
    end

    local function CreateSkillBar( skill )
        local bar = vgui.Create( "DPanel", skillmain )
        bar:SetSize( 60, 65 )
        bar:Dock( TOP )

        local curlevel = LocalPlayer()[ "Get" .. skill .. "Skill" ]()
        local curprogress = LocalPlayer()[ "Get" .. skill .. "XP" ]()

        local skillname = vgui.Create( "DLabel", bar )
        skillname:SetSize( 150, 64 )
        skillname:DockMargin( 5, 5, 5, 5 )
        skillname:Dock( LEFT )
        skillname:SetText( skill .. ": " .. curlevel )
        skillname:SetFont( "crackdown2_font40" )

        local skillprogress = vgui.Create( "DPanel", bar )
        skillprogress:SetSize( 600, 100 )
        skillprogress:DockMargin( 10, 10, 0, 10 )
        skillprogress:Dock( LEFT )

        function skillprogress:Paint( w, h )
            surface.SetDrawColor( fadedwhite )
            surface.DrawOutlinedRect( 0, 0, w, h, 2 )
            surface.SetDrawColor( color_white )
            surface.DrawRect( 2, 2, w * ( curprogress / 100 ), h - 4  )
        end


        local skillstats = vgui.Create( "DLabel", bar )
        skillstats:SetSize( 400, 100 )
        skillstats:DockMargin( 10, 0, 0, 0 )
        skillstats:Dock( LEFT )
        skillstats:SetFont( "crackdown2_font30" )
        skillstats:SetText( "" .. math.Round( curprogress ) .. "/100" )

        function bar:Paint( w, h ) 
            surface.SetDrawColor( fadedwhite )
            surface.DrawOutlinedRect( 0, 0, w, h, 2 )
        end

        return bar
    end

    CreateSkillBar( "Agility" )
    CreateSkillBar( "Weapon" )
    CreateSkillBar( "Strength" )
    CreateSkillBar( "Explosive" )

    AddPanelToConsole( skillmain, "Skill Progress" )

    function CD2_AgencyConsole:Paint( w, h )
        local x, y = self:LocalToScreen( 0, 0 )

	    surface.SetDrawColor( 255, 255, 255, 255 )
	    surface.SetMaterial( blur )

	    for i = 1, 5 do
	        blur:SetFloat( "$blur", ( i / 4 ) * 4 )
	        blur:Recompute()

	        render.UpdateScreenEffectTexture()
	        surface.DrawTexturedRect( -x, -y, ScrW(), ScrH() )
	    end
    end
end

hook.Add( "ScoreboardShow", "crackdown2_intelconsole", function()
    OpenIntelConsole()
    return true
end )
