local player_GetAll = player.GetAll

-- Shield and Health Regeneration
hook.Add( "Tick", "crackdown2_regeneration", function()
    local players = player_GetAll() 
    for i = 1, #players do
        local ply = players[ i ]

        if CLIENT and ply != LocalPlayer() then continue end

        if !ply:Alive() then ply.cd2_delayregens = CurTime() + 0.5 continue end
        if !ply:IsCD2Agent() or ( ply.cd2_delayregens and CurTime() < ply.cd2_delayregens ) then continue end

        if ( !ply.cd_NextRegenTime or CurTime() > ply.cd_NextRegenTime ) then

            if ply:GetNWShields() < ply:GetMaxArmor() and ( !ply.cd_NextRegen or CurTime() > ply.cd_NextRegen ) then

                if SERVER then
                    ply:SetArmor( ply:GetNWShields() + 1 )
                end

                ply:SetIsRechargingShield( true )

                if ply.cd2_cancallshieldhook then hook.Run( "CD2_OnPlayerShieldRegen", ply ) ply.cd2_cancallshieldhook = false end
                ply.cd_NextRegen = CurTime() + 0.03

            elseif ply:GetNWHealth() < ply:GetMaxHealth() and ( !ply.cd_NextRegen or CurTime() > ply.cd_NextRegen ) then

                ply:SetHealth( ply:GetNWHealth() + 1 )
                ply:SetIsRegeningHealth( true )
                
                if ply.cd2_cancallhealthhook then hook.Run( "CD2_OnPlayerHealthRegen", ply ) ply.cd2_cancallhealthhook = false end
                ply.cd_NextRegen = CurTime() + 0.03

            end
            

            -- If these values are at their maxes, enable the calling of CD2 hooks and Set Is methods to false
            if ply:GetNWShields() == ply:GetMaxArmor() then
                ply.cd2_cancallshieldhook = true
                ply:SetIsRechargingShield( false )
            end

            if ply:GetNWHealth() == ply:GetMaxHealth() then
                ply.cd2_cancallhealthhook = true
                ply:SetIsRegeningHealth( false )
            end

        end

    end
end )
---------


if CLIENT then
    -- Regen Sounds
    hook.Add( "CD2_OnPlayerShieldRegen", "crackdown2_onshieldregen", function( ply )
        if ply == LocalPlayer() then
            surface.PlaySound( "buttons/combine_button7.wav" )
        end
    end )


    hook.Add( "CD2_OnPlayerHealthRegen", "crackdown2_onhealthregen", function( ply )
        if ply == LocalPlayer() then
            surface.PlaySound( "buttons/combine_button5.wav" )
        end
    end )
    -----
end


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

    -- Set the client's regen time
    hook.Add( "PlayerHurt", "crackdown2_delayregen", function( ply, attacker, remaining, damagetaken )
        ply.cd_NextRegenTime = CurTime() + 6
        net.Start( "cd2net_playerhurt" )
        net.Send( ply )
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
            ply:SetDSP( 1 )
            limit = false
        end
    end )
end
