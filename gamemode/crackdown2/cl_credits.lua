

function CD2PlayCredits()
    local chan = CD2StartMusic( "sound/crackdown2/music/credits.mp3", 1000, nil, nil, 1 )

    local viewtbl = {}

    CD2CreateThread( function()
        CD2_DrawAgilitySkill = false
        CD2_DrawFirearmSkill = false
        CD2_DrawStrengthSkill = false
        CD2_DrawExplosiveSkill = false

        CD2_DrawTargetting = false
        CD2_DrawHealthandShields = false
        CD2_DrawWeaponInfo = false
        CD2_DrawMinimap = false
        CD2_DrawBlackbars = true

        local nextchange = SysTime() + 4
        local pos = LocalPlayer():GetPos() + Vector( math.random( -5000, 5000 ), math.random( -5000, 5000 ), ( math.random( 1, 3 ) == 1 and math.random( 10, 5000 ) or 10 ) )
        local lerppos = LocalPlayer():GetPos() + Vector( math.random( -5000, 5000 ), math.random( -5000, 5000 ), ( math.random( 1, 3 ) == 1 and math.random( 10, 5000 ) or 10 ) )
        local ang = math.random( 1, 3 ) == 1 and ( LocalPlayer():GetPos() - pos ):Angle() or Angle( math.random( -30, 0 ), math.random( -180, 180 ), 0 )
        CD2_ViewOverride = function( ply, origin, angles, fov, znear, zfar )

            if SysTime() > nextchange then
                pos = LocalPlayer():GetPos() + Vector( math.random( -5000, 5000 ), math.random( -5000, 5000 ), ( math.random( 1, 3 ) == 1 and math.random( 10, 5000 ) or 10 ) )
                lerppos = LocalPlayer():GetPos() + Vector( math.random( -5000, 5000 ), math.random( -5000, 5000 ), ( math.random( 1, 3 ) == 1 and math.random( 10, 5000 ) or 10 ) )
                ang = math.random( 1, 3 ) == 1 and ( LocalPlayer():GetPos() - pos ):Angle() or Angle( math.random( -30, 0 ), math.random( -180, 180 ), 0 )
            end

            viewtbl.origin = pos
            viewtbl.angles = ang
            viewtbl.fov = 60
            viewtbl.znear = znear
            viewtbl.zfar = zfar
            viewtbl.drawviewer = true

            pos = LerpVector( 0.1 * FrameTime(), pos, lerppos )

            return viewtbl
        end

        while !CD2_StopCredits do coroutine.yield() end
        CD2_StopCredits = false

        if chan and chan:IsValid() then chan:FadeOut() end

        CD2_DrawAgilitySkill = true
        CD2_DrawFirearmSkill = true
        CD2_DrawStrengthSkill = true
        CD2_DrawExplosiveSkill = true

        CD2_DrawTargetting = true
        CD2_DrawHealthandShields = true
        CD2_DrawWeaponInfo = true
        CD2_DrawMinimap = true
        CD2_DrawBlackbars = false
        CD2_ViewOverride = nil

    end )
end