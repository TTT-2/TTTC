CLASS_BITS = 10

REGISTERED_WEAPONS = {}

local sharedFlag = {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}
local flag = {FCVAR_NOTIFY, FCVAR_ARCHIVE}

CreateConVar("ttt_customclasses_enabled", "1", flag)
CreateConVar("ttt_customclasses_limited", "1", flag)

CreateConVar("tttc_traitorbuy", "0", sharedFlag)

if SERVER then
    util.AddNetworkString("TTTCSendCustomClass")
    util.AddNetworkString("TTTCSyncCustomClasses")
    util.AddNetworkString("TTTCCustomClassesSynced")
    util.AddNetworkString("TTTCDropClass")
    util.AddNetworkString("TTTCSyncClassWeapon")
    util.AddNetworkString("TTTCSyncClassItem")
end
