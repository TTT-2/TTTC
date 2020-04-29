-- reset (TTTEndRound not triggerd bcus of force restart)
hook.Add("TTTEndRound", "TTTCResetClasses", function()
	if SERVER then
		for _, v in ipairs(player.GetAll()) do
			net.Start("TTTCSyncClass")
			net.WriteEntity(v)
			net.WriteUInt(v:GetCustomClass() or 0, CLASS_BITS)
			net.Broadcast()
		end
	else
		local ply = LocalPlayer()

		ply.classOpt1 = nil
		ply.classOpt2 = nil
	end
end)

-- reset (TTTPrepareRound not triggerd bcus of buggy force restart)
hook.Add("TTTPrepareRound", "TTTCResetClasses", function()
	if SERVER then
		for _, v in ipairs(player.GetAll()) do
			v:UpdateClass(nil)

			v.oldClass = nil
		end
	else
		local ply = LocalPlayer()

		ply.classOpt1 = nil
		ply.classOpt2 = nil
	end
end)

hook.Add("Think", "TTTCThinkCharge", function()
	local plys

	if SERVER then
		plys = player.GetAll()
	else
		plys = {LocalPlayer()}
	end

	for i = 1, #plys do
		local ply = plys[i]

		if not ply:IsActive() or not ply:HasClass() then continue end

		local classData = ply:GetClassData()

		if not classData or not isfunction(classData.OnThink) then continue end

		classData.OnThink(ply)
	end
end)

