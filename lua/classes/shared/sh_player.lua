local plymeta = FindMetaTable("Player")

if not plymeta then return end

AccessorFunc(plymeta, "classTime", "ClassTime", FORCE_NUMBER)
AccessorFunc(plymeta, "classTimestamp", "ClassTimestamp", FORCE_NUMBER)
AccessorFunc(plymeta, "classEndless", "ClassEndless", FORCE_BOOL)
AccessorFunc(plymeta, "classCooldownTS", "ClassCooldownTS", FORCE_NUMBER)

function plymeta:GetCustomClass()
	return self.class
end

function plymeta:SetClass(class)
	local old = self:GetCustomClass()

	if class ~= old then
		local classData = self:GetClassData()

		if classData and self.prepareActivation and isfunction(classData.OnFinishPrepareAbilityActivation) then
			classData.OnFinishPrepareAbilityActivation(self)

			self.prepareActivation = nil
		end

		self.charging = nil
		self.classTime = nil
		self.classTimestamp = nil
		self.classAmount = nil

		if CLIENT and self.sendCharge then
			net.Start("TTTCChangeCharge")
			net.WriteBool(false)
			net.SendToServer()

			self.sendCharge = nil
		end
	end

	if not class then -- reset
		hook.Run("TTTCResetClass", self)

		self:SetClassOptions() -- reset class options

		self.oldClass = nil
		self.classAmount = nil
		self.classTime = nil
		self.classTimestamp = nil
		self.classEndless = nil
		self.classCooldown = nil
		self.classCooldownTS = nil
		self.prepareActivation = nil
		self.chargingWaiting = nil
	end

	self.class = class

	if old ~= class then
		hook.Run("TTTCUpdateClass", self, old, class)

		if old and hook.Run("TTTCPreventClassRemovement", self) ~= true then
			self:RemovePassiveClassEquipment(CLASS.GetClassDataByIndex(old))
		end

		if class and hook.Run("TTTCPreventClassEquipment", self) ~= true then
			self:GivePassiveClassEquipment(CLASS.GetClassDataByIndex(class))
		end
	end

	-- show popup if new class is set
	if CLIENT and class and old ~= class and self == LocalPlayer() and GetGlobalBool("ttt_classes_show_popup", false) then
		local classData = self:GetClassData()

		if classData.lang then
			EPOP:AddMessage(
				{
					text = LANG.TryTranslation("tttc_class_" .. classData.name .. "_name"),
					color = classData.color
				},
				classData.lang.desc and LANG.TryTranslation("tttc_class_" .. classData.name .. "_desc") or nil,
				12
			)
		else
			-- fallback popup for legacy classes
			EPOP:AddMessage(
				{
					text = LANG.TryTranslation(classData.name),
					color = classData.color
				},
				LANG.TryTranslation("ttt2_tttc_class_desc_not_provided"),
				12
			)
		end
	end
end

function plymeta:GetClassCooldown()
	return self.classCooldown or 0
end

function plymeta:SetClassCooldown(classCooldown)
	self.classCooldown = classCooldown
end

function plymeta:GetClassData()
	return CLASS.GetClassDataByIndex(self:GetCustomClass())
end

function plymeta:HasClass(class)
	return self:GetCustomClass() and (not class or class and self:GetCustomClass() == class)
end

function plymeta:SetClassOptions(opt1, opt2)
	self.classOpt1 = opt1
	self.classOpt2 = opt2
end

function plymeta:GetClassOptions()
	return self.classOpt1, self.classOpt2
end

function plymeta:HasClassActive()
	return self.classActive or false
end

function plymeta:SetClassActive(b)
	self.classActive = b
end

function plymeta:ManipulateClassWeapons()
	for _, w in pairs(self:GetWeapons()) do
		if w:GetNWBool("tttc_class_weapon") then
			w.Kind = WEAPON_CLASS

			w.AllowDrop = false
		end
	end
	self.refresh_inventory_cache = true
end

