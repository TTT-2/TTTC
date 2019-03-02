local surface = surface
local draw = draw
local math = math
local string = string

local GetRawLang

local sf = surface
local dr = draw

local notification_state = 0
local notification_phase = 0
local notification_time = 4
local notification_fade = 0.4
local notification_start = 0

local options_closed = true
local class_option1 = CLASSES.UNSET.index
local class_option2 = CLASSES.UNSET.index

-- Fonts
sf.CreateFont("CurrentClass", {font = "Trebuchet24", size = 28, weight = 1000})
sf.CreateFont("CurrentClassDesc", {font = "Trebuchet24", size = 52, weight = 1000})
sf.CreateFont("ClassDesc", {font = "Trebuchet24", size = 21, weight = 1000})
sf.CreateFont("ClassDescOptions", {font = "Trebuchet24", size = 28, weight = 1000})


local function RoundedBoxOutlined(x, y, w, h, color)
	local bordersize = 8
	local bordercol = COLOR_BLACK
	local texOutlinedCorner = surface.GetTextureID("gui/corner8")

	x = math.Round(x)
	y = math.Round(y)
	w = math.Round(w)
	h = math.Round(h)

	surface.SetDrawColor(bordercol)
	surface.SetTexture(texOutlinedCorner)

	surface.DrawTexturedRectRotated(x + bordersize / 2, y + bordersize / 2, bordersize, bordersize, 0)
	surface.DrawTexturedRectRotated(x + w - bordersize / 2, y + bordersize / 2, bordersize, bordersize, 270)
	surface.DrawTexturedRectRotated(x + w - bordersize / 2, y + h - bordersize / 2, bordersize, bordersize, 180)
	surface.DrawTexturedRectRotated(x + bordersize / 2, y + h - bordersize / 2, bordersize, bordersize, 90)

	surface.DrawLine(x + bordersize, y, x + w - bordersize, y)
	surface.DrawLine(x + bordersize, y + h - 1, x + w - bordersize, y + h - 1)

	surface.DrawLine(x, y + bordersize, x, y + h - bordersize)
	surface.DrawLine(x + w - 1, y + bordersize, x + w - 1, y + h - bordersize)

	draw.RoundedBox(bordersize, x + 1, y + 1, w - 2, h - 2, color)
end

local function DrawIconFramed(matPath, x, y, tw, th, lineStart, lineEnd)
	local mat = Material(matPath)

	--draw.RoundedBox(0, x, y, tw, th, COLOR_BLACK)

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(mat)
	surface.DrawTexturedRect(x + 1, y + 1, tw - 2, th - 2)

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawLine(lineStart, y + th + 10, lineEnd, y + th + 10)
end

local function DrawOutlinedBox(x, y, w, h, thickness, clr)
	surface.SetDrawColor(clr)

	for i = 0, thickness - 1 do
		surface.DrawOutlinedRect(x + i, y + i, w - i * 2, h - i * 2)
	end
end

local function DrawBg(x, y, client)
	-- Traitor area sizes
	local tw = 170
	local th = 30
	local col = client:GetClassData().color or COLOR_CLASS

	-- main border, traitor based
	dr.RoundedBox(8, x, y - th, tw, th, col)
end

local function ShadowedText(text, font, x, y, color, xalign, yalign)
	dr.SimpleText(text, font, x + 2, y + 2, COLOR_BLACK, xalign, yalign)
	dr.SimpleText(text, font, x, y, color, xalign, yalign)
end

local margin = 10

local classInformationAdded = false

cvars.AddChangeCallback( "cttt2_current_hud", function( convar_name, value_old, value_new )
	classInformationAdded = false
	ClassesInfo(LocalPlayer())
end )

