if SERVER then
    net.Receive("TTTCCustomClassesSynced", function(len, ply)
       local first = net.ReadBool()
       
       -- run serverside
       hook.Run("TTTCPreFinishedClassesSync", ply, first)
       
       hook.Run("TTTCFinishedClassesSync", ply, first)
       
       hook.Run("TTTCPostFinishedClassesSync", ply, first)
    end)

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
            
            v.oldClass = nil
        end
    end)
    
    hook.Add("TTTBeginRound", "TTTCSelectClasses", function()
        local classesTbl = {}
        
        for _, v in pairs(CLASSES) do
            if v ~= CLASSES.UNSET then
                if GetConVar("tttc_class_" .. v.name .. "_enabled"):GetBool() then
                    local b = true
                    local r = GetConVar("tttc_class_" .. v.name .. "_random"):GetInt()
                    
                    if r > 0 and r < 100 then
                       b = math.random(1, 100) <= r
                    end
                
                    if b then
                        table.insert(classesTbl, v)
                    end
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
            if v:IsActive() then
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
        end
            
        hook.Run("TTTCPreReceiveCustomClasses")
        
        hook.Run("TTTCReceiveCustomClasses")
        
        hook.Run("TTTCPostReceiveCustomClasses")
    end)
    
    hook.Add("PlayerSay", "TTTCClassCommands", function(ply, text, public)
        text = string.Trim(string.lower(text))
        
        if text == "!dropclass" then
            ply:ConCommand("dropclass")
            
            return ""
        end
    end)
    
    hook.Add("PlayerCanPickupWeapon", "TTTCPickupClassWeapon", function(ply, wep)
        if ply:HasCustomClass() then
            local wepClass = wep:GetClass()
        
            if not ply:HasWeapon(wepClass) and table.HasValue(ply:GetClassData().weapons, wepClass) then
                return true
            end
        end
    end)
    
    hook.Add("TTTCReceiveCustomClasses", "TTTCReceiveCustomClasses", function()
        for _, ply in pairs(player.GetAll()) do
            if ply:IsActive() and ply:HasCustomClass() then
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
    
    hook.Add("DoPlayerDeath", "TTTCPostPlayerDeathSave", function(ply)
        ply.oldClass = ply:GetCustomClass()
    end)
    
    -- sync dead players with other players
    hook.Add("TTTBodyFound", "TTTCBodyFound", function(_, deadply, _)
        if GetRoundState() == ROUND_ACTIVE and IsValid(deadply) then
            if deadply.oldClass then
                net.Start("TTTCSyncClass")
                net.WriteEntity(deadply)
                net.WriteUInt(deadply.oldClass - 1, CLASS_BITS)
                net.Broadcast()
            end
        end
    end)
else
    hook.Add("TTTPrepareRound", "TTTCResetClasses", function()
        for _, v in pairs(player.GetAll()) do
            v:SetCustomClass(CLASSES.UNSET.index)
            
            v.oldClass = nil
        end
    end)
    
    net.Receive("TTTCSyncClass", function(len)
        local ply = net.ReadEntity()
        local cls = net.ReadUInt(CLASS_BITS) + 1
       
        if not ply.SetCustomClass then return end
        
        ply:SetCustomClass(cls)
        ply.oldClass = cls
    end)
    
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
    end)
    
    hook.Add("TTTSettingsTabs", "TTTCClassDescription", function(dtabs)
        local client = LocalPlayer()
    
        GetLang = GetLang or LANG.GetRawTranslation
            
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
            local cd = client:GetClassData()
        
            settings_tab:SetName("Current Class Description for " .. GetClassTranslation(cd))
        else
            settings_tab:SetName("Current Class Description")
        end
        
        settings_tab:SetWide(settings_panel:GetWide() - 30)
        settings_panel:AddItem(settings_tab)
        
        -- description
        if client:HasCustomClass() then
            local cd = client:GetClassData()
        
            -- weapons
            if cd.weapons and #cd.weapons > 0 then
                local weaps = ""
                
                for _, cls in pairs(cd.weapons) do
                    local tmp = weapons.Get(cls)
                    
                    local cls2 = tmp and tmp.PrintName or cls
                
                    if weaps ~= "" then
                        weaps = weaps .. ", "
                    end
                    
                    weaps = weaps .. cls2
                end
            
                settings_tab:Help((GetLang("classes_desc_weapons") or "Weapons: ") .. weaps)
            end
            
            -- items
            if cd.items and #cd.items > 0 then
                local items = ""
                
                for _, id in pairs(cd.items) do
                    local name = GetStaticEquipmentItem(id)
                    name = name and (name.name or "UNNAMED") or "UNNAMED"
                
                    if items ~= "" then
                        items = items .. ", "
                    end
                    
                    items = items .. name
                end
                
                settings_tab:Help((GetLang("classes_desc_items") or "Items: ") .. items)
            end
            
            local txt = GetLang("class_desc_" .. cd.name)
            if txt then
                settings_tab:Help(txt)
            end
        else
            local txt = GetLang("tttc_no_cls_desc")
            if txt then
                settings_tab:Help(txt)
            end
        end
        
        settings_tab:SizeToContents()
        
        -- tttc hud settings
        local hud_settings_tab = vgui.Create("DForm")
        hud_settings_tab:SetSpacing(10)
        hud_settings_tab:SetName("HUD Position")
        hud_settings_tab:SetWide(settings_panel:GetWide() - 30)
        settings_panel:AddItem(hud_settings_tab)
        
        hud_settings_tab:NumSlider("x-coordinate (position)", "tttc_hud_x", 0, ScrW(), 2)
        hud_settings_tab:NumSlider("y-coordinate (position)", "tttc_hud_y", 0, ScrH(), 2)
        
        hud_settings_tab:SizeToContents()
        
        -- tttc other settings
        local other_settings_tab = vgui.Create("DForm")
        other_settings_tab:SetSpacing(10)
        other_settings_tab:SetName("TTTC Settings")
        other_settings_tab:SetWide(settings_panel:GetWide() - 30)
        settings_panel:AddItem(other_settings_tab)
        
        local cb = other_settings_tab:CheckBox((GetLang("tttc_toggle_notification") or "Class notification"), "tttc_class_notification")
        cb:SetTooltip((GetLang("tttc_toggle_notification_tip") or "Toggles the class notification"))
        
        other_settings_tab:SizeToContents()
    end)
    
    hook.Add("TTTScoreboardColumns", "TTTCScoreboardClass", function(pnl)
        pnl:AddColumn("Class", function(ply, label)
            if ply:HasCustomClass() then
                local cd = ply:GetClassData()
                
                label:SetColor(cd.color or COLOR_CLASS)
            
                return GetClassTranslation(cd)
            elseif ply.oldClass and ply.oldClass ~= CLASSES.UNSET.index then
                local cd = GetClassByIndex(ply.oldClass)
                
                label:SetColor(cd.color or COLOR_CLASS)
            
                return GetClassTranslation(cd)
            elseif not ply:IsActive() and ply:GetNWBool("body_found") then
                return "-" -- died without any class
            end
            
            return "?"
        end, 100)
    end)
end
