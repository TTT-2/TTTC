CLASSES = {}

if SERVER then
	util.AddNetworkString("TTTCSyncLegacyClasses")
end

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
			deactivated = true
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

	local function EncodeForStream(tbl)
		-- may want to filter out data later
		-- just serialize for now

		local result = util.TableToJSON(tbl)
		if not result then
			ErrorNoHalt("Round report event encoding failed!\n")

			return false
		else
			return result
		end
	end

	hook.Add("PlayerAuthed", "TTTCLegacyClassesSync", function(ply, steamid, uniqueid)
		print("[TTTC] Sending LEGACY CLASSES list to " .. ply:Nick() .. "...")

		local s = EncodeForStream(CLASSES)

		if not s then
			return -- error occurred
		end

		-- divide into happy lil bits.
		-- this was necessary with user messages, now it's
		-- a just-in-case thing if a round somehow manages to be > 64K
		local cut = {}
		local max = 65499

		while #s ~= 0 do
			local bit = string.sub(s, 1, max - 1)

			table.insert(cut, bit)

			s = string.sub(s, max, -1)
		end

		local parts = #cut

		for k, bit in ipairs(cut) do
			net.Start("TTTCSyncLegacyClasses")
			net.WriteBool(true)
			net.WriteBit(k ~= parts) -- continuation bit, 1 if there's more coming
			net.WriteString(bit)

			if ply then
				net.Send(ply)
			else
				net.Broadcast()
			end
		end
	end)

else
	local buff = ""

	net.Receive("TTTCSyncLegacyClasses", function(len)
		print("[TTTC] Received LEGACY CLASSES list from server! Updating...")

		local first = net.ReadBool()
		local cont = net.ReadBit() == 1

		buff = buff .. net.ReadString()

		if cont then
			return
		else
			-- do stuff with buffer contents
			local json_roles = buff -- util.Decompress(buff)

			if not json_roles then
				ErrorNoHalt("[TTTC] LEGACY CLASSES decompression failed!\n")
			else
				-- convert the json string back to a table
				local tmp = util.JSONToTable(json_roles)

				if istable(tmp) then
					CLASSES = tmp
				else
					ErrorNoHalt("[TTTC] LEGACY CLASSES decoding failed!\n")
				end

				-- run client side
				local client = LocalPlayer()

				hook.Run("TTTCPreFinishedClassesSync", client, first)
				hook.Run("TTTCFinishedClassesSync", client, first)
				hook.Run("TTTCPostFinishedClassesSync", client, first)

				ConvertLegacyClasses()
			end

			-- flush
			buff = ""
		end
	end)
end

--legacy player functions
local plymeta = FindMetaTable("Player")

function plymeta:HasCustomClass()
	return self:HasClass() and not hook.Run("TTTCPreventClassActivation", self)
end