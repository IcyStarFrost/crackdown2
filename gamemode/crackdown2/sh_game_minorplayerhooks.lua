local random = math.random
local CurTime = CurTime
local player_GetAll = player.GetAll

if SERVER then
    
    -- Jump sounds
    hook.Add( "KeyPress", "crackdown2_jump", function( ply, key ) 
        if !ply:IsCD2Agent() then return end
        if key == IN_JUMP and ply:IsOnGround() then ply:EmitSound( "crackdown2/ply/jump" .. random( 1, 4 ) .. ".wav", 60, 100, 0.2, CHAN_AUTO ) end
    end )

end

local actcommands = {
    "act group",
    "act forward",
    "act halt"
}

-- Randomly playing act animation
hook.Add( "Tick", "crackdown2_passiveactcommands", function()
    local players = player_GetAll() 
    for i = 1, #players do
        local ply = players[ i ]

        if !ply:Alive() or !ply:IsCD2Agent() then continue end
        
        ply.cd2_nextgesture = ply.cd2_nextgesture or CurTime() + random( 5, 60 )

        if CurTime() > ply.cd2_nextgesture then
            ply:ConCommand( actcommands[ random( 3 ) ])
            ply.cd2_nextgesture = CurTime() + random( 5, 60 )
        end

    end
end )


if CLIENT then
    local limit = false

    -- Wind sounds for falling 
    hook.Add( "Tick", "crackdown2_fallsounds", function()
        local ply = LocalPlayer()
        if !IsValid( ply ) or !ply:IsCD2Agent() then return end
        local vel = ply:GetVelocity()[ 3 ]
    
        if vel < -400 or vel > 400 then 
            if !ply.cd2_fallsoundpatch then
                ply.cd2_fallsoundpatch = CreateSound( ply, "ambient/wind/wind_rooftop1.wav" )
                ply.cd2_fallsoundpatch:Play()
                ply.cd2_fallsoundpatch:ChangeVolume( 0 )
            end
            ply.cd2_fallsoundpatch:ChangeVolume( vel % 1000, 3 )
        else
            if ply.cd2_fallsoundpatch then ply.cd2_fallsoundpatch:ChangeVolume( 0, 1 ) if ply.cd2_fallsoundpatch:GetVolume() == 0 then ply.cd2_fallsoundpatch:Stop() end end
            ply.cd2_fallsoundpatch = nil
        end
        
    end )

    -- Ambient music --
    local nexttrack = CurTime() + random( 90, 250 )
    local tracks = { "sound/crackdown2/music/ambient/agency.mp3", "sound/crackdown2/music/ambient/hope.mp3", "sound/crackdown2/music/ambient/ambient1.mp3", "sound/crackdown2/music/ambient/ambient2.mp3", "sound/crackdown2/music/ambient/ambient3.mp3", "sound/crackdown2/music/ambient/ambient4.mp3", "sound/crackdown2/music/ambient/ambient5.mp3", "sound/crackdown2/music/ambient/ambient6.mp3" }
    hook.Add( "Tick", "crackdown2_ambientmusic", function()
        if nexttrack and CurTime() > nexttrack then 
            nexttrack = nil

            CD2StartMusic( tracks[ random( #tracks ) ], 0, false, true, nil, nil, nil, nil, nil, function( chan )
                if !nexttrack then
                    nexttrack = CurTime() + chan:GetChannel():GetLength() + random( 90, 250 )
                end
            end )

        end
    end )

end


-- Place decals on hard landings and play small effects for soft landings
if SERVER then
    local sound_Play = sound.Play
    hook.Add( "OnPlayerHitGround", "crackdown2_landingdecals", function( ply, inwater, onfloater, vel )

        if vel >= 700 then
            net.Start( "cd2net_playerlandingdecal" )
            net.WriteVector( ply:WorldSpaceCenter() )
            net.WriteBool( vel >= 1000  )
            net.Broadcast()

            sound_Play( "crackdown2/ply/hardland" .. random( 1, 2 ) .. ".wav", ply:GetPos(), 65, 100, 1 )
        else
            net.Start( "cd2net_playersoftland" )
            net.WriteVector( ply:GetPos() )
            net.Broadcast()
        end

        sound_Play( "crackdown2/ply/defaultland" .. random( 1, 3 ) .. ".wav", ply:GetPos(), 65, 100, 1 )
    end )
end