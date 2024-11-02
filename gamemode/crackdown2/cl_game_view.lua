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

CD2.plyangle = nil -- The angle our player is facing

CD2.viewlockedon = false
CD2.lockonoffset = Vector()

local viewtrace = {}

CD2.Freecampos = Vector()
CD2.FreecamFOV = 70
CD2.FreecamAngles = Angle()

CD2.vieworigin = Vector() -- Our view origin
CD2.viewangles = Angle() -- Our view angles
CD2.fieldofview = 60 -- Our field of view

function GM:CalcView( ply, origin, angles, fov, znear, zfar )

    if CD2.FreeCamMode then
        calctable.origin = CD2.Freecampos
        calctable.angles = CD2.FreecamAngles
        calctable.fov = CD2.FreecamFOV
        calctable.znear = znear
        calctable.zfar = zfar
        calctable.drawviewer  = true
        return calctable
    end

    if CD2.ViewOverride then
        local result = CD2.ViewOverride( ply, origin, angles, fov, znear, zfar )
        if result then return result end 
    end

    CD2.fieldofview = CD2.fieldofview or fov
    if !ply:IsCD2Agent() then return end

    if ply:Alive() then

        viewtrace.start = ( origin + Vector( 0, 0, 18 ) ) + CD2.lockonoffset
        viewtrace.endpos = ( ( origin + Vector( 0, 0, 18 ) ) - CD2.viewangles:Forward() * 130 ) + CD2.lockonoffset
        viewtrace.filter = ply
        local result = Trace( viewtrace )
        local pos = result.HitPos - result.Normal * 8

        if CD2.viewlockedon then
            CD2.lockonoffset = LerpVector( 20 * FrameTime(), CD2.lockonoffset, ( CD2.viewangles:Right() * 30 - Vector( 0, 0, 10 ) ) )
            CD2.fieldofview = Lerp( 20 * FrameTime(), CD2.fieldofview, 60 )
        else
            CD2.lockonoffset = LerpVector( 20 * FrameTime(), CD2.lockonoffset, zerovec )
            CD2.fieldofview = Lerp( 20 * FrameTime(), CD2.fieldofview, fov )
        end

        CD2.vieworigin = pos

        CD2.lerpfreecam = CD2.viewangles
        CD2.lerpfreecampos = pos
        CD2.FreecamAngles = CD2.viewangles
        CD2.Freecampos = pos
        CD2.FreecamFOV = CD2.fieldofview

        calctable.origin = pos
        calctable.angles = CD2.viewangles
        calctable.fov = CD2.fieldofview
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

        CD2.fieldofview = Lerp( 5 * FrameTime(), CD2.fieldofview, 50 )

        local pos = result.HitPos - result.Normal * 8

        calctable.origin = pos
        calctable.angles = ang
        calctable.fov = CD2.fieldofview
        calctable.znear = znear
        calctable.zfar = zfar
        calctable.drawviewer  = true

        return calctable

    end
end


local lookatcursorTime = 0
local switchcooldown = 0

