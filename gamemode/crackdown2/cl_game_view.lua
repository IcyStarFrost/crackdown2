-- View stuff. This took way too long to figure out --

local Lerp = Lerp
local Vector = Vector
local Angle = Angle
local LerpAngle = LerpAngle
local FrameTime = FrameTime
local Trace = util.TraceLine
local clamp = math.Clamp
local zerovec = Vector()
local calctable = {} -- Recycled table

CD2_plyangle = nil -- The angle our player is facing

CD2_viewlockedon = false
CD2_lockonoffset = Vector()

local viewtrace = {}

CD2_Freecampos = Vector()
CD2_FreecamFOV = 70
CD2_FreecamAngles = Angle()

CD2_vieworigin = Vector() -- Our view origin
CD2_viewangles = Angle() -- Our view angles
CD2_fieldofview = 60 -- Our field of view

function GM:CalcView( ply, origin, angles, fov, znear, zfar )

    if CD2_FreeCamMode then
        calctable.origin = CD2_Freecampos
        calctable.angles = CD2_FreecamAngles
        calctable.fov = CD2_FreecamFOV
        calctable.znear = znear
        calctable.zfar = zfar
        calctable.drawviewer  = true
        return calctable
    end

    if CD2_ViewOverride then
        local result = CD2_ViewOverride( ply, origin, angles, fov, znear, zfar )
        if result then return result end 
    end

    CD2_fieldofview = CD2_fieldofview or fov
    if !ply:IsCD2Agent() then return end

    if ply:Alive() then

        viewtrace.start = ( origin + Vector( 0, 0, 18 ) ) + CD2_lockonoffset
        viewtrace.endpos = ( ( origin + Vector( 0, 0, 18 ) ) - CD2_viewangles:Forward() * 130 ) + CD2_lockonoffset
        viewtrace.filter = ply
        local result = Trace( viewtrace )
        local pos = result.HitPos - result.Normal * 8

        if CD2_viewlockedon then
            CD2_lockonoffset = LerpVector( 20 * FrameTime(), CD2_lockonoffset, ( CD2_viewangles:Right() * 30 - Vector( 0, 0, 10 ) ) )
            CD2_fieldofview = Lerp( 20 * FrameTime(), CD2_fieldofview, 60 )
        else
            CD2_lockonoffset = LerpVector( 20 * FrameTime(), CD2_lockonoffset, zerovec )
            CD2_fieldofview = Lerp( 20 * FrameTime(), CD2_fieldofview, fov )
        end

        CD2_vieworigin = pos

        CD2_lerpfreecam = CD2_viewangles
        CD2_lerpfreecampos = pos
        CD2_FreecamAngles = CD2_viewangles
        CD2_Freecampos = pos
        CD2_FreecamFOV = CD2_fieldofview

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

    if CD2_FreeCamMode then
        local vec = Vector()
        if cmd:KeyDown( IN_FORWARD ) then
            vec = vec + CD2_FreecamAngles:Forward() * 5
        elseif cmd:KeyDown( IN_BACK ) then
            vec = vec + -CD2_FreecamAngles:Forward() * 5
        end

        if cmd:KeyDown( IN_MOVERIGHT ) then
            vec = vec + CD2_FreecamAngles:Right() * 5
        elseif cmd:KeyDown( IN_MOVELEFT ) then
            vec = vec + -CD2_FreecamAngles:Right() * 5
        end

        if cmd:KeyDown( IN_JUMP ) then
            vec.z = 5
        elseif cmd:KeyDown( IN_WALK ) then
            vec.z = -5
        end

        if cmd:KeyDown( IN_SPEED ) then
            vec = vec * 2
        elseif cmd:KeyDown( IN_DUCK ) then 
            vec = vec / 2
        end
        CD2_lerpfreecam = CD2_lerpfreecam or CD2_viewangles * 1
        CD2_lerpfreecampos = CD2_lerpfreecampos or CD2_vieworigin * 1
        CD2_lerpfreecamfov = CD2_lerpfreecamfov or CD2_fieldofview * 1
        
        CD2_lerpfreecamfov = math.Clamp( CD2_lerpfreecamfov + cmd:GetMouseWheel(), 10, 90 )
        CD2_FreecamFOV = Lerp( ( !cmd:KeyDown( IN_DUCK ) and 4 or 0.6 ) * FrameTime(), CD2_FreecamFOV, CD2_lerpfreecamfov )

        CD2_lerpfreecampos = CD2_lerpfreecampos + vec
        CD2_lerpfreecam[ 2 ] = CD2_lerpfreecam[ 2 ] - cmd:GetMouseX() * 0.02
        CD2_lerpfreecam[ 1 ] = clamp( CD2_lerpfreecam[ 1 ] + cmd:GetMouseY() * 0.02, -90, 90 )

        CD2_FreecamAngles = LerpAngle( ( !cmd:KeyDown( IN_DUCK ) and 4 or 0.6 ) * FrameTime(), CD2_FreecamAngles, CD2_lerpfreecam )
        CD2_Freecampos = LerpVector( ( !cmd:KeyDown( IN_DUCK ) and 4 or 0.6 ) * FrameTime(), CD2_Freecampos, CD2_lerpfreecampos )

        cmd:ClearMovement()
        cmd:ClearButtons()
    end


    if CD2_PreventMovement then cmd:ClearMovement() cmd:ClearButtons() end
    local self = LocalPlayer()

    if !self:IsCD2Agent() then return end

    local vec = Vector( cmd:GetForwardMove(), -cmd:GetSideMove(), 0 )

    if !CD2_plyangle then
        CD2_viewangles = self:EyeAngles()
        CD2_plyangle = CD2_viewangles * 1
    end

    vec:Rotate( Angle( CD2_viewangles[ 1 ], CD2_viewangles[ 2 ], CD2_viewangles[ 3 ] ) )


    CD2_viewangles[ 2 ] = CD2_viewangles[ 2 ] - cmd:GetMouseX() * 0.02
    
    CD2_viewangles[ 1 ] = clamp( CD2_viewangles[ 1 ] +  cmd:GetMouseY() * 0.02, -90, 90 )

    CD2_plyangle[ 1 ] = CD2_viewangles[ 1 ]

    
    local lockontarget = self:GetNW2Entity( "cd2_lockontarget", nil )

    if IsValid( lockontarget ) and !lockontarget.cd2_NoHeadShot and ( lockontarget:IsCD2Agent() or lockontarget:IsCD2NPC() ) and cmd:GetMouseY() < 0 then
        CD2_LockOnPos = "head"
    elseif !IsValid( lockontarget ) or cmd:GetMouseY() > 0 then
        CD2_LockOnPos = "body"
    end


    if !CD2_FreeCamMode and cmd:GetMouseWheel() != 0 and CurTime() > switchcooldown then 
        for k, wep in ipairs( self:GetWeapons() ) do
            if wep != self:GetActiveWeapon() then cmd:SelectWeapon( wep ) break end
        end
        switchcooldown = CurTime() + 0.2
    end
    if !CD2_FreeCamMode and cmd:KeyDown( IN_ATTACK ) and !cmd:KeyDown( IN_USE ) or cmd:KeyDown( IN_ATTACK2 ) or cmd:KeyDown( IN_GRENADE1 ) then lookatcursorTime = CurTime() + 1 end
    
    if CurTime() < lookatcursorTime then CD2_plyangle = CD2_viewangles * 1 cmd:SetViewAngles( CD2_viewangles ) return end

    if cmd:GetForwardMove() != 0 or cmd:GetSideMove() != 0 then
        CD2_plyangle = vec:Angle()
        cmd:SetViewAngles( LerpAngle( FrameTime() * 20, cmd:GetViewAngles(), CD2_plyangle ) )
        cmd:SetForwardMove( self:GetRunSpeed() )
        cmd:SetSideMove( 0 )
    else
        cmd:SetViewAngles( CD2_plyangle )
    end
end