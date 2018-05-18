if CLIENT then
    hook.Add("TTTCFinishedClassesSync", "TTTCMainFinishedClassesSync", function(ply, first)
        if first then -- just on client and first init !
            LANG.AddToLanguage("English", "tttc_no_cls_desc", "Currently you don't have a class!")
            LANG.AddToLanguage("English", "tttc_toggle_notification", "Class notification")
            LANG.AddToLanguage("English", "tttc_toggle_notification_tip", "Toggles the class notification")
            LANG.AddToLanguage("English", "classes_desc_weapons", "The class receives the following weapons at the beginning of the next round: ")
            LANG.AddToLanguage("English", "classes_desc_weapons_short", "Weapons: ")
            LANG.AddToLanguage("English", "classes_desc_items", "The class receives the following items at the beginning of the next round: ")
            LANG.AddToLanguage("English", "classes_desc_items_short", "Items: ")

            LANG.AddToLanguage("Deutsch", "tttc_no_cls_desc", "Du besitzt gerade keine Klasse!")
            LANG.AddToLanguage("Deutsch", "tttc_toggle_notification", "Klassen-Benachrichtigung")
            LANG.AddToLanguage("Deutsch", "tttc_toggle_notification_tip", "Aktiviere/Deaktiviere die Klassen-Benachrichtigung")
            LANG.AddToLanguage("Deutsch", "classes_desc_weapons", "Die Klasse erhält zu Beginn der Runde folgende Waffen: ")
            LANG.AddToLanguage("Deutsch", "classes_desc_weapons_short", "Waffen: ")
            LANG.AddToLanguage("Deutsch", "classes_desc_items", "Die Klasse erhält zu Beginn der Runde folgende Items: ")
            LANG.AddToLanguage("Deutsch", "classes_desc_items_short", "Items: ")
        end
    end)
end