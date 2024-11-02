local ceil = math.ceil


if SERVER then

    -- Gives XP to the player according to their skill level
    function CD2HandleSkillXP( ply, skillname, xp )
        if !IsValid( ply ) then return end
        local finalxp = xp
        local levelsetfunc = ply[ "Set" .. skillname .. "Skill" ] 
        local levelgetfunc = ply[ "Get" .. skillname .. "Skill" ] 
        local xpsetfunc = ply[ "Set" .. skillname .. "XP" ]
        local xpgetfunc = ply[ "Get" .. skillname .. "XP" ]

        if !levelgetfunc or !levelsetfunc then return end

        finalxp = finalxp / levelgetfunc( ply )

        if levelgetfunc( ply ) == 6 then return end

        xpsetfunc( ply, xpgetfunc( ply ) + finalxp )
        
        if ceil( xpgetfunc( ply )  ) >= 100 then
            levelsetfunc( ply, levelgetfunc( ply ) + 1 ) 
            xpsetfunc( ply, 0 )
            
            CD2:DebugMessage( ply:Name() .. " Leveled up their " .. skillname .. " skill to lvl " .. levelgetfunc( ply ) )

            hook.Run( "CD2_OnLevelUp", ply, skillname )

            CD2:CreateThread( function()

                while IsValid( ply ) and !ply:IsOnGround() do
                    coroutine.yield()
                end
                if !IsValid( ply ) then return end

                ply:StartLevelUpEffect()

                coroutine.wait( 1 )
                if !IsValid( ply ) then return end

                ply:BuildSkills()
            end )
        end
    end
end