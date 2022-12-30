local random = math.random

-- If the player dies in singleplayer drop all their weapons instantly rather than in multiplayer waiting if they enter the spawn point menu
hook.Add( "DoPlayerDeath", "crackdown2_dropweaponssingleplayer", function( ply, attacker, dmginfo )
    if !ply:IsCD2Agent() then return end

    if game.SinglePlayer() then
        local weps = ply:GetWeapons()
        for i = 1, #weps do 
            local wep = weps[ i ]
            if IsValid( wep ) then
                ply:DropWeapon( wep, ply:GetPos() + VectorRand( -70, 70 ) )
            end
        end

        local equipment = ents.Create( ply.cd2_Equipment )
        equipment:SetPos( ply:WorldSpaceCenter() )
        equipment:Spawn()

        local phys = equipment:GetPhysicsObject()

        if IsValid( phys ) then
            phys:ApplyForceCenter( Vector( random( -8000, 8000 ), random( -8000, 8000 ), random( 0, 8000 ) ) )
        end
    end
end )


-- Equipment usage

-- Activated when the +grenade1 bind is pressed
hook.Add( "KeyPress", "crackdown2_equipmentuse", function( ply, key )
    if key == IN_GRENADE1 and ply:GetEquipmentCount() > 0 and ( !ply.cd2_grenadecooldown or CurTime() > ply.cd2_grenadecooldown ) then

        CD2CreateThread( function()

            ply:SetEquipmentCount( ply:GetEquipmentCount() - 1 )

            local tbl = scripted_ents.Get( CLIENT and CD2_DropEquipment or ply.cd2_Equipment )
            ply.cd2_grenadecooldown = CurTime() + tbl.Cooldown

            BroadcastLua( "Entity( " .. ply:EntIndex() .. " ):AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_GMOD_GESTURE_ITEM_THROW, true )" )
            coroutine.wait( 0.5 )

            ply:EmitSound( "crackdown2/weapons/grenadethrow.mp3", 60, 100, 1, CHAN_WEAPON )

            coroutine.wait( 0.3 )

            if SERVER then
                local pos = ply:GetEyeTrace().HitPos
                CD2ThrowEquipment( ply.cd2_Equipment , ply, pos )
            end

        end )
    end
end )


-- Melee System

local TraceHull = util.TraceHull
local FindInBox = ents.FindInBox
local hulltbl = {}
local meleeanims = { ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 }

-- Hold down use and press attack to melee
hook.Add( "KeyPress", "crackdown2_meleesystem", function( ply, key )
    if !ply:IsCD2Agent() then return end

    local wep = ply:GetActiveWeapon()

    if IsValid( wep ) and !wep:GetIsReloading() and key == IN_ATTACK and ply:KeyDown( IN_USE ) and ( !ply.cd2_meleecooldown or CurTime() > ply.cd2_meleecooldown ) then
        
        if IsValid( ply.cd2_HeldObject ) then
            BroadcastLua( "Entity( " .. ply:EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE, true )" )
        else
            BroadcastLua( "Entity( " .. ply:EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_ATTACK_AND_RELOAD, " .. meleeanims[ random( #meleeanims ) ] .. ", true )" )
        end
        if ply:IsOnGround() then ply:SetVelocity( ply:GetForward() * 500) end
        ply:EmitSound( "WeaponFrag.Throw", 80, 100, 1, CHAN_WEAPON )

        local start = ply:GetPos() + ply:GetForward() * 50 + Vector( 0, 0, 5 )
        local mins = Vector( -70, -70, 0 )
        local maxs = Vector( 70, 70, 53 )
        local entities = FindInBox( start + mins, start + maxs )

        if #entities > 0 then
            for i = 1, #entities do
                local hitent = entities[ i ]
                if !IsValid( hitent ) then continue end

                local trace = ply:Trace( nil, hitent:WorldSpaceCenter() )

                if hitent != ply and hitent != ply.cd2_HeldObject and ( trace.Entity == hitent or !trace.Hit ) then
                    hitent:EmitSound( "physics/flesh/flesh_impact_hard" .. random( 1, 6 ) .. ".wav")
                    local heldobjectphys = IsValid( ply.cd2_HeldObject ) and ply.cd2_HeldObject:GetPhysicsObject()
                    local add = IsValid( heldobjectphys ) and heldobjectphys:GetMass() / 10 or 0

                    local hitphys = hitent:GetPhysicsObject()
                    local force = hitent:IsCD2NPC() and 20000 or IsValid( hitphys ) and hitphys:GetMass() * 10 or 20000
                    local normal = ( hitent:WorldSpaceCenter() - ply:WorldSpaceCenter() ):GetNormalized()
                    
                    local info = DamageInfo()
                    info:SetAttacker( ply )
                    info:SetInflictor( wep )
                    info:SetDamage( ply:GetMeleeDamage() + add )
                    info:SetDamageType( DMG_CLUB )
                    info:SetDamageForce( normal * force )
                    hitent:TakeDamageInfo( info )
                end
            end
        end
        
        ply.cd2_meleecooldown = CurTime() + 0.5
    end 

end )