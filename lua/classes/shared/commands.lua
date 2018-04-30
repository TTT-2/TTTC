function DropClass(ply)
    net.Start("TTTC_DropClass")
    net.SendToServer()
end
concommand.Add("dropclass", DropClass)

if SERVER then
    net.Receive("TTTC_DropClass", function(len, ply)
        hook.Run("TTTCDropClass", ply)
        
        ply:ResetCustomClass()
    end)
end
