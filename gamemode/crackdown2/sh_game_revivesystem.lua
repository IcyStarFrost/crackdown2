-- Reviving system --


-- TODO: Determine whether this system needs a rewrite or not.
if !game.SinglePlayer() and CLIENT then
    local player_GetAll = player.GetAll
    local upper = string.upper
    local input_LookupBinding = input.LookupBinding
    local input_GetKeyCode = input.GetKeyCode
    local input_GetKeyName = input.GetKeyName
    local IsValid = IsValid

    hook.Add( "Tick", "crackdown2_playerreviving", function()

        local players = player_GetAll() 
        for i = 1, #players do
            local ply = players[ i ]
            local localply = LocalPlayer()
    
            if ply:Alive() or !ply:IsCD2Agent() or ply == localply or !ply:GetCanRevive() then continue end

            local ragdoll = ply:GetRagdollEntity()

            if IsValid( ragdoll ) and localply:GetPos():DistToSqr( ragdoll:GetPos() ) <= ( 70 * 70 ) then
                localply.cd2_revivetarget = ragdoll

                if localply:KeyDown( IN_USE ) then
                    localply.cd2_revivetime = localply.cd2_revivetime or CurTime() + 0.2

                    if CurTime() > localply.cd2_revivetime then

                        net.Start( "cd2net_reviveplayer" )
                        net.WriteEntity( ply )
                        net.SendToServer()

                        localply.cd2_revivetime = math.huge
                    end

                else
                    localply.cd2_revivetime = nil
                end
                
            else
                localply.cd2_revivetarget = nil
            end

        end
    end )

    hook.Add( "HUDPaint", "crackdown2_revivepaint", function()
        if !GetConVar( "cd2_drawhud" ):GetBool() then return end
        local targ = LocalPlayer().cd2_revivetarget
        if !IsValid( targ ) or !targ:GetRagdollOwner():GetCanRevive() then return end

        local usebind = input_LookupBinding( "+use" ) or "e"
        local code = input_GetKeyCode( usebind )
        local buttonname = input_GetKeyName( code )
        
        local screen = ( targ:GetPos() + Vector( 0, 0, 30 ) ):ToScreen()
        CD2DrawInputbar( screen.x, screen.y, upper( buttonname ), "Revive " .. targ:GetRagdollOwner():Name() )
    end )

end


if SERVER then
    -- Received when a Player revives another Player
    -- ply = Reviving player
    -- agent = Originally dead player
    net.Receive( "cd2net_reviveplayer", function( len, ply ) 
        local agent = net.ReadEntity()
        if agent:Alive() or !agent:GetCanRevive() then return end

        CD2:DebugMessage( agent:Name() .. " Was revived by " .. ply:Name() )

        BroadcastLua( "Entity(" .. ply:EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_GMOD_GESTURE_ITEM_PLACE, true )" )

        agent.cd2_revived = true
        agent.cd2_WeaponSpawnDelay = CurTime() + 0.5

        agent:Spawn()
        agent:SetPos( ply:GetPos() + Vector( 0, 0, 5 ) + ply:GetForward() * 50 )
        agent:EmitSound( "crackdown2/ply/revived.mp3", 80 )

        agent:SetNoDraw( true )
        agent:Freeze( true )
        agent.cd2_godmode = true

        local riseent = ents.Create( "cd2_riseent" )
        riseent:SetPos( agent:GetPos() )
        riseent:SetAngles( Angle( 0, agent:EyeAngles()[ 2 ], 0 ) )
        riseent:SetParent( agent )
        riseent:SetPlayer( agent )
        riseent:Spawn()
        riseent.Callback = function( self )
            agent:SetNoDraw( false )
            agent:Freeze( false )
            agent.cd2_godmode = false
        end

        local primary = agent:Give( agent.cd2_lastspawnprimary )
        local secondary = agent:Give( agent.cd2_lastspawnsecondary )

        local weps = agent.cd2_deathweapons
        for i = 1, #weps do
            local class = weps[ i ][ 1 ]
            local reserve = weps[ i ][ 2 ]

            if IsValid( primary ) and class == primary:GetClass() then
                agent:SetAmmo( reserve, primary.Primary.Ammo )
            elseif IsValid( secondary ) and class == secondary:GetClass() then
                agent:SetAmmo( reserve, secondary.Primary.Ammo )
            end
        end

    end )
end


-----