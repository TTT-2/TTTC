local plymeta = FindMetaTable("Player")

if not plymeta then return end

WEAPONS_FOR_CLASSES = {}
ITEMS_FOR_CLASSES = {}

AccessorFunc(plymeta, "customClass", "CustomClass", FORCE_NUMBER)

function plymeta:GetClassData()
    return GetClassByIndex(self:GetCustomClass())
end

if SERVER then
    function plymeta:UpdateCustomClass(index)
        self:SetCustomClass(index)
    
        net.Start("TTT2_SendCustomClass")
        net.WriteUInt(index - 1, CLASS_BITS)
        net.Send(self)
    end
    
    function plymeta:GiveClassWeapon(wep)
        local rt = self:Give(wep)
    
        if rt then
            table.insert(self.classWeapons, wep)
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
        
        local tmr = "g_cwep_" .. sid .. "_" .. cls

        -- giving attempt, will fail if we're in a crazy spot in the map or perhaps
        -- other glitchy cases
        local w = self:GiveClassWeapon(cls)

        if not IsValid(w) or not self:HasWeapon(cls) then
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
        local w = self:GiveClassWeapon(cls)

        if IsValid(w) and self:HasWeapon(cls) then
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
    net.Receive("TTT2_SendCustomClass", function(len)
        local client = LocalPlayer()
        local cls = net.ReadUInt(CLASS_BITS) + 1
       
        if not client.SetCustomClass then return end
        
        client:SetCustomClass(cls)
    end)
end

function plymeta:HasCustomClass()
    return self:GetCustomClass() and self:GetCustomClass() ~= CLASSES.UNSET.index
end
