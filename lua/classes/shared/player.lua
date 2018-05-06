local plymeta = FindMetaTable("Player")

if not plymeta then return end

AccessorFunc(plymeta, "customClass", "CustomClass", FORCE_NUMBER)

function plymeta:GetClassData()
    return GetClassByIndex(self:GetCustomClass())
end

if SERVER then
    function plymeta:RegisterNewWeapon(wep)
        local newWep = wep .. "_tttc"
        
        local tmp = weapons.Get(wep)
        
        if table.HasValue(REGISTERED_WEAPONS, wep) and tmp then 
            return wep
        end
        
        if weapons.Get(newWep) then
            return newWep
        end
        
        net.Start("TTTCRegisterNewWeapon")
        net.WriteString(wep)
        net.Broadcast()
        
        if not tmp then return end
        
        local wepTbl = tmp
        wepTbl.__index = wepTbl
        
        if not wepTbl then return end
        
        wepTbl.CanBuy = {}
        wepTbl.Kind = -1
        wepTbl.Slot = 10
        wepTbl.ClassName = newWep
        
        weapons.Register(wepTbl, newWep)
        
        table.insert(REGISTERED_WEAPONS, newWep)
        
        return newWep
    end
    
    function plymeta:UpdateCustomClass(index)
        self:SetCustomClass(index)
    
        net.Start("TTTCSendCustomClass")
        net.WriteUInt(index - 1, CLASS_BITS)
        net.Send(self)
    end
    
    function plymeta:GiveClassWeapon(wep)
        local newWep = wep
        
        if GetConVar("tttc_traitorbuy"):GetBool() then
            newWep = self:RegisterNewWeapon(wep)
        end
        
        if not newWep then return end
        
        local rt = self:Give(newWep)
    
        if rt then
            table.insert(self.classWeapons, newWep)
        end
        
        return rt
    end
    
    function plymeta:GiveClassEquipmentItem(id)
        local rt = self:GiveEquipmentItem(id)
        
        if rt then
            table.insert(self.classItems, id)
        end
        
        return rt
    end
    
    function plymeta:AddClassEquipmentItem(id)
        table.insert(self.classItems, id)
        
        self:AddEquipmentItem(id)
    end
    
    function plymeta:AddClassEquipmentItemFix(id)
        id = tonumber(id)
        
        if not id then return end
        
        if not self:HasCustomClass() then return end
        
        local cc = self:GetCustomClass()
        
        if not table.HasValue(ITEMS_FOR_CLASSES[cc], id) then
            table.insert(ITEMS_FOR_CLASSES[cc], id)
        end
        
        self:GiveClassEquipmentItem(id)
        self:AddBought(id)

        timer.Simple(0.5, function()
            if not IsValid(self) then return end
            
            net.Start("TTT_BoughtItem")
            net.WriteBit(true)
            net.WriteUInt(id, 16)
            net.Send(self)
        end)

        hook.Run("TTTOrderedEquipment", self, id, true)
    end
    
    function plymeta:GiveClassEquipmentWeapon(cls, clip1, clip2)
        -- Referring to players by SteamID because a player may disconnect while his
        -- unique timer still runs, in which case we want to be able to stop it. For
        -- that we need its name, and hence his SteamID.
        if not IsValid(self) then return end
        
        local sid = self:SteamID()

        -- giving attempt, will fail if we're in a crazy spot in the map or perhaps
        -- other glitchy cases
        
        local w = self:GiveClassWeapon(cls)
        
        if not IsValid(w) then return end
        
        local tmr = "g_cwep_" .. sid .. "_" .. cls

        if not self:HasWeapon(w:GetClass()) then
            if not timer.Exists(tmr) then
                timer.Create(tmr, 1, 0, function() 
                    self:GiveClassEquipmentWeapon(cls, clip1, clip2) 
                end)
            end

            -- we will be retrying
        else
            -- can stop retrying, if we were
            timer.Remove(tmr)

            if w.WasBought then
                -- some weapons give extra ammo after being bought, etc
                w:WasBought(self)
            end
            
            if clip1 then
                w:SetClip1(clip1)
            end
            
            if clip2 then
                w:SetClip2(clip2)
            end
        end
    end
    
    function plymeta:AddClassEquipmentWeaponFix(cls, clip1, clip2)
        if not cls then return end
        
        if not self:HasCustomClass() then return end
        
        local cc = self:GetCustomClass()
        
        if not table.HasValue(WEAPONS_FOR_CLASSES[cc], cls) then
            table.insert(WEAPONS_FOR_CLASSES[cc], cls)
        end
        
        self:GiveClassEquipmentWeapon(cls, clip1, clip2)
        self:AddBought(cls)

        timer.Simple(0.5, function()
            if not IsValid(self) then return end
            
            net.Start("TTT_BoughtItem")
            net.WriteBit(false)
            net.WriteString(cls)
            net.Send(self)
        end)

        hook.Run("TTTOrderedEquipment", self, cls, false)
    end
    
    function plymeta:GiveServerClassWeapon(cls, clip1, clip2)
        if not self:HasCustomClass() then return end
    
        local w = self:GiveClassWeapon(cls)
        
        if not IsValid(w) then return end
        
        local newCls = w:GetClass()
        
        if not table.HasValue(WEAPONS_FOR_CLASSES[self:GetCustomClass()], newCls) then
            table.insert(WEAPONS_FOR_CLASSES[self:GetCustomClass()], newCls)
        end

        if self:HasWeapon(newCls) then
            self:AddBought(cls)
              
            if w.WasBought then
                -- some weapons give extra ammo after being bought, etc
                w:WasBought(self)
            end
            
            if clip1 then
                w:SetClip1(clip1)
            end
            
            if clip2 then
                w:SetClip2(clip2)
            end
            
            timer.Simple(0.5, function()
                if not IsValid(self) then return end
                
                net.Start("TTT_BoughtItem")
                net.WriteBit(false)
                net.WriteString(cls)
                net.Send(self)
            end)

            hook.Run("TTTOrderedEquipment", self, cls, false)
        end
    end
    
    function plymeta:GiveServerClassItem(id)
        if not self:HasCustomClass() then return end
    
        self:GiveClassEquipmentItem(id)
        self:AddBought(id)
        
        if not table.HasValue(ITEMS_FOR_CLASSES[self:GetCustomClass()], id) then
            table.insert(ITEMS_FOR_CLASSES[self:GetCustomClass()], id)
        end

        timer.Simple(0.5, function()
            if not IsValid(self) then return end
            
            net.Start("TTT_BoughtItem")
            net.WriteBit(true)
            net.WriteUInt(id, 16)
            net.Send(self)
        end)

        hook.Run("TTTOrderedEquipment", self, id, true)
    end
    
    function plymeta:ResetCustomClass()
        hook.Run("TTTCResetCustomClass", self)
        
        if self.classWeapons then
            for _, wep in pairs(self.classWeapons) do
                if self:HasWeapon(wep) then
                    self:StripWeapon(wep)
                end
            end
        end
        
        if self.classItems then
            for _, equip in pairs(self.classItems) do
                self.equipment_items = bit.bxor(self.equipment_items, equip)
            end
            
            self:SendEquipment()
        end
            
        self.classWeapons = {}
        self.classItems = {}
        
        self:UpdateCustomClass(CLASSES.UNSET.index)
    end
