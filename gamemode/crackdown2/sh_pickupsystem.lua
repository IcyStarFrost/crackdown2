
local player_GetAll = player.GetAll
local upper = string.upper
local IsValid = IsValid

local isphysics = {
    [ "prop_physics" ] = true,
    [ "prop_physics_multiplayer" ] = true,
    [ "prop_ragdoll" ] = true
}

local delay = 0

hook.Add( "Tick", "crackdown2_pickupsystem", function()

    for k, ply in ipairs( player_GetAll() ) do
        if !ply:IsCD2Agent() then continue end

        if IsValid( ply.cd2_HeldTarget ) and ply.cd2_HeldTarget:IsRagdoll() then
            local ent = ply.cd2_HeldTarget
            local phys = ent:GetPhysicsObject()

            if IsValid( phys ) then
                phys:SetPos( ply:HandsPos() )
                --phys:SetAngles( ply:HandsAngles() )
            end
        end

        if IsValid( ply.cd2_HeldTarget ) and ply:KeyPressed( IN_ATTACK ) and !ply:KeyDown( IN_USE ) then
            ply.cd2_pickupfailsafetime = CurTime() + 1
            ply:SetAnimation( PLAYER_ATTACK1 )
            local ent = ply.cd2_HeldTarget
            ent:SetParent()
            ent:SetCollisionGroup( COLLISION_GROUP_NONE )
            ent:SetPos( ply:HandsPos() )
            ent:SetAngles( ply:HandsAngles() )
            ent:PhysWake()
            if SERVER then ent:SetPhysicsAttacker( ply, 2 ) end
            
            local phys = ent:GetPhysicsObject()

            if IsValid( phys ) then
                local mult = ent:IsRagdoll() and 800000 or 1500
                phys:ApplyForceCenter( ply:GetAimVector() * ( phys:GetMass() * mult ) )
            end

            timer.Simple( 1, function() if !IsValid( ent ) then return end ent:SetOwner( NULL ) ply:GetActiveWeapon():ExitPickupMode() end )
            ply.cd2_HeldTarget = nil
        end

        if CLIENT and ply != LocalPlayer() then continue end

        local find = CD2FindInSphere( ply:GetPos(), 100, function( ent ) return isphysics[ ent:GetClass() ] and ent:GetNW2Int( "cd2_mass", 10000000 ) < ply:GetMaxPickupWeight() and ply:Trace( nil, ent:WorldSpaceCenter(), nil, nil ).Entity == ent end )
        ply.cd2_Pickuptarget = CD2GetClosestInTable( find, ply )
        if ply:KeyDown( IN_USE ) then ply.cd2_PickupDelay = ply.cd2_PickupDelay or CurTime() + 1 else ply.cd2_PickupDelay = nil end
        
        if IsValid( ply.cd2_Pickuptarget ) and !IsValid( ply.cd2_HeldTarget ) and ( ply.cd2_PickupDelay and CurTime() > ply.cd2_PickupDelay ) then
            ply:GetActiveWeapon():EnterPickupMode()

            local ent = ply.cd2_Pickuptarget
            ent:SetPos( ply:HandsPos() )
            ent:SetAngles( ply:HandsAngles() )
            if !ent:IsRagdoll() then
                ent:SetParent( ply, ply:LookupAttachment( "anim_attachment_RH" ) )
            end
            ent:SetOwner( ply )
            ent:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
            ply.cd2_PickupDelay = math.huge

            ply.cd2_HeldTarget = ent
            ply.cd2_pickupfailsafetime = CurTime() + 1

        elseif IsValid( ply.cd2_HeldTarget ) and ( ply.cd2_PickupDelay and CurTime() > ply.cd2_PickupDelay ) then
            ply.cd2_pickupfailsafetime = CurTime() + 1
            local ent = ply.cd2_HeldTarget
            ent:SetParent()
            ent:SetPos( ply:HandsPos() )
            ent:SetCollisionGroup( COLLISION_GROUP_NONE )
            ent:SetAngles( ply:HandsAngles() )
            ent:PhysWake()

            timer.Simple( 1, function() if !IsValid( ent ) then return end ent:SetOwner( NULL ) end )
            ply:GetActiveWeapon():ExitPickupMode()
            ply.cd2_HeldTarget = nil
            ply.cd2_PickupDelay = math.huge
        end

        if ply.cd2_HeldTarget == NULL then
            ply:GetActiveWeapon():ExitPickupMode()
            ply.cd2_HeldTarget = nil
        end

        if !IsValid( ply.cd2_HeldTarget ) and IsValid( ply:GetActiveWeapon() ) and ply:GetActiveWeapon():GetPickupMode() and ( ply.cd2_pickupfailsafetime and CurTime() > ply.cd2_pickupfailsafetime ) then
            ply:GetActiveWeapon():ExitPickupMode()
            ply.cd2_HeldTarget = nil
        end

        if CLIENT and IsValid( ply.cd2_HeldTarget ) and ply.cd2_HeldTarget:GetPos():DistToSqr( ply:GetPos() ) > ( 200 * 200 ) then
            ply.cd2_HeldTarget = nil
        end
        
    end
    
end )

if CLIENT then
    local input_LookupBinding = input.LookupBinding
    local input_GetKeyCode = input.GetKeyCode
    local input_GetKeyName = input.GetKeyName

    hook.Add( "HUDPaint", "crackdown2_pickupprompt", function()
        local ply = LocalPlayer()
        local targ = ply.cd2_Pickuptarget
        if !IsValid( targ ) or IsValid( ply.cd2_HeldTarget ) then return end
        local usebind = input_LookupBinding( "+use" ) or "e"
        local code = input_GetKeyCode( usebind )
        local buttonname = input_GetKeyName( code )
        
        local screen = ( targ:GetPos() + Vector( 0, 0, 30 ) ):ToScreen()
        CD2DrawInputbar( screen.x, screen.y, upper( buttonname ), "Hold to pickup/drop object" )
    end )

end