function plymeta:ClassActivate()
	if CLIENT then
		self.chargingWaiting = nil
	else
		net.Start("TTTCResetChargingWaiting")
		net.Send(self)
	end

	self.classAmount = self.classAmount or 0

	local classData = self:GetClassData()

	if not classData or not self:IsActive()
		or isfunction(classData.CheckActivation) and not classData.CheckActivation(self)
		or classData.amount and classData.amount <= self.classAmount
		or self:HasClassActive()
	then return end

	if isfunction(classData.OnStartPrepareAbilityActivation) and not self.prepareActivation then
		self.prepareActivation = true

		classData.OnStartPrepareAbilityActivation(self)

		return
	else
		if isfunction(classData.OnFinishPrepareAbilityActivation) then
			classData.OnFinishPrepareAbilityActivation(self)
		end

		self.prepareActivation = nil
	end

	if classData.time ~= 0 then
		self:SetClassTime(classData.time)
		self:SetClassEndless(classData.endless)
		self:SetClassTimestamp(CurTime())

		if SERVER then
			self.savedClassInventoryItems = table.Copy(self:GetEquipmentItems())

			if not classData.avoidWeaponReset then

				-- reset inventory
				self.savedClassInventory = {}

				-- save inventory
				for _, v in pairs(self:GetWeapons()) do
					self.savedClassInventory[#self.savedClassInventory + 1] = {cls = WEPS.GetClass(v), clip1 = v:Clip1(), clip2 = v:Clip2()}
				end

				self.savedClassInventoryWeapon = WEPS.GetClass(self:GetActiveWeapon())

				-- take inventory
				self:StripWeapons()
			end

			-- give ability
			self:GiveAbility()
		end

		if classData.OnAbilityActivate and isfunction(classData.OnAbilityActivate) then
			classData.OnAbilityActivate(self)
		end

		if SERVER and not classData.endless then
			local ply = self

			timer.Create("tttc_deactivation_" .. self:UniqueID(), classData.time, 1, function()
				if IsValid(ply) then
					net.Start("TTTCDeactivateClass")
					net.Send(ply)

					ply:ClassDeactivate()
				end
			end)
		end

		self:SetClassActive(true)
	elseif SERVER then
		net.Start("TTTCDeactivateClass")
		net.Send(self)

		self:ClassDeactivate()
	end

	self.classAmount = self.classAmount + 1
end

function plymeta:ClassDeactivate()
	local classData = self:GetClassData()

	if not classData then return end

	if self.prepareActivation and isfunction(classData.OnFinishPrepareAbilityActivation) then
		classData.OnFinishPrepareAbilityActivation(self)

		self.prepareActivation = nil
	end

	self:SetClassActive(false)

	if SERVER then
		if timer.Exists("tttc_deactivation_" .. self:UniqueID()) then
			timer.Remove("tttc_deactivation_" .. self:UniqueID())
		end

		if self:Alive() and classData.time ~= 0 then
			-- take ability
			self:RemoveAbility()

			-- give inventory
			if self.savedClassInventory then
				for _, tbl in ipairs(self.savedClassInventory) do
					if not tbl.cls then continue end

					local wep = self:Give(tbl.cls)

					if IsValid(wep) then
						wep:SetClip1(tbl.clip1 or 0)
						wep:SetClip2(tbl.clip2 or 0)
					end
				end
			end

			if self.savedClassInventoryWeapon then
				self:SelectWeapon(self.savedClassInventoryWeapon)
			end

			-- reset inventory
			self.savedClassInventory = nil
			self.savedClassInventoryItems = nil
		end

		local cooldown = true

		if isfunction(classData.OnAbilityDeactivate) then
			cooldown = not classData.OnAbilityDeactivate(self)
		end

		self.classTimestamp = nil

		if cooldown and classData.cooldown ~= 0 then
			self:SetClassCooldown(classData.cooldown)
			self:SetClassCooldownTS(CurTime())
			self:SyncClassState()
		end

		return
	end

	if isfunction(classData.OnAbilityDeactivate) then
		classData.OnAbilityDeactivate(self)
	end
end

function plymeta:GivePassiveClassEquipment(classData)
	classData = classData or self:GetClassData()
	if not classData then return end

	if classData.OnSet and isfunction(classData.OnSet) then
		classData.OnSet(self)
	end

	if CLIENT then return end

	local passiveItems = classData.passiveItems
	local passiveWeapons = classData.passiveWeapons

	self.passiveNewItems = {}
	self.passiveNewWeps = {}

	if passiveItems and #passiveItems > 0 then
		for _, v in ipairs(passiveItems) do
			if not self:HasEquipmentItem(v) then -- not had this item
				self:GiveClassEquipmentItem(v)

				self.passiveNewItems[#self.passiveNewItems + 1] = v
			end
		end
	end

	if passiveWeapons and #passiveWeapons > 0 then
		for _, v in ipairs(passiveWeapons) do
			if not self:HasWeapon(v) then
				self:GiveClassWeapon(v, true)

				self.passiveNewWeps[#self.passiveNewWeps + 1] = v
			end
		end
	end

	if GetGlobalBool("ttt_classes_extraslot") then
		self:ManipulateClassWeapons()
		timer.Simple(0.1, function()
			net.Start("TTTCManipulateClassWeapons")
			net.Send(self)
		end)
	end
end

function plymeta:RemovePassiveClassEquipment(classData)
	classData = classData or self:GetClassData()

	if classData and classData.OnUnset and isfunction(classData.OnUnset) then
		classData.OnUnset(self)
	end

	if CLIENT then return end

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

if SERVER then
	function plymeta:UpdateClass(index)
		if self:HasClassActive() then
			net.Start("TTTCDeactivateClass")
			net.Send(self)

			self:ClassDeactivate()
		end

		self:RemoveAbility()
		self:SetClass(index)
		self.charging = nil

		net.Start("TTTCSendClass")
		net.WriteUInt(index or 0, CLASS_BITS)
		net.Send(self)
	end

	function plymeta:UpdateClassOptions(opt1, opt2)
		self:SetClassOptions(opt1, opt2)

		net.Start("TTTCSendClassOptions")
		net.WriteUInt(opt1 or 0, CLASS_BITS)
		net.WriteUInt(opt2 or 0, CLASS_BITS)
		net.Send(self)
	end

	function plymeta:GiveClassWeapon(wep, avoidReset)
		local newWep = wep

		if not newWep then return end

		local rt = self:Give(newWep)
		if IsValid(rt) then
			if not avoidReset then
				self.classWeapons = self.classWeapons or {}

				if not table.HasValue(self.classWeapons, newWep) then
					table.insert(self.classWeapons, newWep)
				end
			end

			rt:SetNWBool("tttc_class_weapon", true)
		end

		return rt
	end

	function plymeta:GiveClassEquipmentItem(id)
		self:GiveItem(id)

		self.classItems = self.classItems or {}

		if not table.HasValue(self.classItems, id) then
			table.insert(self.classItems, id)
		end
	end

	function plymeta:GiveServerClassWeapon(cls, clip1, clip2)
		if not self:HasClass() then return end

		local w = self:GiveClassWeapon(cls)

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
		local classData = self:GetClassData()

		if not classData then return end

		local weaps = classData.weapons
		local itms = classData.items

		if weaps and #weaps > 0 then
			for _, v in ipairs(weaps) do
				self:GiveServerClassWeapon(v)
			end
		end

		if itms and #itms > 0 then
			for _, v in ipairs(itms) do
				if not self:HasEquipmentItem(v) then -- not had this item
					self:GiveClassEquipmentItem(v)
				end
			end
		end
	end

	function plymeta:RemoveAbility()
		if self.classWeapons then
			for _, wep in ipairs(self.classWeapons) do
				if self:HasWeapon(wep) then
					self:StripWeapon(wep)
				end
			end
		end

		if self.classItems then
			for _, equip in ipairs(self.classItems) do
				if not self.savedClassInventoryItems or not table.HasValue(self.savedClassInventoryItems, equip) then -- not had this item
					self:RemoveItem(equip)
				end
			end

			self:SendEquipment()
		end

		self.classWeapons = nil
		self.classItems = nil
	end

	function plymeta:SyncClassState()
		net.Start("TTTCSyncClassState")
		net.WriteInt(self.classAmount or 0, 8)
		net.WriteFloat(self.classCooldown or 0)
		net.WriteFloat(self.classCooldownTS or 0)
		net.Send(self)
	end

	net.Receive("TTTCClientSendClasses", function(len, ply)
		local hr = net.ReadUInt(CLASS_BITS)

		if hr == 0 then
			hr = nil
		end

		if not IsValid(ply) then return end

		ply:UpdateClass(hr)
	end)
else
	net.Receive("TTTCSendClass", function(len)
		local client = LocalPlayer()
		local hr = net.ReadUInt(CLASS_BITS)

		if hr == 0 then
			hr = nil
		end

		if not IsValid(client) then return end

		client:SetClass(hr)
	end)

	net.Receive("TTTCSyncClassState", function()
		local client = LocalPlayer()
		local classAmount = net.ReadInt(8)
		local classCooldown = net.ReadFloat()
		local classCooldownTS = net.ReadFloat()

		client.classAmount = classAmount
		client:SetClassCooldown(classCooldown)
		client:SetClassCooldownTS(classCooldownTS)
	end)

	net.Receive("TTTCSendClassOptions", function()
		local client = LocalPlayer()
		local opt1 = net.ReadUInt(CLASS_BITS)
		local opt2 = net.ReadUInt(CLASS_BITS)

		if not IsValid(client) or opt1 == 0 or opt2 == 0 then return end

		client:SetClassOptions(opt1, opt2)
	end)

	net.Receive("TTTCManipulateClassWeapons", function()
		LocalPlayer():ManipulateClassWeapons()
	end)

	function plymeta:ServerUpdateClasses(index)
		net.Start("TTTCClientSendClasses")
		net.WriteUInt(index or 0, CLASS_BITS)
		net.SendToServer()
	end
end
