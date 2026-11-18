extends Node

var abilities = {
	"dash": false,
	"magnetic_feet": false
}

func has_ability(name: String) -> bool:
	return abilities.get(name, false)

func unlock(name: String):
	abilities[name] = true
	print("Unlocked: ", name)
