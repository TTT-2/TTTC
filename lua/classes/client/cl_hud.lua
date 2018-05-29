local table = table
local surface = surface
local draw = draw
local math = math
local string = string

local GetRawLang

local sf = surface
local dr = draw

local notification_state = 0
local notification_phase = 0
local notification_time = 4
local notification_fade = 0.4
local notification_start = 0

-- Fonts
sf.CreateFont("CurrentClass", {font = "Trebuchet24", size = 28, weight = 1000})
sf.CreateFont("CurrentClassDesc", {font = "Trebuchet24", size = 52, weight = 1000})
sf.CreateFont("ClassDesc", {font = "Trebuchet24", size = 21, weight = 1000})

local function DrawBg(x, y, client)
	-- Traitor area sizes
	local tw = 170
	local th = 30
    
    local col = client:GetClassData().color or COLOR_CLASS

	-- main border, traitor based
	dr.RoundedBox(8, x, y - th, tw, th, col)
end

local function ShadowedText(text, font, x, y, color, xalign, yalign)
	dr.SimpleText(text, font, x + 2, y + 2, COLOR_BLACK, xalign, yalign)
	dr.SimpleText(text, font, x, y, color, xalign, yalign)
end

local margin = 10

local function ClassesInfo(client)
	local round_state = GAMEMODE.round_state
    
	if round_state == ROUND_ACTIVE and client:IsActive() then
        if GetConVar("ttt_customclasses_enabled"):GetBool() and client:HasCustomClass() then
            local cd = client:GetClassData()
            
            local x = margin
            local y = ScrH() - margin - 120 * 2 -- add a padding between role and class for other addons, so multiply 120 with 2 (otherwise without 2)
            
            local xStr = tostring(x)
            local yStr = tostring(y)
            
            x = CreateClientConVar("tttc_hud_x", xStr, true, false, "The relative x-coordinate (position) of the HUD. (0-100) Def: " .. xStr):GetFloat()
            y = CreateClientConVar("tttc_hud_y", yStr, true, false, "The relative y-coordinate (position) of the HUD. (0-100) Def: " .. yStr):GetFloat()

            DrawBg(x, y, client)

            x = x + margin + 73
            y = y - 30
            
            local text = GetClassTranslation(cd)

            -- Draw current class state
            ShadowedText(text, "CurrentClass", x, y, COLOR_WHITE, TEXT_ALIGN_CENTER)
        end
    end
end

local function ClassNotification(client)
    local round_state = GAMEMODE.round_state
    local ct = CurTime()
    local tm = notification_start + notification_time
    
	if tm > ct and round_state == ROUND_ACTIVE and client:IsActive() then
        if GetConVar("ttt_customclasses_enabled"):GetBool() and client:HasCustomClass() then
            GetRawLang = GetRawLang or LANG.GetRawTranslation
            
            local cd = client:GetClassData()
            
            local x = margin
            local mid = ScrW() / 2
            
            -- draw box
            local tw = ScrW() - margin * 2
            local th = 75
            local col = cd.color or COLOR_CLASS
            
            local bWeapons = cd.weapons and #cd.weapons > 0
            if bWeapons then
                th = th + 25
            end
            
            local bItems = cd.items and #cd.items > 0
            if bItems then
                th = th + 25
            end
            
            local desc_text = GetRawLang("class_desc_" .. cd.name)
            if desc_text then
                th = th + 25
            end
            
            local y = -th
            
            -------------------------
            -- notification animation
            
            if notification_state >= 1 and notification_phase == 0 then
                notification_phase = 1
            elseif notification_state <= 0 and notification_phase == 2 then
                notification_phase = 3
            else
                if notification_phase == 1 then
                    local restTime = tm - ct
                    restTime = restTime - notification_fade
                    
                    if restTime <= 0 then
                        notification_phase = 2
                    end
                else
                    local restTime = tm - ct
                    
                    if notification_phase == 0 then
                        notification_state = (notification_time - restTime) / notification_fade
                    else
                        notification_state = restTime / notification_fade
                    end
                end
            end
            
            if notification_phase == 3 then
                notification_phase = 0
            end
            
            -- end notification animation
            -----------------------------
            
            y = y + (margin + th) * notification_state

            dr.RoundedBox(8, x, y, tw, th, col)
            
            -- draw class text
            local text = GetClassTranslation(cd)

            ShadowedText(text, "CurrentClassDesc", mid, y + 10, COLOR_WHITE, TEXT_ALIGN_CENTER)
            
            -- draw description
            y = y + 70
            
            -- weapons
            if bWeapons then
                local weaps = ""
                
                for _, cls in ipairs(cd.weapons) do
                    local tmp = weapons.Get(cls)
                    
                    local cls2 = tmp and tmp.PrintName or cls
                
                    if weaps ~= "" then
                        weaps = weaps .. ", "
                    end
                    
                    weaps = weaps .. cls2
                end
            
                text = (GetRawLang("classes_desc_weapons_short") or "Weapons: ") .. weaps
            
                dr.SimpleText(text, "ClassDesc", mid, y, COLOR_WHITE, TEXT_ALIGN_CENTER)
                
                y = y + 25
            end
            
            -- items
            if bItems then
                local items = ""
                
                for _, id in ipairs(cd.items) do
                    local name = GetStaticEquipmentItem(id)
                    name = name and (name.name or "UNNAMED") or "UNNAMED"
                
                    if items ~= "" then
                        items = items .. ", "
                    end
                    
                    items = items .. name
                end
                
                text = (GetRawLang("classes_desc_items_short") or "Items: ") .. items
            
                dr.SimpleText(text, "ClassDesc", mid, y, COLOR_WHITE, TEXT_ALIGN_CENTER)
                
                y = y + 25
            end
            
            -- custom desc
            if desc_text then
                dr.SimpleText(desc_text, "ClassDesc", mid, y, COLOR_WHITE, TEXT_ALIGN_CENTER)
            end
        end
    end
end

hook.Add("HUDPaint", "TTTCClassesHudPaint", function()
	local client = LocalPlayer()
    
    if hook.Run("HUDShouldDraw", "TTTCClassesInfo") then
		ClassesInfo(client)
	end
    
    if CreateClientConVar("tttc_class_notification", "1", true, false, "Toggle the notification on receiving a class.") or hook.Run("HUDShouldDraw", "TTTCClassNotification") then
        ClassNotification(client)
    end
end)

hook.Add("TTTCUpdatedCustomClass", "HUDNtfctnUpdatedCustomClass", function(ply)
    if ply:HasCustomClass() then
        notification_start = CurTime()
        notification_state = 0
        notification_phase = 0
    end
end)
