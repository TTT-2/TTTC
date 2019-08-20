function CLASS.AddHero(name, classData, conVarData)
	conVarData = conVarData or {}

	local oldId

	if CLASS.CLASSES[name] then
		oldId = CLASS.CLASSES[name].index

		CLASS.CLASSES[name] = nil
	end

	classData.name = string.Trim(string.lower(name))

	if SERVER and not oldId then
		CreateConVar("tttc_class_" .. classData.name .. "_enabled", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
		CreateConVar("tttc_class_" .. classData.name .. "_random", tostring(conVarData.random or 100), {FCVAR_ARCHIVE})
	end

	-- necessary to init classes in this way, because we need to wait until the CLASS.CLASSES array is initialized
	-- and every important function works properly
	local i = oldId or table.Count(CLASS.CLASSES) + 1

	classData.index = i

	-- init class arrays
	classData.weapons = classData.weapons or {}
	classData.items = classData.items or {}

	classData.time = classData.time or HERO_TIME
	classData.cooldown = classData.cooldown or HERO_COOLDOWN
	classData.endless = classData.endless or false
	classData.passive = classData.passive or false

	if CLIENT and classData.langs and not oldId then
		hook.Add("TTT2FinishedLoading", "TTTHInitLangFor" .. classData.name, function()
			if LANG then
				for lang, key in pairs(classData.langs) do
					LANG.AddToLanguage(lang, classData.name, key)
				end
			end
		end)
	end

	CLASS.CLASSES[name] = classData

	-- spend an answer
	print("[TTTH][HERO] Added '" .. name .. "' Hero (index: " .. i .. ")")
end

function CLASS.SortHeroesTable(tbl)
	table.sort(tbl, function(a, b)
		return a.index < b.index
	end)
end

function CLASS.GetHeroDataByIndex(index)
	for _, v in pairs(CLASS.CLASSES) do
		if v.index == index then
			return v
		end
	end

	return nil
end

function CLASS.GetSortedHeroes()
	local classes = {}

	for _, v in pairs(CLASS.CLASSES) do
		classes[v.index] = v
	end

	CLASS.SortHeroesTable(classes)

	return classes
end

if CLIENT then
	local GetLang

	function CLASS.GetHeroTranslation(hd)
		GetLang = GetLang or LANG.GetRawTranslation

		return GetLang(hd.name) or hd.name or "-UNKNOWN-"
	end
end
