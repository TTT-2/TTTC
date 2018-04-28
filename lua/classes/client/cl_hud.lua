local table = table
local surface = surface
local draw = draw
local math = math
local string = string

local GetLang

local sf = surface
local dr = draw

-- Fonts
sf.CreateFont("CurrentClass", {font = "Trebuchet24", size = 28, weight = 1000})

local function DrawBg(x, y, client)
	-- Traitor area sizes
	local tw = 170
	local th = 30
    
    local col = client:GetClassData().color or Color(255, 155, 0, 255)

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
            GetLang = GetLang or LANG.GetUnsafeLanguageTable
            
            local L = GetLang()
            local x = margin
            local y = ScrH() - margin - 120

            DrawBg(x, y, client)

            x = x + margin + 73
            y = y - 30
            
            local text = L[client:GetClassData().name]

            -- Draw current class state
            ShadowedText(text, "CurrentClass", x, y, COLOR_WHITE, TEXT_ALIGN_CENTER)
        end
    end
end

hook.Add("HUDPaint", "TTT2ClassesHudPaint", function()
	local client = LocalPlayer()
    
    if hook.Run("HUDShouldDraw", "TTT2ClassesInfo") then
		ClassesInfo(client)
	end
end)
