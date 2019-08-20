function HEROES.AddHero(name, heroData, conVarData)
	conVarData = conVarData or {}

	local oldId

	if HEROES.HEROES[name] then
		oldId = HEROES.HEROES[name].index

		HEROES.HEROES[name] = nil
	end

	heroData.name = string.Trim(string.lower(name))

	if SERVER and not oldId then
		CreateConVar("ttth_hero_" .. heroData.name .. "_enabled", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
		CreateConVar("ttth_hero_" .. heroData.name .. "_random", tostring(conVarData.random or 100), {FCVAR_ARCHIVE})
	end

	-- necessary to init heroes in this way, because we need to wait until the HEROES.HEROES array is initialized
	-- and every important function works properly
	local i = oldId or table.Count(HEROES.HEROES) + 1

	heroData.index = i

	-- init hero arrays
	heroData.weapons = heroData.weapons or {}
	heroData.items = heroData.items or {}

	heroData.time = heroData.time or HERO_TIME
	heroData.cooldown = heroData.cooldown or HERO_COOLDOWN
	heroData.endless = heroData.endless or false
	heroData.passive = heroData.passive or false

	if CLIENT and heroData.langs and not oldId then
		hook.Add("TTT2FinishedLoading", "TTTHInitLangFor" .. heroData.name, function()
			if LANG then
				for lang, key in pairs(heroData.langs) do
					LANG.AddToLanguage(lang, heroData.name, key)
				end
			end
		end)
	end

	HEROES.HEROES[name] = heroData

	-- spend an answer
	print("[TTTH][HERO] Added '" .. name .. "' Hero (index: " .. i .. ")")
end

function HEROES.SortHeroesTable(tbl)
	table.sort(tbl, function(a, b)
		return a.index < b.index
	end)
end

function HEROES.GetHeroDataByIndex(index)
	for _, v in pairs(HEROES.HEROES) do
		if v.index == index then
			return v
		end
	end

	return nil
end

function HEROES.GetSortedHeroes()
	local heroes = {}

	for _, v in pairs(HEROES.HEROES) do
		heroes[v.index] = v
	end

	HEROES.SortHeroesTable(heroes)

	return heroes
end

if CLIENT then
	local GetLang

	function HEROES.GetHeroTranslation(hd)
		GetLang = GetLang or LANG.GetRawTranslation

		return GetLang(hd.name) or hd.name or "-UNKNOWN-"
	end
end
