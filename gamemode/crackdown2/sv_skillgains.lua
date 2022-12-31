local ceil = math.ceil


-- Gives XP to the player according to their skill level
function CD2HandleSkillXP( ply, skillname, xp )
    local finalxp = xp
    local levelsetfunc = ply[ "Set" .. skillname .. "Skill" ] 
    local levelgetfunc = ply[ "Get" .. skillname .. "Skill" ] 
    local xpsetfunc = ply[ "Set" .. skillname .. "XP" ]
    local xpgetfunc = ply[ "Get" .. skillname .. "XP" ]

    finalxp = finalxp / levelgetfunc( ply )

    if levelgetfunc( ply ) == 6 then return end

    xpsetfunc( ply, xpgetfunc( ply ) + finalxp )

    CD2FILESYSTEM:WritePlayerData( ply, "cd2_skillxp_" .. skillname, xpgetfunc( ply ) )

    if ceil( xpgetfunc( ply )  ) >= 100 then
        levelsetfunc( ply, levelgetfunc( ply ) + 1 ) 
        xpsetfunc( ply, 0 )

        CD2FILESYSTEM:WritePlayerData( ply, "cd2_skill_" .. skillname, levelgetfunc( ply ) )
        CD2FILESYSTEM:WritePlayerData( ply, "cd2_skillxp_" .. skillname, 0 )
        CD2CreateThread( function()

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