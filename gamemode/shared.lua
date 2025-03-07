local string_StartWith = string.StartWith
local include = include
local print = print
local ipairs = ipairs

GM.Name = "CRACKDOWN 2"

CD2 = CD2 or {}

if CLIENT then 
    CD2.HUD_SCALE = ScreenScaleH( 0.44 )
end


local function IncludeDirectory( directory )
    directory = directory .. "/"

    
    local lua, dirs = file.Find( directory .. "*", "LUA", "namedesc" )

    for k, luafile in ipairs( lua ) do 
        if string_StartWith( luafile, "sv_") and SERVER then
            include( directory .. luafile )
            print( "Crackdown 2: Loaded Server-Side Lua File: " .. directory .. luafile )
        elseif string_StartWith( luafile, "sh_" ) then
            if SERVER then
                AddCSLuaFile( directory .. luafile )
            end
            include( directory .. luafile )
            print( "Crackdown 2: Loaded Shared Lua File: " .. directory .. luafile )
        elseif string_StartWith( luafile, "cl_" ) then
            if SERVER then
                AddCSLuaFile( directory .. luafile )
            elseif CLIENT then
                include( directory .. luafile )
                print( "Crackdown 2: Loaded Client-Side Lua File: " .. directory .. luafile )
            end
        end
    end

    for k, dir in ipairs( dirs ) do
        IncludeDirectory( directory .. dir )
        print( "Crackdown 2: Loading Directory " .. directory .. dir )
    end

end

if SERVER then
    AddCSLuaFile( "cd2globalfunctions.lua" )
    AddCSLuaFile( "cd2convars.lua" )
    AddCSLuaFile( "cd2_filesystem.lua" )
    AddCSLuaFile( "cd2_fonts.lua" )
end
include( "cd2globalfunctions.lua" )
include( "cd2_filesystem.lua" )
include( "cd2convars.lua" )

if CLIENT then include( "cd2_fonts.lua" ) end

IncludeDirectory( "crackdown2/gamemode/crackdown2" )

if SERVER then
    AddCSLuaFile( "player_class/cd2_player.lua" )
    AddCSLuaFile( "player_class/cd2_spectator.lua" )
end
include( "player_class/cd2_spectator.lua" )
include( "player_class/cd2_player.lua" )