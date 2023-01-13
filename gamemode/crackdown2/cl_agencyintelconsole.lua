
local blur = Material( "pp/blurscreen" )
CD2_CanOpenAgencyConsole = true
local surface_DrawRect = surface.DrawRect
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local blackish = Color( 39, 39, 39)
local mmTrace = {}
local Trace = util.TraceLine
local fadedwhite = Color( 255, 255, 255, 10 )
local math_deg = math.deg
local math_rad = math.rad
local math_sqrt = math.sqrt
local math_atan2 = math.atan2
local math_cos = math.cos
local player_GetAll = player.GetAll
local math_sin = math.sin
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local curfov = 90
local clamp = math.Clamp
local heloicon = Material( "crackdown2/ui/helo.png", "smooth" )
local beaconicon = Material( "crackdown2/ui/beacon.png" )
local cellicon = Material( "crackdown2/ui/celltrackericon.png" )
local cellwhite = Color( 255, 255, 255 )
local Auicon = Material( "crackdown2/ui/auicon.png" )
local playerarrow = Material( "crackdown2/ui/playerarrow.png" )
local celltargetred = Color( 255, 51, 0 )

local peacekeeper = Material( "crackdown2/ui/peacekeeper.png", "smooth" )
local cell = Material( "crackdown2/ui/cell.png", "smooth" )

local function WorldVectorToScreen2( pnl, pos, origin, rotation, scale, radius )
    local relativePosition = pos - origin

    relativePosition:Rotate( Angle( 0, -rotation, 0 ) )

    local angle = math_atan2( relativePosition.y, relativePosition.x )
    angle = math_deg( angle )

    local distance = relativePosition:Length()

    local x = math_cos( math_rad( angle ) ) * distance * scale
    local y = math_sin( math_rad( angle ) ) * distance * scale

    return Vector( x, y )
end

