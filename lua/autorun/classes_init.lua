if SERVER then
	AddCSLuaFile()

	-- shared files
	AddCSLuaFile("classes/shared/sh_tables.lua")
	AddCSLuaFile("classes/shared/sh_defines.lua")
	AddCSLuaFile("classes/shared/sh_functions.lua")
	AddCSLuaFile("classes/shared/sh_player.lua")
	AddCSLuaFile("classes/shared/sh_hooks.lua")
	AddCSLuaFile("classes/shared/sh_legacy_support.lua")

	-- client files
	AddCSLuaFile("classes/client/cl_commands.lua")
	AddCSLuaFile("classes/client/cl_hud.lua")

	resource.AddFile("materials/vgui/ttt/score_logo_heroes.vmt")
end

local heroPre = "classes/classes/"
local heroFiles = file.Find(heroPre .. "hero_*.lua", "LUA")

for _, fl in ipairs(heroFiles) do
	AddCSLuaFile(heroPre .. fl)
end

include("classes/shared/sh_tables.lua")
include("classes/shared/sh_defines.lua")
include("classes/shared/sh_functions.lua")
include("classes/shared/sh_player.lua")
include("classes/shared/sh_hooks.lua")
include("classes/shared/sh_legacy_support.lua")

if CLIENT then
	include("classes/client/cl_commands.lua")
	include("classes/client/cl_hud.lua")
end

for _, fl in ipairs(heroFiles) do
	include(heroPre .. fl)
end

hook.Add("TTT2HUDUpdated", "TTTCUpdateClassesInfo", function()
	if hudelements then
		local hudInfoElements = hudelements.GetAllTypeElements("tttinfopanel")
		for _, v in ipairs(hudInfoElements) do
			if v.SetSecondaryRoleInfoFunction then
				v:SetSecondaryRoleInfoFunction(function()
					local hd = LocalPlayer():GetClassData()

					if not hd then return end

					return {
						color = hd.color or COLOR_CLASS,
						text = CLASS.GetClassTranslation(hd)
					}
				end)
			end
		end
	else
		Msg("Warning: New HUD module does not seem to be loaded in TTT2Initialize, so we cannot register to custom huds.\n")
	end
end)