function GM:CreateMove( cmd )

    if CD2.FreeCamMode then
        local vec = Vector()
        if cmd:KeyDown( IN_FORWARD ) then
            vec = vec + CD2.FreecamAngles:Forward() * 5
        elseif cmd:KeyDown( IN_BACK ) then
            vec = vec + -CD2.FreecamAngles:Forward() * 5
        end

        if cmd:KeyDown( IN_MOVERIGHT ) then
            vec = vec + CD2.FreecamAngles:Right() * 5
        elseif cmd:KeyDown( IN_MOVELEFT ) then
            vec = vec + -CD2.FreecamAngles:Right() * 5
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
        CD2.lerpfreecam = CD2.lerpfreecam or CD2.viewangles * 1
        CD2.lerpfreecampos = CD2.lerpfreecampos or CD2.vieworigin * 1
        CD2.lerpfreecamfov = CD2.lerpfreecamfov or CD2.fieldofview * 1
        
        CD2.lerpfreecamfov = math.Clamp( CD2.lerpfreecamfov + cmd:GetMouseWheel(), 10, 90 )
        CD2.FreecamFOV = Lerp( ( !cmd:KeyDown( IN_DUCK ) and 4 or 0.6 ) * FrameTime(), CD2.FreecamFOV, CD2.lerpfreecamfov )

        CD2.lerpfreecampos = CD2.lerpfreecampos + vec
        CD2.lerpfreecam[ 2 ] = CD2.lerpfreecam[ 2 ] - cmd:GetMouseX() * 0.02
        CD2.lerpfreecam[ 1 ] = clamp( CD2.lerpfreecam[ 1 ] + cmd:GetMouseY() * 0.02, -90, 90 )

        CD2.FreecamAngles = LerpAngle( ( !cmd:KeyDown( IN_DUCK ) and 4 or 0.6 ) * FrameTime(), CD2.FreecamAngles, CD2.lerpfreecam )
        CD2.Freecampos = LerpVector( ( !cmd:KeyDown( IN_DUCK ) and 4 or 0.6 ) * FrameTime(), CD2.Freecampos, CD2.lerpfreecampos )

        cmd:ClearMovement()
        cmd:ClearButtons()
    end


    if CD2.PreventMovement then cmd:ClearMovement() cmd:ClearButtons() end
    local self = LocalPlayer()

    if !self:IsCD2Agent() then return end

    local vec = Vector( cmd:GetForwardMove(), -cmd:GetSideMove(), 0 )

    if !CD2.plyangle then
        CD2.viewangles = self:EyeAngles()
        CD2.plyangle = CD2.viewangles * 1
    end

    vec:Rotate( Angle( CD2.viewangles[ 1 ], CD2.viewangles[ 2 ], CD2.viewangles[ 3 ] ) )

    local lockontarget = self:GetNW2Entity( "cd2_lockontarget", nil )

    if IsValid( lockontarget ) and !lockontarget.cd2_NoHeadShot and ( lockontarget:IsCD2Agent() or lockontarget:IsCD2NPC() ) and cmd:GetMouseY() < -100 then
        CD2.LockOnPos = "head"
    elseif !IsValid( lockontarget ) or cmd:GetMouseY() > 100 then
        CD2.LockOnPos = "body"
    end


    
    if IsValid( lockontarget ) then
        cmd:SetMouseX( 0 )
        cmd:SetMouseY( 0 )
    end


    CD2.viewangles[ 2 ] = CD2.viewangles[ 2 ] - cmd:GetMouseX() * 0.02
    
    CD2.viewangles[ 1 ] = clamp( CD2.viewangles[ 1 ] +  cmd:GetMouseY() * 0.02, -90, 90 )

    if !CD2.PreventMovement then CD2.plyangle[ 1 ] = CD2.viewangles[ 1 ] end



    if !CD2.FreeCamMode and cmd:GetMouseWheel() != 0 and CurTime() > switchcooldown then 
        for k, wep in ipairs( self:GetWeapons() ) do
            if wep != self:GetActiveWeapon() and !self:GetActiveWeapon():GetIsHolstering() then cmd:SelectWeapon( wep ) break end
        end
        switchcooldown = CurTime() + 0.2
    end
    if !CD2.FreeCamMode and cmd:KeyDown( IN_ATTACK ) and !cmd:KeyDown( IN_USE ) or cmd:KeyDown( IN_ATTACK2 ) or cmd:KeyDown( IN_GRENADE1 ) then lookatcursorTime = CurTime() + 1 end
    
    if CurTime() < lookatcursorTime then CD2.plyangle = CD2.viewangles * 1 cmd:SetViewAngles( CD2.viewangles ) return end

    if cmd:GetForwardMove() != 0 or cmd:GetSideMove() != 0 then
        CD2.plyangle = vec:Angle()
        cmd:SetViewAngles( LerpAngle( FrameTime() * 20, cmd:GetViewAngles(), CD2.plyangle ) )
        cmd:SetForwardMove( self:GetRunSpeed() )
        cmd:SetSideMove( 0 )
    else
        cmd:SetViewAngles( CD2.plyangle )
    end
end