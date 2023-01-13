
hook.Add( "Tick", "crackdown2_antibeaconfreaks", function()
    local beacons = ents.FindByClass( "cd2_beacon" )

    for i = 1, #beacons do
        local beacon = beacons[ i ]
        if IsValid( beacon ) and beacon:GetIsCharging() and ( beacon.cd2_freakcount and beacon.cd2_freakcount < 15 or !beacon.cd2_freakcount ) and ( !beacon.cd2_nextfreakspawn or CurTime() > beacon.cd2_nextfreakspawn ) then
            beacon.cd2_freakcount = beacon.cd2_freakcount or 0 

            local freak = ents.Create( "cd2_freak" )
            freak:SetPos( CD2GetRandomPos( 700, beacon:GetPos() ) )
            local ang = ( beacon:GetPos() - freak:GetPos() ):Angle() ang[ 1 ] = 0 ang[ 3 ] = 0
            freak:SetAngles( ang )
            freak:Spawn()

            freak:AttackTarget( beacon )

            freak:CallOnRemove( "removeselffromcount", function()
                if IsValid( beacon ) then beacon.cd2_freakcount = beacon.cd2_freakcount - 1 end
            end )

            beacon.cd2_freakcount = beacon.cd2_freakcount + 1
            
            beacon.cd2_nextfreakspawn = CurTime() + 1
        end
    end
end )