extends Node

var abilities = {
	"dash": false
}

func has_ability(name: String) -> bool:
	return abilities.get(name, false)

func unlock(name: String):
	abilities[name] = true
	print("Unlocked: ", name)
