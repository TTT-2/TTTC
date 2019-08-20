HERO_BITS = 10

COLOR_HERO = Color(255, 155, 0, 255)
HERO_TIME = 60
HERO_COOLDOWN = 60

TTTC = true

if SERVER then
	util.AddNetworkString("TTTHSendHero")
	util.AddNetworkString("TTTHSendHeroOptions")
	util.AddNetworkString("TTTHChooseHeroOption")
	util.AddNetworkString("TTTHClientSendHeroes")
	util.AddNetworkString("TTTHSyncHeroes")
	util.AddNetworkString("TTTHSyncHero")
	util.AddNetworkString("TTTHHeroesSynced")
	util.AddNetworkString("TTTHSyncHeroWeapon")
	util.AddNetworkString("TTTHSyncHeroItem")
	util.AddNetworkString("TTTHActivateHero")
	util.AddNetworkString("TTTHDeactivateHero")
	util.AddNetworkString("TTTHAbortHero")
	util.AddNetworkString("TTTHChangeCharge")
	util.AddNetworkString("TTTHResetChargingWaiting")

	local ttt2_classes = CreateConVar("ttt2_classes", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
	local ttt_classes_limited = CreateConVar("ttt_classes_limited", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
	local ttt_classes_option = CreateConVar("ttt_classes_option", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})

	-- ConVar syncing
	hook.Add("TTT2SyncGlobals", "AddHeroesGlobals", function()
		SetGlobalBool(ttt2_classes:GetName(), ttt2_classes:GetBool())
		SetGlobalBool(ttt_classes_limited:GetName(), ttt_classes_limited:GetBool())
		SetGlobalBool(ttt_classes_option:GetName(), ttt_classes_option:GetBool())
	end)

	cvars.AddChangeCallback(ttt2_classes:GetName(), function(name, old, new)
		SetGlobalBool(name, tobool(new))
	end, "TTT2ClassesCVSyncingToggled")

	cvars.AddChangeCallback(ttt_classes_limited:GetName(), function(name, old, new)
		SetGlobalBool(name, tobool(new))
	end, "TTT2ClassesCVSyncingLimited")

	cvars.AddChangeCallback(ttt_classes_option:GetName(), function(name, old, new)
		SetGlobalBool(name, tobool(new))
	end, "TTT2ClassesCVSyncingOptions")
end
