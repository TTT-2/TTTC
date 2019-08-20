local function force_class(ply, cmd, args, argStr)
	local class = tonumber(args[1])
	local i = 0

	for _, v in pairs(CLASS.CLASSES) do
		i = i + 1
	end

	local hd = CLASS.GetHeroDataByIndex(class)

	if hd and class and class <= i then
		ply:ServerUpdateHeroes(class)

		ply:ChatPrint("You changed to '" .. hd.name .. "' (class: " .. class .. ")")
	end
end
concommand.Add("ttt_force_class", force_class, nil, nil, FCVAR_CHEAT)

------------------

local function classes_index(ply)
	if ply:IsAdmin() then
		ply:ChatPrint("[TTTC] classes_index...")
		ply:ChatPrint("-----------------")
		ply:ChatPrint("[Hero] | [Index]")

		for _, v in pairs(CLASS.GetSortedHeroes()) do
			ply:ChatPrint(v.name .. " | " .. v.index)
		end

		ply:ChatPrint("----------------")
	end
end
concommand.Add("ttt_classes_index", classes_index)

function CLASS.HeroActivate()
	if not GetGlobalBool("ttt2_classes") then return end

	local ply = LocalPlayer()

	if not ply:IsActive() then return end

	if ply.classOpt1 and GetGlobalBool("ttt_classes_option") then
		net.Start("TTTCChooseHeroOption")
		net.WriteBool(false)
		net.SendToServer()

		ply:SetHeroOptions() -- reset class options

		return
	end

	if not ply:IsHero() or hook.Run("TTTCPreventClassActivation", ply) then return end

	if GetRoundState() ~= ROUND_WAIT and ply:IsTerror() then
		local hd = ply:GetHeroData()

		if not hd or hd.deactivated then return end

		local time = CurTime()

		if ply:GetHeroCooldownTS() and ply:GetHeroCooldownTS() + ply:GetHeroCooldown() > time then return end

		if not ply:IsHeroActive() then
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

			net.Start("TTTCActivateHero")
			net.SendToServer()
		elseif not hd.unstoppable then
			net.Start("TTTCDeactivateHero")
			net.SendToServer()
		end
	end
end
concommand.Add("toggleclass", CLASS.HeroActivate, nil, "Activates class ability", {FCVAR_DONTRECORD})

function CLASS.AbortHero()
	if not GetGlobalBool("ttt2_classes") then return end

	local ply = LocalPlayer()

	if not ply:IsActive() then return end

	if ply.classOpt2 and GetGlobalBool("ttt_classes_option") then
		net.Start("TTTCChooseHeroOption")
		net.WriteBool(true)
		net.SendToServer()

		ply:SetHeroOptions() -- reset class options

		return
	end

	if not ply:IsHero() or hook.Run("TTTCPreventClassAbortion", ply) then return end

	if GetRoundState() ~= ROUND_WAIT and ply:IsTerror() then
		local hd = ply:GetHeroData()

		if not hd or hd.deactivated then return end

		net.Start("TTTCAbortHero")
		net.SendToServer()
	end
end
concommand.Add("abortclass", CLASS.AbortHero, nil, "Abort ability preview", {FCVAR_DONTRECORD})

hook.Add("Initialize", "TTTCKeyBinds", function()
	-- Register binding functions
	bind.Register("toggleclass", function()
		CLASS.HeroActivate()
	end, nil, "TTT Classes", "Class Ability:", KEY_X)

	bind.Register("abortclass", function()
		CLASS.AbortHero()
	end, nil, "TTT Classes", "Abort ability preview:", KEY_N)

end)