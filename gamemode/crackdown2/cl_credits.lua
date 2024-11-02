

function CD2PlayCredits()
    local chan = CD2StartMusic( "sound/crackdown2/music/credits.mp3", 1000, nil, nil, 1 )

    local viewtbl = {}

    CD2:CreateThread( function()


        LocalPlayer():ScreenFade( SCREENFADE.IN, Color( 0, 0, 0 ), 4, 1 )
        CD2.DrawAgilitySkill = false
        CD2.DrawFirearmSkill = false
        CD2.DrawStrengthSkill = false
        CD2.DrawExplosiveSkill = false

        CD2.DrawTargetting = false
        CD2.DrawHealthandShields = false
        CD2.DrawWeaponInfo = false
        CD2.DrawMinimap = false
        CD2.DrawBlackbars = true

        CD2.PreventMovement = true

        local endcred = false

        hook.Add( "PlayerBindPress", "crackdown2_skipcredits", function( ply, bind, pressed, code ) 
            local key = input.LookupBinding( "+use" )
            local keycode = input.GetKeyCode( key )

            if keycode == code then
                endcred = true
                hook.Remove( "PlayerBindPress", "crackdown2_skipcredits" )
            end
        end )

        local function DrawCredit( toptext, bottomtext )
            local object = {}
            local drawing = true
            local showtext = CurTime() + 3
            local topcolor = Color( 255, 115, 0, 0 )
            local bottomcolor = Color( 255, 255, 255, 0 )
            
            function object:IsValid() return drawing end

            local id = tostring( object )
            hook.Add( "HUDPaint", "crackdown2_credit" .. id, function()
                if endcred then hook.Remove( "HUDPaint", object ) return end
                if CurTime() < showtext then
                    topcolor.a = Lerp( 3 * FrameTime(), topcolor.a, 255 )
                    bottomcolor.a = Lerp( 3 * FrameTime(), bottomcolor.a, 255 )
                else
                    topcolor.a = Lerp( 3 * FrameTime(), topcolor.a, 0 )
                    bottomcolor.a = Lerp( 3 * FrameTime(), bottomcolor.a, 0 )
                    if topcolor.a < 10 and bottomcolor.a < 10 then
                        drawing = false
                        hook.Remove( "HUDPaint", "crackdown2_credit" .. id )
                    end
                end

                draw.DrawText( toptext, "crackdown2_font50", 200, ScrH() / 2, topcolor, TEXT_ALIGN_LEFT )
                draw.DrawText( bottomtext, "crackdown2_font50", 200, ScrH() / 2 + 60, bottomcolor, TEXT_ALIGN_LEFT )
            end )

            return object
        end
        CD2:CreateThread( function()

            coroutine.wait( 2 )
            local usebind = input.LookupBinding( "+use" )
            local credit = DrawCredit( "Press " .. string.upper( usebind ) .. " to skip the credits", "" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            local credit = DrawCredit( "CRACKDOWN 2", "Garry's Mod Gamemode Recreation by StarFrost" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Game Developer:", "Ruffian Games" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "CRACKDOWN Series Founder:", "David Jones of Realtime Worlds" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Creative Director:", "Billy Thomson" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Producor:", "James Cope" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Leads:", "Stuart Campbell\nIain Donald\nMike Enoch\nChris Gottgetreu" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Leads:", "Steve Iannetta\nRoss Nicoll\nNeil Pollock\nPaul Simms" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Design:", "Ed Campbell\nMartin Livingston\nSean Noonan" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Design:", "Dean Smith\nGraham Wright" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Code:", "Leigh Bird\nBarry Cairns\nRobert Cowsill\nTerryDrever" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Code:", "Neil Duffield\nKarim El-Shakankiri\nDuncan Harrison\nAndrew Heywood" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Code:", "David Hynd\nJohn Hynd\nS L\nPeter Mackay" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Code:", "Will Sykes\nCraig Thomson\nRichard Welsh" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Art:", "Ryan Astley\nKevin Dunlop\nCarlos Garcia\nPaul Large" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Art:", "Stewart Neal\nNeil Macnaughton\nPaulie Simms\nRichard Wazejewski" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original QA:", "Kevin Black\nSean Branney\nAmy Buttress\nGregor Hare" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original QA:", "David Hoare\nSimon Kilroy\nEwan Mckenzie\nJohn Pettie" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Studio:", "Steven Randell\nKirsty Scott\nGavin Howie" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Development Director:", "Gareth Noyce" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Original Studio Head:", "Gaz Liddon" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Special thanks:", "Xenia Emulator which made extracting game sounds possible" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end
            
            credit = DrawCredit( "Special thanks:", "Pyri for finding the original game music" )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            credit = DrawCredit( "Thank you For playing, Agent!", "" .. game.GetMap() .. " was only the beginning.." )
            while credit:IsValid() do coroutine.yield() end
            if endcred then return end

            endcred = true
            hook.Remove( "PlayerBindPress", "crackdown2_skipcredits" )

        end )

        local nextchange = SysTime() + 4
        local pos = LocalPlayer():GetPos() + Vector( math.random( -5000, 5000 ), math.random( -5000, 5000 ), ( math.random( 1, 3 ) == 1 and math.random( 10, 5000 ) or 10 ) )
        local lerppos = LocalPlayer():GetPos() + Vector( math.random( -5000, 5000 ), math.random( -5000, 5000 ), ( math.random( 1, 3 ) == 1 and math.random( 10, 5000 ) or 10 ) )
        local ang = math.random( 1, 3 ) == 1 and ( LocalPlayer():GetPos() - pos ):Angle() or Angle( math.random( -30, 30 ), math.random( -180, 180 ), 0 )
        CD2.ViewOverride = function( ply, origin, angles, fov, znear, zfar )

            if SysTime() > nextchange then
                pos = LocalPlayer():GetPos() + Vector( math.random( -5000, 5000 ), math.random( -5000, 5000 ), ( math.random( 1, 3 ) == 1 and math.random( 10, 5000 ) or 10 ) )
                lerppos = LocalPlayer():GetPos() + Vector( math.random( -5000, 5000 ), math.random( -5000, 5000 ), ( math.random( 1, 3 ) == 1 and math.random( 10, 5000 ) or 10 ) )
                ang = math.random( 1, 3 ) == 1 and ( LocalPlayer():GetPos() - pos ):Angle() or Angle( math.random( -30, 30 ), math.random( -180, 180 ), 0 )
                nextchange = SysTime() + 4
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

        while !CD2_StopCredits and !endcred do coroutine.yield() end
        LocalPlayer():ScreenFade( SCREENFADE.IN, Color( 0, 0, 0 ), 4, 1 )

        CD2_StopCredits = false
        endcred = true
        if chan and chan:IsValid() then chan:FadeOut() end

        CD2.DrawAgilitySkill = true
        CD2.DrawFirearmSkill = true
        CD2.DrawStrengthSkill = true
        CD2.DrawExplosiveSkill = true

        CD2.DrawTargetting = true
        CD2.DrawHealthandShields = true
        CD2.DrawWeaponInfo = true
        CD2.DrawMinimap = true
        CD2.DrawBlackbars = false
        CD2.ViewOverride = nil

        CD2.PreventMovement = false

        if !CD2:KeysToTheCity() and !CD2:ReadPlayerData( "cd2_finishedgame" ) then
            CD2StartMusic( "sound/crackdown2/music/victory.mp3", 1000 )
            sound.PlayFile( "sound/crackdown2/vo/agencydirector/ending_achievement.mp3", "noplay", function( snd, id, name ) snd:SetVolume( 10 ) snd:Play() end )
            CD2:WritePlayerData( "cd2_finishedgame", true )
        end

    end )
end