CLASS_BITS = 10

CreateConVar("ttt_customclasses_enabled", "1", FCVAR_NOTIFY + FCVAR_ARCHIVE)

if SERVER then
    util.AddNetworkString("TTT2_SendCustomClass")
    util.AddNetworkString("TTT2_SyncCustomClasses")
    util.AddNetworkString("TTT2_CustomClassesSynced")
end
