-- Reviving system --

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
                    localply.cd2_revivetime = localply.cd2_revivetime or CurTime() + 1

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
        local targ = LocalPlayer().cd2_revivetarget
        if !IsValid( targ ) or !targ:GetRagdollOwner():GetCanRevive() then return end

        local usebind = input_LookupBinding( "+use" ) or "e"
        local code = input_GetKeyCode( usebind )
        local buttonname = input_GetKeyName( code )
        
        local screen = ( targ:GetPos() + Vector( 0, 0, 30 ) ):ToScreen()
        CD2DrawInputbar( screen.x, screen.y, upper( buttonname ), "Revive " .. targ:GetRagdollOwner():Name() )
    end )

end


-----