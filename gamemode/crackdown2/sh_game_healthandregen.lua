local player_GetAll = player.GetAll

-- Shield and Health Regeneration
hook.Add( "Tick", "crackdown2_regeneration", function()
    if SERVER then

        local players = player_GetAll() 
        for i = 1, #players do
            local ply = players[ i ]
            if !IsValid( ply ) or !ply:IsCD2Agent() then continue end

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
                    ply:SetNWShields( ply:Armor() )
                    ply:SetIsRechargingShield( true )

                    if ply.cd2_cancallShieldsound then ply:SendLua( "surface.PlaySound( 'buttons/combine_button7.wav' )" ) ply.cd2_cancallShieldsound = false end

                    ply.cd2_NextShieldRegen = CurTime() + 0.03
                end

                continue
            elseif ply.cd2_NextRegenTime and CurTime() < ply.cd2_NextRegenTime or ply:Armor() == ply:GetMaxArmor() then
                ply:SetIsRechargingShield( false )
            end
            -----

            -- Health Regeneration --
            if ply:Health() < ply:GetMaxHealth() and ( ply.cd2_NextRegenTime and CurTime() > ply.cd2_NextRegenTime ) then
                
                if !ply.cd2_NextHealthRegen or CurTime() > ply.cd2_NextHealthRegen then

                    ply:SetHealth( ply:Health() + 1 )
                    ply:SetNWHealth( ply:Health() )
                    ply:SetIsRegeningHealth( true )

                    if ply.cd2_cancallHealthsound then ply:SendLua( "surface.PlaySound( 'buttons/combine_button5.wav' )" ) ply.cd2_cancallHealthsound = false end

                    ply.cd2_NextHealthRegen = CurTime() + 0.03
                end

                continue
            elseif ply.cd2_NextRegenTime and CurTime() < ply.cd2_NextRegenTime or ply:Health() == ply:GetMaxHealth() then
                ply:SetIsRegeningHealth( false )
            end

        end

    end

end )



---------


-- Updating each player's networked health and shields 
if SERVER then
    hook.Add( "Tick", "crackdown2_updateplayernw", function()
        local players = player_GetAll() 
        for i = 1, #players do
            local ply = players[ i ]
            if !ply:IsCD2Agent() then continue end
            ply:SetNWShields( ply:Armor() )
            ply:SetNWHealth( ply:Health() )
        end
    end )


    -- Network all health so the target health bars are accurate
    local ents_GetAll = ents.GetAll
    local nextupdate = 0
    hook.Add( "Tick", "crackdown2_networkvars", function()
        if CurTime() < nextupdate then return end
        for k, v in ipairs( ents_GetAll() ) do
            v:SetNWFloat( "cd2_health", v:Health() )
            if IsValid( v:GetPhysicsObject() ) then
                v:SetNW2Int( "cd2_mass", v:GetPhysicsObject():GetMass() )
            end
        end
        nextupdate = CurTime() + 0.1
    end )

    -- Set the regen start time
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
        
        if ply:Alive() and ply:GetNWHealth() < 70 and !limit then
            lowhealthchannel = CD2StartMusic( "sound/crackdown2/music/lowhealth.mp3", 5, true )
            ply:SetDSP( 30 )
            limit = true
        elseif ply:GetNWHealth() > 70 and limit then
            if IsValid( lowhealthchannel ) then lowhealthchannel:FadeOut() end
            CD2StartMusic( "sound/crackdown2/music/healthregenerated.mp3", 2, false, true )
            ply:SetDSP( 1 )
            limit = false
        end
    end )
end
