local plymeta = FindMetaTable("Player")

if not plymeta then return end

plymeta.classWeapons = {}
plymeta.classItems = {}

AccessorFunc(plymeta, "customClass", "CustomClass", FORCE_NUMBER)

function plymeta:GetClassData()
    return GetClassByIndex(self:GetCustomClass())
end

function plymeta:HasCustomClass()
    return self:GetCustomClass() and self:GetCustomClass() ~= CLASSES.UNSET.index
end

if SERVER then
    function plymeta:UpdateCustomClass(index)
        self:SetCustomClass(index)
    
        net.Start("TTTCSendCustomClass")
        net.WriteUInt(index - 1, CLASS_BITS)
        net.Send(self)
        
        hook.Run("TTTCUpdatedCustomClass", self)
    end
    
    function plymeta:GiveClassWeapon(wep)
        local newWep = wep
        
        if GetConVar("tttc_traitorbuy"):GetBool() then
            newWep = RegisterNewClassWeapon(wep)
        end
    
        if not newWep then return end
        
        local rt = self:Give(newWep)
    
        if rt then
            if not table.HasValue(self.classWeapons, newWep) then
                table.insert(self.classWeapons, newWep)
            end
        end
        
        return rt
    end
    
    function plymeta:GiveClassEquipmentItem(id)
        local rt = self:GiveEquipmentItem(id)
        
        if rt then
            if not table.HasValue(self.classItems, id) then
                table.insert(self.classItems, id)
            end
        end
        
        return rt
    end
    
    function plymeta:GiveServerClassWeapon(cls, clip1, clip2)
        if not self:HasCustomClass() then return end
    
        local w = self:GiveClassWeapon(cls)
        
        if not IsValid(w) then return end
        
        local newCls = w:GetClass()
        
        local cd = self:GetClassData()
        
        if not table.HasValue(cd.weapons, newCls) then
            table.insert(cd.weapons, newCls)
            
            net.Start("TTTCSyncClassWeapon")
            net.WriteString(newCls)
            net.Send(self)
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
        
        id = tonumber(id)
        
        if not id then return end
        
        self:GiveClassEquipmentItem(id)
        self:AddBought(id)
        
        local cd = self:GetClassData()
        
        if not table.HasValue(cd.items, id) then
            table.insert(cd.items, id)
            
            net.Start("TTTCSyncClassItem")
            net.WriteUInt(id, 16)
            net.Send(self)
        end

        timer.Simple(0.5, function()
            if not IsValid(self) then return end
            
            net.Start("TTT_BoughtItem")
            net.WriteBit(true)
            net.WriteUInt(id, 16)
            net.Send(self)
        end)

        hook.Run("TTTOrderedEquipment", self, id, id) -- hook.Run("TTTOrderedEquipment", self, id, true) -- i know, looks stupid but thats the way TTT does
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
        
        --[[
        if self.classItems then
            for _, equip in pairs(self.classItems) do
                self.equipment_items = bit.bxor(self.equipment_items, equip)
            end
            
            self:SendEquipment()
        end
        ]]--
            
        self.classWeapons = {}
        self.classItems = {}
        
        self:UpdateCustomClass(CLASSES.UNSET.index)
    end
    
    net.Receive("TTTCClientSendCustomClass", function(len, ply)
        local cls = net.ReadUInt(CLASS_BITS) + 1
       
        if not ply.SetCustomClass then return end
        
        ply:ResetCustomClass()
        ply:UpdateCustomClass(cls)
        
        if ply:IsActive() then
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
    end)
else
    net.Receive("TTTCSendCustomClass", function(len)
        local client = LocalPlayer()
        local cls = net.ReadUInt(CLASS_BITS) + 1
       
        if not client.SetCustomClass then return end
        
        client:SetCustomClass(cls)
        
        hook.Run("TTTCUpdatedCustomClass", client)
    end)
    
    net.Receive("TTTCSyncClassWeapon", function(len)
        local client = LocalPlayer()
        local wep = net.ReadString()
        
        if not client:HasCustomClass() then return end
        
        local cd = client:GetClassData()
        
        if not table.HasValue(cd.weapons, wep) then
            table.insert(cd.weapons, wep)
        end
    end)
    
    net.Receive("TTTCSyncClassItem", function(len)
        local client = LocalPlayer()
        local id = net.ReadUInt(16)
        
        if not client:HasCustomClass() then return end
        
        local cd = client:GetClassData()
        
        if not table.HasValue(cd.items, id) then
            table.insert(cd.items, id)
        end
    end)
    
    function plymeta:ServerUpdateCustomClass(index)
        net.Start("TTTCClientSendCustomClass")
        net.WriteUInt(index - 1, CLASS_BITS)
        net.SendToServer()
    end
end
