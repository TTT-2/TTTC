-- include all class files automatically

fileloader.LoadFolder("classes/classes/", false, SHARED_FILE, function(path)
	MsgN("Added TTT2 class file: ", path)
end)
