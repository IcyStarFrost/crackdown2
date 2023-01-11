AddCSLuaFile()

ENT.Base = "base_anim"
local random = math.random
local IsValid = IsValid
local table_HasValue = table.HasValue
local table_RemoveByValue = table.RemoveByValue
local tracetable = {}
local Trace = util.TraceLine
local player_GetAll = player.GetAll

function ENT:Initialize()

    self:DrawShadow( false )

    if SERVER then
        self.cd2_cellcount = 2 + ( 2 * self:GetDifficulty() )
        self.cd2_maxkillcount = 9 + ( 3 * self:GetDifficulty() )
        self.cd2_killcount = 0
        self.cd2_activecell = {}

        self.cd2_maxpassivenpccount = 3
        self.cd2_passivenpcs = {}
        self.cd2_nextpassivespawn = CurTime() + 2

        hook.Add( "OnCD2NPCKilled", self, function( self, ent, info )
            if !IsValid( self ) then hook.Remove( "OnCD2NPCKilled", self) return end
            if table_HasValue( self.cd2_activecell, ent ) then self.cd2_killcount = self.cd2_killcount + 1 end
        end )
    end


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

            if !IsValid( currentlocation ) or currentlocation != self then return end

            local usebind = input_LookupBinding( "+use" ) or "e"
            local code = input_GetKeyCode( usebind )
            local buttonname = input_GetKeyName( code )
            
            local screen = ( currentlocation:GetPos() + Vector( 0, 0, 30 ) ):ToScreen()
            CD2DrawInputbar( screen.x, screen.y, upper( buttonname ), self:GetLocationType() == "agency" and "Call Helicopter" or self:GetLocationType() == "cell" and "Begin Assault on this Tactical Location" )
        end )

    end

end


function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "IsActive" )
    self:NetworkVar( "Bool", 1, "IsBeginningLocation" )

    self:NetworkVar( "String", 0, "LocationType" )
    self:NetworkVar( "String", 1, "Text" )

    self:NetworkVar( "Int", 0, "Difficulty" )
end

function ENT:OnRemove()
    if CLIENT and IsValid( self.cd2_ambient ) then self.cd2_ambient:Stop() end
end

local difficultynpcs = {
    [ 1 ] = { "cd2_smgcellsoldier", "cd2_shotguncellsoldier" }
}

