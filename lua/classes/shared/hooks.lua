if SERVER then
    hook.Add("Initialize", "TTT2CustomClassesInit", function()
        print()
        print("[TTT2][CLASS] Server is ready to receive new classes...")
        print()

        hook.Run("TTT2_PreClassesInit")
        
        hook.Run("TTT2_ClassesInit")
        
        hook.Run("TTT2_PostClassesInit")
    end)
    
    --hook.Add("TTT2_FinishedSync", "TTT2CustomClassesSync", function(ply, first)
    hook.Add("PlayerAuthed", "TTT2CustomClassesSync", function(ply, steamid, uniqueid)
        UpdateClassData(ply, true)
        
        ply:UpdateCustomClass(1)
    end)
    
    hook.Add("TTTPrepareRound", "TTT2ResetClasses", function()
        for _, v in pairs(player.GetAll()) do
            v:ResetCustomClass()
        end
    end)
end

net.Receive("TTT2_CustomClassesSynced", function(len, ply)
   local first = net.ReadBool()
   
   -- run serverside
   hook.Run("TTT2_FinishedClassesSync", ply, first)
end)

if SERVER then
    hook.Add("TTTBeginRound", "TTT2SelectClasses", function()
        local classesTbl = {}
        
        for _, v in pairs(CLASSES) do
            if v ~= CLASSES.UNSET then
                if GetConVar("ttt2_classes_" .. v.name .. "_enabled"):GetBool() then
                    table.insert(classesTbl, v)
                end
            end
        end
        
        if #classesTbl == 0 then return end
        
        for _, v in pairs(player.GetAll()) do
            v:UpdateCustomClass(table.Random(classesTbl).index)
            
            hook.Run("TTT2_ReceiveCustomClass", v)
        end
    end)
end
