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
                wep.cd2_Ammocount = ply:GetAmmoCount( wep.Primary.Ammo )
            end
        end

        local equipment = ents.Create( ply:GetEquipment() )
        equipment:SetPos( ply:WorldSpaceCenter() )
        equipment.cd2_equipmentcount = ply:GetEquipmentCount()
        equipment:Spawn()

        local phys = equipment:GetPhysicsObject()

        if IsValid( phys ) then
            phys:ApplyForceCenter( Vector( random( -8000, 8000 ), random( -8000, 8000 ), random( 0, 8000 ) ) )
        end

        ply:StripAmmo()
    end
end )


-- Equipment usage

-- Activated when the +grenade1 bind is pressed
hook.Add( "KeyPress", "crackdown2_equipmentuse", function( ply, key )
    if key == IN_GRENADE1 and ( ply:GetEquipmentCount() > 0 or ply.cd2_infiniteammo ) and ( !ply.cd2_grenadecooldown or CurTime() > ply.cd2_grenadecooldown ) then

        CD2CreateThread( function()

            if !ply.cd2_infiniteammo then ply:SetEquipmentCount( ply:GetEquipmentCount() - 1 ) end

            local tbl = scripted_ents.Get( ply:GetEquipment() )
            ply.cd2_grenadecooldown = CurTime() + tbl.Cooldown

            BroadcastLua( "Entity( " .. ply:EntIndex() .. " ):AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_GMOD_GESTURE_ITEM_THROW, true )" )
            coroutine.wait( 0.5 )

            ply:EmitSound( "crackdown2/weapons/grenadethrow.mp3", 60, 100, 1, CHAN_WEAPON )

            coroutine.wait( 0.3 )

            if SERVER then
                local pos = ply:GetEyeTrace().HitPos
                CD2ThrowEquipment( ply:GetEquipment(), ply, pos )
            end

        end )
    end
end )


-- Melee System

local TraceHull = util.TraceHull
local FindInBox = ents.FindInBox
local hulltbl = {}
local meleeanims = { ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 }
local red = Color( 209, 42, 0 )

-- Hold down use and press attack to melee
hook.Add( "KeyPress", "crackdown2_meleesystem", function( ply, key )
    if !ply:IsCD2Agent() or !ply:GetCanUseMelee() then return end

    local wep = ply:GetActiveWeapon()

    if ply:IsOnGround() and IsValid( wep ) and !wep:GetIsReloading() and key == IN_ATTACK and ply:KeyDown( IN_USE ) and ( !ply.cd2_meleecooldown or CurTime() > ply.cd2_meleecooldown ) then
        local nearby = CD2FindInSphere( ply:GetPos(), 300, function( ent ) return ent:IsCD2NPC() end )
        local closest = CD2GetClosestInTable( nearby, ply )
        if IsValid( closest ) then
            local dir = ( closest:CD2EyePos() - ply:EyePos() ):Angle()
            dir:Normalize()
            net.Start( "cd2net_setplayerangle" )
            net.WriteAngle( dir )
            net.Send( ply )
        end

        if IsValid( ply.cd2_HeldObject ) then
            BroadcastLua( "Entity( " .. ply:EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE, true )" )
        else
            BroadcastLua( "Entity( " .. ply:EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_ATTACK_AND_RELOAD, " .. meleeanims[ random( #meleeanims ) ] .. ", true )" )
        end

        CD2CreateThread( function()
            coroutine.wait( 0.1 )
            if !IsValid( ply ) then return end
            ply:SetVelocity( ply:GetForward() * 500 )
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
            ply:Freeze( true )
            coroutine.wait( 0.5 )
            if !IsValid( ply ) then return end
            ply:Freeze( false )
        end )
        
        ply.cd2_PickupDelay = math.huge
        ply.cd2_meleecooldown = CurTime() + 0.5
    end 

end )

local sound_Play = sound.Play
-- Ground pound ability

-- While in air, hold use and press attack
hook.Add( "KeyPress", "crackdown2_groundstrike", function( ply, key )
    if !ply:IsCD2Agent() or ply:GetStrengthSkill() < 4 then return end

    if !ply:IsOnGround() and ply:KeyDown( IN_USE ) and key == IN_ATTACK and !ply.cd2_IsUsingGroundStrike then
        local wep = ply:GetActiveWeapon()
        if !IsValid( wep ) then return end
        wep:SetPickupMode( true )
        wep:SetHoldType( "melee" )

        ply.cd2_IsUsingGroundStrike = true
        ply:EmitSound( "crackdown2/ply/groundstrikeinit.mp3", 60 )
        ply:EmitSound( "crackdown2/ply/die.mp3", 60 )
        CD2CreateThread( function()

            local trail1 = util.SpriteTrail( ply, ply:LookupAttachment( "anim_attachment_RH"), red, true, 20, 0, 1.5, 1 / ( 20 + 0 ) * 0.5, "trails/laser" )
            local trail2 = util.SpriteTrail( ply, ply:LookupAttachment( "anim_attachment_LH"), red, true, 20, 0, 1.5, 1 / ( 20 + 0 ) * 0.5, "trails/laser" )

            while !ply:IsOnGround() do
                ply:SetVelocity( Vector( 0, 0, -20 ) )
                coroutine.yield()
            end

            
            ply:StopSound( "crackdown2/ply/die.mp3" )
            ply:StopSound( "crackdown2/ply/groundstrikeinit.mp3" )
            BroadcastLua( "Entity( " .. ply:EntIndex() .. "):AnimRestartGesture( GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2, true )" )

            net.Start( "cd2net_playerlandingdecal" )
            net.WriteVector( ply:WorldSpaceCenter() )
            net.WriteBool( true  )
            net.Broadcast()

            net.Start( "cd2net_playergroundpound" )
            net.WriteVector( ply:GetPos() )
            net.Broadcast()

            if IsValid( wep ) then
                wep:SetPickupMode( false )
                wep:SetHoldType( wep.HoldType )
            end

            local near = CD2FindInSphere( ply:GetPos(), 200, function( ent ) return ent != ply end )

            for i = 1, #near do
                local ent = near[ i ]
                if !IsValid( ent ) then return end
                local force = ent:IsCD2NPC() and 20000 or IsValid( hitphys ) and hitphys:GetMass() * 50 or 20000
                local info = DamageInfo()
                info:SetAttacker( ply )
                info:SetInflictor( wep )
                info:SetDamage( ply:GetMeleeDamage() * 4 )
                info:SetDamageType( DMG_CLUB )
                info:SetDamageForce( ( ent:WorldSpaceCenter() - ply:GetPos() ):GetNormalized() * force )
                info:SetDamagePosition( ply:GetPos() )
                ent:TakeDamageInfo( info )
            end

            sound_Play( "crackdown2/ply/groundstrike.mp3", ply:GetPos(), 80, 100, 1 )
            sound_Play( "crackdown2/ply/hardland" .. random( 1, 2 ) .. ".wav", ply:GetPos(), 70, 100, 1 )
            ply.cd2_IsUsingGroundStrike = false

            if IsValid( trail1 ) then trail1:Remove() end
            if IsValid( trail2 ) then trail2:Remove() end

            if !KeysToTheCity() and !ply.cd2_hadfirstgroundpound then
                CD2FILESYSTEM:RequestPlayerData( ply, "cd2_firstgroundpound", function( val ) 
                    if !val then
                        ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/groundstrike_achieve.mp3" )
                        CD2FILESYSTEM:WritePlayerData( ply, "cd2_firstgroundpound", true )
                    end
                    ply.cd2_hadfirstgroundpound = true
                end )
            end

        end )

    end
end )