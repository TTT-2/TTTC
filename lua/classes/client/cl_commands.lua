local function force_class(ply, cmd, args, argStr)
	local class = tonumber(args[1])
	local i = 0

	for _, v in pairs(CLASS.CLASSES) do
		i = i + 1
	end

	local hd = CLASS.GetClassDataByIndex(class)

	if hd and class and class <= i then
		ply:ServerUpdateClasses(class)

		ply:ChatPrint("You changed to '" .. hd.name .. "' (class: " .. class .. ")")
	end
end
concommand.Add("ttt_force_class", force_class, nil, nil, FCVAR_CHEAT)

------------------

local function classes_index(ply)
	if ply:IsAdmin() then
		ply:ChatPrint("[TTTC] classes_index...")
		ply:ChatPrint("-----------------")
		ply:ChatPrint("[Class] | [Index]")

		for _, v in pairs(CLASS.GetSortedClasses()) do
			ply:ChatPrint(v.name .. " | " .. v.index)
		end

		ply:ChatPrint("----------------")
	end
end
concommand.Add("ttt_classes_index", classes_index)

function CLASS.ClassActivate()
	if not GetGlobalBool("ttt2_classes") then return end

	local ply = LocalPlayer()

	if not ply:IsActive() then return end

	if ply.classOpt1 and GetGlobalBool("ttt_classes_option") then
		net.Start("TTTCChooseClassOption")
		net.WriteBool(false)
		net.SendToServer()

		ply:SetClassOptions() -- reset class options

		return
	end

	if not ply:HasClass() or hook.Run("TTTCPreventClassActivation", ply) then return end

	if GetRoundState() ~= ROUND_WAIT and ply:IsTerror() then
		local hd = ply:GetClassData()

		if not hd or hd.deactivated then return end

		local time = CurTime()

		if ply:GetClassCooldownTS() and ply:GetClassCooldownTS() + ply:GetClassCooldown() > time then return end

		if not ply:HasClassActive() then
			local charging = hd.charging

			-- TODO ability preview?
			if charging then
				if ply.charging and ply.charging + charging - 1 <= time then
					if ply.sendCharge then
						net.Start("TTTCChangeCharge")
						net.WriteBool(false)
						net.SendToServer()

						ply.sendCharge = nil
					end

					ply.charging = nil
				else
					return
				end
			end

			ply.chargingWaiting = true

			net.Start("TTTCActivateClass")
			net.SendToServer()
		elseif not hd.unstoppable then
			net.Start("TTTCDeactivateClass")
			net.SendToServer()
		end
	end
end
concommand.Add("toggleclass", CLASS.ClassActivate, nil, "Activates class ability", {FCVAR_DONTRECORD})

function CLASS.AbortClass()
	if not GetGlobalBool("ttt2_classes") then return end

	local ply = LocalPlayer()

	if not ply:IsActive() then return end

	if ply.classOpt2 and GetGlobalBool("ttt_classes_option") then
		net.Start("TTTCChooseClassOption")
		net.WriteBool(true)
		net.SendToServer()

		ply:SetClassOptions() -- reset class options

		return
	end

	if not ply:HasClass() or hook.Run("TTTCPreventClassAbortion", ply) then return end

	if GetRoundState() ~= ROUND_WAIT and ply:IsTerror() then
		local hd = ply:GetClassData()

		if not hd or hd.deactivated then return end

		net.Start("TTTCAbortClass")
		net.SendToServer()
	end
end
concommand.Add("abortclass", CLASS.AbortClass, nil, "Abort ability preview", {FCVAR_DONTRECORD})

hook.Add("Initialize", "TTTCKeyBinds", function()
	-- Register binding functions
	bind.Register("toggleclass", function()
		CLASS.ClassActivate()
	end, nil, "TTT2 Classes", "Class Ability:", KEY_X)

	bind.Register("abortclass", function()
		CLASS.AbortClass()
	end, nil, "TTT2 Classes", "Abort ability preview:", KEY_N)
end)