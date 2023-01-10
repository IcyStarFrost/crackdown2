
surface.CreateFont( "crackdown2_typingtext", {
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

surface.CreateFont( "crackdown2_typingtext2", {
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

local id = 0
local white = Color( 255, 255, 255, 255 )
local topcolor = Color( 255, 255, 255, 255 )
function CD2SetTypingText( toptext, bottomtext, red )
    local toptexttbl = string.ToTable( toptext )
    local bottomtexttbl = string.ToTable( bottomtext )

    id = id + 1
    local thisid = id * 1

    topcolor.a = 255
    topcolor.r = 255
    topcolor.g = 255
    topcolor.b = 255
    white.a = 255
    
    CD2_TypingText_Red = red or false
    CD2_TypingText_FlashColor = false
    CD2_TypingText_Top = ""
    CD2_TypingText_Bottom = ""

    CD2CreateThread( function()
        for i = 1, #toptexttbl do
            if thisid != id then return end
            CD2_TypingText_Top = CD2_TypingText_Top .. toptexttbl[ i ]
            LocalPlayer():EmitSound( "crackdown2/ui/texttype.mp3", 70, 100, 1, CHAN_WEAPON )
            coroutine.wait( 0.1 )
        end

        for i = 1, #bottomtexttbl do
            if thisid != id then return end
            CD2_TypingText_Bottom = CD2_TypingText_Bottom .. bottomtexttbl[ i ]
            LocalPlayer():EmitSound( "crackdown2/ui/texttype.mp3", 70, 100, 1, CHAN_WEAPON )
            coroutine.wait( 0.1 )
        end

        CD2_TypingText_FlashColor = true

        coroutine.wait( 4 )

        CD2_TypingText_FlashColor = false
        
        while true do
            if thisid != id then return end
            if white.a < 10 then break end
            white.a = Lerp( 5 * FrameTime(), white.a, 0 )
            topcolor.a = white.a
            coroutine.yield()
        end

        CD2_TypingText_Top = nil
        CD2_TypingText_Bottom = nil
    end )

end

local bluecolor = Color( 0, 183, 255, 100 )
local redcolor = Color( 255, 0, 0, 100 )
local sprite = Material( "crackdown2/ui/sprite1.png" )
local abs = math.abs
local sin = math.sin
local cos = math.cos
local max = math.max
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local draw_DrawText = draw.DrawText

hook.Add( "HUDPaint", "crackdown2_typingtext", function()
    
    if CD2_TypingText_Top then

        if CD2_TypingText_FlashColor then
            bluecolor.a = abs( sin( SysTime() * 4 ) * 100 )
            redcolor.a = abs( sin( SysTime() * 4 ) * 100 )
            surface_SetFont( "crackdown2_typingtext" )
            local w, h = surface_GetTextSize( CD2_TypingText_Top )
            surface_SetDrawColor( !CD2_TypingText_Red and bluecolor or redcolor )
            surface_SetMaterial( sprite )
            surface_DrawTexturedRect( ( ScrW() / 2 ) - ( w / 2 ) - 50, ( ScrH() / 2.3 ), w + 100, h )
        end

        draw_DrawText( CD2_TypingText_Top, "crackdown2_typingtext", ScrW() / 2, ScrH() / 2.3, topcolor, TEXT_ALIGN_CENTER )
    end

    if CD2_TypingText_Bottom then
        draw_DrawText( CD2_TypingText_Bottom, "crackdown2_typingtext2", ScrW() / 2, ScrH() / 2, white, TEXT_ALIGN_CENTER )
    end
end )