local plymeta = FindMetaTable("Player")

if not plymeta then return end

AccessorFunc(plymeta, "heroTime", "HeroTime", FORCE_NUMBER)
AccessorFunc(plymeta, "heroTimestamp", "HeroTimestamp", FORCE_NUMBER)
AccessorFunc(plymeta, "heroEndless", "HeroEndless", FORCE_BOOL)
AccessorFunc(plymeta, "heroCooldownTS", "HeroCooldownTS", FORCE_NUMBER)

function plymeta:GetHero()
	return self.hero
end

function plymeta:SetHero(hero)
	local old = self:GetHero()

	if hero ~= old then
		local hd = self:GetHeroData()

		if hd and self.prepareActivation and isfunction(hd.onFinishPreparingActivation) then
			hd.onFinishPreparingActivation(self)

			self.prepareActivation = nil
		end

		self.charging = nil
		self.heroTime = nil
		self.heroTimestamp = nil
		self.heroAmount = nil

		if CLIENT and self.sendCharge then
			net.Start("TTTHChangeCharge")
			net.WriteBool(false)
			net.SendToServer()

			self.sendCharge = nil
		end
	end

	if not hero then -- reset
		hook.Run("TTTHResetHero", self)

		self:SetHeroOptions() -- reset hero options

		self.oldHero = nil
		self.heroAmount = nil
		self.heroTime = nil
		self.heroTimestamp = nil
		self.heroEndless = nil
		self.heroCooldown = nil
		self.heroCooldownTS = nil
		self.prepareActivation = nil
		self.chargingWaiting = nil
	end

	self.hero = hero

	if old ~= hero then
		hook.Run("TTTHUpdateHero", self, old, hero)
	end
end

function plymeta:GetHeroCooldown()
	return self.heroCooldown or 0
end

function plymeta:SetHeroCooldown(heroCooldown)
	self.heroCooldown = heroCooldown
end

function plymeta:GetHeroData()
	return HEROES.GetHeroDataByIndex(self:GetHero())
end

function plymeta:IsHero(hero)
	return self:GetHero() and (not hero or hero and self:GetHero() == hero)
end

function plymeta:SetHeroOptions(opt1, opt2)
	self.heroOpt1 = opt1
	self.heroOpt2 = opt2
end

function plymeta:GetHeroOptions()
	return self.heroOpt1, self.heroOpt2
end

function plymeta:IsHeroActive()
	return self.heroActive or false
end

function plymeta:SetHeroActive(b)
	self.heroActive = b
end

