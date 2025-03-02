-- Draws the health and shield bars
local hpred = Color( 163, 12, 12)
local orangeish = Color( 202, 79, 22)
local blackish = Color( 39, 39, 39)

local hplerp = -1
local shieldlerp = -1
local lastshield
local damagehexalpha = 0

local damagehexmat = Material( "crackdown2/ui/damagehex.png", "smooth" )

function CD2.HUDCOMPONENENTS.components.HealthAndShields( ply, scrw, scrh, hudscale )
    if !ply:Alive() then return end
    
    local hp, shield, maxshields, hpbars = ply:Health(), math.Clamp( ply:Armor(), 0, 100 ), ply:GetMaxArmor(), ( math.ceil( ply:Health() / 100 ) )

    lastshield = lastshield or shield
    hplerp = hplerp == -1 and hp or hplerp
    shieldlerp = shieldlerp == -1 and shield or shieldlerp

    local modulate =  ( ( hp % 100 ) / 100 ) * ScreenScale( 96 )
    hplerp = Lerp( 30 * FrameTime(), hplerp, modulate == 0 and ScreenScale( 96 ) or modulate)
    shieldlerp = Lerp( 30 * FrameTime(), shieldlerp, ( shield / maxshields ) * ScreenScale( 96 ) )

    surface.SetDrawColor( blackish )
    surface.DrawRect( 70, 50, ScreenScale( 100 ), 35 )

    if hpbars > 1 then
        surface.SetDrawColor( blackish )
        surface.DrawRect( 70, 80, ScreenScale( 30 ), 13 )

        for i = 1, hpbars do
            if i == 1 then continue end
            draw.NoTexture()
            surface.SetDrawColor( orangeish )
            CD2:DrawCircle( 60 + ( 20 * ( i - 1 ) ), 90, math.ceil( ScreenScale( 2.5 ) ), 6, 30 )
        end
    end


    surface.SetDrawColor( color_white )
    surface.DrawRect( 75, 55, shieldlerp, 10 )

    if hpbars == 1 then
        hpred.r = math.max( 30, ( math.abs( math.sin( SysTime() * 1.5 ) * 163 ) ), ( math.abs( math.cos( SysTime() * 1.5 ) * 163 ) ) )
        hpred.g = ( math.abs( math.sin( SysTime() * 1.5 ) * 12 ) )
        hpred.b = ( math.abs( math.sin( SysTime() * 1.5 ) * 12 ) )
    end

    surface.SetDrawColor( hpbars > 1 and orangeish or hpred  )
    surface.DrawRect( 75, 70, hplerp, 10 )

    if shield - lastshield < 0 and shield > 0 then
        damagehexalpha = 80
    end

    lastshield = shield
    damagehexalpha = Lerp( 5 * FrameTime(), damagehexalpha, 0 )

    surface.SetDrawColor( 255, 255, 255, damagehexalpha )
    surface.SetMaterial( damagehexmat )
    surface.DrawTexturedRect( 0, 0, scrw, scrh )

end