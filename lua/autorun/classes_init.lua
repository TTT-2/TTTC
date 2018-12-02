if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("classes/cl_init.lua")

	-- shared files
	AddCSLuaFile("classes/shared/tables.lua")
	AddCSLuaFile("classes/shared/defines.lua")
	AddCSLuaFile("classes/shared/functions.lua")
	AddCSLuaFile("classes/shared/player.lua")
	AddCSLuaFile("classes/shared/hooks.lua")
	AddCSLuaFile("classes/shared/commands.lua")

	-- client files
	AddCSLuaFile("classes/client/cl_hud.lua")
	AddCSLuaFile("classes/client/cl_lang.lua")

	-- include main file
	include("classes/init.lua")
else
	-- include main file
	include("classes/cl_init.lua")
end
