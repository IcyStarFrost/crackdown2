local player_GetAll = player.GetAll

-- Crackdown 2 Lockon system --
local limitlockonsound = false

if CLIENT then CD2_LockOnPos = "body" CD2_LastLockOnPos = "body" end

hook.Add( "Think", "crackdown2_lockon", function()

    if SERVER then
        local players = player_GetAll() 
        for i = 1, #players do
            local ply = players[ i ]
            if !ply:Alive() or !ply:IsCD2Agent() or !ply:GetCanUseLockon() then continue end
            

            if ply:KeyDown( IN_ATTACK2 ) then
                local wep = ply:GetActiveWeapon()
                if !IsValid( wep ) then return end
                ply.cd2_LockOnPos = ply.cd2_LockOnPos or "body"
                
                local lockables = CD2FindInLockableTragets( ply )

                local oldtarget = ply:GetNW2Entity( "cd2_lockontarget", nil )
                local target = IsValid( oldtarget ) and oldtarget:GetPos():DistToSqr( ply:GetPos() ) <= ( wep.LockOnRange * wep.LockOnRange ) and oldtarget or IsValid( lockables[ 1 ] ) and lockables[ 1 ]:GetPos():DistToSqr( ply:GetPos() ) <= ( wep.LockOnRange * wep.LockOnRange ) and lockables[ 1 ]
                ply:SetNW2Entity( "cd2_lockontarget", target )
                

                if IsValid( ply:GetNW2Entity( "cd2_lockontarget", nil ) ) then
                    local pos = ply.cd2_LockOnPos == "body" and ply:GetNW2Entity( "cd2_lockontarget", nil ):WorldSpaceCenter() or ply:GetNW2Entity( "cd2_lockontarget", nil ):CD2EyePos()
                    ply:SetEyeAngles( ( pos - ply:EyePos() ):Angle() )
                end

            else
                ply.cd2_LockOnPos = nil
                ply:SetNW2Entity( "cd2_lockontarget", NULL )
            end

        end
    end

    if CLIENT then 

        local ply = LocalPlayer()
        if !IsValid( ply ) and !ply:IsCD2Agent() then return end

        local lockontarget = ply:GetNW2Entity( "cd2_lockontarget", nil )

        if IsValid( lockontarget ) then
            -- Play lock on sound
            if !limitlockonsound then
                surface.PlaySound( "crackdown2/ply/lockon.mp3" ) 
                limitlockonsound = true
            end

            if CD2_LockOnPos != CD2_LastLockOnPos then
                net.Start( "cd2net_changelockonpos" )
                net.WriteString( CD2_LockOnPos )
                net.SendToServer()
                surface.PlaySound( "crackdown2/ply/switchlockonpos.mp3" ) 
            end
            CD2_LastLockOnPos = CD2_LockOnPos

            local pos = CD2_LockOnPos == "body" and lockontarget:WorldSpaceCenter() or CD2_LockOnPos == "head" and lockontarget:CD2EyePos()
            local dir = ( pos - CD2_vieworigin ):Angle() 
            dir:Normalize() -- Funny story with this, without this function, when you go below the target your view jumps straight down. No clue why but this fixed it
            ply:SetEyeAngles( ( pos - ply:EyePos() ):Angle() )
            
            CD2_viewangles = dir
            CD2_viewlockedon = true
            
        else
            CD2_viewlockedon = false
            limitlockonsound = false
        end

        CD2_lockon = #CD2FindInLockableTragets( ply ) > 0
        
    end 

end )

if SERVER then

    -- Decaying Lock on Spread
    hook.Add( "Tick", "crackdown2_lockonspreadhandle", function()
        local players = player_GetAll()
        for i = 1, #players do
            local ply = players[ i ]
            ply.cd2_LockOnPos = ply.cd2_LockOnPos or "body"
            ply.cd2_lockondecayspeed = ply.cd2_lockondecayspeed or 10
            if !ply:IsCD2Agent() then return end
            
            if ply:GetLockonSpreadDecay() > 0 then
                if IsValid( ply:GetNW2Entity( "cd2_lockontarget", nil ) ) then 
                    ply:SetLockonSpreadDecay( Lerp( ply.cd2_lockondecayspeed * FrameTime(), ply:GetLockonSpreadDecay(), 0 ) )
                else
                    ply:SetLockonSpreadDecay( 0 )
                end
            end
        end
    end )


    net.Receive( "cd2net_changelockonpos", function( len, ply )
        ply.cd2_LockOnPos = net.ReadString()
        local targ = ply:GetNW2Entity( "cd2_lockontarget", nil )
        
        if IsValid( targ ) and ply.cd2_LockOnPos == "head" then 
            local dist = ply:GetPos():Distance( targ:GetPos() )

            ply.cd2_lockondecayspeed = 10 / ( dist / 300 )
            ply:SetLockonSpreadDecay( ( dist / 200 ) * 0.08 ) 
        elseif IsValid( targ ) and ply.cd2_LockOnPos == "body" then
            ply:SetLockonSpreadDecay( 0 ) 
        end
        
    end )
end


------