local function ClassesInfo(client)
	local round_state = GAMEMODE.round_state

	if HUDManager and not classInformationAdded then
		local hud = huds.GetStored(HUDManager.GetHUD())
		--print(string.format("[TTTC] HudManager found! (%s)", HUDManager.GetHUD()))
		for _, elemName in ipairs(hud:GetElements()) do
			if string.match(elemName, "info") then
				local el = hudelements.GetStored(elemName)
				if isfunction(el.SetSecondaryRoleInfoFunction) then
					el:SetSecondaryRoleInfoFunction(function()
						if (round_state == ROUND_PREP or LocalPlayer():IsActive()) and GetConVar("ttt_customclasses_enabled"):GetBool() and LocalPlayer():HasCustomClass() then
							return {color=LocalPlayer():GetClassData().color or COLOR_CLASS, text=GetClassTranslation(LocalPlayer():GetClassData())}
						else
							return nil
						end
					end)
					--print("[TTTC] Class informations added!")
					classInformationAdded = true
				end
			end
		end
	end
	
	if not classInformationAdded then
		if (round_state == ROUND_PREP or client:IsActive()) and GetConVar("ttt_customclasses_enabled"):GetBool() and client:HasCustomClass() then

			local cd = client:GetClassData()

			local x = margin
			local y = ScrH() - margin - 120 * 2 -- add a padding between role and class for other addons, so multiply 120 with 2 (otherwise without 2)

			local xStr = tostring(x)
			local yStr = tostring(y)

			x = CreateClientConVar("tttc_hud_x", xStr, true, false, "The relative x-coordinate (position) of the HUD. (0-100) Def: " .. xStr):GetFloat()
			y = CreateClientConVar("tttc_hud_y", yStr, true, false, "The relative y-coordinate (position) of the HUD. (0-100) Def: " .. yStr):GetFloat()

			DrawBg(x, y, client)

			x = x + margin + 73
			y = y - 30

			local text = GetClassTranslation(cd)

			-- Draw current class state
			ShadowedText(text, "CurrentClass", x, y, COLOR_WHITE, TEXT_ALIGN_CENTER)
		end
	end
end

