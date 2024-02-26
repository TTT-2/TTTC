local draw = draw

local base = "dynamic_hud_element"

DEFINE_BASECLASS(base)

HUDELEMENT.Base = base

if CLIENT then
    local optionMargin = 20
    local optionSize = 120
    local optionCircleSize = 20
    local iconSize = 64

    local circle = 360
    local oldTimerVal, timerVal, outer
    local diamondMaterial = Material("vgui/ttt/icon_diamond")

    local arcID1, arcID2, arcID3, arcID4, arcID5

    local const_defaults = {
        basepos = { x = 0, y = 0 },
        size = { w = optionSize, h = optionSize },
        minsize = { w = 90, h = 90 },
    }

    function HUDELEMENT:Initialize()
        self.scale = 1.0
        oldTimerVal = nil
        timerVal = nil
        outer = nil
        self.optionMargin = optionMargin
        self.optionSize = optionSize
        self.optionCircleSize = optionCircleSize
        self.iconSize = iconSize
        BaseClass.Initialize(self)
    end

    function HUDELEMENT:GetDefaults()
        const_defaults["basepos"] = {
            x = ScrW() - self.optionSize - self.optionMargin,
            y = ScrH() - self.optionSize - self.optionMargin,
        }
        return const_defaults
    end

    -- parameter overwrites
    function HUDELEMENT:IsResizable()
        return true, true
    end

    function HUDELEMENT:AspectRatioIsLocked()
        return true
    end
    -- parameter overwrites end

    function HUDELEMENT:PerformLayout()
        self.scale = self:GetHUDScale()
        self.optionMargin = optionMargin * self.scale
        self.optionSize = optionSize * self.scale
        self.optionCircleSize = optionCircleSize * self.scale
        self.iconSize = iconSize * self.scale
        BaseClass.PerformLayout(self)
    end

    function HUDELEMENT:ShouldDraw()
        local client = LocalPlayer()

        return HUDEditor.IsEditing or (client:HasClass() and client:IsActive())
    end

    function HUDELEMENT:Draw()
        local client = LocalPlayer()
        local pos = self:GetPos()
        local x, y = pos.x, pos.y
        local w = self:GetSize().w
        local r_w = math.Round(w * 0.5) -- radius
        local tx, ty = x + r_w, y + r_w
        local r_optionCircleSize = math.Round(self.optionCircleSize * 0.5) -- radius
        local r_innerCircleSize = r_w - r_optionCircleSize * 2

        local classData = client:GetClassData() or {}
        local timeNow = CurTime()
        local active = client:HasClassActive()

        local abilityStartTime = client:GetClassTimestamp()
        local abilityDuration = client:GetClassTime()
        local abilityTimeSince = timeNow - (abilityStartTime or 0) -- 0 just to avoid arithmetic with nil exception, this never has a real use case and will never even be used

        local cooldownStartTime = client:GetClassCooldownTS()
        local cooldownDuration = client:GetClassCooldown()
        local cooldownTimeSince = timeNow - (cooldownStartTime or 0) -- 0 just to avoid arithmetic with nil exception, this never has a real use case and will never even be used

        local abilityPercentage = 0
        local cooldownPercentage = 0

        if abilityDuration and abilityStartTime and abilityTimeSince <= abilityDuration then
            abilityPercentage = math.Clamp(abilityTimeSince / abilityDuration, 0, 1)
        end

        if cooldownDuration and cooldownStartTime and cooldownTimeSince <= cooldownDuration then
            cooldownPercentage = math.Clamp(cooldownTimeSince / cooldownDuration, 0, 1)
            abilityPercentage = 1 -- set ability circle to zero when cooldown is active
        end

        if classData.endless then
            abilityPercentage = 0
        end

        local ttt2HeroesActive = GetGlobalBool("ttt2_heroes")
        local crystalValid = not ttt2HeroesActive or client:HasCrystal() -- TODO to improve performance, use a var and just update it on destruction
        local text, icon

        if not crystalValid and client:GetNWBool("CanSpawnCrystal") then
            oldTimerVal = nil
            icon = diamondMaterial
        elseif classData.passive and not ttt2HeroesActive then
            return
        elseif
            classData.passive
            or classData.deactivated
            or not crystalValid and not client:GetNWBool("CanSpawnCrystal")
            or classData.amount and classData.amount <= (client.classAmount or 0)
        then
            oldTimerVal = nil
            text = "-"
        elseif cooldownStartTime and cooldownStartTime + cooldownDuration > timeNow then
            timerVal = math.ceil(cooldownStartTime - timeNow + cooldownDuration)
            oldTimerVal = oldTimerVal or timerVal
            text = timerVal

            arcID1 = draw.Arc(
                arcID1,
                tx,
                ty,
                r_w - r_optionCircleSize,
                r_optionCircleSize,
                0,
                circle,
                10,
                Color(0, 0, 0, 150)
            )
        elseif active then
            oldTimerVal = nil

            text = "IN USE!"
        elseif classData.charging then
            oldTimerVal = nil
            text = "CHARGE"
        else
            oldTimerVal = nil
            text = "READY"
        end

        local inner = math.ceil((1 - abilityPercentage) * circle)

        if not oldTimerVal or oldTimerVal ~= timerVal then
            oldTimerVal = timerVal
            outer = math.ceil((1 - cooldownPercentage) * circle)
        end

        local val

        if client.charging then
            local starting = client.charging
            local duration = classData.charging - 1
            local timeSince = timeNow - starting -- 0 just to avoid arithmetic with nil exception, this never has a real use case and will never even be used

            if duration and starting and timeSince <= duration then
                val = math.Clamp(timeSince / duration, 0, 1)
            end
        end

        arcID2 = draw.Arc(
            arcID2,
            tx,
            ty,
            r_innerCircleSize,
            r_innerCircleSize,
            0,
            360,
            10,
            Color(0, 0, 0, 240)
        )
        arcID3 = draw.Arc(arcID3, tx, ty, 0, r_innerCircleSize, 0, circle, 10, Color(0, 0, 0, 230))
        arcID4 = draw.Arc(arcID4, tx, ty, r_w, r_optionCircleSize, 0, outer, 2, Color(0, 0, 0, 200))
        arcID5 = draw.Arc(
            arcID5,
            tx,
            ty,
            r_w - r_optionCircleSize,
            r_optionCircleSize,
            0,
            inner * ((classData.charging and not active) and (client.charging and val or 0) or 1),
            5,
            ColorAlpha(classData.color or Color(255, 155, 55), 170)
        )

        if icon then
            local iSize = w - (self.optionSize - self.iconSize)
            local hw = math.Round((w - iSize) * 0.5)

            util.DrawFilteredTexturedRect(x + hw, y + hw, iSize, iSize, icon)
        elseif text then
            local hw = math.Round(w * 0.5)

            if w >= self.optionSize then
                draw.SimpleText(
                    text,
                    "Trebuchet24",
                    x + hw,
                    y + hw,
                    Color(255, 255, 255, 150),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            else
                draw.SimpleText(
                    text,
                    "Trebuchet18",
                    x + hw,
                    y + hw,
                    Color(255, 255, 255, 150),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
        end
    end
end
