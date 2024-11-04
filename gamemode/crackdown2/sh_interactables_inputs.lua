
if SERVER then

    -- Int1 = Q
    -- Int2 = E
    -- Int3 = R

    local isphysics = {
        [ "prop_physics" ] = "Int1",
        [ "prop_physics_multiplayer" ] = "Int1",
        [ "prop_ragdoll" ] = "Int1",
        [ "func_physbox" ] = "Int1",
        [ "cd2_prop" ] = "Int1"
    }

    local function IsInteractable( ent, ply )
        if isphysics[ ent ] then return true end
        if ent.InteractTest then return ent:InteractTest( ply ) end
    end

    local refreshrate = 0
    hook.Add( "Tick", "crackdown2_nearestinteractables", function()
        if CurTime() < refreshrate then return end
        refreshrate = CurTime() + 0.2

        for k, ply in player.Iterator() do
            if ply:IsCD2Agent() then

                local closestents = ents.FindInSphere( ply:GetPos(), 500 )
                local interactiontest = {
                    [ "Int1" ] = {},
                    [ "Int2" ] = {},
                    [ "Int3" ] = {},
                    IsEmpty = true
                }

                for _, ent in ipairs( closestents ) do
                    local interacttest = IsInteractable( ent, ply )
                    if interacttest then

                        local interacttbl = interactiontest[ interacttest ]

                        local dist = ply:SqrRangeTo( ent )

                        if !interacttbl.closest then
                            interacttbl.closest = ent 
                            interacttbl.closestdistance = dist
                            interactiontest.IsEmpty = false
                        else
                            if dist < interacttbl.closestdistance then
                                interacttbl.closest = ent 
                                interacttbl.closestdistance = dist
                                interactiontest.IsEmpty = false
                            end
                        end
                    end
                end

                local condensedtbl = { 
                    [ "Int1" ] = IsValid( interactiontest.Int1.closest ) and interactiontest.Int1.closest:EntIndex() or nil,
                    [ "Int2" ] = IsValid( interactiontest.Int2.closest ) and interactiontest.Int2.closest:EntIndex() or nil,
                    [ "Int3" ] = IsValid( interactiontest.Int3.closest ) and interactiontest.Int3.closest:EntIndex() or nil,
                }

                local json = util.TableToJSON( condensedtbl )

                if json != ply:GetIntNearestInteractables() then 
                    ply:SetIntNearestInteractables( json )
                end
            end
        end
    end )


    hook.Add( "PlayerButtonDown", "crackdown2_buttondown", function( ply, button )
        if !ply:IsCD2Agent() then return end
        ply.ButtonData[ button ] = true
    end )

    hook.Add( "PlayerButtonUp", "crackdown2_buttonup", function( ply, button )
        if !ply:IsCD2Agent() then return end
        ply.ButtonData[ button ] = nil
    end )

end