local random = math.random

-- Returns if the current game time is day
function CD2IsDay()
    return GetGlobalBool( "cd2_isday", false )
end

if SERVER then
    util.AddNetworkString( "cd2net_dawndusk_changetime" )

    SetGlobalBool( "cd2_isday", true )
    
    CD2.NextTimeChange = CurTime() + 720
    CD2.FreezeTime = false -- Freezes time

    local lasttime = CD2.NextTimeChange
    local debugupdate = CurTime() + 60

    hook.Add( "Tick", "crackdown2_dawnduskcycle", function()
        if CD2.FreezeTime then CD2.NextTimeChange = lasttime return end
        if CurTime() > debugupdate then
            CD2:DebugMessage( "Next time change will occur in " .. tostring( string.NiceTime( CD2.NextTimeChange - CurTime(), 0 ) ) )
            debugupdate = CurTime() + 60
        end

        if CurTime() > CD2.NextTimeChange then
            CD2.NextFreakSpawn = CurTime() + 10
            SetGlobalBool( "cd2_isday", !GetGlobalBool( "cd2_isday", false ) )

            CD2:DebugMessage( "Time is now changing to " .. ( GetGlobalBool( "cd2_isday", false ) and "Dawn" or "Dusk" ) )

            net.Start( "cd2net_dawndusk_changetime" )
            net.WriteBool( GetGlobalBool( "cd2_isday", false ) )
            net.Broadcast()

            CD2.NextTimeChange = CurTime() + 720
        end

        lasttime = CD2.NextTimeChange
    end )

elseif CLIENT then

    net.Receive( "cd2net_dawndusk_changetime", function()
        local isdawn = net.ReadBool()
    
        if isdawn then
            CD2:StartMusic( "sound/crackdown2/music/duskdawn/dawn" .. random( 1, 5 ) .. ".mp3", 4, false, false )
        else
            CD2:StartMusic( "sound/crackdown2/music/duskdawn/dusk" .. random( 1, 5 ) .. ".mp3", 4, false, false )
        end
    end )

end