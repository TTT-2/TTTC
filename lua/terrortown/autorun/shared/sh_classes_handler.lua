CLASS = CLASS or {}
CLASS.CLASSES = CLASS.CLASSES or {}
CLASS.AVAILABLECLASSES = CLASS.AVAILABLECLASSES or {}
CLASS.FREECLASSES = CLASS.FREECLASSES or {}

CLASS_BITS = 10

COLOR_CLASS = Color(255, 155, 0, 255)
CLASS_TIME = 60
CLASS_COOLDOWN = 60

TTTC = true

function CLASS.AddClass(name, classData, conVarData)
    conVarData = conVarData or {}

    local oldId

    if CLASS.CLASSES[name] then
        oldId = CLASS.CLASSES[name].index

        CLASS.CLASSES[name] = nil
    end

    classData.name = string.Trim(string.lower(name))

    if SERVER and not oldId then
        CreateConVar(
            "tttc_class_" .. classData.name .. "_enabled",
            "1",
            { FCVAR_NOTIFY, FCVAR_ARCHIVE }
        )
        CreateConVar(
            "tttc_class_" .. classData.name .. "_random",
            tostring(conVarData.random or 100),
            { FCVAR_ARCHIVE }
        )
    end

    -- necessary to init classes in this way, because we need to wait until the CLASS.CLASSES array is initialized
    -- and every important function works properly
    local i = oldId or table.Count(CLASS.CLASSES) + 1

    classData.index = i

    -- init class arrays
    classData.weapons = classData.weapons or {}
    classData.items = classData.items or {}

    classData.time = classData.time or CLASS_TIME
    classData.cooldown = classData.cooldown or CLASS_COOLDOWN
    classData.endless = classData.endless or false
    classData.passive = classData.passive or false

    if CLIENT and classData.lang and not oldId then
        hook.Add("TTT2FinishedLoading", "TTTCInitLangFor" .. classData.name, function()
            if not LANG then
                return
            end

            for lang, text in pairs(classData.lang.name) do
                LANG.AddToLanguage(lang, "tttc_class_" .. classData.name .. "_name", text)
            end

            for lang, text in pairs(classData.lang.desc) do
                LANG.AddToLanguage(lang, "tttc_class_" .. classData.name .. "_desc", text)
            end
        end)
    end

    -- COMPATIBILITY WITH DEPRECATED NAMES
    classData.OnSet = classData.OnSet or classData.onClassSet
    classData.onClassSet = nil
    classData.OnUnset = classData.OnUnset or classData.onClassUnset
    classData.onClassUnset = nil
    classData.OnAbilityActivate = classData.OnAbilityActivate or classData.onActivate
    classData.onActivate = nil
    classData.OnAbilityDeactivate = classData.OnAbilityDeactivate or classData.onDeactivate
    classData.onDeactivate = nil
    classData.OnStartPrepareAbilityActivation = classData.OnStartPrepareAbilityActivation
        or classData.onPrepareActivation
    classData.onPrepareActivation = nil
    classData.OnFinishPrepareAbilityActivation = classData.OnFinishPrepareAbilityActivation
        or classData.onFinishPreparingActivation
    classData.onFinishPreparingActivation = nil
    classData.OnCharge = classData.OnCharge or classData.onCharge
    classData.onCharge = nil
    classData.CheckActivation = classData.CheckActivation or classData.checkActivation
    classData.checkActivation = nil
    -- END COMPATIBILITY

    CLASS.CLASSES[name] = classData

    -- spend an answer
    Dev(1, "[TTTC][CLASS] Added '" .. name .. "' Class (index: " .. i .. ")")
end

function CLASS.SortClassesTable(tbl)
    table.sort(tbl, function(a, b)
        return a.index < b.index
    end)
end

function CLASS.GetClassDataByIndex(index)
    for _, v in pairs(CLASS.CLASSES) do
        if v.index == index then
            return v
        end
    end

    return nil
end

function CLASS.GetSortedClasses()
    local classes = {}

    for _, v in pairs(CLASS.CLASSES) do
        classes[v.index] = v
    end

    CLASS.SortClassesTable(classes)

    return classes
end

