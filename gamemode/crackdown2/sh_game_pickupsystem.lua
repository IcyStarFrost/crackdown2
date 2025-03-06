
local player_GetAll = player.GetAll
local upper = string.upper
local IsValid = IsValid

local isphysics = {
    [ "prop_physics" ] = true,
    [ "prop_physics_multiplayer" ] = true,
    [ "prop_ragdoll" ] = true,
    [ "func_physbox" ] = true,
    [ "cd2_prop" ] = true
}

-- New rewritten pick up system
hook.Add( "Tick", "crackdown2_pickupsystem", function()
    if CLIENT then return end
    local players = player_GetAll()

    for i = 1, #players do
        local ply = players[ i ]
        if !ply:IsCD2Agent() or ply:GetIsStunned() or !IsValid( ply:GetActiveWeapon() ) then continue end

        local near = CD2:FindInSphere( ply:GetPos(), 100, function( ent ) return ( isphysics[ ent:GetClass() ] or ent.cd2_allowpickup ) and ent:GetNW2Int( "cd2_mass", math.huge ) < ply:GetMaxPickupWeight() and ply:Visible( ent ) and ent:SqrRangeTo( ply ) < ( 100 * 100 ) and IsValid( ent:GetPhysicsObject() ) and ent:GetPhysicsObject():IsMotionEnabled() end )
        
        if ( !ply.cd2_meleecooldown or CurTime() > ply.cd2_meleecooldown ) then
            ply:SetPickupObject( CD2:GetClosestInTable( near, ply ) )
        else
            ply:SetPickupObject( nil )
        end


        -- Held key
        if ply:IsButtonDown( ply:GetInfoNum( "cd2_interact1", KEY_Q ) ) and IsValid( ply:GetPickupObject() ) then ply.cd2_PickupDelay = ply.cd2_PickupDelay or CurTime() + 0.2 else ply.cd2_PickupDelay = nil end

        -- Pickup a new object
        if !IsValid( ply.cd2_HeldObject ) and IsValid( ply:GetPickupObject() ) and ( ply.cd2_PickupDelay and CurTime() > ply.cd2_PickupDelay ) then
            ply:GetActiveWeapon():EnterPickupMode()
            local ent = ply:GetPickupObject()

            ent:SetPos( ply:HandsPos() )
            ent:SetAngles( ply:HandsAngles() )

            if !ent:IsRagdoll() then
                ent:SetParent( ply, ply:LookupAttachment( "anim_attachment_RH" ) )
            end

            ent:SetOwner( ply )
            ent:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
            ent:Use( ply, ply, USE_TOGGLE )

            ply:SetIsHoldingEnt( true )
            ply.cd2_HeldObject = ent
            ply.cd2_PickupDelay = math.huge -- Prevent the delayed code from running again until the use key is lifted

        elseif IsValid( ply.cd2_HeldObject ) and ( ply.cd2_PickupDelay and CurTime() > ply.cd2_PickupDelay or !ply:Alive() ) then -- Drop the held object

            local ent = ply.cd2_HeldObject
            ent:SetParent()
            ent:SetPos( ply:HandsPos() )
            ent:SetCollisionGroup( COLLISION_GROUP_NONE )
            ent:SetAngles( ply:HandsAngles() )
            ent:PhysWake()

            timer.Simple( 1, function() if !IsValid( ent ) then return end ent:SetOwner( NULL ) end )

            ply:SetIsHoldingEnt( false )
            if IsValid( ply:GetActiveWeapon() ) then ply:GetActiveWeapon():ExitPickupMode() end
            ply.cd2_HeldObject = nil
            ply.cd2_PickupDelay = math.huge -- Prevent the delayed code from running again until the use key is lifted

        elseif IsValid( ply.cd2_HeldObject ) and ply:KeyPressed( IN_ATTACK ) and !ply:KeyDown( IN_USE ) then -- Throw the held object

            ply:SetAnimation( PLAYER_ATTACK1 )

            local ent = ply.cd2_HeldObject
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

            ply:SetIsHoldingEnt( false )
            timer.Simple( 1, function()
                if IsValid( ply ) and IsValid( ply:GetActiveWeapon() ) then
                    ply:GetActiveWeapon():ExitPickupMode() 
                end
                if IsValid( ent ) then 
                    ent:SetOwner( NULL ) 
                end
            end )
            ply.cd2_HeldObject = nil
        end

        -- Code to set ragdoll's position to the player's hands
        if IsValid( ply.cd2_HeldObject ) and ply.cd2_HeldObject:IsRagdoll() then
            local ent = ply.cd2_HeldObject
            local phys = ent:GetPhysicsObject()

            if IsValid( phys ) then
                phys:SetPos( ply:HandsPos() )
            end
        end

        -- Incase the held entity gets deleted
        if !IsValid( ply.cd2_HeldObject ) and ply:GetIsHoldingEnt() then
            ply:SetIsHoldingEnt( false )
            ply:GetActiveWeapon():ExitPickupMode()
        end

    end

end )

if CLIENT then

    hook.Add( "HUDPaint", "crackdown2_pickupprompt", function()
        if !GetConVar( "cd2_drawhud" ):GetBool() then return end
        local ply = LocalPlayer()

        if !ply:IsCD2Agent() or !ply:Alive() then return end

        local targ = ply:GetPickupObject()
        local isholding = ply:GetIsHoldingEnt()

        if !IsValid( targ ) or isholding then return end
        
        local screen = ( targ:GetPos() + Vector( 0, 0, 30 ) ):ToScreen()
        CD2:DrawInputBar( screen.x, screen.y, CD2:GetInteractKey1(), "Hold to pickup/drop object" )
    end )

end