function plymeta:HeroActivate()
	if CLIENT then
		self.chargingWaiting = nil
	else
		net.Start("TTTHResetChargingWaiting")
		net.Send(self)
	end

	self.heroAmount = self.heroAmount or 0

	local hd = self:GetHeroData()

	if not hd or not self:IsActive() or isfunction(hd.checkActivation) and not hd.checkActivation(self) or hd.amount and hd.amount <= self.heroAmount then return end

	if isfunction(hd.onPrepareActivation) and not self.prepareActivation then
		self.prepareActivation = true

		hd.onPrepareActivation(self)

		return
	else
		if isfunction(hd.onFinishPreparingActivation) then
			hd.onFinishPreparingActivation(self)
		end

		self.prepareActivation = nil
	end

	if hd.time ~= 0 then
		self:SetHeroTime(hd.time)
		self:SetHeroEndless(hd.endless)
		self:SetHeroTimestamp(CurTime())

		if SERVER then
			self.savedHeroInventoryItems = table.Copy(self:GetEquipmentItems())

			if not hd.avoidWeaponReset then

				-- reset inventory
				self.savedHeroInventory = {}

				-- save inventory
				for _, v in pairs(self:GetWeapons()) do
					self.savedHeroInventory[#self.savedHeroInventory + 1] = {cls = WEPS.GetClass(v), clip1 = v:Clip1(), clip2 = v:Clip2()}
				end

				self.savedHeroInventoryWeapon = WEPS.GetClass(self:GetActiveWeapon())

				-- take inventory
				self:StripWeapons()
			end

			-- give ability
			self:GiveAbility()
		end

		if hd.onActivate and isfunction(hd.onActivate) then
			hd.onActivate(self)
		end

		if SERVER and not hd.endless then
			local ply = self

			timer.Create("ttth_deactivation_" .. self:UniqueID(), hd.time, 1, function()
				if IsValid(ply) then
					net.Start("TTTHDeactivateHero")
					net.Send(ply)

					ply:HeroDeactivate()
				end
			end)
		end

		self:SetHeroActive(true)
	elseif SERVER then
		net.Start("TTTHDeactivateHero")
		net.Send(self)

		self:HeroDeactivate()
	end

	self.heroAmount = self.heroAmount + 1
end

function plymeta:HeroDeactivate()
	local hd = self:GetHeroData()

	if not hd then return end

	if self.prepareActivation and isfunction(hd.onFinishPreparingActivation) then
		hd.onFinishPreparingActivation(self)

		self.prepareActivation = nil
	end

	self:SetHeroActive(false)

	local cooldown = true

	if SERVER then
		if timer.Exists("ttth_deactivation_" .. self:UniqueID()) then
			timer.Remove("ttth_deactivation_" .. self:UniqueID())
		end

		if self:Alive() and hd.time ~= 0 then
			-- take ability
			self:RemoveAbility()

			-- give inventory
			if self.savedHeroInventory then
				for _, tbl in ipairs(self.savedHeroInventory) do
					if tbl.cls then
						local wep = self:Give(tbl.cls)

						if IsValid(wep) then
							wep:SetClip1(tbl.clip1 or 0)
							wep:SetClip2(tbl.clip2 or 0)
						end
					end
				end
			end

			if self.savedHeroInventoryWeapon then
				self:SelectWeapon(self.savedHeroInventoryWeapon)
			end

			-- reset inventory
			self.savedHeroInventory = nil
			self.savedHeroInventoryItems = nil
		end
	end

	if hd.onDeactivate and isfunction(hd.onDeactivate) then
		cooldown = not hd.onDeactivate(self)
	end

	self.heroTimestamp = nil -- Still used???

	if cooldown and hd.cooldown ~= 0 then
		self:SetHeroCooldown(hd.cooldown)
		self:SetHeroCooldownTS(CurTime())
	end
end

if SERVER then
	function plymeta:UpdateHero(index)
		if self:IsHeroActive() then
			net.Start("TTTHDeactivateHero")
			net.Send(self)

			self:HeroDeactivate()
		end

		self:RemoveAbility()
		self:RemovePassiveHeroEquipment()
		self:SetHero(index)

		net.Start("TTTHSendHero")
		net.WriteUInt(index or 0, HERO_BITS)
		net.Send(self)
	end

	function plymeta:UpdateHeroOptions(opt1, opt2)
		self:SetHeroOptions(opt1, opt2)

		net.Start("TTTHSendHeroOptions")
		net.WriteUInt(opt1 or 0, HERO_BITS)
		net.WriteUInt(opt2 or 0, HERO_BITS)
		net.Send(self)
	end

	function plymeta:GiveHeroWeapon(wep, avoidReset)
		local newWep = wep

		if not newWep then return end

		local rt = self:Give(newWep)
		if IsValid(rt) then
			if not avoidReset then
				self.heroWeapons = self.heroWeapons or {}

				if not table.HasValue(self.heroWeapons, newWep) then
					table.insert(self.heroWeapons, newWep)
				end
			end

			rt:SetNWBool("ttth_hero_weapon", true)

			rt.AllowDrop = false
		end

		return rt
	end

	function plymeta:GiveHeroEquipmentItem(id)
		self:GiveItem(id)

		self.heroItems = self.heroItems or {}

		if not table.HasValue(self.heroItems, id) then
			table.insert(self.heroItems, id)
		end
	end

	function plymeta:GiveServerHeroWeapon(cls, clip1, clip2)
		if not self:IsHero() then return end

		local w = self:GiveHeroWeapon(cls)

		if not IsValid(w) then return end

		if self:HasWeapon(cls) then
			self:AddBought(cls)

			if w.WasBought then
				-- some weapons give extra ammo after being bought, etc
				w:WasBought(self)
			end

			if clip1 then
				w:SetClip1(clip1)
			end

			if clip2 then
				w:SetClip2(clip2)
			end

			timer.Simple(0.5, function()
				if not IsValid(self) then return end

				net.Start("TTT_BoughtItem")
				net.WriteBit(false)
				net.WriteString(cls)
				net.Send(self)
			end)

			hook.Run("TTTOrderedEquipment", self, cls, nil)
		end
	end

	function plymeta:GiveAbility()
		local hd = self:GetHeroData()

		if not hd then return end

		local weaps = hd.weapons
		local itms = hd.items

		if weaps and #weaps > 0 then
			for _, v in ipairs(weaps) do
				self:GiveServerHeroWeapon(v)
			end
		end

		if itms and #itms > 0 then
			for _, v in ipairs(itms) do
				if not self:HasEquipmentItem(v) then -- not had this item
					self:GiveHeroEquipmentItem(v)
				end
			end
		end
	end

	function plymeta:RemoveAbility()
		if self.heroWeapons then
			for _, wep in ipairs(self.heroWeapons) do
				if self:HasWeapon(wep) then
					self:StripWeapon(wep)
				end
			end
		end

		if self.heroItems then
			for _, equip in ipairs(self.heroItems) do
				if not self.savedHeroInventoryItems or not table.HasValue(self.savedHeroInventoryItems, equip) then -- not had this item
					self:RemoveItem(equip)
				end
			end

			self:SendEquipment()
		end

		self.heroWeapons = nil
		self.heroItems = nil
	end

	function plymeta:GivePassiveHeroEquipment()
		local hd = self:GetHeroData()

		if not hd then return end

		local passiveItems = hd.passiveItems
		local passiveWeapons = hd.passiveWeapons

		self.passiveNewItems = {}
		self.passiveNewWeps = {}

		if passiveItems and #passiveItems > 0 then
			for _, v in ipairs(passiveItems) do
				if not self:HasEquipmentItem(v) then -- not had this item
					self:GiveHeroEquipmentItem(v)

					self.passiveNewItems[#self.passiveNewItems + 1] = v
				end
			end
		end

		if passiveWeapons and #passiveWeapons > 0 then
			for _, v in ipairs(passiveWeapons) do
				if not self:HasWeapon(v) then
					self:GiveHeroWeapon(v, true)

					self.passiveNewWeps[#self.passiveNewWeps + 1] = v
				end
			end
		end
	end

	function plymeta:RemovePassiveHeroEquipment()
		local passiveWeapons = self.passiveNewWeps
		local passiveItems = self.passiveNewItems

		if passiveWeapons then
			for _, wep in ipairs(passiveWeapons) do
				if self:HasWeapon(wep) then
					self:StripWeapon(wep)
				end
			end
		end

		self.passiveNewWeps = nil

		-- maybe problems if you have the item already bought
		if passiveItems then
			for _, equip in ipairs(passiveItems) do
				self:RemoveItem(equip)
			end

			self:SendEquipment()
		end

		self.passiveNewItems = nil
	end

	net.Receive("TTTHClientSendHeroes", function(len, ply)
		local hr = net.ReadUInt(HERO_BITS)

		if hr == 0 then
			hr = nil
		end

		if not IsValid(ply) then return end

		ply:UpdateHero(hr)
	end)
else
	net.Receive("TTTHSendHero", function(len)
		local client = LocalPlayer()
		local hr = net.ReadUInt(HERO_BITS)

		if hr == 0 then
			hr = nil
		end

		if not IsValid(client) then return end

		client:SetHero(hr)
	end)

	net.Receive("TTTHSendHeroOptions", function()
		local client = LocalPlayer()
		local opt1 = net.ReadUInt(HERO_BITS)
		local opt2 = net.ReadUInt(HERO_BITS)

		if not IsValid(client) or opt1 == 0 or opt2 == 0 then return end

		client:SetHeroOptions(opt1, opt2)
	end)

	function plymeta:ServerUpdateHeroes(index)
		net.Start("TTTHClientSendHeroes")
		net.WriteUInt(index or 0, HERO_BITS)
		net.SendToServer()
	end
end
