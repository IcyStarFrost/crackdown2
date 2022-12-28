local player_GetAll = player.GetAll
local ipairs = ipairs

-- Clean decals every minute and 30 seconds
timer.Create( "crackdown2_decalcleaner", 90, 0, function()
    for k, v in ipairs( player_GetAll() ) do
        v:ConCommand( "r_cleardecals" )
    end
end )