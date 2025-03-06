-- New CD2 hook with the purpose of working around prediction
-- Input hooks aren't called on the client in singleplayer so we must do this to get around that.

if SERVER then
    hook.Add("PlayerButtonDown", "crackdown2_buttondown", function( ply, button )
        net.Start( "cd2net_inputpressed" )
        net.WriteUInt( button, 32 )
        net.Send( ply )

        hook.Run( "CD2_ButtonPressed", ply, button )
    end )

elseif CLIENT then

    net.Receive( "cd2net_inputpressed", function()
        local button = net.ReadUInt( 32 )
        hook.Run( "CD2_ButtonPressed", LocalPlayer(), button )
    end )
end