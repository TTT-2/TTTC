local plymeta = FindMetaTable("Player")

if not plymeta then return end

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
        self.classWeapons = self.classWeapons or {}
        
        local ret = self:Give(wep)
    
        table.insert(self.classWeapons, wep)
        
        return ret
    end
    
    function plymeta:AddClassEquipmentItem(id)
        self.classEquipment = self.classEquipment or {}
    
        table.insert(self.classEquipment, id)
        
        self:AddEquipmentItem(id)
    end
    
    function plymeta:ResetCustomClass()
        hook.Run("TTT2_ResetCustomClass", self)
        
        if self.classWeapons then
            for _, wep in pairs(self.classWeapons) do
                if self:HasWeapon(wep) then
                    self:StripWeapon(wep)
                end
            end
            
            self.classWeapons = {}
        end
        
        if self.classEquipment then
            for _, equip in pairs(self.classEquipment) do
                self.equipment_items = bit.band(self.equipment_items, equip)
            end
        
            self.classEquipment = {}
            
            self:SendEquipment()
        end
        
        self:UpdateCustomClass(1)
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
