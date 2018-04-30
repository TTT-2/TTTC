hook.Add("TTT2_FinishedClassesSync", "TTTCMainFinishedClassesSync", function(ply, first)
	if CLIENT and first then -- just on client and first init !

		LANG.AddToLanguage("English", "tttc_no_cls_desc", "Currently you don't have a class!")

        LANG.AddToLanguage("Deutsch", "tttc_no_cls_desc", "Du besitzt gerade keine Klasse!")
    end
end)