local agentdown = Material( "crackdown2/ui/agentdown.png", "smooth" )

function CD2.HUDCOMPONENENTS.components.MultiplayerHud( ply, scrw, scrh, hudscale )
    if !game.SinglePlayer() and GetConVar( "cd2_drawhud" ):GetBool() then
        for k, v in ipairs( player.GetAll() ) do
            if v == LocalPlayer() or !v:IsCD2Agent() then continue end
            local ent = IsValid( v:GetRagdollEntity() ) and v:GetRagdollEntity() or v
            local screen = ( ent:GetPos() + Vector( 0, 0, 100 ) ):ToScreen()
            draw.DrawText( v:Name(), "crackdown2_agentnames", screen.x, screen.y, v:GetPlayerColor():ToColor(), TEXT_ALIGN_CENTER )

            if !v:Alive() then 
                local screen = ( ent:GetPos() + Vector( 0, 0, 10 ) ):ToScreen()
                surface.SetMaterial( agentdown )
                surface.SetDrawColor( color_white )
                surface.DrawTexturedRect( screen.x - 65, screen.y - 25, 130, 70 )
            end
        end
    end
end

-- Connect messages --
hook.Add( "PlayerConnect", "crackdown2_connectmessage", function( name )
    if game.SinglePlayer() then return end
    CD2SetTextBoxText( name .. " joined the game" )
end )

gameevent.Listen( "player_disconnect" )

hook.Add( "player_disconnect", "crackdown2_disconnectmessage", function( data )
    if game.SinglePlayer() then return end
    CD2SetTextBoxText( data.name .. " left the game (" .. data.reason .. ")"  )
end )