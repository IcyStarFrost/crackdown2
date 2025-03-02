AddCSLuaFile()

ENT.Base = "base_anim"

local IsValid = IsValid
local sin = math.sin 
local cos = math.cos

function ENT:Initialize()

    if CLIENT then
        if LocalPlayer() != self:GetPlayer() then return end
        local currentviewpos = CD2.vieworigin * 1
        local currentviewangles = CD2.viewangles * 1

        CD2.DrawAgilitySkill = false
        CD2.DrawFirearmSkill = false
        CD2.DrawStrengthSkill = false
        CD2.DrawExplosiveSkill = false

        CD2:ToggleHUDComponent( "Crosshair", false )
        CD2.DrawHealthandShields = false
        CD2.DrawWeaponInfo = false
        CD2.DrawMinimap = false
        CD2.DrawBlackbars = true

        local viewtbl = {}
        CD2.ViewOverride = function( ply, origin, angles, fov, znear, zfar )
            if !IsValid( self ) then CD2.ViewOverride = nil return end

            if !self.cd2_showbeginningtacticallocation then
                currentviewpos = LerpVector( 1 * FrameTime(), currentviewpos, self:Trace( self:GetPos() + Vector( 0, 0, 5 ), self:GetPos() + Vector( 0, 0, 1000 ) ).HitPos - Vector( 0, 0, 10 ) )
                currentviewangles = LerpAngle( 0.3 * FrameTime(), currentviewangles, self:GetAngles() )

                viewtbl.origin = currentviewpos
                viewtbl.angles = currentviewangles
                viewtbl.fov = 60
                viewtbl.znear = znear
                viewtbl.zfar = zfar
                viewtbl.drawviewer = true

                return viewtbl
            else
                currentviewpos = LerpVector( 0.5 * FrameTime(), currentviewpos, GetGlobal2Vector( "cd2_beginnerlocation", nil ) + Vector( sin( SysTime() / 5 ) * 4000, cos( SysTime() / 5 ) * 4000, 1000 ) )
                currentviewangles = LerpAngle( 1 * FrameTime(), currentviewangles, ( GetGlobal2Vector( "cd2_beginnerlocation", nil ) - currentviewpos ):Angle() )

                viewtbl.origin = currentviewpos
                viewtbl.angles = currentviewangles
                viewtbl.fov = 60
                viewtbl.znear = znear
                viewtbl.zfar = zfar
                viewtbl.drawviewer = true

                return viewtbl
            end
        end

        local function DrawCredit( toptext, bottomtext )
            local object = {}
            local drawing = true
            local showtext = CurTime() + 3
            local topcolor = Color( 255, 115, 0, 0 )
            local bottomcolor = Color( 255, 255, 255, 0 )
            
            function object:IsValid() return drawing end

            hook.Add( "HUDPaint", self, function()
                if CurTime() < showtext then
                    topcolor.a = Lerp( 3 * FrameTime(), topcolor.a, 255 )
                    bottomcolor.a = Lerp( 3 * FrameTime(), bottomcolor.a, 255 )
                else
                    topcolor.a = Lerp( 3 * FrameTime(), topcolor.a, 0 )
                    bottomcolor.a = Lerp( 3 * FrameTime(), bottomcolor.a, 0 )
                    if topcolor.a < 10 and bottomcolor.a < 10 then
                        drawing = false
                        hook.Remove( "HUDPaint", self )
                    end
                end

                draw.DrawText( toptext, "crackdown2_font50", 200, ScrH() / 2, topcolor, TEXT_ALIGN_LEFT )
                draw.DrawText( bottomtext, "crackdown2_font50", 200, ScrH() / 2 + 60, bottomcolor, TEXT_ALIGN_LEFT )
            end )

            return object
        end

        CD2:CreateThread( function()
            coroutine.wait( 90 )
            self.cd2_showbeginningtacticallocation = true
        end )

        CD2:CreateThread( function()

            local credit = DrawCredit( "CRACKDOWN 2", "Garry's Mod Gamemode Recreation by StarFrost" )
            while credit:IsValid() do coroutine.yield() end



            credit = DrawCredit( "Original Game Developer:", "Ruffian Games" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "CRACKDOWN Series Founder:", "David Jones of Realtime Worlds" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Creative Director:", "Billy Thomson" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Producor:", "James Cope" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Leads:", "Stuart Campbell\nIain Donald\nMike Enoch\nChris Gottgetreu" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Leads:", "Steve Iannetta\nRoss Nicoll\nNeil Pollock\nPaul Simms" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Design:", "Ed Campbell\nMartin Livingston\nSean Noonan" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Design:", "Dean Smith\nGraham Wright" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Code:", "Leigh Bird\nBarry Cairns\nRobert Cowsill\nTerryDrever" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Code:", "Neil Duffield\nKarim El-Shakankiri\nDuncan Harrison\nAndrew Heywood" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Code:", "David Hynd\nJohn Hynd\nS L\nPeter Mackay" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Code:", "Will Sykes\nCraig Thomson\nRichard Welsh" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Art:", "Ryan Astley\nKevin Dunlop\nCarlos Garcia\nPaul Large" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Art:", "Stewart Neal\nNeil Macnaughton\nPaulie Simms\nRichard Wazejewski" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original QA:", "Kevin Black\nSean Branney\nAmy Buttress\nGregor Hare" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original QA:", "David Hoare\nSimon Kilroy\nEwan Mckenzie\nJohn Pettie" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Studio:", "Steven Randell\nKirsty Scott\nGavin Howie" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Development Director:", "Gareth Noyce" )
            while credit:IsValid() do coroutine.yield() end

            credit = DrawCredit( "Original Studio Head:", "Gaz Liddon" )
            while credit:IsValid() do coroutine.yield() end


        end )

    end

    if SERVER then
        CD2:CreateThread( function()

            while IsValid( self ) do

                if IsValid( self.Path ) then
                    if !IsValid( self ) then return end
                    local vecs = {}
                    local segments = self.Path:GetAllSegments()
                    for i = 1, #segments do if !IsValid( self ) then return end vecs[ #vecs + 1 ] = segments[ i ].pos end
        
                    for i = 1, #vecs do
                        if !IsValid( self ) then return end
                        local vector = vecs[ i ]
        
                        while IsValid( self ) and self:GetPos():DistToSqr( vector ) > ( 20 * 20 ) do
                            local ang = ( vector - self:GetPos() ):Angle() ang[ 1 ] = ang[ 1 ] + 20 ang[ 3 ] = 0
                            self:SetAngles( ang )
                            self:SetPos( self:GetPos() + ( vector - self:GetPos() ):GetNormalized() * 10 )
                            coroutine.yield()
                        end
        
                        coroutine.yield()
                    end

                    if IsValid( self.Path ) then self.Path:Invalidate() end
                end

                coroutine.yield()
            end

        end )

    end

end


function ENT:OnRemove()
    if CLIENT and LocalPlayer() == self:GetPlayer() then
        CD2.DrawAgilitySkill = true
        CD2.DrawFirearmSkill = true
        CD2.DrawStrengthSkill = true
        CD2.DrawExplosiveSkill = true

        CD2:ToggleHUDComponent( "Crosshair", true )
        CD2.DrawHealthandShields = true
        CD2.DrawWeaponInfo = true
        CD2.DrawMinimap = true
        CD2.DrawBlackbars = false
    end
end


function ENT:Draw() end

local Trace = util.TraceLine
local normaltrace = {}
function ENT:Trace( start, endpos )
    normaltrace.start = start
    normaltrace.endpos = endpos
    normaltrace.filter = self
    normaltrace.mask = MASK_SOLID_BRUSHONLY
    normaltrace.collisiongroup = COLLISION_GROUP_WEAPON
    local result = Trace( normaltrace )
    return result
end

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Player" )
end
