local table_insert = table.insert
local table_remove = table.remove
local Lerp = Lerp
local FrameTime = FrameTime

-- Table holding all currently playing music
local MusicChannels = {}

-- Meta table
local CD2MusicChannelMeta = {}
CD2MusicChannelMeta.__index = CD2MusicChannelMeta

-- Returns the sound channel
function CD2MusicChannelMeta:GetChannel()
    return self.cd2_musicchannel
end

-- Sets the sound channel
function CD2MusicChannelMeta:SetChannel( chan )
    self.cd2_musicchannel = chan
end

-- Returns if the channel is valid
function CD2MusicChannelMeta:IsValid()
    return IsValid( self.cd2_musicchannel ) and self.cd2_musicchannel:GetState() != GMOD_CHANNEL_STOPPED 
end

-- Returns the priority of the music. Higher priority numbers will silence music below
function CD2MusicChannelMeta:GetPriority()
    return self.cd2_priority
end

-- Returns if this channel is top priority
function CD2MusicChannelMeta:IsHighestPriority()
    local ishighest = true
    for i = 1, #MusicChannels do
        local channel = MusicChannels[ i ]
        if !IsValid( channel ) then table_remove( MusicChannels, i ) continue end

        if channel != self and channel:GetPriority() > self:GetPriority() and !channel:IsFading() then
            ishighest = false
        end
    end
    return ishighest
end

-- Stops the music from playing and destroys self
function CD2MusicChannelMeta:Kill()
    self:GetChannel():Stop()
end

-- Sets the priority
function CD2MusicChannelMeta:SetPriority( num )
    self.cd2_priority = num
end

-- Pauses the music
function CD2MusicChannelMeta:Pause()
    self.cd2_ispaused = true
end

-- Returns if we are paused
function CD2MusicChannelMeta:IsPaused()
    return self.cd2_ispaused
end

-- Unpauses the music
function CD2MusicChannelMeta:UnPause()
    self.cd2_ispaused = false
end

-- Makes the music fade out and destroy
function CD2MusicChannelMeta:FadeOut()
    self.cd2_shouldfade = true
end

-- If the music is fading
function CD2MusicChannelMeta:IsFading()
    return self.cd2_shouldfade
end

local volume = GetConVar( "cd2_musicvolume" ) -- The volume of all music
local incrementalvalue = 0 -- A value that will never re-use old values

-- Starts playing music and returns the music as a CD2Musicchannel object
-- Higher numbers in priority will silence or kill music depending on killonpriorityfade that are lower priority
function CD2StartMusic( path, priority, looped, killonpriorityfade, overridevolume, is3d, fademin, fademax, entity, func )
    local musicvolume = overridevolume or volume:GetFloat()
    local CD2Musicchannel = {}
    setmetatable( CD2Musicchannel, CD2MusicChannelMeta )

    local flags = !is3d and "noplay" or "3d mono noplay"

    sound.PlayFile( path, flags, function( snd, id, name ) 
        if id then ErrorNoHaltWithStack( "CD2 BASS ERROR: " .. path .. " " .. id .. " " .. name ) return end

        incrementalvalue = incrementalvalue + 1 -- Increment by 1

        CD2Musicchannel:SetPriority( priority )
        CD2Musicchannel:SetChannel( snd )
        table_insert( MusicChannels, CD2Musicchannel )

        CD2DebugMessage( "Created Music Channel for file path " .. path .. " with a priority of " .. priority )

        if is3d then
            local min, max = snd:Get3DFadeDistance()
            snd:Set3DFadeDistance( fademin or min , fademax or max )
        end

        snd:EnableLooping( looped or false )
        snd:SetVolume( musicvolume )
        snd:Play()

        local id = incrementalvalue * 1
        hook.Add( "Think", "crackdown2_musicsystem" .. id, function()
            if !CD2Musicchannel:IsValid() then hook.Remove( "Think", "crackdown2_musicsystem" .. id ) return end

            if func then func( CD2Musicchannel ) end

            if CD2MusicChannelMeta:IsPaused() then if snd:GetState() != GMOD_CHANNEL_PLAYING then snd:Pause() end return end

            if is3d and IsValid( entity ) then
                snd:SetPos( entity:GetPos() )
            elseif is3d and !IsValid( entity ) then
                hook.Remove( "Think", "crackdown2_musicsystem" .. id )
                snd:Stop()
                return
            end

            if !CD2Musicchannel:IsFading() and CD2Musicchannel:IsHighestPriority() then -- We are currently playing as top priority
                if snd:GetState() == GMOD_CHANNEL_PAUSED then snd:Play() end
                musicvolume = overridevolume or volume:GetFloat()
                snd:SetVolume( Lerp( 2 * FrameTime(), snd:GetVolume(), musicvolume ) )
            elseif CD2Musicchannel:IsFading() then -- Fading out
                snd:SetVolume( Lerp( 2 * FrameTime(), snd:GetVolume(), 0 ) )

                if snd:GetVolume() <= 0.05 then 
                    hook.Remove( "Think", "crackdown2_musicsystem" .. id )
                    snd:Stop()
                    CD2DebugMessage( "Removed Music Channel " .. path .. " with a priority of " .. priority .. " due to fade out" )
                end
            elseif !CD2Musicchannel:IsFading() and !CD2Musicchannel:IsHighestPriority() then -- We aren't the highest priority and therefor will be silenced until we are
                snd:SetVolume( Lerp( 2 * FrameTime(), snd:GetVolume(), 0 ) )

                if snd:GetVolume() <= 0.05 then 
                    if !killonpriorityfade then snd:Pause() else hook.Remove( "Think", "crackdown2_musicsystem" .. id ) snd:Stop() end
                end
            end
        end )

    end )


    return CD2Musicchannel
end

