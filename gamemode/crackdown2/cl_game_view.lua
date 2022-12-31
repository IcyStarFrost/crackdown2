-- View stuff. This took way too long to figure out --

local Lerp = Lerp
local Vector = Vector
local Angle = Angle
local LerpAngle = LerpAngle
local FrameTime = FrameTime
local Trace = util.TraceLine
local clamp = math.Clamp
local calctable = {} -- Recycled table

local plyangle -- The angle our player is facing
CD2_viewlockedon = false
local lockonoffset = Vector()
local zerovec = Vector()
local viewtrace = {}

CD2_vieworigin = nil -- Our view origin
CD2_viewangles = Angle() -- Our view angles
CD2_fieldofview = nil -- Our field of view

function GM:CalcView( ply, origin, angles, fov, znear, zfar )

    if CD2_ViewOverride then
        return CD2_ViewOverride( ply, origin, angles, fov, znear, zfar )
    end

    CD2_fieldofview = CD2_fieldofview or fov
    if !ply:IsCD2Agent() then return end

    if ply:Alive() then

        viewtrace.start = ( origin + Vector( 0, 0, 18 ) ) + lockonoffset
        viewtrace.endpos = ( ( origin + Vector( 0, 0, 18 ) ) - CD2_viewangles:Forward() * 130 ) + lockonoffset
        viewtrace.filter = ply
        local result = Trace( viewtrace )
        local pos = result.HitPos - result.Normal * 8

        if CD2_viewlockedon then
            lockonoffset = LerpVector( 20 * FrameTime(), lockonoffset, ( CD2_viewangles:Right() * 30 - Vector( 0, 0, 10 ) ) )
            CD2_fieldofview = Lerp( 20 * FrameTime(), CD2_fieldofview, 60 )
        else
            lockonoffset = LerpVector( 20 * FrameTime(), lockonoffset, zerovec )
            CD2_fieldofview = Lerp( 20 * FrameTime(), CD2_fieldofview, fov )
        end

        CD2_vieworigin = pos
        calctable.origin = pos
        calctable.angles = CD2_viewangles
        calctable.fov = CD2_fieldofview
        calctable.znear = znear
        calctable.zfar = zfar
        calctable.drawviewer  = true

        return calctable

    else
        local ragdoll = ply:GetRagdollEntity()

        if !IsValid( ragdoll ) then return end

        local ang = Angle( 0, SysTime() * 2, 0 )
        viewtrace.start = ragdoll:GetPos() + Vector( 0, 0, 10 )
        viewtrace.endpos = ( ragdoll:GetPos() + Vector( 0, 0, 10 ) ) - ang:Forward() * 100
        local result = Trace( viewtrace )

        CD2_fieldofview = Lerp( 5 * FrameTime(), CD2_fieldofview, 50 )

        local pos = result.HitPos - result.Normal * 8

        calctable.origin = pos
        calctable.angles = ang
        calctable.fov = CD2_fieldofview
        calctable.znear = znear
        calctable.zfar = zfar
        calctable.drawviewer  = true

        return calctable

    end
end


local lookatcursorTime = 0
local switchcooldown = 0
function GM:CreateMove( cmd )
    if CD2_PreventMovement then cmd:ClearMovement() cmd:ClearButtons() end
    local self = LocalPlayer()

    if !self:IsCD2Agent() then return end

    local vec = Vector( cmd:GetForwardMove(), -cmd:GetSideMove(), 0 )

    if !plyangle then
        CD2_viewangles = self:EyeAngles()
        plyangle = CD2_viewangles * 1
    end

    vec:Rotate( Angle( CD2_viewangles[ 1 ], CD2_viewangles[ 2 ], CD2_viewangles[ 3 ] ) )


    CD2_viewangles[ 2 ] = CD2_viewangles[ 2 ] - cmd:GetMouseX() * 0.02
    
    CD2_viewangles[ 1 ] = clamp( CD2_viewangles[ 1 ] +  cmd:GetMouseY() * 0.02, -90, 90 )

    plyangle[ 1 ] = CD2_viewangles[ 1 ]

    
    local lockontarget = self:GetNW2Entity( "cd2_lockontarget", nil )

    if IsValid( lockontarget ) and cmd:GetMouseY() < 0 then
        CD2_LockOnPos = "head"
    elseif !IsValid( lockontarget ) or cmd:GetMouseY() > 0 then
        CD2_LockOnPos = "body"
    end


    if cmd:GetMouseWheel() != 0 and CurTime() > switchcooldown then 
        for k, wep in ipairs( self:GetWeapons() ) do
            if wep != self:GetActiveWeapon() then cmd:SelectWeapon( wep ) break end
        end
        switchcooldown = CurTime() + 0.2
    end
    if cmd:KeyDown( IN_ATTACK ) and !cmd:KeyDown( IN_USE ) or cmd:KeyDown( IN_ATTACK2 ) or cmd:KeyDown( IN_GRENADE1 ) then lookatcursorTime = CurTime() + 1 end
    
    if CurTime() < lookatcursorTime then plyangle = CD2_viewangles * 1 cmd:SetViewAngles( CD2_viewangles ) return end

    if cmd:GetForwardMove() != 0 or cmd:GetSideMove() != 0 then
        plyangle = vec:Angle()
        cmd:SetViewAngles( LerpAngle( FrameTime() * 20, cmd:GetViewAngles(), plyangle ) )
        cmd:SetForwardMove( self:GetRunSpeed() )
        cmd:SetSideMove( 0 )
    else
        cmd:SetViewAngles( plyangle )
    end
end