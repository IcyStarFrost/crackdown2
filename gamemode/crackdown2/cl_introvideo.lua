local medialib = include( "crackdown2/gamemode/medialib.lua" )
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local black = Color( 0, 0, 0 )


-- Begins the intro video
function CD2BeginIntroVideo( endcallback )
    local link = "https://www.youtube.com/watch?v=_i_QKKEF1RM"
    local service = medialib.load( "media" ).guessService( link )
    local mediaclip = service:load( link )

    CD2_videopanel = vgui.Create( "DPanel", GetHUDPanel() )
    CD2_videopanel:Dock( FILL )
    CD2_videopanel.clip = mediaclip

    mediaclip:play()

    local delay = SysTime() + 6 -- Delay for six seconds so the player doesn't see the youtube ui
    function CD2_videopanel:Think() if !mediaclip:isPlaying() and SysTime() > delay then if endcallback then endcallback() end self:Remove() end end
    function CD2_videopanel:OnRemove() if mediaclip:isValid() then mediaclip:stop() end end
    function CD2_videopanel:Paint( w, h ) if SysTime() < delay then surface_SetDrawColor( black ) surface_DrawRect( 0, 0, w, h ) return end mediaclip:draw(0, 0, w, h) end
    return mediaclip
end