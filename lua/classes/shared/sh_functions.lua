function CLASS.AddClass(name, classData, conVarData)
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

	classData.time = classData.time or CLASS_TIME
	classData.cooldown = classData.cooldown or CLASS_COOLDOWN
	classData.endless = classData.endless or false
	classData.passive = classData.passive or false

	if CLIENT and classData.lang and not oldId then
		hook.Add("TTT2FinishedLoading", "TTTCInitLangFor" .. classData.name, function()
			if not LANG then return end

			for lang, text in pairs(classData.lang.name) do
				LANG.AddToLanguage(lang, "tttc_class_" .. classData.name .. "_name", text)
			end

			for lang, text in pairs(classData.lang.desc) do
				LANG.AddToLanguage(lang, "tttc_class_" .. classData.name .. "_desc", text)
			end
		end)
	end

	CLASS.CLASSES[name] = classData

	-- spend an answer
	print("[TTTC][CLASS] Added '" .. name .. "' Class (index: " .. i .. ")")
end

function CLASS.SortClassesTable(tbl)
	table.sort(tbl, function(a, b)
		return a.index < b.index
	end)
end

function CLASS.GetClassDataByIndex(index)
	for _, v in pairs(CLASS.CLASSES) do
		if v.index == index then
			return v
		end
	end

	return nil
end

function CLASS.GetSortedClasses()
	local classes = {}

	for _, v in pairs(CLASS.CLASSES) do
		classes[v.index] = v
	end

	CLASS.SortClassesTable(classes)

	return classes
end

if CLIENT then
	local GetLang

	function CLASS.GetClassTranslation(hd)
		GetLang = GetLang or LANG.GetRawTranslation

		local classname = hd and (GetLang("tttc_class_" .. hd.name .. "_name") or hd.name)

		return classname and classname or ("- " .. GetLang("ttt2_tttc_class_unknown") .. " -")
	end
end
