CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"
CLGAMEMODESUBMENU.title = "submenu_addons_tttc_title"

function CLGAMEMODESUBMENU:Populate(parent)
	local form = vgui.CreateTTT2Form(parent, "header_addons_tttc")

	form:MakeHelp({
		label = "help_addons_tttc"
	})

	form:MakeCheckBox({
		label = "label_tttc_classes_enable",
		serverConvar = "ttt2_classes"
	})

	form:MakeCheckBox({
		label = "label_tttc_classes_limited",
		serverConvar = "ttt_classes_limited"
	})

	form:MakeCheckBox({
		label = "label_tttc_classes_option",
		serverConvar = "ttt_classes_option"
	})

	form:MakeCheckBox({
		label = "label_tttc_classes_extraslot",
		serverConvar = "ttt_classes_extraslot"
	})

	form:MakeCheckBox({
		label = "label_tttc_classes_respawn_keep",
		serverConvar = "ttt_classes_keep_on_respawn"
	})

	form:MakeCheckBox({
		label = "label_tttc_classes_popup",
		serverConvar = "ttt_classes_show_popup"
	})

	form:MakeCheckBox({
		label = "label_tttc_classes_teamsync",
		serverConvar = "ttt_classes_sync_team"
	})

	form:MakeSlider({
		label = "label_tttc_classes_different",
		serverConvar = "ttt_classes_different",
		min = 0,
		max = 100,
		decimal = 0
	})
end
