AddCSLuaFile()

ENT.Base = "base_anim"

function ENT:Initialize()
    self:SetModel( "models/props_lab/citizenradio.mdl" )

    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

    if CLIENT then
        self.cd2_musictable = {}
        self.cd2_currentmusicindex = 1
        self.cd2_delay = 0

        local files = file.Find( "sound/crackdown2/music/radio/*", "GAME", "namedesc" )

        for k, v in ipairs( files ) do self.cd2_musictable[ #self.cd2_musictable + 1 ] = "sound/crackdown2/music/radio/" .. v end

        self.cd2_currentmusicindex = math.random( 1, #self.cd2_musictable )
    end

    local phys = self:GetPhysicsObject()
    if IsValid( phys ) then phys:SetMass( 1000 ) end 
end

function ENT:PlayNextTrack()
    if IsValid( self.cd2_music ) then self.cd2_music:Stop() end
    if self.cd2_currentmusicindex > #self.cd2_musictable then self.cd2_currentmusicindex = 1 end
    local track = self.cd2_musictable[ self.cd2_currentmusicindex ]

    sound.PlayFile( track, "3d mono noplay", function( chan, id, name )
        if id then return end
        if !IsValid( self ) then return end
        chan:SetPos( self:GetPos() )
        chan:Set3DFadeDistance( 1000, -1 )
        chan:Play()
        self.cd2_music = chan
    end )

    self.cd2_currentmusicindex = self.cd2_currentmusicindex + 1
end

function ENT:OnTakeDamage( info )
    net.Start( "cd2net_explosion" )
    net.WriteVector( self:GetPos() )
    net.WriteFloat( 0.4 )
    net.Broadcast()
    sound.Play( "ambient/levels/labs/electric_explosion1.wav", self:GetPos(), 70, 100, 1 )
    self:Remove()
end

function ENT:OnRemove()
    if CLIENT and IsValid( self.cd2_music ) then self.cd2_music:Stop() end
end

function ENT:Think()
    if SERVER then return end

    if IsValid( self.cd2_music ) then 
        self.cd2_music:SetPos( self:GetPos() )
    end

    if !IsValid( self.cd2_music ) or self.cd2_music:GetState() == GMOD_CHANNEL_STOPPED and SysTime() > self.cd2_delay then
        self:PlayNextTrack()
        self.cd2_delay = SysTime() + 1
    end
end