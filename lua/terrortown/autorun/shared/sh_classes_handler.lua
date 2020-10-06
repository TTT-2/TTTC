CLASS = CLASS or {}
CLASS.CLASSES = CLASS.CLASSES or {}
CLASS.AVAILABLECLASSES = CLASS.AVAILABLECLASSES or {}
CLASS.FREECLASSES = CLASS.FREECLASSES or {}

CLASS_BITS = 10

COLOR_CLASS = Color(255, 155, 0, 255)
CLASS_TIME = 60
CLASS_COOLDOWN = 60

TTTC = true

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

	-- COMPATIBILITY WITH DEPRECATED NAMES
	classData.OnSet = classData.OnSet or classData.onClassSet
	classData.onClassSet = nil
	classData.OnUnset = classData.OnUnset or classData.onClassUnset
	classData.onClassUnset = nil
	classData.OnAbilityActivate = classData.OnAbilityActivate or classData.onActivate
	classData.onActivate = nil
	classData.OnAbilityDeactivate = classData.OnAbilityDeactivate or classData.onDeactivate
	classData.onDeactivate = nil
	classData.OnStartPrepareAbilityActivation = classData.OnStartPrepareAbilityActivation or classData.onPrepareActivation
	classData.onPrepareActivation = nil
	classData.OnFinishPrepareAbilityActivation = classData.OnFinishPrepareAbilityActivation or classData.onFinishPreparingActivation
	classData.onFinishPreparingActivation = nil
	classData.OnCharge = classData.OnCharge or classData.onCharge
	classData.onCharge = nil
	classData.CheckActivation = classData.CheckActivation or classData.checkActivation
	classData.checkActivation = nil
	-- END COMPATIBILITY

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
	local TryT

	function CLASS.GetClassTranslation(classData)
		TryT = TryT or LANG.TryTranslation

		if not classData then
			return "- " .. TryT("ttt2_tttc_class_unknown") .. " -"
		end

		if classData.lang then
			return TryT("tttc_class_" .. classData.name .. "_name")
		end

		return TryT(classData.name)
	end
end
