local draw = draw
local string = string

local base = "old_ttt_element"

DEFINE_BASECLASS(base)

HUDELEMENT.Base = base

if CLIENT then
	local optionMargin = 20
	local optionWidth = 200
	local optionHeight = 40

	local const_defaults = {
							basepos = {x = 0, y = 0},
							size = {w = optionWidth, h = optionHeight * 2 + optionMargin},
							minsize = {w = 0, h = 0}
		}

	function HUDELEMENT:PreInitialize()
		BaseClass.PreInitialize(self)

		huds.GetStored("old_ttt"):ForceElement(self.id)
	end

	function HUDELEMENT:GetDefaults()
		const_defaults["basepos"] = { x = ScrW() - optionWidth - optionMargin, y = optionMargin + 80 }
		return const_defaults
	end

	function HUDELEMENT:DrawHeroOption(y, key, name, color)
		local x = ScrW() - optionWidth - optionMargin

		-- draw background
		draw.RoundedBoxEx(0, x, y, optionWidth, optionHeight, color)

		-- draw key
		local pad = 40

		draw.SimpleText(key, "HeroDescOptions", x + pad * 0.5, y + optionHeight * 0.5, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		-- draw line
		local line = 3

		draw.RoundedBoxEx(0, x + pad + 1, y, 1, optionHeight, COLOR_WHITE)

		-- draw class name
		draw.SimpleText(name, "HeroDesc", x + pad + line + (optionWidth - pad - line) * 0.5, y + optionHeight * 0.5, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local rawT

	function HUDELEMENT:Draw()
		local client = LocalPlayer()

		if client:IsActive() and GetGlobalBool("ttt_classes_option") then
			if not client.classOpt1 or not client.classOpt2 then return end

			rawT = rawT or LANG.GetRawTranslation

			local key1 = string.upper(input.GetKeyName(bind.Find("toggleclass")) or "?")
			local key2 = string.upper(input.GetKeyName(bind.Find("abortclass")) or "?")

			local y = optionMargin + 80

			local hd1 = CLASS.GetClassDataByIndex(client.classOpt1)
			local hd2 = CLASS.GetClassDataByIndex(client.classOpt2)

			self:DrawHeroOption(y, key1, rawT(hd1.name), hd1.color)

			y = y + optionHeight + 5

			self:DrawHeroOption(y, key2, rawT(hd2.name), hd2.color)
		end
	end
end
