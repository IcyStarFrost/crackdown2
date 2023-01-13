
if !CD2_Precachedplayermodels then

    local precachetable = {
        "models/humans/group01/male_01.mdl",
        "models/humans/group01/male_02.mdl",
        "models/humans/group01/male_03.mdl",
        "models/humans/group01/male_04.mdl",
        "models/humans/group01/male_05.mdl",
        "models/humans/group01/male_06.mdl",
        "models/humans/group01/male_07.mdl",
        "models/humans/group01/male_08.mdl",
        "models/humans/group01/male_09.mdl",

        "models/humans/group01/female_01.mdl",
        "models/humans/group01/female_02.mdl",
        "models/humans/group01/female_03.mdl",
        "models/humans/group01/female_04.mdl",
        "models/humans/group01/female_06.mdl",
        "models/humans/group01/female_07.mdl",

        "models/player/group03/male_01.mdl",
        "models/player/group03/male_02.mdl",
        "models/player/group03/male_03.mdl",
        "models/player/group03/male_04.mdl",
        "models/player/group03/male_05.mdl",
        "models/player/group03/male_06.mdl",
        "models/player/group03/male_07.mdl",
        "models/player/group03/male_08.mdl",
        "models/player/group03/male_09.mdl",

        "models/player/police.mdl",
        "models/player/combine_soldier.mdl",
        "models/player/combine_super_soldier.mdl",
        "models/player/zombie_classic.mdl"
    }

    for i = 1, #precachetable do
        util.PrecacheModel( precachetable[ i ] )
    end

    CD2_Precachedplayermodels = true 
end