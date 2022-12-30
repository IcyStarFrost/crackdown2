local medialib = include( "crackdown2/gamemode/medialib.lua" )
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local black = Color( 0, 0, 0 )
local input_LookupBinding = input.LookupBinding
local input_GetKeyCode = input.GetKeyCode
local input_GetKeyName = input.GetKeyName
local draw_DrawText = draw.DrawText
local IsValid = IsValid

-- Begins the intro video
function CD2BeginIntroVideo( endcallback )
    local link = "https://www.youtube.com/watch?v=_i_QKKEF1RM"
    local service = medialib.load( "media" ).guessService( link )
    local mediaclip = service:load( link )

    CD2_videopanel = vgui.Create( "DPanel", GetHUDPanel() )
    CD2_videopanel:Dock( FILL )
    CD2_videopanel.clip = mediaclip

    mediaclip:play()

    hook.Add( "KeyPress", "crackdown2_skipintro", function( ply, key )
        if !IsValid( CD2_videopanel ) then hook.Remove( "KeyPress", "crackdown2_skipintro" ) return end
        if key == IN_USE and mediaclip:isValid() then
            CD2_videopanel:Remove()
        end
    end ) 

    local delay = SysTime() + 6 -- Delay for six seconds so the player doesn't see the youtube ui
    local endskiptime = SysTime() + 14
    function CD2_videopanel:Think() if !mediaclip:isPlaying() and SysTime() > delay then if endcallback then endcallback() end hook.Remove( "KeyPress", "crackdown2_skipintro" ) self:Remove() end end
    function CD2_videopanel:OnRemove() if mediaclip:isValid() then mediaclip:stop() end end

    function CD2_videopanel:Paint( w, h ) 
        if SysTime() < delay then 
            surface_SetDrawColor( black ) 
            surface_DrawRect( 0, 0, w, h ) 
            endskiptime = SysTime() + 4
        else
            mediaclip:draw( 0, 0, w, h )  
        end 

        if SysTime() < endskiptime and SysTime() > delay then
            local usebind = input_LookupBinding( "+use" ) or "e"
            local code = input_GetKeyCode( usebind )
            local buttonname = input_GetKeyName( code )

            draw_DrawText( "Press " .. buttonname .. " to skip first time playing intro", "crackdown2_equipmentcount", 50, h - 70, color_white, TEXT_ALIGN_LEFT )
        end
    end

    return mediaclip
end