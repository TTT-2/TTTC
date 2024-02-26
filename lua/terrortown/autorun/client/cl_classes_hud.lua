local GetLang

local surface = surface
local draw = draw

local margin = 10
local default_hud_x = margin
local default_hud_y = ScrH() - margin - 120 * 2 -- add a padding between role and class for other addons, so multiply 120 with 2 (otherwise without 2)

local cv = {}
cv.class_notification = CreateClientConVar(
    "tttc_class_notification",
    "1",
    true,
    false,
    "Toggle the notification on receiving a class class."
)
cv.class_hud_width = CreateClientConVar(
    "tttc_hud_width",
    "20",
    true,
    false,
    "The relative x-coordinate (position) of the HUD. (0-100) Def: 20"
)
cv.class_hud_y = CreateClientConVar(
    "tttc_hud_y",
    tostring(default_hud_y),
    true,
    false,
    "The relative y-coordinate (position) of the HUD. (0-100) Def: " .. tostring(default_hud_y)
)
cv.class_hud_x = CreateClientConVar(
    "tttc_hud_x",
    tostring(default_hud_x),
    true,
    false,
    "The relative x-coordinate (position) of the HUD. (0-100) Def: " .. tostring(default_hud_x)
)

local function DrawBg(x, y, client, xw)
    -- Traitor area sizes
    local tw = 150 + xw
    local th = 30
    local classData = client:GetClassData()

    if not classData then
        return
    end

    local col = classData.color or COLOR_CLASS

    -- main border, traitor based
    draw.RoundedBox(8, x, y - th, tw, th, col)
end

local function ShadowedText(text, font, x, y, color, xalign, yalign)
    draw.SimpleText(text, font, x + 2, y + 2, COLOR_BLACK, xalign, yalign)
    draw.SimpleText(text, font, x, y, color, xalign, yalign)
end

local function ClassInfo(client)
    if huds and HUDManager then
        local hud = huds.GetStored(HUDManager.GetHUD())

        if hud and hud.GetElementByType then
            local elem = hud:GetElementByType("tttinfopanel")
            if
                elem
                and elem.SetSecondaryRoleInfoFunction
                and isfunction(elem.SetSecondaryRoleInfoFunction)
            then
                return
            end
        end
    end

    local round_state = GAMEMODE.round_state

    if (round_state == ROUND_PREP or client:IsActive()) and client:HasClass() then
        local classData = client:GetClassData()

        local x = cv.class_hud_x:GetFloat()
        local y = cv.class_hud_y:GetFloat()

        local xw = cv.class_hud_width:GetFloat()

        DrawBg(x, y, client, xw)

        x = x + margin + 63 + xw * 0.5
        y = y - 30

        local text = CLASS.GetClassTranslation(classData)

        -- Draw current class state
        ShadowedText(text, "CurrentClass", x, y, COLOR_WHITE, TEXT_ALIGN_CENTER)
    end
end

hook.Add("TTT2HUDUpdated", "TTTCUpdateClassesInfo", function()
    if not hudelements then
        Msg(
            "Warning: New HUD module does not seem to be loaded in TTT2Initialize, so we cannot register to custom huds.\n"
        )

        return
    end

    local hudInfoElements = hudelements.GetAllTypeElements("tttinfopanel")

    for _, v in ipairs(hudInfoElements) do
        if v.SetSecondaryRoleInfoFunction then
            v:SetSecondaryRoleInfoFunction(function()
                local classData = LocalPlayer():GetClassData()

                if not classData then
                    return
                end

                return {
                    color = classData.color or COLOR_CLASS,
                    text = CLASS.GetClassTranslation(classData),
                }
            end)
        end
    end
end)

hook.Add("TTT2Initialize", "TTTCCreateAdvancedFonts", function()
    surface.CreateAdvancedFont("CurrentClass", { font = "Trebuchet24", size = 28, weight = 1000 })
    surface.CreateAdvancedFont(
        "CurrentClassDesc",
        { font = "Trebuchet24", size = 52, weight = 1000 }
    )
    surface.CreateAdvancedFont("ClassDesc", { font = "Trebuchet24", size = 14, weight = 1000 })
    surface.CreateAdvancedFont(
        "ClassDescOptions",
        { font = "Trebuchet24", size = 28, weight = 1000 }
    )
end)

hook.Add("HUDPaint", "TTTCClassHudPaint", function()
    local client = LocalPlayer()

    if hook.Run("HUDShouldDraw", "TTTCClassInfo") then
        ClassInfo(client)
    end
end)

hook.Add("TTTRenderEntityInfo", "tttc_add_class_info", function(tData)
    local ent = tData:GetEntity()

    if not GetGlobalBool("ttt2_classes", false) then
        return
    end

    -- has to be a player
    if not ent:IsPlayer() then
        return
    end
    if GetRoundState() == ROUND_PREP then
        return
    end

    GetLang = GetLang or LANG.GetRawTranslation

    local class_data = ent:GetClassData()

    if tData:GetAmountDescriptionLines() > 0 then
        tData:AddDescriptionLine()
    end

    tData:AddDescriptionLine(
        GetLang("ttt2_tttc_class") .. ": " .. CLASS.GetClassTranslation(class_data),
        class_data and class_data.color or COLOR_LGRAY
    )
end)
