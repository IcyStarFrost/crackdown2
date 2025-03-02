-- Draws the skill hexes

local weaponskillcolor = Color( 0, 225, 255)
local strengthskillcolor = Color( 255, 251, 0)
local explosiveskillcolor = Color( 0, 110, 255 )
local agilityskillcolor = Color( 72, 255, 0)
local blackish = Color( 39, 39, 39)
local orangeish = Color( 202, 79, 22)
local agilityicon = Material( "crackdown2/ui/agilityicon.png", "smooth" )
local weaponicon = Material( "crackdown2/ui/weaponicon.png", "smooth" )
local strengthicon = Material( "crackdown2/ui/strengthicon.png", "smooth" )
local explosiveicon = Material( "crackdown2/ui/explosiveicon.png", "smooth" )
local skillcircle = Material( "crackdown2/ui/skillcircle.png" )
local skillglow = Material( "crackdown2/ui/skillglow2.png" )

local skillvars = {}

local function DrawSkillCircle( x, y, radius, arc, rotate )
    local seg = 30
	local cir = {}

	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -arc + rotate )
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( rotate ) -- This is needed for non math.absolute segment counts
	table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end


local function DrawSkillHex( x, y, icon, level, xp, col, skillname )
    skillvars[ skillname ] = skillvars[ skillname ] or {}
    skillvars[ skillname ].col = skillvars[ skillname ].col or col

    draw.NoTexture()

    -- Outlined circle pathing behind each skill dot
    surface.DrawCircle( x, y, 30, 0, 0, 0 )

    surface.SetDrawColor( color_white )
    surface.SetMaterial( skillcircle )

    -- White circle pathing behind each skill dot
    DrawSkillCircle( x, y, 33, Lerp( xp / 100, ( 55 * level ), ( 55 * ( level + 1 ) ) ) , -160 )

    draw.NoTexture()

    surface.SetDrawColor( blackish )
    CD2:DrawCircle( x, y, 25, 6, 30 ) -- Base hex

    if icon then
        surface.SetDrawColor( color_white )
        surface.SetMaterial( icon )
        CD2:DrawCircle( x, y, 30, 6, 30 )
    end

    draw.NoTexture()

    local dotsize = 6
    
    -- Top left dot
    surface.SetDrawColor( level == 6 and orangeish or blackish )
    CD2:DrawCircle( x - 15, y - 25, dotsize, 20, 0 )
    surface.DrawCircle( x - 15, y - 25, dotsize, 160, 160, 160, 30 )

    -- Top right dot
    surface.SetDrawColor( level >= 1 and orangeish or blackish )
    CD2:DrawCircle( x + 15, y - 25, dotsize, 20, 0 )
    surface.DrawCircle( x + 15, y - 25, dotsize, 160, 160, 160, 30 )

    -- Right dot
    surface.SetDrawColor( level >= 2 and orangeish or blackish )
    CD2:DrawCircle( x + 30, y, dotsize, 20, 0 )
    surface.DrawCircle( x + 30, y, dotsize, 160, 160, 160, 30 )

    -- Left dot
    surface.SetDrawColor( level >= 5 and orangeish or blackish )
    CD2:DrawCircle( x - 30, y, dotsize, 20, 0 )
    surface.DrawCircle( x - 30, y, dotsize, 160, 160, 160, 30 )

    -- Bottom left dot
    surface.SetDrawColor( level >= 4 and orangeish or blackish )
    CD2:DrawCircle( x - 15, y + 25, dotsize, 20, 0 )
    surface.DrawCircle( x - 15, y + 25, dotsize, 160, 160, 160, 30 )

    -- Bottom right dot
    surface.SetDrawColor( level >= 3 and orangeish or blackish )
    CD2:DrawCircle( x + 15, y + 25, dotsize, 20, 0 )
    surface.DrawCircle( x + 15, y + 25, dotsize, 160, 160, 160, 30 )

    skillvars[ skillname ].col.a = Lerp( 3 * FrameTime(), skillvars[ skillname ].col.a, 0 )

    if skillvars[ skillname ].col.a > 5 then
        surface.SetDrawColor( skillvars[ skillname ].col )
        surface.SetMaterial( skillglow )
        CD2:DrawCircle( x, y, 40, 50, 30 )
    end

    if xp != skillvars[ skillname ].lastxp then
        skillvars[ skillname ].col.a = 255
    end
    
    skillvars[ skillname ].lastxp = xp
end

function CD2.HUDCOMPONENENTS.components.AgilitySkill( ply, scrw, scrh, hudscale )
    if !ply:Alive() then return end

    
    DrawSkillHex( 130, 170, agilityicon, ply:GetAgilitySkill(), ply:GetAgilityXP(), agilityskillcolor, "Agility" )
end

function CD2.HUDCOMPONENENTS.components.WeaponSkill( ply, scrw, scrh, hudscale )
    if !ply:Alive() then return end

    
    DrawSkillHex( 130, 170 * 1.5, weaponicon, ply:GetWeaponSkill(), ply:GetWeaponXP(), weaponskillcolor, "Weapon" )
end

function CD2.HUDCOMPONENENTS.components.StrengthSkill( ply, scrw, scrh, hudscale )
    if !ply:Alive() then return end

    
    DrawSkillHex( 130, 170 * 2, strengthicon, ply:GetStrengthSkill(), ply:GetStrengthXP(), strengthskillcolor, "Strength" )
end

function CD2.HUDCOMPONENENTS.components.ExplosiveSkill( ply, scrw, scrh, hudscale )
    if !ply:Alive() then return end

    
    DrawSkillHex( 130, 170 * 2.5, explosiveicon, ply:GetExplosiveSkill(), ply:GetExplosiveXP(), explosiveskillcolor, "Explosive" )
end