local JSONToTable = util.JSONToTable
local TableToJSON = util.TableToJSON
local compress = util.Compress
local decompress = util.Decompress
print( "Crackdown2 Console: File System has been loaded")

file.CreateDir( "crackdown2" )

-- The gamemode's custom file system. This is what handles the saving, loading, and general data players have
CD2FILESYSTEM = {}

-- File writing with the ability to easily pack tables into jsons or compressed jsons
function CD2FILESYSTEM:Write( filename, contents, type )
    CD2DebugMessage( "Wrote to file " .. filename )
	local f = file.Open( filename, type == "compressed" and "wb" or "w", "DATA" )
	if ( !f ) then return end

    if type == "json" then
        contents = TableToJSON( contents )
    elseif type == "compressed" then
        contents = TableToJSON( contents )
        contents = compress( contents )
    end

	f:Write( contents )
	f:Close()

end

-- File reading with the ability to directly get a table from a json or compressed json
function CD2FILESYSTEM:Read( filename, type )
    CD2DebugMessage( "Reading from file " .. filename )

	local f = file.Open( filename, type == "compressed" and "rb" or "r", "DATA" )
	if ( !f ) then return end

	local contents = f:Read( f:Size() )
	f:Close()

    if type == "json" then
        contents = JSONToTable( contents )
    elseif type == "compressed" then
        contents = decompress( contents )
        contents = JSONToTable( contents )
    end

	return contents
end


if CLIENT then

    -- Writes a value to the Player's agent data
    function CD2FILESYSTEM:WritePlayerData( var, any )
        CD2DebugMessage( "Writing to " .. LocalPlayer():Name() .. "'s Agent data: var = " .. var .. " | value = " .. tostring( any ) )
        local data = CD2FILESYSTEM:Read( "crackdown2/agentdata.dat", "compressed" )
        data[ var ] = any
        CD2FILESYSTEM:Write( "crackdown2/agentdata.dat", data, "compressed" )
    end

    -- Reads a value from the Player's agent data
    function CD2FILESYSTEM:ReadPlayerData( var )
        local data = CD2FILESYSTEM:Read( "crackdown2/agentdata.dat", "compressed" )
        return data[ var ]
    end

    CD2FILESYSTEM:Write( "crackdown2/agentdata.dat", {}, "compressed" )
end