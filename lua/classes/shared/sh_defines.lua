HERO_BITS = 10

COLOR_HERO = Color(255, 155, 0, 255)
HERO_TIME = 60
HERO_COOLDOWN = 60

TTTC = true

if SERVER then
	util.AddNetworkString("TTTCSendHero")
	util.AddNetworkString("TTTCSendHeroOptions")
	util.AddNetworkString("TTTCChooseHeroOption")
	util.AddNetworkString("TTTCClientSendHeroes")
	util.AddNetworkString("TTTCSyncHeroes")
	util.AddNetworkString("TTTCSyncHero")
	util.AddNetworkString("TTTCHeroesSynced")
	util.AddNetworkString("TTTCSyncHeroWeapon")
	util.AddNetworkString("TTTCSyncHeroItem")
	util.AddNetworkString("TTTCActivateHero")
	util.AddNetworkString("TTTCDeactivateHero")
	util.AddNetworkString("TTTCAbortHero")
	util.AddNetworkString("TTTCChangeCharge")
	util.AddNetworkString("TTTCResetChargingWaiting")

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
