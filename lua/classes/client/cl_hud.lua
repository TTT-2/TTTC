-- caching
local GetRawLang
local cached_arcs = {}

local surface = surface
local draw = draw
local math = math

-- Fonts
surface.CreateFont("CurrentHero", {font = "Trebuchet24", size = 28, weight = 1000})
surface.CreateFont("CurrentHeroDesc", {font = "Trebuchet24", size = 52, weight = 1000})
surface.CreateFont("HeroDesc", {font = "Trebuchet24", size = 14, weight = 1000})
surface.CreateFont("HeroDescOptions", {font = "Trebuchet24", size = 28, weight = 1000})

local margin = 10
local default_hud_x = margin
local default_hud_y = ScrH() - margin - 120 * 2 -- add a padding between role and hero for other addons, so multiply 120 with 2 (otherwise without 2)

-- ConVars
local cvar_hero_notification = CreateClientConVar("ttth_hero_notification", "1", true, false, "Toggle the notification on receiving a hero hero.")
local cvar_hero_hud_width = CreateClientConVar("ttth_hud_width", "20", true, false, "The relative x-coordinate (position) of the HUD. (0-100) Def: 20")
local cvar_hero_hud_y = CreateClientConVar("ttth_hud_y", tostring(default_hud_y), true, false, "The relative y-coordinate (position) of the HUD. (0-100) Def: " .. tostring(default_hud_y))
local cvar_hero_hud_x = CreateClientConVar("ttth_hud_x", tostring(default_hud_x), true, false, "The relative x-coordinate (position) of the HUD. (0-100) Def: " .. tostring(default_hud_x))

local function DrawBg(x, y, client, xw)
	-- Traitor area sizes
	local tw = 150 + xw
	local th = 30
	local hd = client:GetHeroData()

	if not hd then return end

	local col = hd.color or COLOR_HERO

	-- main border, traitor based
	draw.RoundedBox(8, x, y - th, tw, th, col)
end

local function ShadowedText(text, font, x, y, color, xalign, yalign)
	draw.SimpleText(text, font, x + 2, y + 2, COLOR_BLACK, xalign, yalign)
	draw.SimpleText(text, font, x, y, color, xalign, yalign)
end

local function HeroInfo(client)
	if huds and HUDManager then
		local hud = huds.GetStored(HUDManager.GetHUD())

		if hud and hud.GetElementByType then
			local elem = hud:GetElementByType("tttinfopanel")
			if elem and elem.SetSecondaryRoleInfoFunction and isfunction(elem.SetSecondaryRoleInfoFunction) then return end
		end
	end

	local round_state = GAMEMODE.round_state

	if (round_state == ROUND_PREP or client:IsActive()) and client:IsHero() then
		local hd = client:GetHeroData()

		local x = cvar_hero_hud_x:GetFloat()
		local y = cvar_hero_hud_y:GetFloat()

		local xw = cvar_hero_hud_width:GetFloat()

		DrawBg(x, y, client, xw)

		x = x + margin + 63 + xw * 0.5
		y = y - 30

		local text = HEROES.GetHeroTranslation(hd)

		-- Draw current hero state
		ShadowedText(text, "CurrentHero", x, y, COLOR_WHITE, TEXT_ALIGN_CENTER)
	end
end

hook.Add("HUDPaint", "TTTHHeroHudPaint", function()
	local client = LocalPlayer()

	if hook.Run("HUDShouldDraw", "TTTHHeroInfo") then
		HeroInfo(client)
	end
end)

------------------------ Experimental -------------------------

function draw.Arc(id, cx, cy, radius, thickness, startang, endang, roughness, color)
	surface.SetDrawColor(color)

	draw.NoTexture()

	surface.DrawArc(surface.PrecacheArc(id, cx, cy, radius, thickness, startang, endang, roughness))
end

-- Currently caching is only searched for changed Startang and Endang. We only modify these parameters, so this will lead to the best possible performance
function surface.PrecacheArc(id, cx, cy, radius, thickness, startang, endang, roughness)
	if cached_arcs[id]
	and cached_arcs[id].cx == cx
	and cached_arcs[id].cy == cy
	and cached_arcs[id].radius == radius
	and cached_arcs[id].startang == startang
	and cached_arcs[id].endang == endang
	then
		return cached_arcs[id].arcs
	else
		cached_arcs[id] = {}
		cached_arcs[id].cx = cx
		cached_arcs[id].cy = cy
		cached_arcs[id].radius = radius
		cached_arcs[id].startang = startang
		cached_arcs[id].endang = endang
	end

	local triarc = {}
	-- local deg2rad = math.pi / 180

	-- Define step
	local step = math.max(roughness or 1, 1)

	-- Correct start/end ang
	startang, endang = startang or 0, endang or 0

	if startang > endang then
		step = math.abs(step) * -1
	end

	-- Create the inner circle's points.
	local inner2 = {}
	local r = radius - thickness

	for deg = startang, endang, step do
		local rad = math.rad(deg)
		-- local rad = deg2rad * deg
		local ox, oy = cx + (math.cos(rad) * r), cy + (-math.sin(rad) * r)

		inner2[#inner2 + 1] = {
			x = ox,
			y = oy,
			u = (ox - cx) / radius + 0.5,
			v = (oy - cy) / radius + 0.5,
		}
	end

	-- Create the outer circle's points.
	local outer2 = {}

	for deg = startang, endang, step do
		local rad = math.rad(deg)
		-- local rad = deg2rad * deg
		local ox, oy = cx + (math.cos(rad) * radius), cy + (-math.sin(rad) * radius)

		outer2[#outer2 + 1] = {
			x = ox,
			y = oy,
			u = (ox - cx) / radius + 0.5,
			v = (oy - cy) / radius + 0.5,
		}
	end

	local inn = #inner2 * 2

	-- Triangulize the points.
	for tri = 1, inn do -- twice as many triangles as there are degrees.
		local p1, p2, p3

		p1 = outer2[math.floor(tri * 0.5) + 1]
		p3 = inner2[math.floor((tri + 1) * 0.5) + 1]

		if tri % 2 == 0 then -- if the number is even use outer.
			p2 = outer2[math.floor((tri + 1) * 0.5)]
		else
			p2 = inner2[math.floor((tri + 1) * 0.5)]
		end

		triarc[#triarc + 1] = {p1, p2, p3}
	end

	cached_arcs[id].arcs = triarc

	-- Return a table of triangles to draw.
	return triarc
end

-- Draw a premade arc
function surface.DrawArc(arc)
	for _, v in ipairs(arc) do
		surface.DrawPoly(v)
	end
end
