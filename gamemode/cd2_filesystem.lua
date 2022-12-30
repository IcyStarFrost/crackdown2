local JSONToTable = util.JSONToTable
local TableToJSON = util.TableToJSON
local compress = util.Compress
local decompress = util.Decompress
print( "Crackdown2 Console: File System has been loaded")

-- The gamemode's custom file system. This is what handles the saving, loading, and general data players have
CD2FILESYSTEM = {}


function CD2FILESYSTEM:Write( filename, contents, type )

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

function CD2FILESYSTEM:Read( filename, type )

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