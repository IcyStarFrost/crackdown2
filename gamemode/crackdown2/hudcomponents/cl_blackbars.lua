local hlerp1
local hlerp2
local black = Color( 0, 0, 0 )

function CD2.HUDCOMPONENENTS.components.BlackBars( ply, scrw, scrh, hudscale )
    if CD2.DrawBlackbars then
        hlerp1 = hlerp1 or -150
        hlerp2 = hlerp2 or scrh

        hlerp1 = Lerp( 2 * FrameTime(), hlerp1, 0 )
        hlerp2 = Lerp( 2 * FrameTime(), hlerp2, scrh - 150 )

        surface.SetDrawColor( black )

        surface.DrawRect( 0, hlerp1, scrw, 150 )
        surface.DrawRect( 0, hlerp2, scrw, 150 )
    else
        hlerp1 = -100
        hlerp2 = scrh
    end
end