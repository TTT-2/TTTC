--- @ignore

CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"

CLGAMEMODESUBMENU.priority = 97
CLGAMEMODESUBMENU.title = "submenu_guide_classes_title"

local TryT = LANG.TryTranslation
local GetRawT = LANG.GetRawTranslation

local heightClassButton = 50
local widthClassListMin = 200
local widthClassListMax = 320
local widthClassListPercent = 0.33

local lastActive

---
-- Only shows the classes page when classes are globally enabled. The classes admin menu
-- uses the same gate.
-- @return boolean Whether the page should be shown
-- @realm client
function CLGAMEMODESUBMENU:ShouldShow()
    return GetGlobalBool("ttt2_classes")
end

---
-- Creates a label that wraps its text if it does not fit into a single line.
-- @note A plain `DLabel` is used here, because `DLabelTTT2` paints its text with
-- `draw.SimpleText`, which does not wrap long texts such as class descriptions.
-- @param Panel parent The parent panel
-- @param string text The text that should be displayed
-- @param[opt] string font The font that should be used
-- @return Panel The created label
-- @realm client
local function CreateWrappedLabel(parent, text, font)
    local label = vgui.Create("DLabel", parent)
    label:Dock(TOP)
    label:SetText(text)
    label:SetFont(font or "DermaTTT2Text")
    label:SetWrap(true)
    label:SetAutoStretchVertical(true)
    label:DockMargin(10, 5, 10, 5)

    return label
end

---
-- Returns all classes that are currently enabled on the server. Classes that are disabled in
-- the class settings are not included, as they cannot be assigned to any player.
-- @param function callback Called with the list of classes that should be shown
-- @realm client
local function GetVisibleClasses(callback)
    CLASS.RequestEnabledClasses(function(enabledClasses)
        local visibleClasses = {}

        -- the sorted classes are indexed by their class index, which can have gaps
        for _, classData in pairs(CLASS.GetSortedClasses()) do
            if not enabledClasses[classData.name] then
                continue
            end

            visibleClasses[#visibleClasses + 1] = {
                class = classData,
                title = CLASS.GetClassTranslation(classData),
            }
        end

        table.SortByMember(visibleClasses, "title", true)

        callback(visibleClasses)
    end)
end

---
-- Populates the info panel with the details of the given class.
-- @param Panel parent The parent panel
-- @param table classData The class whose details should be displayed
-- @realm client
local function PopulateClassInfo(parent, classData)
    CreateWrappedLabel(parent, CLASS.GetClassTranslation(classData), "DermaTTT2TextLarger")

    -- class description, class addons provide it as a language identifier
    local description =
        GetRawT("tttc_class_" .. classData.name .. "_desc") or TryT("guide_class_no_description")

    CreateWrappedLabel(parent, description, "DermaTTT2Text")
end

---
-- Displays the details of the given class in the info panel.
-- @param Panel infoPanel The scroll panel that contains the class details
-- @param table classData The class whose details should be displayed
-- @param Panel classButton The button that belongs to the class
-- @realm client
local function SelectClass(infoPanel, classData, classButton)
    infoPanel:Clear()

    PopulateClassInfo(infoPanel, classData)

    -- handle the set/unset of active buttons for the draw process
    if IsValid(lastActive) and lastActive.SetActive then
        lastActive:SetActive(false)
    end

    classButton:SetActive()
    lastActive = classButton

    -- always show the beginning of a class's description
    infoPanel:GetVBar():SetScroll(0)
    infoPanel:InvalidateLayout(true)
end

function CLGAMEMODESUBMENU:Populate(parent)
    lastActive = nil

    local width, height = parent:GetSize()

    -- the parent is a scroll panel, the container takes its size to prevent scrolling
    -- of the whole page, the class list and the class details scroll on their own
    local container = vgui.Create("DPanelTTT2", parent)
    container:Dock(TOP)
    container:SetTall(height)

    local widthClassList =
        math.Clamp(width * widthClassListPercent, widthClassListMin, widthClassListMax)

    local listPanel = vgui.Create("DScrollPanelTTT2", container)
    listPanel:Dock(LEFT)
    listPanel:SetWide(widthClassList)
    listPanel:DockMargin(0, 0, 10, 0)

    local infoPanel = vgui.Create("DScrollPanelTTT2", container)
    infoPanel:Dock(FILL)

    GetVisibleClasses(function(visibleClasses)
        -- the menu can be closed while the class settings are fetched from the server
        if not IsValid(listPanel) or not IsValid(infoPanel) then
            return
        end

        local firstClass, firstClassButton

        for i = 1, #visibleClasses do
            local classData = visibleClasses[i].class

            local classButton = vgui.Create("DSubmenuButtonTTT2", listPanel)
            classButton:Dock(TOP)
            classButton:DockMargin(0, 0, 0, 5)
            classButton:SetTitle(visibleClasses[i].title)

            classButton.PerformLayout = function(panel)
                panel:SetSize(panel:GetParent():GetWide(), heightClassButton)
            end

            classButton.DoClick = function(slf)
                SelectClass(infoPanel, classData, slf)
            end

            if not firstClass then
                firstClass = classData
                firstClassButton = classButton
            end
        end

        -- preselect the first class so the info panel is never empty
        if firstClass then
            SelectClass(infoPanel, firstClass, firstClassButton)
        else
            CreateWrappedLabel(infoPanel, TryT("guide_class_none"))
        end
    end)
end
