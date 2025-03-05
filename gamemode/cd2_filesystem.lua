local JSONToTable = util.JSONToTable
local TableToJSON = util.TableToJSON
local compress = util.Compress
local decompress = util.Decompress
local string_sub = string.sub
local table_concat = table.concat
print( "Crackdown2 Console: File System has been loaded")

file.CreateDir( "crackdown2" )
if SERVER then file.CreateDir( "crackdown2/mapdata" ) end

-- Data splitting done by https://github.com/alexgrist/NetStream
local function DataSplit( data )
    local index = 1
    local result = {}
    local buffer = {}

    for i = 0, #data do
        buffer[ #buffer + 1 ] = string_sub( data, i, i )
                
        if #buffer == 32768 then
            result[ #result + 1 ] = table_concat( buffer )
                index = index + 1
            buffer = {}
        end
    end
            
    result[ #result + 1 ] = table_concat( buffer )
    
    return result
end


-- The gamemode's custom file system. This is what handles the saving, loading, and general data players have

function CD2:Write( filename, contents )
    CD2:DebugMessage( "Writing to file " .. filename .. " with " .. tostring( contents ) )
	local f = file.Open( filename, "wb", "DATA" )
	if ( !f ) then return end

    contents = TableToJSON( contents )
    contents = compress( contents )

	f:Write( contents )
	f:Close()

end

function CD2:Read( filename )
    CD2:DebugMessage( "Reading from file " .. filename )

	local f = file.Open( filename, "rb", "DATA" )
	if ( !f ) then return end

	local contents = f:Read( f:Size() )
	f:Close()

    contents = decompress( contents )
    contents = JSONToTable( contents )

    CD2:DebugMessage( "Read " .. tostring( contents ) .. " from " .. filename )

	return contents
end


if SERVER then
    -- These functions are only used on the server. Completely useless to use on the client
    -- Writes a value to the current map's data. These two are typically used to save/load Agility Orbs and more
    function CD2:WriteMapData( var, any )
        if !file.Exists( "crackdown2/mapdata/" .. game.GetMap(), "DATA" ) then file.CreateDir( "crackdown2/mapdata/" .. game.GetMap() ) end
        if !file.Exists( "crackdown2/mapdata/" .. game.GetMap() .. "/data.dat", "DATA" ) then CD2:Write( "crackdown2/mapdata/" .. game.GetMap() .. "/data.dat", {} ) end
        local data = CD2:Read( "crackdown2/mapdata/" .. game.GetMap() .. "/data.dat" )
        data[ var ] = any
        CD2:Write( "crackdown2/mapdata/" .. game.GetMap() .. "/data.dat", data )
    end

    -- Removes the data file related to this map
    function CD2:ClearMapData()
        file.Delete( "crackdown2/mapdata/" .. game.GetMap() .. "/data.dat" )
    end

    -- Reads from the current map's data. These two are typically used to save/load Agility Orbs and more
    function CD2:ReadMapData( var )
        local data = CD2:Read( "crackdown2/mapdata/" .. game.GetMap() .. "/data.dat"  )
        return var != "TABLE" and data and data[ var ] or var == "TABLE" and data
    end

    -- Requests the specified variable value from the provided player's Agent data
    function CD2:RequestPlayerData( ply, var, callback )
        CD2:DebugMessage( "Requesting " .. var .. " from " .. ply:Name() .. "'s Agent data" )

        net.Start( "cd2filesystem_requestplayerdata" )
        net.WriteString( var )
        net.Send( ply )

        local chunks = ""

        -- Received when the player sends a chunk of the var we requested from
        net.Receive( "cd2filesystem_dispatchplayerdata", function( len, ply )
            local chunk = net.ReadString()
            local isdone = net.ReadBool()
            chunks = chunks .. chunk

            CD2:DebugMessage( "Received a data chunk from " .. ply:Name() .. " for " .. var  )

            if isdone then local tbl = JSONToTable( chunks ) local val = tbl and tbl[ 1 ] or nil callback( val ) CD2:DebugMessage( "Received all data chunks for " .. var ) end
        end )
    end

    -- Writes the specified value to the player's Agent data variable
    function CD2:WritePlayerData( ply, var, any )
        CD2:DebugMessage( "Writing to " .. ply:Name() .. "'s Agent data: var = " .. var .. " | value = " .. tostring( any ) )
        local tbl = TableToJSON( { any } )
        local chunks = DataSplit( tbl )

        for i = 1, #chunks do 
            net.Start( "cd2filesystem_dispatchplayerdata" )
            net.WriteString( chunks[ i ] )
            net.WriteString( var )
            net.WriteBool( i == #chunks )
            net.Send( ply )
        end
    end

end

if CLIENT then

    -- Writes a value to the Player's agent data
    function CD2:WritePlayerData( var, any )
        CD2:DebugMessage( "Writing to your Agent data: var = " .. var .. " | value = " .. tostring( any ) )
        local data = CD2:Read( "crackdown2/agentdata.dat" )
        data[ var ] = any
        CD2:Write( "crackdown2/agentdata.dat", data )
    end

    -- Reads a value from the Player's agent data
    function CD2:ReadPlayerData( var )
        local data = CD2:Read( "crackdown2/agentdata.dat" )
        CD2:DebugMessage( "Reading from your Agent data: var = " .. var .. " | returned value = " .. tostring( data[ var ] ) )
        return data[ var ]
    end

    -- Create Agent data if it doesn't exist
    if !file.Exists( "crackdown2/agentdata.dat", "DATA" ) then
        CD2:Write( "crackdown2/agentdata.dat", {} )
    end


    -- Received when the server wants to write to the Player's Agent data
    local chunks
    net.Receive( "cd2filesystem_dispatchplayerdata", function()
        chunks = chunks or ""
        local chunk = net.ReadString()
        local var = net.ReadString()
        local isdone = net.ReadBool()

        chunks = chunks .. chunk

        CD2:DebugMessage( "Received a data chunk from the Server for " .. var  )

        if isdone then
            CD2:DebugMessage( "Received all data chunks for " .. var )
            local val = JSONToTable( chunks )[ 1 ]
            CD2:WritePlayerData( var, val )
            chunks = nil
        end
    end )

    -- Received when the server wants to get a value from the Player's Agent Data
    net.Receive( "cd2filesystem_requestplayerdata", function()
        local var = net.ReadString()
        CD2:DebugMessage( "Server is requesting " .. var .. " from your Agent data. Dispatching..")

        local value = CD2:ReadPlayerData( var )
        local tbl = TableToJSON( { value } )
        local chunks = DataSplit( tbl )

        for i = 1, #chunks do 
            net.Start( "cd2filesystem_dispatchplayerdata" )
            net.WriteString( chunks[ i ] )
            net.WriteBool( i == #chunks )
            net.SendToServer()
        end
    end )


end