else
    function plymeta:RegisterNewWeapon(wep)
        local newWep = wep .. "_tttc"
        
        if table.HasValue(REGISTERED_WEAPONS, wep) and weapons.Get(wep) then 
            return wep
        end
        
        if weapons.Get(newWep) then
            return newWep
        end
        
        local tmp = weapons.Get(wep)
        
        if not tmp then return end
        
        local wepTbl = tmp
        wepTbl.__index = wepTbl
        
        wepTbl.CanBuy = {}
        wepTbl.Kind = -1
        wepTbl.Slot = 10
        wepTbl.ClassName = newWep
        
        weapons.Register(wepTbl, newWep)
        
        table.insert(REGISTERED_WEAPONS, newWep)
        
        return newWep
    end

    net.Receive("TTTCSendCustomClass", function(len)
        local client = LocalPlayer()
        local cls = net.ReadUInt(CLASS_BITS) + 1
       
        if not client.SetCustomClass then return end
        
        client:SetCustomClass(cls)
    end)
    
    net.Receive("TTTCRegisterNewWeapon", function(len)
        local client = LocalPlayer()
        local wep = net.ReadString()
        
        client:RegisterNewWeapon(wep)
    end)
end

function plymeta:HasCustomClass()
    return self:GetCustomClass() and self:GetCustomClass() ~= CLASSES.UNSET.index
end