local function DrawCoordsOnMap( pnl, pos, origin, ang, icon, iconsize, color, fov )
    local radius = math.Distance( 0, 0, pnl:GetWide(), pnl:GetTall() )

    pos[ 3 ] = 0
    
    local _, angs = WorldToLocal( pos, Angle( 0, ang[ 2 ], 0 ), LocalPlayer():GetPos(), Angle() )

    surface_SetDrawColor( color or color_white )
    surface_SetMaterial( icon or playerarrow )

    local vec = WorldVectorToScreen2( pnl, pos, origin, -90, radius / ( fov * 390 ), radius )
    surface_DrawTexturedRectRotated( ( pnl:GetWide() / 2 ) + vec[ 1 ], ( pnl:GetTall() / 2 ) - vec[ 2 ], ScreenScale( iconsize ), ScreenScale( iconsize ), angs[ 2 ] )
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

    if !CD2_CanOpenAgencyConsole then return end

    net.Start( "cd2net_playeropenintelconsole" )
    net.WriteBool( true )
    net.SendToServer()

    surface.PlaySound( "crackdown2/ui/ui_open.mp3" )

    CD2_AgencyConsole = vgui.Create( "DPanel", GetHUDPanel() )
    CD2_AgencyConsole:Dock( FILL )
    CD2_AgencyConsole:MakePopup()
    CD2_AgencyConsole:SetKeyBoardInputEnabled( false )

    CD2_PreventMovement = true

    function CD2_AgencyConsole:OnRemove() CD2_PreventMovement = nil end

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

    local midpnl = vgui.Create( "DPanel", CD2_AgencyConsole )
    midpnl:SetSize( ScreenScale( 317), 100 )
    midpnl:DockMargin( 30, 200, 30, 200 )
    midpnl:Dock( LEFT )

    local rightpnl = vgui.Create( "DPanel", CD2_AgencyConsole )
    rightpnl:SetSize( ScreenScale( 134 ), 100 )
    rightpnl:DockMargin( 30, 200, 30, 200 )
    rightpnl:Dock( LEFT )

    local iscontrollingview = false

    local controlview = vgui.Create( "DButton", leftpnl )
    controlview:SetSize( 100, 40 )
    controlview:SetFont( "crackdown2_font30" )
    controlview:SetText( "Control Map View" )
    controlview:Dock( TOP )

    function controlview:DoClick()
        iscontrollingview = !iscontrollingview
        surface.PlaySound( "crackdown2/ui/ui_select.mp3" )
    end

    local function Paint( self, w, h )
        surface_SetDrawColor( blackish )
        surface_DrawRect( 0, 0, w, h )

        surface_SetDrawColor( fadedwhite )
        surface_DrawOutlinedRect( 0, 0, w, h, 3 )
    end

    controlview.Paint = Paint
    leftpnl.Paint = Paint
    rightpnl.Paint = Paint

    local viewoffset = Vector()
    local znear
    local limittime = 0

    function midpnl:Think()
        if iscontrollingview then
            local ismoving = false

            if LocalPlayer():KeyDown( IN_JUMP ) then
                znear = znear - 50
            elseif LocalPlayer():KeyDown( IN_DUCK ) then
                znear = znear + 50
            end

            if LocalPlayer():KeyDown( IN_FORWARD ) then
                viewoffset.x = viewoffset.x + 50
                ismoving = true
            end

            if LocalPlayer():KeyDown( IN_BACK ) then
                viewoffset.x = viewoffset.x - 50
                ismoving = true
            end
            
            if LocalPlayer():KeyDown( IN_MOVERIGHT ) then
                viewoffset.y = viewoffset.y - 50
                ismoving = true
            end

            if LocalPlayer():KeyDown( IN_MOVELEFT ) then
                viewoffset.y = viewoffset.y + 50
                ismoving = true
            end
            if ismoving then LocalPlayer():EmitSound( "crackdown2/ui/ui_move.mp3", 70, 100, 1, CHAN_WEAPON ) end
        end
    end

    function midpnl:Paint( w, h )
        surface_SetDrawColor( blackish )
        surface_DrawRect( 0, 0, w, h )

        mmTrace.start = LocalPlayer():WorldSpaceCenter()
        mmTrace.endpos = LocalPlayer():GetPos() + Vector( 0, 0, 20000 )
        mmTrace.mask = MASK_SOLID_BRUSHONLY
        mmTrace.collisiongroup = COLLISION_GROUP_WORLD
        local result = Trace( mmTrace )

        local x, y = self:GetPos()

        znear = znear or result.Hit and result.HitPos:Distance( mmTrace.endpos )
        render.RenderView( {
            origin = LocalPlayer():GetPos() + Vector( 0, 0, 20000 ) + viewoffset,
            angles = Angle( 90, 0, 0 ),
            znear = !iscontrollingview and result.Hit and result.HitPos:Distance( mmTrace.endpos ) or iscontrollingview and znear or 10,
            fov = 30,
            x = x, y = y,
            w = w, h = h
        } )

        local plypos = LocalPlayer():GetPos()
        plypos[ 3 ] = 0

        local entities = ents.FindByClass( "cd2_*" )

        -- Cell --
        for i = 1, #entities do
            local ent = entities[ i ]
            if IsValid( ent ) and ent:IsCD2NPC() and ent:GetCD2Team() == "cell" and ent:SqrRangeTo( LocalPlayer() ) < ( 3000 * 3000 ) then
                DrawCoordsOnMap( self, ent:GetPos() - viewoffset, plypos, ent:GetAngles(), cellicon, 4, ent:GetEnemy() == LocalPlayer() and celltargetred or cellwhite, 30 )
            end
        end
        --

        -- Tacticle Locations | Helicopters | AUs --
        for i = 1, #entities do
            local ent = entities[ i ]

            if IsValid( ent ) and ent:GetClass() == "cd2_locationmarker" then 
                DrawCoordsOnMap( self, ent:GetPos() - viewoffset, plypos, Angle(), ent:GetLocationType() == "beacon" and beaconicon or ent:GetLocationType() == "cell" and cell or peacekeeper, 20, ent:GetLocationType() == "cell" and celltargetred or color_white, 30 )
            elseif IsValid( ent ) and ent:GetClass() == "cd2_agencyhelicopter" then
                DrawCoordsOnMap( self, ent:GetPos() - viewoffset, plypos, ent:GetAngles(), heloicon, 20, color_white, 30 )
            elseif IsValid( ent ) and ent:GetClass() == "cd2_au" and !ent:GetActive() then
                DrawCoordsOnMap( self, ent:GetPos() - viewoffset, plypos, ent:GetAngles(), Auicon, 15, color_white, 30 )
            end
        end
        
        
        --
        
        -- Players --
        local players = player_GetAll()

        for i = 1, #players do
            local otherplayer = players[ i ]
            if IsValid( otherplayer ) and otherplayer:IsCD2Agent() then
                DrawCoordsOnMap( self, otherplayer:GetPos() - viewoffset, plypos, otherplayer:EyeAngles(), playerarrow, ScreenScale( 3 ), otherplayer:GetPlayerColor():ToColor(), 30 )
            end
        end
        --

    
    end


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

function GM:ScoreboardShow() OpenIntelConsole() end
