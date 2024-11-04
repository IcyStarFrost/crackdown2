local clamp = math.Clamp
local ceil = math.ceil
hook.Add( "PlayerCanPickupWeapon", "crackdown2_npcweapons", function( ply, wep )
    if IsValid( wep.cd2_reservedplayer ) and ply != wep.cd2_reservedplayer then return false end
    if wep:WaterLevel() != 0 then return false end
    local wepowner = wep:GetOwner()
    if IsValid( wepowner ) and wepowner:IsCD2NPC() then
        return false
    end

    local haswep = ply:HasWeapon( wep:GetClass() ) 
    if haswep and ply:GetWeapon( wep:GetClass() ):Ammo1() >= wep.Primary.DefaultClip then
        return false
    elseif haswep and ply:GetWeapon( wep:GetClass() ):Ammo1() < wep.Primary.DefaultClip then
        local count = clamp( ply:GetAmmoCount( wep.Primary.Ammo ) + ( ceil( wep.Primary.DefaultClip / 6 ) ), 0, wep.Primary.DefaultClip )
        ply:GetWeapon( wep:GetClass() ).cd2_Ammocount = count
        ply:SetAmmo( count, wep.Primary.Ammo )
        wep:Remove()
        ply:EmitSound( "items/ammo_pickup.wav", 60 )
        return false
    end

    if #ply:GetWeapons() < 2 then

        timer.Simple( 0, function()
            if !IsValid( ply ) then return end
            for k, v in ipairs( ply:GetWeapons() ) do
                if v != ply:GetActiveWeapon() then 
                    ply.cd2_holsteredweapon:SetModel( v:GetModel() )
                    local mins = ply.cd2_holsteredweapon:GetModelBounds()
                    ply.cd2_holsteredweapon:SetLocalPos( Vector( -10, -9, 0 ) - mins / 2 )
                    break 
                end 
                
            end
        end )

        return true
    end

    if !haswep and ( !ply.cd2_WeaponSpawnDelay or CurTime() > ply.cd2_WeaponSpawnDelay ) and !IsValid( ply.cd2_HeldObject ) then
        local activewep = ply:GetActiveWeapon()

        if ply:IsButtonDown( ply:GetInfoNum( "cd2_interact3", KEY_R ) ) then ply.cd2_PickupWeaponDelay = ply.cd2_PickupWeaponDelay or CurTime() + 0.3 else ply.cd2_PickupWeaponDelay = nil end

        if ply.cd2_PickupWeaponDelay and CurTime() > ply.cd2_PickupWeaponDelay and ply:GetInteractable3() == wep or ( activewep:Ammo1() == 0 and activewep:Clip1() == 0 ) then

            local activewep = ply:GetActiveWeapon()

            if !IsValid( activewep ) then return end

            ply:DropWeapon( activewep, ply:GetPos() + ply:GetForward() * 100 )
            activewep.cd2_Ammocount = ply:GetAmmoCount( activewep.Primary.Ammo )
            
            ply:PickupWeapon( wep )
            ply:EmitSound( "items/ammo_pickup.wav", 60 )
            ply:SetActiveWeapon( wep )

            ply.cd2_PickupDelay = math.huge
            ply.cd2_PickupWeaponDelay = math.huge
        end
        return false
    end

    if IsValid( ply.cd2_HeldObject ) then return false end

end )

local upper = string.upper
local input_GetKeyName = CLIENT and input.GetKeyName
hook.Add( "HUDPaint", "crackdown2_pickupweaponpaint", function()
    if !GetConVar( "cd2_drawhud" ):GetBool() then return end
    local ply = LocalPlayer()

    if !ply:IsCD2Agent() then return end

    local wep = ply:GetInteractable3()
    local curwep = ply:GetActiveWeapon()
    if !IsValid( wep ) or !wep:IsWeapon() or !IsValid( curwep ) then return end

    local buttonname = input_GetKeyName( CD2:GetConVar( "cd2_interact3" ):GetInt() )
    
    local screen = ( wep:GetPos() + Vector( 0, 0, 30 ) ):ToScreen()
    CD2DrawInputbar( screen.x, screen.y, upper( buttonname ), "Hold to Equip " .. wep:GetPrintName() .. " / Drop " .. curwep:GetPrintName() )
end )


-- For cd2_equipmentbase.lua

hook.Add( "HUDPaint", "crackdown2_pickupequipmentpaint", function()
    if !GetConVar( "cd2_drawhud" ):GetBool() then return end
    local ply = LocalPlayer()
    if !ply:IsCD2Agent() then return end

    local equipment = ply:GetInteractable3()

    if !IsValid( equipment ) then return end

    local buttonname = input_GetKeyName( CD2:GetConVar( "cd2_interact3" ):GetInt() )
    
    local screen = ( equipment:GetPos() + Vector( 0, 0, 30 ) ):ToScreen()
    CD2DrawInputbar( screen.x, screen.y, upper( buttonname ), "Hold to Equip " .. equipment:GetPrintName() .. " / Drop " .. scripted_ents.Get( ply:GetEquipment() ).PrintName )
end )