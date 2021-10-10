local tableCopy = table.Copy

local virtualSubmenus = {}

CLGAMEMODEMENU.base = "base_gamemodemenu"

CLGAMEMODEMENU.icon = Material("vgui/ttt/vskin/helpscreen/tttc")
CLGAMEMODEMENU.title = "menu_tttc_title"
CLGAMEMODEMENU.description = "menu_tttc_description"
CLGAMEMODEMENU.priority = 40

CLGAMEMODEMENU.isInitialized = false
CLGAMEMODEMENU.classes = nil

function CLGAMEMODEMENU:IsAdminMenu()
	return true
end

function CLGAMEMODEMENU:InitializeVirtualMenus()
	-- add "virtual" submenus that are treated as real one even without files
	virtualSubmenus = {}

	self.classes = CLASS.GetSortedClasses()
	local classesMenuBase = self:GetSubmenuByName("base_classes")

	local counter = 0
	for _, classData in pairs(self.classes) do

		counter = counter + 1

		virtualSubmenus[counter] = tableCopy(classesMenuBase)
		virtualSubmenus[counter].title = CLASS.GetClassTranslation(classData)
		virtualSubmenus[counter].classData = classData
		virtualSubmenus[counter].basemenu = self
	end
end

-- overwrite the normal submenu function to return our custom virtual submenus
function CLGAMEMODEMENU:GetSubmenus()
	if not self.isInitialized then
		self.isInitialized = true

		self:InitializeVirtualMenus()
	end

	return virtualSubmenus
end

-- overwrite and return true to enable a searchbar
function CLGAMEMODEMENU:HasSearchbar()
	return true
end

function CLGAMEMODEMENU:ShouldShow()
	return GetGlobalBool("ttt2_classes") and self.BaseClass.ShouldShow(self)
end
