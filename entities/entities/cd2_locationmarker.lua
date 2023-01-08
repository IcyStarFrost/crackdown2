AddCSLuaFile()

ENT.Base = "base_anim"

local IsValid = IsValid

function ENT:Initialize()

    self:DrawShadow( false )


    if CLIENT then

        self.cd2_color = Color( 0, 0, 0 )
        
        sound.PlayFile( "sound/crackdown2/ambient/tacticallocationambient.mp3", "3d mono noplay", function( snd, id, name )
            if id then return end

            self.cd2_ambient = snd
            snd:SetPos( self:GetPos() )
            snd:EnableLooping( true )

            snd:Play()

            hook.Add( "Think", self, function()
                if !IsValid( snd ) then hook.Remove( "Think", self ) return end
                snd:SetPos( self:GetPos() )
            end )
        
        end )

        local upper = string.upper
        local input_LookupBinding = CLIENT and input.LookupBinding
        local input_GetKeyCode = CLIENT and input.GetKeyCode
        local input_GetKeyName = CLIENT and input.GetKeyName
        hook.Add( "HUDPaint", self, function()
            local ply = LocalPlayer()
            local currentlocation = ply:GetNW2Entity( "cd2_targettacticlelocation", nil )

            if !IsValid( currentlocation ) then return end

            local usebind = input_LookupBinding( "+use" ) or "e"
            local code = input_GetKeyCode( usebind )
            local buttonname = input_GetKeyName( code )
            
            local screen = ( currentlocation:GetPos() + Vector( 0, 0, 30 ) ):ToScreen()
            CD2DrawInputbar( screen.x, screen.y, upper( buttonname ), "Test" )
        end )

    end

end


function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "IsActive" )
    self:NetworkVar( "String", 0, "LocationType" )
end

function ENT:OnRemove()
    if CLIENT and IsValid( self.cd2_ambient ) then self.cd2_ambient:Stop() end
end

function ENT:OnActivate()
end

function ENT:Think()

    if SERVER and !self:GetIsActive() then

        local nearplys = CD2FindInSphere( self:GetPos(), 150, function( ent ) return ent:IsCD2Agent() end )
        for i = 1, #nearplys do
            local ply = nearplys[ i ]
            if !IsValid( ply ) or !ply:IsCD2Agent() then continue end

            ply:SetNW2Entity( "cd2_targettacticlelocation", self )
            timer.Create( "cd2_unselecttacticlelocation" .. ply:EntIndex(), 0.5, 1, function() ply:SetNW2Entity( "cd2_targettacticlelocation", nil ) end )
            
            if ply:KeyPressed( IN_USE ) then
                self:OnActivate()
                --self:SetIsActive( true )
                --sound.Play( "crackdown2/ambient/tacticallocationactivate.mp3", self:GetPos(), 100, 100, 1 )
            end

        end
    end

    self:NextThink( CurTime() )
    return true
end

if CLIENT then
    local table_insert = table.insert
    local math_rad = math.rad
    local math_sin = math.sin
    local math_cos = math.cos
    local table_insert = table.insert
    local surface_DrawPoly = surface.DrawPoly
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_DrawTexturedRect = surface.DrawTexturedRect
    local render_SetMaterial = render.SetMaterial
    local draw_NoTexture = draw.NoTexture
    local surface_SetMaterial = surface.SetMaterial
    local clamp = math.Clamp
    local sin = math.sin
    local SysTime = SysTime
    local abs = math.abs
    local max = math.max
    local cellcolor = Color( 255, 60, 0, 150 )
    local cell = Material( "crackdown2/ui/cell.png", "smooth" )
    local peacekeeper = Material( "crackdown2/ui/peacekeeper.png", "smooth" )
    local default = Color( 0, 153, 255, 150 )
    local tacticallocationmat = Material( "crackdown2/other/location.png" )



    local function draw_Circle( x, y, radius, seg )
        local cir = {}

        table_insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
        for i = 0, seg do
            local a = math_rad( ( i / seg ) * -360 )
            table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )
        end

        local a = math_rad( 0 ) -- This is needed for non absolute segment counts
        table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )

        surface_DrawPoly( cir )
    end

    function ENT:Draw()

        cam.Start3D2D( self:GetPos() + Vector( 0, 0, 5), Angle( 0, 0, 0 ), 1 )
            local col = self:GetLocationType() == "cell" and cellcolor or default

            if self:GetIsActive() then
                self.cd2_color.r = max( abs( sin( SysTime() )  ) * 255, col.r )
                self.cd2_color.g = max( abs( sin( SysTime() )  ) * 255, col.g )
                self.cd2_color.b = max( abs( sin( SysTime() )  ) * 255, col.b )
                self.cd2_color.a = col.a
            else
                self.cd2_color.r = col.r
                self.cd2_color.g = col.g
                self.cd2_color.b = col.b
                self.cd2_color.a = col.a
            end

            surface_SetDrawColor( self.cd2_color )
            surface_SetMaterial( tacticallocationmat )
            draw_Circle( 0, 0, 150, 6 )

            if self:GetLocationType() == "cell" then
                surface_SetDrawColor( cellcolor )
                surface_SetMaterial( cell )
                local size = 200
                surface_DrawTexturedRect( -size / 2, -size / 2, size, size)
            elseif self:GetLocationType() == "agency" then
                surface_SetDrawColor( default )
                surface_SetMaterial( peacekeeper )
                local size = 200
                surface_DrawTexturedRect( -size / 2, -size / 2, size, size)
            end
        cam.End3D2D()
    
    end


end

