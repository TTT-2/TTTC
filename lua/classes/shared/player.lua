local plymeta = FindMetaTable("Player")

if not plymeta then return end

AccessorFunc(plymeta, "customClass", "CustomClass", FORCE_NUMBER)

function plymeta:GetClassData()
    return GetClassByIndex(self:GetCustomClass())
end

if SERVER then
    function plymeta:ResetCustomClass()
        hook.Run("TTT2_ResetCustomClass", self)

        self:UpdateCustomClass(1)
    end
    
    function plymeta:UpdateCustomClass(index)
        self:SetCustomClass(index)
    
        net.Start("TTT2_SendCustomClass")
        net.WriteUInt(index - 1, CLASS_BITS)
        net.Send(self)
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
