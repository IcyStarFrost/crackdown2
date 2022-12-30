hook.Add( "PlayerCanPickupWeapon", "crackdown2_npcweapons", function( ply, wep )
    local wepowner = wep:GetOwner()
    if IsValid( wepowner ) and wepowner:IsCD2NPC() then
        return false
    end

    local haswep = ply:HasWeapon( wep:GetClass() ) 
    if haswep and ply:GetWeapon( wep:GetClass() ):Ammo1() >= ( wep.Primary.DefaultClip - wep.Primary.ClipSize ) then
        return false
    elseif haswep and ply:GetWeapon( wep:GetClass() ):Ammo1() < ( wep.Primary.DefaultClip - wep.Primary.ClipSize ) then
        ply:SetAmmo( clamp( ply:GetAmmoCount( wep.Primary.Ammo ) + ( ceil( wep.Primary.DefaultClip / 6 ) ), 0, wep.Primary.DefaultClip ), wep.Primary.Ammo )
        wep:Remove()
        ply:EmitSound( "items/ammo_pickup.wav", 60 )
        return false
    end

    if !haswep and ( !ply.cd2_WeaponSpawnDelay or CurTime() > ply.cd2_WeaponSpawnDelay ) and !IsValid( ply.cd2_HeldObject ) then
        ply:SetNW2Entity( "cd2_targetweapon", wep )
        ply:SetNW2Float( "cd2_weapondrawcur", CurTime() + 0.1 )
        if ply:KeyDown( IN_USE ) then ply.cd2_PickupWeaponDelay = ply.cd2_PickupWeaponDelay or CurTime() + 1 else ply.cd2_PickupWeaponDelay = nil end

        if ply.cd2_PickupWeaponDelay and CurTime() > ply.cd2_PickupWeaponDelay then

            local activewep = ply:GetActiveWeapon()

            if !IsValid( activewep ) then return end

            ply:DropWeapon( activewep, ply:GetPos() + ply:GetForward() * 100 )
            activewep.cd2_Ammocount = ply:GetAmmoCount( activewep.Primary.Ammo )
            
            ply:PickupWeapon( wep )
            if wep.cd2_Ammocount then
                ply:SetAmmo( wep.cd2_Ammocount, wep.Primary.Ammo )
            end
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
local input_LookupBinding = CLIENT and input.LookupBinding
local input_GetKeyCode = CLIENT and input.GetKeyCode
local input_GetKeyName = CLIENT and input.GetKeyName
hook.Add( "HUDPaint", "crackdown2_pickupweaponpaint", function()
    local ply = LocalPlayer()
    local wep = ply:GetNW2Entity( "cd2_targetweapon", nil )
    local render = ply:GetNW2Float( "cd2_weapondrawcur", 0 )
    local curwep = ply:GetActiveWeapon()
    if !IsValid( wep ) or !IsValid( curwep ) or CurTime() > render then return end

    local usebind = input_LookupBinding( "+use" ) or "e"
    local code = input_GetKeyCode( usebind )
    local buttonname = input_GetKeyName( code )
    
    local screen = ( wep:GetPos() + Vector( 0, 0, 30 ) ):ToScreen()
    CD2DrawInputbar( screen.x, screen.y, upper( buttonname ), "Hold to Equip " .. wep:GetPrintName() .. " / Drop " .. curwep:GetPrintName() )
end )