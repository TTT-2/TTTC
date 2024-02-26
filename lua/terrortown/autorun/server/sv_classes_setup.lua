resource.AddFile("materials/vgui/ttt/score_logo_heroes.vmt")
resource.AddFile("materials/vgui/ttt/vskin/helpscreen/tttc.vmt")

util.AddNetworkString("TTTCDropClass")
util.AddNetworkString("TTTCSendClass")
util.AddNetworkString("TTTCSendClassOptions")
util.AddNetworkString("TTTCChooseClassOption")
util.AddNetworkString("TTTCClientSendClasses")
util.AddNetworkString("TTTCSyncClasses")
util.AddNetworkString("TTTCSyncClass")
util.AddNetworkString("TTTCSyncClassState")
util.AddNetworkString("TTTCClassesSynced")
util.AddNetworkString("TTTCManipulateClassWeapons")
util.AddNetworkString("TTTCSyncClassWeapon")
util.AddNetworkString("TTTCSyncClassItem")
util.AddNetworkString("TTTCActivateClass")
util.AddNetworkString("TTTCDeactivateClass")
util.AddNetworkString("TTTCAbortClass")
util.AddNetworkString("TTTCChangeCharge")
util.AddNetworkString("TTTCResetChargingWaiting")
util.AddNetworkString("TTTCUpdateScoreboard")

local ttt2_classes = CreateConVar("ttt2_classes", "1", { FCVAR_NOTIFY, FCVAR_ARCHIVE })
local ttt_classes_random =
    CreateConVar("ttt_classes_random", "100", { FCVAR_NOTIFY, FCVAR_ARCHIVE })
local ttt_classes_limited =
    CreateConVar("ttt_classes_limited", "1", { FCVAR_NOTIFY, FCVAR_ARCHIVE })
local ttt_classes_different =
    CreateConVar("ttt_classes_different", "0", { FCVAR_NOTIFY, FCVAR_ARCHIVE })
local ttt_classes_option = CreateConVar("ttt_classes_option", "1", { FCVAR_NOTIFY, FCVAR_ARCHIVE })
local ttt_classes_extraslot =
    CreateConVar("ttt_classes_extraslot", "1", { FCVAR_NOTIFY, FCVAR_ARCHIVE })
local ttt_classes_keep_on_respawn =
    CreateConVar("ttt_classes_keep_on_respawn", "1", { FCVAR_NOTIFY, FCVAR_ARCHIVE })
local ttt_classes_show_popup =
    CreateConVar("ttt_classes_show_popup", "1", { FCVAR_NOTIFY, FCVAR_ARCHIVE })
local ttt_classes_sync_team =
    CreateConVar("ttt_classes_sync_team", "1", { FCVAR_NOTIFY, FCVAR_ARCHIVE })

-- ConVar syncing
hook.Add("TTT2SyncGlobals", "AddClassesGlobals", function()
    SetGlobalBool(ttt2_classes:GetName(), ttt2_classes:GetBool())
    SetGlobalInt(ttt_classes_random:GetName(), ttt_classes_random:GetInt())
    SetGlobalBool(ttt_classes_limited:GetName(), ttt_classes_limited:GetBool())
    SetGlobalInt(ttt_classes_different:GetName(), ttt_classes_different:GetInt())
    SetGlobalBool(ttt_classes_option:GetName(), ttt_classes_option:GetBool())
    SetGlobalBool(ttt_classes_extraslot:GetName(), ttt_classes_extraslot:GetBool())
    SetGlobalBool(ttt_classes_keep_on_respawn:GetName(), ttt_classes_keep_on_respawn:GetBool())
    SetGlobalBool(ttt_classes_show_popup:GetName(), ttt_classes_show_popup:GetBool())
    SetGlobalBool(ttt_classes_sync_team:GetName(), ttt_classes_sync_team:GetBool())
end)

cvars.AddChangeCallback(ttt2_classes:GetName(), function(name, old, new)
    SetGlobalBool(name, tobool(new))

    net.Start("TTTCUpdateScoreboard")
    net.WriteBool(tobool(new))
    net.Broadcast()
end, "TTT2ClassesCVSyncingToggled")

cvars.AddChangeCallback(ttt_classes_random:GetName(), function(name, old, new)
    SetGlobalInt(name, tonumber(new))
end, "TTT2ClassesCVSyncingRandom")

cvars.AddChangeCallback(ttt_classes_limited:GetName(), function(name, old, new)
    SetGlobalBool(name, tobool(new))
end, "TTT2ClassesCVSyncingLimited")

cvars.AddChangeCallback(ttt_classes_different:GetName(), function(name, old, new)
    SetGlobalInt(name, tonumber(new))
end, "TTT2ClassesCVSyncingDifferent")

cvars.AddChangeCallback(ttt_classes_option:GetName(), function(name, old, new)
    SetGlobalBool(name, tobool(new))
end, "TTT2ClassesCVSyncingOptions")

cvars.AddChangeCallback(ttt_classes_extraslot:GetName(), function(name, old, new)
    SetGlobalBool(name, tobool(new))
end, "TTT2ClassesCVSyncingExtraslot")

cvars.AddChangeCallback(ttt_classes_keep_on_respawn:GetName(), function(name, old, new)
    SetGlobalBool(name, tobool(new))
end, "TTT2ClassesCVSyncingRespawn")

cvars.AddChangeCallback(ttt_classes_show_popup:GetName(), function(name, old, new)
    SetGlobalBool(name, tobool(new))
end, "TTT2ClassesCVSyncingPopup")

cvars.AddChangeCallback(ttt_classes_sync_team:GetName(), function(name, old, new)
    SetGlobalBool(name, tobool(new))
end, "TTT2ClassesCVSyncingTeamSync")
