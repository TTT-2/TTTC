function DropClass(ply)
    net.Start("TTTCDropClass")
    net.SendToServer()
end
concommand.Add("dropclass", DropClass)

if SERVER then
    net.Receive("TTTCDropClass", function(len, ply)
        hook.Run("TTTCDropClass", ply)
        
        ply:ResetCustomClass()
    end)
end
