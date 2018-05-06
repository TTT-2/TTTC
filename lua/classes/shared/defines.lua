CLASS_BITS = 10

WEAPONS_FOR_CLASSES = {}
ITEMS_FOR_CLASSES = {}

REGISTERED_WEAPONS = {}

CreateConVar("ttt_customclasses_enabled", "1", FCVAR_NOTIFY + FCVAR_ARCHIVE)
CreateConVar("ttt_customclasses_limited", "1", FCVAR_NOTIFY + FCVAR_ARCHIVE)
CreateConVar("tttc_traitorbuy", "0", FCVAR_NOTIFY + FCVAR_ARCHIVE)

if SERVER then
    util.AddNetworkString("TTTCSendCustomClass")
    util.AddNetworkString("TTTCSyncCustomClasses")
    util.AddNetworkString("TTTCCustomClassesSynced")
    util.AddNetworkString("TTTCDropClass")
    util.AddNetworkString("TTTCRegisterNewWeapon")
end
