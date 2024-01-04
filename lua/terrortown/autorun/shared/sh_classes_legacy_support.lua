CLASSES = {}

function AddCustomClass(name, classData, conVarData)
	if not CLASSES[name] and SERVER then
		local i = 1 -- start at 1 to directly get free slot

		for _, v in pairs(CLASSES) do
			i = i + 1
		end

		-- init class arrays
		classData.index = i
		classData.weapons = classData.weapons or {}
		classData.items = classData.items or {}

		CLASSES[name] = classData
	end
end

local function ConvertLegacyClasses()
	for name, class in SortedPairs(CLASSES) do
		CLASS.AddClass(name, {
			color = class.color or COLOR_WHITE,
			name = string.lower(name),
			passiveWeapons = table.Copy(class.weapons),
			passiveItems = table.Copy(class.items),
			passive = true,
			deactivated = true,
			isLegacyClass = true
		})

		class.index = CLASS.CLASSES[name].index

		print("[TTTC] LEGACY CLASS Converted '" .. name .. "' Class (index: " .. class.index .. "). Please consider reworking this class!")
	end
end

if SERVER then
	hook.Add("PostInitialize", "TTTCLegacyInitHooks", function()
		hook.Run("TTTCPreClassesInit")
		hook.Run("TTTCClassesInit")

		ConvertLegacyClasses()

		hook.Run("TTTCPostClassesInit")
	end)

	hook.Add("PlayerAuthed", "TTTCLegacyClassesSync", function(ply)
		print("[TTTC] Sending LEGACY CLASSES list to " .. ply:Nick() .. "...")

		net.SendStream("TTTCSyncLegacyClasses", CLASSES, ply)
	end)

	hook.Add("OnReloaded", "TTTCLegacyClassesSyncOnReload", function()
		local plys = player.GetAll()

		for i = 1, #plys do
			local ply = plys[i]

			print("[TTTC] Sending LEGACY CLASSES list to " .. ply:Nick() .. "...")

			net.SendStream("TTTCSyncLegacyClasses", CLASSES, ply)
		end
	end)

else
	net.ReceiveStream("TTTCSyncLegacyClasses", function(streamData)
		print("[TTTC] Received LEGACY CLASSES list from server! Updating...")

		CLASSES = streamData

		-- run client side
		local client = LocalPlayer()

		hook.Run("TTTCPreFinishedClassesSync", client, first)
		hook.Run("TTTCFinishedClassesSync", client, first)
		hook.Run("TTTCPostFinishedClassesSync", client, first)

		ConvertLegacyClasses()
	end)
end

--legacy player functions
local plymeta = FindMetaTable("Player")

function plymeta:HasCustomClass()
	return self:HasClass() and not hook.Run("TTTCPreventClassActivation", self)
end
