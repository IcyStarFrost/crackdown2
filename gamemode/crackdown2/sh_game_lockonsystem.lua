local player_GetAll = player.GetAll

-- Crackdown 2 Lockon system --
local limitlockonsound = false
hook.Add( "Think", "crackdown2_lockon", function()

    if SERVER then
        local players = player_GetAll() 
        for i = 1, #players do
            local ply = players[ i ]
            if !ply:Alive() or !ply:IsCD2Agent() then continue end
            

            if ply:KeyDown( IN_ATTACK2 ) then
                local wep = ply:GetActiveWeapon()
                if !IsValid( wep ) then return end
                
                local lockables = CD2FindInLockableTragets( ply )

                local oldtarget = ply:GetNW2Entity( "cd2_lockontarget", nil )
                local target = IsValid( oldtarget ) and oldtarget:GetPos():DistToSqr( ply:GetPos() ) <= ( wep.LockOnRange * wep.LockOnRange ) and oldtarget or IsValid( lockables[ 1 ] ) and lockables[ 1 ]:GetPos():DistToSqr( ply:GetPos() ) <= ( wep.LockOnRange * wep.LockOnRange ) and lockables[ 1 ]
                ply:SetNW2Entity( "cd2_lockontarget", target )
                

                if IsValid( ply:GetNW2Entity( "cd2_lockontarget", nil ) ) then
                    ply:SetEyeAngles( ( ply:GetNW2Entity( "cd2_lockontarget", nil ):WorldSpaceCenter() - ply:EyePos() ):Angle() )
                end

            else
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

            local dir = ( lockontarget:WorldSpaceCenter() - CD2_vieworigin ):Angle() 
            dir:Normalize() -- Funny story with this, without this function, when you go below the target your view jumps straight down. No clue why but this fixed it
            ply:SetEyeAngles( ( lockontarget:WorldSpaceCenter() - ply:EyePos() ):Angle() )
            
            CD2_viewangles = dir
            CD2_viewlockedon = true
            
        else
            CD2_viewlockedon = false
            limitlockonsound = false
        end

        CD2_lockon = #CD2FindInLockableTragets( ply ) > 0
        
    end 

end )
------