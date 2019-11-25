# TTTC - Custom Classes in TTT2

TTTC is an addon to TTT2 that adds custom secondary abilities, called classes, to each player. TTTC doesn't ship with any classes, but provides an easy to use interface. Classes feature two parts: a passive ability that is given once the class is set and an active ability that is triggered on a ability keypress for a certain amount of time combined with a timeout after the usage.

## How to Create a Class

To create a class, the function `CLASS.AddClass(name, classData, conVarData)` has to be called on both client and server.

```lua
-- Example 1 - A basic class

CLASS.AddClass("YOURCLASS", {
    color = Color(149, 188, 195, 255),
    langs = {
        English = "Your Class",
        Deutsch = "Deine Klasse"
    }
})
```

Shown in **`example 1`** is a basic class with only a name and a color and no active features. This file has to be stored in `<your_addon>/lua/classes/classes/<this_file>.lua` to be registered automatically on both client and server.

This simple `classData` table can now be extended by all of the following elements:

```lua
---
-- GENERAL CLASS SETTINGS

-- Sets the color of the class.
classDara.color = <Color> -- [default: Color(255, 155, 0, 255)]

-- Disables the active ability of this class.
classData.passive = <boolean> -- [default: false]

-- Disables all class specific functions. This can be used when all class related things should be
-- handled externally.
classData.deactivated = <boolean> -- [default: false]

-- Sets the language strings of the class that are rendered ingame, at least one should be set.
classData.langs = {}

---
-- PASSIVE ABILITY DATA

-- A table of weapons given to the player once the class is set, they are automatically
-- remoed when the class is removed from the player.
classData.passiveWeapons = {}

-- A table of items given to the player once the class is set, they are automatically
-- remoed when the class is removed from the player.
classData.passiveItems = {}

---
-- ACTIVE ABILITY DATA

-- A table of weapons given to the player once the class is activated, they are automatically
-- removed when the ability is disabled.
classData.weapons = {}

-- A table of items given to the player once the class is activated, they are automatically
-- removed when the ability is disabled.
classData.items = {}

-- A function that is called on activation of an ability. If avoidWeaponReset is equal to false
-- wepons will be removed prior to this function call.
classData.onActivate = function(ply) [default: nil]

-- A function that is called on deactivation of an ability. If avoidWeaponReset is equal to false
-- wepons will be given back prior to this function call.
classData.onDeactivate = function(ply) [default: nil]

-- A function that is called prior to onActivate. If it is set, the ability will be activated on the
-- next ability key press.
classData.onPrepareActivation = function(ply) [default: nil]

-- This function will only be called if onPrepareActivation was set. It is called on the second
-- press of the ability key and is done directly before onActivate.
-- If the ability was canceled in this process, this function is called prior to onDeactivate.
classData.onFinishPreparingActivation = function(ply) [default: nil]

-- This function is called once a player starts the charging process, if returned nil or false, the
-- charging process is stopped.
classData.onCharge = function(ply) [default: nil]

-- This function is called when the ability should be activated. Activation fails if returned nil or false.
classData.checkActivation = function(ply) [default: nil]

-- The time how long the ability is enabled after the player activated it
-- if set to 0, onActivate isn't called. You have to use onDeactivated in this case.
classData.time = <number> -- [default: 60]

-- The cooldown time after the usage of the active ability.
classData.cooldown = <number> -- [default: 60]

-- Defines how long the activate key must be pressed to activate the ability, nil for instant.
classData.charging = <number> -- [default: nil]

-- Defines how many times an ability can be activated per round, nil for infinite times.
classData.amount = <number> -- [default: nil]

-- If true, the time of an ability is infinite.
classData.endless = <boolean> -- [default: false]

-- If true, the player can not disable the ability once they pressed the ability key.
classData.unstoppable = <boolean> -- [default: false]

-- If false, all weapons will be removed while the player uses their ability.
classData.avoidWeaponReset = <boolean> -- [default: false]
```

Check out [this folder](https://github.com/TTT-2/ttt2h-pack-default/tree/master/lua/classes/classes) for a bunch of examples or [this class](https://github.com/TTT-2/tttc-class_shooter/blob/master/lua/classes/classes/class_shooter.lua) for a really simple example.
