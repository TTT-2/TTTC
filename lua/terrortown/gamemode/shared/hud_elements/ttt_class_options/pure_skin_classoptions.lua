local draw = draw
local string = string

local base = "pure_skin_element"

DEFINE_BASECLASS(base)

HUDELEMENT.Base = base

if CLIENT then
	local optionMargin = 20
	local optionWidth = 150
	local optionHeight = 40
	local pad = 20
	local linePad = 8

	local const_defaults = {
		basepos = {x = 0, y = 0},
		size = {w = optionWidth, h = optionHeight * 2 + 5},
		minsize = {w = 130, h = 40}
	}

	function HUDELEMENT:PreInitialize()
		BaseClass.PreInitialize(self)

		local hud = huds.GetStored("pure_skin")
        if hud then
            hud:ForceElement(self.id)
        end

        -- set as fallback default, other skins have to be set to true!
        self.disabledUnlessForced = false
	end

	function HUDELEMENT:Initialize()
		self.scale = 1.0
		self.optionMargin = optionMargin
		self.optionWidth = optionWidth
		self.optionHeight = optionHeight
		self.pad = pad
		self.linePad = linePad

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
		self.pad = pad * self.scale
		self.linePad = linePad * self.scale

		BaseClass.PerformLayout(self)
	end

	function HUDELEMENT:DrawClassOption(ty, key, name, color, key_width)
		local x = self:GetPos().x - key_width - self.pad
		local w = self:GetSize().w + key_width + self.pad

		-- draw bg and shadow
		self:DrawBg(x, ty, w, self.optionHeight, color)

		-- draw key
		draw.AdvancedText(key, "ClassDescOptions", x + (self.pad + key_width) * 0.5, ty + self.optionHeight * 0.5, self:GetDefaultFontColor(color), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, true, self.scale)

		-- draw line
		local line = 3

		draw.RoundedBoxEx(0, x + key_width + self.pad + 1, ty + self.linePad, 1, self.optionHeight - 2 * self.linePad, self:GetDefaultFontColor(color))

		-- draw class name
		draw.AdvancedText(name, "ClassDesc", x + self.pad + key_width + line + (w - self.pad - line - key_width) * 0.5, ty + self.optionHeight * 0.5, self:GetDefaultFontColor(color), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, true, self.scale)

		-- draw lines around the element
		self:DrawLines(x, ty, w, self.optionHeight)
	end

	local tryT

	function HUDELEMENT:Draw()
		local client = LocalPlayer()
		local pos = self:GetPos()
		local y = pos.y

		tryT = tryT or LANG.TryTranslation

		local key1 = string.upper(input.GetKeyName(bind.Find("toggleclass")) or "?")
		local key2 = string.upper(input.GetKeyName(bind.Find("abortclass")) or "?")

		local y_temp = y

		local hd1 = CLASS.GetClassDataByIndex(client.classOpt1)
		local hd2 = CLASS.GetClassDataByIndex(client.classOpt2)

		-- make sure hd1 and hd2 are always defined to make sure the HUD editor is working
		if not hd1 then	
			hd1 = {name = "Placeholder Class 1", color = Color(255, 100, 120)}
		end
		if not hd2 then	
			hd2 = {name = "Placeholder Class 2", color = Color(70, 120, 180)}
		end

		-- get keysize of both bound keys and use the bigger one
        surface.SetFont("ClassDescOptions")
        local key_width = surface.GetTextSize(string.upper(key1))
        key_width = math.max(key_width, surface.GetTextSize(string.upper(key2)))

		self:DrawClassOption(y_temp, key1, tryT(hd1.name), hd1.color, key_width)

		y_temp = y_temp + self.optionHeight + 5

		self:DrawClassOption(y_temp, key2, tryT(hd2.name), hd2.color, key_width)
	end

	function HUDELEMENT:ShouldDraw()
		local client = LocalPlayer()

		return HUDEditor.IsEditing or (client.classOpt1 and client.classOpt2 and client:IsActive() and GetGlobalBool("ttt2_classes") and GetGlobalBool("ttt_classes_option"))
	end
end
