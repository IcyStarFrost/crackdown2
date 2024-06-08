local player_GetAll = player.GetAll
local IsValid = IsValid

-- Shield and Health Regeneration
hook.Add( "Tick", "crackdown2_regeneration", function()
    if SERVER then

        local players = player_GetAll() 
        for i = 1, #players do
            local ply = players[ i ]
            if !IsValid( ply ) or !ply:IsCD2Agent() or !ply:Alive() then continue end

            if ply:Armor() == ply:GetMaxArmor() then
                ply.cd2_cancallShieldsound = true
            end

            if ply:Health() == ply:GetMaxHealth() then
                ply.cd2_cancallHealthsound = true
            end

            -- Shields recharging --
            if ply:Armor() < ply:GetMaxArmor() and ( ply.cd2_NextRegenTime and CurTime() > ply.cd2_NextRegenTime ) then
                
                if !ply.cd2_NextShieldRegen or CurTime() > ply.cd2_NextShieldRegen then

                    ply:SetArmor( ply:Armor() + 1 )

                    if ply.cd2_cancallShieldsound then ply:SendLua( "surface.PlaySound( 'buttons/combine_button7.wav' )" ) ply.cd2_cancallShieldsound = false end

                    ply.cd2_NextShieldRegen = CurTime() + 0.03
                end

                continue
            end
            -----

            -- Health Regeneration --
            if ply:Health() < ply:GetMaxHealth() and ( ply.cd2_NextRegenTime and CurTime() > ply.cd2_NextRegenTime ) then
                
                if !ply.cd2_NextHealthRegen or CurTime() > ply.cd2_NextHealthRegen then

                    ply:SetHealth( ply:Health() + 1 )
                    if ply.cd2_cancallHealthsound then ply:SendLua( "surface.PlaySound( 'buttons/combine_button5.wav' )" ) ply.cd2_cancallHealthsound = false end

                    ply.cd2_NextHealthRegen = CurTime() + 0.03
                end

                continue
            end

        end

    end

end )



---------



if SERVER then

    -- Updating Entity Networked vars when they are created and damaged. Previously this was done every 0.1 seconds. This is more optimized
    hook.Add("OnEntityCreated", "crackdown2_networkhealth", function( ent )
        timer.Simple( 0, function()
            if !IsValid( ent ) then return end
            ent:SetNW2Float( "cd2_health", ent:Health() )

            if IsValid( ent:GetPhysicsObject() ) then
                ent:SetNW2Int( "cd2_mass", ent:GetPhysicsObject():GetMass() )
            end
        end )
    end )

    hook.Add( "PostEntityTakeDamage", "crackdown2_updatenwhealth", function( ent, info, tookdmg )
        if !tookdmg or ent:IsCD2Agent() then return end
        ent:SetNW2Float( "cd2_health", ent:Health() )
    end )

    -- Set the regen start time and updates the player's networked health. Same as above for networked health, player's networked health was updated every 0.1 seconds. Once again this is more optimized
    hook.Add( "PlayerHurt", "crackdown2_delayregen", function( ply, attacker, remaining, damagetaken )
        ply.cd2_NextRegenTime = CurTime() + 6
    end )
end


-- Low health music
if CLIENT then
    local lowhealthchannel
    hook.Add( "Tick", "crackdown2_healthcheck", function()
        local ply = LocalPlayer()

        if !IsValid( ply ) or !ply:IsCD2Agent() then return end
        
        if ply:Alive() and ply:Health() < 70 and !limit then
            lowhealthchannel = CD2StartMusic( "sound/crackdown2/music/lowhealth.mp3", 5, true )
            ply:SetDSP( 30 )
            limit = true
        elseif ply:Health() > 70 and limit then
            if IsValid( lowhealthchannel ) then lowhealthchannel:FadeOut() end
            CD2StartMusic( "sound/crackdown2/music/healthregenerated.mp3", 2, false, true )
            ply:SetDSP( 1 )
            limit = false
        end
    end )
end
