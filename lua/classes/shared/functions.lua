function AddCustomClass(name, classData)
    if not CLASSES[name] then
        CreateConVar("tttc_class_" .. classData.name .. "_enabled", "1", FCVAR_NOTIFY + FCVAR_ARCHIVE + FCVAR_REPLICATED)
            
        if SERVER then
        
            -- necessary to init classes in this way, because we need to wait until the CLASSES array is initialized 
            -- and every important function works properly
            hook.Add("TTTCClassesInit", "Add_" .. classData.name .. "_Class", function() -- unique hook identifier please
                if not CLASSES[name] then -- count CLASSES
                    local i = 1 -- start at 1 to directly get free slot
                    
                    for _, v in pairs(CLASSES) do
                        i = i + 1
                    end
                    
                    classData.index = i
                    CLASSES[name] = classData
                    
                    -- init class arrays
                    WEAPONS_FOR_CLASSES[i] = classData.weapons or {}
                    ITEMS_FOR_CLASSES[i] = classData.items or {}
                    
                    -- spend an answer
                    print("[TTTC][CLASS] Added '" .. name .. "' Class (index: " .. i .. ")")
                end
            end)
        end
    end
end

function SortClassesTable(tbl)
    table.sort(tbl, function(a, b)
       return (a.index < b.index)
    end)
end

function GetClassByIndex(index)
    for _, v in pairs(CLASSES) do
        if v.index == index then
            return v
        end
    end
    
    return CLASSES.UNSET
end

local unregistered = {
    "weapon_zm_improvised",
    "weapon_zm_carry",
    "weapon_ttt_unarmed"
}
    
function RegisterNewClassWeapon(wep)
    if table.HasValue(unregistered, wep) then
        return wep
    end

    local newWep = wep .. "_tttc"
    
    local tmp = weapons.Get(wep)
    
    if tmp and table.HasValue(REGISTERED_WEAPONS, wep) then 
        return wep
    end
    
    if weapons.Get(newWep) then
        return newWep
    end
    
    if not tmp then return end
    
    local wepTbl = tmp
    wepTbl.__index = wepTbl
    wepTbl.ClassName = newWep
    wepTbl.CanBuy = {}
    wepTbl.Kind = -1
    wepTbl.Slot = 10
    wepTbl.AllowDrop = false
    
    weapons.Register(wepTbl, newWep)
    
    table.insert(REGISTERED_WEAPONS, newWep)
    
    return newWep
end

if SERVER then
    -- sync CLASSES list
    -- toggle first if you want to reinitialize EVERYTHING ! Should be avoided, there is a reason why this var exists...

    local function EncodeForStream(tbl)
       -- may want to filter out data later
       -- just serialize for now

       local result = util.TableToJSON(tbl)
       if not result then
          ErrorNoHalt("Round report event encoding failed!\n")
          
          return false
       else
          return result
       end
    end
    
    function UpdateClassData(ply, first)
        print("[TTTC][CLASS] Sending new CLASSES list to " .. ply:Nick() .. "...")

        local s = EncodeForStream(CLASSES)

        if not s then
            return -- error occurred
        end

        -- divide into happy lil bits.
        -- this was necessary with user messages, now it's
        -- a just-in-case thing if a round somehow manages to be > 64K
        local cut = {}
        local max = 65499

        while #s ~= 0 do
            local bit = string.sub(s, 1, max - 1)

            table.insert(cut, bit)

            s = string.sub(s, max, -1)
        end

        local parts = #cut

        for k, bit in pairs(cut) do
            net.Start("TTTCSyncCustomClasses")
            net.WriteBool(first)
            net.WriteBit((k ~= parts)) -- continuation bit, 1 if there's more coming
            net.WriteString(bit)

            if ply ~= nil then
                net.Send(ply)
            else
                net.Broadcast()
            end
        end
    end
else
    -- sync CLASSES
    local buff = ""
    
    local function ReceiveClassesTable(len)
       print("[TTTC][CLASS] Received new CLASSES list from server! Updating...")

       local first = net.ReadBool()
       local cont = net.ReadBit() == 1

       buff = buff .. net.ReadString()

       if cont then
          return
       else
          -- do stuff with buffer contents

          local json_roles = buff -- util.Decompress(buff)
          
          if not json_roles then
             ErrorNoHalt("[TTTC][CLASS] CLASSES decompression failed!\n")
          else
             -- convert the json string back to a table
             local tmp = util.JSONToTable(json_roles)

             if istable(tmp) then
                CLASSES = tmp
             else
                ErrorNoHalt("[TTTC][CLASS] CLASSES decoding failed!\n")
             end
             
             -- confirm update and process next updates
             net.Start("TTTCCustomClassesSynced")
             net.WriteBool(first)
             net.SendToServer()
             
             -- run client side
             hook.Run("TTTCFinishedClassesSync", LocalPlayer(), first)
          end

          -- flush
          buff = ""
       end
    end
    
    net.Receive("TTTCSyncCustomClasses", ReceiveClassesTable)
end
