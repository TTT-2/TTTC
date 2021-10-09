CLGAMEMODESUBMENU.priority = 0
CLGAMEMODESUBMENU.title = "TTTC Class Settings"

function CLGAMEMODESUBMENU:Populate(parent)
		local className = CLASS.GetClassTranslation(self.classData)

		local form = vgui.CreateTTT2Form(parent, className)

		form:MakeHelp({
			label = "tttc_class_" .. self.classData.name .. "_desc"
		})

		form:MakeCheckBox({
			label = "label_tttc_class_enabled",
			serverConvar = "tttc_class_" .. self.classData.name .. "_enabled"
		})

		form:MakeSlider({
			label = "label_tttc_class_spawn_chance",
			serverConvar = "tttc_class_" .. self.classData.name .. "_random",
			min = 0,
			max = 100,
			decimal = 0
		})
end
