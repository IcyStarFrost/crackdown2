if SERVER then
    CD2inputs = CD2inputs or {}

    function CD2HasInput( ply, ent )
        for k, v in pairs( CD2inputs ) do
            if v.ent == ent and v[ ply ] then return true end
        end
    end

    function CD2AdjustInput( ply, enabled, name, ent, cmd, text, distance, callback )

        if enabled then
            CD2inputs[ ent ] = { 
                ent = ent, 
                cmd = cmd, 
                text = text ,
                enabled = enabled, 
                distance = distance,
                callback = callback,
                name = name,
                global = ( ply == nil )
            }
            if ply then
                CD2inputs[ ent ][ ply ] = true 
            end
        else
            CD2inputs[ ent ] = nil
        end

        CD2:DebugMessage( "Adjusting Input for ", ent, " (", name, cmd, text, distance, ply, ")")

        net.Start( "cd2net_input" )
        net.WriteBool( enabled )
        net.WriteString( name )
        net.WriteEntity( ent )

        if enabled then
            net.WriteString( cmd )
            net.WriteString( text )
            net.WriteUInt( distance, 16 )
        end

        if !ply then
            net.Broadcast()
        else
            net.Send( ply )
        end
        
    end

    local function UpdateInputsForPly( ply )
        for name, tbl in pairs( CD2inputs ) do
            net.Start( "cd2net_input" )
            net.WriteBool( tbl.enabled )
            net.WriteString( tbl.name )
            net.WriteEntity( tbl.ent )
            net.WriteString( tbl.cmd )
            net.WriteString( tbl.text )
            net.WriteUInt( tbl.distance, 16 )
            net.Broadcast()
        end
    end


    net.Receive( "cd2net_input", function( len, ply )
        local ent = net.ReadEntity()
        local tbl = CD2inputs[ ent ]

        tbl.callback( ent )
    end )
elseif CLIENT then
    CD2inputs = CD2inputs or {}

    net.Receive( "cd2net_input", function( len, ply )
        local enabled = net.ReadBool()
        local name = net.ReadString()
        local ent = net.ReadEntity()
        local cmd = net.ReadString()
        local text = net.ReadString()
        local distance = net.ReadUInt( 16 )

        CD2:DebugMessage( "Adjusting Input for ", ent, " (", name, cmd, text, distance, ")")

        if !enabled then
            CD2:DebugMessage( name, " Input was removed!" )
            print(CD2inputs[ ent ])
            CD2inputs[ ent ] = nil 

            return
        end

        CD2inputs[ ent ] = { 
            enabled = enabled,
            cmd = cmd,
            text = text,
            distance = distance,
            ent = ent,
            name = name,
        }
    end )

    local function GetClosest()
        local tbl 
        local tocursor 
        for k, v in pairs( CD2inputs ) do
            if !IsValid( v.ent ) or v.ent:SqrRangeTo( LocalPlayer() ) > v.distance ^ 2 then continue end
            if !tbl then
                tbl = v
                tocursor = ( v.ent:GetPos() - EyePos() ):GetNormalized():Dot( EyeAngles():Forward() )
                continue
            end
            local dot = ( v.ent:GetPos() - EyePos() ):GetNormalized():Dot( EyeAngles():Forward() )

            if dot > tocursor then
                tbl = v
                tocursor = dot
            end
        end
        
        return tbl
    end

    local delay
    hook.Add( "HUDPaint", "crackdown2_inputprompts", function()
        if !GetConVar( "cd2_drawhud" ):GetBool() then return end

        local bestinput = GetClosest()

        if bestinput and IsValid( bestinput.ent ) then
            if CurTime() < LocalPlayer():GetNW2Float( "cd2_weapondrawcur", 0 ) then return end

            local usebind = input.LookupBinding( bestinput.cmd ) or "e"
            local code = input.GetKeyCode( usebind )
            local buttonname = input.GetKeyName( code )
            
            local screen = ( bestinput.ent:GetPos() + Vector( 0, 0, 30 ) ):ToScreen()
            CD2DrawInputbar( screen.x, screen.y, string.upper( buttonname ), bestinput.text )

            if input.IsKeyDown( code ) then
                delay = delay or CurTime() + 1

                if CurTime() > delay then
                    net.Start( "cd2net_input" )
                    net.WriteEntity( bestinput.ent )
                    net.SendToServer()
                    delay = math.huge
                end
            else
                delay = nil
            end
        end


     
    end )
end