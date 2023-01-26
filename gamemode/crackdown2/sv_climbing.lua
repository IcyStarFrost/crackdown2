local ipairs = ipairs

local cooldown = 0
hook.Add( "Tick", "crackdown2_climbing", function()

    for k, ply in ipairs( player.GetAll() ) do
        if !IsValid( ply ) or !ply:Alive() or !ply:IsCD2Agent() then continue end

        if ply.cd2_grabbedledge then
            ply:SetVelocity( -ply:GetVelocity() )
            ply:SetPos( ply.cd2_grabbedpos )
            if ply:KeyDown( IN_JUMP ) then ply.cd2_ledgedelay = CurTime() + 1 ply.cd2_grabbedledge = false ply:SetVelocity( Vector( 0, 0, ply:GetJumpPower() ) ) ply:EmitSound( "crackdown2/ply/jump" .. math.random( 1, 4 ) .. ".wav", 60, 100, 0.2, CHAN_AUTO ) end
        end

        if CurTime() > cooldown then 
            local topresult = ply:Trace( ply:EyePos(), ply:EyePos() + ply:GetForward() * 30, COLLISION_GROUP_WORLD, MASK_SOLID_BRUSHONLY )
            local midresult = ply:Trace( ply:WorldSpaceCenter(), ply:WorldSpaceCenter() + ply:GetForward() * 30, COLLISION_GROUP_WORLD, MASK_SOLID_BRUSHONLY )

            if !ply:IsOnGround() and !ply.cd2_grabbedledge and midresult.Hit and !topresult.Hit and ( !ply.cd2_ledgedelay or CurTime() > ply.cd2_ledgedelay ) then
                ply:EmitSound( "crackdown2/ply/ledgegrab" .. math.random( 1, 2 ) .. ".mp3", 60, 100, 0.5 )
                ply.cd2_grabbedledge = true
                ply.cd2_grabbedpos = ply:GetPos()
                local dmg = gmod.GetGamemode():GetFallDamage( ply, math.abs( ply:GetVelocity()[ 3 ] ) ) 
                if dmg > 0 then
                    local fall = DamageInfo()
                    fall:SetDamage( dmg )
                    fall:SetDamageType( DMG_FALL )
                    ply:TakeDamageInfo( fall )
                end
            end
            cooldown = CurTime() + 0.05
        end
    end
end )