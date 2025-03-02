-- Draws the crosshair

local shadedwhite = Color( 177, 177, 177 )
local red = Color( 163, 12, 12)
local orangeish = Color( 202, 79, 22)
local blackish = Color( 39, 39, 39)
local hex = Material( "crackdown2/ui/hex.png", "smooth" )

function CD2.HUDCOMPONENENTS.components.Crosshair( ply, scrw, scrh, hudscale )
    if !ply:Alive() then return end

    draw.NoTexture()
    surface.SetDrawColor( !CD2.lockon and shadedwhite or red )
    CD2:DrawCircle( scrw / 2, scrh / 2, 2, 30 )

    if CD2.lockon then
        local target = ply:GetLockonTarget()
        surface.DrawLine( ( scrw / 2 ), ( scrh / 2 ) + 10, ( scrw / 2 ), ( scrh / 2 ) + 20 )
        surface.DrawLine( ( scrw / 2 ), ( scrh / 2 ) - 10, ( scrw / 2 ), ( scrh / 2 ) - 20 )
        surface.DrawLine( ( scrw / 2 ) + 10, ( scrh / 2 ), ( scrw / 2 ) + 20, ( scrh / 2 ) )
        surface.DrawLine( ( scrw / 2 ) - 10, ( scrh / 2 ), ( scrw / 2 ) - 20, ( scrh / 2 ) )

        if IsValid( target ) then
            local spread = ply:GetLockonSpreadDecay() * 500
            surface.SetDrawColor( shadedwhite )
            surface.SetMaterial( hex )
            surface.DrawTexturedRectRotated( ( scrw / 2 ), ( scrh / 2 ), spread, spread, ( SysTime() * 300 ) )
        end
    end

    -- HEALTH BARS --
    local lockables = CD2:FindInLockableTragets( ply )
    local target = ply.CD2_lockontarget or lockables[ 1 ]

    if IsValid( target ) then 
        local toscreen = ( target:GetPos() + Vector( 0, 0, target:GetModelRadius() ) ):ToScreen()
    
        surface.SetDrawColor( blackish )
        surface.DrawRect( toscreen.x - 30, toscreen.y, 60, 12 )

        surface.SetDrawColor( orangeish )
        surface.DrawRect( toscreen.x - 28, toscreen.y + 2, ( target:GetNW2Float( "cd2_health", 0 ) / target:GetMaxHealth() ) * 56, 8 )
    
    end
end