local function HUDDrawOption(classIndex, x, y, tw, th)
	local cd = GetClassByIndex(classIndex)
	local col = cd.color or COLOR_CLASS
	local text = GetClassTranslation(cd)

	RoundedBoxOutlined(x, y, tw, th, Color(col.r, col.g, col.b, 230))
	RoundedBoxOutlined(x, y, tw, 100, Color(col.r * 0.7, col.g * 0.7, col.b * 0.7, 255))

	-- Draw current class state
	ShadowedText(text, "CurrentClassDesc", x + tw / 2, y + 50, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local bWeapons = cd.weapons and #cd.weapons > 0
	local bItems = cd.items and #cd.items > 0
	local foundWeapon = false

	if cd.icon then
		DrawIconFramed(cd.icon, x + tw / 2 - 64, y + 110, 128, 128, x, x + tw)

		foundWeapon = true
	end

	-- weapons
	if bWeapons then
		for _, cls in ipairs(cd.weapons) do
			local tmp = weapons.Get(cls)

			if tmp and tmp.Icon and not foundWeapon then
				-- special handling for the weird perk weapons
				if string.StartWith(cls, "ttt_perk_") then
					local perkName = string.sub(cls, 10)
					local item = items.GetStored(_G["EQUIP_" .. string.upper(perkName)])

					if item then
						DrawIconFramed(item.material, x + tw / 2 - 64, y + 110, 128, 128, x, x + tw)
					end
				else
					DrawIconFramed(tmp.Icon, x + tw / 2 - 64, y + 110, 128, 128, x, x + tw)
				end

				foundWeapon = true
			end
		end
	end

	-- items
	if bItems then
		for _, id in ipairs(cd.items) do
			local tmp = items.GetStored(id)

			if tmp and tmp.material and not foundWeapon then
				DrawIconFramed(tmp.material, x + tw / 2 - 64, y + 110, 128, 128, x, x + tw)

				foundWeapon = true
			end
		end
	end

	local textY = foundWeapon and (y + 258) or (y + 150)

	-- weapons
	dr.SimpleText("Weapons:", "ClassDescOptions", x + 10, textY, COLOR_WHITE, TEXT_ALIGN_LEFT)

	textY = textY + 40

	for _, cls in ipairs(cd.weapons) do
		local tmp = weapons.Get(cls)
		tmp = (tmp and LANG.TryTranslation(tmp.PrintName)) or tmp and tmp.PrintName or cls

		dr.SimpleText(" - " .. tmp, "ClassDesc", x + 20, textY, COLOR_WHITE, TEXT_ALIGN_LEFT)

		textY = textY + 20
	end

	textY = y + 410

	surface.DrawLine(x, textY, x + tw, textY)

	textY = textY + 10

	-- items
	dr.SimpleText("Items:", "ClassDescOptions", x + 10, textY, COLOR_WHITE, TEXT_ALIGN_LEFT)

	textY = textY + 40

	for _, id in ipairs(cd.items) do
		local name = items.GetStored(id)
		name = (name and LANG.TryTranslation(name.name)) or name and (name.name or "UNNAMED") or "UNNAMED"

		dr.SimpleText(" - " .. name, "ClassDesc", x + 20, textY, COLOR_WHITE, TEXT_ALIGN_LEFT)
		textY = textY + 20
	end
end

local function ClassesOptions(client)
	local round_state = GAMEMODE.round_state

	if round_state == ROUND_PREP and not options_closed then
		if GetConVar("ttt_customclasses_enabled"):GetBool() and class_option1 ~= CLASSES.UNSET.index and class_option2 ~= CLASSES.UNSET.index then
			local tw = 450
			local th = 600
			local border = 50
			local x1 = ScrW() / 2 - tw - border
			local x2 = ScrW() / 2 + border
			local y = ScrH() / 2 - 100 - th / 2
			
			HUDDrawOption(class_option1, x1, y, tw, th)
			HUDDrawOption(class_option2, x2, y, tw, th)

			RoundedBoxOutlined(x1, y + th + 50, 2 * tw + 2 * border, 200, Color(0, 0, 0, 230))

			ShadowedText("Random", "CurrentClassDesc", ScrW() / 2, y + th + 50 + 100, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			--show mousePos
			local mousePosX, mousePosY = gui.MousePos()
			if mousePosX > x1 and mousePosX < x1 + tw and mousePosY > y and mousePosY < y + th then
				DrawOutlinedBox(x1, y, tw, th, 5, COLOR_WHITE)
			elseif mousePosX > x2 and mousePosX < x2 + tw and mousePosY > y and mousePosY < y + th then
				DrawOutlinedBox(x2, y, tw, th, 5, COLOR_WHITE)
			elseif mousePosX > x1 and mousePosX < x1 + 2 * tw + 2 * border and mousePosY > y + th + 50 and mousePosY < y + th + 50 + 200 then
				DrawOutlinedBox(x1, y + th + 50, 2 * tw + 2 * border, 200, 5, COLOR_WHITE)
			end
		end
	elseif not options_closed then
		gui.EnableScreenClicker(false)
		options_closed = true
	end
end

local function ClassNotification(client)
	local round_state = GAMEMODE.round_state
	local ct = CurTime()
	local tm = notification_start + notification_time

	if tm > ct and (round_state == ROUND_PREP or client:IsActive()) and GetConVar("ttt_customclasses_enabled"):GetBool() and client:HasCustomClass() then
		GetRawLang = GetRawLang or LANG.GetRawTranslation

		local cd = client:GetClassData()

		local x = margin
		local mid = ScrW() / 2

		-- draw box
		local tw = ScrW() - margin * 2
		local th = 75
		local col = cd.color or COLOR_CLASS

		local bWeapons = cd.weapons and #cd.weapons > 0
		if bWeapons then
			th = th + 25
		end

		local bItems = cd.items and #cd.items > 0
		if bItems then
			th = th + 25
		end

		local desc_text = GetRawLang("class_desc_" .. cd.name)
		if desc_text then
			th = th + 25
		end

		local y = -th

		-------------------------
		-- notification animation

		if notification_state >= 1 and notification_phase == 0 then
			notification_phase = 1
		elseif notification_state <= 0 and notification_phase == 2 then
			notification_phase = 3
		else
			if notification_phase == 1 then
				local restTime = tm - ct
				restTime = restTime - notification_fade

				if restTime <= 0 then
					notification_phase = 2
				end
			else
				local restTime = tm - ct

				if notification_phase == 0 then
					notification_state = (notification_time - restTime) / notification_fade
				else
					notification_state = restTime / notification_fade
				end
			end
		end

		if notification_phase == 3 then
			notification_phase = 0
		end

		-- end notification animation
		-----------------------------

		y = y + (margin + th) * notification_state

		dr.RoundedBox(8, x, y, tw, th, col)

		-- draw class text
		local text = GetClassTranslation(cd)

		ShadowedText(text, "CurrentClassDesc", mid, y + 10, COLOR_WHITE, TEXT_ALIGN_CENTER)

		-- draw description
		y = y + 70

		-- weapons
		if bWeapons then
			local weaps = ""

			for _, cls in ipairs(cd.weapons) do
				local tmp = weapons.Get(cls)
				tmp = (tmp and (LANG.TryTranslation(tmp.PrintName) or tmp.PrintName)) or cls

				if weaps ~= "" then
					weaps = weaps .. ", "
				end

				weaps = weaps .. tmp
			end

			text = (GetRawLang("classes_desc_weapons_short") or "Weapons: ") .. weaps

			dr.SimpleText(text, "ClassDesc", mid, y, COLOR_WHITE, TEXT_ALIGN_CENTER)

			y = y + 25
		end

		-- items
		if bItems then
			local itms = ""

			for _, id in ipairs(cd.items) do
				local name = items.GetStored(id)
				name = (name and (LANG.TryTranslation(name.name) or name.name)) or "UNNAMED"

				if itms ~= "" then
					itms = itms .. ", "
				end

				itms = itms .. name
			end

			text = (GetRawLang("classes_desc_items_short") or "Items: ") .. itms

			dr.SimpleText(text, "ClassDesc", mid, y, COLOR_WHITE, TEXT_ALIGN_CENTER)

			y = y + 25
		end

		-- custom desc
		if desc_text then
			dr.SimpleText(desc_text, "ClassDesc", mid, y, COLOR_WHITE, TEXT_ALIGN_CENTER)
		end
	end
end

hook.Add("HUDPaint", "TTTCClassesHudPaint", function()
	local client = LocalPlayer()

	if hook.Run("HUDShouldDraw", "TTTCClassesInfo") then
		ClassesInfo(client)
	end

	if CreateClientConVar("tttc_class_notification", "1", true, false, "Toggle the notification on receiving a class.") or hook.Run("HUDShouldDraw", "TTTCClassNotification") then
		ClassNotification(client)
	end

	if hook.Run("HUDShouldDraw", "TTTCClassesInfo") then
		ClassesOptions(client)
	end
end)

hook.Add("TTTCUpdatedCustomClass", "HUDNtfctnUpdatedCustomClass", function(ply)
	if ply:HasCustomClass() then
		notification_start = CurTime()
		notification_state = 0
		notification_phase = 0
	end
end)

hook.Add("TTTCUpdatedCustomClassOptions", "HUDNtfctnUpdatedCustomClassOptions", function(cls1, cls2)
	options_closed = false
	class_option1 = cls1
	class_option2 = cls2

	gui.EnableScreenClicker(true)

	--[[
	if CrosshairSize == "0" then
		CrosshairSize = CrosshairDebugSize:GetFloat()
	end

	RunConsoleCommand("ttt_crosshair_size", CrosshairSize)
	]]--
end)

hook.Add("VGUIMousePressed", "VGUIMousePressedTTTC", function(pnl, Mouse)
	if not options_closed then
		local tw = 450
		local th = 600
		local border = 50
		local x1 = ScrW() / 2 - tw - border
		local x2 = ScrW() / 2 + border
		local y = ScrH() / 2 - 100 - th / 2

		local mousePosX, mousePosY = gui.MousePos()
		if mousePosX > x1 and mousePosX < x1 + tw and mousePosY > y and mousePosY < y + th then
			net.Start("TTTCClientSendCustomClassChoice")
			net.WriteBool(false)
			net.WriteUInt(class_option1 - 1, CLASS_BITS)
		elseif mousePosX > x2 and mousePosX < x2 + tw and mousePosY > y and mousePosY < y + th then
			net.Start("TTTCClientSendCustomClassChoice")
			net.WriteBool(false)
			net.WriteUInt(class_option2 - 1, CLASS_BITS)
		elseif mousePosX > x1 and mousePosX < x1 + 2 * tw + 2 * border and mousePosY > y + th + 50 and mousePosY < y + th + 50 + 200 then
			net.Start("TTTCClientSendCustomClassChoice")
			net.WriteBool(true)
		else
			return
		end

		net.SendToServer()

		options_closed = true

		gui.EnableScreenClicker(false)
	end
end)
