
local blur = Material( "pp/blurscreen" )
CD2_AgencyConsole = nil
CD2_CanOpenAgencyConsole = true
local surface_DrawRect = surface.DrawRect
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local blackish = Color( 39, 39, 39)
local mmTrace = {}
local Trace = util.TraceLine
local fadedwhite = Color( 255, 255, 255, 10 )

function OpenIntelConsole()

    if IsValid( CD2_AgencyConsole ) then 
        CD2_AgencyConsole:Remove() surface.PlaySound( "crackdown2/ui/ui_back.mp3" )
        
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
    toptext:SetFont( "crackdown2_dropmenutoptext" )
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

    local function Paint( self, w, h )
        surface_SetDrawColor( blackish )
        surface_DrawRect( 0, 0, w, h )

        surface_SetDrawColor( fadedwhite )
        surface_DrawOutlinedRect( 0, 0, w, h, 3 )
    end
    leftpnl.Paint = Paint
    rightpnl.Paint = Paint

    function midpnl:Paint( w, h )
        surface_SetDrawColor( blackish )
        surface_DrawRect( 0, 0, w, h )

        mmTrace.start = LocalPlayer():WorldSpaceCenter()
        mmTrace.endpos = LocalPlayer():GetPos() + Vector( 0, 0, 20000 )
        mmTrace.mask = MASK_SOLID_BRUSHONLY
        mmTrace.collisiongroup = COLLISION_GROUP_WORLD
        local result = Trace( mmTrace )

        local x, y = self:GetPos()

        render.RenderView( {
            origin = LocalPlayer():GetPos() + Vector( 0, 0, 20000 ),
            angles = Angle( 90, 0, 0 ),
            znear = result.Hit and result.HitPos:Distance( mmTrace.endpos ) or 10,
            fov = 20,
            x = x, y = y,
            w = w, h = h
        } )

        surface_SetDrawColor( fadedwhite )
        surface_DrawOutlinedRect( 0, 0, w, h, 3 )
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
