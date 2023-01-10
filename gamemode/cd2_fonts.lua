
-- All fonts have been relocated here so everytime I reload the lua files, the fonts are not being recreated over and over and later
-- begins to bloat memory or just crashes the game. 

CD2_LoadedFonts = CD2_LoadedFonts or false
if !CD2_LoadedFonts then
    surface.CreateFont( "crackdown2_weaponstattext", {
        font = "Agency FB",
        extended = false,
        size = math.ceil( ScreenScale( 6.5 ) ),
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,

    })

    surface.CreateFont( "crackdown2_agentnames", {
        font = "Agency FB",
        extended = false,
        size = 20,
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = true,
        additive = false,
        outline = false,

    })

    surface.CreateFont( "crackdown2_font60", {
        font = "Agency FB",
        extended = false,
        size = 60,
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,

    })

    surface.CreateFont( "crackdown2_font50", {
        font = "Agency FB",
        extended = false,
        size = 50,
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,

    })

    surface.CreateFont( "crackdown2_font45", {
        font = "Agency FB",
        extended = false,
        size = 45,
        weight = 1000,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,

    })

    surface.CreateFont( "crackdown2_font40", {
        font = "Agency FB",
        extended = false,
        size = 40,
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,

    })

    surface.CreateFont( "crackdown2_font30", {
        font = "Agency FB",
        extended = false,
        size = 30,
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,

    })
    CD2_LoadedFonts = true
end