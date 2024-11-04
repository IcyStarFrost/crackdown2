
CD2.ConVars = {}

function CD2:GetConVar( name )
    return self.ConVars[ name ]
end

function CD2:ConVar( name, value, shouldsave, isclient, userinfo, desc, min, max )
    
    if isclient and CLIENT then
        local cvar = CreateClientConVar( name, value, shouldsave, userinfo, desc, min, max )
        
        self.ConVars[ name ] = cvar
    elseif !isclient then
        local flags = FCVAR_REPLICATED

        if shouldsave then flags = flags + FCVAR_ARCHIVE end

        local cvar = CreateConVar( name, value, flags, desc, min, max )

        self.ConVars[ name ] = cvar
    end


end


CreateClientConVar( "cd2_musicvolume", 1, true, false, "The Volume of the Music played in Crackdown 2", 0, 1 )
CreateClientConVar( "cd2_drawhud", 1, false, false, "Whether the hud should draw or not", 0, 1 )
CreateClientConVar( "cd2_drawpathfinding", 0, false, false, "debug", 0, 1 )

CD2:ConVar( "cd2_interact1", KEY_Q, true, true, true, "1st Interact key. Used for the following: Object pickups", 0, 1 )
CD2:ConVar( "cd2_interact2", KEY_E, true, true, true, "2nd Interact key. Used for the following: Activating Tactical Locations, Beacons, etc", 0, 1 )
CD2:ConVar( "cd2_interact3", KEY_R, true, true, true, "3rd Interact key. Used for the following: Picking up new weapons", 0, 1 )