CLASS_BITS = 10

COLOR_CLASS = Color(255, 155, 0, 255)
CLASS_TIME = 60
CLASS_COOLDOWN = 60

TTTC = true

if SERVER then
	util.AddNetworkString("TTTCDropClass")
	util.AddNetworkString("TTTCSendClass")
	util.AddNetworkString("TTTCSendClassOptions")
	util.AddNetworkString("TTTCChooseClassOption")
	util.AddNetworkString("TTTCClientSendClasses")
	util.AddNetworkString("TTTCSyncClasses")
	util.AddNetworkString("TTTCSyncClass")
	util.AddNetworkString("TTTCClassesSynced")
	util.AddNetworkString("TTTCManipulateClassWeapons")
	util.AddNetworkString("TTTCSyncClassWeapon")
	util.AddNetworkString("TTTCSyncClassItem")
	util.AddNetworkString("TTTCActivateClass")
	util.AddNetworkString("TTTCDeactivateClass")
	util.AddNetworkString("TTTCAbortClass")
	util.AddNetworkString("TTTCChangeCharge")
	util.AddNetworkString("TTTCResetChargingWaiting")

	local ttt2_classes = CreateConVar("ttt2_classes", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
	local ttt_classes_limited = CreateConVar("ttt_classes_limited", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
	local ttt_classes_option = CreateConVar("ttt_classes_option", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
	local ttt_classes_extraslot = CreateConVar("ttt_classes_extraslot", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})

	-- ConVar syncing
	hook.Add("TTT2SyncGlobals", "AddClassesGlobals", function()
		SetGlobalBool(ttt2_classes:GetName(), ttt2_classes:GetBool())
		SetGlobalBool(ttt_classes_limited:GetName(), ttt_classes_limited:GetBool())
		SetGlobalBool(ttt_classes_option:GetName(), ttt_classes_option:GetBool())
		SetGlobalBool(ttt_classes_extraslot:GetName(), ttt_classes_extraslot:GetBool())
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

	cvars.AddChangeCallback(ttt_classes_extraslot:GetName(), function(name, old, new)
		SetGlobalBool(name, tobool(new))
	end, "TTT2ClassesCVSyncingExtraslot")
end
