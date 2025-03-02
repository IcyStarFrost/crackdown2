-- Draws the minimap
local blackish = Color( 39, 39, 39)
local downicon = Material( "crackdown2/ui/down.png", "smooth" )
local cellicon = Material( "crackdown2/ui/celltrackericon.png" )
local pingmat = Material( "crackdown2/ui/pingcircle.png" )
local playerarrow = Material( "crackdown2/ui/playerarrow.png" )
local beaconicon = Material( "crackdown2/ui/beacon.png" )
local Auicon = Material( "crackdown2/ui/auicon.png" )
local upicon = Material( "crackdown2/ui/up.png", "smooth" )
local heloicon = Material( "crackdown2/ui/helo.png", "smooth" )
local staricon = Material( "crackdown2/ui/star.png", "smooth" )
local FreakIcon = Material( "crackdown2/ui/freak.png", "smooth" )
local beaconblue = Color( 0, 217, 255 )
local cellwhite = Color( 255, 255, 255 )
local celltargetred = Color( 255, 51, 0 )
local agentdown = Material( "crackdown2/ui/agentdown.png", "smooth" )
local peacekeeper = Material( "crackdown2/ui/peacekeeper.png", "smooth" )
local cell = Material( "crackdown2/ui/cell.png", "smooth" )

local ping_locations = {}

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

function CD2.HUDCOMPONENENTS.components.Minimap( ply, scrw, scrh, hudscale )
    if !ply:Alive() then return end
    
    local fov = 15

    draw.NoTexture()
    surface.SetDrawColor( blackish )
    CD2:DrawCircle( 200, scrh - 200, ScreenScale( 50 ), 30 )

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