local bg = Material( "crackdown2/ui/textboxbg.png" )
local linecol = Color( 61, 61, 61, 100 )

CD2.uitextbox_queue = {}

-- Displays the information text box with the given text. Display ends after 5 seconds
function CD2:DispatchTextBox( text )
    self.uitextbox_queue[ #self.uitextbox_queue + 1 ] = text
end

function CD2:InitializeTextBox()
    if IsValid( self.uitextbox ) then self.uitextbox:Remove() end

    local sizex, sizey = 1000, 150
    local textdisplaytime = 0

    self.uitextbox = vgui.Create( "DPanel", GetHUDPanel() )
    self.uitextbox:SetSize( sizex, sizey )
    self.uitextbox:SetPos( ScrW() / 2 - sizex / 2, ScrH() - sizey - 40  )

    self.uitextbox.lbl = vgui.Create( "DLabel", self.uitextbox )
    self.uitextbox.lbl:SetFont( "crackdown2_font40" )
    self.uitextbox.lbl:SetText( "" )
    self.uitextbox.lbl:DockMargin( 10, 10, 10, 0 )
    self.uitextbox.lbl:Dock( FILL )
    self.uitextbox.lbl:SetWrap( true )
    self.uitextbox.lbl:SetContentAlignment( 7 )

    function self.uitextbox:Think()

        if #CD2.uitextbox_queue > 0 and !CD2.uitextbox.text then
            CD2.uitextbox_text = CD2.uitextbox_queue[ 1 ]
        end

        if CD2.uitextbox_text and CD2.uitextbox_text != self.lbl:GetText() then 
            self.lbl:SetText( CD2.uitextbox_text ) 
            textdisplaytime = SysTime() + 5
        end

        if textdisplaytime < SysTime() then
            table.remove( CD2.uitextbox_queue, 1 )

            if #CD2.uitextbox_queue == 0 then
                CD2.uitextbox_text = nil
                self.lbl:SetText( "" )
            else
                CD2.uitextbox_text = CD2.uitextbox_queue[ 1 ]
            end
        end
    end

    function self.uitextbox:Paint( w, h )
        if !CD2.uitextbox_text then return end
        surface.SetDrawColor( color_white )
        surface.SetMaterial( bg )
        surface.DrawTexturedRect( 0, 0, w, h )

        surface.SetDrawColor( linecol )
        surface.DrawOutlinedRect( 0, 0, w, h, 2 )
    end
end

CD2:InitializeTextBox()