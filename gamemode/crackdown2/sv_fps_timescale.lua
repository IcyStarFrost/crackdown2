local curscale = 1
hook.Add( "Tick", "crackdown2_fpstimescale", function()
    local fps = 1 / engine.AbsoluteFrameTime()
    local timescale = math.Clamp( ( fps / 30 ), 0.2, 1 )

    curscale = Lerp( FrameTime() / ( fps > 30 and 1 or 0.5 ), curscale, timescale)
    game.SetTimeScale( curscale )
end )