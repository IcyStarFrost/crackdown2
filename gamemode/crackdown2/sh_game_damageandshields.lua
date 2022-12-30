local abs = math.abs

if SERVER then

    -- Shield system
    hook.Add( "EntityTakeDamage", "crackdown2_shieldsystem", function( ent, info ) 
        local attacker = info:GetAttacker()
        if attacker:IsCD2NPC() then info:SetDamage( info:GetDamage() / attacker.cd2_damagedivider ) end

        if !ent:IsPlayer() then return end

        local shields = ent:Armor()
        local damage = info:GetDamage()
        local shielddamage = ent:Armor() - damage
        local leftover = abs( shielddamage )

        if shields >= damage then
            ent:SetArmor( shields - damage )
            hook.Run( "PlayerHurt", ent, info:GetAttacker(), ent:Health(), damage )

            if info:IsExplosionDamage() then ent:Ignite( 4 ) end
            return true
        elseif shields > 0 then
            info:SetDamage( damage - shields )
            ent:SetArmor( 0 )
            ent:TakeDamageInfo( info )
            return true
        end

    end )

    -- Set the client's regen time
    hook.Add( "PlayerHurt", "crackdown2_delayregen", function( ply, attacker, remaining, damagetaken )
        ply.cd_NextRegenTime = CurTime() + 6
        net.Start( "cd2net_playerhurt" )
        net.Send( ply )
    end )

    -- Ignite any player or npc if they have been damaged by explosions
    hook.Add( "PostEntityTakeDamage", "crackdown2_fireexplosions", function( ent, info )
        if info:IsExplosionDamage() and ( ent:IsPlayer() or ent:IsCD2NPC() ) then
            ent:Ignite( 4 )
        end
    end )

elseif CLIENT then


    local function PlayShieldsOfflineSound() 
        local ply = LocalPlayer()

        sound.PlayFile( "sound/crackdown2/ply/shielddown.mp3", "noplay", function( snd, id, name ) 
            if id then print( id, name ) return end

            snd:SetVolume( 0.1 )
            snd:Play()
            snd:EnableLooping( true )

            hook.Add( "Think", "crackdown2_shieldofflinesoundhandler", function()
                if !IsValid( snd ) or snd:GetState() == GMOD_CHANNEL_STOPPED then hook.Remove( "Think", "crackdown2_shieldofflinesoundhandler" ) return end
                if !ply:Alive() or ply:GetNWShields() > 30 then hook.Remove( "Think", "crackdown2_shieldofflinesoundhandler" ) snd:Stop() return end
            end )

        end )
    end

    -- Shield offline and low sounds
    local limitlow = false
    local limitoffline = false
    hook.Add( "Tick", "crackdown2_shieldoffline", function()
        local ply = LocalPlayer()

        if !IsValid( ply ) or !ply:IsCD2Agent() then return end

        if ply:GetNWShields() <= 30 and !limitlow then
            PlayShieldsOfflineSound() 
            limitlow = true
        elseif ply:GetNWShields() > 30 and limitlow then
            limitlow = false
        end

        if ply:GetNWShields() <= 0 and !limitoffline then
            sound.PlayFile( "sound/crackdown2/ply/shield_takedown.mp3", "noplay", function( snd, id ) if id then return end snd:SetVolume( 0.3 ) snd:Play() end )
            limitoffline = true
        elseif ply:GetNWShields() > 0 and limitoffline then
            limitoffline = false
        end

    end )

end