function CLASS.generateClassPool()
    local maxEntries = GetGlobalInt("ttt_classes_different")
    local classAmount = table.Count(CLASS.CLASSES)

    local classes = {}

    -- if the amount of available classes is smaller than the amount of classes to
    -- be selected, the class array should be shuffled
    if maxEntries > 0 and classAmount >= maxEntries then
        local num_index = 1
        for _, v in pairs(CLASS.CLASSES) do
            classes[num_index] = v

            num_index = num_index + 1
        end

        table.Shuffle(classes)
    else
        classes = CLASS.CLASSES
    end

    for _, v in pairs(classes) do
        if not GetConVar("tttc_class_" .. v.name .. "_enabled"):GetBool() then
            continue
        end

        local b = true
        local r = GetConVar("tttc_class_" .. v.name .. "_random"):GetInt()

        if r > 0 and r < 100 then
            b = math.random(100) <= r
        elseif r <= 0 then
            b = false
        end

        if b then
            local nextEntry = #CLASS.AVAILABLECLASSES + 1

            CLASS.AVAILABLECLASSES[nextEntry] = v

            if maxEntries > 0 and nextEntry >= maxEntries then
                break
            end
        end
    end

    if #CLASS.AVAILABLECLASSES == 0 then
        return
    end

    table.Empty(CLASS.FREECLASSES)

    if GetGlobalBool("ttt_classes_limited") then
        for _, v in ipairs(CLASS.AVAILABLECLASSES) do
            table.insert(CLASS.FREECLASSES, v)
        end
    end
end

function CLASS.selectClassFromPool()
    if #CLASS.FREECLASSES == 0 then
        CLASS.generateClassPool()
    end

    local rand = math.random(#CLASS.FREECLASSES)
    local selection = CLASS.FREECLASSES[rand].index
    table.remove(CLASS.FREECLASSES, rand)

    return selection
end

if CLIENT then
    local TryT

    function CLASS.GetClassTranslation(classData)
        TryT = TryT or LANG.TryTranslation

        if not classData then
            return "- " .. TryT("ttt2_tttc_class_unknown") .. " -"
        end

        if classData.lang then
            return TryT("tttc_class_" .. classData.name .. "_name")
        end

        return TryT(classData.name)
    end
end

local networkRequestID = 0
local networkReceiveFuncs = {}

if SERVER then
    util.AddNetworkString("TTT2RequestEnabledClasses")

    ---
    -- Answers the request for all classes that are currently enabled. The enabled convars are
    -- server-only and can only be read by admins, which is why this request exists. A request
    -- from any player is answered.
    -- @note When classes are globally disabled with the `ttt2_classes` convar, an empty list
    -- is returned.
    -- @param net.Message msg (unused)
    -- @param Player ply The player that requested the enabled classes
    -- @realm server
    net.Receive("TTT2RequestEnabledClasses", function(_, ply)
        local requestID = net.ReadUInt(8)
        local classesEnabled = GetConVar("ttt2_classes")
        local enabledClasses = {}

        -- classes are globally disabled, there is nothing to show
        if classesEnabled and classesEnabled:GetBool() then
            for _, classData in pairs(CLASS.CLASSES) do
                if not classData.name then
                    continue
                end

                local enabledConVar = GetConVar("tttc_class_" .. classData.name .. "_enabled")

                if enabledConVar and enabledConVar:GetBool() then
                    enabledClasses[#enabledClasses + 1] = classData.name
                end
            end
        end

        net.Start("TTT2RequestEnabledClasses")
        net.WriteUInt(requestID, 8)
        net.WriteUInt(#enabledClasses, 8)

        for i = 1, #enabledClasses do
            net.WriteString(enabledClasses[i])
        end

        net.Send(ply)
    end)
else
    net.Receive("TTT2RequestEnabledClasses", function()
        local requestID = net.ReadUInt(8)
        local classCount = net.ReadUInt(8)
        local enabledClasses = {}

        for i = 1, classCount do
            enabledClasses[net.ReadString()] = true
        end

        local callback = networkReceiveFuncs[requestID]

        if not callback then
            return
        end

        networkReceiveFuncs[requestID] = nil

        callback(enabledClasses)
    end)

    ---
    -- Requests a table of all classes that are currently enabled on the server. The class
    -- settings are server-only convars, which is why they have to be requested.
    -- @param function callback Called with a table of enabled class names
    -- @realm client
    function CLASS.RequestEnabledClasses(callback)
        networkRequestID = networkRequestID % 255 + 1
        networkReceiveFuncs[networkRequestID] = callback

        net.Start("TTT2RequestEnabledClasses")
        net.WriteUInt(networkRequestID, 8)
        net.SendToServer()
    end
end
