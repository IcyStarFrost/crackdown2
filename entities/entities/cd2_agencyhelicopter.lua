AddCSLuaFile()

ENT.Base = "base_anim"
ENT.AutomaticFrameAdvance = true

local random = math.random
local Trace = util.TraceLine
local tracetable = {}

if SERVER then
    util.AddNetworkString( "cd2net_heli_playsound" )
end

function ENT:Initialize()
    self:SetModel( "models/combine_helicopter.mdl" )

    timer.Simple( 0, function()
        self:ResetSequence( 0 )
    end )

    self:EmitSound( "^npc/attack_helicopter/aheli_rotor_loop1.wav", 120, 100, 1, CHAN_AUTO )

    self.cd2_angles = self:GetAngles()

end

function ENT:OnRemove()
    self:StopSound( "^npc/attack_helicopter/aheli_rotor_loop1.wav" )
end

-- Makes the helicopter drop peacekeepers
function ENT:DropPeaceKeepers( pos )

    CD2CreateThread( function()

        while true do 
            if !IsValid( self ) then return end

            local posxy = pos * 1
            posxy[ 3 ] = 0

            while true do
                local selfxypos = self:GetPos() selfxypos[ 3 ] = 0
                if selfxypos:DistToSqr( posxy ) < ( 50 * 50 ) then break end
                local pos2 = ( posxy * 1 ) pos[ 3 ] = self:GetPos()[ 3 ]
                self:SetPos( self:GetPos() + ( pos2 - self:GetPos() ):GetNormalized() * 10 )
                coroutine.yield()
            end

            coroutine.wait( 1 )
        
            while true do
                if self:GetPos():DistToSqr( pos ) < ( 50 * 50 ) then break end
                self:SetPos( self:GetPos() + ( pos - self:GetPos() ):GetNormalized() * 5 )

                coroutine.yield()
            end

            
            coroutine.wait( 2 )

            self:DeployPeacekeepers()

            coroutine.wait( 2 )

            while true do
        
                if self:GetPos():DistToSqr( self.cd2_leavepos ) > ( 50 * 50 ) then
                    self:SetPos( self:GetPos() + ( self.cd2_leavepos - self:GetPos() ):GetNormalized() *10 )
                else
                    self:Remove()
                    break
                end
        
                coroutine.yield()
            end

            coroutine.yield()
        end
    end )

end


function ENT:DeployPeacekeepers()

    tracetable.start = self:GetPos()
    tracetable.endpos = self:GetPos() + Vector( 0, 0, 7000 )
    tracetable.mask = MASK_SOLID_BRUSHONLY
    tracetable.collisiongroup = COLLISION_GROUP_WORLD

    local result = Trace( tracetable )
    self.cd2_leavepos = result.HitPos - Vector( 0, 0, 100 )

    for i = 1, 4 do
        if CD2_EmptyStreets then return end
        local peacekeeper = ents.Create( "cd2_droppeacekeeper" )
        peacekeeper:SetPos( self:GetPos() + ( self:GetForward() * ( 50 * i ) ) + self:GetRight() * 50 ) 
        peacekeeper:Spawn()

        CD2CreateThread( function()

            peacekeeper:EmitSound( "crackdown2/npc/peacekeeper/drop" .. random( 1, 2 ) .. ".wav", 70 )

            while IsValid( peacekeeper ) and !peacekeeper:IsOnGround() do coroutine.yield() end 
            if !IsValid( peacekeeper ) then return end
            
            peacekeeper:EmitSound( "crackdown2/npc/peacekeeper/hitground" .. random( 1, 2 ) .. ".wav", 70 )
        end )
    end
end

-- Makes the helicopter go over a entity and picks it up then later deleting itself and the object
function ENT:ExtractEntity( ent )
    self:SetCargo( ent )

    if IsValid( self:GetCargo() ) then
        self.cd2_pickuppos = self:GetCargo():GetPos() + Vector( 0, 0, self:GetCargo():OBBMaxs().z + 5 )
        self.cd2_cargoxypos = self:GetCargo():GetPos() self.cd2_cargoxypos[ 3 ] = 0
    end

    CD2CreateThread( function()

        while true do 
            if !IsValid( self ) then return end

            if IsValid( self:GetCargo() ) then
                
                while true do
                    local selfxypos = self:GetPos() selfxypos[ 3 ] = 0
                    if selfxypos:DistToSqr( self.cd2_cargoxypos ) < ( 50 * 50 ) then break end
                    local pos = ( self.cd2_cargoxypos * 1 ) pos[ 3 ] = self:GetPos()[ 3 ]
                    self:SetPos( self:GetPos() + ( pos - self:GetPos() ):GetNormalized() * 10 )
                    coroutine.yield()
                end

                coroutine.wait( 1 )
        
                while true do
                    if self:GetPos():DistToSqr( self.cd2_pickuppos ) < ( 50 * 50 ) then break end
                    self:SetPos( self:GetPos() + ( self.cd2_pickuppos - self:GetPos() ):GetNormalized() * 5 )

                    coroutine.yield()
                end
                
                coroutine.wait( 2 )

                self:PickupCargo()

                while true do
        
                    if self:GetPos():DistToSqr( self.cd2_leavepos ) > ( 50 * 50 ) then
                        self:SetPos( self:GetPos() + ( self.cd2_leavepos - self:GetPos() ):GetNormalized() *10 )
                    else
                        self:Remove()
                        break
                    end
        
                    coroutine.yield()
                end
        
        
            end
    

            coroutine.yield()
        end

    end )
end

function ENT:PickupCargo()

    tracetable.start = self:GetPos()
    tracetable.endpos = self:GetPos() + Vector( 0, 0, 7000 )
    tracetable.mask = MASK_SOLID_BRUSHONLY
    tracetable.collisiongroup = COLLISION_GROUP_WORLD

    local result = Trace( tracetable )

    net.Start( "cd2net_heli_playsound" )
    net.WriteString( "sound/crackdown2/ambient/helipickup.mp3" )
    net.WriteVector( self:GetPos() )
    net.Broadcast()

    self.cd2_leavepos = result.HitPos - Vector( 0, 0, 100 )
    self:SetHasCargo( true )
    self:GetCargo():SetParent( self )
end

if CLIENT then
    net.Receive( "cd2net_heli_playsound", function() 
        local path = net.ReadString()
        local pos = net.ReadVector()
        sound.PlayFile( path, "3d mono noplay", function( snd, id, name ) 
            if id then return end
            snd:SetVolume( 5 )
            snd:SetPos( pos )
            snd:Play()
        end )
    end )
end

function ENT:Think()

    if self.cd2_lastpos and self.cd2_lastpos != self:GetPos() then
        self.cd2_newangles = ( self:GetPos() - self.cd2_lastpos ):Angle()
    end

    if self.cd2_newangles then
        self.cd2_angles = LerpAngle( 2 * FrameTime(), self.cd2_angles, self.cd2_newangles )
        self.cd2_angles[ 1 ] = 0 
        self.cd2_angles[ 3 ] = 0 
        self:SetAngles( self.cd2_angles )
    end

    self.cd2_lastpos = self:GetPos()

    self:NextThink( CurTime() )
    return true 
end

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Cargo" )

    self:NetworkVar( "Bool", 0, "HasCargo" )
end