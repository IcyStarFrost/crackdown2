local random = math.random
local CurTime = CurTime
local player_GetAll = player.GetAll

if SERVER then
    
    -- Jump sounds
    hook.Add( "KeyPress", "crackdown2_jump", function( ply, key ) 
        if !ply:IsCD2Agent() then return end
        if key == IN_JUMP and 
        ply:IsOnGround() then ply:EmitSound( "crackdown2/ply/jump" .. random( 1, 4 ) .. ".wav", 60, 100, 0.2, CHAN_AUTO ) end
    end )

    hook.Add( "CD2_SwitchWeapon", "crackdown2_changeholstermodel", function( ply, old, new )
        ply.cd2_holsteredweapon:SetModel( old:GetModel() )
        local mins, maxs = ply.cd2_holsteredweapon:GetModelBounds()
        ply.cd2_holsteredweapon:SetLocalPos( Vector( -10, -9, 0 ) - mins / 2 )
    end )

    -- Director commentary over level ups
    hook.Add( "CD2_OnLevelUp", "crackdown2_levelup", function( ply, skill )
        if KeysToTheCity() then return end

        if skill == "Strength" and ply:GetStrengthSkill() == 4 then
            CD2SendTextBoxMessage( ply, "While in the air, hold USE key and press your attack/fire button to initiate a devastating Ground Pound" )
        end

        if skill == "Agility" and !ply.cd2_firstagilityimprove then
            CD2FILESYSTEM:RequestPlayerData( ply, "cd2_firstagilityimprove", function( val )
                if !val then
                    timer.Simple( 2, function()
                        if !IsValid( ply ) then return end
                        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/agility_improve.mp3" )
                    end )
                    CD2FILESYSTEM:WritePlayerData( ply, "cd2_firstagilityimprove", true )
                else
                    ply.cd2_firstagilityimprove = true
                end
            end )
        end

        if skill == "Weapon" and !ply.cd2_firstfirearmimprove then
            CD2FILESYSTEM:RequestPlayerData( ply, "cd2_firstfirearmimprove", function( val )
                if !val then
                    timer.Simple( 2, function()
                        if !IsValid( ply ) then return end
                        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/firearm_improve.mp3" )
                    end )
                    CD2FILESYSTEM:WritePlayerData( ply, "cd2_firstfirearmimprove", true )
                else
                    ply.cd2_firstfirearmimprove = true
                end
            end )
        end

        if skill == "Strength" and !ply.cd2_firststrengthimprove then
            CD2FILESYSTEM:RequestPlayerData( ply, "cd2_firststrengthimprove", function( val )
                if !val then
                    timer.Simple( 2, function()
                        if !IsValid( ply ) then return end
                        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/strength_improve.mp3" )
                    end )
                    CD2FILESYSTEM:WritePlayerData( ply, "cd2_firststrengthimprove", true )
                else
                    ply.cd2_firststrengthimprove = true
                end
            end )
        end

        if skill == "Explosive" and !ply.cd2_firstexplosiveimprove then
            CD2FILESYSTEM:RequestPlayerData( ply, "cd2_firstexplosiveimprove", function( val )
                if !val then
                    timer.Simple( 2, function()
                        if !IsValid( ply ) then return end
                        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/explosive_improve.mp3" )
                    end )
                    CD2FILESYSTEM:WritePlayerData( ply, "cd2_firstexplosiveimprove", true )
                else
                    ply.cd2_firstexplosiveimprove = true
                end
            end )
        end

    end )

    hook.Add( "OnCD2NPCKilled", "crackdown2_firstcellkill", function( npc, info )
        local attacker = info:GetAttacker()
        if !IsValid( attacker ) or !attacker:IsPlayer() or attacker.cd2_hadFirstCellKill or KeysToTheCity() or npc:GetCD2Team() != "cell" then return end
        CD2FILESYSTEM:RequestPlayerData( attacker, "cd2_hadfirstcellkill", function( val )
            if !val then
                attacker:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/firstcellkill.mp3" )
                CD2FILESYSTEM:WritePlayerData( attacker, "cd2_hadfirstcellkill", true )
            else
                attacker.cd2_hadFirstCellKill = true
            end
        end )
    end )

end

local actcommands = {
    "act group",
    "act forward",
    "act halt"
}

local delay = 0

-- Randomly playing act animation
hook.Add( "Tick", "crackdown2_passiveactcommands", function()
    if CurTime() > delay then
        
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

        delay = CurTime() + 2
    end
end )


if CLIENT then
    local limit = false

    hook.Add( "Think", "crackdown2_light", function()
        local ply = LocalPlayer()
        if !IsValid( ply ) or !ply:IsCD2Agent() then return end

        if !ply:GetNoDraw() and !IsValid( ply.cd2_light ) and ( !CD2IsDay() ) then
            ply.cd2_light = ProjectedTexture()
            ply.cd2_light:SetPos( ply:EyePos() + ply:GetAimVector() * 100 )
            ply.cd2_light:SetAngles( ply:EyeAngles() )
            ply.cd2_light:SetFarZ( 2000 )
            ply.cd2_light:SetEnableShadows( false )
            ply.cd2_light:SetBrightness( 3 )
            ply.cd2_light:SetFOV( 60 )
            ply.cd2_light:SetTexture( "effects/flashlight001" )
            ply.cd2_light:Update()
        elseif !ply:GetNoDraw() and IsValid( ply.cd2_light ) and ( !CD2IsDay() ) then
            ply.cd2_light:SetPos( ply:EyePos() )
            ply.cd2_light:SetAngles( ply:EyeAngles() )
            ply.cd2_light:Update()
        elseif IsValid( ply.cd2_light ) and ( CD2IsDay() ) then
            ply.cd2_light:Remove()
        end
    end )

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
    
    hook.Add( "Tick", "crackdown2_ambientmusic", function()
        if nexttrack and CurTime() > nexttrack then 
            local tracks = { "sound/crackdown2/music/ambient/agency.mp3", "sound/crackdown2/music/ambient/hope.mp3",  }
            for i = 1, 14 do tracks[ #tracks + 1 ] = "sound/crackdown2/music/ambient/height" .. i .. ".mp3" end
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

        -- Deal damage to the entity below
        if IsValid( ply:GetGroundEntity() ) then
            local info = DamageInfo()
            info:SetDamage( vel / 10 )
            info:SetDamageType( DMG_FALL )
            info:SetDamagePosition( ply:GetPos() )
            info:SetDamageForce( Vector( 0, 0, 10000 ) )
            info:SetAttacker( ply )
            ply:GetGroundEntity():TakeDamageInfo( info )
        end

        if vel >= 600 then
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