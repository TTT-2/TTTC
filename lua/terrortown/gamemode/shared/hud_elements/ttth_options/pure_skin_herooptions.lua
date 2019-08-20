local draw = draw
local string = string

local base = "pure_skin_element"

DEFINE_BASECLASS(base)

HUDELEMENT.Base = base

if CLIENT then
	local optionMargin = 20
	local optionWidth = 200
	local optionHeight = 40

	local const_defaults = {
		basepos = {x = 0, y = 0},
		size = {w = optionWidth, h = optionHeight * 2 + 5},
		minsize = {w = 130, h = 40}
	}

	function HUDELEMENT:PreInitialize()
		BaseClass.PreInitialize(self)

		local hud = huds.GetStored("pure_skin")
		if not hud then return end

		hud:ForceElement(self.id)
	end

	function HUDELEMENT:Initialize()
		self.scale = 1.0
		self.optionMargin = optionMargin
		self.optionWidth = optionWidth
		self.optionHeight = optionHeight

		BaseClass.Initialize(self)
	end

	function HUDELEMENT:GetDefaults()
		const_defaults["basepos"] = {x = ScrW() - self.optionWidth - self.optionMargin, y =  self.optionMargin + 80 }

		return const_defaults
	end

	-- parameter overwrites
	function HUDELEMENT:IsResizable()
		return true, false
	end
	-- parameter overwrites end

	function HUDELEMENT:PerformLayout()
		self.scale = self:GetHUDScale()
		self.optionMargin = optionMargin * self.scale
		self.optionWidth = optionWidth * self.scale
		self.optionHeight = optionHeight * self.scale

		BaseClass.PerformLayout(self)
	end

	function HUDELEMENT:DrawHeroOption(ty, key, name, color)
		local x = self:GetPos().x
		local w = self:GetSize().w

		-- draw bg and shadow
		self:DrawBg(x, ty, w, self.optionHeight, color)

		-- draw key
		local pad = 40

		draw.SimpleText(key, "HeroDescOptions", x + pad * 0.5, ty + self.optionHeight * 0.5, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		-- draw line
		local line = 3

		draw.RoundedBoxEx(0, x + pad + 1, ty + 3, 1, self.optionHeight - 6, COLOR_WHITE)

		-- draw hero name
		draw.SimpleText(name, "HeroDesc", x + pad + line + (w - pad - line) * 0.5, ty + self.optionHeight * 0.5, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		-- draw lines around the element
		self:DrawLines(x, ty, w, self.optionHeight)
	end

	local rawT

	function HUDELEMENT:Draw()
		local client = LocalPlayer()
		local pos = self:GetPos()
		local y = pos.y

		rawT = rawT or LANG.GetRawTranslation

		local key1 = string.upper(input.GetKeyName(bind.Find("togglehero")) or "?")
		local key2 = string.upper(input.GetKeyName(bind.Find("aborthero")) or "?")

		local y_temp = y

		local hd1 = CLASS.GetHeroDataByIndex(client.heroOpt1)
		local hd2 = CLASS.GetHeroDataByIndex(client.heroOpt2)

		self:DrawHeroOption(y_temp, key1, rawT(hd1.name), hd1.color)

		y_temp = y_temp + self.optionHeight + 5

		self:DrawHeroOption(y_temp, key2, rawT(hd2.name), hd2.color)

	end

	function HUDELEMENT:ShouldDraw()
		local client = LocalPlayer()

		return client:IsActive() and GetGlobalBool("ttt_classes_option") and client.heroOpt1 and client.heroOpt2
	end
end