function ENT:OnActivate( ply )

    if self:GetLocationType() == "cell" and SERVER then

        CD2SetTypingText( nil, "TACTICAL ASSAULT INITIATED", "" )

        if !KeysToTheCity() and random( 1, 2 ) == 1 then
            ply:PlayDirectorVoiceLine( "sound/crackdown2/vo/agencydirector/celldefend.mp3" )
        end

        local npclist = difficultynpcs[ self:GetDifficulty() ]

        self:SetIsActive( true )
        sound.Play( "crackdown2/ambient/tacticallocationactivate.mp3", self:GetPos(), 100, 100, 1 )

        local aborttime = CurTime() + 10
        local limitwarning = false
        CD2CreateThread( function()
            while IsValid( self ) do 
                if !IsValid( self ) or !self:GetIsActive() then return end
                local players = player_GetAll()

                local playernear = false
                for i = 1, #players do
                    local player = players[ i ]
                    if player:IsCD2Agent() and player:SqrRangeTo( self ) < ( 2000 * 2000 ) and player:Alive() then playernear = true break end
                end

                if playernear then aborttime = CurTime() + 10 limitwarning = false else if !limitwarning then CD2SendTextBoxMessage( nil, "Return to the Tactical Location!" ) limitwarning = true end end

                if CurTime() > aborttime then
                    self:SetIsActive( false )
                    self.cd2_killcount = 0
                    CD2SetTypingText( nil, "Tactical Assault Aborted", "", true )
                    return
                end

                coroutine.wait( 1 )
            end
        end )

        CD2CreateThread( function()

            while IsValid( self ) and self.cd2_killcount < self.cd2_maxkillcount do
                if !IsValid( self ) or !self:GetIsActive() then return end
                
                if #self.cd2_activecell < self.cd2_cellcount then
                    local cell = ents.Create( npclist[ random( #npclist ) ] )
                    cell:SetPos( CD2GetRandomPos( 2000, self:GetPos() )  )
                    cell:Spawn()
                    cell:CallOnRemove( "removefromactive", function() table_RemoveByValue( self.cd2_activecell, cell ) end )
                    
                    cell:AttackTarget( ply )
                    self.cd2_activecell[ #self.cd2_activecell + 1 ] = cell
                end

                coroutine.wait( 1 )
            end

            if !IsValid( self ) then return end

            hook.Run( "CD2_OnTacticalLocationCaptured", self )
            self:SetLocationType( "agency" )
            self:SetIsActive( false )

            tracetable.start = self:GetPos()
            tracetable.endpos = self:GetPos() + Vector( 0, 0, 6000 )
            tracetable.mask = MASK_SOLID_BRUSHONLY
            tracetable.collisiongroup = COLLISION_GROUP_WORLD
    
            local result = Trace( tracetable )
    
            if result.HitPos:Distance( self:GetPos() ) > 400 then
                local copter = ents.Create( "cd2_agencyhelicopter" )
                copter:SetPos( result.HitPos ) 
                copter:Spawn()
                copter:DropPeaceKeepers( self:GetPos() + Vector( 0, 0, 200 ) )
            end

            net.Start( "cd2net_locationcaptured" )
            net.Broadcast()

            local agencycount = 0 
            local locations = ents.FindByClass( "cd2_locationmarker" )
            for i = 1, #locations do
                local location = locations[ i ]
                if location:GetLocationType() == "agency" then agencycount = agencycount + 1 end
            end

            CD2SetTypingText( nil, "OBJECTIVE COMPLETE!", "Cell Tactical Location\nCaptured " .. agencycount .. " of " .. #locations .. " Tactical Locations" )

        end )
    elseif self:GetLocationType() == "agency" then
        net.Start( "cd2net_opendropmenu" )
        net.WriteBool( true )
        net.Send( ply )
    end

end

function ENT:VisCheck()
    local players = player_GetAll()
    local withinPVS = false
    for i = 1, #players do
        local ply = players[ i ]
        if ply:IsCD2Agent() and self:GetPos():DistToSqr( ply:GetPos() ) < ( 3000 * 3000 ) then withinPVS = true end
    end
    return withinPVS
end

function ENT:Think()
    if CLIENT then return end

    if !CD2_EmptyStreets and !self:GetIsActive() and CurTime() > self.cd2_nextpassivespawn and #self.cd2_passivenpcs < self.cd2_maxpassivenpccount and self:VisCheck() then
        
        if self:GetLocationType() == "cell" then
            local npclist = difficultynpcs[ self:GetDifficulty() ]

            local cell = ents.Create( npclist[ random( #npclist ) ] )
            cell:SetPos( CD2GetRandomPos( 2000, self:GetPos() )  )
            cell:Spawn()
            cell:CallOnRemove( "removefrompassive", function() table_RemoveByValue( self.cd2_passivenpcs, cell ) end )
            self.cd2_passivenpcs[ #self.cd2_passivenpcs + 1 ] = cell
        elseif self:GetLocationType() == "agency" then
            local peacekeeper = ents.Create( "cd2_peacekeeper" )
            peacekeeper:SetPos( CD2GetRandomPos( 2000, self:GetPos() )  )
            peacekeeper:Spawn()
            peacekeeper:CallOnRemove( "removefrompassive", function() table_RemoveByValue( self.cd2_passivenpcs, peacekeeper ) end )
            self.cd2_passivenpcs[ #self.cd2_passivenpcs + 1 ] = peacekeeper
        end
        
        
        self.cd2_nextpassivespawn = CurTime() + 2
    end

    if !self:GetIsActive() then

        local players = player_GetAll()
        for i = 1, #players do
            local ply = players[ i ]
            if !IsValid( ply ) or !ply:IsCD2Agent() or ply:GetPos():DistToSqr( self:GetPos() ) > ( 150 * 150 ) then continue end

            ply:SetNW2Entity( "cd2_targettacticlelocation", self )
            timer.Create( "cd2_unselecttacticlelocation" .. ply:EntIndex(), 0.6, 1, function() ply:SetNW2Entity( "cd2_targettacticlelocation", nil ) end )
            
            if ply:KeyPressed( IN_USE ) then
                self:OnActivate( ply )
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
    local whitetexture = Material( "vgui/white" )
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
        local isplayerfar = self:GetPos():DistToSqr( LocalPlayer():GetPos() ) >= ( 3000 * 3000 )

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
            surface_SetMaterial( isplayerfar and whitetexture or tacticallocationmat )
            draw_Circle( 0, 0, 150, 6 )

            if !isplayerfar then

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

            end
        cam.End3D2D()
    
    end


end