if SERVER then
	hook.Add("TTTBeginRound", "TTTCSelectClasses", function()
		table.Empty(CLASS.AVAILABLECLASSES)

		if not GetGlobalBool("ttt2_classes") then return end

		local maxEntries = GetGlobalInt("ttt_classes_different")
		local classAmount = table.Count(CLASS.CLASSES)

		local classes = {}

		-- if the amount of available classes is smaller than the amount of classes to
		-- be selected, the class array should be shuffled
		if maxEntries > 0 and classAmount >= maxEntries then
			local num_index = 1
			for _, v in pairs(CLASS.CLASSES) do
				classes[num_index] = v

				num_index = num_index + 1
			end

			table.Shuffle(classes)
		else
			classes = CLASS.CLASSES
		end

		for _, v in pairs(classes) do
			if not GetConVar("tttc_class_" .. v.name .. "_enabled"):GetBool() then continue end

			local b = true
			local r = GetConVar("tttc_class_" .. v.name .. "_random"):GetInt()

			if r > 0 and r < 100 then
				b = math.random(100) <= r
			elseif r <= 0 then
				b = false
			end

			if b then
				local nextEntry = #CLASS.AVAILABLECLASSES + 1

				CLASS.AVAILABLECLASSES[nextEntry] = v

				if maxEntries > 0 and nextEntry >= maxEntries then break end
			end
		end

		if #CLASS.AVAILABLECLASSES == 0 then return end

		table.Empty(CLASS.FREECLASSES)

		if GetGlobalBool("ttt_classes_limited") then
			for _, v in ipairs(CLASS.AVAILABLECLASSES) do
				table.insert(CLASS.FREECLASSES, v)
			end
		end

		for _, v in ipairs(player.GetAll()) do
			if v:IsActive() then
				local hr

				if #CLASS.FREECLASSES == 0 then
					local rand = math.random(#CLASS.AVAILABLECLASSES)

					hr = CLASS.AVAILABLECLASSES[rand].index
				else
					local rand = math.random(#CLASS.FREECLASSES)

					hr = CLASS.FREECLASSES[rand].index

					table.remove(CLASS.FREECLASSES, rand)
				end

				if not GetGlobalBool("ttt_classes_option") then
					v:UpdateClass(hr)
				else
					local opt = hr

					if #CLASS.FREECLASSES == 0 then
						local rand = math.random(#CLASS.AVAILABLECLASSES)

						hr = CLASS.AVAILABLECLASSES[rand].index
					else
						local rand = math.random(#CLASS.FREECLASSES)

						hr = CLASS.FREECLASSES[rand].index

						table.remove(CLASS.FREECLASSES, rand)
					end

					v:UpdateClassOptions(opt, hr)
				end
			end
		end

		hook.Run("TTTCPreReceiveClasses")

		hook.Run("TTTCReceiveClasses")

		hook.Run("TTTCPostReceiveClasses")
	end)

	hook.Add("DoPlayerDeath", "TTTCPostPlayerDeathSave", function(ply)
		ply.oldClass = ply.oldClass or ply:GetCustomClass()
	end)

	hook.Add("PlayerSpawn", "TTTCRemoveClassOnSpawn", function(ply)
		if GetRoundState() == ROUND_ACTIVE then
			local classData = ply:GetClassData()

			if not GetGlobalBool("ttt_classes_keep_on_respawn") or classData and classData.surpressKeepOnRespawn then
				ply:UpdateClass(nil)
			else
				ply:GivePassiveClassEquipment()
				hook.Run("TTTCPlayerRespawnedWithClass", ply)
			end
		end
	end)

	-- sync dead players with other players
	hook.Add("TTTBodyFound", "TTTCBodyFound", function(_, deadply)
		if GetRoundState() == ROUND_ACTIVE and IsValid(deadply) and deadply.oldClass then
			net.Start("TTTCSyncClass")
			net.WriteEntity(deadply)
			net.WriteUInt(deadply.oldClass or 0, CLASS_BITS)
			net.Broadcast()
		end
	end)

	hook.Add("PlayerDroppedWeapon", "TTTCDontDropOnDeath", function(owner, wep)
		if IsValid(wep) and wep:GetNWBool("tttc_class_weapon") then
			wep:Remove()
		end
	end)

	hook.Add("PlayerCanPickupWeapon", "TTTCPickupWeapon", function(ply, wep)
		if IsValid(wep) and wep:GetNWBool("tttc_class_weapon") then
			return true
		elseif ply:HasClass() and ply:HasClassActive() and not ply:GetClassData().avoidWeaponReset then
			return false
		end
	end)

	net.Receive("TTTCChangeCharge", function(len, ply)
		local bool = net.ReadBool()

		if not bool then
			bool = nil
		end

		ply.charging = bool
	end)

	net.Receive("TTTCChooseClassOption", function(len, ply)
		local opt = net.ReadBool()

		local opt1, opt2 = ply:GetClassOptions()

		if not opt then
			ply:UpdateClass(opt1)
		else
			ply:UpdateClass(opt2)
		end

		ply:SetClassOptions() -- reset class options
	end)

	net.Receive("TTTCDropClass", function(len, ply)
		hook.Run("TTTCDropClass", ply)

		ply:UpdateClass(nil)

		ply.oldClass = nil
	end)

	hook.Add("PlayerSay", "TTTCClassCommands", function(ply, text, public)
		text = string.Trim(string.lower(text))

		if text == "!dropclass" then
			ply:ConCommand("dropclass")

			return ""
		end
	end)
end

hook.Add("TTTPrepareRound", "TTTCResetClasses", function()
	for _, v in ipairs(player.GetAll()) do
		v:SetClass(nil)

		v.oldClass = nil
	end
end)

if CLIENT then
	net.Receive("TTTCSyncClass", function(len)
		local ply = net.ReadEntity()
		local hr = net.ReadUInt(CLASS_BITS)

		if hr == 0 then
			hr = nil
		end

		if not ply.SetClass then return end

		ply:SetClass(hr)

		ply.oldClass = hr
	end)

	hook.Add("TTTScoreboardColumns", "TTTCScoreboardClass", function(pnl)
		if not GetGlobalBool("ttt2_classes") then return end

		pnl:AddColumn("Class", function(ply, label)
			if ply:HasClass() then
				local classData = ply:GetClassData()

				label:SetColor(classData.color or COLOR_CLASS)

				return CLASS.GetClassTranslation(classData)
			elseif ply.oldClass then
				local classData = CLASS.GetClassDataByIndex(ply.oldClass)
				if classData then
					label:SetColor(classData.color or COLOR_CLASS)

					return CLASS.GetClassTranslation(classData)
				end
			elseif not ply:IsActive() and ply:GetNWBool("body_found") then
				return "-" -- died without any class
			end

			label:SetColor(Color(255, 255, 255))

			return "?"
		end, 100)
	end)

	local function ThinkCharge()
		local ply = LocalPlayer()

		if not ply:IsActive() or not ply:HasClass() then return end

		local classData = ply:GetClassData()

		if not classData then return end

		local charging = classData.charging
		local time = CurTime()

		if classData.deactivated
			or ply:HasClassActive()
			or not (not ply:GetClassCooldownTS() or ply:GetClassCooldownTS() + ply:GetClassCooldown() <= time)
			or not charging
			or ply.chargingWaiting
			or hook.Run("TTTCPreventCharging", ply)
		then return end

		local abilityKey = bind.Find("toggleclass")

		if abilityKey ~= KEY_NONE then
			local disabled = false

			if isfunction(classData.OnCharge) and not classData.OnCharge(ply) then
				disabled = true
			else
				local btnDown = input.IsButtonDown(abilityKey)

				if btnDown and not ply.charging then
					ply.charging = time

					if not ply.sendCharge then
						net.Start("TTTCChangeCharge")
						net.WriteBool(true)
						net.SendToServer()

						ply.sendCharge = true
					end
				elseif not btnDown and ply.charging then
					disabled = true
				end
			end

			if disabled then
				ply.charging = nil

				if ply.sendCharge then
					net.Start("TTTCChangeCharge")
					net.WriteBool(false)
					net.SendToServer()

					ply.sendCharge = nil
				end
			elseif ply.charging and ply.charging + charging - 1 <= time then
				CLASS.ClassActivate()
			end
		end
	end
	hook.Add("Think", "TTTCThinkCharge", ThinkCharge)

	net.Receive("TTTCUpdateScoreboard", function()
		-- set the value to the global bool manually because the update of
		-- the global bool might come with a delay
		SetGlobalBool("ttt2_classes", net.ReadBool() or false)

		GAMEMODE:ScoreboardCreate()
		GAMEMODE:ScoreboardHide()
	end)
end

-- shared because it is predicted
hook.Add("TTTPlayerSpeedModifier", "ClassChargingModifySpeed", function(ply, _, _, refTbl)
	if not IsValid(ply) or not ply.charging then return end

	refTbl[1] = refTbl[1] * 0.5
end)

-- handle class removal on death / disconnect
if SERVER then
	local function ClassDeinit(ply)
		if not IsValid(ply) or not ply:HasClassActive() then return end

		-- handle class deactivation
		ply:ClassDeactivate()

		-- do it on the client as well
		net.Start("TTTCDeactivateClass")
		net.Send(ply)

		-- handle class abort
		local classData = ply:GetClassData()

		if ply.prepareActivation and isfunction(classData.OnFinishPrepareAbilityActivation) then
			classData.OnFinishPrepareAbilityActivation(ply)

			ply.prepareActivation = nil
		end

		-- do it on the client as well
		net.Start("TTTCAbortClass")
		net.Send(ply)
	end

	hook.Add("PlayerDeath", "TTTC_deinit_death", ClassDeinit)
	hook.Add("PlayerDisconnected", "TTTC_deinit_disconnect", ClassDeinit)
end

net.Receive("TTTCActivateClass", function(len, ply)
	local reset = false

	if not GetGlobalBool("ttt2_classes") then
		reset = true
	end

	ply = ply or LocalPlayer()

	if not IsValid(ply) then
		reset = true
	end

	local classData = ply:GetClassData()

	if not classData or classData.deactivated or not ply:IsActive() or ply:GetClassCooldownTS() and ply:GetClassCooldownTS() + ply:GetClassCooldown() > CurTime() or hook.Run("TTTCPreventClassActivation", ply) then
		reset = true
	end

	if not reset then
		ply:ClassActivate()

		if SERVER then
			net.Start("TTTCActivateClass")
			net.Send(ply)
		end
	elseif SERVER then
		net.Start("TTTCResetChargingWaiting")
		net.Send(ply)
	end
end)

if CLIENT then
	net.Receive("TTTCResetChargingWaiting", function(len)
		LocalPlayer().chargingWaiting = nil
	end)
end

local addons_devs = {
	["76561198049831089"] = true,
	["76561198058039701"] = true,
	["76561198047819379"] = true
}

if CLIENT then
	hook.Add("TTT2ScoreboardAddPlayerRow", "TTT2AddClassesDevs", function(ply)
		local tsid64 = ply:SteamID64()

		if addons_devs[tostring(tsid64)] then
			AddTTT2AddonDev(tsid64)
		end
	end)
end

net.Receive("TTTCDeactivateClass", function(len, ply)
	ply = ply or LocalPlayer()

	if not IsValid(ply) then return end

	ply:ClassDeactivate()

	if SERVER then
		net.Start("TTTCDeactivateClass")
		net.Send(ply)
	end
end)

net.Receive("TTTCAbortClass", function(len, ply)
	ply = ply or LocalPlayer()

	if not IsValid(ply) then return end

	local classData = ply:GetClassData()

	if ply.prepareActivation and isfunction(classData.OnFinishPrepareAbilityActivation) then
		classData.OnFinishPrepareAbilityActivation(ply)

		ply.prepareActivation = nil
	end

	if SERVER then
		net.Start("TTTCAbortClass")
		net.Send(ply)
	end
end)
