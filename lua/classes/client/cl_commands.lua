local function force_hero(ply, cmd, args, argStr)
	local hero = tonumber(args[1])
	local i = 0

	for _, v in pairs(HEROES.HEROES) do
		i = i + 1
	end

	local hd = HEROES.GetHeroDataByIndex(hero)

	if hd and hero and hero <= i then
		ply:ServerUpdateHeroes(hero)

		ply:ChatPrint("You changed to '" .. hd.name .. "' (hero: " .. hero .. ")")
	end
end
concommand.Add("ttt_force_hero", force_hero, nil, nil, FCVAR_CHEAT)

------------------

local function heroes_index(ply)
	if ply:IsAdmin() then
		ply:ChatPrint("[TTTH] heroes_index...")
		ply:ChatPrint("-----------------")
		ply:ChatPrint("[Hero] | [Index]")

		for _, v in pairs(HEROES.GetSortedHeroes()) do
			ply:ChatPrint(v.name .. " | " .. v.index)
		end

		ply:ChatPrint("----------------")
	end
end
concommand.Add("ttt_heroes_index", heroes_index)

function HEROES.HeroActivate()
	if not GetGlobalBool("ttt2_classes") then return end

	local ply = LocalPlayer()

	if not ply:IsActive() then return end

	if ply.heroOpt1 and GetGlobalBool("ttt_classes_option") then
		net.Start("TTTHChooseHeroOption")
		net.WriteBool(false)
		net.SendToServer()

		ply:SetHeroOptions() -- reset hero options

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
						net.Start("TTTHChangeCharge")
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

			net.Start("TTTHActivateHero")
			net.SendToServer()
		elseif not hd.unstoppable then
			net.Start("TTTHDeactivateHero")
			net.SendToServer()
		end
	end
end
concommand.Add("togglehero", HEROES.HeroActivate, nil, "Activates hero ability", {FCVAR_DONTRECORD})

function HEROES.AbortHero()
	if not GetGlobalBool("ttt2_classes") then return end

	local ply = LocalPlayer()

	if not ply:IsActive() then return end

	if ply.heroOpt2 and GetGlobalBool("ttt_classes_option") then
		net.Start("TTTHChooseHeroOption")
		net.WriteBool(true)
		net.SendToServer()

		ply:SetHeroOptions() -- reset hero options

		return
	end

	if not ply:IsHero() or hook.Run("TTTCPreventClassAbortion", ply) then return end

	if GetRoundState() ~= ROUND_WAIT and ply:IsTerror() then
		local hd = ply:GetHeroData()

		if not hd or hd.deactivated then return end

		net.Start("TTTHAbortHero")
		net.SendToServer()
	end
end
concommand.Add("aborthero", HEROES.AbortHero, nil, "Abort ability preview", {FCVAR_DONTRECORD})

hook.Add("Initialize", "TTTCKeyBinds", function()
	-- Register binding functions
	bind.Register("togglehero", function()
		HEROES.HeroActivate()
	end, nil, "TTT Classes", "Class Ability:", KEY_X)

	bind.Register("aborthero", function()
		HEROES.AbortHero()
	end, nil, "TTT Classes", "Abort ability preview:", KEY_N)

end)