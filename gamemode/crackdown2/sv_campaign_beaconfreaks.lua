
local difficultynpcs = {
    [ 1 ] = { "cd2_freak", "cd2_freak", "cd2_freak", "cd2_freak", "cd2_freakslinger" },
    [ 2 ] = { "cd2_freak", "cd2_freak", "cd2_freak", "cd2_freakslinger" },
    [ 3 ] = { "cd2_freak", "cd2_freak", "cd2_freak", "cd2_freakslinger" },
    [ 4 ] = { "cd2_freak", "cd2_freak", "cd2_freak", "cd2_freakslinger" },
}

local random = math.random
hook.Add( "Tick", "crackdown2_antibeaconfreaks", function()
    local beacons = ents.FindByClass( "cd2_beacon" )

    for i = 1, #beacons do
        local beacon = beacons[ i ]
        if IsValid( beacon ) and beacon:GetIsCharging() and ( beacon.cd2_freakcount and beacon.cd2_freakcount < 15 or !beacon.cd2_freakcount ) and ( !beacon.cd2_nextfreakspawn or CurTime() > beacon.cd2_nextfreakspawn ) then
            beacon.cd2_freakcount = beacon.cd2_freakcount or 0 
            local difficulty = CD2:GetBeaconDifficulty()
            local classes = difficultynpcs[ difficulty ]
            
            local freak = ents.Create( classes[ math.random( #classes ) ] )
            freak:SetPos( CD2:GetRandomPos( 700, beacon:GetPos() ) )
            local ang = ( beacon:GetPos() - freak:GetPos() ):Angle() ang[ 1 ] = 0 ang[ 3 ] = 0
            freak:SetAngles( ang )
            freak:Spawn()

            beacon:DeleteOnRemove( freak )

            if freak:GetClass() != "cd2_freak" then
                freak:AttackTarget( beacon )
            end

            freak:CallOnRemove( "removeselffromcount", function()
                if IsValid( beacon ) then beacon.cd2_freakcount = beacon.cd2_freakcount - 1 end
            end )

            if difficulty > 2 and random( 1, 100 ) < 5 and ( !beacon.cd2_goliathcooldown or CurTime() > beacon.cd2_goliathcooldown ) then
                local freak = ents.Create( "cd2_goliath" )
                freak:SetPos( CD2:GetRandomPos( 700, beacon:GetPos() ) )
                local ang = ( beacon:GetPos() - freak:GetPos() ):Angle() ang[ 1 ] = 0 ang[ 3 ] = 0
                freak:SetAngles( ang )
                freak:Spawn()

                beacon:DeleteOnRemove( freak )
    
                freak:AttackTarget( beacon )
    
                freak:CallOnRemove( "removeselffromcount", function()
                    if IsValid( beacon ) then beacon.cd2_freakcount = beacon.cd2_freakcount - 1 end
                end )
                beacon.cd2_freakcount = beacon.cd2_freakcount + 1
                beacon.cd2_goliathcooldown = CurTime() + 90 
            end

            beacon.cd2_freakcount = beacon.cd2_freakcount + 1
            
            beacon.cd2_nextfreakspawn = CurTime() + 1
        end
    end
end )