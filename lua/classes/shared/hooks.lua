net.Receive("TTT2_CustomClassesSynced", function(len, ply)
   local first = net.ReadBool()
   
   -- run serverside
   hook.Run("TTT2_FinishedClassesSync", ply, first)
end)

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
        
        local tmp = {}
        
        if GetConVar("ttt_customclasses_limited"):GetBool() then
            for _, v in pairs(classesTbl) do
                table.insert(tmp, v)
            end
        end
        
        for _, v in pairs(player.GetAll()) do
            local cls
        
            if #tmp == 0 then
                local rand = math.random(1, #classesTbl)
                
                cls = classesTbl[rand].index
            else
                local rand = math.random(1, #tmp)
            
                cls = tmp[rand].index
                
                table.remove(tmp, rand)
            end
            
            v:UpdateCustomClass(cls)
            
            hook.Run("TTT2_PreReceiveCustomClass", v)
            
            hook.Run("TTT2_ReceiveCustomClass", v)
            
            hook.Run("TTT2_PostReceiveCustomClass", v)
        end
    end)
    
    hook.Add("PlayerSay", "TTTCClassCommands", function(ply, text, public)
        if string.lower(text) == "!dropclass" then
            ply:ConCommand("dropclass")
            
            return ""
        end
    end)
else
    local GetLang

    hook.Add("TTTSettingsTabs", "TTTCClassDescription", function(dtabs)
        local client = LocalPlayer()
    
        GetLang = GetLang or LANG.GetUnsafeLanguageTable
            
        local L = GetLang()
            
        local settings_panel = vgui.Create("DPanelList", dtabs)
        settings_panel:StretchToParent(0, 0, dtabs:GetPadding() * 2, 0)
        settings_panel:EnableVerticalScrollbar(true)
        settings_panel:SetPadding(10)
        settings_panel:SetSpacing(10)
        dtabs:AddSheet("TTTC", settings_panel, "icon16/information.png", false, false, "The TTTC settings")
        
        local list = vgui.Create("DIconLayout", settings_panel)
        list:SetSpaceX(5)
        list:SetSpaceY(5)
        list:Dock(FILL)
        list:DockMargin(5, 5, 5, 5)
        list:DockPadding(10, 10, 10, 10)
        
        local settings_tab = vgui.Create("DForm")
        settings_tab:SetSpacing(10)
        
        if client:HasCustomClass() then
            settings_tab:SetName("Current Class Description of " .. L[client:GetClassData().name])
        else
            settings_tab:SetName("Current Class Description")
        end
        
        settings_tab:SetWide(settings_panel:GetWide() - 30)
        settings_panel:AddItem(settings_tab)
        
        if client:HasCustomClass() then
            settings_tab:Help(L["class_desc_" .. client:GetClassData().name])
        else
            settings_tab:Help(L["tttc_no_cls_desc"])
        end
        
        settings_tab:SizeToContents()
    end)
end
