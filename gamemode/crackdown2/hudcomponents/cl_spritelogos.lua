local fireicon = Material( "crackdown2/ui/explosive.png" )
local explosivemodels = {
    [ "models/props_c17/oildrum001_explosive.mdl" ] = true,
    [ "models/props_junk/gascan001a.mdl" ] = true
}
local peacekeeper = Material( "crackdown2/ui/peacekeeper.png", "smooth" )
local cell = Material( "crackdown2/ui/cell.png", "smooth" )
local effects_ents
local next_update_effects = 0
local red = Color( 163, 12, 12)

function CD2.HUDCOMPONENENTS.components_3d.SpriteLogos( ply )
    local ply = LocalPlayer()
    if CD2.InDropMenu or !ply:IsCD2Agent() or CD2.InSpawnPointMenu or !ply:Alive() then return end
    
    if CurTime() > next_update_effects then
        effects_ents = CD2:FindInSphere( ply:GetPos(), 1500 )
        next_update_effects = CurTime() + 0.5
    end

    for i = 1, #effects_ents do
        local v = effects_ents[ i ]
        if !IsValid( v ) then continue end

        -- Peacekeeper --
        if v:IsCD2NPC() and v:GetCD2Team() == "agency" then
            render.SetMaterial( peacekeeper )
            render.DrawSprite( v:GetPos() + Vector( 0, 0, 100 ), 32, 20, color_white )
        -- Explosives --
        elseif explosivemodels[ v:GetModel() ] then
            render.SetMaterial( fireicon )
            render.DrawSprite( v:GetPos() + Vector( 0, 0, v:GetModelRadius() + 40 ), 16, 16, color_white )
        -- Cell --
        elseif v:IsCD2NPC() and v:GetCD2Team() == "cell" then
            render.SetMaterial( cell )
            render.DrawSprite( v:GetPos() + Vector( 0, 0, 100 ), 16, 16, red )
        end
    end
end