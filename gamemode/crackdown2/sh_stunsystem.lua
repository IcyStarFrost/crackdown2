local players_GetAll = player.GetAll
local Trace = util.TraceLine
local viewtrace = {}
local IsValid = IsValid
local zerovec = Vector()
local calctable = {}
local shouldoverride = true
local LerpVector = LerpVector
local Lerp = Lerp
local FrameTime = FrameTime


-- Because gmod's CreateRagdoll function for players actually sucks.
-- Getting the position of the ragdoll was unreliable and gave only the position the ragdoll was spawned. So here's this function
function CD2CreateRagdoll( ply )
    local ragdoll = ents.Create( "prop_ragdoll" )
    ragdoll:SetModel( ply:GetModel() )
    ragdoll:SetPos( ply:GetPos() )
    ragdoll:SetOwner( ply )
    ragdoll:AddEffects( EF_BONEMERGE ) -- Pretty much sets up the bones for us
    ragdoll:SetParent( ply )
    ragdoll:Spawn()
    ply:SetRagdoll( ragdoll )

    ragdoll:SetParent()
    ragdoll:RemoveEffects( EF_BONEMERGE )

    for i = 0, ply:GetBoneCount() - 1 do
        local phys = ragdoll:GetPhysicsObjectNum( ragdoll:TranslateBoneToPhysBone( i ) )
        if IsValid( phys ) then phys:SetVelocity( ply:GetVelocity() ) end
    end

end

-- The stun system. When the player is hurt with a certain amount of explosive damage, they will be stunned and ragdolled for 3 seconds before getting back up
hook.Add( "Tick", "crackdown2_stunsystem", function()

    if SERVER then
        local players = players_GetAll()
        
        for i = 1, #players do
            local ply = players[ i ]

            if !IsValid( ply ) or !ply:IsCD2Agent() then continue end

            if ply:GetIsStunned() and ply:Alive() then -- If the player is currently stunned and alive

                if !IsValid( ply:GetRagdoll() ) then
                    CD2CreateRagdoll( ply )
                    ply:SetNoDraw( true )
                    continue
                end

                ply:SetPos( ply:GetRagdoll():GetPos() )
                ply:SetAngles( Angle( 0, ply:GetRagdoll():GetAngles()[ 2 ], 0 ) )
                ply:SetVelocity( -ply:GetVelocity() )
                ply:Freeze( true ) -- Prevent any inputs

                -- Time is up
                if ply.cd2_stunendtime and CurTime() > ply.cd2_stunendtime then
                    ply:SetIsStunned( false )

                    -- Entity responsible for the rising animation. This is dumb but gmod forced us
                    local riseent = ents.Create( "cd2_riseent" )
                    riseent:SetPos( ply:GetPos() )
                    riseent:SetAngles( Angle( 0, ply:EyeAngles()[ 2 ], 0 ) )
                    riseent:SetParent( ply )
                    riseent:SetPlayer( ply )
                    riseent:Spawn()
                    riseent.Callback = function( self )
                        ply:SetNoDraw( false )
                        ply:Freeze( false )
                    end
                end

            elseif ( !ply:GetIsStunned() or !ply:Alive() ) and IsValid( ply:GetRagdoll() ) then
                ply:GetRagdoll():Remove()
                ply:SetIsStunned( false )
            else
                ply.cd2_stunendtime = CurTime() + 2
            end

            if ply:GetIsStunned() and !ply:Alive() then
                ply:SetIsStunned( false )
            end
            
        end

    elseif CLIENT then 


        -- Override the view so it follows the ragdoll
        local ply = LocalPlayer()
        if !ply:IsCD2Agent() or !IsValid( ply ) then return end
        local ragdoll = ply:GetRagdoll()

        if IsValid( ragdoll ) and ply:Alive() and ply:GetIsStunned() and shouldoverride then
            lastpos = ragdoll:GetPos()

            CD2_ViewOverride = function( ply2, origin, angles, fov, znear, zfar )
                if !IsValid( ragdoll ) or CD2_InSpawnPointMenu then return end

                viewtrace.start = ( ragdoll:GetPos() + Vector( 0, 0, 18 ) )
                viewtrace.endpos = ( ( ragdoll:GetPos() + Vector( 0, 0, 18 ) ) - CD2_viewangles:Forward() * 130 )
                viewtrace.filter = { ply, ragdoll }
                local result = Trace( viewtrace )
                local pos = result.HitPos - result.Normal * 8

                CD2_lockonoffset = LerpVector( 20 * FrameTime(), CD2_lockonoffset, zerovec )
                CD2_fieldofview = Lerp( 20 * FrameTime(), CD2_fieldofview, fov )


                CD2_vieworigin = pos
                calctable.origin = pos
                calctable.angles = CD2_viewangles
                calctable.fov = CD2_fieldofview
                calctable.znear = znear
                calctable.zfar = zfar

                return calctable
            end

            shouldoverride = false
        elseif ( !ply:GetIsStunned() or !ply:Alive() ) and !shouldoverride then 
            CD2_ViewOverride = nil
            shouldoverride = true
        end


    end

end )


