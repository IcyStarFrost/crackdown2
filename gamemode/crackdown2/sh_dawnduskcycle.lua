local random = math.random

-- Returns if the current game time is day
function CD2IsDay()
    return GetGlobalBool( "cd2_isday", false )
end

if SERVER then
    util.AddNetworkString( "cd2net_dawndusk_changetime" )

    SetGlobalBool( "cd2_isday", true )
    CD2_NextTimeChange = CurTime() + 720

    local debugupdate = CurTime() + 60

    hook.Add( "Tick", "crackdown2_dawnduskcycle", function()

        if CurTime() > debugupdate then
            CD2DebugMessage( "Next time change will occur in " .. tostring( math.Round( CD2_NextTimeChange, 0 ) ) .. " seconds" )
            debugupdate = CurTime() + 60
        end

        if CurTime() > CD2_NextTimeChange then
            SetGlobalBool( "cd2_isday", !GetGlobalBool( "cd2_isday", false ) )

            CD2DebugMessage( "Time is now changing to " .. ( GetGlobalBool( "cd2_isday", false ) and "Dawn" or "Dusk" ) )

            net.Start( "cd2net_dawndusk_changetime" )
            net.WriteBool( GetGlobalBool( "cd2_isday", false ) )
            net.Broadcast()

            CD2_NextTimeChange = CurTime() + 720
        end
    end )

elseif CLIENT then

    net.Receive( "cd2net_dawndusk_changetime", function()
        local isdawn = net.ReadBool()
    
        if isdawn then
            CD2StartMusic( "sound/crackdown2/music/duskdawn/dawn" .. random( 1, 5 ) .. ".mp3", 4, false, false )
        else
            CD2StartMusic( "sound/crackdown2/music/duskdawn/dusk" .. random( 1, 5 ) .. ".mp3", 4, false, false )
        end
    end )

end