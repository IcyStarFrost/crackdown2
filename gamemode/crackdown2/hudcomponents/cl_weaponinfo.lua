-- Draws weapon info
local linecol = Color( 61, 61, 61, 100 )
local blackish = Color( 39, 39, 39)
local red = Color( 163, 12, 12)

function CD2.HUDCOMPONENENTS.components.WeaponInfo( ply, scrw, scrh, hudscale )
    local weapon = ply:GetActiveWeapon()

    if IsValid( weapon ) then
        local mdl = weapon:GetWeaponWorldModel()

        surface.SetDrawColor( blackish )
        surface.DrawRect( scrw - 400, scrh - 130, 300, 30 )

        surface.SetDrawColor( blackish )
        surface.DrawRect( scrw - 100, scrh - 140, 70, 40 )

        surface.SetDrawColor( blackish )
        surface.DrawRect( scrw - 400, scrh - 100, 300, 60 )

        draw.DrawText( weapon.Ammo1 and weapon:Ammo1() or "NONE", "crackdown2_font40", scrw - 35, scrh - 140, color_white, TEXT_ALIGN_RIGHT )


        for i = 1, weapon:Clip1() do
            local wscale = 300 / weapon:GetMaxClip1()
            local x = ( scrw - 395 ) + ( wscale * ( i - 1 ) )
            if x >= scrw - 395 and x + wscale / 2 <= scrw - 100 then

                local col = ( weapon:Clip1() / weapon:GetMaxClip1() > 0.4 ) and color_white or red
                surface.SetDrawColor(col)
                surface.DrawRect(x, scrh - 125, math.ceil( wscale / 2 ), 20)
            end
        end

        if !IsValid( CD2_weaponpnl ) and GetConVar( "cd2_drawhud" ):GetBool() then
            CD2_weaponpnl = vgui.Create( "DModelPanel", GetHUDPanel() )
            CD2_weaponpnl:SetModel( mdl )
            CD2_weaponpnl:SetPos( scrw - 400 , scrh - 100 )
            CD2_weaponpnl:SetSize( 300, 60 )
            CD2_weaponpnl:SetFOV( 50 )
    
            local ent = CD2_weaponpnl:GetEntity()
            ent:SetMaterial( "models/debug/debugwhite" )
            CD2_weaponpnl:SetCamPos( Vector( 0, 80, 0 ) )
            CD2_weaponpnl:SetLookAt( ent:OBBCenter() )
            
    
            local thinkpanel = vgui.Create( "DPanel", CD2_weaponpnl )
    
            function CD2_weaponpnl:PostDrawModel( ent ) 
                render.SuppressEngineLighting( false )
            end
    
            function CD2_weaponpnl:PreDrawModel( ent ) 
                render.SuppressEngineLighting( true )
            end
            function CD2_weaponpnl:LayoutEntity() end
            function thinkpanel:Paint( w, h ) end
            function thinkpanel:Think()
                if !GetConVar( "cd2_drawhud" ):GetBool() or CD2.InDropMenu or !ply:IsCD2Agent() or CD2.InSpawnPointMenu or !ply:Alive() then self:GetParent():Remove() return end
                local wep = ply:GetActiveWeapon()
                if IsValid( CD2_weaponpnl ) and IsValid( wep ) then local ent = CD2_weaponpnl:GetEntity() ent:SetModel( wep:GetWeaponWorldModel() ) CD2_weaponpnl:SetLookAt( ent:OBBCenter() ) end
                
                if CD2_weaponpnl != self:GetParent() then
                    self:GetParent():Remove()
                end
            end
        end


        surface.SetDrawColor( blackish )
        surface.DrawRect( scrw - 120, scrh - 100, 90, 60 )


        surface.SetDrawColor( linecol )
        surface.DrawOutlinedRect( scrw - 120, scrh - 100, 90, 60, 2 )
        surface.DrawOutlinedRect( scrw - 100, scrh - 140, 70, 40, 2 )
        surface.DrawOutlinedRect( scrw - 400, scrh - 130, 300, 30, 2 )
        surface.DrawOutlinedRect( scrw - 400, scrh - 100, 280, 60, 2 )

        if !IsValid( CD2_equipmentpnl ) and GetConVar( "cd2_drawhud" ):GetBool() then
            local mdl = scripted_ents.Get( ply:GetEquipment() ).WorldModel

            CD2_equipmentpnl = vgui.Create( "DModelPanel", GetHUDPanel() )
            CD2_equipmentpnl:SetModel( mdl )
            CD2_equipmentpnl:SetPos( scrw - 135 , scrh - 85 )
            CD2_equipmentpnl:SetSize( 64, 64 )
            CD2_equipmentpnl:SetFOV( 60 )

            local ent = CD2_equipmentpnl:GetEntity()
            ent:SetMaterial( "models/debug/debugwhite" )
            CD2_equipmentpnl:SetCamPos( Vector( 0, 15, 0 ) )
            CD2_equipmentpnl:SetLookAt( ent:OBBCenter() )
            

            local thinkpanel = vgui.Create( "DPanel", CD2_equipmentpnl )

            function CD2_equipmentpnl:PostDrawModel( ent ) 
                render.SuppressEngineLighting( false )
            end

            function CD2_equipmentpnl:PreDrawModel( ent ) 
                render.SuppressEngineLighting( true )
            end
            function CD2_equipmentpnl:LayoutEntity() end
            function thinkpanel:Paint( w, h ) end
            function thinkpanel:Think()
                if !GetConVar( "cd2_drawhud" ):GetBool() or CD2.InDropMenu or !ply:IsCD2Agent() or CD2.InSpawnPointMenu or !ply:Alive() then self:GetParent():Remove() return end

                if IsValid( CD2_equipmentpnl ) then
                    local mdl = scripted_ents.Get( ply:GetEquipment() ).WorldModel
                    local ent = CD2_equipmentpnl:GetEntity()

                    if IsValid( ent ) and ent:GetModel() != mdl then ent:SetModel( mdl ) end
                end
                

                if CD2_equipmentpnl != self:GetParent() then
                    self:GetParent():Remove()
                end
            end
        end

        draw.DrawText( ply:GetEquipmentCount(), "crackdown2_font45", scrw - 60, scrh - 90, color_white, TEXT_ALIGN_CENTER )

    end

end