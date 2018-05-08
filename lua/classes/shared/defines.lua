CLASS_BITS = 10

REGISTERED_WEAPONS = {}

CreateConVar("ttt_customclasses_enabled", "1", FCVAR_NOTIFY + FCVAR_ARCHIVE)
CreateConVar("ttt_customclasses_limited", "1", FCVAR_NOTIFY + FCVAR_ARCHIVE)
CreateConVar("tttc_traitorbuy", "0", FCVAR_NOTIFY + FCVAR_ARCHIVE + FCVAR_REPLICATED)

if SERVER then
    util.AddNetworkString("TTTCSendCustomClass")
    util.AddNetworkString("TTTCSyncCustomClasses")
    util.AddNetworkString("TTTCCustomClassesSynced")
    util.AddNetworkString("TTTCDropClass")
    util.AddNetworkString("TTTCSyncClassWeapon")
    util.AddNetworkString("TTTCSyncClassItem")
end
