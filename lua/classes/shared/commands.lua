function DropClass(ply)
    net.Start("TTTCDropClass")
    net.SendToServer()
end
concommand.Add("dropclass", DropClass)

if SERVER then
    net.Receive("TTTCDropClass", function(len, ply)
        hook.Run("TTTCDropClass", ply)
        
        ply:ResetCustomClass()
        
        ply.oldClass = nil
    end)
end

-----------------

local function force_class(ply, cmd, args, argStr)
   local class = tonumber(args[1])
   local i = 0
   
   for _, v in pairs(CLASSES) do
      i = i + 1
   end
   
   local cd = GetClassByIndex(class)
   
   if class and class <= i then
      ply:ServerUpdateCustomClass(class)

      ply:ChatPrint("You changed to '" .. cd.name .. "' (class: " .. class .. ")")
   end
end
concommand.Add("ttt_force_class", force_class, nil, nil, FCVAR_CHEAT)

------------------

local function classes_index(ply)
   if ply:IsAdmin() then
      ply:ChatPrint("[TTTC] classes_index...")
      ply:ChatPrint("-----------------")
      ply:ChatPrint("[Class] | [Index]")
      
      for _, v in pairs(GetSortedClasses()) do
         ply:ChatPrint(v.name .. " | " .. v.index)
      end
      
      ply:ChatPrint("----------------")
   end
end
concommand.Add("ttt_classes_index", classes_index)
