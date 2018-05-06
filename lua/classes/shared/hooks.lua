net.Receive("TTTCCustomClassesSynced", function(len, ply)
   local first = net.ReadBool()
   
   -- run serverside
   hook.Run("TTTCFinishedClassesSync", ply, first)
end)

if SERVER then
    hook.Add("Initialize", "TTTCCustomClassesInit", function()
        print()
        print("[TTTC][CLASS] Server is ready to receive new classes...")
        print()

        hook.Run("TTTCPreClassesInit")
        
        hook.Run("TTTCClassesInit")
        
        hook.Run("TTTCPostClassesInit")
        
        if GetConVar("tttc_traitorbuy"):GetBool() then
            for _, wep in pairs(weapons.GetList()) do
                RegisterNewClassWeapon(wep.ClassName)
            end
        end
    end)
    
    hook.Add("PlayerAuthed", "TTTCCustomClassesSync", function(ply, steamid, uniqueid)
        UpdateClassData(ply, true)
        
        ply:UpdateCustomClass(1)
    end)
    
    hook.Add("TTTPrepareRound", "TTTCResetClasses", function()
        for _, v in pairs(player.GetAll()) do
            v:ResetCustomClass()
        end
    end)
    
    hook.Add("TTTBeginRound", "TTTCSelectClasses", function()
        local classesTbl = {}
        
        for _, v in pairs(CLASSES) do
            if v ~= CLASSES.UNSET then
                if GetConVar("tttc_class_" .. v.name .. "_enabled"):GetBool() then
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
        end
            
        hook.Run("TTTCPreReceiveCustomClasses")
        
        hook.Run("TTTCReceiveCustomClasses")
        
        hook.Run("TTTCPostReceiveCustomClasses")
    end)
    
    hook.Add("PlayerSay", "TTTCClassCommands", function(ply, text, public)
        if string.lower(text) == "!dropclass" then
            ply:ConCommand("dropclass")
            
            return ""
        end
    end)
    
    hook.Add("PlayerCanPickupWeapon", "TTTCPickupClassWeapon", function(ply, wep)
        if GetConVar("tttc_traitorbuy"):GetBool() then
            hasValue = false
        
            for cls, tbl in pairs(WEAPONS_FOR_CLASSES) do
                if table.HasValue(tbl, wepClass) then
                    hasValue = true
                    
                    break
                end
            end
            
            if hasValue then
                if not ply:HasCustomClass() then
                    return false
                elseif not table.HasValue(ply:GetCustomClass(), wepClass) then
                    return false
                end
            end
        end
        
        if ply:HasCustomClass() then
            local wepClass = wep:GetClass()
        
            if not ply:HasWeapon(wepClass) and table.HasValue(WEAPONS_FOR_CLASSES[ply:GetCustomClass()], wepClass) then
                if not table.HasValue(ply.classWeapons, wepClass) then
                    table.insert(ply.classWeapons, wepClass)
                end
                
                return true
            end
        end
    end)
    
    hook.Add("TTTCReceiveCustomClasses", "TTTCReceiveCustomClasses", function()
        for _, ply in pairs(player.GetAll()) do
            if ply:Alive() and ply:HasCustomClass() then
                local cd = ply:GetClassData()
                local weaps = cd.weapons
                local items = cd.items
            
                if weaps and #weaps > 0 then
                    for _, v in pairs(weaps) do
                        ply:GiveServerClassWeapon(v)
                    end
                end
            
                if items and #items > 0 then
                    for _, v in pairs(items) do
                        ply:GiveServerClassItem(v)
                    end
                end
            end
        end
    end)
else
    local GetLang
    
    function GetStaticEquipmentItem(id)
        if not ROLES then
            for i = 1, 3 do
                local tbl = EquipmentItems[i]

                if tbl then
                    for _, v2 in pairs(tbl) do
                        if v2 and v2.id == id then
                            return v2
                        end
                    end
                end
            end
        else
            for _, v in pairs(ROLES) do
                local tbl = EquipmentItems[v.index]

                if tbl then
                    for _, v2 in pairs(tbl) do
                        if v2 and v2.id == id then
                            return v2
                        end
                    end
                end
            end
        end
    end

    hook.Add("TTTCFinishedClassesSync", "TTTCFinishedClassesSyncInitCli", function(ply, first)
        if first then
            if GetConVar("tttc_traitorbuy"):GetBool() then
                for _, wep in pairs(weapons.GetList()) do
                    RegisterNewClassWeapon(wep.ClassName)
                end
            end
        end
        
        for _, v in pairs(CLASSES) do
            -- init class arrays
            if first then
                WEAPONS_FOR_CLASSES[v.index] = {}
                ITEMS_FOR_CLASSES[v.index] = {}
            end
            
            if v ~= CLASSES.UNSET then
                if not GetConVar("tttc_traitorbuy"):GetBool() then
                    if v.weapons then
                        for _, wep in pairs(v.weapons) do
                            if not table.HasValue(WEAPONS_FOR_CLASSES[v.index], wep) then
                                table.insert(WEAPONS_FOR_CLASSES[v.index], wep)
                            end
                        end
                    end
                    
                    if v.items then
                        for _, id in pairs(v.items) do
                            if not table.HasValue(ITEMS_FOR_CLASSES[v.index], id) then
                                table.insert(ITEMS_FOR_CLASSES[v.index], id)
                            end
                        end
                    end
                end
            end
        end
    end)
    
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
            local cd = client:GetClassData()
        
            -- weapons
            if WEAPONS_FOR_CLASSES[cd.index] and #WEAPONS_FOR_CLASSES[cd.index] > 0 then
                local weaps = ""
                
                for _, cls in pairs(WEAPONS_FOR_CLASSES[cd.index]) do
                    local tmp = weapons.Get(cls)
                    
                    cls = tmp and tmp.PrintName or cls
                
                    if weaps ~= "" then
                        weaps = weaps .. ", "
                    end
                    
                    weaps = weaps .. cls
                end
            
                settings_tab:Help(L["classes_desc_weapons"] .. weaps)
            end
            
            -- items
            if ITEMS_FOR_CLASSES[cd.index] and #ITEMS_FOR_CLASSES[cd.index] > 0 then
                local items = ""
                
                for _, id in pairs(ITEMS_FOR_CLASSES[cd.index]) do
                    local name = GetStaticEquipmentItem(id)
                    name = name and name.name or "UNNAMED"
                
                    if items ~= "" then
                        items = items .. ", "
                    end
                    
                    items = items .. name
                end
                
                settings_tab:Help(L["classes_desc_items"] .. items)
            end
            
            settings_tab:Help(L["class_desc_" .. cd.name])
        else
            settings_tab:Help(L["tttc_no_cls_desc"])
        end
        
        settings_tab:SizeToContents()
    end)
end
